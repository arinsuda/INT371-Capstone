package main

import (
	"log"
	"fixed/configs"
	"fixed/pkg/database"
)

func main() {
	// Load configuration
	config := configs.LoadConfig()

	// Connect to database
	db, err := database.Connect(config)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Run migrations
	if err := database.RunMigrations(db); err != nil {
		log.Fatal("Failed to run migrations:", err)
	}

}
