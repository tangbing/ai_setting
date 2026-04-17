from __future__ import annotations

from fastapi.testclient import TestClient


def test_register_login_and_get_me(client: TestClient) -> None:
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "username": "auth_user",
            "password": "password123",
        },
    )

    assert register_response.status_code == 201
    register_payload = register_response.json()
    assert register_payload["tokenType"] == "Bearer"
    assert register_payload["user"]["userName"] == "auth_user"
    assert register_payload["accessToken"]

    duplicate_response = client.post(
        "/api/v1/auth/register",
        json={
            "username": "auth_user",
            "password": "password123",
        },
    )
    assert duplicate_response.status_code == 409

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "auth_user",
            "password": "password123",
        },
    )
    assert login_response.status_code == 200
    login_payload = login_response.json()
    assert login_payload["user"]["userName"] == "auth_user"

    me_response = client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {login_payload['accessToken']}"},
    )
    assert me_response.status_code == 200
    assert me_response.json() == {
        "userId": 1,
        "userName": "auth_user",
        "userAvatar": None,
    }


def test_register_accepts_optional_nickname(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "username": "nick_user",
            "nickname": "Nick User",
            "password": "password123",
        },
    )

    assert response.status_code == 201
    assert response.json()["user"]["userName"] == "Nick User"
