from uuid import UUID

from sqlalchemy import select

from sqlalchemy.ext.asyncio import AsyncSession



from .models import Class





class ClassRepository:



    @staticmethod

    async def create(db: AsyncSession, obj: Class) -> Class:

        db.add(obj)

        await db.commit()

        await db.refresh(obj)

        return obj



    @staticmethod

    async def get_by_id(db: AsyncSession, class_id: UUID) -> Class | None:

        result = await db.execute(select(Class).where(Class.id == class_id))

        return result.scalar_one_or_none()



    @staticmethod

    async def get_all(db: AsyncSession):

        result = await db.execute(select(Class))

        return result.scalars().all()



    @staticmethod

    async def update(db: AsyncSession, obj: Class):

        await db.commit()

        await db.refresh(obj)

        return obj



    @staticmethod

    async def delete(db: AsyncSession, obj: Class):

        await db.delete(obj)

        await db.commit()

        return True

