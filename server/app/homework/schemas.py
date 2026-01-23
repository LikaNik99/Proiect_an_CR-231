import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel

from app.homework.models import HomeworkStatus


class HomeworkBase(BaseModel):
    title: str
    description: Optional[str] = None
    due_date: datetime
    subject_id: uuid.UUID
    class_id: uuid.UUID
    teacher_id: uuid.UUID


class HomeworkCreate(HomeworkBase):
    # NEW: if provided -> homework is for these students only
    student_ids: Optional[List[uuid.UUID]] = None


class HomeworkUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    status: Optional[HomeworkStatus] = None


class SubjectInfo(BaseModel):
    id: uuid.UUID
    name: str

    class Config:
        from_attributes = True


class HomeworkRead(HomeworkBase):
    id: uuid.UUID
    status: HomeworkStatus
    created_at: datetime
    subject: Optional[SubjectInfo] = None

    # NEW: helps clients distinguish class-wide vs personal homework
    assigned_student_ids: List[uuid.UUID] = []
    is_personal: bool = False

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm_with_assignments(hw: "Homework") -> "HomeworkRead":
        # helper: build read model including assignments without relying on pydantic to traverse relationships
        data = {
            "id": hw.id,
            "title": hw.title,
            "description": hw.description,
            "due_date": hw.due_date,
            "subject_id": hw.subject_id,
            "class_id": hw.class_id,
            "teacher_id": hw.teacher_id,
            "status": hw.status,
            "created_at": hw.created_at,
            "subject": hw.subject,
            "assigned_student_ids": [a.student_id for a in getattr(hw, "assignments", []) or []],
        }
        data["is_personal"] = len(data["assigned_student_ids"]) > 0
        return HomeworkRead.model_validate(data)
