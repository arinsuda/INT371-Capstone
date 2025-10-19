package main

import (
	"flag"
	"log"

	"changsure-core-service/internal/config"
	"changsure-core-service/internal/database"
)

func main() {
	var (
		rollback   = flag.Bool("rollback", false, "Rollback all migrations")
		withExtras = flag.Bool("extras", true, "Apply SQL extras (functions, views, procedures)")
		verify     = flag.Bool("verify", true, "Verify extras after applying")
	)
	flag.Parse()

	cfg := config.LoadConfig()

	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatal("❌ Connection failed:", err)
	}
	defer db.Close()

	if *rollback {
		log.Println("🔄 Rolling back all migrations...")
		if err := db.Rollback(); err != nil {
			log.Fatal("❌ Rollback failed:", err)
		}
		log.Println("✅ Rollback completed successfully")
		return
	}

	log.Println("🚀 Starting migrations...")
	if *withExtras {
		if err := db.MigrateWithExtras(); err != nil {
			log.Fatal("❌ Migration failed: ", err)
		}
		if *verify {
			if err := db.VerifyExtras(); err != nil {
				log.Fatal("❌ Verify extras failed: ", err)
			}
		}
	}

	log.Println("✅ All migrations completed successfully!")
}
