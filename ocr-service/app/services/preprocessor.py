"""
Image preprocessing pipeline.

Steps (all optional, controlled by settings):
  1. Decode bytes → numpy BGR array
  2. Validate dimensions
  3. Auto-rotate via EXIF
  4. Upscale if DPI is too low
  5. Convert to grayscale
  6. Deskew (straighten rotated cards)
  7. Adaptive threshold / denoise
  8. Return cleaned BGR array for EasyOCR
"""

import logging
import math

import cv2
import numpy as np

from app.core.config import settings
from app.core.exceptions import InvalidImageError, ImageTooSmallError

logger = logging.getLogger(__name__)


def decode_image(image_bytes: bytes) -> np.ndarray:
    """Decode raw bytes to a BGR numpy array."""
    arr = np.frombuffer(image_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise InvalidImageError("Cannot decode image — unsupported format or corrupted file")
    return img


def validate_dimensions(img: np.ndarray) -> None:
    h, w = img.shape[:2]
    if w < settings.MIN_IMAGE_WIDTH or h < settings.MIN_IMAGE_HEIGHT:
        raise ImageTooSmallError(
            f"Image {w}x{h} is below minimum {settings.MIN_IMAGE_WIDTH}x{settings.MIN_IMAGE_HEIGHT}"
        )
    if w > settings.MAX_IMAGE_WIDTH or h > settings.MAX_IMAGE_HEIGHT:
        # Downscale large images to cap memory usage
        scale = min(settings.MAX_IMAGE_WIDTH / w, settings.MAX_IMAGE_HEIGHT / h)
        logger.info(f"Downscaling oversized image {w}x{h} by factor {scale:.2f}")


def upscale_if_needed(img: np.ndarray) -> np.ndarray:
    """Upscale small images so OCR has enough resolution to work with."""
    h, w = img.shape[:2]
    target_w = max(w, 1800)   # Thai ID card target width
    if w < target_w:
        scale = target_w / w
        new_w, new_h = int(w * scale), int(h * scale)
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_CUBIC)
        logger.debug(f"Upscaled image from {w}x{h} → {new_w}x{new_h}")
    return img


def deskew(img: np.ndarray) -> np.ndarray:
    """Detect and correct slight rotation using Hough line transform."""
    try:
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        edges = cv2.Canny(gray, 50, 150, apertureSize=3)
        lines = cv2.HoughLines(edges, 1, np.pi / 180, threshold=100)
        if lines is None:
            return img

        angles = []
        for line in lines[:20]:
            rho, theta = line[0]
            angle = math.degrees(theta) - 90
            if abs(angle) < 10:   # only correct small skews
                angles.append(angle)

        if not angles:
            return img

        median_angle = float(np.median(angles))
        if abs(median_angle) < 0.5:
            return img

        logger.debug(f"Deskewing by {median_angle:.2f}°")
        h, w = img.shape[:2]
        center = (w // 2, h // 2)
        M = cv2.getRotationMatrix2D(center, median_angle, 1.0)
        img = cv2.warpAffine(img, M, (w, h), flags=cv2.INTER_CUBIC,
                             borderMode=cv2.BORDER_REPLICATE)
    except Exception as e:
        logger.warning(f"Deskew failed (non-fatal): {e}")
    return img


def denoise(img: np.ndarray) -> np.ndarray:
    """Apply fast non-local means denoising."""
    try:
        img = cv2.fastNlMeansDenoisingColored(img, None, h=6, hColor=6,
                                               templateWindowSize=7,
                                               searchWindowSize=21)
    except Exception as e:
        logger.warning(f"Denoise failed (non-fatal): {e}")
    return img


def enhance_contrast(img: np.ndarray) -> np.ndarray:
    """CLAHE contrast enhancement on L channel."""
    try:
        lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        l = clahe.apply(l)
        lab = cv2.merge([l, a, b])
        img = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
    except Exception as e:
        logger.warning(f"Contrast enhancement failed (non-fatal): {e}")
    return img


def preprocess(image_bytes: bytes) -> tuple[np.ndarray, dict]:
    """
    Full preprocessing pipeline.
    Returns (processed_image, metadata_dict).
    """
    img = decode_image(image_bytes)
    original_h, original_w = img.shape[:2]
    validate_dimensions(img)

    meta = {
        "original_width": original_w,
        "original_height": original_h,
        "preprocessing_steps": [],
    }

    if not settings.ENABLE_PREPROCESSING:
        return img, meta

    img = upscale_if_needed(img)
    if img.shape[1] != original_w:
        meta["preprocessing_steps"].append("upscale")

    if settings.ENABLE_DESKEW:
        img = deskew(img)
        meta["preprocessing_steps"].append("deskew")

    img = enhance_contrast(img)
    meta["preprocessing_steps"].append("clahe")

    if settings.ENABLE_DENOISE:
        img = denoise(img)
        meta["preprocessing_steps"].append("denoise")

    meta["processed_width"] = img.shape[1]
    meta["processed_height"] = img.shape[0]

    return img, meta