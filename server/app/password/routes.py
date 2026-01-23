# app/password/router.py
from fastapi import APIRouter, Depends, BackgroundTasks
from config.database import get_db
from config.dependences import get_current_user
from app.password.repositories import PasswordRepository
from app.password.schemas import SendResetCodeSchema, ResetPasswordSchema, ChangePasswordSchema
from app.password.services import PasswordService

router = APIRouter(prefix="/password", tags=["Password"])


@router.post("/send-code")
async def send_code(data: SendResetCodeSchema, background_tasks: BackgroundTasks, session=Depends(get_db)):
    service = PasswordService(PasswordRepository(session))
    return await service.send_reset_code(data.email, background_tasks)


@router.post("/reset")
async def reset_password(data: ResetPasswordSchema, session=Depends(get_db)):
    service = PasswordService(PasswordRepository(session))
    return await service.reset_password(data)


@router.post("/send-activation-code")
async def send_activation_code(data: SendResetCodeSchema, background_tasks: BackgroundTasks, session=Depends(get_db)):
    service = PasswordService(PasswordRepository(session))
    return await service.send_activation_code(data.email, background_tasks)


@router.post("/set-password")
async def set_password(data: ResetPasswordSchema, session=Depends(get_db)):
    service = PasswordService(PasswordRepository(session))
    return await service.set_password_for_new_account(data)


@router.post("/change")
async def change_password(
    data: ChangePasswordSchema,
    current_user: dict = Depends(get_current_user),
    session=Depends(get_db)
):
    service = PasswordService(PasswordRepository(session))
    return await service.change_password(current_user.get("id"), data)
