from datetime import datetime, timezone

from app.auth.repository import AuthRepository

from pydantic import EmailStr

from fastapi import HTTPException, status



from app.auth.schemas import (

    EmailCheckResponse, AccountStatus, UserLoginRequest, AuthResponse,

    RefreshTokenRequest, RefreshTokenResponse

)

from app.password.utils import pwd_context

from config.security import (

    create_access_token, create_refresh_token,

    verify_refresh_token, get_token_expiry

)

from config.token_blacklist import blacklist_token, is_token_blacklisted





class AuthService:

    def __init__(self, repository: AuthRepository):

        self.repository = repository



    async def get_check_email(self, email: EmailStr) -> EmailCheckResponse:

        user = await self.repository.get_by_email(email)

        if not user:

            return EmailCheckResponse()

        return EmailCheckResponse(

            exists=True,

            is_active=user.is_activated,

            status=(

                AccountStatus.ACTIVE

                if user.is_activated

                else AccountStatus.INACTIVE

            ),

            role=user.role,

        )



    async def login(self, data: UserLoginRequest) -> AuthResponse:

        user = await self.repository.get_by_email(data.email)

        if not user:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail="User not found"

            )



        if not user.is_activated:

            if not data.password:

                raise HTTPException(

                    status_code=status.HTTP_400_BAD_REQUEST,

                    detail="Account not activated. Please set your password."

                )



            password_hash = pwd_context.hash(data.password)

            await self.repository.activate_user(user, password_hash)

            access_token = create_access_token({

                "sub": str(user.id),

                "role": user.role.value

            })



            refresh_token = create_refresh_token({

                "sub": str(user.id)

            })



            return AuthResponse(

                id=user.id,

                username=user.username,

                email=user.email,

                role=user.role,

                is_activated=True,

                access_token=access_token,

                refresh_token=refresh_token,

            )



        if not data.password or not pwd_context.verify(data.password, user.password):

            raise HTTPException(

                status_code=status.HTTP_401_UNAUTHORIZED,

                detail="Incorrect password"

            )



        access_token = create_access_token({

            "sub": str(user.id),

            "role": user.role.value

        })



        refresh_token = create_refresh_token({

            "sub": str(user.id)

        })



        return AuthResponse(

            id=user.id,

            username=user.username,

            email=user.email,

            role=user.role,

            is_activated=True,

            access_token=access_token,

            refresh_token=refresh_token

        )



    async def refresh_token(self, data: RefreshTokenRequest) -> RefreshTokenResponse:

        """Generate new access and refresh tokens using a valid refresh token."""

        

        if is_token_blacklisted(data.refresh_token):

            raise HTTPException(

                status_code=status.HTTP_401_UNAUTHORIZED,

                detail="Token has been revoked"

            )



        

        is_valid, payload = verify_refresh_token(data.refresh_token)

        if not is_valid or not payload:

            raise HTTPException(

                status_code=status.HTTP_401_UNAUTHORIZED,

                detail="Invalid or expired refresh token"

            )



        user_id = payload.get("sub")

        if not user_id:

            raise HTTPException(

                status_code=status.HTTP_401_UNAUTHORIZED,

                detail="Invalid token payload"

            )



        

        expiry = get_token_expiry(data.refresh_token)

        if expiry:

            blacklist_token(data.refresh_token, expiry)



        

        

        

        new_access_token = create_access_token({

            "sub": user_id,

            "role": payload.get("role", "student")  

        })



        new_refresh_token = create_refresh_token({

            "sub": user_id

        })



        return RefreshTokenResponse(

            access_token=new_access_token,

            refresh_token=new_refresh_token

        )



    async def logout(self, access_token: str, refresh_token: str = None) -> dict:

        """Logout user by blacklisting their tokens."""

        

        expiry = get_token_expiry(access_token)

        if expiry:

            blacklist_token(access_token, expiry)



        

        if refresh_token:

            refresh_expiry = get_token_expiry(refresh_token)

            if refresh_expiry:

                blacklist_token(refresh_token, refresh_expiry)



        return {"message": "Successfully logged out"}

