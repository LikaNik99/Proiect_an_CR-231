import random
from datetime import datetime, timedelta

from sqlalchemy import select
from app.users.models import User
from config.database import AsyncSession


class PasswordRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def generate_reset_code(self, email: str) -> int | None:
        result = await self.session.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        if not user:
            return None

        code = random.randint(100000, 999999)
        user.reset_code = code
        user.reset_code_expires = datetime.utcnow() + timedelta(minutes=5)
        await self.session.commit()
        return code

    async def reset_password(self, email: str, code: int, password_hash: str) -> bool:
        result = await self.session.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        if (
                not user
                or user.reset_code != code
                or not user.reset_code_expires
                or user.reset_code_expires < datetime.utcnow()
        ):
            return False

        user.password = password_hash
        user.reset_code = None
        user.reset_code_expires = None
        await self.session.commit()
        return True

    async def get_user_by_email(self, email: str) -> User | None:
        result = await self.session.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def set_password_and_activate(self, user: User, password_hash: str):
        user.password = password_hash
        user.is_activated = True
        user.reset_code = None
        user.reset_code_expires = None
        await self.session.commit()

    async def get_user_by_id(self, user_id: str) -> User | None:
        from uuid import UUID
        result = await self.session.execute(select(User).where(User.id == UUID(user_id)))
        return result.scalar_one_or_none()

    async def change_password(self, user: User, new_password_hash: str) -> bool:
        user.password = new_password_hash
        await self.session.commit()
        return True
