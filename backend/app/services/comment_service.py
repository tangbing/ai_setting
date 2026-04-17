from __future__ import annotations

from collections import defaultdict
from collections.abc import Sequence

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.comment import Comment
from app.models.comment_like import CommentLike
from app.models.post import Post
from app.models.user import User
from app.schemas.comment import CommentCreateRequest, CommentReplyRequest, CommentResponse


class CommentService:
    def list_comments(
        self,
        db: Session,
        *,
        post_id: int,
        cursor: str | None,
        limit: int,
        current_user_id: int | None,
    ) -> tuple[list[CommentResponse], str | None]:
        self._get_post_or_raise(db, post_id)

        offset = self._parse_cursor(cursor)
        root_comments = db.scalars(
            select(Comment)
            .where(
                Comment.post_id == post_id,
                Comment.is_deleted.is_(False),
                Comment.level == 1,
            )
            .order_by(Comment.created_at.asc(), Comment.id.asc())
            .offset(offset)
            .limit(limit + 1)
        ).all()

        has_more = len(root_comments) > limit
        page_roots = root_comments[:limit]
        if not page_roots:
            return [], None

        root_ids = [comment.id for comment in page_roots]
        nested_comments = db.scalars(
            select(Comment)
            .where(
                Comment.post_id == post_id,
                Comment.is_deleted.is_(False),
                Comment.root_comment_id.in_(root_ids),
            )
            .order_by(Comment.created_at.asc(), Comment.id.asc())
        ).all()

        all_comments = [*page_roots, *nested_comments]
        serialized = self._build_comment_tree(
            db,
            comments=all_comments,
            current_user_id=current_user_id,
        )
        next_cursor = str(offset + limit) if has_more else None
        return serialized, next_cursor

    def create_comment(
        self,
        db: Session,
        *,
        post_id: int,
        payload: CommentCreateRequest,
        current_user_id: int,
    ) -> CommentResponse:
        self._get_post_or_raise(db, post_id)
        self._get_user_or_raise(db, current_user_id)

        comment = Comment(
            post_id=post_id,
            user_id=current_user_id,
            content=payload.content.strip(),
            level=1,
        )
        db.add(comment)

        post = self._get_post_or_raise(db, post_id)
        post.comment_count += 1
        db.add(post)

        db.commit()
        db.refresh(comment)
        return self._serialize_comment(db, comment=comment, current_user_id=current_user_id)

    def reply_comment(
        self,
        db: Session,
        *,
        comment_id: int,
        payload: CommentReplyRequest,
        current_user_id: int,
    ) -> CommentResponse:
        parent = self._get_comment_or_raise(db, comment_id)
        self._get_user_or_raise(db, current_user_id)

        root_comment_id = parent.root_comment_id or parent.id
        target_level = min(parent.level + 1, 3)

        reply = Comment(
            post_id=parent.post_id,
            user_id=current_user_id,
            parent_comment_id=parent.id,
            root_comment_id=root_comment_id,
            reply_to_user_id=parent.user_id,
            content=payload.content.strip(),
            level=target_level,
        )
        db.add(reply)

        post = self._get_post_or_raise(db, parent.post_id)
        post.comment_count += 1
        db.add(post)

        db.commit()
        db.refresh(reply)
        return self._serialize_comment(db, comment=reply, current_user_id=current_user_id)

    def _build_comment_tree(
        self,
        db: Session,
        *,
        comments: Sequence[Comment],
        current_user_id: int | None,
    ) -> list[CommentResponse]:
        if not comments:
            return []

        user_ids = {
            comment.user_id
            for comment in comments
        } | {
            comment.reply_to_user_id
            for comment in comments
            if comment.reply_to_user_id is not None
        }
        users = {
            user.id: user
            for user in db.scalars(select(User).where(User.id.in_(user_ids))).all()
        }
        liked_ids = self._fetch_liked_comment_ids(
            db,
            comment_ids=[comment.id for comment in comments],
            current_user_id=current_user_id,
        )

        children_map: dict[int, list[Comment]] = defaultdict(list)
        root_comments: list[Comment] = []
        for comment in comments:
            if comment.level == 1:
                root_comments.append(comment)
                continue
            if comment.parent_comment_id is not None:
                children_map[comment.parent_comment_id].append(comment)

        return [
            self._build_comment_response(
                comment=comment,
                users=users,
                liked_ids=liked_ids,
                children_map=children_map,
            )
            for comment in root_comments
        ]

    def _build_comment_response(
        self,
        *,
        comment: Comment,
        users: dict[int, User],
        liked_ids: set[int],
        children_map: dict[int, list[Comment]],
    ) -> CommentResponse:
        author = users.get(comment.user_id)
        reply_to_user = users.get(comment.reply_to_user_id) if comment.reply_to_user_id else None
        return CommentResponse(
            comment_id=comment.id,
            post_id=comment.post_id,
            parent_comment_id=comment.parent_comment_id,
            root_comment_id=comment.root_comment_id,
            reply_to_user_id=comment.reply_to_user_id,
            reply_to_user_name=reply_to_user.nickname if reply_to_user else None,
            user_id=comment.user_id,
            user_name=author.nickname if author else "Unknown",
            user_avatar=author.avatar_url if author else None,
            content=comment.content,
            level=comment.level,
            like_count=comment.like_count,
            is_liked=comment.id in liked_ids,
            create_time=comment.created_at.isoformat(),
            replies=[
                self._build_comment_response(
                    comment=child,
                    users=users,
                    liked_ids=liked_ids,
                    children_map=children_map,
                )
                for child in children_map.get(comment.id, [])
            ],
        )

    def _serialize_comment(
        self,
        db: Session,
        *,
        comment: Comment,
        current_user_id: int | None,
    ) -> CommentResponse:
        users = {}
        author = self._get_user_or_raise(db, comment.user_id)
        users[author.id] = author
        if comment.reply_to_user_id is not None:
            reply_to_user = self._get_user_or_raise(db, comment.reply_to_user_id)
            users[reply_to_user.id] = reply_to_user
        liked_ids = self._fetch_liked_comment_ids(db, [comment.id], current_user_id)
        return self._build_comment_response(
            comment=comment,
            users=users,
            liked_ids=liked_ids,
            children_map={},
        )

    def _fetch_liked_comment_ids(
        self,
        db: Session,
        comment_ids: list[int],
        current_user_id: int | None,
    ) -> set[int]:
        if current_user_id is None or not comment_ids:
            return set()
        rows = db.scalars(
            select(CommentLike.comment_id).where(
                CommentLike.user_id == current_user_id,
                CommentLike.comment_id.in_(comment_ids),
            )
        ).all()
        return set(rows)

    def _get_post_or_raise(self, db: Session, post_id: int) -> Post:
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
        return post

    def _get_comment_or_raise(self, db: Session, comment_id: int) -> Comment:
        comment = db.scalar(
            select(Comment).where(
                Comment.id == comment_id,
                Comment.is_deleted.is_(False),
            )
        )
        if comment is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Comment {comment_id} was not found.",
            )
        return comment

    def _get_user_or_raise(self, db: Session, user_id: int) -> User:
        user = db.scalar(select(User).where(User.id == user_id))
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {user_id} was not found.",
            )
        return user

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
