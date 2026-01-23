import uuid
from typing import List
from fastapi import HTTPException, status
from app.users.repositories.user import UserRepository
from app.users.schemas.user_base import UserCreate, UserRead


class UserService:
    def __init__(self, repository: UserRepository):
        self.repository = repository

    async def get_all_users(self) -> List[UserRead]:
        return await self.repository.get_all()

    async def get_user_by_id(self, user_id: uuid.UUID) -> UserRead:
        user = await self.repository.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with id {user_id} not found",
            )
        return user

    async def check_email_exists(self, email: str) -> None:
        existing_user = await self.repository.get_by_email(email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"User with email '{email}' already exists"
            )

    async def create_user(self, user_create: UserCreate) -> UserRead:
        existing_user = await self.repository.get_by_email(str(user_create.email))
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email already exists",
            )
        return await self.repository.create(user_create)

    async def update_user(self, user_id: uuid.UUID, user_data: UserCreate) -> UserRead:
        existing_user = await self.repository.get_by_email(str(user_data.email))
        if existing_user and existing_user.id != user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"User with email '{user_data.email}' already exists"
            )
        updated_user = await self.repository.update(user_id, user_data)
        if not updated_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with id {user_id} not found",
            )
        return updated_user

    async def delete_user(self, user_id: uuid.UUID) -> None:
        deleted = await self.repository.delete(user_id)
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with id {user_id} not found",
            )
