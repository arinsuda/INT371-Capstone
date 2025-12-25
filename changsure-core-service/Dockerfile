FROM golang:1.25-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential pkg-config git ca-certificates \
    libtesseract-dev libleptonica-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN echo "---- DEBUG: SOURCE FILES ----" && find /src -maxdepth 4

ENV CGO_ENABLED=1 GOOS=linux
RUN go build -trimpath -ldflags="-s -w" -o /out/app ./cmd/api/main.go

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    tesseract-ocr tesseract-ocr-eng tesseract-ocr-tha \
    libtesseract5 liblept5 \
  && rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Bangkok
WORKDIR /app

COPY --from=builder /out/app /app/app

COPY --from=builder /src/seeds /app/seeds

COPY --from=builder /src /app/src

RUN useradd -r -u 10001 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -fsS http://localhost:8080/health || exit 1

CMD ["./app"]
