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
#define REG_STATUS    (AXI_BASE + 0x000)  // reg0
#define REG_CTRL      (AXI_BASE + 0x004)  // reg1
#define REG_X_BASE    (AXI_BASE + 0x008)  // reg2-33   X matrix
#define REG_S_BASE    (AXI_BASE + 0x088)  // reg34-49  S matrix
#define REG_A_BASE    (AXI_BASE + 0x0C8)  // reg50-65  Attn matrix
#define REG_P_BASE    (AXI_BASE + 0x108)  // reg66-73  pooled[8]

// ============================================
// Q1.15 helpers
// ============================================
#define SCALE            32768.0f
#define Q15_TO_FLOAT(x)  ((float)(x) / SCALE)
#define FLOAT_TO_Q15(x)  ((int16_t)((x) * SCALE))

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
// fc_out: Linear(8, 3)
// ============================================
static const int16_t W_fc[3][8] = {
    { 14210, -18098, -10031,  17571, -28653,  11724,  17227,   4656},
    { -2916,  14424,  17510,   6782,  14025, -16192,   7328,  32454},
    {-22802,  13003,   4654, -19833,   7711,  -1992, -14914, -32768}
};

static const int16_t b_fc[3] = {6950, 9209, 3999};

// ============================================
// Iris test sample
// ============================================
static const float iris_sample[4] = {
    -0.9007f,
     1.0321f,
    -1.3412f,
    -1.3129f
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
// ============================================
void compute_embedding(int16_t X[4][8]) {
    int i, j;
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            float val = iris_sample[i] * Q15_TO_FLOAT(W_emb[j])
                      + Q15_TO_FLOAT(b_emb[j]);
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
// Step 6: Read pooled[8] from PL (reg66-73)
// ============================================
void read_pooled_from_pl(int16_t pooled[8]) {
    int i;
    for (i = 0; i < 8; i++) {
        uint32_t val = reg_read(REG_P_BASE + i * 4);
        pooled[i] = (int16_t)(val & 0xFFFF);
    }
}

// ============================================
// Step 7: Classifier fc_out Linear(8,3) + ArgMax
// ============================================
int classify(int16_t pooled[8]) {
    int i, j;
    float logits[3];
    for (i = 0; i < 3; i++) {
        float acc = Q15_TO_FLOAT(b_fc[i]);
        for (j = 0; j < 8; j++)
            acc += Q15_TO_FLOAT(pooled[j]) * Q15_TO_FLOAT(W_fc[i][j]);
        logits[i] = acc;
        printf("  logit[%d] (%s) = %.4f\n\r", i, class_names[i], acc);
    }
    int pred = 0;
    for (i = 1; i < 3; i++)
        if (logits[i] > logits[pred]) pred = i;
    return pred;
}

// ============================================
// Main
// ============================================
int main() {
    int i, j;
    int timeout;
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

    // Step 3: Send pl_start=1
    printf("Sending pl_start...\n\r");
    reg_write(REG_CTRL, 0x1);

    // Step 4: Wait for pl_busy=1
    timeout = 0;
    while (!(reg_read(REG_STATUS) & 0x1)) {
        if (++timeout > 1000000) {
            printf("TIMEOUT pl_busy!\n\r");
            return -1;
        }
    }
    printf("PL busy! STATUS=0x%08X\n\r", reg_read(REG_STATUS));

    // Step 5: Wait for pl_done=1 (S matrix ready)
    printf("Waiting for pl_done (S ready)...\n\r");
    timeout = 0;
    while (!(reg_read(REG_STATUS) & 0x2)) {
        if (++timeout > 50000000) {
            printf("TIMEOUT pl_done! STATUS=0x%08X\n\r",
                   reg_read(REG_STATUS));
            return -1;
        }
    }
    printf("S ready! STATUS=0x%08X\n\r", reg_read(REG_STATUS));

    // Step 6: Read S matrix
    int16_t S[4][4];
    read_S_from_pl(S);
    printf("S matrix:\n\r");
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++)
            printf("  S[%d][%d] = %d (%.4f)\n\r",
                   i, j, S[i][j], Q15_TO_FLOAT(S[i][j]));

    // Step 7: Softmax → Attn
    float Attn[4][4];
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++)
            Attn[i][j] = Q15_TO_FLOAT(S[i][j]);
    softmax(Attn);
    printf("Attn matrix (after softmax):\n\r");
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++)
            printf("  Attn[%d][%d] = %.4f\n\r", i, j, Attn[i][j]);

    // Step 8: Write Attn to PL FIRST
    write_Attn_to_pl(Attn);
    printf("Attn written to PL\n\r");

    // Step 9: NOW clear pl_start=0 to signal PL to continue
    reg_write(REG_CTRL, 0x0);
    printf("pl_start cleared — PL continuing with AttnOut+FF+Pool...\n\r");

    // Step 10: Wait for pl_busy to go low (PL back to IDLE = DONE_ST finished)
    printf("Waiting for PL full pipeline done...\n\r");
    timeout = 0;
    while (reg_read(REG_STATUS) & 0x1) {
        if (++timeout > 200000000) {
            printf("TIMEOUT full pipeline! STATUS=0x%08X\n\r",
                   reg_read(REG_STATUS));
            return -1;
        }
    }
    printf("PL pipeline done! STATUS=0x%08X\n\r", reg_read(REG_STATUS));

    // Step 11: Read pooled[8]
    int16_t pooled[8];
    read_pooled_from_pl(pooled);
    printf("Pooled vector:\n\r");
    for (i = 0; i < 8; i++)
        printf("  pooled[%d] = %d (%.4f)\n\r",
               i, pooled[i], Q15_TO_FLOAT(pooled[i]));

    // Step 12: Classifier + ArgMax
    printf("Classifier logits:\n\r");
    int pred = classify(pooled);
    printf("\n\r=== PREDICTION: %s ===\n\r", class_names[pred]);

    return 0;
}