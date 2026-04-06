# CSV Lead Deduplication

You have a CSV file at `/task/files/leads.csv` with the following columns:
- `name` (string)
- `email` (string)
- `phone` (string)
- `company` (string)
- `source` (string)

The file contains duplicate leads. A duplicate is defined as rows that share the same `email` (case-insensitive).

## Task

1. Read the CSV file
2. Deduplicate by `email` (case-insensitive), keeping the FIRST occurrence
3. Sort the result by `email` alphabetically (ascending)
4. Write the deduplicated CSV to `/task/output/leads_clean.csv`
5. Write a summary JSON to `/task/output/summary.json` with:
   - `total_input`: number of rows in the input
   - `total_output`: number of rows after dedup
   - `duplicates_removed`: number of duplicates removed

The output CSV must have the same columns as the input, with a header row.
