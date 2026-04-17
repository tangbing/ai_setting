from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user_id, get_db, get_optional_current_user_id
from app.schemas.comment import CommentCreateRequest, CommentReplyRequest, CommentResponse
from app.schemas.common import CursorPage
from app.services.comment_service import CommentService
from app.services.like_service import LikeService

router = APIRouter(tags=["comments"])
comment_service = CommentService()
like_service = LikeService()


@router.get(
    "/posts/{post_id}/comments",
    response_model=CursorPage[CommentResponse],
    summary="获取评论列表",
    description=(
        "获取帖子评论树。\n\n"
        "- 一级评论作为根节点返回\n"
        "- 二级和三级评论放在 `replies` 中\n"
        "- 带 token 请求时，`isLiked` 会按当前用户计算"
    ),
)
async def list_comments(
    post_id: int,
    cursor: str | None = Query(default=None, description="分页游标。当前实现使用 offset 字符串。"),
    limit: int = Query(default=30, ge=1, le=100, description="每页一级评论数量。"),
    current_user_id: int | None = Depends(get_optional_current_user_id),
    db: Session = Depends(get_db),
) -> CursorPage[CommentResponse]:
    items, next_cursor = comment_service.list_comments(
        db,
        post_id=post_id,
        cursor=cursor,
        limit=limit,
        current_user_id=current_user_id,
    )
    return CursorPage(items=items, next_cursor=next_cursor, limit=limit, extra={"postId": post_id})


@router.post(
    "/posts/{post_id}/comments",
    status_code=status.HTTP_201_CREATED,
    response_model=CommentResponse,
    summary="发表评论",
    description="给指定帖子创建一级评论。",
)
async def create_comment(
    post_id: int,
    payload: CommentCreateRequest,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
) -> CommentResponse:
    return comment_service.create_comment(
        db,
        post_id=post_id,
        payload=payload,
        current_user_id=current_user_id,
    )


@router.post(
    "/comments/{comment_id}/reply",
    status_code=status.HTTP_201_CREATED,
    response_model=CommentResponse,
    summary="回复评论",
    description=(
        "回复指定评论。\n\n"
        "- 当前支持三级评论规则\n"
        "- 超过三级时，后端仍按三级结构挂载"
    ),
)
async def reply_comment(
    comment_id: int,
    payload: CommentReplyRequest,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
) -> CommentResponse:
    return comment_service.reply_comment(
        db,
        comment_id=comment_id,
        payload=payload,
        current_user_id=current_user_id,
    )


@router.post(
    "/comments/{comment_id}/like",
    summary="点赞评论",
    description="给指定评论点赞。重复点赞会返回 409。",
)
async def like_comment(
    comment_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
) -> dict[str, int]:
    like_count = like_service.like_comment(db, comment_id=comment_id, user_id=current_user_id)
    return {"commentId": comment_id, "likeCount": like_count}


@router.delete(
    "/comments/{comment_id}/like",
    summary="取消点赞评论",
    description="取消当前用户对指定评论的点赞。",
)
async def unlike_comment(
    comment_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
) -> dict[str, int]:
    like_service.unlike_comment(db, comment_id=comment_id, user_id=current_user_id)
    return {"commentId": comment_id}


@router.delete("/comments/{comment_id}", status_code=status.HTTP_501_NOT_IMPLEMENTED)
async def delete_comment(
    comment_id: int,
    _: int = Depends(get_current_user_id),
) -> None:
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail=f"Delete comment is not implemented yet for comment_id={comment_id}.",
    )
