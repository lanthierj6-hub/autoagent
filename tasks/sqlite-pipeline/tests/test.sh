#!/bin/bash
SCORE=0.0
DB="/task/output/pipeline.db"
ANALYTICS="/task/output/analytics.json"

if [ ! -f "$DB" ]; then
    echo "FAIL: $DB not found"
    echo "$SCORE" > /logs/reward.txt
    exit 0
fi
SCORE=$(echo "$SCORE + 0.15" | bc)

if [ ! -f "$ANALYTICS" ]; then
    echo "FAIL: $ANALYTICS not found"
    echo "$SCORE" > /logs/reward.txt
    exit 0
fi
SCORE=$(echo "$SCORE + 0.1" | bc)

# Check table exists and has correct row count
ROW_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM leads;" 2>/dev/null)
if [ "$ROW_COUNT" = "10" ]; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PASS: 10 leads in database"
else
    echo "FAIL: expected 10 rows, got $ROW_COUNT"
fi

# Check analytics values
python3 -c "
import json, sys
a = json.load(open('$ANALYTICS'))
checks = 0

if a.get('total_leads') == 10:
    checks += 1
    print('PASS: total_leads=10')
else:
    print(f'FAIL: total_leads={a.get(\"total_leads\")}')

by_status = a.get('by_status', {})
if by_status.get('new') == 3 and by_status.get('qualified') == 3:
    checks += 1
    print('PASS: by_status correct')
else:
    print(f'FAIL: by_status={by_status}')

avg = a.get('avg_score')
if avg is not None and 70.0 <= float(avg) <= 71.0:
    checks += 1
    print(f'PASS: avg_score={avg}')
else:
    print(f'FAIL: avg_score={avg}')

top = a.get('top_leads', [])
if len(top) == 3 and top[0].get('name') == 'Luc Tremblay':
    checks += 1
    print('PASS: top_leads correct')
else:
    print(f'FAIL: top_leads={top}')

qr = a.get('qualified_rate')
if qr is not None and 39.0 <= float(qr) <= 41.0:
    checks += 1
    print(f'PASS: qualified_rate={qr}')
else:
    print(f'FAIL: qualified_rate={qr}')

print(f'Analytics checks: {checks}/5')
sys.exit(0 if checks >= 3 else 1)
" 2>/dev/null
ANALYTICS_RESULT=$?

# Score based on analytics checks (0.55 remaining)
ANALYTICS_SCORE=$(python3 -c "
import json
a = json.load(open('$ANALYTICS'))
c = 0
if a.get('total_leads') == 10: c += 1
bs = a.get('by_status', {})
if bs.get('new') == 3 and bs.get('qualified') == 3: c += 1
avg = a.get('avg_score')
if avg and 70.0 <= float(avg) <= 71.0: c += 1
top = a.get('top_leads', [])
if len(top) == 3 and top[0].get('name') == 'Luc Tremblay': c += 1
qr = a.get('qualified_rate')
if qr and 39.0 <= float(qr) <= 41.0: c += 1
print(round(c * 0.11, 2))
" 2>/dev/null || echo "0.0")

SCORE=$(echo "$SCORE + $ANALYTICS_SCORE" | bc)
echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
