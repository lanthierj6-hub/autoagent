#!/bin/bash
SCORE=0.0

# Step 1: orders_full.csv exists with correct row count
if [ -f "/task/output/orders_full.csv" ]; then
    COUNT=$(python3 -c "import csv; print(len(list(csv.DictReader(open('/task/output/orders_full.csv')))))" 2>/dev/null)
    if [ "$COUNT" = "20" ]; then
        SCORE=$(echo "$SCORE + 0.1" | bc)
        echo "PASS: orders_full.csv has 20 rows"
    else
        echo "FAIL: orders_full.csv has $COUNT rows, expected 20"
    fi

    # Check required columns
    COLS=$(python3 -c "
import csv
with open('/task/output/orders_full.csv') as f:
    reader = csv.DictReader(f)
    fields = reader.fieldnames
    required = ['order_id','date','customer_name','customer_region','product_name','category','quantity','unit_price','discount_pct','subtotal','tax','total']
    print(sum(1 for r in required if r in fields))
" 2>/dev/null)
    if [ "$COLS" = "12" ]; then
        SCORE=$(echo "$SCORE + 0.05" | bc)
        echo "PASS: all 12 columns present"
    else
        echo "FAIL: only $COLS/12 columns"
    fi

    # Check discount logic
    DISC_OK=$(python3 -c "
import csv
ok = 0
with open('/task/output/orders_full.csv') as f:
    for r in csv.DictReader(f):
        qty = int(r['quantity'])
        disc = float(r['discount_pct'])
        if qty >= 50 and abs(disc - 15) < 0.1: ok += 1
        elif qty >= 25 and qty < 50 and abs(disc - 10) < 0.1: ok += 1
        elif qty >= 10 and qty < 25 and abs(disc - 5) < 0.1: ok += 1
        elif qty < 10 and abs(disc - 0) < 0.1: ok += 1
print(ok)
" 2>/dev/null)
    if [ "$DISC_OK" = "20" ]; then
        SCORE=$(echo "$SCORE + 0.1" | bc)
        echo "PASS: all discounts correct"
    else
        echo "FAIL: $DISC_OK/20 discounts correct"
    fi

    # Check tax and total calculations
    CALC_OK=$(python3 -c "
import csv
ok = 0
with open('/task/output/orders_full.csv') as f:
    for r in csv.DictReader(f):
        qty = int(r['quantity'])
        price = float(r['unit_price'])
        disc = float(r['discount_pct']) / 100
        subtotal = float(r['subtotal'])
        tax = float(r['tax'])
        total = float(r['total'])
        expected_sub = round(qty * price * (1 - disc), 2)
        expected_tax = round(expected_sub * 0.14975, 2)
        expected_total = round(expected_sub + expected_tax, 2)
        if abs(subtotal - expected_sub) < 0.05 and abs(tax - expected_tax) < 0.05 and abs(total - expected_total) < 0.05:
            ok += 1
print(ok)
" 2>/dev/null)
    if [ "$CALC_OK" = "20" ]; then
        SCORE=$(echo "$SCORE + 0.15" | bc)
        echo "PASS: all calculations correct"
    else
        echo "FAIL: $CALC_OK/20 calculations correct"
    fi

    # Check sorted by date
    SORTED=$(python3 -c "
import csv
with open('/task/output/orders_full.csv') as f:
    dates = [r['date'] for r in csv.DictReader(f)]
print('yes' if dates == sorted(dates) else 'no')
" 2>/dev/null)
    if [ "$SORTED" = "yes" ]; then
        SCORE=$(echo "$SCORE + 0.05" | bc)
        echo "PASS: sorted by date"
    else
        echo "FAIL: not sorted by date"
    fi
else
    echo "FAIL: orders_full.csv missing"
fi

# Step 2: customer_report.json
if [ -f "/task/output/customer_report.json" ]; then
    CHECKS=$(python3 -c "
import json
r = json.load(open('/task/output/customer_report.json'))
c = 0
if r.get('total_customers') == 10: c += 1
if r.get('customers_with_orders', 0) > 0: c += 1
if r.get('customers_without_orders', -1) >= 0: c += 1
if 'top_5_by_revenue' in r and len(r['top_5_by_revenue']) == 5: c += 1
if 'revenue_by_region' in r and len(r['revenue_by_region']) >= 4: c += 1
if 'avg_order_value' in r and r['avg_order_value'] > 0: c += 1
# Verify C010 has no orders
if r.get('customers_without_orders', 0) >= 1: c += 1
print(c)
" 2>/dev/null)
    if [ "$CHECKS" -ge 6 ]; then
        SCORE=$(echo "$SCORE + 0.2" | bc)
        echo "PASS: customer report complete ($CHECKS/7)"
    else
        echo "FAIL: customer report incomplete ($CHECKS/7)"
    fi
else
    echo "FAIL: customer_report.json missing"
fi

# Step 3: product_report.json
if [ -f "/task/output/product_report.json" ]; then
    CHECKS=$(python3 -c "
import json
r = json.load(open('/task/output/product_report.json'))
c = 0
if r.get('total_products') == 8: c += 1
if 'units_sold_by_category' in r: c += 1
if 'revenue_by_category' in r: c += 1
if 'top_3_products' in r and len(r['top_3_products']) == 3: c += 1
if 'products_never_ordered' in r: c += 1
# P007 and P008 were never ordered
never = r.get('products_never_ordered', [])
if 'Anti-Slip Additive' in never or 'P007' in str(never): c += 1
if 'UV Resistant Topcoat' in never or 'P008' in str(never): c += 1
print(c)
" 2>/dev/null)
    if [ "$CHECKS" -ge 6 ]; then
        SCORE=$(echo "$SCORE + 0.2" | bc)
        echo "PASS: product report complete ($CHECKS/7)"
    else
        echo "FAIL: product report incomplete ($CHECKS/7)"
    fi
else
    echo "FAIL: product_report.json missing"
fi

# Step 4: executive_summary.txt
if [ -f "/task/output/executive_summary.txt" ]; then
    SIZE=$(wc -c < "/task/output/executive_summary.txt" | tr -d ' ')
    if [ "$SIZE" -gt 300 ]; then
        SCORE=$(echo "$SCORE + 0.05" | bc)
        echo "PASS: executive summary has content ($SIZE bytes)"
    fi
    MENTIONS=$(python3 -c "
text = open('/task/output/executive_summary.txt').read().lower()
c = 0
if 'revenue' in text: c += 1
if 'order' in text: c += 1
if 'region' in text: c += 1
if 'discount' in text: c += 1
print(c)
" 2>/dev/null)
    if [ "$MENTIONS" -ge 3 ]; then
        SCORE=$(echo "$SCORE + 0.1" | bc)
        echo "PASS: summary mentions key metrics ($MENTIONS/4)"
    else
        echo "FAIL: summary missing key metrics ($MENTIONS/4)"
    fi
else
    echo "FAIL: executive_summary.txt missing"
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
