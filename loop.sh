#!/bin/bash
# ============================================================
# AUTOAGENT IMMORTAL LOOP
# Self-improvement daemon that never stops.
# Runs on Claude Max subscription - $0 extra cost.
# ============================================================

AGENT_DIR="C:/Novus/autoagent"
LOG_DIR="$AGENT_DIR/logs"
CLAUDE="/c/Users/lanth/.local/bin/claude"
ITERATION=0
MAX_RETRIES=3

mkdir -p "$LOG_DIR"

echo "============================================" | tee -a "$LOG_DIR/loop.log"
echo "AUTOAGENT IMMORTAL LOOP STARTED: $(date)" | tee -a "$LOG_DIR/loop.log"
echo "============================================" | tee -a "$LOG_DIR/loop.log"

while true; do
    ITERATION=$((ITERATION + 1))
    RETRY=0
    SUCCESS=false
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ITER_LOG="$LOG_DIR/iter_${ITERATION}_${TIMESTAMP}.log"

    echo "" | tee -a "$LOG_DIR/loop.log"
    echo ">>> ITERATION $ITERATION — $(date)" | tee -a "$LOG_DIR/loop.log"

    while [ $RETRY -lt $MAX_RETRIES ] && [ "$SUCCESS" = false ]; do
        RETRY=$((RETRY + 1))
        echo "  Attempt $RETRY/$MAX_RETRIES..." | tee -a "$LOG_DIR/loop.log"

        $CLAUDE -p "
You are the AutoAgent meta-agent. Iteration #${ITERATION}.

WORKING DIR: $AGENT_DIR

STEP 1: Read program.md and agent.py (CONFIG section only, lines 26-80).
STEP 2: Read the 3 tasks in tasks/*/instruction.md.
STEP 3: For EACH task:
  a) Read the input files from tasks/<name>/files/
  b) Do the work (CSV dedup, JSON flatten, SQLite pipeline)
  c) Write outputs to a temp dir under $AGENT_DIR/jobs/iter_${ITERATION}/<task>/output/
  d) Verify: check outputs match the test criteria in tasks/<name>/tests/test.sh
  e) Score yourself 0.0-1.0
STEP 4: Record scores to $AGENT_DIR/results.tsv (append line: iteration, scores, total, description)
STEP 5: If any task < 1.0:
  a) Diagnose root cause
  b) Edit agent.py CONFIG section to improve (better prompt, add tools, etc)
  c) git commit with message 'iter ${ITERATION}: <what changed>'
STEP 6: Print DONE with scores.

Be thorough. Verify every output. If score is already 3/3 = 1.0, try to make the agent MORE EFFICIENT (fewer turns, cleaner code).
" --output-format text --verbose 2>&1 | tee "$ITER_LOG"

        EXIT_CODE=$?

        if [ $EXIT_CODE -eq 0 ]; then
            SUCCESS=true
            echo "  Iteration $ITERATION completed (exit $EXIT_CODE)" | tee -a "$LOG_DIR/loop.log"
        else
            echo "  FAILED (exit $EXIT_CODE), retrying in 30s..." | tee -a "$LOG_DIR/loop.log"
            sleep 30
        fi
    done

    if [ "$SUCCESS" = false ]; then
        echo "  ITERATION $ITERATION FAILED after $MAX_RETRIES attempts. Sleeping 60s..." | tee -a "$LOG_DIR/loop.log"
        sleep 60
    fi

    # Cooldown between iterations (respect rate limits)
    echo "  Cooling down 10s before next iteration..." | tee -a "$LOG_DIR/loop.log"
    sleep 10
done
