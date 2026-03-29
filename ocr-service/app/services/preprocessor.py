import cv2
import numpy as np

from app.core.config import settings
from app.services.orientation import fix_orientation


def preprocess(image_bytes: bytes) -> tuple[np.ndarray, dict, dict]:
    """
    Decode, resize, fix orientation, enhance, and threshold the image.

    Returns:
        (full_thresh, region_coords, orientation_meta)

        full_thresh   — full preprocessed image สำหรับส่งเข้า OCR engine ครั้งเดียว
        region_coords — { "id": (y0,y1,x0,x1), "name": (y0,y1,x0,x1) }
                        ใช้ filter ผล OCR ตาม bounding box ภายหลัง
        orientation_meta — { "rotation_applied_deg": int }

    Raises ValueError for corrupt / unreadable images.

    เปลี่ยนจากเดิมที่ crop ก่อนแล้ว return 2 regions แยก
    → return full image เพื่อให้ engine.read() ทำแค่ครั้งเดียว
      แล้วค่อย filter ผลด้วย _items_in_region() ใน routes.py
    """
    arr = np.frombuffer(image_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    del arr

    if img is None:
        raise ValueError("Could not decode image — corrupt or unsupported format")

    h, w = img.shape[:2]
    if w > settings.MAX_IMAGE_WIDTH:
        scale = settings.MAX_IMAGE_WIDTH / w
        new_w = int(w * scale)
        new_h = int(h * scale)
        resized = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_AREA)
        del img
        img = resized
        del resized
        h, w = new_h, new_w

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    del img

    if settings.SKIP_ORIENTATION_CHECK:
        orientation_meta: dict = {"rotation_applied_deg": 0}
    else:
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

    
    th, tw = thresh.shape[:2]
    region_coords = {
        "id": (int(th * 0.15), int(th * 0.35), int(tw * 0.05), int(tw * 0.70)),
        "name": (int(th * 0.35), int(th * 0.60), int(tw * 0.05), int(tw * 0.90)),
    }

    return np.ascontiguousarray(thresh), region_coords, orientation_meta
