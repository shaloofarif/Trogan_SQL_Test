WITH RECURSIVE intervals AS (
    SELECT 
        CAST(CONCAT('2024-04-08', ' 00:00:00') AS DATETIME) AS interval_start,
        CAST(CONCAT('2024-04-08', ' 00:05:00') AS DATETIME) AS interval_end
    UNION ALL
    SELECT 
        interval_start + INTERVAL 5 MINUTE,
        interval_end + INTERVAL 5 MINUTE
    FROM intervals
    WHERE interval_start < CAST(CONCAT('2024-04-08', ' 23:55:00') AS DATETIME)
),
app_usage_with_intervals AS (
    SELECT 
        i.interval_start,
        i.interval_end,
        u.app_name,
        u.productivity_level,
        TIMESTAMPDIFF(SECOND, 
            GREATEST(i.interval_start, u.start_time), 
            LEAST(i.interval_end, u.end_time)
        ) AS duration
    FROM intervals i
    JOIN user_app_usage_1 u
        ON u.start_time < i.interval_end AND u.end_time > i.interval_start
    WHERE u.usage_date = '2024-04-08'
),
aggregated_intervals AS (
    SELECT 
        interval_start,
        interval_end,
        GROUP_CONCAT(DISTINCT CONCAT(app_name, ' (', total_duration, ')') ORDER BY app_name) AS apps_used,
        SUM(CASE WHEN productivity_level = 'productive' THEN total_duration ELSE 0 END) AS productive_time,
        SUM(CASE WHEN productivity_level = 'unproductive' THEN total_duration ELSE 0 END) AS unproductive_time,
        SUM(CASE WHEN productivity_level = 'neutral' THEN total_duration ELSE 0 END) AS neutral_time,
        SUM(total_duration) AS total_time
    FROM (
        SELECT 
            interval_start,
            interval_end,
            app_name,
            productivity_level,
            SUM(duration) AS total_duration
        FROM app_usage_with_intervals
        GROUP BY interval_start, interval_end, app_name, productivity_level
    ) subquery
    GROUP BY interval_start, interval_end
)
SELECT 
    interval_start,
    interval_end,
    apps_used,
    ROUND((productive_time / total_time) * 100, 2) AS productive_percentage,
    ROUND((unproductive_time / total_time) * 100, 2) AS unproductive_percentage,
    ROUND((neutral_time / total_time) * 100, 2) AS neutral_percentage
FROM aggregated_intervals;