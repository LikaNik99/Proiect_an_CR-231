import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class MaterialBase(BaseModel):
    title: str
    description: Optional[str] = None
    file_url: str
    file_name: str
    file_size: Optional[int] = None
    subject_id: uuid.UUID
    class_id: uuid.UUID
    teacher_id: uuid.UUID


class MaterialCreate(MaterialBase):
    pass


class MaterialUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None


class SubjectInfo(BaseModel):
    id: uuid.UUID
    name: str

    class Config:
        from_attributes = True


class TeacherInfo(BaseModel):
    user_id: uuid.UUID
    first_name: str
    last_name: str

    class Config:
        from_attributes = True


class MaterialRead(MaterialBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime
    subject: Optional[SubjectInfo] = None
    teacher: Optional[TeacherInfo] = None

    class Config:
        from_attributes = True