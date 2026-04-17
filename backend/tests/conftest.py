from __future__ import annotations

import os
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.api.deps import get_db
from app.db.base import Base
from app.main import app
from app.models import comment, comment_like, post, post_like, post_media, user, user_follow

# Import modules for metadata registration side effects.
_ = (user, post, post_media, post_like, comment, comment_like, user_follow)


def _build_test_database_url() -> str:
    return os.getenv(
        "TEST_DATABASE_URL",
        "postgresql+psycopg://edy@localhost:5432/post_backend_test",
    )


TEST_DATABASE_URL = _build_test_database_url()
APP_DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg://edy@localhost:5432/post_backend",
)

if TEST_DATABASE_URL == APP_DATABASE_URL:
    raise RuntimeError(
        "TEST_DATABASE_URL must not be the same as DATABASE_URL. "
        "Use a dedicated test database such as post_backend_test."
    )

test_engine = create_engine(TEST_DATABASE_URL, future=True)
TestingSessionLocal = sessionmaker(
    bind=test_engine,
    autoflush=False,
    autocommit=False,
    future=True,
)


def override_get_db() -> Generator[Session, None, None]:
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def reset_database() -> Generator[None, None, None]:
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def client() -> Generator[TestClient, None, None]:
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def auth_headers(client: TestClient) -> dict[str, str]:
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "username": "tester",
            "password": "password123",
        },
    )
    assert register_response.status_code == 201
    token = register_response.json()["accessToken"]
    return {"Authorization": f"Bearer {token}"}
