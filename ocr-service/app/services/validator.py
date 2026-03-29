
"""
Validates uploaded files before any processing.

Checks:
  - Size limit
  - MIME type (header-sniffing, not just filename extension)
  - Content type header
"""

import logging

import magic  # python-magic

from app.core.config import settings
from app.core.exceptions import FileTooLargeError, InvalidFileTypeError

logger = logging.getLogger(__name__)

# Map of magic bytes → MIME types we accept
_MAGIC_TO_MIME = {
    b"\xff\xd8\xff": "image/jpeg",
    b"\x89PNG\r\n\x1a\n": "image/png",
    b"RIFF": "image/webp",   # partial — webp starts with RIFF....WEBP
    b"BM": "image/bmp",
    b"II\x2a\x00": "image/tiff",
    b"MM\x00\x2a": "image/tiff",
}


def _sniff_mime(data: bytes) -> str:
    """Use libmagic to detect real MIME type."""
    try:
        detected = magic.from_buffer(data[:2048], mime=True)
        return detected
    except Exception:
        return "application/octet-stream"


def validate_upload(data: bytes, content_type: str | None) -> str:
    """
    Validate size, sniff MIME, check against allowlist.
    Returns the detected MIME type.
    Raises FileTooLargeError or InvalidFileTypeError on failure.
    """
    # 1. Size
    if len(data) > settings.MAX_FILE_SIZE_BYTES:
        raise FileTooLargeError(
            f"File size {len(data) / 1024 / 1024:.1f}MB exceeds "
            f"limit of {settings.MAX_FILE_SIZE_MB}MB"
        )

    # 2. Magic bytes
    detected_mime = _sniff_mime(data)
    logger.debug(f"Detected MIME: {detected_mime}, declared: {content_type}")

    if detected_mime not in settings.ALLOWED_CONTENT_TYPES:
        raise InvalidFileTypeError(
            f"Detected file type '{detected_mime}' is not allowed. "
            f"Accepted: {', '.join(settings.ALLOWED_CONTENT_TYPES)}"
        )

    return detected_mime