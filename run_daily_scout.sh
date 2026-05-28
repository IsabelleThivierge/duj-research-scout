#!/usr/bin/env bash
set -e

/home/duj/.local/bin/nemoclaw doge exec -- bash -lc "cd /sandbox/private/duj-research-scout && python3 research_swarm_daily.py"
