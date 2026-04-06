#!/bin/bash
SCORE=0.0

if [ ! -f "/task/output/test_outputs.json" ]; then
    echo "FAIL: test_outputs.json missing"
    echo "SCORE: 0.0"
    echo "0.0" > /logs/reward.txt
    exit 0
fi

# Load expected outputs and compare
MATCH=$(python3 -c "
import json

expected = json.load(open('/task/files/expected_outputs.json'))
actual = json.load(open('/task/output/test_outputs.json'))

if not isinstance(actual, list) or len(actual) != 10:
    print('0')
    exit()

correct = 0
for i, (exp, act) in enumerate(zip(expected, actual)):
    match = True
    # Check total (within 0.05)
    if abs(float(act.get('total', 0)) - float(exp['total'])) > 0.05:
        match = False
    # Check tax (within 0.05)
    if abs(float(act.get('tax', 0)) - float(exp['tax'])) > 0.05:
        match = False
    # Check priority
    if act.get('priority') != exp['priority']:
        match = False
    # Check code
    if act.get('code') != exp['code']:
        match = False
    # Check flagged
    if act.get('flagged') != exp['flagged']:
        match = False
    if match:
        correct += 1
    else:
        import sys
        print(f'Mismatch at index {i}: expected {exp}, got {act}', file=sys.stderr)
print(correct)
" 2>/dev/null)

if [ "$MATCH" = "10" ]; then
    SCORE=$(echo "$SCORE + 0.7" | bc)
    echo "PASS: all 10 outputs correct"
elif [ "$MATCH" -ge 7 ]; then
    SCORE=$(echo "$SCORE + 0.4" | bc)
    echo "PARTIAL: $MATCH/10 outputs correct"
elif [ "$MATCH" -ge 4 ]; then
    SCORE=$(echo "$SCORE + 0.2" | bc)
    echo "PARTIAL: $MATCH/10 outputs correct"
else
    echo "FAIL: only $MATCH/10 outputs correct"
fi

# Check algorithm description
if [ -f "/task/output/algorithm_description.txt" ]; then
    SIZE=$(wc -c < "/task/output/algorithm_description.txt" | tr -d ' ')
    if [ "$SIZE" -gt 200 ]; then
        SCORE=$(echo "$SCORE + 0.1" | bc)
        echo "PASS: algorithm description ($SIZE bytes)"
    fi

    # Check if description mentions key concepts
    CONCEPTS=$(python3 -c "
text = open('/task/output/algorithm_description.txt').read().lower()
c = 0
if 'premium' in text or 'category' in text: c += 1
if 'tax' in text or '0.14975' in text or 'qc' in text: c += 1
if 'priority' in text or 'high' in text: c += 1
if 'code' in text or 'first 3' in text: c += 1
if 'flagged' in text or '10000' in text: c += 1
print(c)
" 2>/dev/null)
    if [ "$CONCEPTS" -ge 3 ]; then
        SCORE=$(echo "$SCORE + 0.2" | bc)
        echo "PASS: description covers key concepts ($CONCEPTS/5)"
    else
        echo "FAIL: description incomplete ($CONCEPTS/5)"
    fi
else
    echo "FAIL: algorithm_description.txt missing"
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
