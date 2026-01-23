import uuid
from doctest import Example
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError

from app.users.repositories.teacher import TeacherRepository
from app.users.repositories.user import UserRepository
from app.users.schemas import TeacherRead
from app.users.schemas.teacher import TeacherCreate, TeacherRead, TeacherUpdate


class TeacherService:
    def __init__(self, repository: TeacherRepository, user_repository: UserRepository):
        self.repository = repository
        self.user_repository = user_repository

    async def get_all_teachers(self, skip: int = 0, limit: int = 100, q: Optional[str] = None) -> List[TeacherRead]:
        teachers = await self.repository.get_all(skip=skip, limit=limit, q=q)
        if not teachers:
            return []
        return teachers

    async def get_teacher_by_id(self, teacher_id: uuid.UUID) -> TeacherRead:
        teacher = await self.repository.get_by_id(teacher_id)
        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Teacher with id {teacher_id} not found",
            )
        return teacher

    async def get_teacher_by_user_id(self, user_id: uuid.UUID) -> TeacherRead:
        teacher = await self.repository.get_by_id(user_id)
        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Teacher for user_id {user_id} not found",
            )
        return teacher

    async def create_teacher(self, teacher_create: TeacherCreate) -> TeacherRead:
        existing_teacher = await self.repository.get_by_user_id(
            teacher_create.user_id
        )

        if existing_teacher:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Teacher with this user already exists",
            )

        return await self.repository.create(teacher_create)

    async def update_teacher(
            self,
            teacher_id: uuid.UUID,
            teacher_data: TeacherUpdate,
    ) -> TeacherRead:

        if teacher_data.email is not None:
            existing_user = await self.user_repository.get_by_email(
                email=str(teacher_data.email)
            )

            if existing_user and existing_user.id != teacher_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User with this email already exists",
                )

        try:
            updated = await self.repository.update(teacher_id, teacher_data)

            if not updated:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Teacher with id {teacher_id} not found",
                )

            return updated

        except IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email already exists",
            )

    async def delete_teacher(self, teacher_id: uuid.UUID) -> None:
        deleted = await self.repository.delete(teacher_id)
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Teacher with id {teacher_id} not found",
            )

    async def get_students_for_teacher(self, teacher_id: uuid.UUID):
        return await self.repository.get_students_for_teacher(teacher_id)
