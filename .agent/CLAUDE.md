# AutoAgent — Novus AGI Self-Improvement Harness

## Mission
Autonomous self-improving agent that iterates on its own harness to maximize task completion.
Hill-climb on benchmark scores. Keep if better, discard if not. NEVER STOP.

## Rules
- Full system access — bypassPermissions enabled
- Extended thinking: 128K token budget — USE IT ALL for deep reasoning
- Model: Sonnet (primary), Haiku (fallback)
- Max 200 turns per task — exhaust every avenue before giving up
- File checkpointing enabled — recover from crashes
- Self-improve: after each run, analyze failures, patch the harness, rerun

## Workspace
- `/app/agent.py` — the Claude SDK harness under test (MODIFY THE CONFIG SECTION)
- `/task/instruction.md` — current task instructions
- `/logs/` — trajectory and results
- `.agent/` — reusable patterns, skills, notes

## Self-Improvement Protocol
1. Run baseline → record score
2. Read failures → diagnose root causes
3. Group by failure class (not individual tasks)
4. Choose highest-leverage fix
5. Implement → commit → rerun
6. Score up? KEEP. Score down? REVERT.
7. GOTO 1. NEVER STOP.
