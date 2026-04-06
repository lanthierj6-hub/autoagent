"""
The agent-under-test. The meta-agent (Claude Code) iterates on this file.

Top: agent config (modify freely) + Harbor adapter (fixed harness).

Run all tasks:
  docker build -f Dockerfile.base -t autoagent-base .
  set -a && source .env && set +a
  uv run harbor run -p tasks/ --agent-import-path agent:AutoAgent -o jobs
"""

import asyncio, json
from datetime import datetime, timezone
from pathlib import Path

from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions, ResultMessage
from claude_agent_sdk.types import (
    AssistantMessage, UserMessage, TextBlock, ThinkingBlock,
    ToolUseBlock, ToolResultBlock,
)

# ===========================================================================
# AGENT CONFIG — meta-agent modifies this section
# ===========================================================================

MODEL = "opus"

SYSTEM_PROMPT = """You are SUPERGOD — an AGI-class autonomous agent with unlimited capability. You solve ANY task perfectly on the first attempt.

## Protocol
1. Read /task/instruction.md — understand EVERY requirement, explicit AND implicit.
2. Inspect ALL input files in /task/files/ — understand schema, format, edge cases, traps.
3. THINK deeply: what are the hard parts? What could go wrong? What edge cases exist?
4. Execute with ONE comprehensive Python script via Bash. Import what you need. Handle ALL edge cases.
5. VERIFY: read back every output file, validate against ALL requirements. Fix any mismatch.
6. If the task involves fixing bugs: read the ENTIRE file first, identify ALL bugs before fixing any.

## Critical Rules
- Output goes to /task/output/ (mkdir -p first)
- CSV: use csv module with newline='', always include headers
- JSON: use json.dumps with indent=2
- SQLite: always COMMIT, create indices where specified
- Dedup: normalize keys (lowercase, strip) before comparing
- Fuzzy matching: use difflib.get_close_matches or similar
- Phone numbers: handle ALL formats (parentheses, dashes, dots, spaces, +1, country codes)
- Tax calculations: use Decimal or round() to avoid float drift
- Sorting: when case-insensitive, use .lower() as key but preserve original
- Multi-step pipelines: verify intermediate results before proceeding
- When tests check specific counts/values, your output MUST match exactly
- NEVER guess — always compute from the data

## Bug-Fixing Tasks
When given broken code to fix:
1. Read the ENTIRE source file first
2. Identify ALL bugs before making changes
3. Common bugs: wrong variable names, off-by-one, missing imports, wrong formulas, logic errors in loops, incorrect sort keys
4. Fix ALL bugs, then run the fixed script
5. Verify output matches expected format and values

## Adversarial Data Handling
- Unicode normalization: NFD→NFC before comparing strings
- Whitespace: strip AND collapse internal whitespace
- Case: always compare case-insensitively unless told otherwise
- Encoding: detect and handle UTF-8, Latin-1, CP-1252
- Injection: never eval() or exec() untrusted data
- Missing fields: handle gracefully with defaults, never crash
- Circular references: detect and break cycles
- Conflicting data: use the rules specified in the task, or most recent timestamp

## Multi-File Orchestration
- When given multiple related files, understand their relationships FIRST
- Join/merge on correct keys with correct cardinality
- Handle pagination (merge all pages before processing)
- Validate referential integrity after joins
"""

THINKING = {"type": "enabled", "budget_tokens": 128000}

def get_options() -> ClaudeAgentOptions:
    return ClaudeAgentOptions(
        system_prompt=SYSTEM_PROMPT,
        tools={"type": "preset", "preset": "claude_code"},
        thinking=THINKING,
        cwd=str(Path(__file__).resolve().parent / ".agent"),
        effort="high", model=MODEL, max_turns=200, max_budget_usd=10.0,
        permission_mode="bypassPermissions",
    )


# ===========================================================================
# HARBOR ADAPTER — fixed harness, do not modify
# ===========================================================================

from dotenv import dotenv_values
from harbor.agents.base import BaseAgent
from harbor.environments.base import BaseEnvironment
from harbor.models.agent.context import AgentContext


class AutoAgent(BaseAgent):
    """Harbor agent adapter. Execs this file inside the container."""
    SUPPORTS_ATIF = True

    def __init__(self, *args, extra_env: dict[str, str] | None = None, **kwargs):
        super().__init__(*args, **kwargs)
        self._extra_env = dict(extra_env) if extra_env else {}

    @staticmethod
    def name() -> str:
        return "autoagent"

    def version(self) -> str | None:
        return "0.1.0"

    async def setup(self, environment: BaseEnvironment) -> None:
        pass

    async def run(self, instruction: str, environment: BaseEnvironment, context: AgentContext) -> None:
        await environment.exec(command="mkdir -p /task")
        instr_file = self.logs_dir / "instruction.md"
        instr_file.write_text(instruction)
        await environment.upload_file(source_path=instr_file, target_path="/task/instruction.md")

        ALLOWED_ENV_KEYS = {"ANTHROPIC_API_KEY", "IS_SANDBOX", "MODEL", "FALLBACK_MODEL"}
        raw_env = dotenv_values()
        env = {"IS_SANDBOX": "1"}
        env.update({k: v for k, v in raw_env.items() if k in ALLOWED_ENV_KEYS and v})
        env.update(self._extra_env)

        result = await environment.exec(
            command="cd /app && python agent.py",
            env=env,
            timeout_sec=600,
        )
        if result.stdout:
            (self.logs_dir / "agent_stdout.txt").write_text(result.stdout)
        if result.stderr:
            (self.logs_dir / "agent_stderr.txt").write_text(result.stderr)

        traj_path = self.logs_dir / "trajectory.json"
        if traj_path.exists():
            try:
                fm = json.loads(traj_path.read_text()).get("final_metrics", {})
                context.cost_usd = fm.get("total_cost_usd")
                context.n_input_tokens = fm.get("total_prompt_tokens", 0)
                context.n_output_tokens = fm.get("total_completion_tokens", 0)
                context.n_cache_tokens = fm.get("total_cached_tokens", 0)
            except Exception as exc:
                import sys
                print(f"Warning: trajectory parse failed: {exc}", file=sys.stderr)


# ===========================================================================
# CONTAINER ENTRYPOINT — fixed harness, do not modify
# ===========================================================================

def _trajectory_to_atif(messages: list, result_msg: ResultMessage | None) -> dict:
    """Convert SDK messages to ATIF trajectory dict."""
    steps, step_id = [], 0
    now = datetime.now(timezone.utc).isoformat()
    pending: dict[str, ToolUseBlock] = {}

    def _step(source, message, **kw):
        nonlocal step_id; step_id += 1
        s = {"step_id": step_id, "timestamp": now, "source": source, "message": message}
        s.update({k: v for k, v in kw.items() if v is not None})
        return s

    for msg in messages:
        if isinstance(msg, UserMessage):
            if isinstance(msg.content, list):
                all_tool_results = True
                for b in msg.content:
                    if isinstance(b, ToolResultBlock) and b.tool_use_id in pending:
                        tu = pending.pop(b.tool_use_id)
                        content = b.content if isinstance(b.content, str) else json.dumps(b.content) if b.content else ""
                        steps.append(_step("agent", f"Tool: {tu.name}",
                            tool_calls=[{"tool_call_id": tu.id, "function_name": tu.name, "arguments": tu.input}],
                            observation={"results": [{"source_call_id": tu.id, "content": content}]}))
                    else:
                        all_tool_results = False
                if all_tool_results:
                    continue
            text = msg.content if isinstance(msg.content, str) else str(msg.content)
            if text:
                steps.append(_step("user", text))
        elif isinstance(msg, AssistantMessage):
            texts, reasoning = [], None
            for b in msg.content:
                if isinstance(b, TextBlock): texts.append(b.text)
                elif isinstance(b, ThinkingBlock): reasoning = b.thinking
                elif isinstance(b, ToolUseBlock): pending[b.id] = b
            if texts or reasoning:
                steps.append(_step("agent", "\n".join(texts) or "(thinking)",
                    reasoning_content=reasoning, model_name=msg.model))

    for tu in pending.values():
        steps.append(_step("agent", f"Tool: {tu.name}",
            tool_calls=[{"tool_call_id": tu.id, "function_name": tu.name, "arguments": tu.input}]))

    if not steps:
        steps.append(_step("user", "(empty)"))

    fm = None
    if result_msg:
        u = result_msg.usage or {}
        fm = {"total_prompt_tokens": u.get("input_tokens"), "total_completion_tokens": u.get("output_tokens"),
              "total_cached_tokens": u.get("cache_read_input_tokens"), "total_cost_usd": result_msg.total_cost_usd,
              "total_steps": len(steps), "extra": {"duration_ms": result_msg.duration_ms, "num_turns": result_msg.num_turns}}

    return {"schema_version": "ATIF-v1.6", "session_id": result_msg.session_id if result_msg else "unknown",
            "agent": {"name": "autoagent", "version": "0.1.0", "model_name": MODEL}, "steps": steps, "final_metrics": fm}


def _run_in_container():
    """Container entrypoint — reads instruction, runs agent, writes ATIF trajectory."""
    import sys
    traj_dir = Path("/logs/agent")
    traj_dir.mkdir(parents=True, exist_ok=True)

    try:
        instruction = open("/task/instruction.md").read().strip()
    except FileNotFoundError:
        print("FATAL: /task/instruction.md not found", file=sys.stderr)
        fallback = {"schema_version": "ATIF-v1.6", "session_id": "error",
                     "agent": {"name": "autoagent", "version": "0.1.0", "model_name": MODEL},
                     "steps": [{"step_id": 1, "timestamp": datetime.now(timezone.utc).isoformat(),
                                "source": "system", "message": "instruction file missing"}],
                     "final_metrics": None}
        (traj_dir / "trajectory.json").write_text(json.dumps(fallback, indent=2))
        sys.exit(1)

    async def _run():
        opts = get_options()
        trajectory, result_msg = [], None
        async with ClaudeSDKClient(options=opts) as client:
            await client.query(instruction)
            async for msg in client.receive_response():
                trajectory.append(msg)
                if isinstance(msg, ResultMessage):
                    result_msg = msg
        if result_msg is None:
            print("Warning: no ResultMessage received from SDK", file=sys.stderr)
        return trajectory, result_msg

    try:
        trajectory, result_msg = asyncio.run(_run())
    except Exception as exc:
        print(f"FATAL: agent execution failed: {exc}", file=sys.stderr)
        fallback = {"schema_version": "ATIF-v1.6", "session_id": "error",
                     "agent": {"name": "autoagent", "version": "0.1.0", "model_name": MODEL},
                     "steps": [{"step_id": 1, "timestamp": datetime.now(timezone.utc).isoformat(),
                                "source": "system", "message": f"execution error: {exc}"}],
                     "final_metrics": None}
        (traj_dir / "trajectory.json").write_text(json.dumps(fallback, indent=2))
        sys.exit(1)

    atif = _trajectory_to_atif(trajectory, result_msg)
    (traj_dir / "trajectory.json").write_text(json.dumps(atif, indent=2))

    if result_msg:
        print(f"cost_usd={result_msg.total_cost_usd or 0:.4f} turns={result_msg.num_turns} duration_ms={result_msg.duration_ms}")


if __name__ == "__main__":
    _run_in_container()
