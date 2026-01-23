from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes.auth import router as auth_router
from routes.game import router as game_router
from routes.lobby import router as lobby_router
from routes.player import router as player_router
from routes.games import router as games_router

from core.database import Base, engine

# 🔥 Importăm toate modelele explicit
from models import player, games, move, chat, lobby

# ============================
#   CREARE TABELE SQLALCHEMY
# ============================
Base.metadata.create_all(bind=engine)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(game_router)
app.include_router(lobby_router)
app.include_router(player_router)
app.include_router(games_router)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
