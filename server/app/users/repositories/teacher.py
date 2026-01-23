import uuid
from datetime import datetime
from typing import Optional, List

from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy import or_, func

from app.users.models import Teacher, User
from app.users.enums import UserRole
from app.users.schemas.teacher import TeacherCreate, TeacherRead, TeacherUpdate
from config.database import AsyncSession


class TeacherRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_all(self, skip: int = 0, limit: int = 100, q: Optional[str] = None) -> list[TeacherRead]:
        query = select(Teacher).options(
            selectinload(Teacher.user),
            selectinload(Teacher.classes),
        )

        if q:
            # search by username, email or subject
            query = query.join(Teacher.user).where(
                or_(
                    func.lower(User.username).like(f"%{q.lower()}%"),
                    func.lower(User.email).like(f"%{q.lower()}%"),
                    func.lower(Teacher.subject).like(f"%{q.lower()}%")
                )
            )

        query = query.offset(skip).limit(limit)
        result = await self.session.execute(query)
        teachers = result.scalars().all()
        return [TeacherRead.model_validate(teacher) for teacher in teachers]

    async def get_by_user_id(self, user_id: uuid.UUID):
        return await self.session.scalar(
            select(Teacher).where(Teacher.user_id == user_id)
        )

    async def get_by_id(self, id: uuid.UUID) -> TeacherRead | None:
        result = await self.session.execute(
            select(Teacher)
            .options(
                selectinload(Teacher.user),
                selectinload(Teacher.classes),
            )
            .where(Teacher.user_id == id)
        )
        teacher = result.scalars().first()
        return TeacherRead.model_validate(teacher) if teacher else None

    async def create(self, teacher_create: TeacherCreate) -> TeacherRead:

        async with self.session.begin():
            user = User(
                id=uuid.uuid4(),
                username=teacher_create.username,
                email=str(teacher_create.email),
                role=UserRole.TEACHER,
                school_id=teacher_create.school_id,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            self.session.add(user)
            await self.session.flush()

            teacher = Teacher(
                user_id=user.id,
                subject=teacher_create.subject,
                is_homeroom=teacher_create.is_homeroom or False,
                is_director=teacher_create.is_director or False,
            )
            self.session.add(teacher)

        result = await self.session.execute(
            select(Teacher)
            .options(
                selectinload(Teacher.user),
                selectinload(Teacher.classes),
            )
            .where(Teacher.user_id == teacher.user_id)
        )
        teacher = result.scalars().first()
        return TeacherRead.model_validate(teacher)

    async def update(self, id: uuid.UUID, data: TeacherUpdate) -> TeacherRead | None:
        result = await self.session.execute(
            select(Teacher)
            .options(selectinload(Teacher.user), selectinload(Teacher.classes))
            .where(Teacher.user_id == id)
        )
        teacher = result.scalars().first()
        if not teacher:
            return None

        if data.subject is not None:
            teacher.subject = data.subject
        if data.is_director is not None:
            teacher.is_director = data.is_director
        if data.is_homeroom is not None:
            teacher.is_homeroom = data.is_homeroom
        if hasattr(data, "username") and data.username:
            teacher.user.username = data.username
        if hasattr(data, "email") and data.email:
            teacher.user.email = str(data.email)

        await self.session.flush()
        await self.session.refresh(teacher)

        return TeacherRead.model_validate(teacher)

    async def delete(self, id: uuid.UUID) -> bool:
        result = await self.session.execute(select(User).where(User.id == id))
        user = result.scalars().first()
        if not user:
            return False

        await self.session.delete(user)
        await self.session.commit()
        return True

    async def get_students_for_teacher(self, teacher_id: uuid.UUID):
        """Return students for classes where this teacher is assigned."""
        from app.classes.models import Class
        from app.users.models.students import Student
        from app.users.schemas.student import StudentRead
        from sqlalchemy import select
        from sqlalchemy.orm import selectinload

        query = select(Student).join(Class, Class.id == Student.class_id).where(Class.teacher_id == teacher_id).options(selectinload(Student.user))
        result = await self.session.execute(query)
        students = result.scalars().all()
        return [StudentRead.model_validate(s) for s in students]
