#!/bin/bash
SCORE=0.0

# Step 1: clean_data.csv exists
if [ ! -f "/task/output/clean_data.csv" ]; then
    echo "FAIL: clean_data.csv missing"
    echo "SCORE: 0.0"
    echo "0.0" > /logs/reward.txt
    exit 0
fi

# Step 2: Correct row count (15)
COUNT=$(python3 -c "import csv; print(len(list(csv.DictReader(open('/task/output/clean_data.csv')))))" 2>/dev/null)
if [ "$COUNT" = "15" ]; then
    SCORE=$(echo "$SCORE + 0.15" | bc)
    echo "PASS: 15 rows"
else
    echo "FAIL: $COUNT rows, expected 15"
fi

# Step 3: No BOM in output
BOM=$(python3 -c "
d = open('/task/output/clean_data.csv','rb').read(3)
print('yes' if d[:3] == b'\\xef\\xbb\\xbf' else 'no')
" 2>/dev/null)
if [ "$BOM" = "no" ]; then
    SCORE=$(echo "$SCORE + 0.05" | bc)
    echo "PASS: no BOM"
else
    echo "FAIL: BOM still present"
fi

# Step 4: Unicode normalized (no combining characters, no Cyrillic homoglyphs)
UNICODE_OK=$(python3 -c "
import csv, unicodedata
with open('/task/output/clean_data.csv') as f:
    rows = list(csv.DictReader(f))
ok = True
for r in rows:
    name = r.get('name','')
    nfc = unicodedata.normalize('NFC', name)
    # Check no Cyrillic characters remain
    for ch in name:
        if 'CYRILLIC' in unicodedata.name(ch, ''):
            ok = False
            break
print('yes' if ok else 'no')
" 2>/dev/null)
if [ "$UNICODE_OK" = "yes" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: Unicode normalized"
else
    echo "FAIL: Unicode issues remain"
fi

# Step 5: All emails valid or INVALID
EMAIL_OK=$(python3 -c "
import csv
with open('/task/output/clean_data.csv') as f:
    rows = list(csv.DictReader(f))
ok = 0
for r in rows:
    e = r.get('email','').strip()
    if e == 'INVALID' or ('@' in e and '.' in e):
        ok += 1
print(ok)
" 2>/dev/null)
if [ "$EMAIL_OK" = "15" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: all emails valid or INVALID"
else
    echo "FAIL: $EMAIL_OK/15 emails valid"
fi

# Step 6: No negative amounts
NEG=$(python3 -c "
import csv
with open('/task/output/clean_data.csv') as f:
    rows = list(csv.DictReader(f))
neg = sum(1 for r in rows if float(r.get('amount', 0)) < 0)
print(neg)
" 2>/dev/null)
if [ "$NEG" = "0" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: no negative amounts"
else
    echo "FAIL: $NEG negative amounts remain"
fi

# Step 7: All dates in YYYY-MM-DD format
DATE_OK=$(python3 -c "
import csv, re
with open('/task/output/clean_data.csv') as f:
    rows = list(csv.DictReader(f))
ok = sum(1 for r in rows if re.match(r'^\d{4}-\d{2}-\d{2}$', r.get('date','').strip()))
print(ok)
" 2>/dev/null)
if [ "$DATE_OK" = "15" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: all dates YYYY-MM-DD"
else
    echo "FAIL: $DATE_OK/15 dates correct"
fi

# Step 8: Status values valid
STATUS_OK=$(python3 -c "
import csv
valid = {'active','inactive','pending','unknown'}
with open('/task/output/clean_data.csv') as f:
    rows = list(csv.DictReader(f))
ok = sum(1 for r in rows if r.get('status','').strip() in valid)
print(ok)
" 2>/dev/null)
if [ "$STATUS_OK" = "15" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: all statuses valid"
else
    echo "FAIL: $STATUS_OK/15 statuses valid"
fi

# Step 9: Sorted by date then name
SORTED=$(python3 -c "
import csv
with open('/task/output/clean_data.csv') as f:
    rows = list(csv.DictReader(f))
keys = [(r['date'], r['name'].lower()) for r in rows]
print('yes' if keys == sorted(keys) else 'no')
" 2>/dev/null)
if [ "$SORTED" = "yes" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: sorted by date then name"
else
    echo "FAIL: not sorted correctly"
fi

# Step 10: cleaning_report.json exists and complete
if [ -f "/task/output/cleaning_report.json" ]; then
    CHECKS=$(python3 -c "
import json
r = json.load(open('/task/output/cleaning_report.json'))
c = 0
if r.get('rows_after_cleaning') == 15: c += 1
if 'total_raw_rows' in r and r['total_raw_rows'] > 15: c += 1
if 'duplicates_removed' in r and r['duplicates_removed'] >= 2: c += 1
if 'invalid_emails' in r and r['invalid_emails'] >= 1: c += 1
if 'date_formats_converted' in r: c += 1
print(c)
" 2>/dev/null)
    if [ "$CHECKS" -ge 4 ]; then
        SCORE=$(echo "$SCORE + 0.2" | bc)
        echo "PASS: cleaning report complete ($CHECKS/5)"
    else
        echo "FAIL: cleaning report incomplete ($CHECKS/5)"
    fi
else
    echo "FAIL: cleaning_report.json missing"
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
