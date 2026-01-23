import uuid
from typing import List, Tuple
from fastapi import HTTPException, status

from app.grade.models import GradeModel
from app.grade.repository import GradeRepository
from app.grade.schemas import GradeCreate, GradeUpdate
from config.pagination import create_paginated_response


class GradeService:
    def __init__(self, repository: GradeRepository):
        self.repository = repository

    async def create_grade(self, grade_data: GradeCreate) -> GradeModel:
        return await self.repository.create(grade_data)

    async def get_grade(self, grade_id: uuid.UUID) -> GradeModel:
        grade = await self.repository.get_by_id(grade_id)
        if not grade:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Grade with id {grade_id} not found"
            )
        return grade

    async def get_all_grades(self, skip: int = 0, limit: int = 20) -> dict:
        items, total = await self.repository.get_all(skip, limit)
        return create_paginated_response(items, total, skip, limit)

    async def get_student_grades(self, student_id: uuid.UUID, skip: int = 0, limit: int = 100) -> Tuple[List[GradeModel], int]:
        return await self.repository.get_by_student(student_id, skip, limit)

    async def get_teacher_grades(self, teacher_id: uuid.UUID, skip: int = 0, limit: int = 100) -> Tuple[List[GradeModel], int]:
        return await self.repository.get_by_teacher(teacher_id, skip, limit)

    async def get_subject_grades(self, subject_id: uuid.UUID, skip: int = 0, limit: int = 100) -> Tuple[List[GradeModel], int]:
        return await self.repository.get_by_subject(subject_id, skip, limit)

    async def update_grade(self, grade_id: uuid.UUID, grade_data: GradeUpdate) -> GradeModel:
        grade = await self.repository.update(grade_id, grade_data)
        if not grade:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Grade with id {grade_id} not found"
            )
        return grade

    async def delete_grade(self, grade_id: uuid.UUID) -> None:
        success = await self.repository.delete(grade_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Grade with id {grade_id} not found"
            )
