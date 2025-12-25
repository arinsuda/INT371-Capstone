package database

import (
	"fmt"
	"log"

	"changsure-core-service/internal/registry"
)

func (d *Database) MigrateWithExtras(extraModels ...interface{}) error {
	log.Println("🔄 Running database migrations...")

	// โหลด models ทั้งหมดจาก registry
	models := registry.AllModels()
	models = append(models, extraModels...)

	// ใช้ AutoMigrate ทีเดียว
	if err := d.DB.AutoMigrate(models...); err != nil {
		return fmt.Errorf("migration failed: %w", err)
	}

	log.Println("✅ Migrations completed successfully")
	return nil
}

func (d *Database) Rollback() error {
	log.Println("🔄 Rolling back migrations...")

	models := registry.AllModels()
	if err := d.DB.Migrator().DropTable(models...); err != nil {
		return fmt.Errorf("rollback failed: %w", err)
	}

	log.Println("✅ Rollback complete")
	return nil
}
