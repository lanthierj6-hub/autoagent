#!/bin/bash
SCORE=0.0

# Step 1: CSV exists
if [ -f "/task/output/sales_clean.csv" ]; then
    echo "PASS: sales_clean.csv exists"
    SCORE=$(echo "$SCORE + 0.1" | bc)
else
    echo "FAIL: sales_clean.csv missing"
    echo "SCORE: 0.0"
    echo "0.0" > /logs/reward.txt
    exit 0
fi

# Step 2: Correct row count (12 valid records after dedup + validation)
COUNT=$(python3 -c "import csv; print(len(list(csv.DictReader(open('/task/output/sales_clean.csv')))))" 2>/dev/null)
if [ "$COUNT" = "12" ]; then
    SCORE=$(echo "$SCORE + 0.15" | bc)
    echo "PASS: 12 records"
else
    echo "FAIL: $COUNT records, expected 12"
fi

# Step 3: Tax calculation correct (spot check first row)
TAX_OK=$(python3 -c "
import csv
with open('/task/output/sales_clean.csv') as f:
    rows = list(csv.DictReader(f))
ok = 0
for r in rows:
    qty = float(r['quantity'])
    price = float(r['unit_price'])
    expected_total = round(qty * price, 2)
    expected_tax = round(expected_total * 0.14975, 2)
    actual_total = float(r['total'])
    actual_tax = float(r['tax'])
    if abs(actual_total - expected_total) < 0.02 and abs(actual_tax - expected_tax) < 0.02:
        ok += 1
print(ok)
" 2>/dev/null)
if [ "$TAX_OK" = "12" ]; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PASS: all tax calculations correct"
else
    echo "FAIL: $TAX_OK/12 rows have correct tax"
fi

# Step 4: Sorted by date ascending
SORTED=$(python3 -c "
import csv
with open('/task/output/sales_clean.csv') as f:
    rows = list(csv.DictReader(f))
dates = [r['date'] for r in rows]
print('yes' if dates == sorted(dates) else 'no')
" 2>/dev/null)
if [ "$SORTED" = "yes" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: sorted by date"
else
    echo "FAIL: not sorted by date"
fi

# Step 5: Summary JSON exists and correct
if [ -f "/task/output/summary.json" ]; then
    CHECKS=$(python3 -c "
import json
s = json.load(open('/task/output/summary.json'))
c = 0
if s.get('records_processed') == 12: c += 1
if s.get('records_rejected') == 3: c += 1
if 'total_revenue' in s and s['total_revenue'] > 0: c += 1
if 'top_product' in s and len(s['top_product']) > 0: c += 1
if 'avg_order_value' in s and s['avg_order_value'] > 0: c += 1
print(c)
" 2>/dev/null)
    if [ "$CHECKS" = "5" ]; then
        SCORE=$(echo "$SCORE + 0.25" | bc)
        echo "PASS: summary complete (5/5)"
    else
        echo "FAIL: summary incomplete ($CHECKS/5)"
    fi
else
    echo "FAIL: summary.json missing"
fi

# Step 6: Grand total = total + tax for all rows
GT_OK=$(python3 -c "
import csv
with open('/task/output/sales_clean.csv') as f:
    rows = list(csv.DictReader(f))
ok = sum(1 for r in rows if abs(float(r['grand_total']) - float(r['total']) - float(r['tax'])) < 0.02)
print(ok)
" 2>/dev/null)
if [ "$GT_OK" = "12" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: grand_total = total + tax for all rows"
else
    echo "FAIL: $GT_OK/12 grand_total correct"
fi

# Step 7: No duplicate rows in output
UNIQ=$(python3 -c "
import csv
with open('/task/output/sales_clean.csv') as f:
    rows = list(csv.DictReader(f))
keys = set()
for r in rows:
    k = (r['date'], r['product'], r['region'], r['quantity'])
    keys.add(k)
print('yes' if len(keys) == len(rows) else 'no')
" 2>/dev/null)
if [ "$UNIQ" = "yes" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: no duplicates"
else
    echo "FAIL: duplicates found"
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
