import uuid
from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel, EmailStr

from app.users.schemas.user_base import UserRead
from app.classes.schemas import ClassSlim


class SubjectSlim(BaseModel):
    id: uuid.UUID
    name: str

    class Config:
        from_attributes = True


class TeacherBase(BaseModel):
    user_id: uuid.UUID
    subject: Optional[str]
    is_director: Optional[bool] = False
    is_homeroom: Optional[bool] = False
    class_id: Optional[uuid.UUID] = None
    school_id: Optional[uuid.UUID] = None

    class Config:
        from_attributes = True


class TeacherCreate(TeacherBase):
    username: str
    email: EmailStr


class TeacherUpdate(TeacherCreate):
    pass


class TeacherRead(TeacherBase):
    user: UserRead
    classes: list[ClassSlim] = []
    subjects: List[SubjectSlim] = []
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
