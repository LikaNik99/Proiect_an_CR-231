import uuid
from typing import List
from fastapi import APIRouter, Depends, status

from app.notification.repository import NotificationRepository
from app.notification.schemas import NotificationCreate, NotificationRead
from app.notification.service import NotificationService
from config.database import AsyncSession, get_db
from config.dependences import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications"])


async def get_notification_service(session: AsyncSession = Depends(get_db)) -> NotificationService:
    repository = NotificationRepository(session)
    return NotificationService(repository)


@router.post("/", response_model=NotificationRead, status_code=status.HTTP_201_CREATED)
async def create_notification(
    notification_data: NotificationCreate,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    return await service.create_notification(notification_data)


@router.get("/my-notifications", response_model=List[NotificationRead])
async def get_my_notifications(
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    user_id = uuid.UUID(current_user["id"])
    return await service.get_user_notifications(user_id)


@router.put("/{notification_id}/read", response_model=NotificationRead)
async def mark_notification_as_read(
    notification_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    return await service.mark_as_read(notification_id)


@router.post("/broadcast", status_code=status.HTTP_201_CREATED)
async def broadcast_announcement(
    title: str,
    message: str,
    target_roles: List[str] = None,  # ["TEACHER", "STUDENT"] or None for all
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
    session: AsyncSession = Depends(get_db)
):
    """
    Broadcast announcement to all users or specific roles (Director only).
    """
    from sqlalchemy import select
    from app.users.models.user import User, UserRole
    from app.websocket.manager import manager

    # Check if user is director
    user_id = uuid.UUID(current_user["id"])
    from app.users.models.teachers import Teacher
    result = await session.execute(
        select(Teacher).where(Teacher.user_id == user_id)
    )
    teacher = result.scalar_one_or_none()

    if not teacher or not teacher.is_director:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only directors can broadcast announcements"
        )

    # Get all users based on target roles
    query = select(User)
    if target_roles:
        role_enums = [UserRole(role) for role in target_roles]
        query = query.where(User.role.in_(role_enums))

    result = await session.execute(query)
    users = list(result.scalars().all())

    # Create notifications for all users
    notifications_created = 0
    for user in users:
        notif = await service.create_notification(
            NotificationCreate(
                title=title,
                message=message,
                notification_type=NotificationType.ANNOUNCEMENT,
                user_id=user.id
            )
        )

        # Send via WebSocket
        try:
            await manager.send_personal_message(
                {
                    "type": "announcement",
                    "event": "created",
                    "notification": {
                        "id": str(notif.id),
                        "title": notif.title,
                        "message": notif.message,
                        "notification_type": notif.notification_type,
                        "created_at": notif.created_at.isoformat(),
                    }
                },
                str(user.id)
            )
        except Exception:
            pass

        notifications_created += 1

    return {
        "success": True,
        "message": f"Announcement sent to {notifications_created} users",
        "count": notifications_created
    }


@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_notification(
    notification_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    await service.delete_notification(notification_id)