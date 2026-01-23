from pydantic import BaseModel, EmailStr


class ResetPasswordSchema(BaseModel):
    email: EmailStr
    code: int
    password: str


class SendResetCodeSchema(BaseModel):
    email: EmailStr


class ChangePasswordSchema(BaseModel):
    current_password: str
    new_password: str
