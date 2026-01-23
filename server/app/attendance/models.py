import enum

import uuid

from datetime import date, datetime

from typing import TYPE_CHECKING, Optional



from sqlalchemy import ForeignKey, Text

from sqlalchemy.dialects.postgresql import UUID

from sqlalchemy.orm import Mapped, mapped_column, relationship

from sqlalchemy.sql.functions import func



from config.database import Base



if TYPE_CHECKING:

    from app.users.models import Student, Teacher

    from app.subject.models import Subject





class AttendanceStatus(str, enum.Enum):

    PRESENT = "present"

    ABSENT = "absent"

    LATE = "late"

    EXCUSED = "excused"





class Attendance(Base):

    __tablename__ = "attendances"



    id: Mapped[uuid.UUID] = mapped_column(

        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, index=True

    )



    attendance_date: Mapped[date] = mapped_column(nullable=False)

    status: Mapped[AttendanceStatus] = mapped_column(nullable=False)

    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)



    created_at: Mapped[datetime] = mapped_column(server_default=func.now())

    updated_at: Mapped[datetime] = mapped_column(server_default=func.now(), onupdate=func.now())



    

    student_id: Mapped[uuid.UUID] = mapped_column(

        ForeignKey("students.user_id", ondelete="CASCADE"),

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



    

    student: Mapped["Student"] = relationship("Student", back_populates="attendances")

    subject: Mapped["Subject"] = relationship("Subject", back_populates="attendances")

    teacher: Mapped["Teacher"] = relationship("Teacher", back_populates="attendances")



    def __repr__(self):

        return f"<Attendance(student={self.student_id}, date={self.attendance_date}, status={self.status})>"
