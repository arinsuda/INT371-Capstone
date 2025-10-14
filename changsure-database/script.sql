-- ============================================
-- ChangSure - Reservation Only (Full-Ready Core)
-- Focus: Province → Category → Service → Technician → Reservation
-- + Views, Indexes, Auto-Match (Randomized Filters)
-- MySQL 8.0.42
-- ============================================

DROP DATABASE IF EXISTS `ChangSureV1`;
CREATE DATABASE `ChangSureV1` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ChangSureV1`;

SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET time_zone = '+00:00';

-- ============================================
-- Helper: Distance fn (km)
-- ============================================
DELIMITER $$
CREATE FUNCTION IF NOT EXISTS calculate_distance(
  lat1 DECIMAL(10,7), lon1 DECIMAL(10,7),
  lat2 DECIMAL(10,7), lon2 DECIMAL(10,7)
) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  RETURN 6371 * 2 * ASIN(SQRT(
    POWER(SIN((RADIANS(lat2)-RADIANS(lat1))/2),2) +
    COS(RADIANS(lat1))*COS(RADIANS(lat2))*
    POWER(SIN((RADIANS(lon2)-RADIANS(lon1))/2),2)
  ));
END$$
DELIMITER ;

-- ============================================
-- Lookup
-- ============================================
CREATE TABLE provinces (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name_th VARCHAR(100) NOT NULL UNIQUE,
  name_en VARCHAR(100) NULL,
  region VARCHAR(50) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO provinces (name_th, name_en, region) VALUES
('กรุงเทพมหานคร','Bangkok','Central'),
('เชียงใหม่','Chiang Mai','North'),
('ชลบุรี','Chonburi','East')
ON DUPLICATE KEY UPDATE name_en=VALUES(name_en), region=VALUES(region);

CREATE TABLE reservation_statuses (
  id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO reservation_statuses (code,name) VALUES
('pending','Pending'),
('confirmed','Confirmed'),
('in_progress','In Progress'),
('completed','Completed'),
('cancelled','Cancelled');

-- ============================================
-- Service Catalog
-- ============================================
CREATE TABLE service_categories (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(190) NOT NULL,
  description TEXT NULL,
  icon_url VARCHAR(500) NULL,
  sort_order INT UNSIGNED NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_active (is_active),
  INDEX idx_sort (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE services (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  category_id INT UNSIGNED NOT NULL,
  name VARCHAR(190) NOT NULL,
  description TEXT NULL,
  icon_url VARCHAR(500) NULL,
  duration_minutes INT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE RESTRICT,
  INDEX idx_category_active (category_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Technicians
-- ============================================
CREATE TABLE technicians (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  display_name VARCHAR(190) NOT NULL,
  bio TEXT NULL,
  province_id INT UNSIGNED NULL,
  latitude DECIMAL(10,7) NULL,
  longitude DECIMAL(10,7) NULL,
  rating_avg DECIMAL(3,2) NOT NULL DEFAULT 0.00,
  rating_count INT UNSIGNED NOT NULL DEFAULT 0,
  is_available TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (province_id) REFERENCES provinces(id) ON DELETE SET NULL,
  INDEX idx_province (province_id),
  INDEX idx_available (is_available),
  INDEX idx_geo (latitude, longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- พื้นที่บริการรายจังหวัด (ใช้ตอนเลือกจังหวัดก่อน)
CREATE TABLE technician_service_areas (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id INT UNSIGNED NOT NULL,
  province_id INT UNSIGNED NOT NULL,
  FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE CASCADE,
  FOREIGN KEY (province_id) REFERENCES provinces(id) ON DELETE CASCADE,
  UNIQUE KEY uq_tech_province (technician_id, province_id),
  INDEX idx_province (province_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ราคา/เรตของช่างต่อบริการ
CREATE TABLE technician_services (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id INT UNSIGNED NOT NULL,
  service_id INT UNSIGNED NOT NULL,
  pricing_type ENUM('fixed','range','negotiable') NOT NULL DEFAULT 'range',
  price_fixed DECIMAL(12,2) NULL,
  price_min DECIMAL(12,2) NULL,
  price_max DECIMAL(12,2) NULL,
  currency CHAR(3) NOT NULL DEFAULT 'THB',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE CASCADE,
  FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
  UNIQUE KEY uq_tech_service (technician_id, service_id),
  INDEX idx_service_active (service_id, is_active),
  INDEX idx_price_min (service_id, price_min)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Customers (Demo only; ไม่มีระบบ Auth ในสคริปต์นี้)
-- ============================================
CREATE TABLE customers (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  fullname VARCHAR(190) NOT NULL,
  phone VARCHAR(32) NULL,
  province_id INT UNSIGNED NULL,
  address VARCHAR(500) NULL,
  latitude DECIMAL(10,7) NULL,
  longitude DECIMAL(10,7) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (province_id) REFERENCES provinces(id) ON DELETE SET NULL,
  INDEX idx_province (province_id),
  INDEX idx_geo (latitude, longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Reservations (หัวใจของระบบ)
-- ============================================
CREATE TABLE reservations (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  customer_id INT UNSIGNED NOT NULL,
  technician_id INT UNSIGNED NOT NULL,
  service_id INT UNSIGNED NOT NULL,
  start_at DATETIME NOT NULL COMMENT 'UTC',
  end_at DATETIME NOT NULL COMMENT 'UTC',
  timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Bangkok',
  status_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  confirmation_deadline DATETIME NOT NULL,
  address VARCHAR(500) NOT NULL,
  province_id INT UNSIGNED NULL,
  latitude DECIMAL(10,7) NULL,
  longitude DECIMAL(10,7) NULL,
  price_estimate DECIMAL(12,2) NULL,
  price_final DECIMAL(12,2) NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT,
  FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE RESTRICT,
  FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT,
  FOREIGN KEY (status_id) REFERENCES reservation_statuses(id),
  FOREIGN KEY (province_id) REFERENCES provinces(id) ON DELETE SET NULL,
  INDEX idx_customer_status (customer_id, status_id),
  INDEX idx_technician_status (technician_id, status_id),
  INDEX idx_resv_time (technician_id, start_at, end_at),
  INDEX idx_start_at (start_at),
  INDEX idx_status (status_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ประวัติการเปลี่ยนสถานะ (Audit)
CREATE TABLE reservation_status_logs (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  reservation_id INT UNSIGNED NOT NULL,
  old_status_id TINYINT UNSIGNED NULL,
  new_status_id TINYINT UNSIGNED NOT NULL,
  changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE CASCADE,
  FOREIGN KEY (old_status_id) REFERENCES reservation_statuses(id),
  FOREIGN KEY (new_status_id) REFERENCES reservation_statuses(id),
  INDEX idx_resv_time (reservation_id, changed_at),
  INDEX idx_resv_status (reservation_id, new_status_id, changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Views (ช่วย FE)
-- ============================================
-- ราคาเริ่มต้นของบริการ = MIN(price_min) ของช่างที่เปิดรับงาน
DROP VIEW IF EXISTS view_service_starting_prices;
CREATE VIEW view_service_starting_prices AS
SELECT s.id AS service_id, s.name AS service_name,
       MIN(ts.price_min) AS starting_price
FROM services s
JOIN technician_services ts ON ts.service_id = s.id AND ts.is_active = 1
WHERE s.is_active = 1
GROUP BY s.id, s.name;

-- รายชื่อช่างที่รับงานตามบริการ (ไว้ต่อยอดคำนวณระยะทางภายนอก/ใน SP)
DROP VIEW IF EXISTS view_technicians_per_service;
CREATE VIEW view_technicians_per_service AS
SELECT
  ts.service_id,
  t.id AS technician_id,
  t.display_name,
  t.rating_avg,
  t.rating_count,
  t.latitude,
  t.longitude,
  ts.pricing_type,
  ts.price_min,
  ts.price_max,
  ts.price_fixed,
  t.is_available
FROM technicians t
JOIN technician_services ts ON ts.technician_id = t.id AND ts.is_active = 1
WHERE t.is_available = 1;

-- ============================================
-- Stored Procedures
-- ============================================
DELIMITER $$

-- Auto-match แบบ "สุ่ม 1 คน" ที่ผ่านตัวกรอง ราคา/ระยะทาง/จังหวัด/บริการ
DROP PROCEDURE IF EXISTS auto_match_technician $$
CREATE PROCEDURE auto_match_technician (
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
    SELECT v.technician_id, v.display_name,
           calculate_distance(v_lat, v_lon, v.latitude, v.longitude) AS distance_km,
           COALESCE(v.price_min, v.price_fixed) AS base_price,
           v.rating_avg, v.rating_count
    FROM view_technicians_per_service v
    JOIN technician_service_areas a
      ON a.technician_id = v.technician_id
     AND a.province_id   = p_province_id
    WHERE v.service_id = p_service_id
      AND v.is_available = 1
      AND (COALESCE(v.price_min, v.price_fixed) BETWEEN p_min_price AND p_max_price)
      AND calculate_distance(v_lat, v_lon, v.latitude, v.longitude) <= p_max_distance
    ORDER BY RAND()
    LIMIT 1;
  END IF;
END $$

-- ช่วยสร้าง Reservation + เขียน Log สถานะ (เริ่มต้นเป็น pending)
DROP PROCEDURE IF EXISTS create_reservation $$
CREATE PROCEDURE create_reservation (
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
     start_at, end_at, timezone,
     status_id, confirmation_deadline,
     address, province_id, latitude, longitude,
     price_estimate, notes)
  VALUES
    (p_customer_id, p_technician_id, p_service_id,
     p_start_at, p_end_at, COALESCE(p_timezone,'Asia/Bangkok'),
     v_status_pending, p_confirmation_deadline,
     p_address, p_province_id, p_lat, p_lon,
     p_price_estimate, p_notes);

  INSERT INTO reservation_status_logs (reservation_id, old_status_id, new_status_id)
  VALUES (LAST_INSERT_ID(), NULL, v_status_pending);

  SELECT LAST_INSERT_ID() AS reservation_id;
END $$

-- อัปเดตสถานะ Reservation พร้อม Log
DROP PROCEDURE IF EXISTS set_reservation_status $$
CREATE PROCEDURE set_reservation_status(
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

  UPDATE reservations
  SET status_id = v_new_status_id
  WHERE id = p_reservation_id;

  INSERT INTO reservation_status_logs (reservation_id, old_status_id, new_status_id)
  VALUES (p_reservation_id, v_old_status_id, v_new_status_id);
END $$

DELIMITER ;

-- ============================================
-- Seed (ตัวอย่างข้อมูล)
-- ============================================
INSERT INTO service_categories (name, description, sort_order) VALUES
('งานประปา','ซ่อมท่อ เปลี่ยนก็อก ติดตั้งสุขภัณฑ์',1),
('งานไฟฟ้า','ปลั๊กไฟ สวิตช์ เดินสายไฟ',2)
ON DUPLICATE KEY UPDATE description=VALUES(description), sort_order=VALUES(sort_order);

INSERT INTO services (category_id, name, description, duration_minutes) VALUES
(1,'ซ่อมท่อน้ำ','แก้ท่อรั่ว อุดรอยรั่ว เปลี่ยนท่อ',120),
(1,'ติดตั้งก๊อกน้ำ','ติดตั้งก๊อกน้ำใหม่',60),
(2,'ติดตั้งปลั๊กไฟ','เพิ่ม/ย้ายปลั๊กไฟ',90),
(2,'ซ่อมสวิตช์ไฟ','เปลี่ยนสวิตช์เสีย',60)
ON DUPLICATE KEY UPDATE description=VALUES(description), duration_minutes=VALUES(duration_minutes);

INSERT INTO technicians (display_name, bio, province_id, latitude, longitude, rating_avg, rating_count, is_available)
VALUES
('ช่างเอก ประปา', 'ประปา 8 ปี', 1, 13.7563, 100.5018, 4.8, 120, 1),
('ช่างบาส ไฟฟ้า', 'ไฟฟ้า 6 ปี', 1, 13.7500, 100.5200, 4.6, 90, 1),
('ช่างมายด์ ชลบุรี', 'ไฟฟ้า/ประปา 5 ปี', 3, 13.3611, 100.9847, 4.7, 60, 1)
ON DUPLICATE KEY UPDATE bio=VALUES(bio), province_id=VALUES(province_id);

INSERT INTO technician_service_areas (technician_id, province_id) VALUES
(1,1),(2,1),(3,3)
ON DUPLICATE KEY UPDATE province_id=VALUES(province_id);

INSERT INTO technician_services (technician_id, service_id, pricing_type, price_min, price_max, price_fixed)
VALUES
(1,1,'range',500,1200,NULL),
(1,2,'fixed',NULL,NULL,700),
(2,3,'range',600,1500,NULL),
(2,4,'fixed',NULL,NULL,650),
(3,1,'range',450,1000,NULL),
(3,3,'range',550,1300,NULL)
ON DUPLICATE KEY UPDATE pricing_type=VALUES(pricing_type),
  price_min=VALUES(price_min), price_max=VALUES(price_max), price_fixed=VALUES(price_fixed);

INSERT INTO customers (fullname, phone, province_id, address, latitude, longitude)
VALUES ('คุณเอม','0800000000',1,'เขตปทุมวัน กทม.',13.7460,100.5320);

-- ============================================
-- Example Usage
-- ============================================
/*
-- 1) แสดงบริการพร้อม "ราคาเริ่มต้น"
SELECT * FROM view_service_starting_prices ORDER BY service_name;

-- 2) ให้ระบบสุ่มช่างที่ตรงตัวกรอง (จังหวัด=1, บริการ=3, ราคา 0–900, ระยะ <= 20 กม.)
CALL auto_match_technician(1, 3, 1, 0, 900, 20);

-- 3) สมมติสุ่มได้ technician_id = 2 → สร้างการจอง
CALL create_reservation(
  1,          -- customer_id
  2,          -- technician_id
  3,          -- service_id
  '2025-10-07 02:00:00',  -- start_at (UTC)
  '2025-10-07 03:30:00',  -- end_at   (UTC)
  'Asia/Bangkok',
  '2025-10-06 18:00:00',  -- confirmation_deadline
  'บางรัก กทม.',         -- address
  1,                      -- province_id
  13.7300, 100.5300,      -- lat, lon
  800.00,                 -- price_estimate
  'ติดตั้งปลั๊กเพิ่ม'      -- notes
);

-- 4) อัปเดตสถานะ (เช่น จาก pending → confirmed)
CALL set_reservation_status(1, 'confirmed');
*/
-- ============================================
-- End
-- ============================================
