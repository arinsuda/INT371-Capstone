from functools import lru_cache
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # ── App ──────────────────────────────────────────────
    APP_ENV: str = "production"
    ENABLE_DOCS: bool = False
    CORS_ORIGINS: List[str] = ["*"]

    # ── OCR Engine ───────────────────────────────────────
    OCR_LANGUAGES: List[str] = ["th", "en"]
    OCR_USE_GPU: bool = False
    OCR_WORKERS: int = 2                   # parallel OCR workers
    OCR_TIMEOUT_SECONDS: int = 60

    # ── Image Validation ─────────────────────────────────
    MAX_FILE_SIZE_MB: float = 10.0
    ALLOWED_CONTENT_TYPES: List[str] = [
        "image/jpeg",
        "image/png",
        "image/webp",
        "image/bmp",
        "image/tiff",
    ]
    MIN_IMAGE_WIDTH: int = 300
    MIN_IMAGE_HEIGHT: int = 200
    MAX_IMAGE_WIDTH: int = 8000
    MAX_IMAGE_HEIGHT: int = 8000

    # ── Preprocessing ────────────────────────────────────
    ENABLE_PREPROCESSING: bool = True
    ENABLE_DESKEW: bool = True
    ENABLE_DENOISE: bool = True
    TARGET_DPI: int = 300

    # ── Confidence ───────────────────────────────────────
    MIN_CONFIDENCE_THRESHOLD: float = 0.5

    # ── Rate Limiting ────────────────────────────────────
    RATE_LIMIT_ENABLED: bool = False
    RATE_LIMIT_PER_MINUTE: int = 60

    @property
    def MAX_FILE_SIZE_BYTES(self) -> int:
        return int(self.MAX_FILE_SIZE_MB * 1024 * 1024)


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()