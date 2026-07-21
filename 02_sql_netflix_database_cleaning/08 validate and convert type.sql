-- =====================================================================
-- 08 — VALIDATE AND CONVERT DATE/TIME COLUMNS
-- =====================================================================
-- Validate that time-formatted fields actually match HH:MM:SS/proper
-- datetime format before converting column types.

SELECT COUNT(*) AS invalid_duration
FROM viewingactivity_staging
WHERE duration NOT REGEXP '^[0-9]{2}:[0-9]{2}:[0-9]{2}$';

SELECT COUNT(*) AS invalid_bookmark
FROM viewingactivity_staging
WHERE bookmark NOT REGEXP '^[0-9]{2}:[0-9]{2}:[0-9]{2}$';

SELECT COUNT(*) AS invalid_latest_bookmark
FROM viewingactivity_staging
WHERE latest_bookmark NOT REGEXP '^[0-9]{2}:[0-9]{2}:[0-9]{2}$';

SELECT COUNT(*) AS invalid_start_time
FROM viewingactivity_staging
WHERE start_time NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$';

-- Identify what the invalid latest_bookmark values actually are.
SELECT
    latest_bookmark,
    COUNT(*) AS occurrences
FROM viewingactivity_staging
WHERE latest_bookmark NOT REGEXP '^[0-9]{2}:[0-9]{2}:[0-9]{2}$'
GROUP BY latest_bookmark
ORDER BY occurrences DESC;

-- "Not latest view" is a placeholder string, not a time value.
-- Convert it to NULL.
UPDATE viewingactivity_staging
SET latest_bookmark = NULL
WHERE latest_bookmark = 'Not latest view';

-- Confirm no invalid time values remain.
SELECT COUNT(*) AS remaining_invalid_latest_bookmark
FROM viewingactivity_staging
WHERE latest_bookmark IS NOT NULL
  AND latest_bookmark NOT REGEXP '^[0-9]{2}:[0-9]{2}:[0-9]{2}$';


-- --- Convert to proper types ---
ALTER TABLE viewingactivity_staging
MODIFY COLUMN start_time      DATETIME,
MODIFY COLUMN duration        TIME,
MODIFY COLUMN bookmark        TIME,
MODIFY COLUMN latest_bookmark TIME;

DESCRIBE viewingactivity_staging;

-- Spot-check the converted values.
SELECT
    start_time,
    duration,
    bookmark,
    latest_bookmark
FROM viewingactivity_staging
LIMIT 20;

-- Rows with zero duration represent titles clicked into but never
-- actually played. Reviewed here before deciding how to treat them
-- later.
SELECT *
FROM viewingactivity_staging
WHERE duration = '00:00:00';
