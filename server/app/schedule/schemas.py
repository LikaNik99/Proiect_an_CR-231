import uuid
from datetime import time, datetime
from typing import Optional
from pydantic import BaseModel

from app.schedule.models import DayOfWeek


class ScheduleBase(BaseModel):
    day_of_week: DayOfWeek
    period_number: int
    start_time: time
    end_time: time
    room: Optional[str] = None
    class_id: uuid.UUID
    subject_id: uuid.UUID
    teacher_id: uuid.UUID


class ScheduleCreate(ScheduleBase):
    pass


class ScheduleUpdate(BaseModel):
    day_of_week: Optional[DayOfWeek] = None
    period_number: Optional[int] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    room: Optional[str] = None


class SubjectInfo(BaseModel):
    id: uuid.UUID
    name: str

    class Config:
        from_attributes = True


class TeacherInfo(BaseModel):
    id: uuid.UUID
    username: str

    class Config:
        from_attributes = True


class ClassInfo(BaseModel):
    id: uuid.UUID
    name: str

    class Config:
        from_attributes = True


class ScheduleRead(ScheduleBase):
    id: uuid.UUID
    created_at: datetime
    subject: Optional[SubjectInfo] = None
    class_: Optional[ClassInfo] = None

    class Config:
        from_attributes = True