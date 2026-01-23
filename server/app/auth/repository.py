from sqlalchemy.future import select



from app.users.models import User

from app.users.enums import UserRole

from config.database import AsyncSession

from pydantic import EmailStr





class AuthRepository:

    def __init__(self, session: AsyncSession):

        self.session = session



    async def get_by_email(self, email: EmailStr) -> User | None:

        result = await self.session.execute(select(User).where(User.email == email))

        return result.scalars().first()



    async def create_user(self, username: str, email: str, role: UserRole) -> User:

        user = User(username=username, email=email, role=role, is_activated=False)

        self.session.add(user)

        await self.session.commit()

        await self.session.refresh(user)

        return user



    async def activate_user(self, user: User, password: str) -> User:

        user.password = password

        user.is_activated = True

        await self.session.commit()

        await self.session.refresh(user)

        return user



    async def set_password(self, user: User, password: str) -> User:

        user.password = password

        await self.session.commit()

        await self.session.refresh(user)

        return user



