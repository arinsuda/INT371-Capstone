import cv2
import numpy as np
from app.core.config import settings


def preprocess(image_bytes: bytes):
    arr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)

    if img is None:
        raise ValueError("Invalid image")

    h, w = img.shape[:2]

    if w > settings.MAX_IMAGE_WIDTH:
        scale = settings.MAX_IMAGE_WIDTH / w
        img = cv2.resize(img, (int(w * scale), int(h * scale)))

    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    return img