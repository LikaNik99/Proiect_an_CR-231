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


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, index=True
    )

    subject: Mapped[str] = mapped_column(nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    is_read: Mapped[bool] = mapped_column(default=False)

    created_at: Mapped[datetime] = mapped_column(server_default=func.now())

    # Foreign keys
    sender_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )
    receiver_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    # Relationships
    sender: Mapped["User"] = relationship("User", foreign_keys=[sender_id], back_populates="sent_messages")
    receiver: Mapped["User"] = relationship("User", foreign_keys=[receiver_id], back_populates="received_messages")

    def __repr__(self):
        return f"<Message(subject={self.subject}, from={self.sender_id}, to={self.receiver_id})>"