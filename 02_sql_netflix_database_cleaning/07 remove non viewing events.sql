-- =====================================================================
-- 07 — REMOVE NON-VIEWING EVENTS
-- =====================================================================
-- Trailers, teasers, hooks, and bumpers are not legitimate viewing
-- sessions.

DELETE FROM viewingactivity_staging
WHERE supplemental_video_type IS NOT NULL
  AND TRIM(supplemental_video_type) <> '';

-- Autoplayed content (rows carrying an "attributes" flag) is removed
-- for the same reason- It reflects Netflix's behavior, not a
-- deliberate viewing choice by a profile.

DELETE FROM viewingactivity_staging
WHERE attributes IS NOT NULL
  AND TRIM(attributes) <> '';
