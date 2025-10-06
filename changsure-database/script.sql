-- ============================================
-- ChangSure Demo (Ultra-Minified)
-- Core: Province → Service → Technician → Appointment + Auto-Match
-- ============================================

DROP DATABASE IF EXISTS `ChangSureDemo`;
CREATE DATABASE `ChangSureDemo` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ChangSureDemo`;

-- ========== Helper ==========
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

-- ========== Lookup ==========
CREATE TABLE provinces (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name_th VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO provinces (name_th) VALUES ('กรุงเทพมหานคร'),('เชียงใหม่'),('ชลบุรี');

CREATE TABLE appointment_statuses (
  id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(20) UNIQUE
);
INSERT INTO appointment_statuses (code) VALUES ('pending'),('confirmed'),('completed');

-- ========== Service ==========
CREATE TABLE service_categories (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100)
);

CREATE TABLE services (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  category_id INT UNSIGNED,
  name VARCHAR(100),
  FOREIGN KEY (category_id) REFERENCES service_categories(id)
);

-- ========== Technician ==========
CREATE TABLE technicians (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  display_name VARCHAR(100),
  province_id INT UNSIGNED,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  rating DECIMAL(3,2),
  FOREIGN KEY (province_id) REFERENCES provinces(id)
);

CREATE TABLE technician_services (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id INT UNSIGNED,
  service_id INT UNSIGNED,
  price_min DECIMAL(10,2),
  price_max DECIMAL(10,2),
  FOREIGN KEY (technician_id) REFERENCES technicians(id),
  FOREIGN KEY (service_id) REFERENCES services(id)
);

CREATE TABLE technician_service_areas (
  technician_id INT UNSIGNED,
  province_id INT UNSIGNED,
  PRIMARY KEY (technician_id, province_id),
  FOREIGN KEY (technician_id) REFERENCES technicians(id),
  FOREIGN KEY (province_id) REFERENCES provinces(id)
);

-- ========== Customer ==========
CREATE TABLE customers (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  fullname VARCHAR(100),
  province_id INT UNSIGNED,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  FOREIGN KEY (province_id) REFERENCES provinces(id)
);

-- ========== Appointment ==========
CREATE TABLE appointments (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  customer_id INT UNSIGNED,
  technician_id INT UNSIGNED,
  service_id INT UNSIGNED,
  status_id TINYINT UNSIGNED,
  start_at DATETIME,
  price_estimate DECIMAL(10,2),
  FOREIGN KEY (customer_id) REFERENCES customers(id),
  FOREIGN KEY (technician_id) REFERENCES technicians(id),
  FOREIGN KEY (service_id) REFERENCES services(id),
  FOREIGN KEY (status_id) REFERENCES appointment_statuses(id)
);

-- ========== Auto-Match Technician ==========
DELIMITER $$
CREATE PROCEDURE auto_match_technician (
  IN p_customer_id INT,
  IN p_service_id INT,
  IN p_province_id INT,
  IN p_min_price DECIMAL(10,2),
  IN p_max_price DECIMAL(10,2),
  IN p_max_distance DECIMAL(10,2)
)
BEGIN
  DECLARE v_lat DECIMAL(10,7);
  DECLARE v_lon DECIMAL(10,7);
  SELECT latitude, longitude INTO v_lat, v_lon FROM customers WHERE id = p_customer_id;

  IF v_lat IS NULL OR v_lon IS NULL THEN
    SELECT NULL AS technician_id, 'Missing customer location' AS message;
  ELSE
    SELECT t.id AS technician_id, t.display_name,
           calculate_distance(v_lat, v_lon, t.latitude, t.longitude) AS distance_km,
           ts.price_min, ts.price_max
    FROM technicians t
    JOIN technician_services ts ON ts.technician_id = t.id
    JOIN technician_service_areas ta ON ta.technician_id = t.id AND ta.province_id = p_province_id
    WHERE ts.service_id = p_service_id
      AND ts.price_min BETWEEN p_min_price AND p_max_price
      AND calculate_distance(v_lat, v_lon, t.latitude, t.longitude) <= p_max_distance
    ORDER BY RAND()
    LIMIT 1;
  END IF;
END$$
DELIMITER ;

-- ========== Sample Data ==========
INSERT INTO service_categories (name) VALUES ('งานประปา'),('งานไฟฟ้า');
INSERT INTO services (category_id,name) VALUES (1,'ซ่อมท่อน้ำ'),(1,'ติดตั้งก๊อกน้ำ'),(2,'ซ่อมสวิตช์ไฟ');

INSERT INTO technicians (display_name,province_id,latitude,longitude,rating)
VALUES ('ช่างเอก',1,13.7563,100.5018,4.8),('ช่างบาส',1,13.75,100.52,4.6),('ช่างมายด์',3,13.3611,100.9847,4.7);

INSERT INTO technician_service_areas (technician_id, province_id) VALUES
(1,1),(2,1),(3,3);
INSERT INTO technician_services (technician_id, service_id, price_min, price_max) VALUES
(1,1,500,1200),
(1,2,600,900),
(2,3,700,1000),
(3,1,450,950);

INSERT INTO customers (fullname,province_id,latitude,longitude)
VALUES ('คุณเอม',1,13.746,100.532);

-- ========== Example Usage ==========
-- CALL auto_match_technician(1,1,1,0,900,20);
