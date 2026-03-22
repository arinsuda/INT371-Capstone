package database

import (
	"database/sql"
	_ "embed"
	"fmt"
	"log"
	"strings"

	"changsure-core-service/internal/config"
	_ "github.com/go-sql-driver/mysql"
)

//go:embed sql/views.sql
var viewsSQL string

//go:embed sql/procedure_auto_match.sql
var procAutoMatchSQL string

//go:embed sql/procedure_reservation.sql
var procReservationSQL string

func (d *Database) ApplyExtras() error {
	log.Println("🔧 Applying SQL extras...")

	sqlDB, err := d.DB.DB()
	if err != nil {
		return err
	}

	// Views — split ด้วย ; ได้เพราะไม่มี ; ข้างใน
	for _, stmt := range splitBySemicolon(viewsSQL) {
		if _, err := sqlDB.Exec(stmt); err != nil {
			log.Printf("⚠️ Warning executing view: %v", err)
		}
	}

	// Procedures — ต้องใช้ multiStatements=true เพราะมี ; ข้างใน BEGIN...END
	multiDB, err := sql.Open("mysql", config.GlobalConfig.GetMigrationDSN())
	if err != nil {
		return fmt.Errorf("open multi-statement connection: %w", err)
	}
	defer multiDB.Close()

	for _, p := range []struct{ name, sql string }{
		{"AutoMatch", procAutoMatchSQL},
		{"Reservation", procReservationSQL},
	} {
		if strings.TrimSpace(p.sql) == "" {
			continue
		}
		if _, err := multiDB.Exec(p.sql); err != nil {
			return fmt.Errorf("failed to execute procedure %s: %w", p.name, err)
		}
	}

	log.Println("✅ SQL extras applied successfully")
	return nil
}

func splitBySemicolon(s string) []string {
	var out []string
	for _, part := range strings.Split(s, ";") {
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	return out
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
		{objectType: "VIEW", name: "technician_stats", query: "SELECT COUNT(*) FROM information_schema.VIEWS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'technician_stats'"},
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
