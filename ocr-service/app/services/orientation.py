import cv2
import numpy as np


def _detect_skew_angle(gray: np.ndarray) -> float:
    edges = cv2.Canny(gray, 50, 150, apertureSize=3)
    lines = cv2.HoughLinesP(
        edges,
        rho=1,
        theta=np.pi / 180,
        threshold=80,
        minLineLength=gray.shape[1] // 4,
        maxLineGap=20,
    )
    del edges

    if lines is None:
        return 0.0

    angles = []
    for line in lines:
        x1, y1, x2, y2 = line[0]
        if x2 != x1:
            angle = np.degrees(np.arctan2(y2 - y1, x2 - x1))

            if abs(angle) < 15:
                angles.append(angle)

    if not angles:
        return 0.0

    return float(np.median(angles))


def _rotate_image(img: np.ndarray, angle: float) -> np.ndarray:
    h, w = img.shape[:2]
    cx, cy = w // 2, h // 2
    M = cv2.getRotationMatrix2D((cx, cy), angle, 1.0)

    cos_a, sin_a = abs(M[0, 0]), abs(M[0, 1])
    new_w = int(h * sin_a + w * cos_a)
    new_h = int(h * cos_a + w * sin_a)
    M[0, 2] += (new_w / 2) - cx
    M[1, 2] += (new_h / 2) - cy

    return cv2.warpAffine(
        img,
        M,
        (new_w, new_h),
        flags=cv2.INTER_NEAREST,
        borderMode=cv2.BORDER_REPLICATE,
    )


def deskew(img: np.ndarray) -> np.ndarray:
    angle = _detect_skew_angle(img)
    if abs(angle) < 0.5:
        return img
    corrected = _rotate_image(img, -angle)
    return corrected


def _horizontal_projection_variance(img: np.ndarray) -> float:
    row_sums = img.sum(axis=1).astype(np.float32)
    return float(row_sums.var())


_ROTATIONS = {
    0: None,
    90: cv2.ROTATE_90_CLOCKWISE,
    180: cv2.ROTATE_180,
    270: cv2.ROTATE_90_COUNTERCLOCKWISE,
}


def correct_orientation(img: np.ndarray) -> tuple[np.ndarray, int]:
    best_var = -1.0
    best_img = img
    best_deg = 0

    for deg, code in _ROTATIONS.items():
        candidate = cv2.rotate(img, code) if code is not None else img
        var = _horizontal_projection_variance(candidate)
        if var > best_var:
            best_var = var
            best_img = candidate
            best_deg = deg

        if code is not None and not np.shares_memory(candidate, best_img):
            del candidate

    return best_img, best_deg


def fix_orientation(img: np.ndarray) -> tuple[np.ndarray, dict]:
    oriented, rotation_deg = correct_orientation(img)
    deskewed = deskew(oriented)

    if not np.shares_memory(oriented, img) and not np.shares_memory(oriented, deskewed):
        del oriented

    meta = {"rotation_applied_deg": rotation_deg}
    return deskewed, meta
