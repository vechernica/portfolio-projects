-- =====================================================================
-- 04 — CHECK FOR DUPLICATE RECORDS
-- =====================================================================


WITH duplicate_cte AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                duration,
                start_time,
                bookmark,
                latest_bookmark,
                profile_name,
                country,
                supplemental_video_type,
                attributes,
                device_type,
                title
        ) AS row_num
    FROM viewingactivity_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- No exact duplicates found. Netflix logs a new row per playback event, so exact 
-- duplicatesaren't expected here. Checked anyway.
