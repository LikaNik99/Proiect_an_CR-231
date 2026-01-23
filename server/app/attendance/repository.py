import uuid

from typing import List, Optional

from sqlalchemy import select

from sqlalchemy.orm import joinedload



from app.attendance.models import Attendance

from app.attendance.schemas import AttendanceCreate, AttendanceUpdate

from config.database import AsyncSession





class AttendanceRepository:

    def __init__(self, session: AsyncSession):

        self.session = session



    async def create(self, attendance_data: AttendanceCreate) -> Attendance:

        attendance = Attendance(**attendance_data.model_dump())

        self.session.add(attendance)

        await self.session.commit()

        await self.session.refresh(attendance)



        

        result = await self.session.execute(

            select(Attendance)

            .options(joinedload(Attendance.subject))

            .where(Attendance.id == attendance.id)

        )

        return result.scalar_one()



    async def get_by_id(self, attendance_id: uuid.UUID) -> Optional[Attendance]:

        result = await self.session.execute(

            select(Attendance)

            .options(joinedload(Attendance.subject))

            .where(Attendance.id == attendance_id)

        )

        return result.scalar_one_or_none()



    async def get_by_student(self, student_id: uuid.UUID) -> List[Attendance]:

        result = await self.session.execute(

            select(Attendance)

            .options(joinedload(Attendance.subject))

            .where(Attendance.student_id == student_id)

            .order_by(Attendance.attendance_date.desc())

        )

        return list(result.scalars().all())



    async def update(self, attendance_id: uuid.UUID, attendance_data: AttendanceUpdate) -> Optional[Attendance]:

        attendance = await self.get_by_id(attendance_id)

        if not attendance:

            return None



        update_data = attendance_data.model_dump(exclude_unset=True)

        for field, value in update_data.items():

            setattr(attendance, field, value)



        await self.session.commit()

        await self.session.refresh(attendance)

        return attendance



    async def delete(self, attendance_id: uuid.UUID) -> bool:

        attendance = await self.get_by_id(attendance_id)

        if not attendance:

            return False



        await self.session.delete(attendance)

        await self.session.commit()

        return True
