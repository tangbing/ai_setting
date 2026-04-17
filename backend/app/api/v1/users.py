from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user_id, get_db
from app.schemas.user import CurrentUserResponse
from app.services.auth_service import AuthService

router = APIRouter(prefix="/users", tags=["users"])
auth_service = AuthService()


@router.get(
    "/me",
    response_model=CurrentUserResponse,
    summary="获取当前用户",
    description="需要 Bearer Token。返回当前登录用户资料。",
)
async def get_me(
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
) -> CurrentUserResponse:
    return auth_service.get_user_profile(db, current_user_id)
