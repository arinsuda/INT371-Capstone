package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"
	"strings"

	"changsure-core-service/internal/config"
	"changsure-core-service/internal/database"
	"changsure-core-service/internal/routes"

	"github.com/gofiber/fiber/v3"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("⚠️  No .env file found, using environment variables")
	}

	cfg := config.LoadConfig()

	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatalf("❌ Failed to connect to database: %v", err)
	}
	defer db.Close()

	if shouldRunMigrations(cfg) {
		log.Println("🔄 Running database migrations...")
		if err := db.MigrateWithExtras(); err != nil {
			log.Fatalf("❌ Migration failed: %v", err)
		}
	} else {
		log.Println("⊘ Skipping migrations (production mode)")
	}

	if shouldRunSeed(cfg) {
		log.Println("🌱 Running database seeders...")
		if err := db.Seed(); err != nil {
			log.Fatalf("❌ Seeding failed: %v", err)
		}
	} else {
		log.Println("⊘ Skipping seeders")
	}

	app := fiber.New(fiber.Config{
		AppName:      "Chang Sure API",
		ServerHeader: "Chang Sure",
		ErrorHandler: customErrorHandler,
		BodyLimit:    10 * 1024 * 1024,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
	})

	routes.Setup(app, cfg, db.Gorm())

	printStartupInfo(cfg)

	serverErrors := make(chan error, 1)
	go func() {
		addr := ":" + cfg.App.Port
		serverErrors <- app.Listen(addr)
	}()

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-serverErrors:
		log.Fatalf("❌ Server error: %v", err)

	case sig := <-shutdown:
		log.Printf("🛑 Shutting down server... (signal: %v)", sig)

		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := app.ShutdownWithContext(ctx); err != nil {
			log.Fatalf("❌ Graceful shutdown failed: %v", err)
		}

		log.Println("👋 Server stopped gracefully")
	}
}

func shouldRunMigrations(cfg *config.Config) bool {
	switch cfg.App.Environment {
	case "development", "staging":
		return true
	case "production":
		return false
	default:
		return true
	}
}

func shouldRunSeed(cfg *config.Config) bool {
	// เปิดได้ด้วย ENV ตัวใดตัวหนึ่ง
	// SEED_ON_BOOT=true   หรือ   APP_SEED=true
	envSeed := strings.ToLower(os.Getenv("SEED_ON_BOOT"))
	if envSeed == "1" || envSeed == "true" || strings.ToLower(os.Getenv("APP_SEED")) == "true" {
		return true
	}

	switch cfg.App.Environment {
	case "development":
		return false
	default:
		return false
	}
}

func customErrorHandler(c fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError
	message := "Internal Server Error"

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
		message = e.Message
	}

	if os.Getenv("APP_ENV") == "production" {
		log.Printf("ERROR: [%d] %s - Path: %s", code, message, c.Path())
	}

	return c.Status(code).JSON(fiber.Map{
		"success": false,
		"error": fiber.Map{
			"code":    getErrorCode(code),
			"message": message,
		},
	})
}
func getErrorCode(statusCode int) string {
	switch statusCode {
	case fiber.StatusBadRequest:
		return "BAD_REQUEST"
	case fiber.StatusUnauthorized:
		return "UNAUTHORIZED"
	case fiber.StatusForbidden:
		return "FORBIDDEN"
	case fiber.StatusNotFound:
		return "NOT_FOUND"
	case fiber.StatusRequestEntityTooLarge:
		return "FILE_TOO_LARGE"
	case fiber.StatusUnsupportedMediaType:
		return "UNSUPPORTED_MEDIA_TYPE"
	case fiber.StatusUnprocessableEntity:
		return "UNPROCESSABLE_ENTITY"
	case fiber.StatusInternalServerError:
		return "INTERNAL_ERROR"
	default:
		return "UNKNOWN_ERROR"
	}
}

func printStartupInfo(cfg *config.Config) {
	printBanner()

	log.Printf("✅ Server started successfully")
	log.Printf("📦 Environment: %s", cfg.App.Environment)
	log.Printf("🔌 Port: %s", cfg.App.Port)
	log.Printf("💾 Database: %s@%s:%s/%s",
		cfg.Database.Username,
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.DatabaseName,
	)
	log.Printf("📍 API Base: http://localhost:%s/api/v1", cfg.App.Port)
	log.Printf("💚 Health Check: http://localhost:%s/health", cfg.App.Port)
	log.Printf("🔍 OCR Endpoint: http://localhost:%s/api/v1/ocr/id-card", cfg.App.Port)
	fmt.Println()
}

func printBanner() {
	fmt.Println(`
   ________                       _____                 
  / ____/ /_  ____ _____  ____ _ / ___/__  __________ 
 / /   / __ \/ __ '/ __ \/ __ '/ \__ \/ / / / ___/ _ \
/ /___/ / / / /_/ / / / / /_/ / ___/ / /_/ / /  /  __/
\____/_/ /_/\__,_/_/ /_/\__, / /____/\__,_/_/   \___/ 
                       /____/                           
	`)
}
