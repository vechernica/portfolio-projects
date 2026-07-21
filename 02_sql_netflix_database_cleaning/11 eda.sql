-- =====================================================================
-- Netflix Viewing Activity — Exploratory Data Analysis
-- Database: MySQL 8.0
-- Source table: netflix_viewing_eda (output of sql/01-10 cleaning)
--
-- Each section answers one specific question about viewing behavior.
-- Queries are grouped by theme rather than numbered sequentially, since
-- none of them depend on one another running in order.
-- =====================================================================


-- =====================================================================
-- PREVIEW
-- =====================================================================

SELECT *
FROM netflix_viewing_eda;


-- =====================================================================
-- VIEWING VOLUME OVER TIME
-- =====================================================================
-- Total sessions and hours watched by month.

SELECT
    watch_year,
    watch_month,
    COUNT(*) AS sessions,
    ROUND(SUM(duration_minutes) / 60, 1) AS hours_watched
FROM netflix_viewing_eda
GROUP BY watch_year, watch_month
ORDER BY watch_year, watch_month;


-- =====================================================================
-- DAY-OF-WEEK / HOUR-OF-DAY PATTERNS
-- =====================================================================
-- Session counts by day and hour.

SELECT
    watch_day,
    watch_hour,
    COUNT(*) AS sessions
FROM netflix_viewing_eda
GROUP BY watch_day, watch_hour
ORDER BY sessions DESC;

-- Weekday vs. weekend comparison.
SELECT
    CASE WHEN watch_day IN ('Saturday', 'Sunday') THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(*)                        AS sessions,
    ROUND(SUM(duration_minutes) / 60, 1) AS total_hours,
    ROUND(AVG(duration_minutes), 1)      AS avg_session_minutes
FROM netflix_viewing_eda
GROUP BY day_type;


-- =====================================================================
-- BINGE BEHAVIOR
-- =====================================================================
-- A binge is defined here as 3+ episodes of the same show watched on the 
-- same calendar day.

SELECT
    profile_name,
    show_title,
    watch_date,
    COUNT(*) AS episodes_watched_that_day
FROM netflix_viewing_eda
WHERE show_title IS NOT NULL
  AND season_number NOT IN ('Not Applicable')
GROUP BY profile_name, show_title, watch_date
HAVING COUNT(*) >= 3
ORDER BY episodes_watched_that_day DESC;


-- =====================================================================
-- REWATCH BEHAVIOR
-- =====================================================================
-- Grouped by season AND episode number.

SELECT
    profile_name,
    show_title,
    season_number,
    episode_number,
    COUNT(*)        AS times_watched,
    MIN(watch_date) AS first_watched,
    MAX(watch_date) AS most_recently_watched
FROM netflix_viewing_eda
WHERE show_title IS NOT NULL
GROUP BY profile_name, show_title, season_number, episode_number
HAVING COUNT(*) > 1
ORDER BY times_watched DESC;


-- =====================================================================
-- PROFILE-LEVEL SUMMARIES
-- =====================================================================

-- Total hours and session count per profile.
SELECT
    profile_name,
    COUNT(*)                              AS sessions,
    ROUND(SUM(duration_minutes) / 60, 1)  AS total_hours,
    ROUND(AVG(duration_minutes), 1)       AS avg_session_minutes
FROM netflix_viewing_eda
GROUP BY profile_name
ORDER BY total_hours DESC;

-- Device habits per profile.
SELECT
    profile_name,
    device_category,
    COUNT(*) AS sessions
FROM netflix_viewing_eda
GROUP BY profile_name, device_category
ORDER BY profile_name, sessions DESC;

-- Top 10 most-watched titles per profile, ranked by total watch time.
WITH ranked_content AS (
    SELECT
        profile_name,
        show_title,
        CASE WHEN season_number = 'Not Applicable' THEN 'Movie' ELSE 'Show' END AS content_type,
        COUNT(*) AS plays,
        ROUND(SUM(duration_minutes) / 60, 1) AS total_hours,
        ROW_NUMBER() OVER (
            PARTITION BY profile_name
            ORDER BY SUM(duration_minutes) DESC
        ) AS rank_within_profile
    FROM netflix_viewing_eda
    WHERE show_title IS NOT NULL
    GROUP BY profile_name, show_title, content_type
)
SELECT
    profile_name,
    rank_within_profile,
    show_title,
    content_type,
    plays,
    total_hours
FROM ranked_content
WHERE rank_within_profile <= 10
ORDER BY profile_name, rank_within_profile;

-- Shows watched by more than one profile.
SELECT
    show_title,
    COUNT(DISTINCT profile_name) AS profiles_watched,
    GROUP_CONCAT(DISTINCT profile_name ORDER BY profile_name SEPARATOR ', ') AS which_profiles
FROM netflix_viewing_eda
WHERE show_title IS NOT NULL
GROUP BY show_title
HAVING profiles_watched > 1
ORDER BY profiles_watched DESC;


-- =====================================================================
-- COMPLETION RATE PATTERNS
-- =====================================================================
-- Completion_rate measures how much of a title was actually watched, not 
-- just that it was started.

-- Average completion by device category.
SELECT
    device_category,
    ROUND(AVG(completion_percentage), 1) AS avg_completion,
    COUNT(*) AS sessions_with_completion_data
FROM netflix_viewing_eda
WHERE completion_percentage IS NOT NULL
GROUP BY device_category
ORDER BY avg_completion DESC;

-- Shows most often started but not finished. Requires at least 3
-- sessions to avoid a single rushed rewatch skewing the average.
SELECT
    show_title,
    COUNT(*) AS sessions,
    ROUND(AVG(completion_percentage), 1) AS avg_completion
FROM netflix_viewing_eda
WHERE completion_percentage IS NOT NULL
GROUP BY show_title
HAVING sessions >= 3
ORDER BY avg_completion ASC
LIMIT 15;


-- =====================================================================
-- CONTENT BREAKDOWN — MOVIES VS. SHOWS
-- =====================================================================

-- All content ranked by total watch time.
SELECT
    show_title,
    CASE WHEN season_number = 'Not Applicable' THEN 'Movie' ELSE 'Show' END AS content_type,
    COUNT(*) AS plays,
    ROUND(SUM(duration_minutes) / 60, 1) AS total_hours
FROM netflix_viewing_eda
GROUP BY show_title, content_type
ORDER BY total_hours DESC;

-- Most-watched movies specifically, filtered to titles watched more
-- than once.
SELECT
    show_title,
    COUNT(*) AS plays,
    ROUND(SUM(duration_minutes) / 60, 1) AS total_hours
FROM netflix_viewing_eda
WHERE season_number = 'Not Applicable'
GROUP BY show_title
HAVING plays > 1
ORDER BY total_hours DESC
LIMIT 15;


-- =====================================================================
-- GEOGRAPHY
-- =====================================================================

-- Sessions and distinct viewing days by country.
SELECT
    country_name,
    COUNT(*) AS sessions,
    COUNT(DISTINCT watch_date) AS distinct_days
FROM netflix_viewing_eda
GROUP BY country_name
ORDER BY sessions DESC;

-- Device usage by country.
SELECT
    country_name,
    device_category,
    COUNT(*) AS sessions
FROM netflix_viewing_eda
GROUP BY country_name, device_category
ORDER BY country_name, sessions DESC;
