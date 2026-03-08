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
        raise InvalidImageError("Cannot decode image — unsupported format or corrupted file")
    return img


def validate_dimensions(img: np.ndarray) -> None:
    h, w = img.shape[:2]
    if w < settings.MIN_IMAGE_WIDTH or h < settings.MIN_IMAGE_HEIGHT:
        raise ImageTooSmallError(
            f"Image {w}x{h} is below minimum {settings.MIN_IMAGE_WIDTH}x{settings.MIN_IMAGE_HEIGHT}"
        )


def downscale_if_needed(img: np.ndarray) -> np.ndarray:
    """ลดขนาดรูปที่ใหญ่เกินไปก่อน — ป้องกัน RAM spike ตอน preprocess"""
    h, w = img.shape[:2]
    max_w = 2000  # Thai ID card ไม่จำเป็นต้องใหญ่กว่านี้
    if w > max_w:
        scale = max_w / w
        new_w, new_h = int(w * scale), int(h * scale)
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_AREA)
        logger.debug(f"Downscaled {w}x{h} → {new_w}x{new_h}")
    return img


def upscale_if_needed(img: np.ndarray) -> np.ndarray:
    """Upscale รูปที่เล็กเกินไป"""
    h, w = img.shape[:2]
    target_w = 1400
    if w < target_w:
        scale = target_w / w
        new_w, new_h = int(w * scale), int(h * scale)
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_CUBIC)
        logger.debug(f"Upscaled {w}x{h} → {new_w}x{new_h}")
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
        center = (w // 2, h // 2)
        M = cv2.getRotationMatrix2D(center, median_angle, 1.0)
        img = cv2.warpAffine(img, M, (w, h), flags=cv2.INTER_CUBIC,
                             borderMode=cv2.BORDER_REPLICATE)
    except Exception as e:
        logger.warning(f"Deskew failed (non-fatal): {e}")
    return img


def enhance_contrast(img: np.ndarray) -> np.ndarray:
    """CLAHE contrast enhancement — เบาและเร็ว"""
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

    # 1. Downscale ก่อนเสมอ — ป้องกัน RAM spike
    img = downscale_if_needed(img)
    if img.shape[1] != original_w:
        meta["preprocessing_steps"].append("downscale")

    # 2. Upscale ถ้าเล็กเกินไป
    img = upscale_if_needed(img)
    if img.shape[1] != original_w and "downscale" not in meta["preprocessing_steps"]:
        meta["preprocessing_steps"].append("upscale")

    # 3. CLAHE contrast — เบา ไม่กิน RAM
    img = enhance_contrast(img)
    meta["preprocessing_steps"].append("clahe")

    # 4. Deskew — ถ้าเปิดใช้
    if settings.ENABLE_DESKEW:
        img = deskew(img)
        meta["preprocessing_steps"].append("deskew")

    # NOTE: denoise ถูกปิดโดยเจตนา
    # fastNlMeansDenoisingColored กิน RAM มากบน CPU และทำให้ container crash
    # ถ้าจะเปิดต้องมี RAM อย่างน้อย 8GB และใช้ GPU

    meta["processed_width"] = img.shape[1]
    meta["processed_height"] = img.shape[0]

    logger.debug(
        f"Preprocess done: {original_w}x{original_h} → "
        f"{img.shape[1]}x{img.shape[0]}, steps={meta['preprocessing_steps']}"
    )

    return img, meta