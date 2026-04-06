#!/bin/bash
SCORE=0.0

# Step 1: scored_leads.json exists
if [ ! -f "/task/output/scored_leads.json" ]; then
    echo "FAIL: scored_leads.json missing"
    echo "SCORE: 0.0"
    echo "0.0" > /logs/reward.txt
    exit 0
fi

# Step 2: Correct number of leads
COUNT=$(python3 -c "import json; print(len(json.load(open('/task/output/scored_leads.json'))))" 2>/dev/null)
if [ "$COUNT" = "8" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: 8 scored leads"
else
    echo "FAIL: $COUNT leads, expected 8"
fi

# Step 3: Sorted by score descending
SORTED=$(python3 -c "
import json
data = json.load(open('/task/output/scored_leads.json'))
scores = [d['score'] for d in data]
print('yes' if scores == sorted(scores, reverse=True) else 'no')
" 2>/dev/null)
if [ "$SORTED" = "yes" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: sorted by score descending"
fi

# Step 4: Score calculations are correct (spot checks)
SCORE_OK=$(python3 -c "
import json
data = {d['name']: d for d in json.load(open('/task/output/scored_leads.json'))}
ok = 0
# Pierre Lavoie: owner+QC03+referral+budget15k+interest9 should be ~100
if data.get('Pierre Lavoie', {}).get('score', 0) >= 95: ok += 1
# Marc Bergeron: VP+QC05+referral+budget45k+interest10 should be ~100
if data.get('Marc Bergeron', {}).get('score', 0) >= 95: ok += 1
# Sophie Roy: coordinator+QC13+cold_call+budget5k+interest4 should be low
if data.get('Sophie Roy', {}).get('score', 0) < 40: ok += 1
# Anne Bouchard: specialist+QC06+social+budget3k+interest3 should be low
if data.get('Anne Bouchard', {}).get('score', 0) < 40: ok += 1
print(ok)
" 2>/dev/null)
if [ "$SCORE_OK" = "4" ]; then
    SCORE=$(echo "$SCORE + 0.15" | bc)
    echo "PASS: score calculations correct"
else
    echo "FAIL: score calculations wrong ($SCORE_OK/4)"
fi

# Step 5: Grade assignments correct
GRADE_OK=$(python3 -c "
import json
data = {d['name']: d for d in json.load(open('/task/output/scored_leads.json'))}
ok = 0
# A grades for top scorers
if data.get('Pierre Lavoie', {}).get('grade') == 'A': ok += 1
if data.get('Luc Martin', {}).get('grade') == 'A': ok += 1
# F for low scorers
if data.get('Sophie Roy', {}).get('grade') == 'F': ok += 1
if data.get('Anne Bouchard', {}).get('grade') == 'F': ok += 1
print(ok)
" 2>/dev/null)
if [ "$GRADE_OK" = "4" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: grades correct"
else
    echo "FAIL: grades wrong ($GRADE_OK/4)"
fi

# Step 6: Qualification threshold at 60
QUAL_OK=$(python3 -c "
import json
data = json.load(open('/task/output/scored_leads.json'))
ok = 0
for d in data:
    if d['score'] >= 60 and d['qualified'] == True: ok += 1
    elif d['score'] < 60 and d['qualified'] == False: ok += 1
print(ok)
" 2>/dev/null)
if [ "$QUAL_OK" = "8" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: qualification threshold correct (60)"
else
    echo "FAIL: qualification wrong ($QUAL_OK/8)"
fi

# Step 7: Owner title gets 20 points (bug fix verification)
OWNER_OK=$(python3 -c "
import json
data = {d['name']: d for d in json.load(open('/task/output/scored_leads.json'))}
# Pierre Lavoie is 'Owner' - should get max title score
# If 'owner' not handled, score would be lower
print('yes' if data.get('Pierre Lavoie', {}).get('score', 0) >= 95 else 'no')
" 2>/dev/null)
if [ "$OWNER_OK" = "yes" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: owner title bug fixed"
fi

# Step 8: pipeline_stats.json
if [ -f "/task/output/pipeline_stats.json" ]; then
    CHECKS=$(python3 -c "
import json
s = json.load(open('/task/output/pipeline_stats.json'))
c = 0
if s.get('total_leads') == 8: c += 1
if s.get('qualified_count') == 5: c += 1
if s.get('disqualified_count') == 3: c += 1
if 'avg_score' in s and 60 < s['avg_score'] < 85: c += 1
if 'grade_distribution' in s: c += 1
if s.get('top_lead') in ['Pierre Lavoie', 'Marc Bergeron']: c += 1
print(c)
" 2>/dev/null)
    if [ "$CHECKS" -ge 5 ]; then
        SCORE=$(echo "$SCORE + 0.25" | bc)
        echo "PASS: pipeline stats complete ($CHECKS/6)"
    else
        echo "FAIL: pipeline stats incomplete ($CHECKS/6)"
    fi
else
    echo "FAIL: pipeline_stats.json missing"
fi

# Step 9: Fixed files exist in output
if [ -f "/task/output/app/__init__.py" ] && [ -f "/task/output/app/models.py" ] && [ -f "/task/output/app/scoring.py" ] && [ -f "/task/output/app/main.py" ]; then
    SCORE=$(echo "$SCORE + 0.1" | bc)
    echo "PASS: all 4 fixed files present"
else
    echo "FAIL: missing fixed source files"
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
