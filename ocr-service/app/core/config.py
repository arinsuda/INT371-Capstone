from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_ENV: str = "development"
    DEBUG: bool = False

    OCR_LANGUAGES: list[str] = ["th", "en"]
    OCR_USE_GPU: bool = True
    OCR_TIMEOUT_SECONDS: int = 120
    OCR_MODEL_DIR: str = "/app/.easyocr/model"

    MAX_IMAGE_WIDTH: int = 1024
    MAX_FILE_SIZE_BYTES: int = 5 * 1024 * 1024

    BATCH_MAX_FILES: int = 10
    BATCH_MAX_CONCURRENCY: int = 1

    MIN_CONFIDENCE_THRESHOLD: float = 0.3

    ALLOWED_CONTENT_TYPES: list[str] = [
        "image/jpeg",
        "image/png",
        "image/webp",
    ]

    RATE_LIMIT_REQUESTS: int = 10
    RATE_LIMIT_WINDOW_SECONDS: int = 60

    TRUSTED_PROXY_IPS: list[str] = ["127.0.0.1"]

    
    
    SKIP_ORIENTATION_CHECK: bool = False


settings = Settings()
