import uuid

from datetime import datetime

from typing import List, Optional, TYPE_CHECKING



from sqlalchemy.dialects.postgresql import UUID

from sqlalchemy.orm import Mapped, mapped_column, relationship

from sqlalchemy.sql.functions import func

from sqlalchemy import ForeignKey

from sqlalchemy.sql.sqltypes import String



from config.database import Base



if TYPE_CHECKING:

    from app.users.models import User, Teacher, Student

    from app.school.models import School

    from app.schedule.models import Schedule

    from app.homework.models import Homework

    from app.material.models import Material





class Class(Base):

    __tablename__ = "classes"



    id: Mapped[uuid.UUID] = mapped_column(

        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, index=True

    )

    name: Mapped[str] = mapped_column(String, nullable=False)

    school_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("schools.id"))



    created_at: Mapped[datetime] = mapped_column(server_default=func.now())

    updated_at: Mapped[datetime] = mapped_column(server_default=func.now(), onupdate=func.now())



    school: Mapped["School"] = relationship("School", back_populates="classes")



    teacher_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("teachers.user_id"), nullable=True)

    teacher: Mapped["Teacher"] = relationship("Teacher", back_populates="classes", foreign_keys=[teacher_id])



    students: Mapped[list["Student"]] = relationship("Student", back_populates="class_")



    

    schedules: Mapped[List["Schedule"]] = relationship("Schedule", back_populates="class_", cascade="all, delete-orphan")

    homeworks: Mapped[List["Homework"]] = relationship("Homework", back_populates="class_", cascade="all, delete-orphan")

    materials: Mapped[List["Material"]] = relationship("app.material.models.Material", back_populates="class_", cascade="all, delete-orphan")

