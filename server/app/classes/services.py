from datetime import datetime

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession



from app.classes import Class

from app.classes.repositories import ClassRepository

from app.classes.schemas import ClassCreate, ClassUpdate





class ClassService:



    @staticmethod

    async def create_class(db: AsyncSession, data: ClassCreate) -> Class:

        new_class = Class(

            name=data.name,

            school_id=data.school_id,

            created_at=datetime.utcnow(),

            updated_at=datetime.utcnow()

        )

        return await ClassRepository.create(db, new_class)



    @staticmethod

    async def get_class(db: AsyncSession, class_id: UUID) -> Class | None:

        return await ClassRepository.get_by_id(db, class_id)



    @staticmethod

    async def get_classes(db: AsyncSession):

        return await ClassRepository.get_all(db)



    @staticmethod

    async def update_class(db: AsyncSession, class_id: UUID, data: ClassUpdate) -> Class | None:

        class_obj = await ClassRepository.get_by_id(db, class_id)

        if not class_obj:

            return None



        if data.name is not None:

            class_obj.name = data.name

        if data.school_id is not None:

            class_obj.school_id = data.school_id



        return await ClassRepository.update(db, class_obj)



    @staticmethod

    async def delete_class(db: AsyncSession, class_id: UUID) -> bool:

        class_obj = await ClassRepository.get_by_id(db, class_id)

        if not class_obj:

            return False

        return await ClassRepository.delete(db, class_obj)

