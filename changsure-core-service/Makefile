.PHONY: help migrate migrate-rollback migrate-no-extras seed fresh dev build run test test-coverage lint format clean docker-build docker-run docker-stop docker-compose-up docker-compose-down docker-compose-logs install-deps health curl-health curl-idcard curl-text

# ===== Variables =====
APP_NAME := chang-sure-api
PORT     := 8080             # ให้ตรงกับ cfg.App.Port ของคุณ
DOCKER_IMAGE := $(APP_NAME):latest

help: ## Show this help
	@echo "Usage: make [target]"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ===== DB (Linux/WSL) =====
migrate: ## Run DB migrations
	@echo "🚀 Running migrations..."
	go run cmd/migrate/main.go

migrate-rollback: ## Rollback migrations
	@echo "🔄 Rolling back migrations..."
	go run cmd/migrate/main.go -rollback

migrate-no-extras: ## Migrate without extras
	@echo "🚀 Running migrations (without extras)..."
	go run cmd/migrate/main.go -extras=false

seed: ## Seed database
	@echo "🌱 Seeding database..."
	go run cmd/seed/main.go

fresh: ## Rollback -> Migrate -> Seed
	$(MAKE) migrate-rollback
	$(MAKE) migrate
	$(MAKE) seed

# ===== App =====
dev: ## Run with air (hot reload)
	@echo "Starting development server..."
	air

build: ## Build API binary
	@echo "Building $(APP_NAME)..."
	go build -o bin/$(APP_NAME) cmd/api/main.go
	@echo "✅ Build complete: bin/$(APP_NAME)"

run: ## Run main.go (root) if you have it; otherwise use cmd/api
	@echo "Starting $(APP_NAME)..."
	go run cmd/api/main.go

test: ## Run tests
	go test -v ./...

test-coverage: ## Run tests with coverage
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

lint: ## Lint
	golangci-lint run

format: ## go fmt + goimports
	go fmt ./...
	goimports -w .

clean: ## Clean artifacts
	rm -rf bin/ coverage.out

# ===== Health & curls =====
health: ## GET /health
	curl -s http://localhost:$(PORT)/health

curl-health: ## Alias
	$(MAKE) health

curl-idcard: ## Test ID card OCR (adjust path & route)
	curl -X POST http://localhost:$(PORT)/api/v1/ocr-id \
		-F "file=@test-idcard.jpg" \
		-H "Accept: application/json"

curl-text: ## Example for generic text OCR (if you add it)
	curl -X POST http://localhost:$(PORT)/api/ocr/text \
		-F "image=@test-text.jpg"

# ===== Docker =====
docker-build: ## Build Docker image
	docker build -t $(DOCKER_IMAGE) .

docker-run: ## Run Docker container
	docker run -d --name $(APP_NAME) -p $(PORT):$(PORT) $(DOCKER_IMAGE)

docker-stop: ## Stop & remove container
	- docker stop $(APP_NAME)
	- docker rm $(APP_NAME)

docker-compose-up: ## Compose up
	docker-compose up -d

docker-compose-down: ## Compose down
	docker-compose down

docker-compose-logs: ## Compose logs
	docker-compose logs -f

# ===== Install deps (cross-platform hint) =====
install-deps: ## Install deps (Linux/WSL). On Windows: install Tesseract manually + go mod tidy
	@echo "Installing Tesseract OCR (Linux/WSL only)..."
	- sudo apt-get update && sudo apt-get install -y tesseract-ocr tesseract-ocr-tha tesseract-ocr-eng
	@echo "Installing Go deps..."
	go mod tidy
	@echo "✅ Done"
