-- =====================================================================
-- 10 — FINAL VALIDATION AND EDA TABLE
-- =====================================================================

SELECT COUNT(*) AS final_row_count
FROM viewingactivity_staging;

DESCRIBE viewingactivity_staging;

-- Check for unexpected NULLs across key columns.
SELECT
    COUNT(*)                           AS total_rows,
    SUM(duration IS NULL)              AS missing_duration,
    SUM(start_time IS NULL)            AS missing_start_time,
    SUM(profile_name IS NULL)          AS missing_profile,
    SUM(show_title IS NULL)            AS missing_show_title,
    SUM(duration_minutes IS NULL)      AS missing_duration_minutes,
    SUM(watch_date IS NULL)            AS missing_watch_date,
    SUM(completion_percentage IS NULL) AS missing_completion_percentage
FROM viewingactivity_staging;

-- Confirm completion_percentage never falls outside a valid 0-100 range.
SELECT *
FROM viewingactivity_staging
WHERE completion_percentage < 0
   OR completion_percentage > 100;

-- Final duration summary.
SELECT
    MIN(duration_minutes)           AS shortest_minutes,
    ROUND(AVG(duration_minutes), 2) AS average_minutes,
    MAX(duration_minutes)           AS longest_minutes
FROM viewingactivity_staging;

-- Quick summary breakdowns, useful both as a validation step and as a
-- preview of the EDA to follow.
SELECT
    profile_name,
    COUNT(*) AS viewing_sessions
FROM viewingactivity_staging
GROUP BY profile_name
ORDER BY viewing_sessions DESC;

SELECT
    device_category,
    COUNT(*) AS viewing_sessions
FROM viewingactivity_staging
GROUP BY device_category
ORDER BY viewing_sessions DESC;

SELECT
    country_name,
    COUNT(*) AS viewing_sessions
FROM viewingactivity_staging
GROUP BY country_name
ORDER BY viewing_sessions DESC;


-- --- Save final EDA dataset ---

CREATE TABLE netflix_viewing_eda AS
SELECT *
FROM viewingactivity_staging;
