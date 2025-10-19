FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o app .

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    tesseract-ocr-tha \
    imagemagick \
    ca-certificates

WORKDIR /app
COPY --from=builder /app/app .
EXPOSE 8080
CMD ["./app"]