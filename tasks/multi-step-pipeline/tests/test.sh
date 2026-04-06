#!/bin/bash
SCORE=0.0

# Step 1: Companies CSV
if [ -f "/task/output/step1_companies.csv" ]; then
    COUNT=$(python3 -c "import csv; print(len(list(csv.DictReader(open('/task/output/step1_companies.csv')))))" 2>/dev/null)
    if [ "$COUNT" = "8" ]; then
        SCORE=$(echo "$SCORE + 0.15" | bc)
        echo "PASS: step1 has 8 companies"
    else
        echo "FAIL: step1 has $COUNT companies, expected 8"
    fi
else
    echo "FAIL: step1_companies.csv missing"
fi

# Step 2: Enriched transactions
if [ -f "/task/output/step2_enriched.csv" ]; then
    COUNT=$(python3 -c "import csv; print(len(list(csv.DictReader(open('/task/output/step2_enriched.csv')))))" 2>/dev/null)
    if [ "$COUNT" = "20" ]; then
        SCORE=$(echo "$SCORE + 0.1" | bc)
        echo "PASS: step2 has 20 transactions"
    fi

    # Check fuzzy matching worked (novus epoxy variants should all match)
    MATCHED=$(python3 -c "
import csv
with open('/task/output/step2_enriched.csv') as f:
    rows = list(csv.DictReader(f))
    has_id = sum(1 for r in rows if r.get('company_id','').strip())
    has_total = sum(1 for r in rows if r.get('total','').strip())
    print(f'{has_id},{has_total}')
" 2>/dev/null)
    IDS=$(echo "$MATCHED" | cut -d, -f1)
    TOTALS=$(echo "$MATCHED" | cut -d, -f2)
    if [ "$IDS" = "20" ] && [ "$TOTALS" = "20" ]; then
        SCORE=$(echo "$SCORE + 0.15" | bc)
        echo "PASS: all rows have company_id and total"
    else
        echo "FAIL: missing company_id($IDS) or total($TOTALS)"
    fi
else
    echo "FAIL: step2_enriched.csv missing"
fi

# Step 3: Analytics JSON
if [ -f "/task/output/step3_analytics.json" ]; then
    CHECKS=$(python3 -c "
import json
a = json.load(open('/task/output/step3_analytics.json'))
c = 0
if 'revenue_per_company' in a: c += 1
if 'revenue_per_region' in a: c += 1
if 'top_3_companies' in a and len(a['top_3_companies']) == 3: c += 1
if 'average_transaction_size' in a: c += 1
if 'total_tax_collected' in a: c += 1
print(c)
" 2>/dev/null)
    if [ "$CHECKS" = "5" ]; then
        SCORE=$(echo "$SCORE + 0.2" | bc)
        echo "PASS: analytics complete (5/5)"
    else
        echo "FAIL: analytics incomplete ($CHECKS/5)"
    fi
else
    echo "FAIL: step3_analytics.json missing"
fi

# Step 4: Report
if [ -f "/task/output/step4_report.txt" ]; then
    HAS_CONTENT=$(wc -c < "/task/output/step4_report.txt" | tr -d ' ')
    if [ "$HAS_CONTENT" -gt 200 ]; then
        SCORE=$(echo "$SCORE + 0.1" | bc)
        echo "PASS: report has content ($HAS_CONTENT bytes)"
    fi

    if grep -qi "revenue" "/task/output/step4_report.txt" && grep -qi "tax" "/task/output/step4_report.txt"; then
        SCORE=$(echo "$SCORE + 0.1" | bc)
        echo "PASS: report mentions revenue and tax"
    fi
else
    echo "FAIL: step4_report.txt missing"
fi

# Step 5: SQLite
if [ -f "/task/output/pipeline.db" ]; then
    TABLES=$(sqlite3 "/task/output/pipeline.db" ".tables" 2>/dev/null | tr -s ' ' '\n' | grep -c -E "companies|transactions|analytics")
    if [ "$TABLES" -ge 3 ]; then
        SCORE=$(echo "$SCORE + 0.1" | bc)
        echo "PASS: all 3 tables exist"
    else
        echo "FAIL: only $TABLES/3 tables"
    fi

    IDX=$(sqlite3 "/task/output/pipeline.db" ".indices transactions" 2>/dev/null | wc -l)
    if [ "$IDX" -ge 1 ]; then
        SCORE=$(echo "$SCORE + 0.1" | bc)
        echo "PASS: index on transactions"
    fi
else
    echo "FAIL: pipeline.db missing"
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
