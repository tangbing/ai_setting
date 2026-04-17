from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class CurrentUserResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    user_id: int = Field(serialization_alias="userId")
    user_name: str = Field(serialization_alias="userName")
    user_avatar: str | None = Field(default=None, serialization_alias="userAvatar")
