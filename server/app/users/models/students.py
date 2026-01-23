import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional, List

from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql.functions import func

from app.classes import Class
from config.database import Base

if TYPE_CHECKING:
    from app.users.models import User
    from app.grade.models import GradeModel
    from app.attendance.models import Attendance


class Student(Base):
    __tablename__ = "students"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True
    )

    user: Mapped["User"] = relationship("User", back_populates="student", uselist=False)
    class_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("classes.id", ondelete="SET NULL"), nullable=True
    )

    class_: Mapped[Optional["Class"]] = relationship("Class", back_populates="students",
                                                     overlaps="homeroom,headed_classes")

    # New relationships
    grades: Mapped[List["GradeModel"]] = relationship("GradeModel", back_populates="student", cascade="all, delete-orphan")
    attendances: Mapped[List["Attendance"]] = relationship("Attendance", back_populates="student", cascade="all, delete-orphan")

    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(server_default=func.now(), onupdate=func.now())

    def __repr__(self):
        return f"<Student(user_id={self.user_id})>"
