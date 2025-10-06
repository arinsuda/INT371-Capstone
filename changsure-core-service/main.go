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
	"changsure-core-service/src/routes"

	"github.com/gofiber/fiber/v3"
)

func main() {

	cfg := configs.LoadConfig()

	if err := cfg.ValidateDatabaseConfig(); err != nil {
		log.Fatalf("invalid database config: %v", err)
	}

	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}

	if err := database.RunMigrations(db); err != nil {
		log.Fatalf("failed to run migrations: %v", err)
	}

	app := fiber.New(fiber.Config{
		AppName: "Chang Sure",
	})

	routes.Setup(app, cfg, db)

	go func() {
		addr := ":" + cfg.App.Port
		log.Printf("✅ boot ok: env=%s port=%s db=%s", cfg.App.Environment, cfg.App.Port, cfg.Database.DatabaseName)

		fmt.Println(`
   ________                       _____                 
  / ____/ /_  ____ _____  ____ _ / ___/__  __________ 
 / /   / __ \/ __ '/ __ \/ __ '/ \__ \/ / / / ___/ _ \
/ /___/ / / / /_/ / / / / /_/ / ___/ / /_/ / /  /  __/
\____/_/ /_/\__,_/_/ /_/\__, / /____/\__,_/_/   \___/ 
                       /____/                           
		`)
		if err := app.Listen(addr); err != nil {
			log.Printf("server stopped: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	log.Println("🛑 shutting down...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := app.ShutdownWithContext(ctx); err != nil {
		log.Printf("graceful shutdown error: %v", err)
	}
	log.Println("👋 bye")
}
