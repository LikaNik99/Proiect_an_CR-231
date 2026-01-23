from fastapi import APIRouter, Depends
from typing import List
import uuid

from app.school import SchoolService, SchoolRepository, SchoolRead, SchoolCreate, SchoolUpdate
from config.database import AsyncSession, get_db
from config.dependences import admin_required

router = APIRouter(prefix="/schools", tags=["Schools"])


async def get_school_service(session: AsyncSession = Depends(get_db)) -> SchoolService:
    repository = SchoolRepository(session)
    return SchoolService(repository)


@router.get("/", response_model=List[SchoolRead], dependencies=[Depends(admin_required)])
async def list_schools(service: SchoolService = Depends(get_school_service)):
    return await service.get_all()


@router.get("/{school_id}", response_model=SchoolRead, dependencies=[Depends(admin_required)])
async def get_school(school_id: uuid.UUID, service: SchoolService = Depends(get_school_service)):
    return await service.get_by_id(school_id)


@router.post("/", response_model=SchoolRead, dependencies=[Depends(admin_required)])
async def create_school(school_data: SchoolCreate, service: SchoolService = Depends(get_school_service)):
    return await service.create(school_data)


@router.put("/{school_id}", response_model=SchoolRead, dependencies=[Depends(admin_required)])
async def update_school(school_id: uuid.UUID, school_update: SchoolUpdate,
                        service: SchoolService = Depends(get_school_service)):
    return await service.update(school_id, school_update)


@router.delete("/{school_id}", dependencies=[Depends(admin_required)])
async def delete_school(school_id: uuid.UUID, service: SchoolService = Depends(get_school_service)):
    return await service.delete(school_id)
