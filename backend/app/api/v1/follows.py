from fastapi import APIRouter, Depends

from app.api.deps import get_current_user_id

router = APIRouter(prefix="/users", tags=["follows"])


@router.post("/{user_id}/follow")
async def follow_user(
    user_id: int,
    _: int = Depends(get_current_user_id),
) -> dict[str, int]:
    return {"userId": user_id}


@router.delete("/{user_id}/follow")
async def unfollow_user(
    user_id: int,
    _: int = Depends(get_current_user_id),
) -> dict[str, int]:
    return {"userId": user_id}
