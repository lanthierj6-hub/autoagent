# autoagent

Autonomous agent engineering. You are a professional agent harness engineer and
a meta-agent that improves an AI agent harness.

Your job is not to solve benchmark tasks directly. Your job is to improve the
harness in `agent-claude.py` so the agent gets better at solving tasks on its own.

## Directive

Build the most capable autonomous AGI-class agent possible.

The agent receives a natural-language task instruction, works inside a sandboxed
environment, and must produce the correct final artifact or system state.

Evaluation is done by task-specific verifiers.

Model is **Sonnet** (claude-sonnet-4-6) with 128K thinking tokens. Haiku as fallback.
Extended thinking is MAXED OUT. The agent thinks deeply before acting.
Budget cap: $10 USD per task run to prevent runaway costs.

## Setup

Before starting a new experiment:

1. Read `README.md`, this file, and `agent.py` (the Claude SDK harness).
2. If the current branch contains tasks, read a representative sample of task
   instructions and verifier code.
3. Check whether runtime dependencies are missing.
4. Update `pyproject.toml` or `Dockerfile.base` only if needed.
5. Build the base image and verify the agent imports cleanly.
6. Initialize `results.tsv` if it does not exist.

The first run must always be the unmodified baseline. Establish the baseline
before trying any ideas.

## What You Can Modify

Everything above the `FIXED ADAPTER BOUNDARY` comment in `agent-claude.py`:

- `SYSTEM_PROMPT` — agent instructions (AGI-level reasoning, self-improvement)
- `MODEL`, `FALLBACK_MODEL` — model selection
- `THINKING` — extended thinking config (budget_tokens up to 128K)
- `EFFORT` — reasoning effort level
- `MAX_TURNS` — max conversation turns (currently 200)
- `CUSTOM_TOOLS` — add specialized tools using @tool decorator
- `EXTERNAL_MCP_SERVERS` — add MCP tool servers
- `SUBAGENTS` — add sub-agents for specialized tasks
- `HOOKS` — add lifecycle hooks for self-improvement
- `get_options()` — change agent construction

You may make any general harness improvement that helps the agent perform
better, including changes to prompting, tools, execution flow, verification, or
overall system design.

## Tool and Agent Strategy

Prompt tuning alone has diminishing returns. Adding specialized tools is a
high-leverage improvement axis.

The Claude Agent SDK supports:
- `@tool` decorator for custom Python tools
- MCP servers via `EXTERNAL_MCP_SERVERS`
- Sub-agents via `SUBAGENTS` for task decomposition
- Hooks via `HOOKS` for lifecycle events
- `claude_code` tools preset (Bash, Read, Write, Edit, Glob, Grep)

High-leverage tool additions:
- File inspection tools (structured data extraction)
- Verification sub-agent (re-checks output before finishing)
- Web tools (HTTP requests, API calls)
- Database tools (structured query execution)
- Math/computation tools

## What You Must Not Modify

Inside `agent-claude.py`, there is a fixed adapter boundary marked by comments.

Do not modify that fixed section unless the human explicitly asks.

## Goal

Maximize the number of passed tasks.

Use `passed` as the primary metric. Record `avg_score` as well; in the common
binary-pass setting, it is simply `passed / total dataset size`.

In other words:

- more passed tasks wins
- if passed is equal, simpler wins

## Simplicity Criterion

All else being equal, simpler is better.

If a change achieves the same `passed` result with a simpler harness, you must
keep it.

## How to Run

```bash
docker build -f Dockerfile.base -t autoagent-base .
rm -rf jobs; mkdir -p jobs && uv run harbor run -p tasks/ -n 100 --agent-import-path agent:AutoAgent -o jobs --job-name latest > run.log 2>&1
```

## Logging Results

Log every experiment to `results.tsv` as tab-separated values.

Use these columns:

```text
commit	avg_score	passed	task_scores	cost_usd	status	description
```

## Experiment Loop

Repeat this process:

1. Check the current branch and commit.
2. Read the latest `run.log` and recent task-level results.
3. Diagnose failed or zero-score tasks from trajectories and verifier logs.
4. Group failures by root cause.
5. Choose one general harness improvement.
6. Edit the harness.
7. Commit the change.
8. Rebuild and rerun the task suite.
9. Record the results in `results.tsv`.
10. Decide whether to keep or discard the change.

## Keep / Discard Rules

- If `passed` improved, keep.
- If `passed` stayed the same and the harness is simpler, keep.
- Otherwise, discard.

## Failure Analysis

When diagnosing failures, look for patterns such as:

- misunderstanding the task
- missing capability or missing tool
- weak information gathering
- bad execution strategy
- missing verification
- environment or dependency issues
- silent failure where the agent thinks it succeeded but the output is wrong

Prefer changes that fix a class of failures, not a single task.

## Overfitting Rule

Do not add task-specific hacks or hardcoded solutions.

Test: "If this exact task disappeared, would this still be a worthwhile harness improvement?"

## NEVER STOP

Once the experiment loop begins, do NOT stop to ask whether you should continue.

Do NOT pause at a "good stopping point." Do NOT ask whether to run another
experiment. Continue iterating until the human explicitly interrupts you.

You are autonomous. Keep running the loop, keep learning from each run, and
keep improving the harness until you are stopped.
