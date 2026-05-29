#include <stdio.h>
#include <stdint.h>
#include <cuda_runtime.h>
#include <math.h>

#define POPULATION 10000000
#define ACTIVE 1000000
#define STEPS 200
#define INNER_ITERS 32

#define CUDA_CHECK(call) do {                           \
    cudaError_t err = call;                             \
    if (err != cudaSuccess) {                           \
        fprintf(stderr, "CUDA Error: %s\n",             \
                cudaGetErrorString(err));               \
        return 1;                                       \
    }                                                   \
} while(0)

struct AgentState {
    uint32_t lineage;
    float orbit_state;
    float invariant;
    float local_epoch;
    float dormancy_age;
    float energy;
    float drift;
};

__host__ __device__ __forceinline__
uint32_t xorshift32(uint32_t x) {
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return x;
}

__global__ void control_pool_kernel(
    AgentState* pool,
    unsigned int step,
    unsigned int* violations
) {
    int tid =
        blockIdx.x * blockDim.x +
        threadIdx.x;

    if (tid >= ACTIVE) return;

    uint32_t seed =
        xorshift32(
            tid ^
            (step * 2654435761u));

    int bot_idx =
        seed % POPULATION;

    AgentState state =
        pool[bot_idx];

    float macro_epoch =
        0.5f + step * 0.001f;

    // CONTROL:
    // no DUJ reconciliation

    float orbit =
        state.orbit_state;

    #pragma unroll 8
    for (int k = 0;
         k < INNER_ITERS;
         k++) {

        seed =
            xorshift32(seed + k);

        float noise =
            (float)(seed & 65535)
            / 65535.0f;

        orbit =
            fmaf(
                orbit,
                0.9991f,
                noise * 0.0009f);

        orbit +=
            sinf(orbit + noise)
            * 0.0001f;

        orbit -=
            cosf(
                state.invariant +
                state.drift)
            * 0.00005f;

        float local_gap =
            fabsf(
                orbit -
                state.invariant);

        // CONTROL:
        // uncontrolled drift growth
        state.drift +=
            local_gap *
            0.00005f;
    }

    float event =
        (float)(
            xorshift32(
                seed + 99)
            & 65535)
        / 65535.0f;

    state.energy +=
        event * 0.01f +
        orbit * 0.00001f;

    state.drift +=
        fabsf(
            event -
            state.invariant)
        * 0.002f;

    bool violation =
        (state.drift > 0.05f) ||
        (state.energy >
         state.invariant
         + 0.25f);

    if (violation) {
        atomicAdd(
            violations,
            1);
    }

    // persistent writeback
    state.orbit_state =
        orbit;

    state.local_epoch =
        macro_epoch;

    state.dormancy_age +=
        1.0f;

    pool[bot_idx] =
        state;
}

int main() {

    printf(
        "☠️ CUDA Persistent Pool CONTROL\n");

    printf(
        "population=%d\n",
        POPULATION);

    printf(
        "active_frontier=%d\n",
        ACTIVE);

    printf(
        "steps=%d\n",
        STEPS);

    printf(
        "---------------------------------\n");

    AgentState* h_pool =
        (AgentState*)
        malloc(
            sizeof(AgentState)
            * POPULATION);

    for (int i = 0;
         i < POPULATION;
         i++) {

        uint32_t seed =
            xorshift32(i);

        h_pool[i].lineage =
            i;

        h_pool[i].orbit_state =
            (seed & 65535)
            / 65535.0f;

        h_pool[i].invariant =
            0.5f +
            ((seed >> 8)
            & 255)
            / 510.0f;

        h_pool[i].local_epoch =
            ((seed >> 16)
            & 255)
            / 255.0f;

        h_pool[i].dormancy_age =
            seed % 5000;

        h_pool[i].energy =
            ((seed >> 4)
            & 255)
            / 255.0f;

        h_pool[i].drift =
            ((seed >> 12)
            & 255)
            / 2550.0f;
    }

    AgentState* d_pool;
    unsigned int* d_violations;

    CUDA_CHECK(
        cudaMalloc(
            &d_pool,
            sizeof(AgentState)
            * POPULATION));

    CUDA_CHECK(
        cudaMemcpy(
            d_pool,
            h_pool,
            sizeof(AgentState)
            * POPULATION,
            cudaMemcpyHostToDevice));

    CUDA_CHECK(
        cudaMalloc(
            &d_violations,
            sizeof(unsigned int)));

    CUDA_CHECK(
        cudaMemset(
            d_violations,
            0,
            sizeof(unsigned int)));

    int threads = 256;

    int blocks =
        (ACTIVE +
        threads - 1)
        / threads;

    cudaEvent_t start;
    cudaEvent_t stop;

    cudaEventCreate(
        &start);

    cudaEventCreate(
        &stop);

    cudaEventRecord(
        start);

    for (int step = 1;
         step <= STEPS;
         step++) {

        control_pool_kernel<<<
            blocks,
            threads>>>(
                d_pool,
                step,
                d_violations);

        if (step % 20 == 0) {

            CUDA_CHECK(
                cudaDeviceSynchronize());

            unsigned int h_v;

            CUDA_CHECK(
                cudaMemcpy(
                    &h_v,
                    d_violations,
                    sizeof(unsigned int),
                    cudaMemcpyDeviceToHost));

            float rate =
                ((float)h_v /
                (ACTIVE * step))
                * 100.0f;

            printf(
                "step=%03d "
                "exec=%d "
                "violations=%u "
                "rate=%.2f%%\n",
                step,
                ACTIVE * step,
                h_v,
                rate);
        }
    }

    cudaDeviceSynchronize();

    cudaEventRecord(
        stop);

    cudaEventSynchronize(
        stop);

    float ms = 0.0f;

    cudaEventElapsedTime(
        &ms,
        start,
        stop);

    unsigned int h_v;

    cudaMemcpy(
        &h_v,
        d_violations,
        sizeof(unsigned int),
        cudaMemcpyDeviceToHost);

    unsigned long long total_exec =
        (unsigned long long)
        ACTIVE *
        STEPS;

    printf(
        "---------------------------------\n");

    printf(
        "RESULT\n");

    printf(
        "total_exec=%llu\n",
        total_exec);

    printf(
        "violations=%u\n",
        h_v);

    printf(
        "violation_rate=%.2f%%\n",
        ((float)h_v /
        total_exec)
        * 100.0f);

    printf(
        "time_ms=%.3f\n",
        ms);

    printf(
        "hydrations_per_second=%.0f\n",
        ((float)total_exec /
        (ms / 1000.0f)));

    printf(
        "status=CONTROL_POOL_ACTIVE\n");

    cudaFree(d_pool);
    cudaFree(d_violations);
    free(h_pool);

    return 0;
}
