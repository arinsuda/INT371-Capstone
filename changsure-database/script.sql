-- =====================================================================
-- Online Technician Booking App - Optimized MySQL 8.0 Schema
-- Character set: utf8mb4, Collation: utf8mb4_unicode_ci
-- Time zone recommendation: store all timestamps in UTC.
-- =====================================================================

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';

-- Create database with optimal settings
CREATE DATABASE IF NOT EXISTS changsure_app
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE changsure_app;

-- =====================================================================
-- USERS & PROFILES
-- =====================================================================

CREATE TABLE users (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  firstname     VARCHAR(100) NOT NULL,
  lastname      VARCHAR(100) NOT NULL,
  email         VARCHAR(190) NULL,
  phone         VARCHAR(32)  NULL,
  password_hash VARCHAR(255) NOT NULL,
  date_of_birth DATE NULL,
  gender        ENUM('male','female','other') NULL,
  role          ENUM('customer','technician','admin') NOT NULL,
  status        ENUM('active','suspended','deleted') NOT NULL DEFAULT 'active',
  avatar_url        VARCHAR(500) NULL,
  email_verified_at TIMESTAMP NULL DEFAULT NULL,
  last_login_at TIMESTAMP NULL DEFAULT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at    TIMESTAMP NULL DEFAULT NULL,
  
  -- Indexes
  UNIQUE KEY uniq_users_email (email),
  UNIQUE KEY uniq_users_phone (phone),
  KEY idx_users_role_status (role, status),
  KEY idx_users_status_created (status, created_at),
  KEY idx_users_last_login (last_login_at),
  
  -- Constraints
  CONSTRAINT chk_users_contact CHECK (
    (email IS NOT NULL AND email != '') OR (phone IS NOT NULL AND phone != '')
  ),
  CONSTRAINT chk_users_email_format CHECK (
    email IS NULL OR email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ROW_FORMAT=DYNAMIC;

CREATE TABLE customer_profiles (
  id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id           BIGINT UNSIGNED NOT NULL,
  default_address_id BIGINT UNSIGNED NULL,
  phone_backup      VARCHAR(32) NULL,
  preferences       JSON NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uniq_customer_user (user_id),

  CONSTRAINT fk_customer_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ROW_FORMAT=DYNAMIC;

CREATE TABLE technician_profiles (
  id               BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id          BIGINT UNSIGNED NOT NULL,
  display_name     VARCHAR(190) NOT NULL,
  bio              TEXT NULL,
  id_card_no       VARCHAR(64) NULL,
  tax_id           VARCHAR(64) NULL,
  bank_account     JSON NULL,
  experience_years TINYINT UNSIGNED NULL,
  status           ENUM('pending','verified','rejected','suspended') NOT NULL DEFAULT 'pending',
  rating_avg       DECIMAL(3,2) NOT NULL DEFAULT 0.00,
  rating_count     INT UNSIGNED NOT NULL DEFAULT 0,
  total_jobs       INT UNSIGNED NOT NULL DEFAULT 0,
  completion_rate  DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  response_time_avg INT UNSIGNED NULL,
  is_available     TINYINT(1) NOT NULL DEFAULT 1,
  last_seen_at     TIMESTAMP NULL DEFAULT NULL,
  verified_at      TIMESTAMP NULL DEFAULT NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_technician_user (user_id),
  UNIQUE KEY uniq_technician_id_card (id_card_no),
  KEY idx_technician_status (status),
  KEY idx_technician_available (is_available, status),
  KEY idx_technician_rating (rating_avg DESC, rating_count DESC),
  KEY idx_technician_performance (completion_rate DESC, total_jobs DESC),
  KEY idx_technician_last_seen (last_seen_at),
  
  -- Full-text search
  FULLTEXT KEY ft_technician_search (display_name, bio),
  
  -- Constraints
  CONSTRAINT fk_technician_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_technician_rating_avg CHECK (rating_avg BETWEEN 0.00 AND 5.00),
  CONSTRAINT chk_technician_completion_rate CHECK (completion_rate BETWEEN 0.00 AND 100.00),
  CONSTRAINT chk_technician_experience CHECK (experience_years IS NULL OR experience_years <= 50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ROW_FORMAT=DYNAMIC;

CREATE TABLE admin_profiles (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id     BIGINT UNSIGNED NOT NULL,
  permissions JSON NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY uniq_admin_user (user_id),
  
  CONSTRAINT fk_admin_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- TECHNICIAN VERIFICATION & CREDENTIALS
-- =====================================================================

CREATE TABLE technician_verifications (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id  BIGINT UNSIGNED NOT NULL,
  doc_type       ENUM('id_card','certificate','license','portfolio','insurance') NOT NULL,
  doc_url        VARCHAR(500) NOT NULL,
  doc_number     VARCHAR(100) NULL,
  issued_by      VARCHAR(200) NULL,
  expires_at     DATE NULL,
  verify_status  ENUM('pending','approved','rejected','expired') NOT NULL DEFAULT 'pending',
  verified_by    BIGINT UNSIGNED NULL,
  verified_at    TIMESTAMP NULL DEFAULT NULL,
  rejection_reason VARCHAR(500) NULL,
  notes          TEXT NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  KEY idx_tv_tech_status (technician_id, verify_status),
  KEY idx_tv_doc_type (doc_type, verify_status),
  KEY idx_tv_expiry (expires_at),
  KEY idx_tv_verified_by (verified_by),
  
  CONSTRAINT fk_tv_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tv_verified_by FOREIGN KEY (verified_by) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- SERVICE CATEGORIES & TECHNICIAN SERVICES
-- =====================================================================

CREATE TABLE service_categories (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name        VARCHAR(190) NOT NULL,
  description TEXT NULL,
  icon_url    VARCHAR(500) NULL,
  parent_id   BIGINT UNSIGNED NULL,
  level       TINYINT UNSIGNED NOT NULL DEFAULT 0,
  sort_order  INT UNSIGNED NOT NULL DEFAULT 0,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  is_featured TINYINT(1) NOT NULL DEFAULT 0,
  metadata    JSON NULL, -- additional category metadata
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_sc_name_parent (name, parent_id),
  KEY idx_sc_parent_active (parent_id, is_active, sort_order),
  KEY idx_sc_featured (is_featured, sort_order),
  KEY idx_sc_level (level, sort_order),
  
  -- Full-text search
  FULLTEXT KEY ft_sc_search (name, description),
  
  CONSTRAINT fk_sc_parent FOREIGN KEY (parent_id) REFERENCES service_categories(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT chk_sc_level CHECK (level <= 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE technician_services (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id BIGINT UNSIGNED NOT NULL,
  category_id   BIGINT UNSIGNED NOT NULL,
  service_title VARCHAR(190) NOT NULL,
  service_desc  TEXT NULL,
  base_rate     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  rate_unit     ENUM('hour','job','day') NOT NULL,
  min_duration  INT UNSIGNED NULL, -- in minutes
  max_duration  INT UNSIGNED NULL, -- in minutes
  travel_fee    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  materials_included TINYINT(1) NOT NULL DEFAULT 0,
  warranty_period INT UNSIGNED NULL, -- in days
  tags          JSON NULL, -- service tags for better search
  images        JSON NULL, -- service portfolio images
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  sort_order    INT UNSIGNED NOT NULL DEFAULT 0,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_tech_category_title (technician_id, category_id, service_title),
  KEY idx_ts_category_active (category_id, is_active, sort_order),
  KEY idx_ts_tech_active (technician_id, is_active),
  KEY idx_ts_rate (base_rate),
  
  -- Full-text search
  FULLTEXT KEY ft_ts_search (service_title, service_desc),
  
  CONSTRAINT fk_ts_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ts_category FOREIGN KEY (category_id) REFERENCES service_categories(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_ts_duration CHECK (
    min_duration IS NULL OR max_duration IS NULL OR min_duration <= max_duration
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- TECHNICIAN AVAILABILITY & LOCATION
-- =====================================================================

CREATE TABLE technician_availabilities (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id BIGINT UNSIGNED NOT NULL,
  weekday       TINYINT UNSIGNED NOT NULL, -- 0=Sunday, 1=Monday, ... 6=Saturday
  start_time    TIME NOT NULL,
  end_time      TIME NOT NULL,
  break_start   TIME NULL,
  break_end     TIME NULL,
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_avail (technician_id, weekday, start_time, end_time),
  KEY idx_avail_tech_active (technician_id, is_active),
  KEY idx_avail_weekday (weekday, is_active),
  
  CONSTRAINT fk_ta_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_ta_weekday CHECK (weekday BETWEEN 0 AND 6),
  CONSTRAINT chk_ta_time_range CHECK (start_time < end_time),
  CONSTRAINT chk_ta_break_range CHECK (
    (break_start IS NULL AND break_end IS NULL) OR
    (break_start IS NOT NULL AND break_end IS NOT NULL AND break_start < break_end AND
     break_start >= start_time AND break_end <= end_time)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Special availability exceptions (holidays, vacation, etc.)
CREATE TABLE technician_availability_exceptions (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id BIGINT UNSIGNED NOT NULL,
  exception_date DATE NOT NULL,
  is_available  TINYINT(1) NOT NULL DEFAULT 0,
  start_time    TIME NULL,
  end_time      TIME NULL,
  reason        VARCHAR(255) NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY uniq_exception (technician_id, exception_date),
  KEY idx_exception_date (exception_date),
  
  CONSTRAINT fk_tae_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optimized location table with spatial indexing
CREATE TABLE technician_locations (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id BIGINT UNSIGNED NOT NULL,
  location      POINT NOT NULL SRID 4326,
  lat           DECIMAL(10,7) AS (ST_Y(location)) STORED,
  lng           DECIMAL(10,7) AS (ST_X(location)) STORED,
  accuracy      DECIMAL(8,2) NULL, -- GPS accuracy in meters
  heading       DECIMAL(5,1) NULL, -- direction in degrees
  speed         DECIMAL(5,1) NULL, -- km/h
  is_online     TINYINT(1) NOT NULL DEFAULT 1,
  battery_level TINYINT UNSIGNED NULL,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_tl_technician (technician_id),
  SPATIAL INDEX spx_location (location),
  KEY idx_tl_online_updated (is_online, updated_at),
  KEY idx_tl_updated (updated_at),
  
  CONSTRAINT fk_tl_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_tl_battery CHECK (battery_level IS NULL OR battery_level BETWEEN 0 AND 100),
  CONSTRAINT chk_tl_heading CHECK (heading IS NULL OR heading BETWEEN 0.0 AND 359.9),
  CONSTRAINT chk_tl_speed CHECK (speed IS NULL OR speed >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Service areas for technicians
CREATE TABLE technician_service_areas (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  technician_id BIGINT UNSIGNED NOT NULL,
  area_name     VARCHAR(100) NOT NULL,
  area_polygon  POLYGON NOT NULL SRID 4326,
  max_distance  DECIMAL(5,1) NULL, -- km from center point
  travel_fee    DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  KEY idx_tsa_tech_active (technician_id, is_active),
  SPATIAL INDEX spx_area_polygon (area_polygon),
  
  CONSTRAINT fk_tsa_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- CUSTOMER ADDRESSES & FAVORITES
-- =====================================================================

CREATE TABLE customer_addresses (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  customer_id   BIGINT UNSIGNED NOT NULL,
  label         VARCHAR(100) NOT NULL,
  address       VARCHAR(500) NOT NULL,
  location      POINT NULL SRID 4326,
  lat           DECIMAL(10,7) AS (IFNULL(ST_Y(location), NULL)) STORED,
  lng           DECIMAL(10,7) AS (IFNULL(ST_X(location), NULL)) STORED,
  postal_code   VARCHAR(20) NULL,
  district      VARCHAR(100) NULL,
  province      VARCHAR(100) NULL,
  country       VARCHAR(100) NOT NULL DEFAULT 'Thailand',
  is_default    TINYINT(1) NOT NULL DEFAULT 0,
  access_notes  TEXT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  -- indexes
  KEY idx_addr_customer_default (customer_id, is_default),
  SPATIAL INDEX spx_addr_location (location),
  KEY idx_addr_postal (postal_code),
  KEY idx_addr_district (district, province),
  UNIQUE KEY uniq_addr_label (customer_id, label),

  CONSTRAINT fk_addr_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE favorites (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  customer_id   BIGINT UNSIGNED NOT NULL,
  technician_id BIGINT UNSIGNED NOT NULL,
  notes         VARCHAR(255) NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY uniq_fav (customer_id, technician_id),
  KEY idx_fav_tech (technician_id),
  KEY idx_fav_created (created_at),
  
  CONSTRAINT fk_fav_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_fav_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- JOB REQUESTS & QUOTES
-- =====================================================================

CREATE TABLE job_requests (
  id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  customer_id       BIGINT UNSIGNED NOT NULL,
  category_id       BIGINT UNSIGNED NOT NULL,
  title             VARCHAR(190) NOT NULL,
  description       TEXT NULL,
  budget_min        DECIMAL(10,2) NULL,
  budget_max        DECIMAL(10,2) NULL,
  is_urgent         TINYINT(1) NOT NULL DEFAULT 0,
  service_address   VARCHAR(500) NULL,
  service_point     POINT NULL SRID 4326,
  service_lat       DECIMAL(10,7) AS (IFNULL(ST_Y(service_point), NULL)) STORED,
  service_lng       DECIMAL(10,7) AS (IFNULL(ST_X(service_point), NULL)) STORED,
  preferred_start   DATETIME NULL,
  preferred_end     DATETIME NULL,
  flexible_timing   TINYINT(1) NOT NULL DEFAULT 0,
  requires_materials TINYINT(1) NOT NULL DEFAULT 0,
  access_instructions TEXT NULL,
  contact_preference ENUM('phone','chat','both') NOT NULL DEFAULT 'both',
  expires_at        DATETIME NULL,
  status            ENUM('open','matched','cancelled','expired') NOT NULL DEFAULT 'open',
  matched_at        DATETIME NULL,
  view_count        INT UNSIGNED NOT NULL DEFAULT 0,
  quote_count       INT UNSIGNED NOT NULL DEFAULT 0,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  KEY idx_jr_status_category (status, category_id, is_urgent),
  KEY idx_jr_customer_status (customer_id, status),
  KEY idx_jr_timing (preferred_start, preferred_end),
  KEY idx_jr_budget (budget_min, budget_max),
  KEY idx_jr_created (created_at DESC),
  KEY idx_jr_expires (expires_at),
  SPATIAL INDEX spx_request_point (service_point),
  
  -- Full-text search
  FULLTEXT KEY ft_jr_search (title, description),
  
  CONSTRAINT fk_jr_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_jr_category FOREIGN KEY (category_id) REFERENCES service_categories(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_jr_budget CHECK (budget_min IS NULL OR budget_max IS NULL OR budget_min <= budget_max),
  CONSTRAINT chk_jr_timing CHECK (preferred_start IS NULL OR preferred_end IS NULL OR preferred_start <= preferred_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE request_media (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_request_id BIGINT UNSIGNED NOT NULL,
  file_url       VARCHAR(500) NOT NULL,
  file_type      VARCHAR(50) NOT NULL,
  file_size      INT UNSIGNED NULL, -- in bytes
  file_name      VARCHAR(255) NULL,
  mime_type      VARCHAR(100) NULL,
  is_primary     TINYINT(1) NOT NULL DEFAULT 0,
  sort_order     TINYINT UNSIGNED NOT NULL DEFAULT 0,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  KEY idx_rm_request_primary (job_request_id, is_primary, sort_order),
  
  CONSTRAINT fk_rm_request FOREIGN KEY (job_request_id) REFERENCES job_requests(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Enhanced quotes table
CREATE TABLE quotes (
  id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_request_id    BIGINT UNSIGNED NOT NULL,
  technician_id     BIGINT UNSIGNED NOT NULL,
  message           TEXT NULL,
  price_quote       DECIMAL(10,2) NOT NULL,
  travel_fee        DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  materials_cost    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  estimated_duration INT UNSIGNED NULL, -- in minutes
  warranty_period   INT UNSIGNED NULL, -- in days
  valid_until       DATETIME NULL,
  terms_conditions  TEXT NULL,
  status            ENUM('sent','viewed','accepted','rejected','withdrawn','expired') NOT NULL DEFAULT 'sent',
  viewed_at         DATETIME NULL,
  responded_at      DATETIME NULL,
  response_time     INT UNSIGNED NULL, -- minutes from request to quote
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_quote (job_request_id, technician_id),
  KEY idx_quote_tech_status (technician_id, status),
  KEY idx_quote_request_status (job_request_id, status, price_quote),
  KEY idx_quote_valid_until (valid_until),
  KEY idx_quote_response_time (response_time),
  
  CONSTRAINT fk_quote_request FOREIGN KEY (job_request_id) REFERENCES job_requests(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_quote_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_quote_pricing CHECK (price_quote >= 0 AND travel_fee >= 0 AND materials_cost >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- JOB ORDERS & ORDER MANAGEMENT
-- =====================================================================

CREATE TABLE job_orders (
  id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_request_id    BIGINT UNSIGNED NOT NULL,
  customer_id       BIGINT UNSIGNED NOT NULL,
  technician_id     BIGINT UNSIGNED NOT NULL,
  quote_id          BIGINT UNSIGNED NULL,
  order_number      VARCHAR(50) UNIQUE NOT NULL,
  status            ENUM('pending','accepted','confirmed','in_progress','paused','completed','cancelled','disputed') NOT NULL DEFAULT 'pending',
  priority          ENUM('low','normal','high','urgent') NOT NULL DEFAULT 'normal',
  scheduled_start   DATETIME NULL,
  scheduled_end     DATETIME NULL,
  actual_start      DATETIME NULL,
  actual_end        DATETIME NULL,
  arrived_at        DATETIME NULL,
  confirmed_at      DATETIME NULL,
  agreed_price      DECIMAL(10,2) NULL,
  final_amount      DECIMAL(10,2) NULL,
  discount_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  tax_amount        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total_amount      DECIMAL(10,2) AS (COALESCE(final_amount, agreed_price, 0) - discount_amount + tax_amount) STORED,
  currency          VARCHAR(3) NOT NULL DEFAULT 'THB',
  payment_method    ENUM('cash','card','transfer','wallet','credit') NULL,
  is_emergency      TINYINT(1) NOT NULL DEFAULT 0,
  requires_followup TINYINT(1) NOT NULL DEFAULT 0,
  followup_date     DATE NULL,
  completion_notes  TEXT NULL,
  cancel_reason     VARCHAR(500) NULL,
  cancelled_by      ENUM('customer','technician','system','admin') NULL,
  internal_notes    TEXT NULL, -- admin notes
  customer_rating   TINYINT UNSIGNED NULL,
  technician_rating TINYINT UNSIGNED NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_order_number (order_number),
  KEY idx_order_tech_status (technician_id, status, scheduled_start),
  KEY idx_order_customer_status (customer_id, status, created_at),
  KEY idx_order_status_priority (status, priority, created_at),
  KEY idx_order_scheduled (scheduled_start, scheduled_end),
  KEY idx_order_followup (requires_followup, followup_date),
  KEY idx_order_emergency (is_emergency, status),
  KEY idx_order_amount (total_amount),
  
  CONSTRAINT fk_order_request FOREIGN KEY (job_request_id) REFERENCES job_requests(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_order_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_order_quote FOREIGN KEY (quote_id) REFERENCES quotes(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT chk_order_ratings CHECK (
    (customer_rating IS NULL OR customer_rating BETWEEN 1 AND 5) AND
    (technician_rating IS NULL OR technician_rating BETWEEN 1 AND 5)
  ),
  CONSTRAINT chk_order_timing CHECK (
    scheduled_start IS NULL OR scheduled_end IS NULL OR scheduled_start <= scheduled_end
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE order_media (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id  BIGINT UNSIGNED NOT NULL,
  uploaded_by   ENUM('customer','technician') NOT NULL,
  media_type    ENUM('before','progress','after','signature','other') NOT NULL,
  file_url      VARCHAR(500) NOT NULL,
  file_type     VARCHAR(50) NOT NULL,
  file_size     INT UNSIGNED NULL,
  description   VARCHAR(255) NULL,
  is_public     TINYINT(1) NOT NULL DEFAULT 0,
  sort_order    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  KEY idx_om_order_type (job_order_id, media_type, sort_order),
  KEY idx_om_public (is_public, media_type),
  
  CONSTRAINT fk_om_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Enhanced line items with better categorization
CREATE TABLE order_line_items (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id  BIGINT UNSIGNED NOT NULL,
  item_type     ENUM('labor','material','travel','equipment','discount','tax','surcharge') NOT NULL,
  category      VARCHAR(100) NULL, -- subcategory for better organization
  description   VARCHAR(255) NOT NULL,
  qty           DECIMAL(10,2) NOT NULL DEFAULT 1.00,
  unit_price    DECIMAL(10,2) NOT NULL,
  amount        DECIMAL(10,2) AS (ROUND(qty * unit_price, 2)) STORED,
  unit          VARCHAR(20) NULL, -- hour, piece, meter, etc.
  is_taxable    TINYINT(1) NOT NULL DEFAULT 1,
  tax_rate      DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  sort_order    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  KEY idx_oli_order_type (job_order_id, item_type, sort_order),
  KEY idx_oli_amount (amount DESC),
  
  CONSTRAINT fk_oli_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_oli_qty CHECK (qty > 0),
  CONSTRAINT chk_oli_tax_rate CHECK (tax_rate >= 0 AND tax_rate <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Order status history for audit trail
CREATE TABLE order_status_history (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id BIGINT UNSIGNED NOT NULL,
  old_status   VARCHAR(50) NULL,
  new_status   VARCHAR(50) NOT NULL,
  changed_by   BIGINT UNSIGNED NULL,
  reason       VARCHAR(500) NULL,
  metadata     JSON NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  KEY idx_osh_order_created (job_order_id, created_at),
  KEY idx_osh_status (new_status, created_at),
  
  CONSTRAINT fk_osh_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_osh_changed_by FOREIGN KEY (changed_by) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- REVIEWS & RATINGS SYSTEM
-- =====================================================================

CREATE TABLE reviews (
  id               BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id     BIGINT UNSIGNED NOT NULL,
  customer_id      BIGINT UNSIGNED NOT NULL,
  technician_id    BIGINT UNSIGNED NOT NULL,
  overall_rating   TINYINT UNSIGNED NOT NULL,
  quality_rating   TINYINT UNSIGNED NULL,
  timeliness_rating TINYINT UNSIGNED NULL,
  communication_rating TINYINT UNSIGNED NULL,
  professionalism_rating TINYINT UNSIGNED NULL,
  value_rating     TINYINT UNSIGNED NULL,
  comment          TEXT NULL,
  pros             JSON NULL, -- array of positive aspects
  cons             JSON NULL, -- array of negative aspects
  would_recommend  TINYINT(1) NULL,
  is_verified      TINYINT(1) NOT NULL DEFAULT 1,
  is_featured      TINYINT(1) NOT NULL DEFAULT 0,
  is_public        TINYINT(1) NOT NULL DEFAULT 1,
  helpful_count    INT UNSIGNED NOT NULL DEFAULT 0,
  response_from_tech TEXT NULL, -- technician's response
  responded_at     DATETIME NULL,
  moderated_at     DATETIME NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_review_order (job_order_id),
  KEY idx_review_tech_rating (technician_id, overall_rating DESC, created_at DESC),
  KEY idx_review_customer (customer_id, created_at DESC),
  KEY idx_review_featured (is_featured, overall_rating DESC),
  KEY idx_review_public_verified (is_public, is_verified, overall_rating DESC),
  
  -- Full-text search
  FULLTEXT KEY ft_review_content (comment, response_from_tech),
  
  CONSTRAINT fk_review_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_review_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_review_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_review_ratings CHECK (
    overall_rating BETWEEN 1 AND 5 AND
    (quality_rating IS NULL OR quality_rating BETWEEN 1 AND 5) AND
    (timeliness_rating IS NULL OR timeliness_rating BETWEEN 1 AND 5) AND
    (communication_rating IS NULL OR communication_rating BETWEEN 1 AND 5) AND
    (professionalism_rating IS NULL OR professionalism_rating BETWEEN 1 AND 5) AND
    (value_rating IS NULL OR value_rating BETWEEN 1 AND 5)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Review helpfulness votes
CREATE TABLE review_votes (
  id        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  review_id BIGINT UNSIGNED NOT NULL,
  user_id   BIGINT UNSIGNED NOT NULL,
  is_helpful TINYINT(1) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY uniq_review_vote (review_id, user_id),
  KEY idx_rv_helpful (is_helpful, created_at),
  
  CONSTRAINT fk_rv_review FOREIGN KEY (review_id) REFERENCES reviews(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_rv_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- PAYMENT & FINANCIAL SYSTEM
-- =====================================================================

CREATE TABLE payments (
  id               BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id     BIGINT UNSIGNED NOT NULL,
  payment_number   VARCHAR(50) UNIQUE NOT NULL,
  provider         ENUM('stripe','omise','promptpay','truemoney','cash','bank_transfer','credit') NOT NULL,
  provider_id      VARCHAR(190) NULL, -- provider's payment ID
  intent_id        VARCHAR(190) NULL, -- payment intent/session ID
  method_details   JSON NULL, -- card details, bank info, etc.
  status           ENUM('pending','authorized','captured','partially_refunded','refunded','failed','cancelled') NOT NULL DEFAULT 'pending',
  amount           DECIMAL(10,2) NOT NULL,
  fee              DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  net_amount       DECIMAL(10,2) AS (amount - fee) STORED,
  currency         VARCHAR(3) NOT NULL DEFAULT 'THB',
  exchange_rate    DECIMAL(10,4) NULL,
  reference_number VARCHAR(100) NULL,
  receipt_url      VARCHAR(500) NULL,
  failure_reason   VARCHAR(500) NULL,
  refund_reason    VARCHAR(500) NULL,
  authorized_at    DATETIME NULL,
  captured_at      DATETIME NULL,
  failed_at        DATETIME NULL,
  expires_at       DATETIME NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_payment_number (payment_number),
  KEY idx_payment_order (job_order_id, status),
  KEY idx_payment_provider (provider, status),
  KEY idx_payment_status_amount (status, amount DESC),
  KEY idx_payment_captured (captured_at),
  KEY idx_payment_reference (reference_number),
  
  CONSTRAINT fk_payment_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_payment_amount CHECK (amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Payment installments for large orders
CREATE TABLE payment_installments (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  payment_id    BIGINT UNSIGNED NOT NULL,
  installment_number TINYINT UNSIGNED NOT NULL,
  amount        DECIMAL(10,2) NOT NULL,
  due_date      DATE NOT NULL,
  paid_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  status        ENUM('pending','paid','overdue','waived') NOT NULL DEFAULT 'pending',
  paid_at       DATETIME NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY uniq_installment (payment_id, installment_number),
  KEY idx_installment_due (due_date, status),
  KEY idx_installment_status (status, due_date),
  
  CONSTRAINT fk_pi_payment FOREIGN KEY (payment_id) REFERENCES payments(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Enhanced payouts with better tracking
CREATE TABLE payouts (
  id               BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  payment_id       BIGINT UNSIGNED NOT NULL,
  technician_id    BIGINT UNSIGNED NOT NULL,
  payout_number    VARCHAR(50) UNIQUE NOT NULL,
  amount           DECIMAL(10,2) NOT NULL,
  commission_rate  DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  commission_amount DECIMAL(10,2) AS (ROUND(amount * commission_rate / 100, 2)) STORED,
  net_amount       DECIMAL(10,2) AS (amount - (amount * commission_rate / 100)) STORED,
  tax_amount       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  processing_fee   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  bank_account     JSON NULL, -- encrypted bank details
  status           ENUM('pending','processing','paid','failed','returned','cancelled') NOT NULL DEFAULT 'pending',
  processed_at     DATETIME NULL,
  paid_at          DATETIME NULL,
  failure_reason   VARCHAR(500) NULL,
  reference_number VARCHAR(100) NULL,
  receipt_url      VARCHAR(500) NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_payout_number (payout_number),
  UNIQUE KEY uniq_payout_payment_tech (payment_id, technician_id),
  KEY idx_payout_tech_status (technician_id, status, created_at DESC),
  KEY idx_payout_status_amount (status, amount DESC),
  KEY idx_payout_processed (processed_at),
  KEY idx_payout_reference (reference_number),
  
  CONSTRAINT fk_payout_payment FOREIGN KEY (payment_id) REFERENCES payments(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_payout_technician FOREIGN KEY (technician_id) REFERENCES technician_profiles(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_payout_commission CHECK (commission_rate >= 0 AND commission_rate <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- DISPUTES & RESOLUTION SYSTEM
-- =====================================================================

CREATE TABLE disputes (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id       BIGINT UNSIGNED NOT NULL,
  dispute_number     VARCHAR(50) UNIQUE NOT NULL,
  raised_by_user_id  BIGINT UNSIGNED NOT NULL,
  dispute_type       ENUM('quality','payment','no_show','damage','other') NOT NULL,
  priority           ENUM('low','medium','high','critical') NOT NULL DEFAULT 'medium',
  subject            VARCHAR(255) NOT NULL,
  description        TEXT NOT NULL,
  requested_resolution ENUM('refund','discount','redo','compensation','other') NULL,
  requested_amount   DECIMAL(10,2) NULL,
  evidence_urls      JSON NULL, -- supporting documents/images
  status             ENUM('open','investigating','mediation','resolved','rejected','escalated') NOT NULL DEFAULT 'open',
  assigned_to        BIGINT UNSIGNED NULL, -- admin handling the dispute
  resolution_summary TEXT NULL,
  resolution_amount  DECIMAL(10,2) NULL,
  customer_satisfied TINYINT(1) NULL,
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  resolved_at        DATETIME NULL,
  
  -- Indexes
  UNIQUE KEY uniq_dispute_number (dispute_number),
  KEY idx_dispute_order (job_order_id, status),
  KEY idx_dispute_raised_by (raised_by_user_id, created_at DESC),
  KEY idx_dispute_status_priority (status, priority, created_at),
  KEY idx_dispute_assigned (assigned_to, status),
  KEY idx_dispute_type (dispute_type, status),
  
  CONSTRAINT fk_dispute_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_dispute_raised_by FOREIGN KEY (raised_by_user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_dispute_assigned_to FOREIGN KEY (assigned_to) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dispute messages/communication log
CREATE TABLE dispute_messages (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  dispute_id  BIGINT UNSIGNED NOT NULL,
  sender_id   BIGINT UNSIGNED NOT NULL,
  message     TEXT NOT NULL,
  attachments JSON NULL,
  is_internal TINYINT(1) NOT NULL DEFAULT 0, -- internal admin notes
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  KEY idx_dm_dispute_created (dispute_id, created_at),
  KEY idx_dm_sender (sender_id, created_at),
  KEY idx_dm_internal (is_internal, created_at),
  
  CONSTRAINT fk_dm_dispute FOREIGN KEY (dispute_id) REFERENCES disputes(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_dm_sender FOREIGN KEY (sender_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- COUPONS & PROMOTIONS
-- =====================================================================

CREATE TABLE coupons (
  id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  code            VARCHAR(50) UNIQUE NOT NULL,
  name            VARCHAR(190) NOT NULL,
  description     TEXT NULL,
  discount_type   ENUM('amount','percentage','free_shipping') NOT NULL,
  discount_value  DECIMAL(10,2) NOT NULL,
  min_order_amount DECIMAL(10,2) NULL,
  max_discount    DECIMAL(10,2) NULL,
  usage_limit     INT UNSIGNED NULL,
  usage_count     INT UNSIGNED NOT NULL DEFAULT 0,
  user_usage_limit TINYINT UNSIGNED NULL, -- per user limit
  applicable_categories JSON NULL, -- array of category IDs
  excluded_categories JSON NULL,
  customer_segments JSON NULL, -- new, returning, premium, etc.
  valid_from      DATETIME NULL,
  valid_to        DATETIME NULL,
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  is_public       TINYINT(1) NOT NULL DEFAULT 1,
  created_by      BIGINT UNSIGNED NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Indexes
  UNIQUE KEY uniq_coupon_code (code),
  KEY idx_coupon_active_dates (is_active, valid_from, valid_to),
  KEY idx_coupon_public (is_public, is_active),
  KEY idx_coupon_usage (usage_count, usage_limit),
  KEY idx_coupon_created_by (created_by),
  
  CONSTRAINT fk_coupon_created_by FOREIGN KEY (created_by) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT chk_coupon_dates CHECK (valid_from IS NULL OR valid_to IS NULL OR valid_from <= valid_to),
  CONSTRAINT chk_coupon_discount CHECK (discount_value > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE coupon_usages (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  coupon_id    BIGINT UNSIGNED NOT NULL,
  user_id      BIGINT UNSIGNED NOT NULL,
  job_order_id BIGINT UNSIGNED NULL,
  discount_applied DECIMAL(10,2) NOT NULL,
  used_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  KEY idx_cu_coupon_user (coupon_id, user_id),
  KEY idx_cu_user_used (user_id, used_at DESC),
  KEY idx_cu_order (job_order_id),
  
  CONSTRAINT fk_cu_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_cu_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_cu_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- COMMUNICATION & NOTIFICATIONS
-- =====================================================================

CREATE TABLE notifications (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id      BIGINT UNSIGNED NOT NULL,
  type         VARCHAR(100) NOT NULL,
  category     ENUM('order','payment','system','marketing','security','review') NOT NULL,
  title        VARCHAR(255) NOT NULL,
  message      TEXT NOT NULL,
  action_url   VARCHAR(500) NULL,
  payload_json JSON NULL,
  priority     ENUM('low','normal','high','urgent') NOT NULL DEFAULT 'normal',
  channels     JSON NOT NULL, -- push, email, sms
  is_read      TINYINT(1) NOT NULL DEFAULT 0,
  read_at      DATETIME NULL,
  expires_at   DATETIME NULL,
  sent_via     JSON NULL, -- tracking which channels were used
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  -- Indexes
  KEY idx_notif_user_unread (user_id, is_read, created_at DESC),
  KEY idx_notif_type_category (type, category, created_at DESC),
  KEY idx_notif_priority (priority, created_at DESC),
  KEY idx_notif_expires (expires_at),
  
  CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notification preferences
CREATE TABLE notification_preferences (
  id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id    BIGINT UNSIGNED NOT NULL,
  category   VARCHAR(100) NOT NULL,
  push_enabled TINYINT(1) NOT NULL DEFAULT 1,
  email_enabled TINYINT(1) NOT NULL DEFAULT 1,
  sms_enabled TINYINT(1) NOT NULL DEFAULT 0,
  frequency  ENUM('instant','daily','weekly','never') NOT NULL DEFAULT 'instant',
  quiet_hours JSON NULL, -- start and end time for quiet hours
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY uniq_user_category (user_id, category),
  
  CONSTRAINT fk_np_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Enhanced chat system
CREATE TABLE chats (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_order_id  BIGINT UNSIGNED NULL,
  chat_type     ENUM('order','support','general') NOT NULL DEFAULT 'order',
  participants  JSON NOT NULL, -- user IDs array
  status        ENUM('active','archived','blocked') NOT NULL DEFAULT 'active',
  last_message_at TIMESTAMP NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  KEY idx_chat_order (job_order_id),
  KEY idx_chat_type_status (chat_type, status),
  KEY idx_chat_last_message (last_message_at DESC),
  
  CONSTRAINT fk_chat_order FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE chat_messages (
  id               BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  chat_id          BIGINT UNSIGNED NOT NULL,
  sender_user_id   BIGINT UNSIGNED NOT NULL,
  message_type     ENUM('text','image','video','audio','file','location','system') NOT NULL DEFAULT 'text',
  message          TEXT NULL,
  attachments      JSON NULL, -- file URLs and metadata
  location_data    JSON NULL, -- lat, lng, address
  is_system        TINYINT(1) NOT NULL DEFAULT 0,
  reply_to_id      BIGINT UNSIGNED NULL,
  is_edited        TINYINT(1) NOT NULL DEFAULT 0,
  edited_at        DATETIME NULL,
  is_deleted       TINYINT(1) NOT NULL DEFAULT 0,
  deleted_at       DATETIME NULL,
  read_by          JSON NULL, -- user_id => timestamp mapping
  delivered_at     DATETIME NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  -- Indexes
  KEY idx_cm_chat_created (chat_id, created_at DESC),
  KEY idx_cm_sender (sender_user_id, created_at DESC),
  KEY idx_cm_reply_to (reply_to_id),
  KEY idx_cm_type (message_type, created_at DESC),
  
  -- Full-text search
  FULLTEXT KEY ft_cm_message (message),
  
  CONSTRAINT fk_cm_chat FOREIGN KEY (chat_id) REFERENCES chats(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_cm_sender FOREIGN KEY (sender_user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cm_reply_to FOREIGN KEY (reply_to_id) REFERENCES chat_messages(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- SESSION & SECURITY
-- =====================================================================

CREATE TABLE sessions (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NOT NULL,
  session_token VARCHAR(255) UNIQUE NOT NULL,
  device_info   JSON NULL, -- device type, OS, browser, etc.
  ip_address    VARCHAR(45) NULL,
  location_info JSON NULL, -- country, city from IP
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  last_activity TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  expires_at    DATETIME NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revoked_at    DATETIME NULL,
  
  -- Indexes
  UNIQUE KEY uniq_session_token (session_token),
  KEY idx_session_user_active (user_id, is_active, last_activity DESC),
  KEY idx_session_expires (expires_at),
  KEY idx_session_ip (ip_address, created_at DESC),
  
  CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Security log for tracking suspicious activities
CREATE TABLE security_logs (
  id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id    BIGINT UNSIGNED NULL,
  event_type ENUM('login','logout','failed_login','password_change','suspicious_activity','account_locked') NOT NULL,
  ip_address VARCHAR(45) NULL,
  user_agent TEXT NULL,
  metadata   JSON NULL,
  risk_score TINYINT UNSIGNED NULL, -- 0-100
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  KEY idx_sl_user_event (user_id, event_type, created_at DESC),
  KEY idx_sl_ip_event (ip_address, event_type, created_at DESC),
  KEY idx_sl_risk_score (risk_score DESC, created_at DESC),
  KEY idx_sl_created (created_at DESC),
  
  CONSTRAINT fk_sl_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- AUDIT & LOGGING SYSTEM
-- =====================================================================

CREATE TABLE audit_logs (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  actor_user_id  BIGINT UNSIGNED NULL,
  action         VARCHAR(100) NOT NULL,
  target_type    VARCHAR(50) NOT NULL,
  target_id      BIGINT UNSIGNED NULL,
  old_values     JSON NULL,
  new_values     JSON NULL,
  ip_address     VARCHAR(45) NULL,
  user_agent     VARCHAR(500) NULL,
  request_id     VARCHAR(100) NULL, -- for request tracing
  metadata       JSON NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  -- Indexes
  KEY idx_audit_actor_created (actor_user_id, created_at DESC),
  KEY idx_audit_target (target_type, target_id, created_at DESC),
  KEY idx_audit_action (action, created_at DESC),
  KEY idx_audit_request (request_id),
  KEY idx_audit_created (created_at DESC),
  
  -- Partitioning by month for performance
  PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
    PARTITION p202501 VALUES LESS THAN (UNIX_TIMESTAMP('2025-02-01')),
    PARTITION p202502 VALUES LESS THAN (UNIX_TIMESTAMP('2025-03-01')),
    PARTITION p202503 VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01')),
    PARTITION p_future VALUES LESS THAN MAXVALUE
  ),
  
  CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- ANALYTICS & REPORTING TABLES
-- =====================================================================

-- Daily metrics summary for better reporting performance
CREATE TABLE daily_metrics (
  id                    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  metric_date          DATE NOT NULL,
  total_users          INT UNSIGNED NOT NULL DEFAULT 0,
  new_customers        INT UNSIGNED NOT NULL DEFAULT 0,
  new_technicians      INT UNSIGNED NOT NULL DEFAULT 0,
  active_customers     INT UNSIGNED NOT NULL DEFAULT 0,
  active_technicians   INT UNSIGNED NOT NULL DEFAULT 0,
  total_requests       INT UNSIGNED NOT NULL DEFAULT 0,
  total_orders         INT UNSIGNED NOT NULL DEFAULT 0,
  completed_orders     INT UNSIGNED NOT NULL DEFAULT 0,
  cancelled_orders     INT UNSIGNED NOT NULL DEFAULT 0,
  total_revenue        DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_commission     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  avg_order_value      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  avg_completion_time  INT UNSIGNED NULL, -- in minutes
  customer_satisfaction DECIMAL(3,2) NULL,
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY uniq_metric_date (metric_date),
  KEY idx_dm_date_desc (metric_date DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- OPTIMIZED TRIGGERS FOR DATA CONSISTENCY
-- =====================================================================

DELIMITER $

-- Update technician ratings after review insert/update/delete
CREATE TRIGGER trg_reviews_after_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
  UPDATE technician_profiles tp
  SET 
    tp.rating_count = tp.rating_count + 1,
    tp.rating_avg = (
      SELECT ROUND(AVG(r.overall_rating), 2)
      FROM reviews r WHERE r.technician_id = NEW.technician_id
    )
  WHERE tp.id = NEW.technician_id;
END$$

CREATE TRIGGER trg_reviews_after_update
AFTER UPDATE ON reviews
FOR EACH ROW
BEGIN
  IF (OLD.overall_rating <> NEW.overall_rating) THEN
    UPDATE technician_profiles tp
    SET tp.rating_avg = (
      SELECT ROUND(AVG(r.overall_rating), 2)
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
  SET 
    tp.rating_count = GREATEST(tp.rating_count - 1, 0),
    tp.rating_avg = COALESCE((
      SELECT ROUND(AVG(r.overall_rating), 2)
      FROM reviews r WHERE r.technician_id = OLD.technician_id
    ), 0.00)
  WHERE tp.id = OLD.technician_id;
END$

-- Update quote count when quotes are added/removed
CREATE TRIGGER trg_quotes_after_insert
AFTER INSERT ON quotes
FOR EACH ROW
BEGIN
  UPDATE job_requests jr
  SET jr.quote_count = jr.quote_count + 1
  WHERE jr.id = NEW.job_request_id;
END$

CREATE TRIGGER trg_quotes_after_delete
AFTER DELETE ON quotes
FOR EACH ROW
BEGIN
  UPDATE job_requests jr
  SET jr.quote_count = GREATEST(jr.quote_count - 1, 0)
  WHERE jr.id = OLD.job_request_id;
END$

-- Update technician completion rate and job count
CREATE TRIGGER trg_orders_completion_update
AFTER UPDATE ON job_orders
FOR EACH ROW
BEGIN
  IF (OLD.status <> NEW.status AND NEW.status IN ('completed','cancelled')) THEN
    UPDATE technician_profiles tp
    JOIN (
      SELECT 
        SUM(CASE WHEN status='completed' THEN 1 ELSE 0 END) AS completed_cnt,
        SUM(CASE WHEN status IN ('completed','cancelled') THEN 1 ELSE 0 END) AS total_cnt
      FROM job_orders
      WHERE technician_id = NEW.technician_id
    ) agg
    SET 
      tp.total_jobs = agg.total_cnt,
      tp.completion_rate = CASE 
        WHEN agg.total_cnt = 0 THEN 0.00
        ELSE ROUND(agg.completed_cnt * 100.0 / agg.total_cnt, 2)
      END
    WHERE tp.id = NEW.technician_id;
  END IF;
END$$

-- Auto-generate order numbers
CREATE TRIGGER trg_orders_before_insert
BEFORE INSERT ON job_orders
FOR EACH ROW
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    SET NEW.order_number = CONCAT('ORD-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(NEW.id, 6, '0'));
  END IF;
END$

-- Auto-generate payment numbers
CREATE TRIGGER trg_payments_before_insert
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
  IF NEW.payment_number IS NULL OR NEW.payment_number = '' THEN
    SET NEW.payment_number = CONCAT('PAY-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(NEW.id, 6, '0'));
  END IF;
END$

-- Auto-generate payout numbers
CREATE TRIGGER trg_payouts_before_insert
BEFORE INSERT ON payouts
FOR EACH ROW
BEGIN
  IF NEW.payout_number IS NULL OR NEW.payout_number = '' THEN
    SET NEW.payout_number = CONCAT('POUT-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(NEW.id, 6, '0'));
  END IF;
END$

-- Auto-generate dispute numbers
CREATE TRIGGER trg_disputes_before_insert
BEFORE INSERT ON disputes
FOR EACH ROW
BEGIN
  IF NEW.dispute_number IS NULL OR NEW.dispute_number = '' THEN
    SET NEW.dispute_number = CONCAT('DISP-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(NEW.id, 6, '0'));
  END IF;
END$

-- Update coupon usage count
CREATE TRIGGER trg_coupon_usage_after_insert
AFTER INSERT ON coupon_usages
FOR EACH ROW
BEGIN
  UPDATE coupons c
  SET c.usage_count = c.usage_count + 1
  WHERE c.id = NEW.coupon_id;
END$

-- Update chat last message timestamp
CREATE TRIGGER trg_chat_messages_after_insert
AFTER INSERT ON chat_messages
FOR EACH ROW
BEGIN
  UPDATE chats c
  SET c.last_message_at = NEW.created_at
  WHERE c.id = NEW.chat_id;
END$

-- Update review helpful count
CREATE TRIGGER trg_review_votes_after_insert
AFTER INSERT ON review_votes
FOR EACH ROW
BEGIN
  UPDATE reviews r
  SET r.helpful_count = (
    SELECT COUNT(*) 
    FROM review_votes rv 
    WHERE rv.review_id = NEW.review_id AND rv.is_helpful = 1
  )
  WHERE r.id = NEW.review_id;
END$

CREATE TRIGGER trg_review_votes_after_update
AFTER UPDATE ON review_votes
FOR EACH ROW
BEGIN
  UPDATE reviews r
  SET r.helpful_count = (
    SELECT COUNT(*) 
    FROM review_votes rv 
    WHERE rv.review_id = NEW.review_id AND rv.is_helpful = 1
  )
  WHERE r.id = NEW.review_id;
END$

CREATE TRIGGER trg_review_votes_after_delete
AFTER DELETE ON review_votes
FOR EACH ROW
BEGIN
  UPDATE reviews r
  SET r.helpful_count = (
    SELECT COUNT(*) 
    FROM review_votes rv 
    WHERE rv.review_id = OLD.review_id AND rv.is_helpful = 1
  )
  WHERE r.id = OLD.review_id;
END$

DELIMITER ;

-- =====================================================================
-- STORED PROCEDURES FOR COMMON OPERATIONS
-- =====================================================================

DELIMITER $

-- Find nearby technicians for a service request
CREATE PROCEDURE sp_find_nearby_technicians(
  IN p_category_id BIGINT UNSIGNED,
  IN p_lat DECIMAL(10,7),
  IN p_lng DECIMAL(10,7),
  IN p_radius_km INT UNSIGNED DEFAULT 20,
  IN p_limit INT UNSIGNED DEFAULT 50
)
BEGIN
  SELECT 
    tp.id,
    tp.user_id,
    tp.display_name,
    tp.rating_avg,
    tp.rating_count,
    tp.completion_rate,
    tl.lat,
    tl.lng,
    ST_Distance_Sphere(
      POINT(p_lng, p_lat),
      tl.location
    ) / 1000 AS distance_km,
    ts.base_rate,
    ts.rate_unit,
    u.status as user_status
  FROM technician_profiles tp
  JOIN users u ON tp.user_id = u.id
  JOIN technician_locations tl ON tp.id = tl.technician_id
  JOIN technician_services ts ON tp.id = ts.technician_id
  WHERE 
    tp.status = 'verified'
    AND tp.is_available = 1
    AND u.status = 'active'
    AND ts.category_id = p_category_id
    AND ts.is_active = 1
    AND tl.is_online = 1
    AND ST_Distance_Sphere(
      POINT(p_lng, p_lat),
      tl.location
    ) / 1000 <= p_radius_km
  ORDER BY distance_km ASC, tp.rating_avg DESC
  LIMIT p_limit;
END$

-- Update technician availability status
CREATE PROCEDURE sp_update_technician_availability(
  IN p_technician_id BIGINT UNSIGNED,
  IN p_is_available TINYINT(1),
  IN p_is_online TINYINT(1) DEFAULT NULL
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  
  START TRANSACTION;
  
  -- Update technician availability
  UPDATE technician_profiles 
  SET 
    is_available = p_is_available,
    last_seen_at = CURRENT_TIMESTAMP
  WHERE id = p_technician_id;
  
  -- Update online status if provided
  IF p_is_online IS NOT NULL THEN
    UPDATE technician_locations
    SET is_online = p_is_online
    WHERE technician_id = p_technician_id;
  END IF;
  
  COMMIT;
END$

-- Calculate order total with line items
CREATE PROCEDURE sp_calculate_order_total(
  IN p_order_id BIGINT UNSIGNED,
  OUT p_subtotal DECIMAL(10,2),
  OUT p_tax_total DECIMAL(10,2),
  OUT p_discount_total DECIMAL(10,2),
  OUT p_final_total DECIMAL(10,2)
)
BEGIN
  -- Calculate subtotal
  SELECT COALESCE(SUM(amount), 0.00) INTO p_subtotal
  FROM order_line_items 
  WHERE job_order_id = p_order_id 
  AND item_type NOT IN ('tax', 'discount');
  
  -- Calculate tax total
  SELECT COALESCE(SUM(amount), 0.00) INTO p_tax_total
  FROM order_line_items 
  WHERE job_order_id = p_order_id 
  AND item_type = 'tax';
  
  -- Calculate discount total
  SELECT COALESCE(SUM(ABS(amount)), 0.00) INTO p_discount_total
  FROM order_line_items 
  WHERE job_order_id = p_order_id 
  AND item_type = 'discount';
  
  -- Calculate final total
  SET p_final_total = p_subtotal + p_tax_total - p_discount_total;
END$

-- Generate daily metrics
CREATE PROCEDURE sp_generate_daily_metrics(IN p_date DATE)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  
  START TRANSACTION;
  
  -- Delete existing metrics for the date
  DELETE FROM daily_metrics WHERE metric_date = p_date;
  
  -- Insert new metrics
  INSERT INTO daily_metrics (
    metric_date,
    total_users,
    new_customers,
    new_technicians,
    active_customers,
    active_technicians,
    total_requests,
    total_orders,
    completed_orders,
    cancelled_orders,
    total_revenue,
    avg_order_value,
    customer_satisfaction
  )
  SELECT 
    p_date,
    (SELECT COUNT(*) FROM users WHERE DATE(created_at) <= p_date AND status != 'deleted'),
    (SELECT COUNT(*) FROM customer_profiles cp JOIN users u ON cp.user_id = u.id WHERE DATE(cp.created_at) = p_date),
    (SELECT COUNT(*) FROM technician_profiles tp JOIN users u ON tp.user_id = u.id WHERE DATE(tp.created_at) = p_date),
    (SELECT COUNT(DISTINCT customer_id) FROM job_orders WHERE DATE(created_at) = p_date),
    (SELECT COUNT(DISTINCT technician_id) FROM job_orders WHERE DATE(created_at) = p_date),
    (SELECT COUNT(*) FROM job_requests WHERE DATE(created_at) = p_date),
    (SELECT COUNT(*) FROM job_orders WHERE DATE(created_at) = p_date),
    (SELECT COUNT(*) FROM job_orders WHERE DATE(completed_at) = p_date),
    (SELECT COUNT(*) FROM job_orders WHERE DATE(updated_at) = p_date AND status = 'cancelled'),
    (SELECT COALESCE(SUM(total_amount), 0) FROM job_orders WHERE DATE(completed_at) = p_date AND status = 'completed'),
    (SELECT COALESCE(AVG(total_amount), 0) FROM job_orders WHERE DATE(completed_at) = p_date AND status = 'completed'),
    (SELECT COALESCE(AVG(overall_rating), 0) FROM reviews WHERE DATE(created_at) = p_date);
  
  COMMIT;
END$

DELIMITER ;

-- =====================================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================================

-- Active technicians with their current status and ratings
CREATE VIEW vw_active_technicians AS
SELECT 
  tp.id,
  tp.user_id,
  u.email,
  u.phone,
  tp.display_name,
  tp.rating_avg,
  tp.rating_count,
  tp.completion_rate,
  tp.total_jobs,
  tp.is_available,
  tp.last_seen_at,
  tl.lat,
  tl.lng,
  tl.is_online,
  tl.updated_at as location_updated_at,
  COUNT(DISTINCT ts.id) as service_count,
  GROUP_CONCAT(DISTINCT sc.name ORDER BY sc.name SEPARATOR ', ') as service_categories
FROM technician_profiles tp
JOIN users u ON tp.user_id = u.id
LEFT JOIN technician_locations tl ON tp.id = tl.technician_id
LEFT JOIN technician_services ts ON tp.id = ts.technician_id AND ts.is_active = 1
LEFT JOIN service_categories sc ON ts.category_id = sc.id
WHERE tp.status = 'verified' 
  AND u.status = 'active'
GROUP BY tp.id, tp.user_id, u.email, u.phone, tp.display_name, 
         tp.rating_avg, tp.rating_count, tp.completion_rate, tp.total_jobs,
         tp.is_available, tp.last_seen_at, tl.lat, tl.lng, 
         tl.is_online, tl.updated_at;

-- Order summary with customer and technician details
CREATE VIEW vw_order_summary AS
SELECT 
  jo.id,
  jo.order_number,
  jo.status,
  jo.priority,
  jo.scheduled_start,
  jo.scheduled_end,
  jo.total_amount,
  jo.created_at,
  jo.updated_at,
  -- Customer details
  cp.firstname as customer_firstname,
  cp.lastname as customer_lastname,
  cu.email as customer_email,
  cu.phone as customer_phone,
  -- Technician details
  tp.display_name as technician_name,
  tu.email as technician_email,
  tu.phone as technician_phone,
  -- Service details
  jr.title as service_title,
  sc.name as category_name,
  -- Payment status
  p.status as payment_status,
  p.amount as payment_amount
FROM job_orders jo
JOIN customer_profiles cp ON jo.customer_id = cp.id
JOIN users cu ON cp.user_id = cu.id
JOIN technician_profiles tp ON jo.technician_id = tp.id
JOIN users tu ON tp.user_id = tu.id
JOIN job_requests jr ON jo.job_request_id = jr.id
JOIN service_categories sc ON jr.category_id = sc.id
LEFT JOIN payments p ON jo.id = p.job_order_id;

-- Recent reviews with customer and technician info
CREATE VIEW vw_recent_reviews AS
SELECT 
  r.id,
  r.overall_rating,
  r.comment,
  r.would_recommend,
  r.is_public,
  r.created_at,
  -- Customer info
  cp.firstname as customer_firstname,
  cp.lastname as customer_lastname,
  -- Technician info
  tp.display_name as technician_name,
  -- Order info
  jo.order_number,
  jr.title as service_title,
  sc.name as category_name
FROM reviews r
JOIN customer_profiles cp ON r.customer_id = cp.id
JOIN technician_profiles tp ON r.technician_id = tp.id
JOIN job_orders jo ON r.job_order_id = jo.id
JOIN job_requests jr ON jo.job_request_id = jr.id
JOIN service_categories sc ON jr.category_id = sc.id
WHERE r.is_public = 1
ORDER BY r.created_at DESC;

-- =====================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================================

-- Composite indexes for common query patterns
CREATE INDEX idx_orders_tech_status_date ON job_orders (technician_id, status, scheduled_start);
CREATE INDEX idx_orders_customer_status_date ON job_orders (customer_id, status, created_at DESC);
CREATE INDEX idx_requests_category_status_urgent ON job_requests (category_id, status, is_urgent, created_at DESC);
CREATE INDEX idx_payments_status_amount_date ON payments (status, amount DESC, created_at DESC);
CREATE INDEX idx_reviews_tech_rating_public ON reviews (technician_id, overall_rating DESC, is_public, created_at DESC);

-- Performance indexes for location-based queries
CREATE INDEX idx_tech_locations_online_updated ON technician_locations (is_online, updated_at DESC);
CREATE INDEX idx_customer_addresses_default ON customer_addresses (customer_id, is_default, created_at DESC);

-- Indexes for audit and analytics
CREATE INDEX idx_audit_logs_created_action ON audit_logs (created_at DESC, action);
CREATE INDEX idx_notifications_user_priority ON notifications (user_id, priority, created_at DESC);

-- =====================================================================
-- INITIAL DATA SETUP
-- =====================================================================

-- Insert default service categories
INSERT INTO service_categories (name, description, level, sort_order, is_active, is_featured) VALUES
('Electronics & Appliances', 'TV, Computer, AC, Washing Machine repairs', 0, 1, 1, 1),
('Plumbing', 'Pipe repairs, leak fixes, bathroom fittings', 0, 2, 1, 1),
('Electrical', 'Wiring, socket installation, electrical repairs', 0, 3, 1, 1),
('Home Cleaning', 'House cleaning, deep cleaning, sanitization', 0, 4, 1, 1),
('Carpentry', 'Furniture assembly, wood work, door repairs', 0, 5, 1, 0),
('Painting', 'Wall painting, furniture painting, touch-ups', 0, 6, 1, 0),
('Pest Control', 'Termite control, cockroach treatment, fumigation', 0, 7, 1, 0),
('Gardening', 'Lawn care, plant maintenance, landscaping', 0, 8, 1, 0);

-- Insert sub-categories for Electronics & Appliances
INSERT INTO service_categories (name, description, parent_id, level, sort_order, is_active) VALUES
('TV Repair', 'LCD, LED, Smart TV repairs', 1, 1, 1, 1),
('AC Repair', 'Air conditioner service and repairs', 1, 1, 2, 1),
('Washing Machine', 'Washing machine repairs and service', 1, 1, 3, 1),
('Refrigerator', 'Fridge repairs and gas refill', 1, 1, 4, 1),
('Computer Repair', 'Laptop and desktop repairs', 1, 1, 5, 1);

-- Insert default admin user
INSERT INTO users (email, password_hash, role, status)
VALUES ('admin@changsure.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'active');

SET @admin_user_id = LAST_INSERT_ID();

INSERT INTO admin_profiles (user_id, permissions)
VALUES (@admin_user_id, JSON_ARRAY('all'));

-- Insert default notification preferences
INSERT INTO notification_preferences (user_id, category, push_enabled, email_enabled, sms_enabled) VALUES
(@admin_user_id, 'order', 1, 1, 0),
(@admin_user_id, 'payment', 1, 1, 1),
(@admin_user_id, 'system', 1, 1, 0),
(@admin_user_id, 'security', 1, 1, 1);

-- Insert sample coupon
INSERT INTO coupons (code, name, description, discount_type, discount_value, min_order_amount, max_discount, usage_limit, valid_from, valid_to, is_active, is_public) VALUES
('WELCOME20', 'Welcome Discount', '20% off for new customers', 'percentage', 20.00, 500.00, 200.00, 1000, NOW(), DATE_ADD(NOW(), INTERVAL 3 MONTH), 1, 1),
('FIRST100', 'First Service Discount', '100 THB off your first service', 'amount', 100.00, 300.00, 100.00, NULL, NOW(), DATE_ADD(NOW(), INTERVAL 6 MONTH), 1, 1);

-- =====================================================================
-- OPTIMIZATION SETTINGS
-- =====================================================================

-- Table optimization settings
ALTER TABLE customer_profiles
  ADD CONSTRAINT fk_customer_address
  FOREIGN KEY (default_address_id) REFERENCES customer_addresses(id)
  ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE service_categories 
  ADD COLUMN created_by BIGINT UNSIGNED NULL,
  ADD CONSTRAINT fk_sc_created_by FOREIGN KEY (created_by) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE users ENGINE=InnoDB ROW_FORMAT=DYNAMIC;
ALTER TABLE job_orders ENGINE=InnoDB ROW_FORMAT=DYNAMIC;
ALTER TABLE payments ENGINE=InnoDB ROW_FORMAT=DYNAMIC;
ALTER TABLE reviews ENGINE=InnoDB ROW_FORMAT=DYNAMIC;
ALTER TABLE chat_messages ENGINE=InnoDB ROW_FORMAT=DYNAMIC;
ALTER TABLE audit_logs ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

-- Enable query cache for read-heavy tables
-- Note: Query cache is deprecated in MySQL 8.0, consider using Redis instead

-- =====================================================================
-- MAINTENANCE PROCEDURES
-- =====================================================================

DELIMITER $

-- Cleanup old sessions
CREATE PROCEDURE sp_cleanup_expired_sessions()
BEGIN
  DELETE FROM sessions 
  WHERE expires_at < NOW() 
  OR (revoked_at IS NOT NULL AND revoked_at < DATE_SUB(NOW(), INTERVAL 7 DAY));
END$

-- Cleanup old notifications
CREATE PROCEDURE sp_cleanup_old_notifications()
BEGIN
  DELETE FROM notifications 
  WHERE expires_at < NOW() 
  OR (is_read = 1 AND created_at < DATE_SUB(NOW(), INTERVAL 30 DAY));
END$

-- Archive old audit logs (move to archive table)
CREATE PROCEDURE sp_archive_old_audit_logs()
BEGIN
  -- This would typically move records to an archive table
  -- For now, we'll just delete very old records
  DELETE FROM audit_logs 
  WHERE created_at < DATE_SUB(NOW(), INTERVAL 2 YEAR);
END$

-- Update technician response times
CREATE PROCEDURE sp_update_technician_response_times()
BEGIN
  UPDATE technician_profiles tp
  SET response_time_avg = (
    SELECT AVG(q.response_time)
    FROM quotes q
    WHERE q.technician_id = tp.id 
    AND q.response_time IS NOT NULL
    AND q.created_at >= DATE_SUB(NOW(), INTERVAL 3 MONTH)
  )
  WHERE tp.status = 'verified';
END$

DELIMITER ;

-- =====================================================================
-- SECURITY ENHANCEMENTS
-- =====================================================================

-- Create database user with limited privileges (run as root)
-- CREATE USER 'changsure_app'@'localhost' IDENTIFIED BY 'strong_password_here';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON changsure_app.* TO 'changsure_app'@'localhost';
-- GRANT EXECUTE ON changsure_app.* TO 'changsure_app'@'localhost';
-- FLUSH PRIVILEGES;

-- Enable SSL for connections (configure in my.cnf)
-- ssl-ca=/path/to/ca.pem
-- ssl-cert=/path/to/server-cert.pem
-- ssl-key=/path/to/server-key.pem

-- =====================================================================
-- MONITORING & HEALTH CHECKS
-- =====================================================================

-- Create health check view
CREATE VIEW vw_system_health AS
SELECT 
  'users' as table_name,
  COUNT(*) as total_records,
  COUNT(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 1 END) as daily_additions
FROM users
UNION ALL
SELECT 
  'job_orders' as table_name,
  COUNT(*) as total_records,
  COUNT(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 1 END) as daily_additions
FROM job_orders
UNION ALL
SELECT 
  'payments' as table_name,
  COUNT(*) as total_records,
  COUNT(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 1 END) as daily_additions
FROM payments;

-- =====================================================================
-- BACKUP RECOMMENDATIONS
-- =====================================================================

/*
Recommended backup strategy:

1. Full backup daily:
   mysqldump --routines --triggers --single-transaction --master-data=2 changsure_app > backup_full_$(date +%Y%m%d).sql

2. Incremental backup hourly:
   mysqlbinlog --start-datetime="2025-01-01 00:00:00" /var/lib/mysql/mysql-bin.000001 > backup_incremental_$(date +%Y%m%d_%H).sql

3. Point-in-time recovery setup:
   - Enable binary logging: log-bin=mysql-bin
   - Set expire_logs_days=7
   - Regular backup of binary logs

4. Test restore procedures monthly
*/

-- =====================================================================
-- PERFORMANCE TUNING RECOMMENDATIONS
-- =====================================================================

/*
MySQL Configuration (my.cnf) recommendations for production:

[mysqld]
# Memory settings
innodb_buffer_pool_size = 70% of RAM
innodb_log_file_size = 256M
innodb_log_buffer_size = 16M
innodb_flush_log_at_trx_commit = 2

# Connection settings
max_connections = 500
max_connect_errors = 100000
wait_timeout = 300
interactive_timeout = 300

# Query cache (if using MySQL < 8.0)
query_cache_type = 1
query_cache_size = 256M

# Binary logging
log-bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7

# Slow query log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Optimization
optimizer_search_depth = 62
table_open_cache = 4000
thread_cache_size = 50
tmp_table_size = 512M
max_heap_table_size = 512M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT
innodb_io_capacity = 1000
innodb_read_io_threads = 8
innodb_write_io_threads = 8
*/

-- End of optimized schema
COMMIT;
-- =====================================================================    
SET FOREIGN_KEY_CHECKS = 0;

-- ตัวอย่างการ drop objects ที่จะถูกสร้างใหม่
DROP VIEW IF EXISTS vw_active_technicians;
DROP VIEW IF EXISTS vw_order_summary;
DROP VIEW IF EXISTS vw_recent_reviews;
DROP VIEW IF EXISTS vw_system_health;

DROP TRIGGER IF EXISTS trg_reviews_after_insert;
DROP TRIGGER IF EXISTS trg_reviews_after_update;
DROP TRIGGER IF EXISTS trg_reviews_after_delete;
DROP TRIGGER IF EXISTS trg_quotes_after_insert;
DROP TRIGGER IF EXISTS trg_quotes_after_delete;
DROP TRIGGER IF EXISTS trg_orders_completion_update;
DROP TRIGGER IF EXISTS trg_orders_before_insert;
DROP TRIGGER IF EXISTS trg_payments_before_insert;
DROP TRIGGER IF EXISTS trg_payouts_before_insert;
DROP TRIGGER IF EXISTS trg_disputes_before_insert;
DROP TRIGGER IF EXISTS trg_coupon_usage_after_insert;
DROP TRIGGER IF EXISTS trg_chat_messages_after_insert;
DROP TRIGGER IF EXISTS trg_review_votes_after_insert;
DROP TRIGGER IF EXISTS trg_review_votes_after_update;
DROP TRIGGER IF EXISTS trg_review_votes_after_delete;

DROP PROCEDURE IF EXISTS sp_find_nearby_technicians;
DROP PROCEDURE IF EXISTS sp_update_technician_availability;
DROP PROCEDURE IF EXISTS sp_calculate_order_total;
DROP PROCEDURE IF EXISTS sp_generate_daily_metrics;
DROP PROCEDURE IF EXISTS sp_cleanup_expired_sessions;
DROP PROCEDURE IF EXISTS sp_cleanup_old_notifications;
DROP PROCEDURE IF EXISTS sp_archive_old_audit_logs;
DROP PROCEDURE IF EXISTS sp_update_technician_response_times;

SET FOREIGN_KEY_CHECKS = 1;
-- =====================================================================