from pydantic import BaseModel, ConfigDict, Field

from app.schemas.user import CurrentUserResponse


class RegisterRequest(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "username": "testuser",
                "password": "testpassword123",
                "nickname": "Test User",
            }
        },
    )

    username: str = Field(min_length=3, max_length=50)
    nickname: str | None = Field(default=None, min_length=1, max_length=50)
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "username": "testuser",
                "password": "testpassword123",
            }
        },
    )

    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=8, max_length=128)


class LoginResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    access_token: str = Field(serialization_alias="accessToken")
    token_type: str = Field(default="Bearer", serialization_alias="tokenType")
    user: CurrentUserResponse


class RegisterResponse(LoginResponse):
    pass
