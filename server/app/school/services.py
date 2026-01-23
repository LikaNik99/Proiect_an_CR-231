import uuid
from typing import List
from fastapi import HTTPException, status

from app.school import SchoolRepository, SchoolCreate, SchoolUpdate, SchoolRead


class SchoolService:
    def __init__(self, repository: SchoolRepository):
        self.repository = repository

    async def get_all(self) -> List[SchoolRead]:
        return await self.repository.get_all()

    async def get_by_id(self, id: uuid.UUID) -> SchoolRead:
        return await self.repository.get_by_id(id)

    async def create(self, school_create: SchoolCreate) -> SchoolRead:
        school_create.name = school_create.name.strip().title()
        if school_create.phone:
            school_create.phone = school_create.phone.strip()
        return await self.repository.create(school_create)

    async def update(self, id: uuid.UUID, school_update: SchoolUpdate) -> SchoolRead:
        if school_update.name:
            school_update.name = school_update.name.strip().title()
        if school_update.phone:
            school_update.phone = school_update.phone.strip()

        return await self.repository.update(id, school_update)

    async def delete(self, id: uuid.UUID) -> bool:
        # school = await self.repository.get_by_id(id)
        return await self.repository.delete(id)
