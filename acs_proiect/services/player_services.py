from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

class PlayerService:
    def __init__(self, db):
        from repositories.player_repositories import PlayerRepository
        self.repo = PlayerRepository(db)

    def create_player(self, username: str, password: str):
        existing = self.repo.get_by_username(username)
        if existing:
            raise ValueError("Username already exists")

        hashed_password = pwd_context.hash(password)
        return self.repo.create_player(username, hashed_password)

    def login(self, username: str, password: str):
        player = self.repo.get_by_username(username)
        if not player:
            raise ValueError("User not found")

        if not pwd_context.verify(password, player.password_hash):
            raise ValueError("Invalid password")

        return player
