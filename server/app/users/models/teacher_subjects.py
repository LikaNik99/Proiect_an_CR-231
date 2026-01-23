import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql.functions import func

from config.database import Base

if TYPE_CHECKING:
    from app.users.models import Teacher
    from app.subject.models import Subject
    from app.classes.models import Class


class TeacherSubject(Base):
    """Many-to-many Teacher <-> Subject (what disciplines a teacher can teach)."""

    __tablename__ = "teacher_subjects"
    __table_args__ = (
        UniqueConstraint("teacher_id", "subject_id", name="uq_teacher_subject"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    teacher_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("teachers.user_id", ondelete="CASCADE"), nullable=False, index=True
    )
    subject_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False, index=True
    )

    created_at: Mapped[datetime] = mapped_column(server_default=func.now())

    teacher: Mapped["Teacher"] = relationship("Teacher", back_populates="teacher_subjects")
    subject: Mapped["Subject"] = relationship("Subject")


class TeacherClassSubject(Base):
    """Assignment Teacher -> Class -> Subject.

    This is the source of truth for which subjects a teacher teaches in a given class.
    Schedule entries should reference one of these assignments.
    """

    __tablename__ = "teacher_class_subjects"
    __table_args__ = (
        UniqueConstraint("teacher_id", "class_id", "subject_id", name="uq_teacher_class_subject"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    teacher_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("teachers.user_id", ondelete="CASCADE"), nullable=False, index=True
    )
    class_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("classes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    subject_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False, index=True
    )

    created_at: Mapped[datetime] = mapped_column(server_default=func.now())

    teacher: Mapped["Teacher"] = relationship("Teacher", back_populates="teacher_class_subjects")
    class_: Mapped["Class"] = relationship("Class")
    subject: Mapped["Subject"] = relationship("Subject")
