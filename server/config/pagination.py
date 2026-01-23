"""
Pagination utilities for FastAPI endpoints.
Provides standardized pagination parameters and response format.
"""
from typing import TypeVar, Generic, List, Optional
from pydantic import BaseModel
from fastapi import Query

T = TypeVar('T')


class PaginationParams:
    """
    Dependency for pagination parameters.
    Usage: pagination: PaginationParams = Depends()
    """
    def __init__(
        self,
        skip: int = Query(0, ge=0, description="Number of records to skip"),
        limit: int = Query(20, ge=1, le=100, description="Number of records to return (max 100)"),
    ):
        self.skip = skip
        self.limit = limit


class PaginatedResponse(BaseModel, Generic[T]):
    """Standardized paginated response format."""
    items: List[T]
    total: int
    skip: int
    limit: int
    has_more: bool

    class Config:
        from_attributes = True


def create_paginated_response(
    items: List[T],
    total: int,
    skip: int,
    limit: int
) -> dict:
    """Create a paginated response dictionary."""
    return {
        "items": items,
        "total": total,
        "skip": skip,
        "limit": limit,
        "has_more": skip + len(items) < total
    }
