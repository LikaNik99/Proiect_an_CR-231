from __future__ import annotations



from datetime import datetime

from typing import Optional

from uuid import UUID



from pydantic import BaseModel





class ClassBase(BaseModel):

    name: str

    school_id: UUID



    model_config = {"from_attributes": True}





class ClassCreate(ClassBase):

    pass





class ClassUpdate(BaseModel):

    name: Optional[str] = None

    school_id: Optional[UUID] = None





class ClassOut(ClassBase):

    id: UUID

    created_at: datetime

    updated_at: datetime



    model_config = {"from_attributes": True}





class SubjectSlim(BaseModel):

    id: UUID

    name: str



    model_config = {"from_attributes": True}





class ClassSlim(BaseModel):

    """Lightweight class representation for embedding in other schemas."""



    id: UUID

    name: str

    school_id: UUID

    teacher_id: Optional[UUID] = None

    subjects: list[SubjectSlim] = []



    model_config = {"from_attributes": True}



