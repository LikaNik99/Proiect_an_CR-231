import uuid
from typing import List, Optional
from sqlalchemy import select

from app.notification.models import Notification
from app.notification.schemas import NotificationCreate, NotificationUpdate
from config.database import AsyncSession


class NotificationRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, notification_data: NotificationCreate) -> Notification:
        notification = Notification(**notification_data.model_dump())
        self.session.add(notification)
        await self.session.commit()
        await self.session.refresh(notification)
        return notification

    async def get_by_id(self, notification_id: uuid.UUID) -> Optional[Notification]:
        result = await self.session.execute(
            select(Notification).where(Notification.id == notification_id)
        )
        return result.scalar_one_or_none()

    async def get_by_user(self, user_id: uuid.UUID) -> List[Notification]:
        result = await self.session.execute(
            select(Notification)
            .where(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
        )
        return list(result.scalars().all())

    async def mark_as_read(self, notification_id: uuid.UUID) -> Optional[Notification]:
        notification = await self.get_by_id(notification_id)
        if not notification:
            return None

        notification.is_read = True
        await self.session.commit()
        await self.session.refresh(notification)
        return notification

    async def delete(self, notification_id: uuid.UUID) -> bool:
        notification = await self.get_by_id(notification_id)
        if not notification:
            return False

        await self.session.delete(notification)
        await self.session.commit()
        return True