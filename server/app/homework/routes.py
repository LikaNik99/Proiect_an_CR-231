import uuid
from typing import List
from fastapi import APIRouter, Depends, status

from app.homework.repository import HomeworkRepository
from app.homework.schemas import HomeworkCreate, HomeworkRead, HomeworkUpdate
from app.homework.service import HomeworkService
from config.database import AsyncSession, get_db
from config.dependences import get_current_user

# NEW: notification + websocket
from sqlalchemy import select
from app.classes.models import Class
from app.notification.repository import NotificationRepository
from app.notification.schemas import NotificationCreate
from app.notification.models import NotificationType
from app.websocket.manager import manager

# NEW: student model
from app.users.models.students import Student

router = APIRouter(prefix="/homework", tags=["Homework"])


async def get_homework_service(session: AsyncSession = Depends(get_db)) -> HomeworkService:
    repository = HomeworkRepository(session)
    return HomeworkService(repository)


def _format_due(dt) -> str | None:
    if not dt:
        return None

    # If time part is 00:00, show only date; otherwise show date + hour.
    try:
        if getattr(dt, "hour", 0) == 0 and getattr(dt, "minute", 0) == 0:
            return dt.strftime('%d.%m.%Y')
        return dt.strftime('%d.%m.%Y %H:%M')
    except Exception:
        return None


def _build_homework_notification_text(hw, class_name: str | None) -> tuple[str, str]:
    # Title & message designed to be short in a notification list, but informative.
    due_txt = _format_due(getattr(hw, "due_date", None))

    subject_name = None
    subj = getattr(hw, "subject", None)
    if subj is not None:
        subject_name = getattr(subj, "name", None)

    assigned_count = len(getattr(hw, "assignments", []) or [])
    is_personal = assigned_count > 0

    title = "Temă nouă"

    parts: list[str] = []
    if is_personal:
        parts.append("Ai primit o temă personală")
    else:
        parts.append("A fost publicată o temă pentru clasă")

    # Include title/subject/class in a predictable order.
    if getattr(hw, "title", None):
        parts.append(f"„{hw.title}“")

    if subject_name:
        parts.append(f"la {subject_name}")

    if class_name:
        parts.append(f"(Clasa {class_name})")

    if due_txt:
        parts.append(f"Termen: {due_txt}")

    message = ". ".join(parts) + "."
    return title, message


def _serialize_homework_read(hw) -> dict:
    # helper used for websocket payloads
    return {
        "id": str(hw.id),
        "title": hw.title,
        "description": getattr(hw, "description", None),
        "due_date": hw.due_date.isoformat() if getattr(hw, "due_date", None) else None,
        "status": getattr(hw, "status", None),
        "subject_id": str(hw.subject_id) if getattr(hw, "subject_id", None) else None,
        "class_id": str(hw.class_id),
        "teacher_id": str(hw.teacher_id) if getattr(hw, "teacher_id", None) else None,
        "assigned_student_ids": [str(a.student_id) for a in getattr(hw, "assignments", []) or []],
        "is_personal": bool(getattr(hw, "assignments", None)) and len(getattr(hw, "assignments", []) or []) > 0,
    }


@router.post("/", response_model=HomeworkRead, status_code=status.HTTP_201_CREATED)
async def create_homework(
    homework_data: HomeworkCreate,
    current_user: dict = Depends(get_current_user),
    service: HomeworkService = Depends(get_homework_service),
    session: AsyncSession = Depends(get_db),
):
    hw = await service.create_homework(homework_data)

    # Notify: if homework has explicit assignments -> notify only those students.
    # Otherwise notify all students in the class.
    try:
        assigned_ids = [str(a.student_id) for a in getattr(hw, 'assignments', []) or []]

        user_ids: List[str] = []
        class_name: str | None = None

        if assigned_ids:
            user_ids = assigned_ids
        else:
            result = await session.execute(select(Class).where(Class.id == hw.class_id))
            cls = result.scalar_one_or_none()
            if cls:
                class_name = getattr(cls, "name", None)
            if cls and getattr(cls, "students", None):
                user_ids = [str(s.user_id) for s in cls.students if getattr(s, "user_id", None)]

        if user_ids:
            notif_repo = NotificationRepository(session)
            title, message = _build_homework_notification_text(hw, class_name)

            for uid in user_ids:
                notif = await notif_repo.create(
                    NotificationCreate(
                        title=title,
                        message=message,
                        notification_type=NotificationType.NEW_HOMEWORK,
                        user_id=uuid.UUID(uid),
                    )
                )

                await manager.send_personal_message(
                    {
                        "type": "homework",
                        "event": "created",
                        "notification": {
                            "id": str(notif.id),
                            "title": notif.title,
                            "message": notif.message,
                            "notification_type": notif.notification_type,
                            "is_read": notif.is_read,
                            "created_at": notif.created_at.isoformat() if getattr(notif, "created_at", None) else None,
                            "user_id": str(notif.user_id),
                        },
                        "homework": _serialize_homework_read(hw),
                    },
                    user_id=str(uid),
                )
    except Exception:
        pass

    return HomeworkRead.from_orm_with_assignments(hw)


@router.post('/bulk', response_model=List[HomeworkRead], status_code=status.HTTP_201_CREATED)
async def create_homework_bulk(
    homeworks: List[HomeworkCreate],
    current_user: dict = Depends(get_current_user),
    service: HomeworkService = Depends(get_homework_service),
    session: AsyncSession = Depends(get_db),
):
    created = await service.bulk_create_homework(homeworks)

    # Notify students for each created homework
    try:
        notif_repo = NotificationRepository(session)

        # Group by class id to avoid repeated Selects
        class_ids = {c.class_id for c in created if getattr(c, "class_id", None)}
        class_map = {}
        for cid in class_ids:
            result = await session.execute(select(Class).where(Class.id == cid))
            class_map[cid] = result.scalar_one_or_none()

        for hw in created:
            assigned_ids = [str(a.student_id) for a in getattr(hw, 'assignments', []) or []]

            user_ids: List[str] = []
            class_name: str | None = None

            if assigned_ids:
                user_ids = assigned_ids
            else:
                cls = class_map.get(hw.class_id)
                if not cls or not getattr(cls, "students", None):
                    continue
                class_name = getattr(cls, "name", None)
                user_ids = [str(s.user_id) for s in cls.students if getattr(s, "user_id", None)]

            title, message = _build_homework_notification_text(hw, class_name)

            for uid in user_ids:
                notif = await notif_repo.create(
                    NotificationCreate(
                        title=title,
                        message=message,
                        notification_type=NotificationType.NEW_HOMEWORK,
                        user_id=uuid.UUID(uid),
                    )
                )

                await manager.send_personal_message(
                    {
                        "type": "homework",
                        "event": "created",
                        "notification": {
                            "id": str(notif.id),
                            "title": notif.title,
                            "message": notif.message,
                            "notification_type": notif.notification_type,
                            "is_read": notif.is_read,
                            "created_at": notif.created_at.isoformat() if getattr(notif, "created_at", None) else None,
                            "user_id": str(notif.user_id),
                        },
                        "homework": _serialize_homework_read(hw),
                    },
                    user_id=str(uid),
                )
    except Exception:
        pass

    return [HomeworkRead.from_orm_with_assignments(hw) for hw in created]


@router.get("/my", response_model=List[HomeworkRead])
async def get_my_homework(
    current_user: dict = Depends(get_current_user),
    service: HomeworkService = Depends(get_homework_service),
    session: AsyncSession = Depends(get_db),
):
    # For students: returns ONLY homework explicitly assigned to this student.
    # Only homework with a HomeworkAssignment entry for this student will be returned.
    user_id = uuid.UUID(current_user["id"])
    result = await session.execute(select(Student).where(Student.user_id == user_id))
    student = result.scalar_one_or_none()
    class_id = getattr(student, 'class_id', None) if student else None

    items = await service.get_student_homework(student_id=user_id, class_id=class_id)
    return [HomeworkRead.from_orm_with_assignments(hw) for hw in items]


@router.get("/class/{class_id}", response_model=List[HomeworkRead])
async def get_class_homework(
    class_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: HomeworkService = Depends(get_homework_service)
):
    items = await service.get_class_homework(class_id)
    return [HomeworkRead.from_orm_with_assignments(hw) for hw in items]


@router.get("/{homework_id}", response_model=HomeworkRead)
async def get_homework(
    homework_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: HomeworkService = Depends(get_homework_service)
):
    return await service.get_homework(homework_id)


@router.put("/{homework_id}", response_model=HomeworkRead)
async def update_homework(
    homework_id: uuid.UUID,
    homework_data: HomeworkUpdate,
    current_user: dict = Depends(get_current_user),
    service: HomeworkService = Depends(get_homework_service)
):
    return await service.update_homework(homework_id, homework_data)


@router.delete("/{homework_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_homework(
    homework_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: HomeworkService = Depends(get_homework_service)
):
    await service.delete_homework(homework_id)