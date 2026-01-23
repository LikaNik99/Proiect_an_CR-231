import uuid

from typing import List

from fastapi import HTTPException, status



from app.attendance.models import Attendance

from app.attendance.repository import AttendanceRepository

from app.attendance.schemas import AttendanceCreate, AttendanceUpdate





class AttendanceService:

    def __init__(self, repository: AttendanceRepository):

        self.repository = repository



    async def create_attendance(self, attendance_data: AttendanceCreate) -> Attendance:

        return await self.repository.create(attendance_data)



    async def get_attendance(self, attendance_id: uuid.UUID) -> Attendance:

        attendance = await self.repository.get_by_id(attendance_id)

        if not attendance:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail=f"Attendance with id {attendance_id} not found"

            )

        return attendance



    async def get_student_attendance(self, student_id: uuid.UUID) -> List[Attendance]:

        return await self.repository.get_by_student(student_id)



    async def update_attendance(self, attendance_id: uuid.UUID, attendance_data: AttendanceUpdate) -> Attendance:

        attendance = await self.repository.update(attendance_id, attendance_data)

        if not attendance:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail=f"Attendance with id {attendance_id} not found"

            )

        return attendance



    async def delete_attendance(self, attendance_id: uuid.UUID) -> None:

        success = await self.repository.delete(attendance_id)

        if not success:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail=f"Attendance with id {attendance_id} not found"

            )



    async def bulk_create_attendance(self, attendances: List[AttendanceCreate]) -> List[Attendance]:

        created = []

        for a in attendances:

            created.append(await self.repository.create(a))

        return created

