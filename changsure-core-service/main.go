package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"changsure-core-service/configs"
	"changsure-core-service/pkg/database"
	"changsure-core-service/pkg/registry"
	"changsure-core-service/src/routes"

	"github.com/gofiber/fiber/v3"
)

func main() {
	// Load configuration
	cfg := configs.LoadConfig()

	// Validate database config
	if err := cfg.ValidateDatabaseConfig(); err != nil {
		log.Fatalf("❌ Invalid database config: %v", err)
	}

	// Connect to database
	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatalf("❌ Failed to connect to database: %v", err)
	}

	// Run migrations
	log.Println("🔄 Running database migrations...")
	if err := database.AutoMigrate(db, registry.AllModels()...); err != nil {
		log.Fatalf("❌ Failed to run migrations: %v", err)
	}

	// Apply database extras (functions, views, procedures)
	if err := database.ApplyExtras(db); err != nil {
		log.Fatalf("❌ Failed to apply database extras: %v", err)
	}

	// Optional: Verify extras were applied
	if err := database.VerifyExtras(db); err != nil {
		log.Printf("⚠️  Warning: Database extras verification failed: %v", err)
	}

	// Create Fiber app
	app := fiber.New(fiber.Config{
		AppName:      "Chang Sure API",
		ServerHeader: "Chang Sure",
		ErrorHandler: customErrorHandler,
	})

	// Setup routes with dependency injection
	routes.Setup(app, cfg, db)

	// Start server in goroutine
	go func() {
		addr := ":" + cfg.App.Port
		log.Printf("✅ Server starting: env=%s port=%s db=%s",
			cfg.App.Environment, cfg.App.Port, cfg.Database.DatabaseName)

		printBanner()

		if err := app.Listen(addr); err != nil {
			log.Printf("❌ Server stopped: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	log.Println("🛑 Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := app.ShutdownWithContext(ctx); err != nil {
		log.Printf("❌ Graceful shutdown error: %v", err)
	}

	// Close database connection
	if err := database.Close(); err != nil {
		log.Printf("⚠️  Error closing database: %v", err)
	}

	log.Println("👋 Server stopped gracefully")
}

// customErrorHandler handles all errors in a consistent format
func customErrorHandler(c fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError
	message := "Internal Server Error"

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
		message = e.Message
	}

	return c.Status(code).JSON(fiber.Map{
		"status":  "error",
		"message": message,
	})
}

// printBanner prints the startup banner
func printBanner() {
	fmt.Println(`
   ________                       _____                 
  / ____/ /_  ____ _____  ____ _ / ___/__  __________ 
 / /   / __ \/ __ '/ __ \/ __ '/ \__ \/ / / / ___/ _ \
/ /___/ / / / /_/ / / / / /_/ / ___/ / /_/ / /  /  __/
\____/_/ /_/\__,_/_/ /_/\__, / /____/\__,_/_/   \___/ 
                       /____/                           
	`)
	fmt.Println("🚀 Chang Sure API Server")
	fmt.Println("📍 API Documentation: http://localhost:8080/api/v1")
	fmt.Println("💚 Health Check: http://localhost:8080/health")
	fmt.Println()
}
