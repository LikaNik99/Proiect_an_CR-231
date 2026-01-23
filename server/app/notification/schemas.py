import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel

from app.notification.models import NotificationType


class NotificationBase(BaseModel):
    title: str
    message: str
    notification_type: NotificationType
    user_id: uuid.UUID


class NotificationCreate(NotificationBase):
    pass


class NotificationUpdate(BaseModel):
    is_read: Optional[bool] = None


class NotificationRead(NotificationBase):
    id: uuid.UUID
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True