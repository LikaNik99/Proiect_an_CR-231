import os
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()


def setup_cors(app):
    # Get allowed origins from environment variable or use defaults for development
    allowed_origins_str = os.environ.get("ALLOWED_ORIGINS", "")

    if allowed_origins_str:
        allowed_origins = [origin.strip() for origin in allowed_origins_str.split(",")]
    else:
        # Default development origins
        allowed_origins = [
            '*'
        ]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
        allow_headers=["*"],
    )
