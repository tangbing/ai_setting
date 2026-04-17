from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.comment import Comment
from app.models.comment_like import CommentLike
from app.models.post import Post
from app.models.post_like import PostLike
from app.models.user import User


class LikeService:
    def like_post(self, db: Session, *, post_id: int, user_id: int) -> int:
        self._get_user_or_raise(db, user_id)
        post = self._get_post_or_raise(db, post_id)
        existing = db.scalar(
            select(PostLike).where(PostLike.post_id == post_id, PostLike.user_id == user_id)
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"User {user_id} already liked post {post_id}.",
            )

        db.add(PostLike(post_id=post_id, user_id=user_id))
        post.like_count += 1
        db.add(post)
        db.commit()
        return post.like_count

    def unlike_post(self, db: Session, *, post_id: int, user_id: int) -> None:
        self._get_user_or_raise(db, user_id)
        post = self._get_post_or_raise(db, post_id)
        existing = db.scalar(
            select(PostLike).where(PostLike.post_id == post_id, PostLike.user_id == user_id)
        )
        if existing is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Like record for post {post_id} was not found.",
            )

        db.delete(existing)
        post.like_count = max(post.like_count - 1, 0)
        db.add(post)
        db.commit()

    def like_comment(self, db: Session, *, comment_id: int, user_id: int) -> int:
        self._get_user_or_raise(db, user_id)
        comment = self._get_comment_or_raise(db, comment_id)
        existing = db.scalar(
            select(CommentLike).where(
                CommentLike.comment_id == comment_id,
                CommentLike.user_id == user_id,
            )
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"User {user_id} already liked comment {comment_id}.",
            )

        db.add(CommentLike(comment_id=comment_id, user_id=user_id))
        comment.like_count += 1
        db.add(comment)
        db.commit()
        return comment.like_count

    def unlike_comment(self, db: Session, *, comment_id: int, user_id: int) -> None:
        self._get_user_or_raise(db, user_id)
        comment = self._get_comment_or_raise(db, comment_id)
        existing = db.scalar(
            select(CommentLike).where(
                CommentLike.comment_id == comment_id,
                CommentLike.user_id == user_id,
            )
        )
        if existing is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Like record for comment {comment_id} was not found.",
            )

        db.delete(existing)
        comment.like_count = max(comment.like_count - 1, 0)
        db.add(comment)
        db.commit()

    def _get_user_or_raise(self, db: Session, user_id: int) -> User:
        user = db.scalar(select(User).where(User.id == user_id))
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {user_id} was not found.",
            )
        return user

    def _get_post_or_raise(self, db: Session, post_id: int) -> Post:
        post = db.scalar(select(Post).where(Post.id == post_id, Post.is_deleted.is_(False)))
        if post is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Post {post_id} was not found.",
            )
        return post

    def _get_comment_or_raise(self, db: Session, comment_id: int) -> Comment:
        comment = db.scalar(
            select(Comment).where(Comment.id == comment_id, Comment.is_deleted.is_(False))
        )
        if comment is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Comment {comment_id} was not found.",
            )
        return comment
