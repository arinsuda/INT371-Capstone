from functools import lru_cache
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    OCR_LANGUAGES: list[str] = ["th", "en"]
    OCR_USE_GPU: bool = False

    # 🔥 IMPORTANT
    OCR_MAX_CONCURRENCY: int = 1
    OCR_TIMEOUT_SECONDS: int = 15

    # Image
    MAX_IMAGE_WIDTH: int = 1024
    MAX_FILE_SIZE_MB: int = 5

settings = Settings()