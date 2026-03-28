import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.engine import ocr_engine
from app.core.exceptions import (
    OCREngineNotReadyError,
    OCRTimeoutError,
    RateLimitExceeded,
)
from app.core.logging import setup_logging
from app.api.routes import router

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
    await ocr_engine.initialize()
    yield
    await ocr_engine.shutdown()


app = FastAPI(title="Thai ID OCR Service", lifespan=lifespan)
app.include_router(router)


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    return JSONResponse(
        status_code=429,
        headers={"Retry-After": str(int(exc.retry_after) + 1)},
        content={
            "success": False,
            "error": "RateLimitExceeded",
            "message": f"Limit: {exc.limit} requests per {exc.window}s. "
            f"Retry after {exc.retry_after:.1f}s",
        },
    )


@app.exception_handler(OCREngineNotReadyError)
async def ocr_not_ready_handler(request: Request, exc: OCREngineNotReadyError):
    return JSONResponse(
        status_code=503,
        content={
            "success": False,
            "error": "EngineNotReady",
            "message": str(exc),
        },
    )


@app.exception_handler(OCRTimeoutError)
async def ocr_timeout_handler(request: Request, exc: OCRTimeoutError):
    return JSONResponse(
        status_code=504,
        content={
            "success": False,
            "error": "OCRTimeout",
            "message": str(exc),
        },
    )


@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError):
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "error": "InvalidImage",
            "message": str(exc),
        },
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": "InternalError",
            "message": "An unexpected error occurred",
        },
    )
