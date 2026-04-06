# Phone Number Extraction & Normalization

You have a messy text file at `/task/files/raw_contacts.txt` containing Quebec business contacts scraped from various sources. Phone numbers appear in many formats mixed with other text.

## Task

1. Read the raw text file
2. Extract ALL phone numbers (Quebec formats: 514, 418, 450, 438, 581, 819, 873)
3. Normalize every number to format: `+1-XXX-XXX-XXXX`
4. Deduplicate (same number in different formats = 1 entry)
5. For each number, extract the associated business name (if on the same line or preceding line)
6. Write results to `/task/output/phones.csv` with columns: `phone`, `business`, `source_line`
7. Write stats to `/task/output/stats.json`:
   - `total_raw_matches`: how many phone patterns found before dedup
   - `total_unique`: unique numbers after normalization + dedup
   - `by_area_code`: object with area code as key, count as value
   - `formats_found`: list of distinct formats encountered (e.g., "(514) 555-1234", "514.555.1234")
