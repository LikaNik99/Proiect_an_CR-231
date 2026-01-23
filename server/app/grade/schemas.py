import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.grade.models import GradeTypes


class GradeBase(BaseModel):
    value: int = Field(..., ge=2, le=10, description="Grade value between 2 and 10")
    types: GradeTypes
    student_id: uuid.UUID
    teacher_id: uuid.UUID
    subject_id: uuid.UUID


class GradeCreate(GradeBase):
    pass


class GradeUpdate(BaseModel):
    value: Optional[int] = Field(None, ge=2, le=10)
    types: Optional[GradeTypes] = None


class SubjectInfo(BaseModel):
    id: uuid.UUID
    name: str

    class Config:
        from_attributes = True


class GradeRead(GradeBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime
    subject: Optional[SubjectInfo] = None

    class Config:
        from_attributes = True


class GradeWithSubject(BaseModel):
    id: uuid.UUID
    value: int
    types: GradeTypes
    created_at: datetime
    subject_name: str
    subject_id: uuid.UUID

    class Config:
        from_attributes = True