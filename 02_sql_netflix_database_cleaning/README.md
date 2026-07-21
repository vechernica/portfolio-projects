# Netflix Viewing History — SQL Data Cleaning Project

## Overview

This project applies a standard SQL data-cleaning workflow (staging
tables, anonymization, duplicate checking, standardization, text
parsing, type conversion, and feature creation) to a personal
dataset: my own Netflix "Download Your Data" export.

**Source file:** `ViewingActivity.csv` from Netflix's official data
export tool (Account → Settings → "Download Your Personal Information").
7,302 rows of individual playback events, cleaned down to a final
EDA table.

[View the interactive dashboard on Tableau Public](https://public.tableau.com/app/profile/kalina.stefanova/viz/NetflixData_17844763137030/Dashboard1#1)

---

## Privacy & what's excluded

A full Netflix data export contains far more than viewing history - e.g.
account details, billing history, IP address logs, and customer service
transcripts. None of that is relevant to a cleaning
demo, and none of it is in this repo.

**Included:** cleaned SQL scripts, the final cleaned dataset
(`netflix_viewing_eda`), and this documentation.

**Excluded, on purpose:**
- Payment/billing records
- IP address logs
- Account details (email, subscription/payment info)
- Customer service chat transcripts
- Full profile list (contains real names of other people on the account)
- The raw dataset

**Precautions taken on the cleaned dataset before publishing:**
Profile names are confirmed to only contain anonymized labels
(`Profile A`, `Profile B`, etc. — see below) before export, checked
directly against the final table rather than assumed. No other fields
in the cleaned export contain information about anyone besides the
account owner.

**Profile names are never typed into the script at all.** Rather than
hardcoding a mapping like `'Kalina' → 'Profile A'` (which would put a
real name in a public repo, if only briefly, in the script's edit
history), profile labels are assigned dynamically using `DENSE_RANK()`
over the distinct values already present in the table. The script never
needs to "know" or reference an actual name — see
[`02_anonymize_profiles.sql`](./sql/02_anonymize_profiles.sql).

---

## Dataset structure (raw)

| Column | Description |
|---|---|
| `Duration` | How long this playback event lasted (`HH:MM:SS`) |
| `Start Time` | Timestamp the playback started (UTC) |
| `Bookmark` / `Latest Bookmark` | Playback position at event time / most recent position |
| `Profile Name` | Which household profile watched (anonymized in Step 2) |
| `Country` | Country the stream occurred in, e.g. `"DE (Germany)"` |
| `Supplemental Video Type` | Trailers/extras marker (mostly blank) |
| `Attributes` | Additional metadata (mostly blank) |
| `Device Type` | Raw device string, e.g. `"Apple iPhone 14 Pro Max iPhone"` |
| `Title` | Show/episode or movie title (German-language, colon-delimited for episodes) |

---

## Repo structure

```
netflix-viewing-history-cleaning/
├── README.md
├── data/
│   └── netflix_viewing_eda_cleaned.csv
└── sql/
    ├── 01_import_and_staging.sql
    ├── 02_anonymize_profiles.sql
    ├── 03_rename_columns.sql
    ├── 04_duplicate_check.sql
    ├── 05_standardize_categories.sql
    ├── 06_parse_titles.sql
    ├── 07_remove_non_viewing_events.sql
    ├── 08_validate_and_convert_types.sql
    ├── 09_create_eda_features.sql
    ├── 10_final_validation.sql
    └── 11_eda.sql
```

Scripts are numbered and run in order — each is self-contained enough
to review individually, but they build on the staging table created in
`01`.

---

## Cleaning workflow

1. **Import & staging** (`01`) — raw CSV imported into MySQL, then
   copied into a staging table so the raw import is never modified
   directly.
2. **Anonymize profile names** (`02`) — done first, before any other
   step touches the data, using rank-based label assignment so no real
   name is ever written into the script.
3. **Rename columns to snake_case** (`03`) — raw CSV headers had spaces
   and mixed case; renamed for consistency and to avoid backtick-quoting
   every reference downstream.
4. **Duplicate check** (`04`) — exact-row duplicate detection using the
   same `ROW_NUMBER()` method as prior cleaning projects. **Result: zero
   exact duplicates.** Netflix logs a new row per playback event, so
   this isn't a bug in the data — it's a real, documented finding rather
   than a skipped step.
5. **Standardize categories** (`05`) — ~30 raw device-name strings
   bucketed into readable categories (Phone, Tablet, Smart TV, Streaming
   Box, Web/App, Smart Display, Other); `Country` split from
   `"DE (Germany)"` into separate `country_code` and `country_name`
   columns.
6. **Parse titles** (`06`) — `show_title`, `season_number`, and
   `episode_number` extracted from the combined title string, handling
   multiple German and English naming conventions (Staffel, Season, S1,
   Kapitel, Chapter, Buch, Teil, Part, Ausgabe, Limited Series, and
   standalone numeric formats), including a documented character-encoding
   artifact in one title variant. Titles matching no season/episode
   pattern are classified as movies; episodes with no identifiable
   season are classified as Limited Series.
7. **Remove non-viewing events** (`07`) — trailer/teaser/hook/bumper
   rows and autoplay events removed, since they represent Netflix
   platform behavior rather than a deliberate viewing choice.
8. **Validate & convert types** (`08`) — time-formatted fields checked
   against expected `HH:MM:SS` format before conversion; a placeholder
   string (`"Not latest view"`) converted to `NULL`; `start_time`
   converted to `DATETIME`, `duration`/`bookmark` fields to `TIME`.
9. **Create EDA features** (`09`) — redundant columns dropped (replaced
   by parsed/standardized equivalents) after taking a backup copy;
   `duration_minutes`, `watch_date`/`watch_year`/`watch_month`/
   `watch_day`/`watch_hour`, and `completion_percentage` added.
   Sessions under one minute removed as accidental playback rather than
   intentional viewing; completion percentage left `NULL` rather than
   forced into an invalid value when bookmark exceeds duration.
10. **Final validation** (`10`) — null checks, range validation on
    `completion_percentage`, and summary breakdowns by profile, device,
    and country before saving the finished `netflix_viewing_eda` table.

---

## Key cleaning decisions

- **Anonymization comes first and never touches the repo.** No real
  name appears in any script, even transiently.
- **Zero-duration and sub-one-minute rows are handled differently.**
  Zero-duration clicks are reviewed as a real signal (title clicked but
  never played); rows under one minute are removed as accidental
  playback/tracking artifacts, since analysis is meaningfully distorted
  by extremely short, likely-unintentional sessions.
- **Completion percentage is never forced.** If `bookmark` exceeds
  `duration` (a data inconsistency, not a real behavior), the value is
  `NULL` rather than an invalid or misleading percentage.
- **Movies vs. series vs. limited series** are distinguished by whether
  a season and/or episode number could be parsed from the title —
  documented explicitly rather than left as an implicit side effect of
  the regex.

---

## Before / after

| Stage | Row count |
|---|---|
| Raw import | 22,505 |
| After removing non-viewing events, short sessions | *edit this* |

---

## Exploratory data analysis

Once the table was cleaned, [`sql/11_eda.sql`](./sql/11_eda.sql) runs a
set of grouped queries against `netflix_viewing_eda` to answer specific
questions about viewing behavior:

- **Viewing volume over time** — sessions and hours watched by month.
- **Day/hour patterns** — a day-of-week x hour-of-day breakdown, plus a
  simpler weekday-vs-weekend comparison.
- **Binge behavior** — defined here as 3+ episodes of the same show
  watched on the same calendar day (this schema has no session-level
  grouping, so this is a documented proxy rather than a precise
  session boundary).
- **Rewatch behavior** — titles watched more than once, grouped by
  season *and* episode number specifically, since episode numbers
  reset each season and grouping by episode alone would conflate
  different episodes across seasons.
- **Profile-level summaries** — total hours per profile, device habits
  per profile, top 10 most-watched titles per profile (via a single
  `ROW_NUMBER() PARTITION BY` query rather than one query per profile),
  and shows watched by more than one profile.
- **Completion rate patterns** — average completion percentage by
  device category, and the shows most often started but not finished.
  This metric doesn't exist in a typical tabular cleaning project and
  is one of the more distinctive parts of this dataset.
- **Movies vs. shows** — content ranked by total watch time, and the
  most-rewatched movies specifically.
- **Geography** — sessions and distinct viewing days by country (a
  rough travel timeline for the export period), and device usage
  broken down by country.

### Findings

*insert here*

---

## What I'd explore next

Beyond the EDA above, a few natural follow-ons if this were extended
further:
- Correlating completion rate with time of day (do late-night sessions
  get abandoned more often?)
- A proper session-level rewatch definition, if session boundaries
  were reconstructed from timestamps rather than approximated by
  calendar day
- Visualizing the day x hour heatmap and monthly trend as actual
  charts rather than raw query output

---

## Tools

MySQL 8.0. 
