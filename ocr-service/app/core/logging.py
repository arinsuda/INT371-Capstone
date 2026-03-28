import logging
import sys

from app.core.config import settings

class JSONFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        import json
        import traceback

        log: dict = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S"),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        if hasattr(record, "request_id"):
            log["request_id"] = record.request_id
        if hasattr(record, "elapsed_ms"):
            log["elapsed_ms"] = record.elapsed_ms
        if hasattr(record, "status_code"):
            log["status_code"] = record.status_code

        if record.exc_info:
            log["exception"] = traceback.format_exception(*record.exc_info)

        return json.dumps(log, ensure_ascii=False)


def setup_logging() -> None:
    level = logging.DEBUG if settings.APP_ENV == "development" else logging.INFO

    handler = logging.StreamHandler(sys.stdout)

    if settings.APP_ENV == "production":
        handler.setFormatter(JSONFormatter())
    else:
        handler.setFormatter(
            logging.Formatter("%(asctime)s [%(levelname)s] %(name)s — %(message)s")
        )

    root = logging.getLogger()
    root.setLevel(level)
    root.handlers = [handler]

    for noisy in ("easyocr", "PIL", "urllib3", "httpx"):
        logging.getLogger(noisy).setLevel(logging.WARNING)
