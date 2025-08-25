package main

import (
	"log"

	"changsure-core-service/configs"
	"changsure-core-service/pkg/database"
)

func main() {
	// 1) Load configuration
	cfg := configs.LoadConfig()

	// 2) Validate DB config (กันเคส .env ไม่ครบ)
	if err := cfg.ValidateDatabaseConfig(); err != nil {
		log.Fatalf("invalid database config: %v", err)
	}

	// 3) Connect to database
	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}

	// 4) Run migrations
	if err := database.RunMigrations(db); err != nil {
		log.Fatalf("failed to run migrations: %v", err)
	}

	log.Printf("✅ boot ok: env=%s port=%s db=%s", cfg.App.Environment, cfg.App.Port, cfg.Database.DatabaseName)

	// หมายเหตุ: เดี๋ยวตอนคุณส่งไฟล์ Fiber routes มา เราค่อย start server ที่นี่ต่อ
}
