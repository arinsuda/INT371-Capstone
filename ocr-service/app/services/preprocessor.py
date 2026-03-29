import logging
import math

import cv2
import numpy as np

from app.core.config import settings
from app.core.exceptions import InvalidImageError, ImageTooSmallError

logger = logging.getLogger(__name__)


def decode_image(image_bytes: bytes) -> np.ndarray:
    arr = np.frombuffer(image_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise InvalidImageError(
            "Cannot decode image — unsupported format or corrupted file"
        )
    return img


def validate_dimensions(img: np.ndarray) -> None:
    h, w = img.shape[:2]
    if w < settings.MIN_IMAGE_WIDTH or h < settings.MIN_IMAGE_HEIGHT:
        raise ImageTooSmallError(
            f"Image {w}x{h} is below minimum {settings.MIN_IMAGE_WIDTH}x{settings.MIN_IMAGE_HEIGHT}"
        )


def resize_for_ocr(img: np.ndarray) -> np.ndarray:
    """
    Resize รูปให้อยู่ในช่วง 1200-1400px width
    - ใหญ่กว่า 1400 → downscale (ลด RAM ที่ EasyOCR ใช้)
    - เล็กกว่า 1200 → upscale (ให้ OCR อ่านได้ชัดขึ้น)
    - Thai ID card จริงๆ ไม่จำเป็นต้องใหญ่กว่า 1400px
    """
    h, w = img.shape[:2]
    target_w = 1280

    if w == target_w:
        return img

    scale = target_w / w
    new_w = target_w
    new_h = int(h * scale)

    interp = cv2.INTER_AREA if w > target_w else cv2.INTER_CUBIC
    img = cv2.resize(img, (new_w, new_h), interpolation=interp)
    logger.debug(f"Resized {w}x{h} → {new_w}x{new_h} (scale={scale:.2f})")
    return img


def deskew(img: np.ndarray) -> np.ndarray:
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
            if abs(angle) < 10:
                angles.append(angle)

        if not angles:
            return img

        median_angle = float(np.median(angles))
        if abs(median_angle) < 0.5:
            return img

        logger.debug(f"Deskewing by {median_angle:.2f}°")
        h, w = img.shape[:2]
        M = cv2.getRotationMatrix2D((w // 2, h // 2), median_angle, 1.0)
        img = cv2.warpAffine(
            img, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE
        )
    except Exception as e:
        logger.warning(f"Deskew failed (non-fatal): {e}")
    return img


def enhance_contrast(img: np.ndarray) -> np.ndarray:
    try:
        lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        l = clahe.apply(l)
        img = cv2.cvtColor(cv2.merge([l, a, b]), cv2.COLOR_LAB2BGR)
    except Exception as e:
        logger.warning(f"Contrast enhancement failed (non-fatal): {e}")
    return img


def preprocess(image_bytes: bytes) -> tuple[np.ndarray, dict]:
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

    # 1. Resize ให้อยู่ที่ 1280px เสมอ — ลด RAM ที่ EasyOCR ต้องใช้
    img = resize_for_ocr(img)
    meta["preprocessing_steps"].append("downscale" if original_w > 1280 else "upscale")

    # 2. CLAHE contrast
    img = enhance_contrast(img)
    meta["preprocessing_steps"].append("clahe")

    # 3. Deskew
    if settings.ENABLE_DESKEW:
        img = deskew(img)
        meta["preprocessing_steps"].append("deskew")

    meta["processed_width"] = img.shape[1]
    meta["processed_height"] = img.shape[0]

    logger.debug(
        f"Preprocess done: {original_w}x{original_h} → "
        f"{img.shape[1]}x{img.shape[0]}, steps={meta['preprocessing_steps']}"
    )
    return img, meta
