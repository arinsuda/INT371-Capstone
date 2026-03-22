DROP VIEW IF EXISTS view_service_starting_prices;

DROP VIEW IF EXISTS view_technicians_per_service;

DROP VIEW IF EXISTS technician_stats;

CREATE VIEW view_service_starting_prices AS
SELECT
    s.id AS service_id,
    s.ser_name AS service_name,
    MIN(ts.price_min) AS starting_price
FROM
    services s
    JOIN technician_services ts ON ts.service_id = s.id
    AND ts.is_active = 1
WHERE
    s.is_active = 1
GROUP BY
    s.id,
    s.ser_name;

CREATE VIEW view_technicians_per_service AS
SELECT
    ts.service_id,
    t.id AS technician_id,
    CONCAT(t.first_name, ' ', t.last_name) AS display_name,
    ts.pricing_type,
    ts.price_min,
    ts.price_max,
    ts.price_fixed,
    t.is_available
FROM
    technicians t
    JOIN technician_services ts ON ts.technician_id = t.id
    AND ts.is_active = 1
WHERE
    t.is_available = 1;

CREATE VIEW technician_stats AS
SELECT
    t.id AS technician_id,
    COUNT(
        DISTINCT CASE
            WHEN b.status NOT IN ('PENDING', 'CANCELLED', 'REJECTED') THEN b.id
        END
    ) AS total_jobs,
    COALESCE(ROUND(AVG(rv.rating), 2), 0.00) AS rating_avg,
    COUNT(rv.id) AS rating_count
FROM
    technicians t
    LEFT JOIN bookings b ON b.technician_id = t.id
    LEFT JOIN reviews rv ON rv.booking_id = b.id
WHERE
    t.deleted_at IS NULL
GROUP BY
    t.id;