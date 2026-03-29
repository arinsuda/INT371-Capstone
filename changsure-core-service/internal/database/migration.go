package database

import (
	"fmt"
	"log"

	"changsure-core-service/internal/modules/technician"
	"changsure-core-service/internal/registry"
)

func (d *Database) MigrateWithExtras(extraModels ...interface{}) error {
	log.Println("🔄 Running database migrations...")

	models := registry.AllModels()
	models = append(models, extraModels...)

	if err := d.DB.AutoMigrate(models...); err != nil {
		return fmt.Errorf("migration failed: %w", err)
	}

	if err := d.dropDerivedTechnicianColumns(); err != nil {
		return fmt.Errorf("drop derived columns failed: %w", err)
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

func (d *Database) dropDerivedTechnicianColumns() error {
	migrator := d.DB.Migrator()

	type colCheck struct {
		table string
		col   string
	}

	cols := []colCheck{
		{"technicians", "rating_avg"},
		{"technicians", "rating_count"},
		{"technicians", "total_jobs"},
	}

	for _, c := range cols {
		if migrator.HasColumn(&technician.Technician{}, c.col) {
			log.Printf("   dropping column: %s.%s", c.table, c.col)
			if err := migrator.DropColumn(&technician.Technician{}, c.col); err != nil {
				return fmt.Errorf("drop %s.%s: %w", c.table, c.col, err)
			}
		}
	}
	return nil
}
