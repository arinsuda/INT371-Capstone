DROP PROCEDURE IF EXISTS auto_match_technician;

CREATE PROCEDURE auto_match_technician (
    IN p_customer_id INT,
    IN p_service_id INT,
    IN p_province_id INT,
    IN p_min_price DECIMAL(12, 2),
    IN p_max_price DECIMAL(12, 2),
    IN p_max_distance DECIMAL(10, 2)
) BEGIN DECLARE v_lat DECIMAL(10, 7);

DECLARE v_lon DECIMAL(10, 7);

SELECT
    latitude,
    longitude INTO v_lat,
    v_lon
FROM
    customers
WHERE
    id = p_customer_id;

IF v_lat IS NULL
OR v_lon IS NULL THEN
SELECT
    NULL AS technician_id,
    'Missing customer location' AS message;

ELSE
SELECT
    v.technician_id,
    v.display_name,
    (
        6371 * 2 * ASIN(
            SQRT(
                POWER(SIN((RADIANS(v.latitude) - RADIANS(v_lat)) / 2), 2) + COS(RADIANS(v_lat)) * COS(RADIANS(v.latitude)) * POWER(SIN((RADIANS(v.longitude) - RADIANS(v_lon)) / 2), 2)
            )
        )
    ) AS distance_km,
    COALESCE(v.price_min, v.price_fixed) AS base_price,
    v.rating_avg,
    v.rating_count
FROM
    view_technicians_per_service v
    JOIN technician_service_areas a ON a.technician_id = v.technician_id
    AND a.province_id = p_province_id
WHERE
    v.service_id = p_service_id
    AND v.is_available = 1
    AND (
        COALESCE(v.price_min, v.price_fixed) BETWEEN p_min_price
        AND p_max_price
    )
    AND (
        6371 * 2 * ASIN(
            SQRT(
                POWER(SIN((RADIANS(v.latitude) - RADIANS(v_lat)) / 2), 2) + COS(RADIANS(v_lat)) * COS(RADIANS(v.latitude)) * POWER(SIN((RADIANS(v.longitude) - RADIANS(v_lon)) / 2), 2)
            )
        )
    ) <= p_max_distance
ORDER BY
    RAND()
LIMIT
    1;

END IF;

END;