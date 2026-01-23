import uuid
from typing import List
from fastapi import APIRouter, Depends, status

from app.subject.repository import SubjectRepository
from app.subject.schemas import SubjectCreate, SubjectRead, SubjectUpdate
from app.subject.service import SubjectService
from config.database import AsyncSession, get_db
from config.dependences import get_current_user, admin_required

router = APIRouter(prefix="/subjects", tags=["Subjects"])


async def get_subject_service(session: AsyncSession = Depends(get_db)) -> SubjectService:
    repository = SubjectRepository(session)
    return SubjectService(repository)


@router.post("/", response_model=SubjectRead, status_code=status.HTTP_201_CREATED, dependencies=[Depends(admin_required)])
async def create_subject(
    subject_data: SubjectCreate,
    service: SubjectService = Depends(get_subject_service)
):
    """Create a new subject (Admin only)"""
    return await service.create_subject(subject_data)


@router.get("/", response_model=List[SubjectRead])
async def get_all_subjects(
    current_user: dict = Depends(get_current_user),
    service: SubjectService = Depends(get_subject_service)
):
    """Get all subjects"""
    return await service.get_all_subjects()


@router.get("/{subject_id}", response_model=SubjectRead)
async def get_subject(
    subject_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: SubjectService = Depends(get_subject_service)
):
    """Get a specific subject by ID"""
    return await service.get_subject(subject_id)


@router.put("/{subject_id}", response_model=SubjectRead, dependencies=[Depends(admin_required)])
async def update_subject(
    subject_id: uuid.UUID,
    subject_data: SubjectUpdate,
    service: SubjectService = Depends(get_subject_service)
):
    """Update a subject (Admin only)"""
    return await service.update_subject(subject_id, subject_data)


@router.delete("/{subject_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(admin_required)])
async def delete_subject(
    subject_id: uuid.UUID,
    service: SubjectService = Depends(get_subject_service)
):
    """Delete a subject (Admin only)"""
    await service.delete_subject(subject_id)