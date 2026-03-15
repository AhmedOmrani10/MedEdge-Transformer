#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "xil_io.h"
#include "xparameters.h"
#include "sleep.h"

// ============================================
// AXI Register Map
// ============================================
#define AXI_BASE      0x43C00000
#define REG_STATUS    (AXI_BASE + 0x000)
#define REG_CTRL      (AXI_BASE + 0x004)
#define REG_X_BASE    (AXI_BASE + 0x008)
#define REG_S_BASE    (AXI_BASE + 0x088)
#define REG_A_BASE    (AXI_BASE + 0x0C8)
#define REG_P_BASE    (AXI_BASE + 0x108)

// ============================================
// Q1.15 helpers
// ============================================
#define SCALE            32768.0f
#define Q15_TO_FLOAT(x)  ((float)(x) / SCALE)
#define FLOAT_TO_Q15(x)  ((int16_t)((x) * SCALE))

// ============================================
// Test samples (15 total, 5 per class)
// ============================================
#define NUM_SAMPLES 15

static const float iris_samples[NUM_SAMPLES][4] = {
    {-0.9007f,  1.0190f, -1.3402f, -1.3154f},  // [ 0] idx=  0 Setosa
    {-0.5372f,  1.9398f, -1.1697f, -1.0522f},  // [ 1] idx=  5 Setosa
    {-0.5372f,  1.4794f, -1.2834f, -1.3154f},  // [ 2] idx= 10 Setosa
    {-0.5372f,  0.7888f, -1.1697f, -1.3154f},  // [ 3] idx= 20 Setosa
    {-1.2642f,  0.0982f, -1.2266f, -1.3154f},  // [ 4] idx= 30 Setosa
    {-0.4160f, -1.7434f,  0.1375f,  0.1325f},  // [ 5] idx= 53 Versicolor
    {-0.1737f, -0.5924f,  0.4217f,  0.1325f},  // [ 6] idx= 55 Versicolor
    {-0.7795f, -0.8226f,  0.0807f,  0.2641f},  // [ 7] idx= 59 Versicolor
    { 0.1898f, -1.9736f,  0.1375f, -0.2624f},  // [ 8] idx= 62 Versicolor
    {-0.2948f, -0.3622f, -0.0898f,  0.1325f},  // [ 9] idx= 64 Versicolor
    { 0.5533f,  0.5586f,  1.2743f,  1.7121f},  // [10] idx=100 Virginica
    {-0.0525f, -0.8226f,  0.7628f,  0.9223f},  // [11] idx=101 Virginica
    { 0.5533f, -0.3622f,  1.0469f,  0.7907f},  // [12] idx=103 Virginica
    { 0.7957f,  0.3284f,  0.7628f,  1.0539f},  // [13] idx=110 Virginica
    { 1.2803f,  0.3284f,  1.1038f,  1.4488f},  // [14] idx=120 Virginica
};

static const int expected_labels[NUM_SAMPLES] = {
    0, 0, 0, 0, 0,
    1, 1, 1, 1, 1,
    2, 2, 2, 2, 2
};

static const char* class_names[3] = {"Setosa", "Versicolor", "Virginica"};

// ============================================
// Embedding weights (PS side)
// ============================================
static const int16_t W_emb[8] = {
    21759, 14418, -18176, 32765,
    25929, 29673, -32768, -32534
};

static const int16_t b_emb[8] = {
    11527, -997, -32768, 12623,
    -27958, 29330, -28496, -16842
};

// ============================================
// Classifier weights (PS side)
// ============================================
static const int16_t W_fc[3][8] = {
    { 14210, -18098, -10031,  17571, -28653,  11724,  17227,   4656},
    { -2916,  14424,  17510,   6782,  14025, -16192,   7328,  32454},
    {-22802,  13003,   4654, -19833,   7711,  -1992, -14914, -32768}
};

static const int16_t b_fc[3] = {6950, 9209, 3999};

// ============================================
// Helpers
// ============================================
static inline void reg_write(uint32_t addr, uint32_t val) {
    Xil_Out32(addr, val);
}

static inline uint32_t reg_read(uint32_t addr) {
    return Xil_In32(addr);
}

// ============================================
// Compute embedding
// ============================================
void compute_embedding(const float sample[4], int16_t X[4][8]) {
    int i, j;
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            float val = sample[i] * Q15_TO_FLOAT(W_emb[j])
                      + Q15_TO_FLOAT(b_emb[j]);
            if (val >  0.9999f) val =  0.9999f;
            if (val < -1.0f)    val = -1.0f;
            X[i][j] = FLOAT_TO_Q15(val);
        }
    }
}

// ============================================
// Write X to PL
// ============================================
void write_X_to_pl(int16_t X[4][8]) {
    int i, j, idx = 0;
    for (i = 0; i < 4; i++)
        for (j = 0; j < 8; j++) {
            reg_write(REG_X_BASE + idx * 4, (uint32_t)(int32_t)X[i][j]);
            idx++;
        }
}

// ============================================
// Read S from PL
// ============================================
void read_S_from_pl(int16_t S[4][4]) {
    int i, j, idx = 0;
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++) {
            uint32_t val = reg_read(REG_S_BASE + idx * 4);
            S[i][j] = (int16_t)(val & 0xFFFF);
            idx++;
        }
}

// ============================================
// Softmax
// ============================================
void softmax(float A[4][4]) {
    int i, j;
    for (i = 0; i < 4; i++) {
        float max_val = A[i][0];
        for (j = 1; j < 4; j++)
            if (A[i][j] > max_val) max_val = A[i][j];
        float sum = 0.0f;
        for (j = 0; j < 4; j++) {
            A[i][j] = expf(A[i][j] - max_val);
            sum += A[i][j];
        }
        for (j = 0; j < 4; j++)
            A[i][j] /= sum;
    }
}

// ============================================
// Write Attn to PL
// ============================================
void write_Attn_to_pl(float A[4][4]) {
    int i, j, idx = 0;
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++) {
            int16_t val = FLOAT_TO_Q15(A[i][j]);
            reg_write(REG_A_BASE + idx * 4, (uint32_t)(int32_t)val);
            idx++;
        }
}

// ============================================
// Read pooled from PL
// ============================================
void read_pooled_from_pl(int16_t pooled[8]) {
    int i;
    for (i = 0; i < 8; i++) {
        uint32_t val = reg_read(REG_P_BASE + i * 4);
        pooled[i] = (int16_t)(val & 0xFFFF);
    }
}

// ============================================
// Classifier
// ============================================
int classify(int16_t pooled[8], float logits_out[3]) {
    int i, j;
    for (i = 0; i < 3; i++) {
        float acc = Q15_TO_FLOAT(b_fc[i]);
        for (j = 0; j < 8; j++)
            acc += Q15_TO_FLOAT(pooled[j]) * Q15_TO_FLOAT(W_fc[i][j]);
        logits_out[i] = acc;
    }
    int pred = 0;
    for (i = 1; i < 3; i++)
        if (logits_out[i] > logits_out[pred]) pred = i;
    return pred;
}

// ============================================
// Run one sample through full pipeline
// ============================================
int run_sample(int sample_idx) {
    int i, j;
    int timeout;
    const float* sample = iris_samples[sample_idx];

    printf("[%2d] Starting...\n\r", sample_idx);

    // Step 0: force clean state — just clear ctrl and wait fixed delay
    reg_write(REG_CTRL, 0x0);
    usleep(100000);  // 100ms
    printf("[%2d] STATUS = 0x%08X\n\r",
           sample_idx, reg_read(REG_STATUS));

    // Step 1: Embedding
    int16_t X[4][8];
    compute_embedding(sample, X);
    printf("[%2d] Embedding done\n\r", sample_idx);

    // Step 2: Write X to PL
    write_X_to_pl(X);
    printf("[%2d] X written\n\r", sample_idx);

    // Step 3: Send pl_start=1
    reg_write(REG_CTRL, 0x1);
    printf("[%2d] pl_start sent, STATUS=0x%08X\n\r",
           sample_idx, reg_read(REG_STATUS));

    // Step 4: Wait pl_busy=1
    timeout = 0;
    while (!(reg_read(REG_STATUS) & 0x1)) {
        if (++timeout > 1000000) {
            printf("[%2d] TIMEOUT pl_busy! STATUS=0x%08X\n\r",
                   sample_idx, reg_read(REG_STATUS));
            return -1;
        }
    }
    printf("[%2d] PL busy, STATUS=0x%08X\n\r",
           sample_idx, reg_read(REG_STATUS));

    // Step 5: Small delay for S to stabilize
    usleep(1000);

    // Step 6: Read S matrix
    int16_t S[4][4];
    read_S_from_pl(S);
    printf("[%2d] S read: [%d,%d,%d,%d]\n\r",
           sample_idx, S[0][0], S[0][1], S[0][2], S[0][3]);

    // Step 7: Softmax
    float Attn[4][4];
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++)
            Attn[i][j] = Q15_TO_FLOAT(S[i][j]);
    softmax(Attn);

    // Step 8: Write Attn FIRST then clear pl_start
    write_Attn_to_pl(Attn);
    printf("[%2d] Attn written\n\r", sample_idx);

    reg_write(REG_CTRL, 0x0);
    printf("[%2d] pl_start cleared, STATUS=0x%08X\n\r",
           sample_idx, reg_read(REG_STATUS));

    // Step 9: Wait pl_done=1
    printf("[%2d] Waiting pl_done...\n\r", sample_idx);
    timeout = 0;
    while (!(reg_read(REG_STATUS) & 0x2)) {
        if (++timeout > 200000000) {
            printf("[%2d] TIMEOUT pl_done! STATUS=0x%08X\n\r",
                   sample_idx, reg_read(REG_STATUS));
            return -1;
        }
    }
    printf("[%2d] PL done, STATUS=0x%08X\n\r",
           sample_idx, reg_read(REG_STATUS));

    // Step 10: Read pooled
    int16_t pooled[8];
    read_pooled_from_pl(pooled);
    printf("[%2d] pooled=[%d,%d,%d,%d,%d,%d,%d,%d]\n\r",
           sample_idx,
           pooled[0], pooled[1], pooled[2], pooled[3],
           pooled[4], pooled[5], pooled[6], pooled[7]);

    // Step 11: Classify
    float logits[3];
    int pred = classify(pooled, logits);

    // Step 12: Print result
    int true_label = expected_labels[sample_idx];
    printf("[%2d] true=%-12s pred=%-12s %s  "
           "logits=[%.3f, %.3f, %.3f]\n\r",
           sample_idx,
           class_names[true_label],
           class_names[pred],
           (pred == true_label) ? "OK" : "XX",
           logits[0], logits[1], logits[2]);

    // Step 13: Wait for PL to go back to IDLE (status=0)
    printf("[%2d] Waiting IDLE...\n\r", sample_idx);
    timeout = 0;
    while (reg_read(REG_STATUS) & 0x3) {
        if (++timeout > 200000000) {
            printf("[%2d] TIMEOUT waiting IDLE! STATUS=0x%08X\n\r",
                   sample_idx, reg_read(REG_STATUS));
            return -1;
        }
    }
    printf("[%2d] PL IDLE OK\n\r\n\r", sample_idx);

    return pred;
}

// ============================================
// Main
// ============================================
int main() {
    int i;
    int correct = 0;
    int pred;

    printf("=== MedEdge Transformer - 15 Sample Test ===\n\r");

    for (i = 0; i < NUM_SAMPLES; i++) {
        pred = run_sample(i);
        if (pred >= 0 && pred == expected_labels[i])
            correct++;
    }

    printf("============================================\n\r");
    printf("=== RESULTS: %d/%d correct (%.1f%%) ===\n\r",
           correct, NUM_SAMPLES,
           100.0f * correct / NUM_SAMPLES);

    return 0;
}