# JSON to CSV Transformation

You have a JSON file at `/task/files/api_response.json` containing an array of business objects from an API response.

## Task

1. Read the JSON file
2. Flatten nested objects into a flat CSV structure
3. Column naming: use dot notation for nested fields (e.g., `address.city`, `contact.email`)
4. Handle missing fields gracefully (empty string for missing values)
5. Sort rows by `name` alphabetically
6. Write the result to `/task/output/businesses.csv`
7. Write metadata to `/task/output/meta.json`:
   - `total_records`: number of records
   - `columns`: list of column names in the CSV
   - `missing_fields_count`: total number of missing field values across all records
