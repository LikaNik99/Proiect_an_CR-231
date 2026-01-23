"""
Simple in-memory token blacklist.
For production, use Redis or a database table.
"""
from datetime import datetime, timezone
from typing import Set, Dict
import threading

# Thread-safe set for blacklisted tokens
_blacklisted_tokens: Set[str] = set()
_token_expiry: Dict[str, datetime] = {}
_lock = threading.Lock()


def blacklist_token(token: str, expires_at: datetime) -> None:
    """Add a token to the blacklist."""
    with _lock:
        _blacklisted_tokens.add(token)
        _token_expiry[token] = expires_at


def is_token_blacklisted(token: str) -> bool:
    """Check if a token is blacklisted."""
    with _lock:
        # Clean up expired tokens
        _cleanup_expired_tokens()
        return token in _blacklisted_tokens


def _cleanup_expired_tokens() -> None:
    """Remove expired tokens from the blacklist."""
    now = datetime.now(timezone.utc)
    expired = [t for t, exp in _token_expiry.items() if exp < now]
    for token in expired:
        _blacklisted_tokens.discard(token)
        _token_expiry.pop(token, None)


def clear_blacklist() -> None:
    """Clear all blacklisted tokens (for testing)."""
    with _lock:
        _blacklisted_tokens.clear()
        _token_expiry.clear()
