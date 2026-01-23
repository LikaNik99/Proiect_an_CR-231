import uuid
from typing import List
from fastapi import APIRouter, Depends, Query, status, HTTPException

from app.grade.repository import GradeRepository
from app.grade.schemas import GradeCreate, GradeRead, GradeUpdate
from app.grade.service import GradeService
from config.database import AsyncSession, get_db
from config.dependences import get_current_user, admin_required
from config.pagination import PaginationParams

# NEW: notification + websocket
from app.notification.repository import NotificationRepository
from app.notification.schemas import NotificationCreate
from app.notification.models import NotificationType
from app.websocket.manager import manager

router = APIRouter(prefix="/grades", tags=["Grades"])


async def get_grade_service(session: AsyncSession = Depends(get_db)) -> GradeService:
    repository = GradeRepository(session)
    return GradeService(repository)


@router.post("/", response_model=GradeRead, status_code=status.HTTP_201_CREATED)
async def create_grade(
        grade_data: GradeCreate,
        current_user: dict = Depends(get_current_user),
        service: GradeService = Depends(get_grade_service),
        session: AsyncSession = Depends(get_db),
):
    """Create a new grade (Teacher or Admin only)"""

    # Enforce role (docstring already claims this, but it wasn't enforced)
    if current_user.get("role") not in {"teacher", "admin"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only teacher or admin can create grades",
        )

    grade = await service.create_grade(grade_data)

    # Create persistent notification for the student
    try:
        subject_name = None
        try:
            subject_name = getattr(getattr(grade, "subject", None), "name", None)
        except Exception:
            subject_name = None

        title = "Notă nouă"
        if subject_name:
            message = f"Ai primit nota {grade.value} la {subject_name}."
        else:
            message = f"Ai primit nota {grade.value}."

        notif_repo = NotificationRepository(session)
        notif = await notif_repo.create(
            NotificationCreate(
                title=title,
                message=message,
                notification_type=NotificationType.NEW_GRADE,
                user_id=grade.student_id,
            )
        )

        # Emit real-time WebSocket event to the student (if connected)
        await manager.send_personal_message(
            {
                "type": "grade",
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
                "grade": {
                    "id": str(grade.id),
                    "value": grade.value,
                    "types": grade.types,
                    "student_id": str(grade.student_id),
                    "teacher_id": str(grade.teacher_id),
                    "subject_id": str(grade.subject_id),
                    "subject": {
                        "id": str(grade.subject.id),
                        "name": grade.subject.name,
                    } if getattr(grade, "subject", None) is not None else None,
                    "created_at": grade.created_at.isoformat() if getattr(grade, "created_at", None) else None,
                },
            },
            user_id=str(grade.student_id),
        )
    except Exception:
        # Notification failures shouldn't fail the grade creation.
        pass

    return grade


@router.get("/", dependencies=[Depends(admin_required)])
async def get_all_grades(
        pagination: PaginationParams = Depends(),
        service: GradeService = Depends(get_grade_service)
):
    """Get all grades with pagination (Admin only)"""
    return await service.get_all_grades(pagination.skip, pagination.limit)


@router.get("/my-grades", response_model=List[GradeRead])
async def get_my_grades(
        skip: int = Query(0, ge=0),
        limit: int = Query(100, ge=1, le=200),
        current_user: dict = Depends(get_current_user),
        service: GradeService = Depends(get_grade_service)
):
    """Get grades for the current student with pagination"""
    user_id = uuid.UUID(current_user["id"])
    items, total = await service.get_student_grades(user_id, skip, limit)
    return items  # Return items directly for backward compatibility


@router.get("/student/{student_id}", response_model=List[GradeRead])
async def get_student_grades(
        student_id: uuid.UUID,
        skip: int = Query(0, ge=0),
        limit: int = Query(100, ge=1, le=200),
        current_user: dict = Depends(get_current_user),
        service: GradeService = Depends(get_grade_service)
):
    """Get grades for a specific student with pagination"""
    items, total = await service.get_student_grades(student_id, skip, limit)
    return items


@router.get("/teacher/{teacher_id}", response_model=List[GradeRead])
async def get_teacher_grades(
        teacher_id: uuid.UUID,
        skip: int = Query(0, ge=0),
        limit: int = Query(100, ge=1, le=200),
        current_user: dict = Depends(get_current_user),
        service: GradeService = Depends(get_grade_service)
):
    """Get all grades given by a specific teacher with pagination"""
    items, total = await service.get_teacher_grades(teacher_id, skip, limit)
    return items


@router.get("/subject/{subject_id}", response_model=List[GradeRead])
async def get_subject_grades(
        subject_id: uuid.UUID,
        skip: int = Query(0, ge=0),
        limit: int = Query(100, ge=1, le=200),
        current_user: dict = Depends(get_current_user),
        service: GradeService = Depends(get_grade_service)
):
    """Get all grades for a specific subject with pagination"""
    items, total = await service.get_subject_grades(subject_id, skip, limit)
    return items


@router.get("/{grade_id}", response_model=GradeRead)
async def get_grade(
        grade_id: uuid.UUID,
        current_user: dict = Depends(get_current_user),
        service: GradeService = Depends(get_grade_service)
):
    """Get a specific grade by ID"""
    return await service.get_grade(grade_id)


@router.put("/{grade_id}", response_model=GradeRead)
async def update_grade(
        grade_id: uuid.UUID,
        grade_data: GradeUpdate,
        current_user: dict = Depends(get_current_user),
        service: GradeService = Depends(get_grade_service)
):
    """Update a grade (Teacher or Admin only)"""
    return await service.update_grade(grade_id, grade_data)


@router.delete("/{grade_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_grade(
        grade_id: uuid.UUID,
        current_user: dict = Depends(get_current_user),
        service: GradeService = Depends(get_grade_service)
):
    """Delete a grade (Admin only)"""
    await service.delete_grade(grade_id)
