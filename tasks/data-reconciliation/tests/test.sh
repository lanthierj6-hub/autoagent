#!/bin/bash
SCORE=0.0

# Step 1: unified_customers.csv exists
if [ ! -f "/task/output/unified_customers.csv" ]; then
    echo "FAIL: unified_customers.csv missing"
    echo "SCORE: 0.0"
    echo "0.0" > /logs/reward.txt
    exit 0
fi

# Step 2: Correct row count (10 unique customers)
COUNT=$(python3 -c "import csv; print(len(list(csv.DictReader(open('/task/output/unified_customers.csv')))))" 2>/dev/null)
if [ "$COUNT" = "10" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: 10 unified records"
else
    echo "FAIL: $COUNT records, expected 10"
fi

# Step 3: All required columns present
COLS=$(python3 -c "
import csv
with open('/task/output/unified_customers.csv') as f:
    fields = csv.DictReader(f).fieldnames
required = ['customer_id','name','email','phone','region','tier','total_invoiced','total_paid','outstanding','payment_terms','last_contact','contact_count_90d','nps_score','churn_risk','health_score','recommended_action','data_completeness']
print(sum(1 for r in required if r in fields))
" 2>/dev/null)
if [ "$COLS" = "17" ]; then
    SCORE=$(echo "$SCORE + 0.05" | bc)
    echo "PASS: all 17 columns"
else
    echo "FAIL: $COLS/17 columns"
fi

# Step 4: Sorted by customer_id
SORTED=$(python3 -c "
import csv
with open('/task/output/unified_customers.csv') as f:
    ids = [r['customer_id'] for r in csv.DictReader(f)]
print('yes' if ids == sorted(ids) else 'no')
" 2>/dev/null)
if [ "$SORTED" = "yes" ]; then
    SCORE=$(echo "$SCORE + 0.05" | bc)
    echo "PASS: sorted by customer_id"
fi

# Step 5: CRM data is authoritative for names
NAME_OK=$(python3 -c "
import csv
with open('/task/output/unified_customers.csv') as f:
    rows = {r['customer_id']: r for r in csv.DictReader(f)}
ok = 0
# NE-001 should have CRM name
if rows.get('NE-001', {}).get('name', '') == 'Garage Pro Québec': ok += 1
# NE-009 not in CRM - should be N/A
if rows.get('NE-009', {}).get('name', '') == 'N/A': ok += 1
# NE-010 not in CRM - should be N/A
if rows.get('NE-010', {}).get('name', '') == 'N/A': ok += 1
print(ok)
" 2>/dev/null)
if [ "$NAME_OK" = "3" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: CRM authority correct for names"
else
    echo "FAIL: name authority wrong ($NAME_OK/3)"
fi

# Step 6: Billing data authoritative for financials
FIN_OK=$(python3 -c "
import csv
with open('/task/output/unified_customers.csv') as f:
    rows = {r['customer_id']: r for r in csv.DictReader(f)}
ok = 0
# NE-004 has outstanding 15200
if abs(float(rows.get('NE-004', {}).get('outstanding', -1)) - 15200.0) < 0.01: ok += 1
# NE-007 not in billing - should be 0
if float(rows.get('NE-007', {}).get('total_invoiced', -1)) == 0: ok += 1
# NE-006 total_invoiced = 89500
if abs(float(rows.get('NE-006', {}).get('total_invoiced', -1)) - 89500.0) < 0.01: ok += 1
print(ok)
" 2>/dev/null)
if [ "$FIN_OK" = "3" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: billing authority correct"
else
    echo "FAIL: billing authority wrong ($FIN_OK/3)"
fi

# Step 7: Health score calculation
HS_OK=$(python3 -c "
import csv
with open('/task/output/unified_customers.csv') as f:
    rows = {r['customer_id']: r for r in csv.DictReader(f)}
ok = 0
# NE-001: nps=9, contact=12, outstanding=0 -> 9*10 + 12*2 - 0 = 114.0
r = rows.get('NE-001', {})
hs = float(r.get('health_score', 0))
if abs(hs - 114.0) < 0.2: ok += 1
# NE-004: nps=10, contact=15, outstanding=15200 -> 10*10 + 15*2 - 15.2 = 114.8
r = rows.get('NE-004', {})
hs = float(r.get('health_score', 0))
if abs(hs - 114.8) < 0.2: ok += 1
# NE-005: nps=null->5, contact=0, outstanding=0 -> 5*10 + 0 - 0 = 50.0
r = rows.get('NE-005', {})
hs = float(r.get('health_score', 0))
if abs(hs - 50.0) < 0.2: ok += 1
print(ok)
" 2>/dev/null)
if [ "$HS_OK" = "3" ]; then
    SCORE=$(echo "$SCORE + 0.15" | bc)
    echo "PASS: health scores correct"
else
    echo "FAIL: health scores wrong ($HS_OK/3)"
fi

# Step 8: Recommended actions correct
ACT_OK=$(python3 -c "
import csv
with open('/task/output/unified_customers.csv') as f:
    rows = {r['customer_id']: r for r in csv.DictReader(f)}
ok = 0
# NE-001 health=114 -> upsell
if rows.get('NE-001', {}).get('recommended_action') == 'upsell': ok += 1
# NE-005 health=50 -> nurture
if rows.get('NE-005', {}).get('recommended_action') == 'nurture': ok += 1
# NE-003 nps=4, contact=1, outstanding=0 -> 4*10+1*2-0=42 -> nurture
if rows.get('NE-003', {}).get('recommended_action') == 'nurture': ok += 1
print(ok)
" 2>/dev/null)
if [ "$ACT_OK" = "3" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: recommended actions correct"
else
    echo "FAIL: recommended actions wrong ($ACT_OK/3)"
fi

# Step 9: Reconciliation report
if [ -f "/task/output/reconciliation_report.json" ]; then
    CHECKS=$(python3 -c "
import json
r = json.load(open('/task/output/reconciliation_report.json'))
c = 0
if r.get('total_unified_records') == 10: c += 1
if r.get('in_all_sources') == 6: c += 1
if r.get('in_two_sources') == 2: c += 1
if r.get('in_one_source') == 2: c += 1
if r.get('top_customer_by_revenue') == 'NE-006': c += 1
if 'total_outstanding' in r and r['total_outstanding'] > 0: c += 1
if 'action_distribution' in r: c += 1
print(c)
" 2>/dev/null)
    if [ "$CHECKS" -ge 5 ]; then
        SCORE=$(echo "$SCORE + 0.25" | bc)
        echo "PASS: reconciliation report complete ($CHECKS/7)"
    else
        echo "FAIL: reconciliation report incomplete ($CHECKS/7)"
    fi
else
    echo "FAIL: reconciliation_report.json missing"
fi

# Step 10: Tier assignment for non-CRM customers
TIER_OK=$(python3 -c "
import csv
with open('/task/output/unified_customers.csv') as f:
    rows = {r['customer_id']: r for r in csv.DictReader(f)}
ok = 0
# NE-009: not in CRM, invoiced=5400 -> bronze
if rows.get('NE-009', {}).get('tier') == 'bronze': ok += 1
# NE-010: not in CRM, not in billing (0) -> bronze
if rows.get('NE-010', {}).get('tier') == 'bronze': ok += 1
print(ok)
" 2>/dev/null)
if [ "$TIER_OK" = "2" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: tier assignment correct for non-CRM customers"
else
    echo "FAIL: tier assignment wrong ($TIER_OK/2)"
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
