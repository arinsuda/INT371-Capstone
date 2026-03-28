import cv2
import numpy as np

from app.core.config import settings
from app.services.orientation import fix_orientation


def preprocess(image_bytes: bytes) -> tuple[np.ndarray, np.ndarray, dict]:
    """
    Decode, resize, fix orientation, enhance, and threshold the image.

    Returns:
        (id_region, name_region, meta)
        meta contains orientation diagnostics for the response.

    Raises ValueError for corrupt / unreadable images.
    """
    arr = np.frombuffer(image_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    del arr

    if img is None:
        raise ValueError("Could not decode image — corrupt or unsupported format")

    h, w = img.shape[:2]
    if w > settings.MAX_IMAGE_WIDTH:
        scale = settings.MAX_IMAGE_WIDTH / w
        new_w, new_h = int(w * scale), int(h * scale)
        resized = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_AREA)
        del img
        img = resized
        del resized

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    del img

    gray, orientation_meta = fix_orientation(gray)

    cv2.equalizeHist(gray, dst=gray)

    cv2.GaussianBlur(gray, (3, 3), 0, dst=gray)

    thresh = cv2.adaptiveThreshold(
        gray,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        blockSize=31,
        C=2,
    )
    del gray

    id_region, name_region = _crop_regions(thresh)
    del thresh

    return id_region, name_region, orientation_meta


def _crop_regions(img: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    h, w = img.shape[:2]
    id_region = img[int(h * 0.15) : int(h * 0.35), int(w * 0.05) : int(w * 0.70)]
    name_region = img[int(h * 0.35) : int(h * 0.60), int(w * 0.05) : int(w * 0.90)]
    return np.ascontiguousarray(id_region), np.ascontiguousarray(name_region)
