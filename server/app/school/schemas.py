from pydantic import BaseModel, EmailStr, HttpUrl
from typing import Optional, List
import uuid
from datetime import datetime


class SchoolBase(BaseModel):
    name: str
    location: str
    phone: Optional[str]
    email: Optional[EmailStr]
    website: Optional[HttpUrl]
    logo_url: Optional[HttpUrl]
    established_year: Optional[int]
    is_active: Optional[bool] = True


class SchoolCreate(SchoolBase):
    pass


class SchoolUpdate(SchoolBase):
    pass


class SchoolRead(SchoolBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = {
        "from_attributes": True
    }
