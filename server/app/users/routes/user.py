from fastapi import APIRouter, Depends, status, UploadFile, File, HTTPException
from typing import List, Optional
from pydantic import BaseModel
import uuid
import os
from sqlalchemy.future import select
from app.users.schemas.user_base import UserCreate, UserRead
from app.users.models import User as UserModel
from app.users.repositories.user import UserRepository
from app.users.services.user import UserService
from config.database import AsyncSession, get_db
from config.dependences import admin_required, get_current_user

router = APIRouter(prefix="/users", tags=["Users"])


async def get_user_service(session: AsyncSession = Depends(get_db)) -> UserService:
    repository = UserRepository(session)
    return UserService(repository)


@router.get("/", response_model=List[UserRead], dependencies=[Depends(admin_required)])
async def get_all_users(service: UserService = Depends(get_user_service)):
    return await service.get_all_users()


@router.get("/{user_id}", response_model=UserRead)
async def get_user_by_id(user_id: uuid.UUID, service: UserService = Depends(get_user_service)):
    return await service.get_user_by_id(user_id)


@router.post("/",
             response_model=UserRead,
             status_code=status.HTTP_201_CREATED,
             dependencies=[Depends(admin_required)],
             )
async def create_user(user_data: UserCreate, service: UserService = Depends(get_user_service)):
    return await service.create_user(user_data)


@router.put("/{user_id}", response_model=UserRead, dependencies=[Depends(admin_required)])
async def update_user(
        user_id: uuid.UUID, user_data: UserCreate, service: UserService = Depends(get_user_service)
):
    return await service.update_user(user_id, user_data)


@router.delete("/{user_id}", status_code=status.HTTP_200_OK, dependencies=[Depends(admin_required)])
async def delete_user(user_id: uuid.UUID, service: UserService = Depends(get_user_service)):
    await service.delete_user(user_id)
    return {"message": f"User with id {user_id} deleted successfully."}


class UpdateProfileRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None

    class Config:
        from_attributes = True


@router.put("/me/profile", response_model=UserRead)
async def update_my_profile(
        data: UpdateProfileRequest,
        current_user: dict = Depends(get_current_user),
        session: AsyncSession = Depends(get_db),
):
    """Update current user's profile (username, email)."""
    user_id = uuid.UUID(current_user.get("id"))
    result = await session.execute(select(UserModel).where(UserModel.id == user_id))
    user_obj = result.scalars().first()

    if not user_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    # Update fields if provided
    if data.username and data.username.strip():
        user_obj.username = data.username.strip()
    if data.email and data.email.strip():
        # Check if email is already in use by another user
        email_check = await session.execute(
            select(UserModel).where(UserModel.email == data.email, UserModel.id != user_id)
        )
        if email_check.scalars().first():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already in use")
        user_obj.email = data.email.strip()

    await session.commit()
    await session.refresh(user_obj)

    return UserRead.model_validate(user_obj)


@router.post("/{user_id}/avatar", response_model=UserRead)
async def upload_avatar(
        user_id: uuid.UUID,
        file: UploadFile = File(...),
        current_user: dict = Depends(get_current_user),
        session: AsyncSession = Depends(get_db),
):
    """Upload avatar for a user. Allowed: image/jpeg, image/png. Max size: 5MB."""
    # Authorization: owner or admin
    is_admin = current_user.get("role") == "admin"
    if not is_admin and current_user.get("id") != str(user_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to upload avatar for this user")

    # Validate content type
    if file.content_type not in ("image/jpeg", "image/png"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only JPEG and PNG images are allowed")

    # Read file bytes and check size
    contents = await file.read()
    max_size = 5 * 1024 * 1024  # 5MB
    if len(contents) > max_size:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="File too large. Max 5MB")

    # Save file
    uploads_dir = os.environ.get("UPLOADS_DIR", "uploads")
    os.makedirs(uploads_dir, exist_ok=True)
    ext = "jpg" if file.content_type == "image/jpeg" else "png"
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = os.path.join(uploads_dir, filename)
    with open(filepath, "wb") as f:
        f.write(contents)

    # Update user avatar_url
    repo = UserRepository(session)
    user = await repo.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    # user is a Pydantic model; repository expects to update via repository or DB
    # We'll update the user model directly using session
    result = await session.execute(select(UserModel).where(UserModel.id == user_id))
    user_obj = result.scalars().first()
    if not user_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    # Save URL as relative path
    user_obj.avatar_url = f"/uploads/{filename}"
    await session.commit()
    await session.refresh(user_obj)

    return UserRead.model_validate(user_obj)
