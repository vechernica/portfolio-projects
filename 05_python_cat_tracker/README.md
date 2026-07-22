# 05_python_cat_tracker

A Python script that tracks daily care for my two cats, Freya and Neptun - feeding (separate) and water/litter (shared). I built it to practice the fundamentals: loops, dictionaries, conditionals, basic input handling.

## Visualization

```
Did you feed Freya today? (yes/no): yes
Did you feed Neptun today? (yes/no): no
Was the water changed today? (yes/no): yes
Was the litter cleaned today? (yes/no): yes

--- Feeding & Care Summary ---
Freya: fed ✅
Neptun: NOT fed ❌
Water: changed ✅
Litter: cleaned ✅

Something still needs doing today!
```

## What it does

Each day it asks:
- Was each cat fed?
- Was the shared water bowl changed?
- Was the shared litter box cleaned?

It then prints a summary of what's done and what's still outstanding.

## Why this is here

Python is something I'm teaching myself independently, and this project is a small, honest starting point rather than a polished showcase. Basically I am just playing around and practicing. 

## Skills demonstrated

- Using dictionaries to track per-item status instead of separate variables for each
- Structuring input/output around a real, recurring task rather than an abstract exercise
- Writing conditional logic that checks multiple states at once (`all()`)

## Tools used

- Python (`input()`, dictionaries, loops, conditionals)

## Running it

```bash
python cat-care-tracker
```

## Where I'd take it next

- Log results to a file to build a history over time
- Add a treat counter with a daily limit
- Track a streak of fully completed care days
