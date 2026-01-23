import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr

from app.users.schemas.user_base import UserRead


class StudentBase(BaseModel):
    user_id: uuid.UUID
    class_id: Optional[uuid.UUID] = None

    class Config:
        from_attributes = True


class StudentCreate(BaseModel):
    username: str
    email: EmailStr
    class_id: uuid.UUID
    school_id: uuid.UUID


class StudentUpdate(StudentCreate):
    pass


class StudentRead(StudentBase):
    user_id: uuid.UUID
    user: Optional[UserRead]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
