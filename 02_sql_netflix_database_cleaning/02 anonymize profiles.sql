-- =====================================================================
-- 02 — ANONYMIZE PROFILE NAMES (PRIVACY)
-- =====================================================================

-- `Profile Name` identifies real people in the household,
-- so it's anonymized first.

-- Labels are assigned dynamically by rank order rather than hardcoded
-- per name, so no real name ever needs to appear in this script.

-- Preview how many distinct profiles exist before anonymizing.
SELECT DISTINCT `Profile Name`
FROM viewingactivity_staging;

ALTER TABLE viewingactivity_staging
ADD COLUMN profile_rank INT;

UPDATE viewingactivity_staging v
JOIN (
    SELECT
        `Profile Name`,
        DENSE_RANK() OVER (ORDER BY `Profile Name`) AS rnk
    FROM (
        SELECT DISTINCT `Profile Name`
        FROM viewingactivity_staging
    ) AS distinct_profiles
) AS ranked
    ON v.`Profile Name` = ranked.`Profile Name`
SET v.profile_rank = ranked.rnk;

-- CHAR(64 + n) converts 1, 2, 3... into 'A', 'B', 'C'... (ASCII 65 = 'A').

UPDATE viewingactivity_staging
SET `Profile Name` = CONCAT('Profile ', CHAR(64 + profile_rank));

ALTER TABLE viewingactivity_staging
DROP COLUMN profile_rank;

-- Confirm only anonymized labels remain.
SELECT DISTINCT `Profile Name`
FROM viewingactivity_staging;
