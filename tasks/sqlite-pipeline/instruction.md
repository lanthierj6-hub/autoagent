# SQLite Lead Pipeline

Create a SQLite database and populate it with lead data, then run analytics queries.

## Task

1. Create a SQLite database at `/task/output/pipeline.db`
2. Create a `leads` table with columns:
   - `id` INTEGER PRIMARY KEY AUTOINCREMENT
   - `name` TEXT NOT NULL
   - `email` TEXT
   - `phone` TEXT
   - `company` TEXT
   - `source` TEXT
   - `score` INTEGER (0-100)
   - `status` TEXT (one of: 'new', 'contacted', 'qualified', 'closed')
   - `created_at` TEXT (ISO 8601 format)
3. Read `/task/files/leads_raw.json` and insert all records into the table
4. Run the following analytics and write results to `/task/output/analytics.json`:
   - `total_leads`: total number of leads
   - `by_status`: object with status as key, count as value
   - `by_source`: object with source as key, count as value
   - `avg_score`: average score rounded to 1 decimal
   - `top_leads`: list of top 3 leads by score (name and score only)
   - `qualified_rate`: percentage of leads with status 'qualified' or 'closed', rounded to 1 decimal
