from fastapi import FastAPI, UploadFile, File
from paddleocr import PaddleOCR
import numpy as np
import cv2

app = FastAPI()

ocr = PaddleOCR(
    use_angle_cls=True,
    lang="latin",
    use_gpu=False,
    det_db_score_mode="slow",
)

@app.post("/ocr")
async def run_ocr(file: UploadFile = File(...)):
    image_bytes = await file.read()

    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    result = ocr.ocr(img, cls=True)

    outputs = []
    for line in result[0]:
        bbox, (text, conf) = line
        outputs.append({
            "text": text,
            "confidence": float(conf),
            "bbox": bbox
        })

    return {
        "count": len(outputs),
        "items": outputs
    }

@app.get("/health")
def health():
    return {"ok": True}
