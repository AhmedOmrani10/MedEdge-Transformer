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
#define AXI_BASE    0x43C00000
#define REG_STATUS  (AXI_BASE + 0x000)  // reg0
#define REG_CTRL    (AXI_BASE + 0x004)  // reg1
#define REG_X_BASE  (AXI_BASE + 0x008)  // reg2-33  X matrix
#define REG_S_BASE  (AXI_BASE + 0x088)  // reg34-49 S matrix
#define REG_A_BASE  (AXI_BASE + 0x0C8)  // reg50-65 Attn matrix

// ============================================
// Q1.15 helpers
// ============================================
#define SCALE            32768.0f
#define Q15_TO_FLOAT(x)  ((float)(x) / SCALE)
#define FLOAT_TO_Q15(x)  ((int16_t)((x) * SCALE))

// ============================================
// Embedding weights (PS side only)
// nn.Linear(1, 8): weight[8], bias[8]
// For each feature i: X[i][j] = feature[i] * W_emb[j] + b_emb[j]
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
// fc_out: Linear(8, 3)
// weight[3][8], bias[3]
// ============================================
static const int16_t W_fc[3][8] = {
    { 14210, -18098, -10031,  17571, -28653,  11724,  17227,   4656},
    { -2916,  14424,  17510,   6782,  14025, -16192,   7328,  32454},
    {-22802,  13003,   4654, -19833,   7711,  -1992, -14914, -32768}
};

static const int16_t b_fc[3] = {6950, 9209, 3999};

// ============================================
// Iris test sample (first sample)
// Already StandardScaler normalized
// ============================================
static const float iris_sample[4] = {
    -0.9007f,   // sepal length
     1.0321f,   // sepal width
    -1.3412f,   // petal length
    -1.3129f    // petal width
};

static const char* class_names[3] = {"Setosa", "Versicolor", "Virginica"};

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
// Step 1: Compute embedding on PS
// Input: feature scalar (float)
// Output: X[4][8] in Q1.15
// For each position i:
//   X[i][j] = feature[i] * W_emb[j] + b_emb[j]
// ============================================
void compute_embedding(int16_t X[4][8]) {
    int i, j;
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            float val = iris_sample[i] * Q15_TO_FLOAT(W_emb[j])
                      + Q15_TO_FLOAT(b_emb[j]);
            // clamp to Q1.15 range
            if (val >  0.9999f) val =  0.9999f;
            if (val < -1.0f)    val = -1.0f;
            X[i][j] = FLOAT_TO_Q15(val);
        }
    }
}

// ============================================
// Step 2: Write X matrix to PL (reg2-33)
// ============================================
void write_X_to_pl(int16_t X[4][8]) {
    int i, j, idx = 0;
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            reg_write(REG_X_BASE + idx * 4, (uint32_t)(int32_t)X[i][j]);
            idx++;
        }
    }
}

// ============================================
// Step 3: Read S matrix from PL (reg34-49)
// ============================================
void read_S_from_pl(int16_t S[4][4]) {
    int i, j, idx = 0;
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 4; j++) {
            uint32_t val = reg_read(REG_S_BASE + idx * 4);
            S[i][j] = (int16_t)(val & 0xFFFF);
            idx++;
        }
    }
}

// ============================================
// Step 4: Softmax on PS (row by row)
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
// Step 5: Write Attn matrix to PL (reg50-65)
// ============================================
void write_Attn_to_pl(float A[4][4]) {
    int i, j, idx = 0;
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 4; j++) {
            int16_t val = FLOAT_TO_Q15(A[i][j]);
            reg_write(REG_A_BASE + idx * 4, (uint32_t)(int32_t)val);
            idx++;
        }
    }
}

// ============================================
// Main
// ============================================
int main() {
    int i, j;
    printf("=== MedEdge Transformer ===\n\r");

    // Step 1: Embedding
    int16_t X[4][8];
    compute_embedding(X);
    printf("Embedding done:\n\r");
    for (i = 0; i < 4; i++)
        for (j = 0; j < 8; j++)
            printf("  X[%d][%d] = %d\n\r", i, j, X[i][j]);

    // Step 2: Write X to PL
    write_X_to_pl(X);
    printf("X written to PL\n\r");

    // Step 3: Send pl_start
    printf("Sending pl_start...\n\r");
    reg_write(REG_CTRL, 0x1);

    // Step 4: Wait for pl_busy
    int timeout = 0;
    while (!(reg_read(REG_STATUS) & 0x1)) {
        if (++timeout > 1000000) {
            printf("TIMEOUT pl_busy!\n\r");
            return -1;
        }
    }
    printf("PL busy! STATUS=0x%08X\n\r", reg_read(REG_STATUS));

    // Step 5: Clear pl_start
    reg_write(REG_CTRL, 0x0);

    // Step 6: Wait for pl_done
    printf("Waiting for pl_done...\n\r");
    timeout = 0;
    while (!(reg_read(REG_STATUS) & 0x2)) {
        if (++timeout > 5000000) {
            printf("TIMEOUT pl_done! STATUS=0x%08X\n\r",
                   reg_read(REG_STATUS));
            return -1;
        }
    }
    printf("PL done! STATUS=0x%08X\n\r", reg_read(REG_STATUS));

    // Step 7: Read S matrix
    int16_t S[4][4];
    read_S_from_pl(S);
    printf("S matrix:\n\r");
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++)
            printf("  S[%d][%d] = %d (%.4f)\n\r",
                   i, j, S[i][j], Q15_TO_FLOAT(S[i][j]));

    // Step 8: Softmax
    float Attn[4][4];
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++)
            Attn[i][j] = Q15_TO_FLOAT(S[i][j]);
    softmax(Attn);

    printf("Attn matrix (after softmax):\n\r");
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++)
            printf("  Attn[%d][%d] = %.4f\n\r", i, j, Attn[i][j]);

    // Step 9: Write Attn to PL
    write_Attn_to_pl(Attn);
    printf("Attn written to PL\n\r");

    printf("=== Cycle complete! ===\n\r");
    printf("Next: PL computes Attn x V, FF, AvgPool\n\r");
    printf("Then PS runs classifier\n\r");

    return 0;
}