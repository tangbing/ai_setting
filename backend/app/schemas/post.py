from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class PostMediaPayload(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "mediaType": "image",
                "url": "https://example.com/post-image.jpg",
                "sortOrder": 1,
                "thumbnailUrl": "https://example.com/post-image-thumb.jpg",
            }
        },
    )

    media_type: Literal["image"] = Field(
        default="image",
        alias="mediaType",
        serialization_alias="mediaType",
        description="Current backend only supports image media. Omit this field or pass 'image'.",
    )
    url: str = Field(description="Public image URL or uploaded object storage URL.")
    sort_order: int = Field(
        alias="sortOrder",
        serialization_alias="sortOrder",
        ge=1,
        le=9,
        description="Display order inside the post, from 1 to 9.",
    )
    thumbnail_url: str | None = Field(
        default=None,
        alias="thumbnailUrl",
        serialization_alias="thumbnailUrl",
        description="Optional thumbnail URL for the image.",
    )


class PostCreateRequest(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "examples": [
                {
                    "contentText": "Text only post",
                    "locationName": "Shenzhen",
                    "topicText": "Assembly",
                    "mediaList": [],
                },
                {
                    "contentText": "Post with one image",
                    "locationName": "Shenzhen",
                    "topicText": "Assembly",
                    "mediaList": [
                        {
                            "mediaType": "image",
                            "url": "https://example.com/post-image.jpg",
                            "sortOrder": 1,
                        }
                    ],
                },
                {
                    "mediaList": [
                        {
                            "url": "https://example.com/post-image.jpg",
                            "sortOrder": 1,
                        }
                    ]
                },
            ]
        },
    )

    content_text: str | None = Field(
        default=None,
        alias="contentText",
        serialization_alias="contentText",
    )
    location_name: str | None = Field(
        default=None,
        alias="locationName",
        serialization_alias="locationName",
    )
    topic_text: str | None = Field(
        default=None,
        alias="topicText",
        serialization_alias="topicText",
    )
    media_list: list[PostMediaPayload] = Field(
        default_factory=list,
        alias="mediaList",
        serialization_alias="mediaList",
        description="Optional media list. Current backend supports up to 9 images.",
    )

    @model_validator(mode="after")
    def validate_content_or_media(self) -> "PostCreateRequest":
        if not (self.content_text and self.content_text.strip()) and not self.media_list:
            raise ValueError("contentText and mediaList cannot both be empty")
        if len(self.media_list) > 9:
            raise ValueError("mediaList cannot contain more than 9 items")
        return self


class PostMediaResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    media_type: str = Field(serialization_alias="mediaType")
    url: str
    thumbnail_url: str | None = Field(default=None, serialization_alias="thumbnailUrl")


class PostResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    post_id: int = Field(serialization_alias="postId")
    user_id: int = Field(serialization_alias="userId")
    user_name: str = Field(serialization_alias="userName")
    user_avatar: str | None = Field(default=None, serialization_alias="userAvatar")
    content_text: str = Field(serialization_alias="contentText")
    media_list: list[PostMediaResponse] = Field(
        default_factory=list,
        serialization_alias="mediaList",
    )
    location_name: str | None = Field(default=None, serialization_alias="locationName")
    publish_time: str = Field(serialization_alias="publishTime")
    like_count: int = Field(serialization_alias="likeCount")
    comment_count: int = Field(serialization_alias="commentCount")
    view_count: int = Field(serialization_alias="viewCount")
    is_liked: bool = Field(serialization_alias="isLiked")
    is_hot: bool = Field(serialization_alias="isHot")
    is_followed: bool = Field(serialization_alias="isFollowed")
    is_mine: bool = Field(serialization_alias="isMine")
