import enum
import uuid
from datetime import time, datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql.functions import func

from config.database import Base

if TYPE_CHECKING:
    from app.users.models import Teacher
    from app.classes.models import Class
    from app.subject.models import Subject


class DayOfWeek(str, enum.Enum):
    MONDAY = "monday"
    TUESDAY = "tuesday"
    WEDNESDAY = "wednesday"
    THURSDAY = "thursday"
    FRIDAY = "friday"
    SATURDAY = "saturday"
    SUNDAY = "sunday"


class Schedule(Base):
    __tablename__ = "schedules"
    __table_args__ = (
        CheckConstraint('period_number >= 1 AND period_number <= 10', name='period_number_range'),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, index=True
    )

    day_of_week: Mapped[DayOfWeek] = mapped_column(nullable=False)
    period_number: Mapped[int] = mapped_column(nullable=False)  # 1-10 (ora 1, ora 2, etc.)
    start_time: Mapped[time] = mapped_column(nullable=False)
    end_time: Mapped[time] = mapped_column(nullable=False)
    room: Mapped[Optional[str]] = mapped_column(nullable=True)  # sala de clasă

    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(server_default=func.now(), onupdate=func.now())

    # Foreign keys
    class_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("classes.id", ondelete="CASCADE"),
        nullable=False
    )
    subject_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("subjects.id", ondelete="CASCADE"),
        nullable=False
    )
    teacher_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("teachers.user_id", ondelete="CASCADE"),
        nullable=False
    )

    # Relationships
    class_: Mapped["Class"] = relationship("Class", back_populates="schedules")
    subject: Mapped["Subject"] = relationship("Subject", back_populates="schedules")
    teacher: Mapped["Teacher"] = relationship("Teacher", back_populates="schedules")

    def __repr__(self):
        return f"<Schedule(day={self.day_of_week}, period={self.period_number}, subject={self.subject_id})>"