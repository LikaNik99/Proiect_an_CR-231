import os
from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from typing import Optional, Tuple
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.environ.get("SECRET_KEY")
ALGORITHM = os.environ.get("ALGORITHM")
ACCESS_TOKEN_EXPIRE_MINUTES = os.environ.get("ACCESS_TOKEN_EXPIRE_MINUTES")
REFRESH_TOKEN_EXPIRE_DAYS = os.environ.get("REFRESH_TOKEN_EXPIRE_DAYS")


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=int(ACCESS_TOKEN_EXPIRE_MINUTES)))
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=int(REFRESH_TOKEN_EXPIRE_DAYS))
    to_encode.update({
        "exp": expire,
        "type": "refresh"
    })
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def verify_refresh_token(token: str) -> Tuple[bool, Optional[dict]]:
    """
    Verify a refresh token and return its payload.
    Returns (is_valid, payload) tuple.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        # Check if it's a refresh token
        if payload.get("type") != "refresh":
            return False, None

        return True, payload
    except JWTError:
        return False, None


def get_token_expiry(token: str) -> Optional[datetime]:
    """Get the expiry datetime from a token."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM], options={"verify_exp": False})
        exp = payload.get("exp")
        if exp:
            return datetime.fromtimestamp(exp, tz=timezone.utc)
    except JWTError:
        pass
    return None
