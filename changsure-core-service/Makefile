.PHONY: migrate migrate-rollback seed dev build

# Database migrations
migrate:
	@echo "🚀 Running migrations..."
	@go run cmd/migrate/main.go

migrate-rollback:
	@echo "🔄 Rolling back migrations..."
	@go run cmd/migrate/main.go -rollback

migrate-no-extras:
	@echo "🚀 Running migrations (without extras)..."
	@go run cmd/migrate/main.go -extras=false

# Database seeding
seed:
	@echo "🌱 Seeding database..."
	@go run cmd/seed/main.go

# Fresh install (rollback + migrate + seed)
fresh:
	@make migrate-rollback
	@make migrate
	@make seed

# Development
dev:
	@air

# Build
build:
	@go build -o bin/api cmd/api/main.go

# Health check
health:
	@curl -s http://localhost:8080/health | jq