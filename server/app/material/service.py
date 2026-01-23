import uuid
from typing import List
from fastapi import HTTPException, status

from app.material.models import Material
from app.material.repository import MaterialRepository
from app.material.schemas import MaterialCreate, MaterialUpdate


class MaterialService:
    def __init__(self, repository: MaterialRepository):
        self.repository = repository

    async def create_material(self, material_data: MaterialCreate) -> Material:
        return await self.repository.create(material_data)

    async def get_material(self, material_id: uuid.UUID) -> Material:
        material = await self.repository.get_by_id(material_id)
        if not material:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Material with id {material_id} not found"
            )
        return material

    async def get_class_materials(self, class_id: uuid.UUID) -> List[Material]:
        return await self.repository.get_by_class(class_id)

    async def get_subject_materials(self, subject_id: uuid.UUID) -> List[Material]:
        return await self.repository.get_by_subject(subject_id)

    async def get_teacher_materials(self, teacher_id: uuid.UUID) -> List[Material]:
        return await self.repository.get_by_teacher(teacher_id)

    async def update_material(self, material_id: uuid.UUID, material_data: MaterialUpdate) -> Material:
        material = await self.repository.update(material_id, material_data)
        if not material:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Material with id {material_id} not found"
            )
        return material

    async def delete_material(self, material_id: uuid.UUID) -> None:
        success = await self.repository.delete(material_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Material with id {material_id} not found"
            )
