DROP VIEW IF EXISTS view_service_starting_prices;

DROP VIEW IF EXISTS view_technicians_per_service;

CREATE VIEW view_service_starting_prices AS
SELECT
    s.id AS service_id,
    s.name AS service_name,
    MIN(ts.price_min) AS starting_price
FROM
    services s
    JOIN technician_services ts ON ts.service_id = s.id
    AND ts.is_active = 1
WHERE
    s.is_active = 1
GROUP BY
    s.id,
    s.name;

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
FROM
    technicians t
    JOIN technician_services ts ON ts.technician_id = t.id
    AND ts.is_active = 1
WHERE
    t.is_available = 1;