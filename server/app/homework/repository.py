import uuid
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from app.homework.models import Homework, HomeworkAssignment
from app.homework.schemas import HomeworkCreate, HomeworkUpdate
from config.database import AsyncSession


class HomeworkRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, homework_data: HomeworkCreate) -> Homework:
        data = homework_data.model_dump()
        student_ids = data.pop('student_ids', None)

        homework = Homework(**data)
        self.session.add(homework)
        await self.session.flush()  # ensure homework.id exists

        if student_ids:
            for sid in student_ids:
                self.session.add(
                    HomeworkAssignment(homework_id=homework.id, student_id=sid)
                )

        await self.session.commit()

        # Re-load with eager relationships; refresh() alone won't populate relationships and
        # touching hw.subject outside of an async loader context can raise MissingGreenlet.
        return await self.get_by_id(homework.id)

    async def get_by_id(self, homework_id: uuid.UUID) -> Optional[Homework]:
        result = await self.session.execute(
            select(Homework)
            .options(joinedload(Homework.subject), joinedload(Homework.assignments))
            .where(Homework.id == homework_id)
        )
        # joinedload() over a collection requires unique() before scalar_one_or_none()
        return result.unique().scalar_one_or_none()

    async def get_by_class(self, class_id: uuid.UUID) -> List[Homework]:
        result = await self.session.execute(
            select(Homework)
            .options(joinedload(Homework.subject), joinedload(Homework.assignments))
            .where(Homework.class_id == class_id)
            .order_by(Homework.due_date.asc())
        )
        # joinedload() over a collection requires unique() before scalars().all()
        return list(result.unique().scalars().all())

    async def get_for_student(self, student_id: uuid.UUID, class_id: Optional[uuid.UUID]) -> List[Homework]:
        # Returns ONLY homework explicitly assigned to this specific student.
        # This filters by HomeworkAssignment records, so only homework created
        # with this student's ID in the student_ids list will be returned.
        stmt = (
            select(Homework)
            .options(joinedload(Homework.subject), joinedload(Homework.assignments))
            .join(HomeworkAssignment, HomeworkAssignment.homework_id == Homework.id)
            .where(HomeworkAssignment.student_id == student_id)
            .order_by(Homework.due_date.asc())
        )

        result = await self.session.execute(stmt)
        return list(result.unique().scalars().all())

    async def update(self, homework_id: uuid.UUID, homework_data: HomeworkUpdate) -> Optional[Homework]:
        homework = await self.get_by_id(homework_id)
        if not homework:
            return None

        update_data = homework_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(homework, field, value)

        await self.session.commit()

        # Re-load with eager relationships to keep serialization safe.
        return await self.get_by_id(homework_id)

    async def delete(self, homework_id: uuid.UUID) -> bool:
        homework = await self.get_by_id(homework_id)
        if not homework:
            return False

        await self.session.delete(homework)
        await self.session.commit()
        return True