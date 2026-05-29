#include <stdio.h>
#include <stdint.h>
#include <cuda_runtime.h>

#define ACTIVE 1000000
#define STEPS 50
#define LATENT 1000000000ULL

__device__ uint32_t xorshift32(uint32_t x) {
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return x;
}

__global__ void duj_hydration_kernel(
    unsigned long long step,
    unsigned int *violations
) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= ACTIVE) return;

    uint32_t seed = xorshift32((uint32_t)(i + step * 2654435761u));

    unsigned long long bot_id = seed % LATENT;

    float energy = (float)(seed & 65535) / 65535.0f;
    float drift = (float)((seed >> 16) & 65535) / 65535.0f * 0.02f;
    float invariant = 0.5f + ((float)(xorshift32(seed) & 65535) / 65535.0f) * 0.5f;
    float local_epoch = (float)(xorshift32(seed + 17) & 255) / 255.0f;

    float macro_epoch = 0.5f + step * 0.001f;
    float dormant_steps = (float)(xorshift32(seed + 31) % 5000);
    float effective_macro = macro_epoch + dormant_steps * 0.00005f;

    float epoch_gap = fabsf(effective_macro - local_epoch);
    float correction = fminf(epoch_gap * 0.75f, 0.2f);

    drift = fmaxf(drift - correction, 0.0f);

    float event = (float)(xorshift32(seed + 99) & 65535) / 65535.0f;

    energy += event * 0.01f;
    drift += fabsf(event - invariant) * 0.002f;

    bool violation = (drift > 0.05f) || (energy > invariant + 0.25f);

    if (violation) {
        atomicAdd(violations, 1);
    }

    // prevent optimizer from deleting bot_id completely
    if (bot_id == LATENT + 1) {
        atomicAdd(violations, 1);
    }
}

int main() {
    printf("🦊 CUDA DUJ Dormancy Hydration Test\n");
    printf("latent_population=%llu\n", LATENT);
    printf("active_frontier=%d\n", ACTIVE);
    printf("steps=%d\n", STEPS);
    printf("------------------------------------------------------------\n");

    unsigned int *d_violations;
    unsigned int h_violations = 0;

    cudaMalloc(&d_violations, sizeof(unsigned int));
    cudaMemset(d_violations, 0, sizeof(unsigned int));

    int threads = 256;
    int blocks = (ACTIVE + threads - 1) / threads;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);

    for (int step = 1; step <= STEPS; step++) {
        duj_hydration_kernel<<<blocks, threads>>>(step, d_violations);
        cudaDeviceSynchronize();

        cudaMemcpy(&h_violations, d_violations, sizeof(unsigned int), cudaMemcpyDeviceToHost);

        float rate = ((float)h_violations / (float)(ACTIVE * step)) * 100.0f;

        printf(
            "step=%03d exec=%d violations=%u rate=%.2f%%\n",
            step,
            ACTIVE * step,
            h_violations,
            rate
        );
    }

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0.0f;
    cudaEventElapsedTime(&ms, start, stop);

    int total_exec = ACTIVE * STEPS;

    printf("------------------------------------------------------------\n");
    printf("RESULT\n");
    printf("total_exec=%d\n", total_exec);
    printf("violations=%u\n", h_violations);
    printf("violation_rate=%.2f%%\n", ((float)h_violations / total_exec) * 100.0f);
    printf("time_ms=%.3f\n", ms);
    printf("hydrations_per_second=%.0f\n", ((float)total_exec / (ms / 1000.0f)));
    printf("status=CUDA_PATH_ACTIVE\n");

    cudaFree(d_violations);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    return 0;
}
