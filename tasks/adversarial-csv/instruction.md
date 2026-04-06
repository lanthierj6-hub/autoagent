# Adversarial CSV Cleaning

You are given a deliberately malformed CSV file (`files/dirty_data.csv`) that contains common real-world data quality issues. Your job is to produce a clean, validated output.

## Input Issues (you must handle ALL of these)
- BOM (byte order mark) at the start of the file
- Mixed line endings (CRLF, LF, CR)
- Fields with embedded newlines inside quoted values
- Fields containing the delimiter (comma) inside quotes
- Unicode homoglyphs (e.g., Cyrillic "а" instead of Latin "a", fullwidth digits)
- Leading/trailing whitespace in field values
- Empty rows interspersed
- Duplicate header row in the middle of the data
- Inconsistent quoting (some fields quoted, some not)
- A field containing a literal `"NULL"` string vs actual empty/missing values
- Dates in 3 different formats: YYYY-MM-DD, DD/MM/YYYY, MM-DD-YYYY

## Required Output

### `/task/output/clean_data.csv`
Columns: `id,name,email,amount,date,status`
- `id`: integer, sequential starting from 1
- `name`: normalized Unicode (NFC), trimmed, title case
- `email`: lowercased, trimmed, must contain @ and . — rows with invalid email get `INVALID` in email field
- `amount`: float with 2 decimal places, negative values become 0.00
- `date`: all converted to YYYY-MM-DD format
- `status`: one of `active`, `inactive`, `pending` (lowercased) — anything else becomes `unknown`
- Remove exact duplicate rows (after normalization)
- Remove rows that are completely empty
- Remove duplicate header rows
- Sort by date ascending, then by name ascending
- Exactly 15 clean rows expected

### `/task/output/cleaning_report.json`
```json
{
  "total_raw_rows": <int - including header dupes and empty rows>,
  "rows_after_cleaning": 15,
  "duplicates_removed": <int>,
  "invalid_emails": <int>,
  "negative_amounts_fixed": <int>,
  "unicode_normalizations": <int>,
  "date_formats_converted": {"YYYY-MM-DD": <int>, "DD/MM/YYYY": <int>, "MM-DD-YYYY": <int>}
}
```
