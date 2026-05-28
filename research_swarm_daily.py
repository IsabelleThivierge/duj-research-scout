import subprocess
import datetime
import pathlib

def duj_handoff_packet(source_agent, output, goal, max_chars=3500):
    timeout_risk = len(output) > max_chars

    return f"""
DUJ-LITE HANDOFF PACKET

Source agent: {source_agent}
Goal anchor: {goal}

Handoff size chars: {len(output)}
Timeout risk: {timeout_risk}

Bounded summary:
{output[:max_chars]}

Instruction to next agent:
Stay anchored to the goal. Critique only the bounded summary above. Prioritize weak assumptions, unsupported claims, missing bottlenecks, and confidence level.
"""

OUT = pathlib.Path("reports")
OUT.mkdir(exist_ok=True)

def run(agent, msg, timeout=600):
    try:
        r = subprocess.run(
            ["/usr/local/bin/openclaw", "agent", "--agent", agent, "--message", msg],
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

goal = "Public research scan on multi-agent AI bottlenecks, GPU scarcity, edge-agent orchestration, coordination failures, and distributed systems constraints."

executor_packet = duj_handoff_packet(
    "ExecutorClaw",
    executor,
    goal,
    max_chars=3500
)

print("🛡️ Running SafetyClaw with DUJ-lite handoff...")
safety = run(
    "safetyclaw",
    f"Critique this bounded DUJ-lite handoff packet:\n\n{executor_packet}",
    timeout=600
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
