from __future__ import annotations

from app.db.session import SessionLocal
from app.schemas.auth import RegisterRequest
from app.services.auth_service import AuthService


def main() -> None:
    db = SessionLocal()
    service = AuthService()
    try:
        response = service.register_user(
            db,
            RegisterRequest(
                username="testuser",
                nickname="Test User",
                password="testpassword123",
            ),
        )
        print(response.model_dump(by_alias=True))
    finally:
        db.close()


if __name__ == "__main__":
    main()
