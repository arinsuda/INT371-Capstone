package main

import (
	"log"

	"changsure-core-service/internal/config"
	"changsure-core-service/internal/database"
	"github.com/joho/godotenv"
)

func main() {

	_ = godotenv.Load()

	cfg := config.LoadConfig()

	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatal("❌ Connection failed:", err)
	}
	defer db.Close()

	log.Println("🌱 Starting seeding...")

	if err := db.Seed(); err != nil {
		log.Fatal("❌ Seeding failed:", err)
	}

	log.Println("✅ Seeding completed successfully!")
}
