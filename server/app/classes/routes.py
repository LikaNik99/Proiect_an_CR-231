from fastapi import APIRouter, Depends, HTTPException

from sqlalchemy.ext.asyncio import AsyncSession

from uuid import UUID



from app.classes.schemas import ClassOut, ClassCreate, ClassUpdate

from app.classes.services import ClassService

from config.database import get_db

from config.dependences import admin_required



router = APIRouter(prefix="/classes", tags=["Classes"])





@router.post("/", response_model=ClassOut, dependencies=[Depends(admin_required)])

async def create_class(data: ClassCreate, db: AsyncSession = Depends(get_db)):

    return await ClassService.create_class(db, data)





@router.get("/{class_id}", response_model=ClassOut)

async def get_class(class_id: UUID, db: AsyncSession = Depends(get_db)):

    result = await ClassService.get_class(db, class_id)

    if not result:

        raise HTTPException(404, "Class not found")

    return result





@router.get("/", response_model=list[ClassOut], dependencies=[Depends(admin_required)])

async def list_classes(db: AsyncSession = Depends(get_db)):

    return await ClassService.get_classes(db)





@router.put("/{class_id}", response_model=ClassOut, dependencies=[Depends(admin_required)])

async def update_class(class_id: UUID, data: ClassUpdate, db: AsyncSession = Depends(get_db)):

    result = await ClassService.update_class(db, class_id, data)

    if not result:

        raise HTTPException(404, "Class not found")

    return result





@router.delete("/{class_id}", dependencies=[Depends(admin_required)])

async def delete_class(class_id: UUID, db: AsyncSession = Depends(get_db)):

    ok = await ClassService.delete_class(db, class_id)

    if not ok:

        raise HTTPException(404, "Class not found")

    return {"message": "Deleted"}

