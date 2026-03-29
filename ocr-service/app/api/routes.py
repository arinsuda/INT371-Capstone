import asyncio
import time
import uuid

from fastapi import APIRouter, UploadFile, File, Request
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.engine import ocr_engine
from app.core.exceptions import (
    FileTooLargeError,
    InvalidFileTypeError,
    OCRTimeoutError,
    BatchTooLargeError,
)
from app.models.schemas import BatchItemResult, OrientationMeta
from app.services.preprocessor import preprocess
from app.services.validator import validate_upload
from app.services.thai_id import extract_thai_id, validate_thai_id
from app.services.normalizer import normalize_name_from_ocr_items
from app.services.rate_limiter import rate_limiter

router = APIRouter()


def _get_client_ip(request: Request) -> str:
    peer = request.client.host if request.client else None
    if peer in settings.TRUSTED_PROXY_IPS:
        forwarded = request.headers.get("X-Forwarded-For", "")
        if forwarded:
            return forwarded.split(",")[0].strip()
    return peer or "unknown"


def _bbox_center_y(bbox: list) -> float:
    """คำนวณ center y จาก bounding box ของ EasyOCR [[x,y], [x,y], [x,y], [x,y]]"""
    ys = [pt[1] for pt in bbox]
    return (min(ys) + max(ys)) / 2


def _bbox_center_x(bbox: list) -> float:
    xs = [pt[0] for pt in bbox]
    return (min(xs) + max(xs)) / 2


def _items_in_region(
    items: list[dict], region: tuple[int, int, int, int]
) -> list[dict]:
    """
    Filter OCR items ที่มี center point อยู่ใน region (y0, y1, x0, x1)
    ใช้แทนการ crop image ก่อน inference
    """
    y0, y1, x0, x1 = region
    result = []
    for item in items:
        cy = _bbox_center_y(item["bbox"])
        cx = _bbox_center_x(item["bbox"])
        if y0 <= cy <= y1 and x0 <= cx <= x1:
            result.append(item)
    return result


async def _process_single(raw: bytes, content_type: str | None) -> dict:
    validate_upload(raw, content_type)

    full_img, region_coords, orientation_meta = preprocess(raw)
    del raw

    all_texts = await ocr_engine.read(full_img)
    del full_img

    id_texts = _items_in_region(all_texts, region_coords["id"])
    name_texts = _items_in_region(all_texts, region_coords["name"])

    thai_id = extract_thai_id(id_texts)
    valid = validate_thai_id(thai_id) if thai_id else False
    name_raw = normalize_name_from_ocr_items(name_texts)

    return {
        "id_number": thai_id,
        "valid": valid,
        "name_raw": name_raw,
        "orientation_meta": orientation_meta,
        "id_texts": id_texts,
        "name_texts": name_texts,
    }


@router.post("/ocr")
async def ocr(request: Request, file: UploadFile = File(...)):
    request_id = str(uuid.uuid4())
    t0 = time.perf_counter()

    await rate_limiter.check(_get_client_ip(request))

    raw = await file.read()

    try:
        result = await _process_single(raw, file.content_type)
    except FileTooLargeError:
        return JSONResponse(
            status_code=413,
            content={
                "success": False,
                "error": "FileTooLarge",
                "message": f"File exceeds {settings.MAX_FILE_SIZE_BYTES // (1024 * 1024)} MB limit",
                "request_id": request_id,
            },
        )
    except InvalidFileTypeError:
        return JSONResponse(
            status_code=415,
            content={
                "success": False,
                "error": "InvalidFileType",
                "message": f"Allowed types: {', '.join(settings.ALLOWED_CONTENT_TYPES)}",
                "request_id": request_id,
            },
        )

    response: dict = {
        "request_id": request_id,
        "elapsed_ms": round((time.perf_counter() - t0) * 1000, 2),
        "id_number": result["id_number"],
        "valid": result["valid"],
        "name_raw": result["name_raw"],
        "orientation": OrientationMeta(**result["orientation_meta"]),
    }
    if settings.DEBUG:
        response["debug"] = {
            "id_texts": result["id_texts"],
            "name_texts": result["name_texts"],
        }

    return response


@router.post("/ocr/batch")
async def ocr_batch(request: Request, files: list[UploadFile] = File(...)):
    request_id = str(uuid.uuid4())
    t0 = time.perf_counter()

    await rate_limiter.check(_get_client_ip(request))

    if len(files) > settings.BATCH_MAX_FILES:
        return JSONResponse(
            status_code=422,
            content={
                "success": False,
                "error": "BatchTooLarge",
                "message": f"Maximum {settings.BATCH_MAX_FILES} files per batch request",
                "request_id": request_id,
            },
        )

    sem = asyncio.Semaphore(settings.BATCH_MAX_CONCURRENCY)

    async def _process_item(index: int, upload: UploadFile) -> BatchItemResult:
        async with sem:
            raw = await upload.read()
            try:
                result = await _process_single(raw, upload.content_type)
                return BatchItemResult(
                    filename=upload.filename or f"file_{index}",
                    index=index,
                    success=True,
                    id_number=result["id_number"],
                    valid=result["valid"],
                    name_raw=result["name_raw"],
                    orientation=OrientationMeta(**result["orientation_meta"]),
                )
            except (FileTooLargeError, InvalidFileTypeError, ValueError) as exc:
                return BatchItemResult(
                    filename=upload.filename or f"file_{index}",
                    index=index,
                    success=False,
                    error=type(exc).__name__,
                )
            except OCRTimeoutError:
                return BatchItemResult(
                    filename=upload.filename or f"file_{index}",
                    index=index,
                    success=False,
                    error="OCRTimeout",
                )

    results = await asyncio.gather(*(_process_item(i, f) for i, f in enumerate(files)))
    results = sorted(results, key=lambda r: r.index)
    succeeded = sum(1 for r in results if r.success)

    return {
        "request_id": request_id,
        "elapsed_ms": round((time.perf_counter() - t0) * 1000, 2),
        "total": len(results),
        "succeeded": succeeded,
        "failed": len(results) - succeeded,
        "results": results,
    }


@router.get("/healthz")
async def healthz():
    return {"status": "ok"}


@router.get("/readyz")
async def readyz():
    if not ocr_engine.is_ready:
        return JSONResponse(status_code=503, content={"status": "not_ready"})
    return {"status": "ready", "languages": settings.OCR_LANGUAGES}
