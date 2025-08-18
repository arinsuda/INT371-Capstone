
-- =====================================================================
-- Online Technician Booking App - MySQL 8.0 Schema (Engine=InnoDB)
-- Character set: utf8mb4, Collation: utf8mb4_0900_ai_ci
-- Time zone recommendation: store all timestamps in UTC.
-- =====================================================================

SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- ---------------------------------------------------------------------
-- Helper: status enums (use ENUM for performance & correctness in MySQL)
-- ---------------------------------------------------------------------

-- You can inline ENUM in each table; they’re listed here for reference:
-- users.role:        ('customer','technician','admin')
-- users.status:      ('active','suspended','deleted')
-- tech.status:       ('pending','verified','rejected')
-- verify.status:     ('pending','approved','rejected')
-- service.rate_unit: ('hour','job')
-- request.status:    ('open','matched','cancelled','expired')
-- order.status:      ('pending','accepted','in_progress','completed','cancelled')
-- payment.provider:  ('stripe','omise','promptpay','cash')
-- payment.status:    ('pending','authorized','captured','refunded','failed')
-- payout.status:     ('pending','paid','failed')
-- dispute.status:    ('open','under_review','resolved','rejected')
-- notification.type: (free text, index by type if needed)

-- =====================================================================
-- USERS & PROFILES
-- =====================================================================

CREATE TABLE users (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  email         VARCHAR(190) UNIQUE,
  phone         VARCHAR(32)  UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('customer','technician','admin') NOT NULL,
  status        ENUM('active','suspended','deleted') NOT NULL DEFAULT 'active',
  last_login_at TIMESTAMP NULL DEFAULT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at    TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT chk_user_contact CHECK (email IS NOT NULL OR phone IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE customer_profiles (
  id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id         BIGINT UNSIGNED NOT NULL,
  firstname       VARCHAR(100) NOT NULL,
  lastname       VARCHAR(100) NOT NULL,
  avatar_url      VARCHAR(500) NULL,
  default_address VARCHAR(500) NULL,
  default_lat     DECIMAL(9,6) NULL,
  default_lng     DECIMAL(9,6) NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_customer_user (user_id),
  CONSTRAINT fk_customer_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE technician_profiles (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NOT NULL,
  display_name  VARCHAR(190) NOT NULL,
  bio           TEXT NULL,
  id_card_no    VARCHAR(64) NULL,
  status        ENUM('pending','verified','rejected') NOT NULL DEFAULT 'pending',
  rating_avg    DECIMAL(3,2) NOT NULL DEFAULT 0.00,
  rating_count  INT UNSIGNED NOT NULL DEFAULT 0,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_technician_user (user_id),
  KEY idx_technician_status (status),
  CONSTRAINT fk_technician_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE admin_profiles (
  id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id    BIGINT UNSIGNED NOT NULL,
  firstname  VARCHAR(100) NOT NULL,
  lastname   VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_admin_user (user_id),
  CONSTRAINT fk_admin_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =====================================================================
-- TECHNICIAN VERIFICATION & SERVICE SETUP
-- =====================================================================

CREATE TABLE technician_verifications (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id  BIGINT UNSIGNED NOT NULL,
  doc_type       ENUM('id_card','certificate','license') NOT NULL,
  doc_url        VARCHAR(500) NOT NULL,
  verify_status  ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  verified_by    BIGINT UNSIGNED NULL,   -- admin user_id
  verified_at    TIMESTAMP NULL DEFAULT NULL,
  remark         VARCHAR(500) NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_tv_tech_status (technician_id, verify_status),
  CONSTRAINT fk_tv_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tv_verified_by FOREIGN KEY (verified_by) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE service_categories (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name        VARCHAR(190) NOT NULL,
  description VARCHAR(500) NULL,
  parent_id   BIGINT UNSIGNED NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_sc_parent (parent_id),
  CONSTRAINT fk_sc_parent FOREIGN KEY (parent_id) REFERENCES service_categories(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE technician_services (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id BIGINT UNSIGNED NOT NULL,
  category_id   BIGINT UNSIGNED NOT NULL,
  service_title VARCHAR(190) NOT NULL,
  service_desc  TEXT NULL,
  base_rate     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  rate_unit     ENUM('hour','job') NOT NULL,
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_tech_category (technician_id, category_id, service_title),
  KEY idx_ts_lookup (category_id, is_active),
  CONSTRAINT fk_ts_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ts_category FOREIGN KEY (category_id) REFERENCES service_categories(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Technician weekly availability
CREATE TABLE technician_availabilities (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id BIGINT UNSIGNED NOT NULL,
  weekday       TINYINT UNSIGNED NOT NULL,     -- 0=Sun .. 6=Sat
  start_time    TIME NOT NULL,
  end_time      TIME NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_avail (technician_id, weekday, start_time, end_time),
  KEY idx_avail_tech (technician_id),
  CONSTRAINT fk_ta_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_time_range CHECK (start_time < end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Real-time location (use POINT with SRID 4326 + SPATIAL INDEX)
CREATE TABLE technician_locations (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id BIGINT UNSIGNED NOT NULL UNIQUE,
  location      POINT NOT NULL SRID 4326,
  lat           DECIMAL(9,6) AS (ST_Y(location)) STORED,
  lng           DECIMAL(9,6) AS (ST_X(location)) STORED,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  SPATIAL INDEX spx_location (location),
  KEY idx_tl_updated (updated_at),
  CONSTRAINT fk_tl_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =====================================================================
-- SOCIAL: FAVORITES & REVIEWS
-- =====================================================================

CREATE TABLE favorites (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  customer_id   BIGINT UNSIGNED NOT NULL,
  technician_id BIGINT UNSIGNED NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_fav (customer_id, technician_id),
  KEY idx_fav_tech (technician_id),
  CONSTRAINT fk_fav_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_fav_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =====================================================================
-- BOOKING: REQUEST -> ORDER
-- =====================================================================

CREATE TABLE customer_addresses (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  customer_id   BIGINT UNSIGNED NOT NULL,
  label         VARCHAR(100) NOT NULL,   -- e.g., Home, Office
  address       VARCHAR(500) NOT NULL,
  location      POINT NULL SRID 4326,
  lat           DECIMAL(9,6) AS (IFNULL(ST_Y(location), NULL)) STORED,
  lng           DECIMAL(9,6) AS (IFNULL(ST_X(location), NULL)) STORED,
  is_default    TINYINT(1) NOT NULL DEFAULT 0,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  SPATIAL INDEX spx_addr_location (location),
  KEY idx_addr_customer (customer_id, is_default),
  CONSTRAINT fk_addr_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE job_requests (
  id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  customer_id     BIGINT UNSIGNED NOT NULL,
  category_id     BIGINT UNSIGNED NOT NULL,
  title           VARCHAR(190) NOT NULL,
  description     TEXT NULL,
  budget_min      DECIMAL(10,2) NULL,
  budget_max      DECIMAL(10,2) NULL,
  is_urgent       TINYINT(1) NOT NULL DEFAULT 0,
  service_address VARCHAR(500) NULL,
  service_point   POINT NULL SRID 4326,
  service_lat     DECIMAL(9,6) AS (IFNULL(ST_Y(service_point), NULL)) STORED,
  service_lng     DECIMAL(9,6) AS (IFNULL(ST_X(service_point), NULL)) STORED,
  preferred_start DATETIME NULL,
  preferred_end   DATETIME NULL,
  expires_at      DATETIME NULL,
  status          ENUM('open','matched','cancelled','expired') NOT NULL DEFAULT 'open',
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  SPATIAL INDEX spx_request_point (service_point),
  KEY idx_request_status (status, category_id, is_urgent),
  CONSTRAINT fk_jr_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_jr_category FOREIGN KEY (category_id) REFERENCES service_categories(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE request_media (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_request_id BIGINT UNSIGNED NOT NULL,
  file_url       VARCHAR(500) NOT NULL,
  file_type      VARCHAR(50) NOT NULL, -- image/jpeg, video/mp4, etc.
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_rm_request (job_request_id),
  CONSTRAINT fk_rm_request FOREIGN KEY (job_request_id) REFERENCES job_requests(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Quotes (optional but recommended for marketplace flow)
CREATE TABLE quotes (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_request_id BIGINT UNSIGNED NOT NULL,
  technician_id  BIGINT UNSIGNED NOT NULL,
  message        VARCHAR(500) NULL,
  price_quote    DECIMAL(10,2) NOT NULL,
  status         ENUM('sent','accepted','rejected','withdrawn') NOT NULL DEFAULT 'sent',
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_quote (job_request_id, technician_id),
  KEY idx_quote_lookup (job_request_id, status),
  CONSTRAINT fk_quote_request FOREIGN KEY (job_request_id) REFERENCES job_requests(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_quote_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE job_orders (
  id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_request_id  BIGINT UNSIGNED NOT NULL,
  customer_id     BIGINT UNSIGNED NOT NULL,
  technician_id   BIGINT UNSIGNED NOT NULL,
  quote_id        BIGINT UNSIGNED NULL,          -- if created from a quote
  status          ENUM('pending','accepted','in_progress','completed','cancelled') NOT NULL DEFAULT 'pending',
  scheduled_start DATETIME NULL,
  scheduled_end   DATETIME NULL,
  started_at      DATETIME NULL,
  completed_at    DATETIME NULL,
  agreed_price    DECIMAL(10,2) NULL,
  cancel_reason   VARCHAR(500) NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_order_tech_status (technician_id, status),
  KEY idx_order_customer (customer_id, status),
  CONSTRAINT fk_order_request FOREIGN KEY (job_request_id) REFERENCES job_requests(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_order_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_order_quote FOREIGN KEY (quote_id) REFERENCES quotes(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE order_media (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id  BIGINT UNSIGNED NOT NULL,
  file_url      VARCHAR(500) NOT NULL,
  file_type     VARCHAR(50) NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_om_order (job_order_id),
  CONSTRAINT fk_om_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Line items (e.g., parts, travel fee)
CREATE TABLE order_line_items (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id  BIGINT UNSIGNED NOT NULL,
  item_type     VARCHAR(50) NOT NULL,  -- 'labor','part','travel','discount'
  description   VARCHAR(255) NOT NULL,
  qty           DECIMAL(10,2) NOT NULL DEFAULT 1.00,
  unit_price    DECIMAL(10,2) NOT NULL,
  amount        DECIMAL(10,2) AS (ROUND(qty * unit_price, 2)) STORED,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_oli_order (job_order_id),
  CONSTRAINT fk_oli_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE reviews (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id   BIGINT UNSIGNED NOT NULL,
  customer_id    BIGINT UNSIGNED NOT NULL,
  technician_id  BIGINT UNSIGNED NOT NULL,
  rating         TINYINT UNSIGNED NOT NULL, -- 1..5
  comment        VARCHAR(1000) NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_review (job_order_id, customer_id),
  KEY idx_review_tech (technician_id, rating),
  CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT fk_review_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_review_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_review_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =====================================================================
-- PAYMENTS, PAYOUTS, DISPUTES
-- =====================================================================

CREATE TABLE payments (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id  BIGINT UNSIGNED NOT NULL,
  provider      ENUM('stripe','omise','promptpay','cash') NOT NULL,
  intent_id     VARCHAR(190) NULL, -- provider’s payment intent/session id
  status        ENUM('pending','authorized','captured','refunded','failed') NOT NULL DEFAULT 'pending',
  amount        DECIMAL(10,2) NOT NULL,
  fee           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  paid_at       DATETIME NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_payment_order (job_order_id, provider),
  KEY idx_payment_status (status),
  CONSTRAINT fk_payment_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE payouts (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  payment_id    BIGINT UNSIGNED NOT NULL,
  technician_id BIGINT UNSIGNED NOT NULL,
  amount        DECIMAL(10,2) NOT NULL,
  status        ENUM('pending','paid','failed') NOT NULL DEFAULT 'pending',
  paid_at       DATETIME NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_payout (payment_id, technician_id),
  KEY idx_payout_status (status),
  CONSTRAINT fk_payout_payment FOREIGN KEY (payment_id) REFERENCES payments(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_payout_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE disputes (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id       BIGINT UNSIGNED NOT NULL,
  raised_by_user_id  BIGINT UNSIGNED NOT NULL,
  reason             VARCHAR(500) NOT NULL,
  status             ENUM('open','under_review','resolved','rejected') NOT NULL DEFAULT 'open',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at        DATETIME NULL,
  KEY idx_dispute_order (job_order_id, status),
  CONSTRAINT fk_dispute_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_dispute_user FOREIGN KEY (raised_by_user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Optional: coupons
CREATE TABLE coupons (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  code          VARCHAR(50) UNIQUE NOT NULL,
  description   VARCHAR(255) NULL,
  discount_type ENUM('amount','percent') NOT NULL,
  discount_val  DECIMAL(10,2) NOT NULL,
  max_uses      INT UNSIGNED NULL,
  valid_from    DATETIME NULL,
  valid_to      DATETIME NULL,
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE coupon_usages (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  coupon_id    BIGINT UNSIGNED NOT NULL,
  user_id      BIGINT UNSIGNED NOT NULL,
  job_order_id BIGINT UNSIGNED NULL,
  used_at      DATETIME NOT NULL,
  UNIQUE KEY uniq_coupon_user_order (coupon_id, user_id, job_order_id),
  KEY idx_coupon_user (coupon_id, user_id),
  CONSTRAINT fk_cu_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_cu_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_cu_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =====================================================================
-- SESSIONS, NOTIFICATIONS, CHAT
-- =====================================================================

CREATE TABLE sessions (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id     BIGINT UNSIGNED NOT NULL,
  device      VARCHAR(150) NULL,
  ip          VARCHAR(45) NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revoked_at  DATETIME NULL,
  KEY idx_session_user (user_id, created_at),
  CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE notifications (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id      BIGINT UNSIGNED NOT NULL,
  type         VARCHAR(100) NOT NULL,
  payload_json JSON NOT NULL,
  is_read      TINYINT(1) NOT NULL DEFAULT 0,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_notif_user (user_id, is_read, created_at),
  CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE chats (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id  BIGINT UNSIGNED NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_chat_order (job_order_id),
  CONSTRAINT fk_chat_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE chat_messages (
  id               BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  chat_id          BIGINT UNSIGNED NOT NULL,
  sender_user_id   BIGINT UNSIGNED NOT NULL,
  message          VARCHAR(2000) NULL,
  attachment_url   VARCHAR(500) NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_cm_chat (chat_id, created_at),
  CONSTRAINT fk_cm_chat FOREIGN KEY (chat_id) REFERENCES chats(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_cm_sender FOREIGN KEY (sender_user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =====================================================================
-- AUDIT LOGS
-- =====================================================================

CREATE TABLE audit_logs (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  actor_user_id BIGINT UNSIGNED NULL,
  action       VARCHAR(100) NOT NULL,       -- e.g., 'VERIFY_TECHNICIAN','ORDER_STATUS_CHANGE'
  target_type  VARCHAR(50) NOT NULL,        -- 'technician','job_order','payment', etc.
  target_id    BIGINT UNSIGNED NULL,
  metadata     JSON NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_audit_actor (actor_user_id, created_at),
  KEY idx_audit_target (target_type, target_id),
  CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =====================================================================
-- TRIGGERS (example): keep technician rating_avg & rating_count in sync
-- =====================================================================

DELIMITER $$
CREATE TRIGGER trg_reviews_after_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
  UPDATE technician_profiles tp
  SET tp.rating_count = tp.rating_count + 1,
      tp.rating_avg = (
        SELECT ROUND(AVG(r.rating), 2)
        FROM reviews r WHERE r.technician_id = NEW.technician_id
      )
  WHERE tp.id = NEW.technician_id;
END$$

CREATE TRIGGER trg_reviews_after_update
AFTER UPDATE ON reviews
FOR EACH ROW
BEGIN
  IF (OLD.rating <> NEW.rating) THEN
    UPDATE technician_profiles tp
    SET tp.rating_avg = (
      SELECT ROUND(AVG(r.rating), 2)
      FROM reviews r WHERE r.technician_id = NEW.technician_id
    )
    WHERE tp.id = NEW.technician_id;
  END IF;
END$$

CREATE TRIGGER trg_reviews_after_delete
AFTER DELETE ON reviews
FOR EACH ROW
BEGIN
  UPDATE technician_profiles tp
  SET tp.rating_count = GREATEST(tp.rating_count - 1, 0),
      tp.rating_avg = COALESCE((
        SELECT ROUND(AVG(r.rating), 2)
        FROM reviews r WHERE r.technician_id = OLD.technician_id
      ), 0.00)
  WHERE tp.id = OLD.technician_id;
END$$
DELIMITER ;
