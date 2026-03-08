# ─────────────────────────────────────────────────────────
# Stage 1: Build / download models
# ─────────────────────────────────────────────────────────
FROM python:3.10-slim AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Pre-download EasyOCR models into the image layer
# so containers start instantly without network access
RUN mkdir -p /app/.easyocr/model
RUN PYTHONPATH=/install/lib/python3.10/site-packages \
    python - <<'EOF'
import easyocr
easyocr.Reader(
    ['th', 'en'],
    gpu=False,
    model_storage_directory='/app/.easyocr/model',
    download_enabled=True,
    verbose=False,
)
print('Models downloaded successfully')
EOF


# ─────────────────────────────────────────────────────────
# Stage 2: Runtime image (lean)
# ─────────────────────────────────────────────────────────
FROM python:3.10-slim AS runtime

# Security: run as non-root
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# System libs only — no build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    libmagic1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

# Copy pre-downloaded OCR models
COPY --from=builder /app/.easyocr /app/.easyocr

# Copy application source
COPY app/ ./app/

# Ensure correct ownership
RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

# Healthcheck — /readyz returns 200 once models are loaded
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/readyz || exit 1

CMD ["uvicorn", "app.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--workers", "1", \
     "--loop", "uvloop", \
     "--http", "httptools", \
     "--no-access-log"]