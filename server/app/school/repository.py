import uuid
from typing import List
from fastapi import HTTPException, status
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from app.school import SchoolRead, School, SchoolCreate, SchoolUpdate
from config.database import AsyncSession


class SchoolRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_all(self) -> List[SchoolRead]:
        result = await self.session.execute(select(School))
        schools = result.scalars().all()
        return [SchoolRead.model_validate(s) for s in schools]

    async def get_by_id(self, id: uuid.UUID) -> SchoolRead:
        result = await self.session.execute(
            select(School)
            .where(School.id == id)
            .options(selectinload(School.classes), selectinload(School.users))
        )
        school = result.scalars().first()
        if not school:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="School not found")
        return SchoolRead.model_validate(school)

    async def create(self, school_create: SchoolCreate) -> SchoolRead:
        result = await self.session.execute(select(School).where(School.email == school_create.email))
        existing_school = result.scalars().first()
        if existing_school:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already exists")

        school = School(
            name=school_create.name,
            location=school_create.location,
            phone=school_create.phone,
            email=school_create.email,
            website=str(school_create.website),
            logo_url=str(school_create.logo_url),
            established_year=school_create.established_year,
            is_active=school_create.is_active,
        )
        self.session.add(school)
        await self.session.commit()
        await self.session.refresh(school)
        return SchoolRead.model_validate(school)

    async def update(self, id: uuid.UUID, school_update: SchoolUpdate) -> SchoolRead:
        result = await self.session.execute(select(School).where(School.id == id))
        school = result.scalars().first()
        if not school:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="School not found")

        update_data = school_update.model_dump(exclude_unset=True)
        if 'email' in update_data and update_data['email']:
            existing_email = await self.session.execute(
                select(School).where(School.email == update_data['email'], School.id != id)
            )
            if existing_email.scalars().first():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Another school with this email already exists"
                )
        for field in ['website', 'logo_url']:
            if field in update_data and update_data[field] is not None:
                update_data[field] = str(update_data[field])

        for key, value in update_data.items():
            setattr(school, key, value)

        await self.session.commit()
        await self.session.refresh(school)
        return SchoolRead.model_validate(school)

    async def delete(self, id: uuid.UUID) -> bool:
        result = await self.session.execute(
            select(School)
            .where(School.id == id)
        )
        school = result.scalars().first()
        if not school:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="School not found")

        await self.session.delete(school)
        await self.session.commit()
        return True
