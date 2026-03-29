import logging
import math

import cv2
import numpy as np

from app.core.config import settings
from app.services.orientation import fix_orientation

logger = logging.getLogger(__name__)


def _decode(image_bytes: bytes) -> np.ndarray:
    arr = np.frombuffer(image_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Could not decode image — corrupt or unsupported format")
    return img


def _resize(img: np.ndarray, target_w: int = 1280) -> np.ndarray:
    """
    Resize ให้ได้ target_w เสมอ
    - ใหญ่กว่า → INTER_AREA (downscale)
    - เล็กกว่า → INTER_CUBIC (upscale ให้ OCR อ่านชัดขึ้น)
    """
    h, w = img.shape[:2]
    if w == target_w:
        return img
    scale = target_w / w
    new_h = int(h * scale)
    interp = cv2.INTER_AREA if w > target_w else cv2.INTER_CUBIC
    return cv2.resize(img, (target_w, new_h), interpolation=interp)


def _clahe(img: np.ndarray) -> np.ndarray:
    """
    CLAHE บน L channel ของ LAB — ดีกว่า equalizeHist มากสำหรับภาพที่มี
    background สีหรือแสงไม่สม่ำเสมอ (เช่น บัตรสีฟ้า/เขียว)
    """
    try:
        lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        l = clahe.apply(l)
        return cv2.cvtColor(cv2.merge([l, a, b]), cv2.COLOR_LAB2BGR)
    except Exception as e:
        logger.warning("CLAHE failed (non-fatal): %s", e)
        return img


def _deskew(img: np.ndarray) -> np.ndarray:
    """Detect และ correct skew angle ไม่เกิน ±10°"""
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

        logger.debug("Deskewing by %.2f°", median_angle)
        h, w = img.shape[:2]
        M = cv2.getRotationMatrix2D((w // 2, h // 2), median_angle, 1.0)
        return cv2.warpAffine(img, M, (w, h),
                              flags=cv2.INTER_CUBIC,
                              borderMode=cv2.BORDER_REPLICATE)
    except Exception as e:
        logger.warning("Deskew failed (non-fatal): %s", e)
        return img


def _crop_regions(img: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """
    Crop ตาม layout บัตรประชาชนไทย
    - id_region:   แถวบน  (เลข 13 หลัก)
    - name_region: แถวกลาง (ชื่อ-นามสกุล)

    x เริ่มจาก 0.20 เพื่อตัด barcode ด้านซ้ายออก
    """
    h, w = img.shape[:2]
    id_region   = img[int(h * 0.05) : int(h * 0.35), int(w * 0.20) : int(w * 0.95)]
    name_region = img[int(h * 0.35) : int(h * 0.60), int(w * 0.20) : int(w * 0.95)]
    return np.ascontiguousarray(id_region), np.ascontiguousarray(name_region)


def preprocess(image_bytes: bytes) -> tuple[np.ndarray, np.ndarray, dict]:
    """
    Pipeline:
      1. Decode
      2. Resize → 1280px (upscale ถ้าเล็กกว่า, downscale ถ้าใหญ่กว่า)
      3. CLAHE contrast enhancement (LAB colorspace)
      4. Deskew (optional, ควบคุมด้วย SKIP_ORIENTATION_CHECK)
      5. Crop 2 regions → ส่งเข้า EasyOCR แยกกัน (accurate กว่า full image)

    Returns:
        (id_region, name_region, orientation_meta)
        โดย id_region และ name_region เป็น BGR image (ไม่ threshold)
        เพราะ EasyOCR จัดการ preprocessing ภายในได้ดีกว่า

    Raises:
        ValueError — corrupt / unreadable image
    """
    img = _decode(image_bytes)

    original_h, original_w = img.shape[:2]
    logger.debug("Input image: %dx%d", original_w, original_h)

    # 1. Resize
    img = _resize(img, target_w=1280)

    # 2. CLAHE
    img = _clahe(img)

    # 3. Orientation / deskew
    if settings.SKIP_ORIENTATION_CHECK:
        orientation_meta: dict = {"rotation_applied_deg": 0}
    else:
        img = _deskew(img)
        orientation_meta = {"rotation_applied_deg": 0}

    # 4. Crop regions
    id_region, name_region = _crop_regions(img)
    del img

    logger.debug(
        "Preprocessed: %dx%d → id_region=%s name_region=%s",
        original_w, original_h,
        id_region.shape, name_region.shape,
    )

    return id_region, name_region, orientation_meta