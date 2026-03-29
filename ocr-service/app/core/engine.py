import asyncio
import logging
from concurrent.futures import ThreadPoolExecutor
from typing import Any

import numpy as np
import easyocr

from app.core.config import settings
from app.core.exceptions import OCRTimeoutError

logger = logging.getLogger(__name__)


def _build_reader() -> easyocr.Reader:
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
        contrast_ths=0.3,    # เพิ่มจาก 0.1 → ตัด false positive เร็วขึ้น
        adjust_contrast=0.5,
        batch_size=1,
        workers=0,
        width_ths=0.7,       # merge text box ที่ชิดกัน
        decoder="greedy",    # เร็วกว่า beamsearch (default) ~10-20%
    )


class OCREngine:
    def __init__(self) -> None:
        self._reader: easyocr.Reader | None = None
        self._executor = ThreadPoolExecutor(max_workers=1)
        self._semaphore = asyncio.Semaphore(1)
        self._ready = False

    @property
    def is_ready(self) -> bool:
        return self._ready

    async def initialize(self) -> None:
        loop = asyncio.get_running_loop()
        logger.info("Loading EasyOCR model (gpu=%s)...", settings.OCR_USE_GPU)
        self._reader = await loop.run_in_executor(self._executor, _build_reader)
        self._ready = True
        logger.info("EasyOCR model ready")

    async def read(self, image: np.ndarray) -> list[dict]:
        """
        Run OCR on a single image array.
        Returns list of { text, confidence, bbox }.
        """
        if not self._ready:
            raise RuntimeError("OCR engine not ready")

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

    async def shutdown(self) -> None:
        self._executor.shutdown(wait=True)


ocr_engine = OCREngine()
