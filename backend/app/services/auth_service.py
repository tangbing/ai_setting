from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import create_access_token, hash_password, verify_password
from app.models.user import User
from app.schemas.auth import LoginRequest, LoginResponse, RegisterRequest, RegisterResponse
from app.schemas.user import CurrentUserResponse


class AuthService:
    def register_user(self, db: Session, payload: RegisterRequest) -> RegisterResponse:
        existing_user = db.scalar(select(User).where(User.username == payload.username))
        if existing_user is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Username {payload.username} already exists.",
            )

        nickname = payload.nickname.strip() if payload.nickname else payload.username
        user = User(
            username=payload.username,
            nickname=nickname,
            password_hash=self.hash_password(payload.password),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return RegisterResponse(
            access_token=self.issue_access_token(user.id),
            token_type="Bearer",
            user=self._serialize_user(user),
        )

    def login_user(self, db: Session, payload: LoginRequest) -> LoginResponse:
        user = db.scalar(select(User).where(User.username == payload.username))
        if user is None or not self.verify_password(payload.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid username or password.",
            )

        return LoginResponse(
            access_token=self.issue_access_token(user.id),
            token_type="Bearer",
            user=self._serialize_user(user),
        )

    def get_user_profile(self, db: Session, user_id: int) -> CurrentUserResponse:
        user = db.scalar(select(User).where(User.id == user_id))
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {user_id} was not found.",
            )
        return self._serialize_user(user)

    def hash_password(self, password: str) -> str:
        return hash_password(password)

    def verify_password(self, password: str, password_hash: str) -> bool:
        return verify_password(password, password_hash)

    def issue_access_token(self, user_id: int) -> str:
        return create_access_token(user_id)

    def _serialize_user(self, user: User) -> CurrentUserResponse:
        return CurrentUserResponse(
            user_id=user.id,
            user_name=user.nickname,
            user_avatar=user.avatar_url,
        )
