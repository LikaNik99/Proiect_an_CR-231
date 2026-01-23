"""
WebSocket connection manager for real-time notifications.
"""
import json
import logging
from typing import Dict, List, Set
from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages WebSocket connections for real-time communication."""

    def __init__(self):
        # Map of user_id to their active connections
        self.active_connections: Dict[str, List[WebSocket]] = {}
        # Set of all connected websockets for broadcast
        self.all_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket, user_id: str):
        """Accept a new WebSocket connection."""
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        self.all_connections.add(websocket)
        logger.info(f"User {user_id} connected. Total connections: {len(self.all_connections)}")

    def disconnect(self, websocket: WebSocket, user_id: str):
        """Remove a WebSocket connection."""
        if user_id in self.active_connections:
            if websocket in self.active_connections[user_id]:
                self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        self.all_connections.discard(websocket)
        logger.info(f"User {user_id} disconnected. Total connections: {len(self.all_connections)}")

    async def send_personal_message(self, message: dict, user_id: str):
        """Send a message to a specific user."""
        if user_id in self.active_connections:
            disconnected = []
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.warning(f"Failed to send to user {user_id}: {e}")
                    disconnected.append(connection)
            # Clean up disconnected connections
            for conn in disconnected:
                self.disconnect(conn, user_id)

    async def send_to_users(self, message: dict, user_ids: List[str]):
        """Send a message to multiple users."""
        for user_id in user_ids:
            await self.send_personal_message(message, user_id)

    async def broadcast(self, message: dict):
        """Send a message to all connected clients."""
        disconnected = []
        for connection in self.all_connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.warning(f"Broadcast failed: {e}")
                disconnected.append(connection)
        # Clean up disconnected connections
        for conn in disconnected:
            self.all_connections.discard(conn)

    def get_online_users(self) -> List[str]:
        """Get list of currently connected user IDs."""
        return list(self.active_connections.keys())

    def is_user_online(self, user_id: str) -> bool:
        """Check if a user is currently connected."""
        return user_id in self.active_connections


# Global connection manager instance
manager = ConnectionManager()
