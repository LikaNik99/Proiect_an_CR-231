import uuid
from typing import List
from fastapi import HTTPException, status

from app.notification.models import Notification
from app.notification.repository import NotificationRepository
from app.notification.schemas import NotificationCreate


class NotificationService:
    def __init__(self, repository: NotificationRepository):
        self.repository = repository

    async def create_notification(self, notification_data: NotificationCreate) -> Notification:
        return await self.repository.create(notification_data)

    async def get_notification(self, notification_id: uuid.UUID) -> Notification:
        notification = await self.repository.get_by_id(notification_id)
        if not notification:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Notification with id {notification_id} not found"
            )
        return notification

    async def get_user_notifications(self, user_id: uuid.UUID) -> List[Notification]:
        return await self.repository.get_by_user(user_id)

    async def mark_as_read(self, notification_id: uuid.UUID) -> Notification:
        notification = await self.repository.mark_as_read(notification_id)
        if not notification:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Notification with id {notification_id} not found"
            )
        return notification

    async def delete_notification(self, notification_id: uuid.UUID) -> None:
        success = await self.repository.delete(notification_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Notification with id {notification_id} not found"
            )