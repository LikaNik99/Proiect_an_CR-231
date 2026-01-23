import enum
import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql.functions import func

from config.database import Base

if TYPE_CHECKING:
    from app.users.models import User


class NotificationType(str, enum.Enum):
    NEW_GRADE = "new_grade"
    NEW_HOMEWORK = "new_homework"
    ANNOUNCEMENT = "announcement"
    SCHEDULE_CHANGE = "schedule_change"
    ATTENDANCE = "attendance"
    MESSAGE = "message"
    OTHER = "other"


class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, index=True
    )

    title: Mapped[str] = mapped_column(nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    notification_type: Mapped[NotificationType] = mapped_column(nullable=False)
    is_read: Mapped[bool] = mapped_column(default=False)

    created_at: Mapped[datetime] = mapped_column(server_default=func.now())

    # Foreign key
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="notifications")

    def __repr__(self):
        return f"<Notification(title={self.title}, type={self.notification_type})>"