# DUJ Research Scout 🦊

Hardware: Local NVIDIA Jetson edge hardware (affectionately named “Doge” 🦊) running OpenClaw + NVIDIA Nemotron.

Experimental multi-agent public research workflow running through OpenClaw + NVIDIA Nemotron.

This repository captures the **first successful research swarm run** executed on NVIDIA Nemotron through OpenClaw orchestration on local NVIDIA Jetson edge hardware.

## Current Experimental Tracks

This repository currently contains three active experimental directions:

1. **OpenClaw / Nemotron Research Swarm**
   - Multi-agent public research orchestration on NVIDIA edge hardware.

2. **CUDA Dormancy Hydration Experiments**
   - Billion-scale latent population stress testing on Jetson Orin Nano using CUDA kernels.

3. **Persistent Pool Stability Benchmarks**
   - Testing dormant agent rehydration under DUJ bounded reconciliation vs control conditions.

## Preliminary Persistent Pool Results

| Test | Violation Rate |
|-------|----------------|
| Persistent Pool (DUJ) | 9.46% |
| Persistent Pool (Control) | 64.96% |

### Reproducibility

The persistent pool experiment was repeated across **3 runs per condition** on local NVIDIA Jetson edge hardware.

Observed reproducibility:

- **DUJ:** 9.46%, 9.46%, 9.46%
- **Control:** 64.96%, 64.96%, 64.96%

### Experimental Framing

These are preliminary constrained-hardware experiments designed to explore:

- bounded coordination under persistent dormancy
- latent population rehydration stability
- active frontier scaling on edge hardware

Current limitations:

- single hardware platform (Jetson Orin Nano)
- synthetic invariant model
- preliminary benchmark only
- not evidence of general intelligence or universal coordination stability

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
