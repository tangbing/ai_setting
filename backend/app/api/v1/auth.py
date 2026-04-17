from __future__ import annotations

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.auth import LoginRequest, LoginResponse, RegisterRequest, RegisterResponse
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])
auth_service = AuthService()


@router.post(
    "/register",
    status_code=status.HTTP_201_CREATED,
    response_model=RegisterResponse,
    summary="注册",
    description=(
        "创建新用户并直接返回 access token。\n\n"
        "- 必填字段只有 `username` 和 `password`\n"
        "- `nickname` 可选，不传时默认使用 `username` 作为展示名"
    ),
)
async def register(
    payload: RegisterRequest,
    db: Session = Depends(get_db),
) -> RegisterResponse:
    return auth_service.register_user(db, payload)


@router.post(
    "/login",
    response_model=LoginResponse,
    summary="登录",
    description="使用用户名和密码登录，成功后返回 access token。",
)
async def login(
    payload: LoginRequest,
    db: Session = Depends(get_db),
) -> LoginResponse:
    return auth_service.login_user(db, payload)
