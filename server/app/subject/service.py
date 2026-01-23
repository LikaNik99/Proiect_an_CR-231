import uuid
from typing import List
from fastapi import HTTPException, status

from app.subject.models import Subject
from app.subject.repository import SubjectRepository
from app.subject.schemas import SubjectCreate, SubjectUpdate


class SubjectService:
    def __init__(self, repository: SubjectRepository):
        self.repository = repository

    async def create_subject(self, subject_data: SubjectCreate) -> Subject:
        return await self.repository.create(subject_data)

    async def get_subject(self, subject_id: uuid.UUID) -> Subject:
        subject = await self.repository.get_by_id(subject_id)
        if not subject:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Subject with id {subject_id} not found"
            )
        return subject

    async def get_all_subjects(self) -> List[Subject]:
        return await self.repository.get_all()

    async def update_subject(self, subject_id: uuid.UUID, subject_data: SubjectUpdate) -> Subject:
        subject = await self.repository.update(subject_id, subject_data)
        if not subject:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Subject with id {subject_id} not found"
            )
        return subject

    async def delete_subject(self, subject_id: uuid.UUID) -> None:
        success = await self.repository.delete(subject_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Subject with id {subject_id} not found"
            )