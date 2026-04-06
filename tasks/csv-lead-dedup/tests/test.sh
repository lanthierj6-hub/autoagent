#!/bin/bash
# Verifier for csv-lead-dedup task
# Writes score (0.0-1.0) to /logs/reward.txt

SCORE=0.0
OUTPUT_CSV="/task/output/leads_clean.csv"
OUTPUT_JSON="/task/output/summary.json"

# Check output files exist (0.2 each)
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

# Check CSV row count (should be 10 unique emails + header = 11 lines)
LINE_COUNT=$(wc -l < "$OUTPUT_CSV" | tr -d ' ')
if [ "$LINE_COUNT" -eq 11 ]; then
    SCORE=$(echo "$SCORE + 0.3" | bc)
    echo "PASS: correct row count (11)"
else
    echo "FAIL: expected 11 lines, got $LINE_COUNT"
fi

# Check summary JSON values
TOTAL_INPUT=$(python3 -c "import json; print(json.load(open('$OUTPUT_JSON'))['total_input'])" 2>/dev/null)
TOTAL_OUTPUT=$(python3 -c "import json; print(json.load(open('$OUTPUT_JSON'))['total_output'])" 2>/dev/null)
DUPES=$(python3 -c "import json; print(json.load(open('$OUTPUT_JSON'))['duplicates_removed'])" 2>/dev/null)

if [ "$TOTAL_INPUT" = "15" ] && [ "$TOTAL_OUTPUT" = "10" ] && [ "$DUPES" = "5" ]; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PASS: summary counts correct"
else
    echo "FAIL: summary counts wrong (input=$TOTAL_INPUT output=$TOTAL_OUTPUT dupes=$DUPES)"
fi

# Check sorted by email
SORTED=$(python3 -c "
import csv
with open('$OUTPUT_CSV') as f:
    rows = list(csv.DictReader(f))
    emails = [r['email'].lower() for r in rows]
    print('yes' if emails == sorted(emails) else 'no')
" 2>/dev/null)

if [ "$SORTED" = "yes" ]; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PASS: sorted by email"
else
    echo "FAIL: not sorted by email"
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
