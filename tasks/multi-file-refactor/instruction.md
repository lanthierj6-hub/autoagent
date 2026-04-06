# Multi-File Refactor & Debug

You are given a small Python application spread across 4 files in `files/app/`. The application is a lead scoring system, but it has **10 bugs** spread across all 4 files. Some bugs are in one file but cause failures in another (cross-file dependencies).

## Your Task
1. Read ALL 4 source files carefully
2. Find and fix ALL 10 bugs
3. Copy the fixed files to `/task/output/app/`
4. Run the application: `cd /task/output && python3 -m app.main`
5. The app should produce `/task/output/scored_leads.json` and `/task/output/pipeline_stats.json`

## Application Architecture
- `app/__init__.py` — Package init
- `app/models.py` — Data models (Lead, Score, Pipeline)
- `app/scoring.py` — Scoring logic (uses models)
- `app/main.py` — Orchestrator (uses scoring + models, reads /task/files/leads_input.json)

## Expected Output

### scored_leads.json
Array of 8 lead objects, each with:
- All original fields preserved
- `score` (0-100 integer)
- `grade` (A/B/C/D/F based on score)
- `qualified` (boolean)
- Sorted by score descending

### pipeline_stats.json
```json
{
  "total_leads": 8,
  "qualified_count": <int>,
  "disqualified_count": <int>,
  "avg_score": <float>,
  "grade_distribution": {"A": <int>, "B": <int>, "C": <int>, "D": <int>, "F": <int>},
  "top_lead": "<name of highest scoring lead>"
}
```
