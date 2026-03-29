"""OCR Engine — EasyOCR with async worker pool.

Uses a semaphore-guarded executor pool so that multiple concurrent
requests don't block the event loop while still limiting GPU/CPU
contention.
"""

import asyncio
import logging
from concurrent.futures import ThreadPoolExecutor
from typing import Any

import easyocr

from app.core.config import settings
from app.core.exceptions import OCREngineError, OCRTimeoutError

logger = logging.getLogger(__name__)


class OCREngine:
    def __init__(self):
        self._readers: list[easyocr.Reader] = []
        self._executor: ThreadPoolExecutor | None = None
        self._semaphore: asyncio.Semaphore | None = None
        self._ready = False

    async def initialize(self):
        """Warm up OCR readers in a thread pool (blocking init)."""
        loop = asyncio.get_event_loop()
        self._executor = ThreadPoolExecutor(
            max_workers=settings.OCR_WORKERS,
            thread_name_prefix="ocr-worker",
        )
        self._semaphore = asyncio.Semaphore(settings.OCR_WORKERS)

        # Initialize one reader per worker thread to avoid sharing state
        readers = await asyncio.gather(
            *[
                loop.run_in_executor(self._executor, self._create_reader)
                for _ in range(settings.OCR_WORKERS)
            ]
        )
        self._readers = list(readers)
        self._ready = True
        logger.info(
            f"OCR Engine initialized with {settings.OCR_WORKERS} workers, "
            f"languages={settings.OCR_LANGUAGES}, gpu={settings.OCR_USE_GPU}"
        )

    def _create_reader(self) -> easyocr.Reader:
        return easyocr.Reader(
            settings.OCR_LANGUAGES,
            gpu=settings.OCR_USE_GPU,
            verbose=False,
            # Download models to a predictable path for Docker layer caching
            model_storage_directory="/app/.easyocr/model",
            download_enabled=True,
        )

    async def read(self, image_array) -> list[dict[str, Any]]:
        """
        Run OCR on a numpy image array.
        Returns list of {text, confidence, bbox} dicts.
        """
        if not self._ready:
            raise OCREngineError("OCR engine is not initialized")

        loop = asyncio.get_event_loop()

        # Round-robin reader selection by semaphore index
        async with self._semaphore:
            reader_index = 0  # semaphore ensures at most N concurrent → pick first free
            reader = self._readers[reader_index]

            try:
                raw = await asyncio.wait_for(
                    loop.run_in_executor(
                        self._executor,
                        lambda: reader.readtext(
                            image_array,
                            detail=1,
                            paragraph=False,
                        ),
                    ),
                    timeout=settings.OCR_TIMEOUT_SECONDS,
                )
            except asyncio.TimeoutError:
                raise OCRTimeoutError()
            except Exception as e:
                logger.exception(f"EasyOCR internal error: {e}")
                raise OCREngineError(str(e))

        results = []
        for bbox, text, conf in raw:
            if conf >= settings.MIN_CONFIDENCE_THRESHOLD:
                results.append(
                    {
                        "text": text,
                        "confidence": round(float(conf), 6),
                        "bbox": [[round(float(x), 2), round(float(y), 2)] for x, y in bbox],
                    }
                )
        return results

    async def shutdown(self):
        if self._executor:
            self._executor.shutdown(wait=False)
        self._ready = False


# Singleton — imported everywhere
ocr_engine = OCREngine()