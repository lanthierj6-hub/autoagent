#!/bin/bash
SCORE=0.0
OUTPUT_CSV="/task/output/businesses.csv"
OUTPUT_JSON="/task/output/meta.json"

if [ ! -f "$OUTPUT_CSV" ]; then
    echo "FAIL: $OUTPUT_CSV not found"
    echo "$SCORE" > /logs/reward.txt
    exit 0
fi
SCORE=$(echo "$SCORE + 0.2" | bc)

if [ ! -f "$OUTPUT_JSON" ]; then
    echo "FAIL: $OUTPUT_JSON not found"
    echo "$SCORE" > /logs/reward.txt
    exit 0
fi
SCORE=$(echo "$SCORE + 0.1" | bc)

# Check row count (6 records + header = 7)
LINE_COUNT=$(wc -l < "$OUTPUT_CSV" | tr -d ' ')
if [ "$LINE_COUNT" -eq 7 ]; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PASS: row count correct (7)"
else
    echo "FAIL: expected 7 lines, got $LINE_COUNT"
fi

# Check meta total_records
TOTAL=$(python3 -c "import json; print(json.load(open('$OUTPUT_JSON'))['total_records'])" 2>/dev/null)
if [ "$TOTAL" = "6" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: total_records=6"
else
    echo "FAIL: total_records=$TOTAL, expected 6"
fi

# Check sorted by name (first data row should be Alliance)
FIRST=$(python3 -c "
import csv
with open('$OUTPUT_CSV') as f:
    rows = list(csv.DictReader(f))
    print(rows[0].get('name', ''))
" 2>/dev/null)
if echo "$FIRST" | grep -qi "alliance"; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PASS: sorted by name"
else
    echo "FAIL: first row is '$FIRST', expected Alliance..."
fi

# Check that nested fields are flattened with dot notation
HEADER=$(head -1 "$OUTPUT_CSV")
if echo "$HEADER" | grep -q "contact.email" && echo "$HEADER" | grep -q "address.city"; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PASS: dot notation in headers"
else
    echo "FAIL: headers don't use dot notation: $HEADER"
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
