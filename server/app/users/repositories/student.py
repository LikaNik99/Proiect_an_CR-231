import uuid
from datetime import datetime
from http.client import HTTPException
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy.exc import SQLAlchemyError, IntegrityError

from app.users.models import Student, User
from app.users.enums import UserRole
from app.users.schemas.student import StudentCreate, StudentRead
from config.database import AsyncSession


class StudentRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_all(self) -> List[StudentRead]:
        result = await self.session.execute(select(Student).options(selectinload(Student.user)))
        students = result.scalars().all()
        return [StudentRead.model_validate(student) for student in students]

    async def get_by_id(self, student_id: uuid.UUID) -> Optional[StudentRead]:
        result = await self.session.execute(
            select(Student).options(selectinload(Student.user)).where(Student.user_id == student_id)
        )
        student = result.scalars().first()
        return StudentRead.model_validate(student) if student else None

    async def create(self, student_create: StudentCreate) -> StudentRead:
        try:
            async with self.session.begin():
                user = User(
                    id=uuid.uuid4(),
                    username=student_create.username,
                    email=str(student_create.email),
                    role=UserRole.STUDENT,
                    school_id=student_create.school_id,
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow(),
                )
                self.session.add(user)
                await self.session.flush()
                student = Student(
                    user_id=user.id,
                    class_id=student_create.class_id,
                )
                self.session.add(student)
            await self.session.refresh(student)
            return StudentRead.model_validate(student)

        except Exception as e:
            await self.session.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Unexpected error: {str(e)}"
            )

    async def update(self, student_id: uuid.UUID, student_data: StudentCreate) -> StudentRead:
        try:
            async with self.session.begin():
                result = await self.session.execute(
                    select(Student).options(selectinload(Student.user))
                    .where(Student.user_id == student_id)
                )
                student = result.scalars().first()
                if not student:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail=f"Student with id {student_id} not found"
                    )
                if student_data.username:
                    student.user.username = student_data.username
                if student_data.email:
                    student.user.email = str(student_data.email)
                if student_data.class_id is not None:
                    student.class_id = student_data.class_id
                if student_data.school_id is not None:
                    student.school_id = student_data.school_id

            await self.session.refresh(student)
            return StudentRead.model_validate(student)

        except IntegrityError as e:
            await self.session.rollback()
            msg = str(e.orig)
            if "users_email_key" in msg or "Key (email)" in msg:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Email '{student_data.email}' already exists."
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to update student: {msg}"
            )

        except SQLAlchemyError as e:
            await self.session.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to update student: {str(e)}"
            )

    async def delete(self, student_id: uuid.UUID) -> bool:
        try:
            async with self.session.begin():
                result = await self.session.execute(select(Student).where(Student.user_id == student_id))
                student = result.scalars().first()
                if not student:
                    return False
                await self.session.delete(student)
            return True
        except SQLAlchemyError:
            await self.session.rollback()
            return False
