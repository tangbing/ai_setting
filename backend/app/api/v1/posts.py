from __future__ import annotations

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user_id, get_db, get_optional_current_user_id
from app.schemas.common import CursorPage
from app.schemas.post import PostCreateRequest, PostResponse
from app.services.like_service import LikeService
from app.services.post_service import PostService

router = APIRouter(prefix="/posts", tags=["posts"])
post_service = PostService()
like_service = LikeService()


@router.get(
    "",
    response_model=CursorPage[PostResponse],
    summary="获取帖子列表",
    description=(
        "获取帖子流。\n\n"
        "- `feed=newest` 按发布时间倒序\n"
        "- `feed=hot` 按点赞数、评论数、时间排序\n"
        "- `feed=following` 只看已关注作者的帖子\n"
        "- 匿名查询时，`isLiked/isMine/isFollowed` 会按未登录用户计算"
    ),
)
async def list_posts(
    feed: str = Query(
        default="newest",
        description="帖子流类型，可选 newest / hot / following",
    ),
    cursor: str | None = Query(
        default=None,
        description="分页游标。当前实现使用 offset 字符串。",
    ),
    limit: int = Query(default=20, ge=1, le=50, description="每页数量，默认 20，最大 50"),
    current_user_id: int | None = Depends(get_optional_current_user_id),
    db: Session = Depends(get_db),
) -> CursorPage[PostResponse]:
    items, next_cursor = post_service.list_posts(
        db,
        feed=feed,
        cursor=cursor,
        limit=limit,
        current_user_id=current_user_id,
    )
    return CursorPage(items=items, next_cursor=next_cursor, limit=limit, extra={"feed": feed})


@router.get(
    "/{post_id}",
    response_model=PostResponse,
    summary="获取帖子详情",
    description="根据 postId 获取帖子详情。带 token 请求时会返回当前用户态字段，例如 isLiked。",
)
async def get_post(
    post_id: int,
    current_user_id: int | None = Depends(get_optional_current_user_id),
    db: Session = Depends(get_db),
) -> PostResponse:
    return post_service.get_post(
        db,
        post_id=post_id,
        current_user_id=current_user_id,
    )


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=PostResponse,
    summary="发帖",
    description=(
        "创建帖子。\n\n"
        "- `contentText` 和 `mediaList` 不能同时为空\n"
        "- 当前只支持图片，因此 `mediaList[*].mediaType` 只支持 `image`\n"
        "- `mediaType` 不传时，后端默认按 `image` 处理\n"
        "- `sortOrder` 取值 1 到 9"
    ),
)
async def create_post(
    payload: PostCreateRequest,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
) -> PostResponse:
    return post_service.create_post(
        db,
        payload=payload,
        current_user_id=current_user_id,
    )


@router.post(
    "/{post_id}/like",
    summary="点赞帖子",
    description="给指定帖子点赞。重复点赞会返回 409。",
)
async def like_post(
    post_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
) -> dict[str, int]:
    like_count = like_service.like_post(db, post_id=post_id, user_id=current_user_id)
    return {"postId": post_id, "likeCount": like_count}


@router.delete(
    "/{post_id}/like",
    summary="取消点赞帖子",
    description="取消当前用户对指定帖子的点赞。",
)
async def unlike_post(
    post_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
) -> dict[str, int]:
    like_service.unlike_post(db, post_id=post_id, user_id=current_user_id)
    return {"postId": post_id}


@router.post(
    "/{post_id}/view",
    summary="增加帖子浏览量",
    description="手动增加帖子 viewCount。",
)
async def increment_view(
    post_id: int,
    db: Session = Depends(get_db),
) -> dict[str, int]:
    view_count = post_service.increment_view(db, post_id=post_id)
    return {"postId": post_id, "viewCount": view_count}
