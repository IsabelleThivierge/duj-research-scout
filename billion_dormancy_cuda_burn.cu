#include <stdio.h>
#include <stdint.h>
#include <cuda_runtime.h>
#include <math.h>

#define ACTIVE 10000000
#define STEPS 500
#define LATENT 1000000000ULL
#define INNER_ITERS 64

#define CUDA_CHECK(call) do {                                      \
    cudaError_t err = call;                                        \
    if (err != cudaSuccess) {                                      \
        fprintf(stderr, "CUDA error %s:%d: %s\n",                  \
                __FILE__, __LINE__, cudaGetErrorString(err));      \
        return 1;                                                  \
    }                                                             \
} while (0)

__device__ __forceinline__ uint32_t xorshift32(uint32_t x) {
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return x;
}

__global__ void duj_burn_kernel(
    unsigned int step,
    unsigned int *violations,
    float *sink
) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= ACTIVE) return;

    uint32_t seed = xorshift32((uint32_t)i ^ (step * 2654435761u));

    unsigned long long bot_id = (unsigned long long)seed % LATENT;

    float energy = (float)(seed & 65535) / 65535.0f;
    float drift = (float)((seed >> 16) & 65535) / 65535.0f * 0.02f;
    float invariant = 0.5f + ((float)(xorshift32(seed + 11) & 65535) / 65535.0f) * 0.5f;
    float local_epoch = (float)(xorshift32(seed + 17) & 255) / 255.0f;

    float macro_epoch = 0.5f + step * 0.001f;
    float dormant_steps = (float)(xorshift32(seed + 31) % 5000);
    float effective_macro = macro_epoch + dormant_steps * 0.00005f;

    float epoch_gap = fabsf(effective_macro - local_epoch);
    float correction = fminf(epoch_gap * 0.75f, 0.2f);

    drift = fmaxf(drift - correction, 0.0f);

    float event = (float)(xorshift32(seed + 99) & 65535) / 65535.0f;

    // Heavier synthetic DUJ-like orbit work so jtop/tegrastats can see GPU load.
    float orbit = energy + drift + invariant + event;

    #pragma unroll 8
    for (int k = 0; k < INNER_ITERS; k++) {
        seed = xorshift32(seed + k + step);
        float noise = (float)(seed & 65535) / 65535.0f;

        orbit = fmaf(orbit, 0.9991f, noise * 0.0009f);
        orbit += sinf(orbit + noise) * 0.0001f;
        orbit -= cosf(invariant + drift) * 0.00005f;

        float local_gap = fabsf(orbit - invariant);
        drift += fminf(local_gap * 0.00001f, 0.0005f);
        drift = fmaxf(drift - correction * 0.0001f, 0.0f);
    }

    energy += event * 0.01f + orbit * 0.00001f;
    drift += fabsf(event - invariant) * 0.002f;

    bool violation = (drift > 0.05f) || (energy > invariant + 0.25f);

    if (violation) {
        atomicAdd(violations, 1);
    }

    // Prevent optimizer from deleting work.
    sink[i] = orbit + drift + energy + (float)(bot_id & 1023ULL) * 0.000001f;
}

int main() {
    printf("🦊 CUDA DUJ Dormancy Burn Test\n");
    printf("latent_population=%llu\n", LATENT);
    printf("active_frontier=%d\n", ACTIVE);
    printf("steps=%d\n", STEPS);
    printf("inner_iters=%d\n", INNER_ITERS);
    printf("total_hydration_evals=%llu\n", (unsigned long long)ACTIVE * (unsigned long long)STEPS);
    printf("------------------------------------------------------------\n");

    unsigned int *d_violations = NULL;
    float *d_sink = NULL;
    unsigned int h_violations = 0;

    CUDA_CHECK(cudaMalloc(&d_violations, sizeof(unsigned int)));
    CUDA_CHECK(cudaMalloc(&d_sink, sizeof(float) * (size_t)ACTIVE));
    CUDA_CHECK(cudaMemset(d_violations, 0, sizeof(unsigned int)));
    CUDA_CHECK(cudaMemset(d_sink, 0, sizeof(float) * (size_t)ACTIVE));

    int threads = 256;
    int blocks = (ACTIVE + threads - 1) / threads;

    printf("blocks=%d threads=%d\n", blocks, threads);
    printf("Running kernel loop... watch jtop/tegrastats now.\n");

    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    CUDA_CHECK(cudaEventRecord(start));

    for (int step = 1; step <= STEPS; step++) {
        duj_burn_kernel<<<blocks, threads>>>(step, d_violations, d_sink);
        CUDA_CHECK(cudaGetLastError());

        if (step % 50 == 0) {
            CUDA_CHECK(cudaDeviceSynchronize());
            CUDA_CHECK(cudaMemcpy(&h_violations, d_violations, sizeof(unsigned int), cudaMemcpyDeviceToHost));
            float rate = ((float)h_violations / ((float)ACTIVE * (float)step)) * 100.0f;
            printf("step=%03d exec=%llu violations=%u rate=%.2f%%\n",
                   step,
                   (unsigned long long)ACTIVE * (unsigned long long)step,
                   h_violations,
                   rate);
        }
    }

    CUDA_CHECK(cudaDeviceSynchronize());
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));

    float ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));

    CUDA_CHECK(cudaMemcpy(&h_violations, d_violations, sizeof(unsigned int), cudaMemcpyDeviceToHost));

    unsigned long long total_exec = (unsigned long long)ACTIVE * (unsigned long long)STEPS;
    double hps = (double)total_exec / ((double)ms / 1000.0);

    printf("------------------------------------------------------------\n");
    printf("RESULT\n");
    printf("total_exec=%llu\n", total_exec);
    printf("violations=%u\n", h_violations);
    printf("violation_rate=%.2f%%\n", ((double)h_violations / (double)total_exec) * 100.0);
    printf("time_ms=%.3f\n", ms);
    printf("hydrations_per_second=%.0f\n", hps);
    printf("status=CUDA_BURN_PATH_ACTIVE\n");

    CUDA_CHECK(cudaFree(d_violations));
    CUDA_CHECK(cudaFree(d_sink));
    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));

    return 0;
}
