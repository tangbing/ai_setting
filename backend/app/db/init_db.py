from app.db.base import Base
from app.db.session import engine
from app.models import comment, comment_like, post, post_like, post_media, user, user_follow


def init_db() -> None:
    # Import side effects register model metadata before create_all is called.
    _ = (user, post, post_media, post_like, comment, comment_like, user_follow)
    Base.metadata.create_all(bind=engine)
