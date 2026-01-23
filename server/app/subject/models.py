import uuid
from typing import List, TYPE_CHECKING
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from config.database import Base

if TYPE_CHECKING:
    from app.grade.models import GradeModel
    from app.schedule.models import Schedule
    from app.homework.models import Homework
    from app.attendance.models import Attendance
    from app.material.models import Material


class Subject(Base):
    __tablename__ = "subjects"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, index=True
    )
    name: Mapped[str] = mapped_column(nullable=False, index=True)

    # Relationships
    grades: Mapped[List["GradeModel"]] = relationship("GradeModel", back_populates="subject", cascade="all, delete-orphan")
    schedules: Mapped[List["Schedule"]] = relationship("Schedule", back_populates="subject", cascade="all, delete-orphan")
    homeworks: Mapped[List["Homework"]] = relationship("Homework", back_populates="subject", cascade="all, delete-orphan")
    attendances: Mapped[List["Attendance"]] = relationship("Attendance", back_populates="subject", cascade="all, delete-orphan")
    materials: Mapped[List["Material"]] = relationship("Material", back_populates="subject", cascade="all, delete-orphan")
