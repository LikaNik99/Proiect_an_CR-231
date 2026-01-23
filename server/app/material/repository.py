import uuid
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from app.material.models import Material
from app.material.schemas import MaterialCreate, MaterialUpdate
from config.database import AsyncSession


class MaterialRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, material_data: MaterialCreate) -> Material:
        material = Material(**material_data.model_dump())
        self.session.add(material)
        await self.session.commit()
        await self.session.refresh(material)
        return material

    async def get_by_id(self, material_id: uuid.UUID) -> Optional[Material]:
        result = await self.session.execute(
            select(Material)
            .options(joinedload(Material.subject), joinedload(Material.teacher))
            .where(Material.id == material_id)
        )
        return result.scalar_one_or_none()

    async def get_by_class(self, class_id: uuid.UUID) -> List[Material]:
        result = await self.session.execute(
            select(Material)
            .options(joinedload(Material.subject), joinedload(Material.teacher))
            .where(Material.class_id == class_id)
            .order_by(Material.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_by_subject(self, subject_id: uuid.UUID) -> List[Material]:
        result = await self.session.execute(
            select(Material)
            .options(joinedload(Material.subject), joinedload(Material.teacher))
            .where(Material.subject_id == subject_id)
            .order_by(Material.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_by_teacher(self, teacher_id: uuid.UUID) -> List[Material]:
        result = await self.session.execute(
            select(Material)
            .options(joinedload(Material.subject), joinedload(Material.teacher))
            .where(Material.teacher_id == teacher_id)
            .order_by(Material.created_at.desc())
        )
        return list(result.scalars().all())

    async def update(self, material_id: uuid.UUID, material_data: MaterialUpdate) -> Optional[Material]:
        material = await self.get_by_id(material_id)
        if not material:
            return None

        update_data = material_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(material, field, value)

        await self.session.commit()
        await self.session.refresh(material)
        return material

    async def delete(self, material_id: uuid.UUID) -> bool:
        material = await self.get_by_id(material_id)
        if not material:
            return False

        await self.session.delete(material)
        await self.session.commit()
        return True
