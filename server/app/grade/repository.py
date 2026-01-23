import uuid
from typing import List, Optional, Tuple
from sqlalchemy import select, func
from sqlalchemy.orm import joinedload
from datetime import datetime

from app.grade.models import GradeModel
from app.grade.schemas import GradeCreate, GradeUpdate
from config.database import AsyncSession


class GradeRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, grade_data: GradeCreate) -> GradeModel:
        grade = GradeModel(**grade_data.model_dump())

        if getattr(grade, 'created_at', None) is None:
            grade.created_at = datetime.utcnow()
        if getattr(grade, 'updated_at', None) is None:
            grade.updated_at = datetime.utcnow()

        self.session.add(grade)
        await self.session.commit()

        result = await self.session.execute(
            select(GradeModel)
            .options(joinedload(GradeModel.subject))
            .where(GradeModel.id == grade.id)
        )
        return result.scalar_one()

    async def get_by_id(self, grade_id: uuid.UUID) -> Optional[GradeModel]:
        result = await self.session.execute(
            select(GradeModel)
            .options(joinedload(GradeModel.subject))
            .where(GradeModel.id == grade_id)
        )
        return result.scalar_one_or_none()

    async def get_all(self, skip: int = 0, limit: int = 100) -> Tuple[List[GradeModel], int]:
        # Get total count
        count_result = await self.session.execute(select(func.count(GradeModel.id)))
        total = count_result.scalar()

        # Get paginated results
        result = await self.session.execute(
            select(GradeModel)
            .options(joinedload(GradeModel.subject))
            .order_by(GradeModel.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all()), total

    async def get_by_student(self, student_id: uuid.UUID, skip: int = 0, limit: int = 100) -> Tuple[
        List[GradeModel], int]:
        # Get total count
        count_result = await self.session.execute(
            select(func.count(GradeModel.id)).where(GradeModel.student_id == student_id)
        )
        total = count_result.scalar()

        # Get paginated results
        result = await self.session.execute(
            select(GradeModel)
            .options(joinedload(GradeModel.subject))
            .where(GradeModel.student_id == student_id)
            .order_by(GradeModel.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all()), total

    async def get_by_teacher(self, teacher_id: uuid.UUID, skip: int = 0, limit: int = 100) -> Tuple[
        List[GradeModel], int]:
        count_result = await self.session.execute(
            select(func.count(GradeModel.id)).where(GradeModel.teacher_id == teacher_id)
        )
        total = count_result.scalar()

        result = await self.session.execute(
            select(GradeModel)
            .options(joinedload(GradeModel.subject))
            .where(GradeModel.teacher_id == teacher_id)
            .order_by(GradeModel.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all()), total

    async def get_by_subject(self, subject_id: uuid.UUID, skip: int = 0, limit: int = 100) -> Tuple[
        List[GradeModel], int]:
        count_result = await self.session.execute(
            select(func.count(GradeModel.id)).where(GradeModel.subject_id == subject_id)
        )
        total = count_result.scalar()

        result = await self.session.execute(
            select(GradeModel)
            .options(joinedload(GradeModel.subject))
            .where(GradeModel.subject_id == subject_id)
            .order_by(GradeModel.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all()), total

    async def update(self, grade_id: uuid.UUID, grade_data: GradeUpdate) -> Optional[GradeModel]:
        grade = await self.get_by_id(grade_id)
        if not grade:
            return None

        update_data = grade_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(grade, field, value)

        await self.session.commit()
        await self.session.refresh(grade)
        return grade

    async def delete(self, grade_id: uuid.UUID) -> bool:
        grade = await self.get_by_id(grade_id)
        if not grade:
            return False

        await self.session.delete(grade)
        await self.session.commit()
        return True
