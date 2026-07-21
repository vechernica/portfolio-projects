-- =====================================================================
-- 06 — EXTRACT SHOW TITLE, SEASON, AND EPISODE
-- =====================================================================
-- Title is a composite field showing show name, season, and episode
-- into one string (e.g. "Community: Staffel 4: Folge 3"). 

ALTER TABLE viewingactivity_staging
ADD COLUMN show_title VARCHAR(255),
ADD COLUMN season_number VARCHAR(50),
ADD COLUMN episode_number VARCHAR(50);

-- Show title is always the text before the first colon.
UPDATE viewingactivity_staging
SET show_title = TRIM(SUBSTRING_INDEX(title, ':', 1))
WHERE title IS NOT NULL;


-- --- Season-naming edge cases ---

-- Staffel / Season / S1 / Kapitel / Buch / Teil / Part / Ausgabe / Limited Series
UPDATE viewingactivity_staging
SET season_number = CASE
    WHEN title REGEXP '(Limited Series|Miniserie)' THEN 'Limited Series'

    WHEN title REGEXP 'S[0-9]+'
        THEN REGEXP_REPLACE(REGEXP_SUBSTR(title, 'S[0-9]+'), '[^0-9]', '')

    ELSE REGEXP_REPLACE(
        REGEXP_SUBSTR(
            title,
            '(Staffel|Season|Kapitel|Buch|Teil|Part|Ausgabe) [0-9]+'
        ),
        '[^0-9]',
        ''
    )
END
WHERE title REGEXP '(Staffel|Season|S[0-9]+|Kapitel|Buch|Teil|Part|Ausgabe|Limited Series|Miniserie)';

-- German "Kapitel <written number>" formats (e.g. "Kapitel eins").
-- Includes a variant of "fünf" that appears in the export.
UPDATE viewingactivity_staging
SET season_number = CASE
    WHEN title LIKE '%Kapitel eins%'   THEN '1'
    WHEN title LIKE '%Kapitel zwei%'   THEN '2'
    WHEN title LIKE '%Kapitel drei%'   THEN '3'
    WHEN title LIKE '%Kapitel vier%'   THEN '4'
    WHEN title LIKE '%Kapitel fünf%'
      OR title LIKE '%Kapitel fГјnf%'
      OR title LIKE '%Kapitel funf%'   THEN '5'
    WHEN title LIKE '%Kapitel sechs%'  THEN '6'
    WHEN title LIKE '%Kapitel sieben%' THEN '7'
    WHEN title LIKE '%Kapitel acht%'   THEN '8'
    WHEN title LIKE '%Kapitel neun%'   THEN '9'
    WHEN title LIKE '%Kapitel zehn%'
      OR title LIKE '%Kapitel zechn%'  THEN '10'
END
WHERE title LIKE '%Kapitel%';

-- English "Chapter <written number>" formats.
UPDATE viewingactivity_staging
SET season_number = CASE
    WHEN title LIKE '%Chapter One%'   THEN '1'
    WHEN title LIKE '%Chapter Two%'   THEN '2'
    WHEN title LIKE '%Chapter Three%' THEN '3'
    WHEN title LIKE '%Chapter Four%'  THEN '4'
    WHEN title LIKE '%Chapter Five%'  THEN '5'
END
WHERE title LIKE '%Chapter%';

-- Standalone season numbers between colons
-- (e.g. "Pokémon Ultimative Reisen: Die Serie: 1: Title").
-- Only applied where a season number hasn't already been matched.
UPDATE viewingactivity_staging
SET season_number = REGEXP_REPLACE(
    REGEXP_SUBSTR(title, ':[[:space:]]*[0-9]+[[:space:]]*:'),
    '[^0-9]',
    ''
)
WHERE (season_number IS NULL OR TRIM(season_number) = '')
  AND title REGEXP ':[[:space:]]*[0-9]+[[:space:]]*:';


-- --- Episode number ---
-- Handles "Folge <n>" (German) and "Episode <n>" (English).
UPDATE viewingactivity_staging
SET episode_number = REGEXP_REPLACE(
    REGEXP_SUBSTR(title, '(Folge|Episode) [0-9]+'),
    '[^0-9]',
    ''
)
WHERE title REGEXP '(Folge|Episode) [0-9]+';


-- --- Classify movies ---
-- A title with no identifiable season and no identifiable episode is
-- treated as a movie.
UPDATE viewingactivity_staging
SET
    season_number  = 'Not Applicable',
    episode_number = 'Not Applicable'
WHERE (season_number IS NULL OR TRIM(season_number) = '')
  AND (episode_number IS NULL OR TRIM(episode_number) = '');


-- --- Classify limited series ---
-- Titles with an episode number but no identifiable season are
-- classified as Limited Series.
UPDATE viewingactivity_staging
SET season_number = 'Limited Series'
WHERE (season_number IS NULL OR TRIM(season_number) = '')
  AND episode_number IS NOT NULL
  AND TRIM(episode_number) <> '';


-- --- Validation ---
SELECT
    title,
    show_title,
    season_number,
    episode_number
FROM viewingactivity_staging
ORDER BY show_title, season_number, episode_number;

-- Check for any rows that still have no season/episode classification.
SELECT
    title,
    season_number,
    episode_number
FROM viewingactivity_staging
WHERE season_number IS NULL
   OR TRIM(season_number) = ''
   OR episode_number IS NULL
   OR TRIM(episode_number) = '';

-- Spot-check known difficult titles.
SELECT
    title,
    season_number,
    episode_number
FROM viewingactivity_staging
WHERE title LIKE '%Love Is Blind%'
   OR title LIKE '%Stranger Things%'
   OR title LIKE '%Pokémon%'
   OR title LIKE '%Unsolved Mysteries%'
ORDER BY title;
