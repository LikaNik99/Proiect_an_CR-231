import uuid
from pydantic import BaseModel


class SubjectBase(BaseModel):
    name: str


class SubjectCreate(SubjectBase):
    pass


class SubjectUpdate(SubjectBase):
    pass


class SubjectRead(SubjectBase):
    id: uuid.UUID

    class Config:
        from_attributes = True