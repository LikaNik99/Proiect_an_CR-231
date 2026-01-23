import uuid
from typing import List, Optional
from fastapi import HTTPException, status

from app.users.repositories import StudentRepository
from app.users.schemas.student import StudentCreate, StudentRead


class StudentService:
    def __init__(self, repository: StudentRepository):
        self.repository = repository

    async def get_all_students(self) -> List[StudentRead]:
        students = await self.repository.get_all()
        if not students:
            return []
        return students

    async def get_student_by_id(self, student_id: uuid.UUID):
        student = await self.repository.get_by_id(student_id)
        if not student:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Student with id {student_id} not found",
            )
        return student

    async def create_student(self, student_create: StudentCreate) -> StudentRead:
        return await self.repository.create(student_create)

    async def delete_student(self, student_id: uuid.UUID) -> None:
        deleted = await self.repository.delete(student_id)
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Student with id {student_id} not found",
            )

    async def update_student(
            self, student_id: uuid.UUID, student_data: StudentCreate
    ) -> StudentRead:
        student = await self.repository.update(student_id, student_data)
        if not student:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Student with id {student_id} not found",
            )
        return student
