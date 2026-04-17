from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app.api.deps import get_current_user_id
from app.core.config import settings

router = APIRouter(prefix="/uploads", tags=["uploads"])


@router.post("/images")
async def upload_image(
    file: UploadFile = File(...),
    _: int = Depends(get_current_user_id),
) -> dict[str, str]:
    content_type = (file.content_type or "").lower()
    if content_type not in {"image/jpeg", "image/png", "image/webp", "image/gif"}:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only jpeg, png, webp, and gif images are supported.",
        )

    suffix = Path(file.filename or "").suffix.lower()
    if not suffix:
        suffix = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/webp": ".webp",
            "image/gif": ".gif",
        }.get(content_type, ".jpg")

    filename = f"{uuid4().hex}{suffix}"
    destination = settings.upload_dir_path / filename

    content = await file.read()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty.",
        )

    destination.write_bytes(content)
    relative_url = f"{settings.upload_mount_path}/{filename}"
    return {
        "filename": filename,
        "url": relative_url,
    }
