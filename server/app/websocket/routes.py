"""
WebSocket routes for real-time notifications.
"""
import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from jose import jwt, JWTError

from config.security import SECRET_KEY, ALGORITHM
from app.websocket.manager import manager

logger = logging.getLogger(__name__)
router = APIRouter(tags=["WebSocket"])


def verify_ws_token(token: str) -> dict | None:
    """Verify JWT token for WebSocket connection."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        role = payload.get("role")
        if user_id and role:
            return {"id": user_id, "role": role}
    except JWTError as e:
        logger.warning(f"WebSocket token verification failed: {e}")
    return None


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(...)
):
    """
    WebSocket endpoint for real-time notifications.
    Connect with: ws://server/ws?token=<jwt_token>
    """
    # Verify token
    user = verify_ws_token(token)
    if not user:
        await websocket.close(code=4001, reason="Invalid or expired token")
        return

    user_id = user["id"]

    # Accept connection
    await manager.connect(websocket, user_id)

    try:
        # Send connection confirmation
        await websocket.send_json({
            "type": "connected",
            "message": "Connected to notification service",
            "user_id": user_id
        })

        # Keep connection alive and listen for messages
        while True:
            try:
                data = await websocket.receive_json()

                # Handle ping/pong for keep-alive
                if data.get("type") == "ping":
                    await websocket.send_json({"type": "pong"})

                # Handle other message types as needed
                elif data.get("type") == "subscribe":
                    # Client wants to subscribe to specific channels
                    channels = data.get("channels", [])
                    await websocket.send_json({
                        "type": "subscribed",
                        "channels": channels
                    })

            except Exception as e:
                logger.warning(f"Error processing message: {e}")
                break

    except WebSocketDisconnect:
        logger.info(f"User {user_id} disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    finally:
        manager.disconnect(websocket, user_id)


@router.get("/ws/online")
async def get_online_users():
    """Get count of online users (for admin dashboard)."""
    return {
        "online_count": len(manager.all_connections),
        "users_online": len(manager.active_connections)
    }
