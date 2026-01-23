from fastapi import APIRouter, Depends

from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials



from app.auth.repository import AuthRepository

from app.auth.schemas import (

    UserLoginRequest, EmailCheckRequest, AuthResponse,

    RefreshTokenRequest, RefreshTokenResponse, LogoutRequest

)

from app.auth.services import AuthService

from config.database import get_db, AsyncSession



router = APIRouter(prefix="/auth", tags=["Auth"])

http_bearer = HTTPBearer(auto_error=False)





def get_auth_service(db: AsyncSession = Depends(get_db)) -> AuthService:

    repository = AuthRepository(db)

    return AuthService(repository)





@router.post("/check-email")

async def check_email(

        data: EmailCheckRequest,

        auth_service: AuthService = Depends(get_auth_service)

):

    return await auth_service.get_check_email(data.email)





@router.post("/login", response_model=AuthResponse)

async def login(

        data: UserLoginRequest,

        auth_service: AuthService = Depends(get_auth_service)

):

    return await auth_service.login(data)





@router.post("/refresh", response_model=RefreshTokenResponse)

async def refresh_token(

        data: RefreshTokenRequest,

        auth_service: AuthService = Depends(get_auth_service)

):

    """Refresh access token using a valid refresh token."""

    return await auth_service.refresh_token(data)





@router.post("/logout")

async def logout(

        data: LogoutRequest = None,

        credentials: HTTPAuthorizationCredentials = Depends(http_bearer),

        auth_service: AuthService = Depends(get_auth_service)

):

    """Logout user and invalidate tokens."""

    access_token = credentials.credentials if credentials else None

    refresh_token = data.refresh_token if data else None



    if not access_token:

        return {"message": "No token provided, considered logged out"}



    return await auth_service.logout(access_token, refresh_token)



