import logging
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError, ExpiredSignatureError

from config.security import SECRET_KEY, ALGORITHM
from config.token_blacklist import is_token_blacklisted

logger = logging.getLogger(__name__)
http_bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(http_bearer_scheme)):
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No authorization credentials provided"
        )

    token = credentials.credentials

    # Check if token is blacklisted
    if is_token_blacklisted(token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked"
        )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        role: str = payload.get("role")

        if not user_id or not role:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
            )
        return {"id": user_id, "role": role}
    except ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired",
        )
    except JWTError as e:
        logger.warning(f"JWT validation failed: {type(e).__name__}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )


def admin_required(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admin can access this resource"
        )
    return current_user


async def director_required(current_user: dict = Depends(get_current_user)):
    """
    Verifies that the current user is a teacher with director privileges.
    """
    from config.database import get_db
    from sqlalchemy import select
    from app.users.models import Teacher
    import uuid

    if current_user["role"] != "teacher":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only teachers can be directors"
        )

    # Check if this teacher is marked as director
    async for session in get_db():
        try:
            user_id = uuid.UUID(current_user["id"])
            result = await session.execute(
                select(Teacher).where(Teacher.user_id == user_id)
            )
            teacher = result.scalar_one_or_none()

            if not teacher or not teacher.is_director:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Only directors can access this resource"
                )

            return current_user
        finally:
            break

