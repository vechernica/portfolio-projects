-- =====================================================================
-- 03 — RENAME COLUMNS TO SNAKE_CASE
-- =====================================================================

-- Raw column headers came in from the CSV with spaces and mixed case.
-- Renaming to snake_case removes the need for backtick quote.

ALTER TABLE viewingactivity_staging
    RENAME COLUMN Duration                 TO duration,
    RENAME COLUMN `Start Time`              TO start_time,
    RENAME COLUMN Bookmark                  TO bookmark,
    RENAME COLUMN `Latest Bookmark`         TO latest_bookmark,
    RENAME COLUMN `Profile Name`            TO profile_name,
    RENAME COLUMN Country                   TO country,
    RENAME COLUMN `Supplemental Video Type` TO supplemental_video_type,
    RENAME COLUMN Attributes                TO attributes,
    RENAME COLUMN `Device Type`             TO device_type,
    RENAME COLUMN Title                     TO title;

DESCRIBE viewingactivity_staging;
