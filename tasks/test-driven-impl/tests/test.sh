#!/bin/bash
SCORE=0.0

# Step 1: pricing_engine.py exists
if [ ! -f "/task/output/pricing_engine.py" ]; then
    echo "FAIL: pricing_engine.py missing"
    echo "SCORE: 0.0"
    echo "0.0" > /logs/reward.txt
    exit 0
fi

# Step 2: Run the actual tests
cd /task/output
pip install pytest -q 2>/dev/null
RESULT=$(python3 -m pytest /task/files/test_pricing.py -v --tb=short 2>&1)
echo "$RESULT"

# Count passed tests
PASSED=$(echo "$RESULT" | grep -c " PASSED")
FAILED=$(echo "$RESULT" | grep -c " FAILED")
ERRORS=$(echo "$RESULT" | grep -c " ERROR")
TOTAL=25

echo "Tests: $PASSED passed, $FAILED failed, $ERRORS errors out of $TOTAL"

if [ "$PASSED" = "$TOTAL" ]; then
    SCORE="1.0"
    echo "PASS: all $TOTAL tests pass"
elif [ "$PASSED" -ge 20 ]; then
    SCORE=$(echo "scale=2; $PASSED / $TOTAL" | bc)
    echo "PARTIAL: $PASSED/$TOTAL tests pass"
elif [ "$PASSED" -ge 10 ]; then
    SCORE=$(echo "scale=2; $PASSED / $TOTAL * 0.8" | bc)
    echo "PARTIAL: $PASSED/$TOTAL tests pass"
else
    SCORE=$(echo "scale=2; $PASSED / $TOTAL * 0.5" | bc)
    echo "FAIL: only $PASSED/$TOTAL tests pass"
fi

# Step 3: test_results.txt exists
if [ -f "/task/output/test_results.txt" ]; then
    SIZE=$(wc -c < "/task/output/test_results.txt" | tr -d ' ')
    if [ "$SIZE" -gt 50 ]; then
        echo "PASS: test_results.txt exists ($SIZE bytes)"
    fi
fi

echo "SCORE: $SCORE"
echo "$SCORE" > /logs/reward.txt
