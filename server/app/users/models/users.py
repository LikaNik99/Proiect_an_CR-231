import uuid
from datetime import datetime
from typing import Optional, TYPE_CHECKING, List
from passlib.context import CryptContext
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql.functions import func
from sqlalchemy import ForeignKey
from sqlalchemy.sql.sqltypes import Integer, DateTime, String

from app.classes import Class
from app.users.enums import UserRole
from config.database import Base

if TYPE_CHECKING:
    from app.users.models import Student, Teacher
    from app.school.models import School
    from app.notification.models import Notification

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, index=True
    )
    username: Mapped[str] = mapped_column(nullable=False, index=True)
    email: Mapped[str] = mapped_column(unique=True, nullable=False)
    password: Mapped[Optional[str]] = mapped_column(nullable=True)
    role: Mapped[UserRole] = mapped_column(nullable=False)
    is_activated: Mapped[bool] = mapped_column(default=False)
    reset_code: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    reset_code_expires: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    school_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("schools.id", ondelete="SET NULL"), nullable=True
    )

    # Avatar/profile picture URL (optional)
    avatar_url: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(server_default=func.now(), onupdate=func.now())

    school: Mapped[Optional["School"]] = relationship("School", back_populates="users")

    teacher: Mapped[Optional["Teacher"]] = relationship(
        "Teacher",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
        passive_deletes=True
    )

    student: Mapped[Optional["Student"]] = relationship(
        "Student",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
        passive_deletes=True
    )

    # Relationships for notifications
    notifications: Mapped[List["Notification"]] = relationship(
        "Notification", back_populates="user", cascade="all, delete-orphan"
    )

    def set_password(self, plain_password: str):
        self.password = pwd_context.hash(plain_password)

    def verify_password(self, plain_password: str) -> bool:
        if self.password is None:
            return False
        return pwd_context.verify(plain_password, self.password)
