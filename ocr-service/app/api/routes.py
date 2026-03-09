import logging
import time

from fastapi import APIRouter, Request, UploadFile, File, Depends
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.engine import ocr_engine
from app.models.schemas import OCRResponse, OCRItem, BBox, HealthResponse, PreprocessingMeta
from app.services.validator import validate_upload
from app.services.preprocessor import preprocess

logger = logging.getLogger(__name__)

router = APIRouter()


# ── Health ───────────────────────────────────────────────────────────────────

@router.get(
    "/health",
    response_model=HealthResponse,
    tags=["Ops"],
    summary="Health check",
)
async def health():
    return HealthResponse(
        status="ok",
        version="2.0.0",
        engine="easyocr",
        languages=settings.OCR_LANGUAGES,
        gpu=settings.OCR_USE_GPU,
        workers=settings.OCR_WORKERS,
    )


@router.get("/readyz", tags=["Ops"], summary="Readiness probe")
async def readyz():
    if not ocr_engine._ready:
        return JSONResponse(status_code=503, content={"status": "not_ready"})
    return {"status": "ready"}


# ── OCR ──────────────────────────────────────────────────────────────────────

@router.post(
    "/ocr",
    response_model=OCRResponse,
    tags=["OCR"],
    summary="Scan image and extract text",
    responses={
        413: {"description": "File too large"},
        415: {"description": "Unsupported file type"},
        422: {"description": "Invalid or unreadable image"},
        504: {"description": "OCR timed out"},
    },
)
async def run_ocr(
    request: Request,
    file: UploadFile = File(..., description="Image file (JPEG, PNG, WebP, BMP, TIFF)"),
):
    t_start = time.perf_counter()
    request_id = getattr(request.state, "request_id", None)

    # 1. Read bytes
    raw = await file.read()

    # 2. Validate file type + size
    validate_upload(raw, file.content_type)

    # 3. Preprocess
    img, meta = preprocess(raw)

    # 4. OCR
    raw_results = await ocr_engine.read(img)

    # 5. Shape response
    items = [
        OCRItem(
            text=r["text"],
            confidence=r["confidence"],
            bbox=BBox.from_easyocr(r["bbox"]),
        )
        for r in raw_results
    ]

    elapsed_ms = round((time.perf_counter() - t_start) * 1000, 2)

    return OCRResponse(
        count=len(items),
        items=items,
        request_id=request_id,
        elapsed_ms=elapsed_ms,
        preprocessing=PreprocessingMeta(**meta),
    )


# ── Batch ────────────────────────────────────────────────────────────────────

@router.post(
    "/ocr/batch",
    tags=["OCR"],
    summary="Scan multiple images (max 5)",
)
async def run_ocr_batch(
    request: Request,
    files: list[UploadFile] = File(...),
):
    import asyncio

    if len(files) > 5:
        return JSONResponse(
            status_code=400,
            content={"success": False, "error": "TOO_MANY_FILES", "message": "Max 5 files per batch"},
        )

    async def process_one(f: UploadFile, index: int):
        try:
            raw = await f.read()
            validate_upload(raw, f.content_type)
            img, meta = preprocess(raw)
            raw_results = await ocr_engine.read(img)
            items = [
                {"text": r["text"], "confidence": r["confidence"], "bbox": r["bbox"]}
                for r in raw_results
            ]
            return {"index": index, "filename": f.filename, "success": True,
                    "count": len(items), "items": items}
        except Exception as e:
            return {"index": index, "filename": f.filename, "success": False,
                    "error": type(e).__name__, "message": str(e)}

    results = await asyncio.gather(*[process_one(f, i) for i, f in enumerate(files)])
    return {"success": True, "results": sorted(results, key=lambda x: x["index"])}