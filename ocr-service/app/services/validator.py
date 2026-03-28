import logging

import magic

from app.core.config import settings
from app.core.exceptions import FileTooLargeError, InvalidFileTypeError

logger = logging.getLogger(__name__)

def _sniff_mime(data: bytes) -> str:
    try:
        return magic.from_buffer(data[:2048], mime=True)
    except Exception:
        return "application/octet-stream"


def validate_upload(data: bytes, content_type: str | None) -> None:
    if len(data) > settings.MAX_FILE_SIZE_BYTES:
        raise FileTooLargeError(
            f"File size {len(data)} exceeds limit {settings.MAX_FILE_SIZE_BYTES}"
        )

    detected_mime = _sniff_mime(data)
    logger.debug(f"Detected MIME: {detected_mime}, declared: {content_type}")

    if detected_mime not in settings.ALLOWED_CONTENT_TYPES:
        raise InvalidFileTypeError(
            f"Detected file type '{detected_mime}' is not allowed. "
            f"Accepted: {', '.join(settings.ALLOWED_CONTENT_TYPES)}"
        )
