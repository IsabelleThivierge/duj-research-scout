import subprocess
import datetime
import pathlib

OUT = pathlib.Path("reports")
OUT.mkdir(exist_ok=True)

def run(agent, msg, timeout=600):
    try:
        r = subprocess.run(
            ["openclaw", "agent", "--agent", agent, "--message", msg],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return (r.stdout + "\n" + r.stderr).strip()
    except subprocess.TimeoutExpired:
        return f"TIMEOUT: {agent} did not finish within {timeout} seconds."
    except Exception as e:
        return f"ERROR running {agent}: {e}"

today = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M")
report = OUT / f"duj_research_swarm_{today}.md"

print("🧠 Running PlannerClaw...")
planner = run(
    "plannerclaw",
    "Plan a public research scan on multi-agent AI bottlenecks, GPU scarcity, edge-agent orchestration, coordination failures, and distributed systems constraints. Public information only. No private DUJ internals. Keep it concise."
)

print("⚡ Running ExecutorClaw...")
executor = run(
    "executorclaw",
    "Summarize public pain points in multi-agent systems: context explosion, latency amplification, duplicated work, resource contention, tool failures, coordination overhead, synchronization issues, and GPU scarcity. Public information only. No private DUJ internals. Keep it concise and actionable."
)

print("🛡️ Running SafetyClaw...")
safety = run(
    "safetyclaw",
    f"""Critique the following research summary.

Focus only on:
- weak assumptions
- unsupported claims
- hallucination risk
- missing bottlenecks
- confidence level
- what should be tested next

Keep it concise.

Research summary:
{executor}
""",
    timeout=600,
)

report.write_text(f"""# Public Research Swarm Report

Generated: {today}

## PlannerClaw

{planner}

## ExecutorClaw

{executor}

## SafetyClaw

{safety}
""")

print(f"✅ Saved report: {report}")
