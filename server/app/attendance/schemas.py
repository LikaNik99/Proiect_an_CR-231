import uuid

from datetime import date, datetime

from typing import Optional

from pydantic import BaseModel



from app.attendance.models import AttendanceStatus





class AttendanceBase(BaseModel):

    attendance_date: date

    status: AttendanceStatus

    notes: Optional[str] = None

    student_id: uuid.UUID

    subject_id: uuid.UUID

    teacher_id: uuid.UUID





class AttendanceCreate(AttendanceBase):

    pass





class AttendanceUpdate(BaseModel):

    status: Optional[AttendanceStatus] = None

    notes: Optional[str] = None





class SubjectInfo(BaseModel):

    id: uuid.UUID

    name: str



    class Config:

        from_attributes = True





class AttendanceRead(AttendanceBase):

    id: uuid.UUID

    created_at: datetime

    subject: Optional[SubjectInfo] = None



    class Config:

        from_attributes = True
