package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"changsure-core-service/internal/config"
	"changsure-core-service/internal/database"
	"changsure-core-service/internal/routes"

	"github.com/gofiber/fiber/v3"
)

func main() {
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

	app := fiber.New(fiber.Config{
		AppName:      "Chang Sure API",
		ServerHeader: "Chang Sure",
		ErrorHandler: customErrorHandler,
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

func customErrorHandler(c fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError
	message := "Internal Server Error"

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
		message = e.Message
	}

	return c.Status(code).JSON(fiber.Map{
		"success": false,
		"error":   message,
		"code":    code,
	})
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
