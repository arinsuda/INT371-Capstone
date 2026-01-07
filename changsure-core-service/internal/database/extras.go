package database

import (
	_ "embed"
	"fmt"
	"log"
	"strings"
)

var viewsSQL string

var procAutoMatchSQL string

var procReservationSQL string

func (d *Database) ApplyExtras() error {
	log.Println("🔧 Applying SQL extras...")

	sqlDB, err := d.DB.DB()
	if err != nil {
		return err
	}

	viewStmts := strings.Split(viewsSQL, ";")
	for _, stmt := range viewStmts {
		stmt = strings.TrimSpace(stmt)
		if stmt == "" {
			continue
		}
		if _, err := sqlDB.Exec(stmt); err != nil {
			log.Printf("⚠️ Warning executing view: %v", err)

		}
	}

	procedures := []struct {
		name string
		sql  string
	}{
		{"AutoMatch", procAutoMatchSQL},
		{"Reservation", procReservationSQL},
	}

	for _, p := range procedures {
		if strings.TrimSpace(p.sql) == "" {
			continue
		}
		if _, err := sqlDB.Exec(p.sql); err != nil {
			return fmt.Errorf("failed to execute procedure %s: %w", p.name, err)
		}
	}

	log.Println("✅ SQL extras applied successfully")
	return nil
}

func (d *Database) VerifyExtras() error {

	log.Println("🔍 Verifying SQL extras...")

	type check struct {
		objectType string
		name       string
		query      string
	}
	checks := []check{
		{objectType: "VIEW", name: "view_service_starting_prices", query: "SELECT COUNT(*) FROM information_schema.VIEWS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'view_service_starting_prices'"},
		{objectType: "VIEW", name: "view_technicians_per_service", query: "SELECT COUNT(*) FROM information_schema.VIEWS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'view_technicians_per_service'"},
		{objectType: "PROCEDURE", name: "auto_match_technician", query: "SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'auto_match_technician' AND ROUTINE_TYPE = 'PROCEDURE'"},
		{objectType: "PROCEDURE", name: "create_reservation", query: "SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'create_reservation' AND ROUTINE_TYPE = 'PROCEDURE'"},
		{objectType: "PROCEDURE", name: "set_reservation_status", query: "SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'set_reservation_status' AND ROUTINE_TYPE = 'PROCEDURE'"},
	}

	for _, c := range checks {
		var count int
		if err := d.DB.Raw(c.query).Scan(&count).Error; err != nil {
			return fmt.Errorf("verify %s %s: %w", c.objectType, c.name, err)
		}
		if count == 0 {
			return fmt.Errorf("%s %s not found", c.objectType, c.name)
		}
		log.Printf("   ✓ %s: %s", c.objectType, c.name)
	}

	log.Println("✅ All SQL extras verified successfully")
	return nil
}
