import uuid

from enum import Enum



from pydantic import BaseModel, EmailStr, Field

from typing import Optional



from app.users.enums import UserRole





class EmailCheckRequest(BaseModel):

    email: EmailStr





class AccountStatus(str, Enum):

    NOT_FOUND = "not_found"

    INACTIVE = "inactive"

    ACTIVE = "active"





class EmailCheckResponse(BaseModel):

    exists: bool = Field(default=False)

    is_active: bool = Field(default=False)

    status: AccountStatus = Field(default=AccountStatus.NOT_FOUND)

    role: Optional[UserRole] = None





class UserCreatePasswordRequest(BaseModel):

    email: EmailStr

    password: str





class UserLoginRequest(BaseModel):

    email: EmailStr

    password: str





class RegisterRequest(BaseModel):

    username: str = Field(..., min_length=3)

    email: EmailStr

    role: UserRole

    school_id: Optional[uuid.UUID] = None





class AuthResponse(BaseModel):

    id: uuid.UUID

    username: str

    email: EmailStr

    role: UserRole

    is_activated: bool

    access_token: Optional[str] = None

    refresh_token: Optional[str] = None



    class Config:

        from_attributes = True





class RefreshTokenRequest(BaseModel):

    refresh_token: str





class RefreshTokenResponse(BaseModel):

    access_token: str

    refresh_token: str





class LogoutRequest(BaseModel):

    refresh_token: Optional[str] = None

