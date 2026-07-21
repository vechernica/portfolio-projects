-- =====================================================================
-- 01 — IMPORT AND STAGING
-- =====================================================================
-- Preview the raw imported data before any changes are made.

SELECT *
FROM viewingactivity;

-- All cleaning is performed on a staging copy.

CREATE TABLE viewingactivity_staging
LIKE viewingactivity;

INSERT INTO viewingactivity_staging
SELECT *
FROM viewingactivity;

-- Verify the copy succeeded.
SELECT *
FROM viewingactivity_staging;
