package database

import (
	"fmt"
	"log"
)

type sqlStatement struct {
	name string
	sql  string
}

func (d *Database) ApplyExtras() error {
	log.Println("🔧 Applying SQL extras...")

	sqlDB, err := d.DB.DB()
	if err != nil {
		return fmt.Errorf("failed to get sql.DB: %w", err)
	}

	stmts := []sqlStatement{

		{name: "Drop view_service_starting_prices", sql: `DROP VIEW IF EXISTS view_service_starting_prices`},
		{name: "Drop view_technicians_per_service", sql: `DROP VIEW IF EXISTS view_technicians_per_service`},
		{name: "Drop auto_match_technician", sql: `DROP PROCEDURE IF EXISTS auto_match_technician`},
		{name: "Drop create_reservation", sql: `DROP PROCEDURE IF EXISTS create_reservation`},
		{name: "Drop set_reservation_status", sql: `DROP PROCEDURE IF EXISTS set_reservation_status`},

		{
			name: "Create view_service_starting_prices",
			sql: `CREATE VIEW view_service_starting_prices AS
				SELECT s.id AS service_id, s.name AS service_name,
					   MIN(ts.price_min) AS starting_price
				FROM services s
				JOIN technician_services ts ON ts.service_id = s.id AND ts.is_active = 1
				WHERE s.is_active = 1
				GROUP BY s.id, s.name`,
		},
		{
			name: "Create view_technicians_per_service",
			sql: `CREATE VIEW view_technicians_per_service AS
				SELECT
					ts.service_id, t.id AS technician_id, t.display_name,
					t.rating_avg, t.rating_count, t.latitude, t.longitude,
					ts.pricing_type, ts.price_min, ts.price_max, ts.price_fixed, t.is_available
				FROM technicians t
				JOIN technician_services ts ON ts.technician_id = t.id AND ts.is_active = 1
				WHERE t.is_available = 1`,
		},

		{
			name: "Create auto_match_technician",
			sql: `CREATE PROCEDURE auto_match_technician (
				IN p_customer_id INT,
				IN p_service_id INT,
				IN p_province_id INT,
				IN p_min_price DECIMAL(12,2),
				IN p_max_price DECIMAL(12,2),
				IN p_max_distance DECIMAL(10,2)
			)
			BEGIN
				DECLARE v_lat DECIMAL(10,7);
				DECLARE v_lon DECIMAL(10,7);
				
				SELECT latitude, longitude INTO v_lat, v_lon 
				FROM customers WHERE id = p_customer_id;
				
				IF v_lat IS NULL OR v_lon IS NULL THEN
					SELECT NULL AS technician_id, 'Missing customer location' AS message;
				ELSE
					SELECT 
						v.technician_id, 
						v.display_name,
						(
							6371 * 2 * ASIN(SQRT(
								POWER(SIN((RADIANS(v.latitude)-RADIANS(v_lat))/2),2) +
								COS(RADIANS(v_lat))*COS(RADIANS(v.latitude))*
								POWER(SIN((RADIANS(v.longitude)-RADIANS(v_lon))/2),2)
							))
						) AS distance_km,
						COALESCE(v.price_min, v.price_fixed) AS base_price,
						v.rating_avg, v.rating_count
					FROM view_technicians_per_service v
					JOIN technician_service_areas a
						ON a.technician_id = v.technician_id AND a.province_id = p_province_id
					WHERE v.service_id = p_service_id
						AND v.is_available = 1
						AND (COALESCE(v.price_min, v.price_fixed) BETWEEN p_min_price AND p_max_price)
						AND (
							6371 * 2 * ASIN(SQRT(
								POWER(SIN((RADIANS(v.latitude)-RADIANS(v_lat))/2),2) +
								COS(RADIANS(v_lat))*COS(RADIANS(v.latitude))*
								POWER(SIN((RADIANS(v.longitude)-RADIANS(v_lon))/2),2)
							))
						) <= p_max_distance
					ORDER BY RAND() LIMIT 1;
				END IF;
			END`,
		},
		{
			name: "Create create_reservation",
			sql: `CREATE PROCEDURE create_reservation (
				IN p_customer_id INT,
				IN p_technician_id INT,
				IN p_service_id INT,
				IN p_start_at DATETIME,
				IN p_end_at DATETIME,
				IN p_timezone VARCHAR(50),
				IN p_confirmation_deadline DATETIME,
				IN p_address VARCHAR(500),
				IN p_province_id INT,
				IN p_lat DECIMAL(10,7),
				IN p_lon DECIMAL(10,7),
				IN p_price_estimate DECIMAL(12,2),
				IN p_notes TEXT
			)
			BEGIN
				DECLARE v_status_pending TINYINT UNSIGNED;
				
				SELECT id INTO v_status_pending
				FROM reservation_statuses WHERE code = 'pending' LIMIT 1;
				
				INSERT INTO reservations
					(customer_id, technician_id, service_id,
					 start_at, end_at, timezone, status_id, confirmation_deadline,
					 address, province_id, latitude, longitude, price_estimate, notes)
				VALUES
					(p_customer_id, p_technician_id, p_service_id,
					 p_start_at, p_end_at, COALESCE(p_timezone,'Asia/Bangkok'),
					 v_status_pending, p_confirmation_deadline,
					 p_address, p_province_id, p_lat, p_lon,
					 p_price_estimate, p_notes);
				
				INSERT INTO reservation_status_logs (reservation_id, old_status_id, new_status_id)
				VALUES (LAST_INSERT_ID(), NULL, v_status_pending);
				
				SELECT LAST_INSERT_ID() AS reservation_id;
			END`,
		},
		{
			name: "Create set_reservation_status",
			sql: `CREATE PROCEDURE set_reservation_status(
				IN p_reservation_id INT,
				IN p_new_status_code VARCHAR(20)
			)
			BEGIN
				DECLARE v_new_status_id TINYINT UNSIGNED;
				DECLARE v_old_status_id TINYINT UNSIGNED;
				
				SELECT id INTO v_new_status_id 
				FROM reservation_statuses WHERE code = p_new_status_code LIMIT 1;
				
				SELECT status_id INTO v_old_status_id 
				FROM reservations WHERE id = p_reservation_id;
				
				UPDATE reservations SET status_id = v_new_status_id 
				WHERE id = p_reservation_id;
				
				INSERT INTO reservation_status_logs (reservation_id, old_status_id, new_status_id)
				VALUES (p_reservation_id, v_old_status_id, v_new_status_id);
			END`,
		},
	}

	for i, stmt := range stmts {
		log.Printf("   [%d/%d] %s", i+1, len(stmts), stmt.name)
		if _, err := sqlDB.Exec(stmt.sql); err != nil {
			return fmt.Errorf("failed '%s': %w", stmt.name, err)
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
		{
			objectType: "VIEW",
			name:       "view_service_starting_prices",
			query:      "SELECT COUNT(*) FROM information_schema.VIEWS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'view_service_starting_prices'",
		},
		{
			objectType: "VIEW",
			name:       "view_technicians_per_service",
			query:      "SELECT COUNT(*) FROM information_schema.VIEWS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'view_technicians_per_service'",
		},
		{
			objectType: "PROCEDURE",
			name:       "auto_match_technician",
			query:      "SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'auto_match_technician' AND ROUTINE_TYPE = 'PROCEDURE'",
		},
		{
			objectType: "PROCEDURE",
			name:       "create_reservation",
			query:      "SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'create_reservation' AND ROUTINE_TYPE = 'PROCEDURE'",
		},
		{
			objectType: "PROCEDURE",
			name:       "set_reservation_status",
			query:      "SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'set_reservation_status' AND ROUTINE_TYPE = 'PROCEDURE'",
		},
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
