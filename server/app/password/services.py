from fastapi import HTTPException, BackgroundTasks
from datetime import datetime
from app.password.repositories import PasswordRepository
from app.password.schemas import ResetPasswordSchema, ChangePasswordSchema
from app.password.utils import hash_password, send_email
from app.password.template_email import build_reset_password_html


class PasswordService:
    def __init__(self, repo: PasswordRepository):
        self.repo = repo

    async def send_reset_code(self, email: str, background_tasks: BackgroundTasks):
        code = await self.repo.generate_reset_code(email)
        if not code:
            raise HTTPException(status_code=404, detail="Email not found")

        html_template = build_reset_password_html(code, email=email)
        background_tasks.add_task(
            send_email,
            to=email,
            subject="Cod resetare parolă",
            message=f"Codul tău de resetare este: {code}",
            html_template=html_template
        )
        return {"message": "Codul a fost trimis pe email"}

    async def reset_password(self, data: ResetPasswordSchema):
        user = await self.repo.get_user_by_email(data.email)
        if not user:
            raise HTTPException(status_code=404, detail="Email invalid")

        if (
                not user.reset_code
                or user.reset_code != data.code
                or not user.reset_code_expires
                or user.reset_code_expires < datetime.utcnow()
        ):
            raise HTTPException(status_code=400, detail="Cod invalid sau expirat")

        if user.password and user.verify_password(data.password):
            raise HTTPException(status_code=400, detail="Parola nouă nu poate fi aceeași cu cea veche")

        password_hash = hash_password(data.password)
        ok = await self.repo.reset_password(data.email, data.code, password_hash)
        if not ok:
            raise HTTPException(status_code=400, detail="Cod invalid sau email greșit")

        return {"message": "Parola a fost resetată cu succes"}

    async def send_activation_code(self, email: str, background_tasks: BackgroundTasks):
        user = await self.repo.get_user_by_email(email)
        if not user:
            raise HTTPException(status_code=404, detail="Contul nu există")

        if user.is_activated:
            return {"message": "Contul este deja activ"}

        code = await self.repo.generate_reset_code(email)
        html_template = build_reset_password_html(code, email=email)
        background_tasks.add_task(
            send_email,
            to=email,
            subject="Cod setare parolă cont nou",
            message=f"Codul tău pentru setarea parolei este: {code}",
            html_template=html_template
        )
        return {"message": "Codul pentru setarea parolei a fost trimis pe email"}

    async def set_password_for_new_account(self, data: ResetPasswordSchema):
        user = await self.repo.get_user_by_email(data.email)
        if not user or user.is_activated:
            raise HTTPException(status_code=400, detail="Contul nu există sau este deja activ")

        if (
                not user.reset_code
                or user.reset_code != data.code
                or not user.reset_code_expires
                or user.reset_code_expires < datetime.utcnow()
        ):
            raise HTTPException(status_code=400, detail="Cod invalid sau expirat")

        password_hash = hash_password(data.password)
        await self.repo.set_password_and_activate(user, password_hash)
        return {"message": "Parola a fost setată și contul activat"}

    async def change_password(self, user_id: str, data: ChangePasswordSchema):
        user = await self.repo.get_user_by_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="Utilizatorul nu a fost găsit")

        if not user.verify_password(data.current_password):
            raise HTTPException(status_code=400, detail="Parola curentă este incorectă")

        if data.current_password == data.new_password:
            raise HTTPException(status_code=400, detail="Parola nouă trebuie să fie diferită de cea curentă")

        if len(data.new_password) < 6:
            raise HTTPException(status_code=400, detail="Parola nouă trebuie să aibă minim 6 caractere")

        new_password_hash = hash_password(data.new_password)
        await self.repo.change_password(user, new_password_hash)
        return {"message": "Parola a fost schimbată cu succes"}
