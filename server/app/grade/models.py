import enum
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql.functions import func

from config.database import Base

if TYPE_CHECKING:
    from app.users.models import Teacher, Student
    from app.subject.models import Subject


class GradeTypes(str, enum.Enum):
    EXAM = "exam"
    TEST = "test"
    HOMEWORK = "homework"
    ASSIGNMENT = "assignment"
    OTHER = "other"


class GradeModel(Base):
    __tablename__ = "grades"
    __table_args__ = (
        CheckConstraint('value >= 2 AND value <= 10', name='grade_value_range'),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, index=True
    )
    value: Mapped[int] = mapped_column(nullable=False)
    types: Mapped[GradeTypes] = mapped_column(nullable=False)
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(server_default=func.now(), onupdate=func.now())

    student_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("students.user_id", ondelete="CASCADE"),
        nullable=False
    )
    teacher_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("teachers.user_id", ondelete="CASCADE"),
        nullable=False
    )
    subject_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("subjects.id"), nullable=False)

    student: Mapped["Student"] = relationship("Student", back_populates="grades")
    teacher: Mapped["Teacher"] = relationship("Teacher", back_populates="grades")
    subject: Mapped["Subject"] = relationship("Subject", back_populates="grades")
