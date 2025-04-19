WITH RECURSIVE intervals AS (
    SELECT 
        CAST(CONCAT('2024-03-30', ' 00:00:00') AS DATETIME) AS interval_start,
        CAST(CONCAT('2024-03-30', ' 00:05:00') AS DATETIME) AS interval_end
    UNION ALL
    SELECT 
        interval_start + INTERVAL 5 MINUTE,
        interval_end + INTERVAL 5 MINUTE
    FROM intervals
    WHERE interval_start < CAST(CONCAT('2024-03-30', ' 23:55:00') AS DATETIME)
)
SELECT 
    i.interval_start,
    i.interval_end,
    u.app_name,
    u.start_time,
    u.end_time
FROM intervals i
LEFT JOIN user_app_usage_1 u
    ON u.start_time < i.interval_end AND u.end_time > i.interval_start
WHERE u.usage_date = '2024-03-30';