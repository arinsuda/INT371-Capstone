import asyncio
import logging
from concurrent.futures import ThreadPoolExecutor
import easyocr
import gc

from app.core.config import settings

logger = logging.getLogger(__name__)


class OCREngine:
    def __init__(self):
        self._reader = None
        self._executor = None
        self._semaphore = asyncio.Semaphore(settings.OCR_MAX_CONCURRENCY)
        self._ready = False

    async def initialize(self):
        loop = asyncio.get_event_loop()

        self._executor = ThreadPoolExecutor(
            max_workers=1,
            thread_name_prefix="ocr-worker"
        )

        logger.info("Loading EasyOCR model...")

        self._reader = await loop.run_in_executor(
            self._executor,
            lambda: easyocr.Reader(
                settings.OCR_LANGUAGES,
                gpu=settings.OCR_USE_GPU,
                verbose=False
            )
        )

        self._ready = True
        logger.info("OCR Engine Ready")

    async def read(self, image):
        if not self._ready:
            raise RuntimeError("OCR not ready")

        loop = asyncio.get_event_loop()

        async with self._semaphore:
            try:
                result = await asyncio.wait_for(
                    loop.run_in_executor(
                        self._executor,
                        lambda: self._reader.readtext(
                            image,
                            detail=1,
                            paragraph=False
                        )
                    ),
                    timeout=settings.OCR_TIMEOUT_SECONDS
                )

            except asyncio.TimeoutError:
                raise RuntimeError("OCR timeout")

            except Exception as e:
                logger.exception(e)
                raise RuntimeError("OCR failed")

            finally:
                gc.collect()  # 🔥 reduce memory fragmentation

        return [
            {
                "text": text,
                "confidence": float(conf),
                "bbox": bbox
            }
            for bbox, text, conf in result
            if conf > 0.5
        ]


ocr_engine = OCREngine()