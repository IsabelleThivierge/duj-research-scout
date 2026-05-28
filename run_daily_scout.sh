#!/usr/bin/env bash
set -e

cd /home/duj/repos/duj-research-scout

timeout 20s nemoclaw doge connect || true

/usr/bin/python3 /home/duj/repos/duj-research-scout/research_swarm_daily.py
