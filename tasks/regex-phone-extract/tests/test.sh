#!/bin/bash
SCORE=0.0
OUTPUT_CSV="/task/output/phones.csv"
OUTPUT_JSON="/task/output/stats.json"

if [ ! -f "$OUTPUT_CSV" ]; then echo "FAIL: CSV missing"; echo "$SCORE" > /logs/reward.txt; exit 0; fi
SCORE=$(echo "$SCORE + 0.1" | bc)

if [ ! -f "$OUTPUT_JSON" ]; then echo "FAIL: JSON missing"; echo "$SCORE" > /logs/reward.txt; exit 0; fi
SCORE=$(echo "$SCORE + 0.1" | bc)

# Check CSV has header with phone column
HEADER=$(head -1 "$OUTPUT_CSV")
if echo "$HEADER" | grep -qi "phone"; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
else
    echo "FAIL: CSV missing phone column"
fi

# Check unique phone count (should be ~20 unique numbers)
PHONE_COUNT=$(python3 -c "
import csv
with open('$OUTPUT_CSV') as f:
    rows = list(csv.DictReader(f))
    print(len(rows))
" 2>/dev/null)

if [ -n "$PHONE_COUNT" ] && [ "$PHONE_COUNT" -ge 18 ] && [ "$PHONE_COUNT" -le 22 ]; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PASS: phone count=$PHONE_COUNT (expected 18-22)"
else
    echo "FAIL: phone count=$PHONE_COUNT (expected 18-22)"
fi

# Check normalization format (+1-XXX-XXX-XXXX)
NORMALIZED=$(python3 -c "
import csv, re
with open('$OUTPUT_CSV') as f:
    rows = list(csv.DictReader(f))
    pattern = re.compile(r'^\+1-\d{3}-\d{3}-\d{4}$')
    valid = sum(1 for r in rows if pattern.match(r.get('phone','')))
    print(f'{valid}/{len(rows)}')
    print('yes' if valid == len(rows) else 'no')
" 2>/dev/null)

if echo "$NORMALIZED" | tail -1 | grep -q "yes"; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PASS: all phones normalized"
else
    echo "FAIL: not all phones normalized: $NORMALIZED"
fi

# Check stats JSON has required fields
STATS_OK=$(python3 -c "
import json
s = json.load(open('$OUTPUT_JSON'))
checks = 0
if 'total_raw_matches' in s and isinstance(s['total_raw_matches'], int): checks += 1
if 'total_unique' in s and isinstance(s['total_unique'], int): checks += 1
if 'by_area_code' in s and isinstance(s['by_area_code'], dict): checks += 1
if 'formats_found' in s and isinstance(s['formats_found'], list): checks += 1
print(checks)
" 2>/dev/null)

if [ "$STATS_OK" = "4" ]; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PASS: stats JSON complete"
else
    echo "FAIL: stats JSON incomplete ($STATS_OK/4)"
fi

# Check no duplicates
NO_DUPES=$(python3 -c "
import csv
with open('$OUTPUT_CSV') as f:
    rows = list(csv.DictReader(f))
    phones = [r.get('phone','') for r in rows]
    print('yes' if len(phones) == len(set(phones)) else 'no')
" 2>/dev/null)

if [ "$NO_DUPES" = "yes" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: no duplicates"
else
    echo "FAIL: duplicates found"
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
