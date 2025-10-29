package database

import (
	"fmt"
	"log"

	"changsure-core-service/internal/registry"
)

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

func (d *Database) Rollback() error {
	log.Println("🔄 Rolling back migrations...")

	models := registry.AllModels()
	if err := d.Migrator().DropTable(models...); err != nil {
		return fmt.Errorf("rollback failed: %w", err)
	}

	log.Println("✅ Rollback completed")
	return nil
}

func (d *Database) MigrateWithExtras(extraModels ...interface{}) error {

	if err := d.Migrate(extraModels...); err != nil {
		return fmt.Errorf("migration failed: %w", err)
	}

	if err := d.ApplyExtras(); err != nil {
		return fmt.Errorf("extras failed: %w", err)
	}

	if err := d.VerifyExtras(); err != nil {
		return fmt.Errorf("verification failed: %w", err)
	}

	return nil
}
