import uuid
from typing import List
from fastapi import HTTPException, status

from app.schedule.models import Schedule
from app.schedule.repository import ScheduleRepository
from app.schedule.schemas import ScheduleCreate, ScheduleUpdate


class ScheduleService:
    def __init__(self, repository: ScheduleRepository):
        self.repository = repository

    async def create_schedule(self, schedule_data: ScheduleCreate) -> Schedule:
        return await self.repository.create(schedule_data)

    async def get_schedule(self, schedule_id: uuid.UUID) -> Schedule:
        schedule = await self.repository.get_by_id(schedule_id)
        if not schedule:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Schedule with id {schedule_id} not found"
            )
        return schedule

    async def get_class_schedule(self, class_id: uuid.UUID) -> List[Schedule]:
        return await self.repository.get_by_class(class_id)

    async def get_teacher_schedule(self, teacher_id: uuid.UUID) -> List[Schedule]:
        return await self.repository.get_by_teacher(teacher_id)

    async def update_schedule(self, schedule_id: uuid.UUID, schedule_data: ScheduleUpdate) -> Schedule:
        schedule = await self.repository.update(schedule_id, schedule_data)
        if not schedule:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Schedule with id {schedule_id} not found"
            )
        return schedule

    async def delete_schedule(self, schedule_id: uuid.UUID) -> None:
        success = await self.repository.delete(schedule_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Schedule with id {schedule_id} not found"
            )