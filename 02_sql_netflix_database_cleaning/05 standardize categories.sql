-- =====================================================================
-- 05 — STANDARDIZE DEVICE AND COUNTRY FIELDS
-- =====================================================================

-- --- Device categories ---
-- Raw device_type contains dozens of strings (e.g. "Apple iPhone 14 Pro 
-- Max iPhone"). Bucketing into broad categories makes future analysis 
-- of device habits readable.

SELECT DISTINCT device_type
FROM viewingactivity_staging
ORDER BY 1;

ALTER TABLE viewingactivity_staging
ADD COLUMN device_category VARCHAR(20);

UPDATE viewingactivity_staging
SET device_category = CASE
    WHEN device_type LIKE '%Phone%'                                  THEN 'Phone'
    WHEN device_type LIKE '%Tablet%' OR device_type LIKE '%iPad'     THEN 'Tablet'
    WHEN device_type LIKE '%TV%'                                     THEN 'Smart TV'
    WHEN device_type LIKE '%FireTV%'
      OR device_type LIKE '%Set Top Box%'
      OR device_type LIKE '%ATV%'                                    THEN 'Streaming Box'
    WHEN device_type LIKE '%Windows%'
      OR device_type LIKE '%Edge%'
      OR device_type LIKE '%Cadmium%'                                THEN 'Web/App'
    WHEN device_type LIKE '%Nest Hub%'
      OR device_type LIKE '%Smart Display%'                          THEN 'Smart Display'
    ELSE 'Other'
END;

-- Check the size of the "Other" bucket. A large bucket here would mean
-- the categorization isn't capturing the real device mix and the CASE
-- conditions above need refining.

SELECT
    device_category,
    COUNT(*) AS viewing_sessions
FROM viewingactivity_staging
GROUP BY device_category
ORDER BY viewing_sessions DESC;

-- --- Country code and name ---
-- Raw format is consistently "DE (Germany)". Splitting it imto two columns 
-- makes it easier to queu the data later on.

ALTER TABLE viewingactivity_staging
ADD COLUMN country_code VARCHAR(2),
ADD COLUMN country_name VARCHAR(50);

UPDATE viewingactivity_staging
SET
    country_code = TRIM(SUBSTRING_INDEX(country, ' (', 1)),
    country_name = TRIM(TRAILING ')' FROM SUBSTRING_INDEX(country, '(', -1));

-- Verify every row parsed correctly (no NULLs or unexpected values).
SELECT DISTINCT
    country,
    country_code,
    country_name
FROM viewingactivity_staging;

ALTER TABLE viewingactivity_staging
DROP COLUMN country;
