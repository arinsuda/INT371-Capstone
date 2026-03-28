import uuid
import redis
import json

r = redis.Redis(host="redis", port=6379)

@router.post("/ocr")
async def submit_ocr(file: UploadFile):
    raw = await file.read()
    job_id = str(uuid.uuid4())

    r.rpush("ocr_queue", json.dumps({
        "id": job_id,
        "image": raw.hex()
    }))

    return {"job_id": job_id}