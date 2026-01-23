import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional, List

from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql.functions import func
from sqlalchemy.sql.sqltypes import String, Boolean, DateTime

from config.database import Base

if TYPE_CHECKING:
    from app.grade.models import GradeModel
    from app.users.models import User
    from app.classes.models import Class
    from app.schedule.models import Schedule
    from app.homework.models import Homework
    from app.attendance.models import Attendance
    from app.material.models import Material
    from app.users.models.teacher_subjects import TeacherSubject, TeacherClassSubject


class Teacher(Base):
    __tablename__ = "teachers"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )

    subject: Mapped[str | None] = mapped_column(String, nullable=True)

    is_homeroom: Mapped[bool] = mapped_column(Boolean(), default=False, nullable=False)
    is_director: Mapped[bool] = mapped_column(Boolean(), default=False, nullable=False)
    class_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("classes.id", ondelete="SET NULL"), nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )

    classes: Mapped[list["Class"]] = relationship(
        "Class", back_populates="teacher", foreign_keys="Class.teacher_id"
    )
    user: Mapped["User"] = relationship("User", back_populates="teacher", uselist=False)

    # New relationships
    grades: Mapped[List["GradeModel"]] = relationship("GradeModel", back_populates="teacher", cascade="all, delete-orphan")
    schedules: Mapped[List["Schedule"]] = relationship("Schedule", back_populates="teacher", cascade="all, delete-orphan")
    homeworks: Mapped[List["Homework"]] = relationship("Homework", back_populates="teacher", cascade="all, delete-orphan")
    attendances: Mapped[List["Attendance"]] = relationship("Attendance", back_populates="teacher", cascade="all, delete-orphan")
    materials: Mapped[List["Material"]] = relationship("Material", back_populates="teacher", cascade="all, delete-orphan")

    # NEW: explicit subject associations
    teacher_subjects: Mapped[List["TeacherSubject"]] = relationship(
        "TeacherSubject", back_populates="teacher", cascade="all, delete-orphan"
    )
    teacher_class_subjects: Mapped[List["TeacherClassSubject"]] = relationship(
        "TeacherClassSubject", back_populates="teacher", cascade="all, delete-orphan"
    )
