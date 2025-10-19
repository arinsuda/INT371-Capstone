package database

import (
	"fmt"
	"log"

	"changsure-core-service/internal/registry"
)

// Migrate runs GORM auto-migration for all registered models
func (d *Database) Migrate(extraModels ...interface{}) error {
	log.Println("🔄 Running database migrations...")

	models := registry.AllModels()
	models = append(models, extraModels...)

	for _, model := range models {
		if err := d.DB.AutoMigrate(model); err != nil {
			return fmt.Errorf("failed to migrate %T: %w", model, err)
		}
		log.Printf("   ✓ Migrated: %T", model)
	}

	log.Println("✅ Migrations completed successfully")
	return nil
}

// Rollback drops all tables (use with extreme caution!)
func (d *Database) Rollback() error {
	log.Println("🔄 Rolling back migrations...")

	models := registry.AllModels()
	if err := d.Migrator().DropTable(models...); err != nil {
		return fmt.Errorf("rollback failed: %w", err)
	}

	log.Println("✅ Rollback completed")
	return nil
}

// MigrateWithExtras runs migrations AND applies SQL extras
func (d *Database) MigrateWithExtras(extraModels ...interface{}) error {
	// 1. Run GORM migrations
	if err := d.Migrate(extraModels...); err != nil {
		return fmt.Errorf("migration failed: %w", err)
	}

	// 2. Apply SQL extras (functions, views, procedures)
	if err := d.ApplyExtras(); err != nil {
		return fmt.Errorf("extras failed: %w", err)
	}

	// 3. Verify everything
	if err := d.VerifyExtras(); err != nil {
		return fmt.Errorf("verification failed: %w", err)
	}

	return nil
}
