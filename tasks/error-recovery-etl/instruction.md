# Error Recovery ETL

You are given a broken Python ETL script (`files/etl_pipeline.py`) and its input data (`files/sales_raw.json`).

The script has **6 deliberate bugs** that cause it to crash or produce wrong output. Your job:

1. **Read** the script and input data carefully
2. **Fix all 6 bugs** so the script runs correctly
3. **Run** the fixed script: `python3 /task/files/etl_pipeline.py`
4. The script should produce `/task/output/sales_clean.csv` and `/task/output/summary.json`

## Expected Output

### sales_clean.csv
- Columns: `date,product,region,quantity,unit_price,total,tax,grand_total`
- 12 rows of clean data (after dedup and validation)
- `total = quantity * unit_price`
- `tax = total * 0.14975` (Quebec GST+QST)
- `grand_total = total + tax`
- Sorted by date ascending

### summary.json
```json
{
  "total_revenue": <sum of all grand_total>,
  "top_product": "<product with highest total revenue>",
  "records_processed": 12,
  "records_rejected": 3,
  "avg_order_value": <mean of grand_total>
}
```

## Hints About the Bugs
The bugs are realistic mistakes: off-by-one, wrong variable name, missing import, incorrect formula, encoding issue, and a logic error in dedup. You must find them by reading the code — no hints about which lines.
