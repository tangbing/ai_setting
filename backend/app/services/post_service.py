from __future__ import annotations

from collections.abc import Sequence

from fastapi import HTTPException, status
from sqlalchemy import Select, exists, select
from sqlalchemy.orm import Session

from app.models.post import Post
from app.models.post_like import PostLike
from app.models.post_media import PostMedia
from app.models.user import User
from app.models.user_follow import UserFollow
from app.schemas.post import PostCreateRequest, PostMediaResponse, PostResponse


class PostService:
    def list_posts(
        self,
        db: Session,
        *,
        feed: str,
        cursor: str | None,
        limit: int,
        current_user_id: int | None,
    ) -> tuple[list[PostResponse], str | None]:
        offset = self._parse_cursor(cursor)
        statement = self._build_feed_query(feed=feed, current_user_id=current_user_id)
        posts = db.scalars(statement.offset(offset).limit(limit + 1)).all()

        has_more = len(posts) > limit
        page_posts = posts[:limit]
        serialized = self._serialize_posts(
            db,
            posts=page_posts,
            current_user_id=current_user_id,
        )
        next_cursor = str(offset + limit) if has_more else None
        return serialized, next_cursor

    def get_post(
        self,
        db: Session,
        *,
        post_id: int,
        current_user_id: int | None,
    ) -> PostResponse:
        post = db.scalar(
            select(Post).where(
                Post.id == post_id,
                Post.is_deleted.is_(False),
            )
        )
        if post is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Post {post_id} was not found.",
            )
        return self._serialize_post(db, post=post, current_user_id=current_user_id)

    def create_post(
        self,
        db: Session,
        *,
        payload: PostCreateRequest,
        current_user_id: int,
    ) -> PostResponse:
        self._get_user_or_raise(db, current_user_id)

        normalized_content = payload.content_text.strip() if payload.content_text else None
        normalized_location = payload.location_name.strip() if payload.location_name else None
        normalized_topic = payload.topic_text.strip() if payload.topic_text else None
        media_type = "image" if payload.media_list else None

        post = Post(
            author_id=current_user_id,
            content_text=normalized_content,
            location_name=normalized_location or None,
            topic_text=normalized_topic or None,
            media_type=media_type,
        )
        db.add(post)
        db.flush()

        for media in sorted(payload.media_list, key=lambda item: item.sort_order):
            db.add(
                PostMedia(
                    post_id=post.id,
                    media_type=media.media_type,
                    url=media.url,
                    thumbnail_url=media.thumbnail_url,
                    sort_order=media.sort_order,
                )
            )

        db.commit()
        db.refresh(post)
        return self._serialize_post(db, post=post, current_user_id=current_user_id)

    def increment_view(self, db: Session, *, post_id: int) -> int:
        post = db.scalar(
            select(Post).where(
                Post.id == post_id,
                Post.is_deleted.is_(False),
            )
        )
        if post is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Post {post_id} was not found.",
            )
        post.view_count += 1
        db.add(post)
        db.commit()
        return post.view_count

    def _build_feed_query(
        self,
        *,
        feed: str,
        current_user_id: int | None,
    ) -> Select[tuple[Post]]:
        query = select(Post).where(Post.is_deleted.is_(False))
        normalized_feed = feed.lower()

        if normalized_feed not in {"newest", "hot", "following"}:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="feed must be one of: newest, hot, following",
            )

        if normalized_feed == "following":
            if current_user_id is None:
                return query.where(False)
            query = query.where(
                exists(
                    select(UserFollow.id).where(
                        UserFollow.follower_user_id == current_user_id,
                        UserFollow.followed_user_id == Post.author_id,
                    )
                )
            ).order_by(Post.created_at.desc(), Post.id.desc())
        elif normalized_feed == "hot":
            query = query.order_by(
                Post.like_count.desc(),
                Post.comment_count.desc(),
                Post.created_at.desc(),
                Post.id.desc(),
            )
        else:
            query = query.order_by(Post.created_at.desc(), Post.id.desc())

        return query

    def _serialize_posts(
        self,
        db: Session,
        *,
        posts: Sequence[Post],
        current_user_id: int | None,
    ) -> list[PostResponse]:
        if not posts:
            return []

        author_ids = list({post.author_id for post in posts})
        post_ids = [post.id for post in posts]

        users = {
            user.id: user
            for user in db.scalars(select(User).where(User.id.in_(author_ids))).all()
        }
        media_map = self._fetch_media_map(db, post_ids)
        liked_ids = self._fetch_liked_post_ids(db, post_ids, current_user_id)
        followed_author_ids = self._fetch_followed_author_ids(db, author_ids, current_user_id)

        return [
            self._build_post_response(
                post=post,
                user=users.get(post.author_id),
                media_items=media_map.get(post.id, []),
                liked_ids=liked_ids,
                followed_author_ids=followed_author_ids,
                current_user_id=current_user_id,
            )
            for post in posts
        ]

    def _serialize_post(
        self,
        db: Session,
        *,
        post: Post,
        current_user_id: int | None,
    ) -> PostResponse:
        user = db.scalar(select(User).where(User.id == post.author_id))
        media_items = db.scalars(
            select(PostMedia)
            .where(PostMedia.post_id == post.id)
            .order_by(PostMedia.sort_order.asc(), PostMedia.id.asc())
        ).all()
        liked_ids = self._fetch_liked_post_ids(db, [post.id], current_user_id)
        followed_author_ids = self._fetch_followed_author_ids(db, [post.author_id], current_user_id)
        return self._build_post_response(
            post=post,
            user=user,
            media_items=media_items,
            liked_ids=liked_ids,
            followed_author_ids=followed_author_ids,
            current_user_id=current_user_id,
        )

    def _build_post_response(
        self,
        *,
        post: Post,
        user: User | None,
        media_items: Sequence[PostMedia],
        liked_ids: set[int],
        followed_author_ids: set[int],
        current_user_id: int | None,
    ) -> PostResponse:
        content_text = post.content_text or ""
        return PostResponse(
            post_id=post.id,
            user_id=post.author_id,
            user_name=user.nickname if user else "Unknown",
            user_avatar=user.avatar_url if user else None,
            content_text=content_text,
            media_list=[
                PostMediaResponse(
                    media_type=item.media_type,
                    url=item.url,
                    thumbnail_url=item.thumbnail_url,
                )
                for item in media_items
            ],
            location_name=post.location_name,
            publish_time=post.created_at.isoformat(),
            like_count=post.like_count,
            comment_count=post.comment_count,
            view_count=post.view_count,
            is_liked=post.id in liked_ids,
            is_hot=self._is_hot(post),
            is_followed=post.author_id in followed_author_ids,
            is_mine=current_user_id == post.author_id,
        )

    def _fetch_media_map(self, db: Session, post_ids: list[int]) -> dict[int, list[PostMedia]]:
        media_map: dict[int, list[PostMedia]] = {post_id: [] for post_id in post_ids}
        media_items = db.scalars(
            select(PostMedia)
            .where(PostMedia.post_id.in_(post_ids))
            .order_by(PostMedia.post_id.asc(), PostMedia.sort_order.asc(), PostMedia.id.asc())
        ).all()
        for item in media_items:
            media_map.setdefault(item.post_id, []).append(item)
        return media_map

    def _fetch_liked_post_ids(
        self,
        db: Session,
        post_ids: list[int],
        current_user_id: int | None,
    ) -> set[int]:
        if current_user_id is None or not post_ids:
            return set()
        liked_rows = db.scalars(
            select(PostLike.post_id).where(
                PostLike.user_id == current_user_id,
                PostLike.post_id.in_(post_ids),
            )
        ).all()
        return set(liked_rows)

    def _fetch_followed_author_ids(
        self,
        db: Session,
        author_ids: list[int],
        current_user_id: int | None,
    ) -> set[int]:
        if current_user_id is None or not author_ids:
            return set()
        followed_rows = db.scalars(
            select(UserFollow.followed_user_id).where(
                UserFollow.follower_user_id == current_user_id,
                UserFollow.followed_user_id.in_(author_ids),
            )
        ).all()
        return set(followed_rows)

    def _get_user_or_raise(self, db: Session, user_id: int) -> User:
        user = db.scalar(select(User).where(User.id == user_id))
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {user_id} was not found.",
            )
        return user

    def _is_hot(self, post: Post) -> bool:
        return (post.like_count + post.comment_count) >= 10

    def _parse_cursor(self, cursor: str | None) -> int:
        if cursor is None:
            return 0
        try:
            return max(int(cursor), 0)
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Cursor must be an integer offset string.",
            ) from exc
