import uuid
from typing import List
from fastapi import APIRouter, Depends, status

from app.schedule.repository import ScheduleRepository
from app.schedule.schemas import ScheduleCreate, ScheduleRead, ScheduleUpdate
from app.schedule.service import ScheduleService
from config.database import AsyncSession, get_db
from config.dependences import get_current_user, admin_required

router = APIRouter(prefix="/schedules", tags=["Schedules"])


async def get_schedule_service(session: AsyncSession = Depends(get_db)) -> ScheduleService:
    repository = ScheduleRepository(session)
    return ScheduleService(repository)


@router.post("/", response_model=ScheduleRead, status_code=status.HTTP_201_CREATED)
async def create_schedule(
    schedule_data: ScheduleCreate,
    current_user: dict = Depends(get_current_user),
    service: ScheduleService = Depends(get_schedule_service)
):
    return await service.create_schedule(schedule_data)


@router.get("/class/{class_id}", response_model=List[ScheduleRead])
async def get_class_schedule(
    class_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: ScheduleService = Depends(get_schedule_service)
):
    return await service.get_class_schedule(class_id)


@router.get("/teacher/{teacher_id}", response_model=List[ScheduleRead])
async def get_teacher_schedule(
    teacher_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: ScheduleService = Depends(get_schedule_service)
):
    """Get all schedules for a specific teacher"""
    return await service.get_teacher_schedule(teacher_id)


@router.get("/{schedule_id}", response_model=ScheduleRead)
async def get_schedule(
    schedule_id: uuid.UUID,
        service: ScheduleService = Depends(get_schedule_service)
):
    return await service.get_schedule(schedule_id)


@router.put("/{schedule_id}", response_model=ScheduleRead)
async def update_schedule(
    schedule_id: uuid.UUID,
    schedule_data: ScheduleUpdate,
    current_user: dict = Depends(get_current_user),
    service: ScheduleService = Depends(get_schedule_service)
):
    return await service.update_schedule(schedule_id, schedule_data)


@router.delete("/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_schedule(
    schedule_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    service: ScheduleService = Depends(get_schedule_service)
):
    await service.delete_schedule(schedule_id)