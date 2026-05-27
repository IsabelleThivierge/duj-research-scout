cat > README.md << 'EOF'
# DUJ Research Scout 🦊

Experimental multi-agent public research workflow running through OpenClaw + NVIDIA Nemotron.

This repository captures the **first successful research swarm run** executed on NVIDIA Nemotron through OpenClaw orchestration on local edge hardware ("Doge" 🦊).

## What this does

The workflow launches a lightweight research swarm with specialized agent roles:

- **PlannerClaw** → creates structured research plans
- **ExecutorClaw** → executes public research synthesis
- **SafetyClaw** → critiques outputs and stress-tests assumptions

The current version focuses on:

- Multi-agent AI bottlenecks
- Edge-agent orchestration
- Coordination failures
- GPU scarcity and scaling limits
- Distributed system constraints

## First Run Outcome

The initial research swarm successfully:

✅ Generated a structured public research plan  
✅ Produced a multi-agent bottleneck analysis  
✅ Documented current system limitations  
⚠️ Observed SafetyClaw timeout behavior in sandboxed conditions

An interesting observation from the first run:

> Safety timeout behavior may itself become a benchmark target for future DUJ-lite coordination experiments.

## Repository Structure

```text
research_swarm_daily.py   # Main swarm orchestration script
FIRST_RUN_SUMMARY.md      # First successful run summary
reports/                  # Generated outputs (ignored from git)
