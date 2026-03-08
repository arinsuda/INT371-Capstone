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

# Create user with home directory
RUN groupadd -r appuser && useradd -r -g appuser -m -d /home/appuser appuser

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    libmagic1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

# Copy models — owned by appuser from the start, no chown needed after
COPY --chown=appuser:appuser --from=builder /app/.easyocr /app/.easyocr

# Copy application source
COPY --chown=appuser:appuser app/ ./app/

# Pre-create EasyOCR user_network dir with correct ownership
RUN mkdir -p /home/appuser/.EasyOCR/user_network \
 && chown -R appuser:appuser /home/appuser/.EasyOCR

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/readyz || exit 1

CMD ["uvicorn", "app.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--workers", "1", \
     "--loop", "uvloop", \
     "--http", "httptools", \
     "--no-access-log"]