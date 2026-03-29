DROP PROCEDURE IF EXISTS create_reservation;

DROP PROCEDURE IF EXISTS set_reservation_status;

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
    IN p_lat DECIMAL(10, 7),
    IN p_lon DECIMAL(10, 7),
    IN p_price_estimate DECIMAL(12, 2),
    IN p_notes TEXT
) BEGIN DECLARE v_status_pending TINYINT UNSIGNED;

SELECT
    id INTO v_status_pending
FROM
    reservation_statuses
WHERE
    code = 'pending'
LIMIT
    1;

INSERT INTO
    reservations (
        customer_id,
        technician_id,
        service_id,
        start_at,
        end_at,
        timezone,
        status_id,
        confirmation_deadline,
        address,
        province_id,
        latitude,
        longitude,
        price_estimate,
        notes
    )
VALUES
    (
        p_customer_id,
        p_technician_id,
        p_service_id,
        p_start_at,
        p_end_at,
        COALESCE(p_timezone, 'Asia/Bangkok'),
        v_status_pending,
        p_confirmation_deadline,
        p_address,
        p_province_id,
        p_lat,
        p_lon,
        p_price_estimate,
        p_notes
    );

INSERT INTO
    reservation_status_logs (reservation_id, old_status_id, new_status_id)
VALUES
    (LAST_INSERT_ID(), NULL, v_status_pending);

SELECT
    LAST_INSERT_ID() AS reservation_id;

END;

CREATE PROCEDURE set_reservation_status(
    IN p_reservation_id INT,
    IN p_new_status_code VARCHAR(20)
) BEGIN DECLARE v_new_status_id TINYINT UNSIGNED;

DECLARE v_old_status_id TINYINT UNSIGNED;

SELECT
    id INTO v_new_status_id
FROM
    reservation_statuses
WHERE
    code = p_new_status_code
LIMIT
    1;

SELECT
    status_id INTO v_old_status_id
FROM
    reservations
WHERE
    id = p_reservation_id;

UPDATE
    reservations
SET
    status_id = v_new_status_id
WHERE
    id = p_reservation_id;

INSERT INTO
    reservation_status_logs (reservation_id, old_status_id, new_status_id)
VALUES
    (
        p_reservation_id,
        v_old_status_id,
        v_new_status_id
    );

END;