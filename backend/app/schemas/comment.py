from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class CommentCreateRequest(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={"example": {"content": "First comment"}},
    )

    content: str = Field(min_length=1, max_length=2000)


class CommentReplyRequest(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "content": "Reply comment",
                "replyToCommentId": 1,
            }
        },
    )

    content: str = Field(min_length=1, max_length=2000)
    reply_to_comment_id: int | None = Field(
        default=None,
        alias="replyToCommentId",
        serialization_alias="replyToCommentId",
    )


class CommentResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    comment_id: int = Field(serialization_alias="commentId")
    post_id: int = Field(serialization_alias="postId")
    parent_comment_id: int | None = Field(default=None, serialization_alias="parentCommentId")
    root_comment_id: int | None = Field(default=None, serialization_alias="rootCommentId")
    reply_to_user_id: int | None = Field(default=None, serialization_alias="replyToUserId")
    reply_to_user_name: str | None = Field(default=None, serialization_alias="replyToUserName")
    user_id: int = Field(serialization_alias="userId")
    user_name: str = Field(serialization_alias="userName")
    user_avatar: str | None = Field(default=None, serialization_alias="userAvatar")
    content: str
    level: int
    like_count: int = Field(serialization_alias="likeCount")
    is_liked: bool = Field(serialization_alias="isLiked")
    create_time: str = Field(serialization_alias="createTime")
    replies: list["CommentResponse"] = Field(default_factory=list)


CommentResponse.model_rebuild()
