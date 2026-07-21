-- =====================================================================
-- 09 — BACKUP, DROP REDUNDANT COLUMNS, CREATE EDA FEATURES
-- =====================================================================

-- --- Backup before final column removal ---
-- Preserves the option to recover any removed column later without 
-- re-running the full cleaning pipeline.

CREATE TABLE viewingactivity_eda_backup AS
SELECT *
FROM viewingactivity_staging;

-- --- Remove columns no longer needed for EDA ---
-- title:                    replaced by show_title / season_number / episode_number
-- device_type:              replaced by device_category
-- supplemental_video_type:  no longer relevant — trailer/teaser rows were removed
-- attributes:               no longer relevant — autoplay rows were removed

ALTER TABLE viewingactivity_staging
DROP COLUMN title,
DROP COLUMN device_type,
DROP COLUMN supplemental_video_type,
DROP COLUMN attributes;

DESCRIBE viewingactivity_staging;

-- --- Duration in minutes ---
-- Easier to aggregate/compare than TIME.
ALTER TABLE viewingactivity_staging
ADD COLUMN duration_minutes DECIMAL(10, 2);

UPDATE viewingactivity_staging
SET duration_minutes = TIME_TO_SEC(duration) / 60;

SELECT
    duration,
    duration_minutes
FROM viewingactivity_staging
ORDER BY duration_minutes DESC
LIMIT 20;

SELECT
    MIN(duration_minutes)           AS shortest_minutes,
    MAX(duration_minutes)           AS longest_minutes,
    ROUND(AVG(duration_minutes), 2) AS average_minutes
FROM viewingactivity_staging;

-- Sessions under one minute are treated as accidental playback starts
-- and are removed.
SELECT
    show_title,
    duration,
    duration_minutes,
    start_time,
    profile_name,
    device_category
FROM viewingactivity_staging
WHERE duration_minutes < 1
ORDER BY duration_minutes;

SELECT
    COUNT(*)                                              AS total_rows,
    SUM(CASE WHEN duration_minutes < 1 THEN 1 ELSE 0 END) AS under_one_minute,
    ROUND(
        SUM(CASE WHEN duration_minutes < 1 THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS percentage_of_data
FROM viewingactivity_staging;

DELETE FROM viewingactivity_staging
WHERE duration_minutes < 1;

-- Confirm the removal.
SELECT COUNT(*) AS remaining_short_sessions
FROM viewingactivity_staging
WHERE duration_minutes < 1;

SELECT COUNT(*) AS remaining_rows
FROM viewingactivity_staging;


-- --- Viewing time breakdown columns ---
-- For time-of-day/day-of-week analysis.
ALTER TABLE viewingactivity_staging
ADD COLUMN watch_date  DATE,
ADD COLUMN watch_year  INT,
ADD COLUMN watch_month INT,
ADD COLUMN watch_day   VARCHAR(10),
ADD COLUMN watch_hour  INT;

UPDATE viewingactivity_staging
SET
    watch_date  = DATE(start_time),
    watch_year  = YEAR(start_time),
    watch_month = MONTH(start_time),
    watch_day   = DAYNAME(start_time),
    watch_hour  = HOUR(start_time);

SELECT
    start_time,
    watch_date,
    watch_year,
    watch_month,
    watch_day,
    watch_hour
FROM viewingactivity_staging
LIMIT 25;


-- --- Completion percentage ---
-- How much of a title was actually watched. Only calculated when
-- bookmark does not exceed duration.

ALTER TABLE viewingactivity_staging
ADD COLUMN completion_percentage DECIMAL(6, 2);

UPDATE viewingactivity_staging
SET completion_percentage =
    CASE
        WHEN duration IS NOT NULL
         AND duration <> '00:00:00'
         AND bookmark IS NOT NULL
         AND TIME_TO_SEC(bookmark) <= TIME_TO_SEC(duration)
        THEN ROUND((TIME_TO_SEC(bookmark) / TIME_TO_SEC(duration)) * 100, 2)
        ELSE NULL
    END;

SELECT
    show_title,
    duration,
    bookmark,
    completion_percentage
FROM viewingactivity_staging
WHERE completion_percentage IS NOT NULL
LIMIT 25;

SELECT
    MIN(completion_percentage)           AS minimum_completion,
    MAX(completion_percentage)           AS maximum_completion,
    ROUND(AVG(completion_percentage), 2) AS average_completion,
    COUNT(completion_percentage)         AS calculated_records
FROM viewingactivity_staging;

-- Review rows where completion percentage could not be calculated,
-- to confirm the NULLs are expected (e.g. bookmark exceeding duration).

SELECT
    show_title,
    duration,
    bookmark
FROM viewingactivity_staging
WHERE completion_percentage IS NULL
  AND bookmark IS NOT NULL
LIMIT 25;
