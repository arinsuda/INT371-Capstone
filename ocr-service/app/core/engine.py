import asyncio
import time
import logging
from concurrent.futures import ThreadPoolExecutor
from app.core.exceptions import OCRTimeoutError
from typing import Any
import numpy as np
import easyocr

from app.core.config import settings

logger = logging.getLogger(__name__)


def _build_reader() -> easyocr.Reader:
    """Instantiate the EasyOCR reader (runs in executor thread)."""
    return easyocr.Reader(
        settings.OCR_LANGUAGES,
        gpu=settings.OCR_USE_GPU,
        model_storage_directory=settings.OCR_MODEL_DIR,
        download_enabled=False,
        verbose=False,
    )


def _run_readtext(reader: easyocr.Reader, image: Any) -> list:
    return reader.readtext(
        image,
        detail=1,
        paragraph=False,
        contrast_ths=0.1,
        adjust_contrast=0.5,
        batch_size=1,
        workers=0,
    )


class OCREngine:
    def __init__(self) -> None:
        self._reader = None
        self._executor = ThreadPoolExecutor(max_workers=1)
        self._semaphore = asyncio.Semaphore(1)
        self._ready = False

    @property
    def is_ready(self) -> bool:
        return self._ready

    async def initialize(self) -> None:
        loop = asyncio.get_running_loop()

        self._reader = await loop.run_in_executor(self._executor, _build_reader)

        self._ready = True

    async def read(self, image):
        if not self._ready:
            raise RuntimeError("OCR not ready")

        loop = asyncio.get_running_loop()

        async with self._semaphore:
            try:
                result = await asyncio.wait_for(
                    loop.run_in_executor(
                        self._executor,
                        _run_readtext,
                        self._reader,
                        image,
                    ),
                    timeout=settings.OCR_TIMEOUT_SECONDS,
                )
            except asyncio.TimeoutError:
                raise OCRTimeoutError()

        return [
            {
                "text": text,
                "confidence": float(conf),
                "bbox": bbox,
            }
            for bbox, text, conf in result
            if conf >= settings.MIN_CONFIDENCE_THRESHOLD
        ]

    async def shutdown(self):
        self._executor.shutdown(wait=True)


ocr_engine = OCREngine()
