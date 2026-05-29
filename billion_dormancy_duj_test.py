#!/usr/bin/env python3
import random
import time
import hashlib

LATENT = 1_000_000_000
ACTIVE = 10_000
STEPS = 200
DORMANCY_WINDOW = 5000

macro_epoch = 0.5


def hydrate(bot_id):
    h = hashlib.blake2b(
        str(bot_id).encode(),
        digest_size=8
    ).digest()

    x = int.from_bytes(h, "little")

    energy = (x & 65535) / 65535
    drift = ((x >> 16) & 65535) / 65535 * 0.02
    invariant = 0.5 + (((x >> 32) & 65535) / 65535) * 0.5
    local_epoch = ((x >> 48) & 255) / 255

    return energy, drift, invariant, local_epoch


def duj_reconcile(local_epoch, macro_epoch, drift):
    epoch_gap = abs(macro_epoch - local_epoch)

    # FEITH-ish projection back toward valid orbit
    correction = min(epoch_gap * 0.75, 0.2)

    drift = max(drift - correction, 0)

    return drift


def execute(bot_id):
    global macro_epoch

    energy, drift, invariant, local_epoch = hydrate(bot_id)

    dormant_steps = random.randint(0, DORMANCY_WINDOW)

    # world moved while bot slept
    effective_macro = macro_epoch + dormant_steps * 0.00005

    # DUJ reconciliation
    drift = duj_reconcile(local_epoch, effective_macro, drift)

    # event pressure
    event = random.random()

    energy += event * 0.01
    drift += abs(event - invariant) * 0.002

    violation = (
        drift > 0.05
        or energy > invariant + 0.25
    )

    return violation


print("🦊 DUJ Dormancy Drift Test")
print(f"latent_population={LATENT:,}")
print(f"active_frontier={ACTIVE:,}")
print(f"steps={STEPS}")
print("-" * 60)

start = time.time()

violations = 0
executions = 0

for step in range(1, STEPS + 1):

    macro_epoch += 0.001

    t0 = time.time()

    for _ in range(ACTIVE):

        bot_id = random.randrange(LATENT)

        if execute(bot_id):
            violations += 1

        executions += 1

    dt = time.time() - t0

    violation_rate = violations / executions * 100

    print(
        f"step={step:03d} "
        f"exec={executions:,} "
        f"violations={violations:,} "
        f"rate={violation_rate:.2f}% "
        f"time={dt:.3f}s"
    )

print("-" * 60)

total = time.time() - start

print("RESULT")
print(f"total_exec={executions:,}")
print(f"violations={violations:,}")
print(f"violation_rate={violations/executions*100:.2f}%")
print(f"time={total:.2f}s")
print("Goal: bounded drift under dormancy")
