import uuid
from typing import List
from fastapi import APIRouter, Depends, status

from app.material.repository import MaterialRepository
from app.material.schemas import MaterialCreate, MaterialRead, MaterialUpdate
from app.material.service import MaterialService
from config.database import AsyncSession, get_db
from config.dependences import get_current_user

router = APIRouter(prefix="/materials", tags=["Materials"])


async def get_material_service(session: AsyncSession = Depends(get_db)) -> MaterialService:
    repository = MaterialRepository(session)
    return MaterialService(repository)


@router.post("/", response_model=MaterialRead, status_code=status.HTTP_201_CREATED)
async def create_material(
    material_data: MaterialCreate,
    current_user: dict = Depends(get_current_user),
    service: MaterialService = Depends(get_material_service)
):
    return await service.create_material(material_data)


@router.get("/class/{class_id}", response_model=List[MaterialRead])
async def get_class_materials(
    class_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: MaterialService = Depends(get_material_service)
):
    return await service.get_class_materials(class_id)


@router.get("/subject/{subject_id}", response_model=List[MaterialRead])
async def get_subject_materials(
    subject_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: MaterialService = Depends(get_material_service)
):
    return await service.get_subject_materials(subject_id)


@router.get("/teacher/{teacher_id}", response_model=List[MaterialRead])
async def get_teacher_materials(
    teacher_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: MaterialService = Depends(get_material_service)
):
    return await service.get_teacher_materials(teacher_id)


@router.get("/{material_id}", response_model=MaterialRead)
async def get_material(
    material_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: MaterialService = Depends(get_material_service)
):
    return await service.get_material(material_id)


@router.put("/{material_id}", response_model=MaterialRead)
async def update_material(
    material_id: uuid.UUID,
    material_data: MaterialUpdate,
    current_user: dict = Depends(get_current_user),
    service: MaterialService = Depends(get_material_service)
):
    return await service.update_material(material_id, material_data)


@router.delete("/{material_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_material(
    material_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: MaterialService = Depends(get_material_service)
):
    await service.delete_material(material_id)
