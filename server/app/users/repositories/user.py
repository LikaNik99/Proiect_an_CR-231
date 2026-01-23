import uuid
from datetime import datetime

from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError
from app.users.models import User
from app.users.schemas.user_base import UserCreate, UserRead
from config.database import AsyncSession


class UserRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_all(self) -> list[UserRead]:
        result = await self.session.execute(select(User))
        users = result.scalars().all()
        return [UserRead.model_validate(user) for user in users]

    async def get_by_id(self, user_id: uuid.UUID) -> UserRead | None:
        result = await self.session.execute(select(User).where(User.id == user_id))
        user = result.scalars().first()
        return UserRead.model_validate(user) if user else None

    async def get_by_email(self, email: str) -> UserRead | None:
        result = await self.session.execute(select(User).where(User.email == email))
        user = result.scalars().first()
        return UserRead.model_validate(user) if user else None

    async def create(self, user_create: UserCreate) -> UserRead:
        user = User(
            username=user_create.username,
            email=str(user_create.email),
            role=user_create.role,
            school_id=user_create.school_id,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        self.session.add(user)
        try:
            await self.session.commit()
        except IntegrityError:
            await self.session.rollback()
            raise
        await self.session.refresh(user)
        return UserRead.model_validate(user)

    async def update(self, user_id: uuid.UUID, data: UserCreate) -> UserRead | None:
        result = await self.session.execute(select(User).where(User.id == user_id))
        user = result.scalars().first()
        if not user:
            return None

        user.username = data.username
        user.email = data.email
        user.role = data.role
        user.school_id = data.school_id
        await self.session.commit()
        await self.session.refresh(user)
        return UserRead.model_validate(user)

    async def delete(self, user_id: uuid.UUID) -> bool:
        result = await self.session.execute(select(User).where(User.id == user_id))
        user = result.scalars().first()
        if not user:
            return False
        await self.session.delete(user)
        await self.session.commit()
        return True
