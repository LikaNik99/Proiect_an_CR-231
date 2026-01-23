import uuid
from typing import List, Optional
from sqlalchemy import select

from app.subject.models import Subject
from app.subject.schemas import SubjectCreate, SubjectUpdate
from config.database import AsyncSession


class SubjectRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, subject_data: SubjectCreate) -> Subject:
        subject = Subject(**subject_data.model_dump())
        self.session.add(subject)
        await self.session.commit()
        await self.session.refresh(subject)
        return subject

    async def get_by_id(self, subject_id: uuid.UUID) -> Optional[Subject]:
        result = await self.session.execute(
            select(Subject).where(Subject.id == subject_id)
        )
        return result.scalar_one_or_none()

    async def get_all(self) -> List[Subject]:
        result = await self.session.execute(select(Subject))
        return list(result.scalars().all())

    async def update(self, subject_id: uuid.UUID, subject_data: SubjectUpdate) -> Optional[Subject]:
        subject = await self.get_by_id(subject_id)
        if not subject:
            return None

        update_data = subject_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(subject, field, value)

        await self.session.commit()
        await self.session.refresh(subject)
        return subject

    async def delete(self, subject_id: uuid.UUID) -> bool:
        subject = await self.get_by_id(subject_id)
        if not subject:
            return False

        await self.session.delete(subject)
        await self.session.commit()
        return True