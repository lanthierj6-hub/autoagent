# Multi-Step Data Pipeline

Build a complete data pipeline that chains multiple operations together. This tests the agent's ability to handle complex, multi-step workflows with dependencies between steps.

## Input Files

- `/task/files/companies.json` — list of companies with nested data
- `/task/files/transactions.csv` — financial transactions referencing company IDs
- `/task/files/regions.csv` — region code to name mapping

## Pipeline Steps

### Step 1: Normalize Companies
- Read companies.json
- Flatten nested addresses
- Assign a `company_id` (sequential, starting at 1)
- Write to `/task/output/step1_companies.csv`

### Step 2: Enrich Transactions
- Read transactions.csv
- Join with step1_companies.csv on company name (fuzzy match: case-insensitive, strip whitespace)
- Join with regions.csv to add region_name
- Calculate `tax_amount` = amount * tax_rate
- Calculate `total` = amount + tax_amount
- Write to `/task/output/step2_enriched.csv`

### Step 3: Analytics
- From step2, compute:
  - Revenue per company (sum of `total`)
  - Revenue per region
  - Top 3 companies by revenue
  - Average transaction size
  - Total tax collected
- Write to `/task/output/step3_analytics.json`

### Step 4: Executive Summary
- Generate a plain text report at `/task/output/step4_report.txt`
- Must include: title, date, total revenue, total tax, top 3 companies with amounts, revenue by region
- Professional formatting with headers and alignment

### Step 5: SQLite Archive
- Create `/task/output/pipeline.db` with tables: `companies`, `transactions`, `analytics`
- Insert all processed data
- Create an index on `transactions.company_id`
