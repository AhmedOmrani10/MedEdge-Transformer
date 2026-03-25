#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "xil_io.h"
#include "xparameters.h"
#include "sleep.h"

#define AXI_BASE      0x43C00000
#define REG_STATUS    (AXI_BASE + 0x000)
#define REG_CTRL      (AXI_BASE + 0x004)
#define REG_X_BASE    (AXI_BASE + 0x008)
#define REG_S_BASE    (AXI_BASE + 0x088)
#define REG_A_BASE    (AXI_BASE + 0x0C8)
#define REG_P_BASE    (AXI_BASE + 0x108)

#define SCALE            32768.0f
#define Q15_TO_FLOAT(x)  ((float)(x) / SCALE)
#define FLOAT_TO_Q15(x)  ((int16_t)((x) * SCALE))

#define NUM_SAMPLES 15

static const float iris_samples[NUM_SAMPLES][4] = {
    {-0.9007f,  1.0190f, -1.3402f, -1.3154f},
    {-0.5372f,  1.9398f, -1.1697f, -1.0522f},
    {-0.5372f,  1.4794f, -1.2834f, -1.3154f},
    {-0.5372f,  0.7888f, -1.1697f, -1.3154f},
    {-1.2642f,  0.0982f, -1.2266f, -1.3154f},
    {-0.4160f, -1.7434f,  0.1375f,  0.1325f},
    {-0.1737f, -0.5924f,  0.4217f,  0.1325f},
    {-0.7795f, -0.8226f,  0.0807f,  0.2641f},
    { 0.1898f, -1.9736f,  0.1375f, -0.2624f},
    {-0.2948f, -0.3622f, -0.0898f,  0.1325f},
    { 0.5533f,  0.5586f,  1.2743f,  1.7121f},
    {-0.0525f, -0.8226f,  0.7628f,  0.9223f},
    { 0.5533f, -0.3622f,  1.0469f,  0.7907f},
    { 0.7957f,  0.3284f,  0.7628f,  1.0539f},
    { 1.2803f,  0.3284f,  1.1038f,  1.4488f},
};

static const int expected_labels[NUM_SAMPLES] = {
    0,0,0,0,0, 1,1,1,1,1, 2,2,2,2,2
};

static const char* class_names[3] = {"Setosa","Versicolor","Virginica"};

// New weights from training
static const int16_t W_emb[8] = {
    10048,-10010,-9998,-10006,-10016,-9993,10005,9999
};
static const int16_t b_emb[8] = {
    -5664,-9718,-9704,-9840,-9837,-766,9844,5458
};

static const int16_t W_fc[3][8] = {
    {-14714, -701, -698, -827, -815, 8234, 832, -3548},
    {4574, -19918, -19891, -20036, -20043, -10948, 20039, 15646},
    {-19130, 3697, 3695, 3570, 3586, 12626, -3564, -7942},
    {-18881, 3449, 3447, 3321, 3338, 12378, -3316, -7694}
};

static const int16_t b_fc[3] = {1719, 10784, -6633};

static inline void reg_write(uint32_t addr, uint32_t val) {
    Xil_Out32(addr, val);
}
static inline uint32_t reg_read(uint32_t addr) {
    return Xil_In32(addr);
}

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

void write_X_to_pl(int16_t X[4][8]) {
    int i, j, idx = 0;
    for (i = 0; i < 4; i++)
        for (j = 0; j < 8; j++) {
            reg_write(REG_X_BASE + idx*4, (uint32_t)(int32_t)X[i][j]);
            idx++;
        }
}

void read_S_from_pl(int16_t S[4][4]) {
    int i, j, idx = 0;
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++) {
            S[i][j] = (int16_t)(reg_read(REG_S_BASE + idx*4) & 0xFFFF);
            idx++;
        }
}

void softmax(float A[4][4]) {
    int i, j;
    for (i = 0; i < 4; i++) {
        float mx = A[i][0];
        for (j = 1; j < 4; j++) if (A[i][j] > mx) mx = A[i][j];
        float sum = 0;
        for (j = 0; j < 4; j++) { A[i][j] = expf(A[i][j]-mx); sum += A[i][j]; }
        for (j = 0; j < 4; j++) A[i][j] /= sum;
    }
}

void write_Attn_to_pl(float A[4][4]) {
    int i, j, idx = 0;
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++) {
            reg_write(REG_A_BASE + idx*4,
                      (uint32_t)(int32_t)FLOAT_TO_Q15(A[i][j]));
            idx++;
        }
}

void read_pooled_from_pl(int16_t pooled[8]) {
    int i;
    for (i = 0; i < 8; i++)
        pooled[i] = (int16_t)(reg_read(REG_P_BASE + i*4) & 0xFFFF);
}

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

int run_sample(int idx) {
    int i, j, timeout;
    const float* sample = iris_samples[idx];

    reg_write(REG_CTRL, 0x0);
    usleep(100000);

    int16_t X[4][8];
    compute_embedding(sample, X);

    // DEBUG: print embedding for sample 0
    if (idx == 0) {
        printf("X[0]=[%d,%d,%d,%d,%d,%d,%d,%d]\n\r",
               X[0][0],X[0][1],X[0][2],X[0][3],
               X[0][4],X[0][5],X[0][6],X[0][7]);
    }

    write_X_to_pl(X);
    reg_write(REG_CTRL, 0x1);

    timeout = 0;
    while (!(reg_read(REG_STATUS) & 0x1)) {
        if (++timeout > 1000000) {
            printf("[%2d] TIMEOUT pl_busy!\n\r", idx);
            return -1;
        }
    }

    usleep(1000);

    int16_t S[4][4];
    read_S_from_pl(S);

    // DEBUG: print S for sample 0
    if (idx == 0) {
        printf("S[0]=[%d,%d,%d,%d]\n\r",
               S[0][0],S[0][1],S[0][2],S[0][3]);
        printf("S[1]=[%d,%d,%d,%d]\n\r",
               S[1][0],S[1][1],S[1][2],S[1][3]);
        printf("S[2]=[%d,%d,%d,%d]\n\r",
               S[2][0],S[2][1],S[2][2],S[2][3]);
        printf("S[3]=[%d,%d,%d,%d]\n\r",
               S[3][0],S[3][1],S[3][2],S[3][3]);
    }

    float Attn[4][4];
    for (i = 0; i < 4; i++)
        for (j = 0; j < 4; j++)
            Attn[i][j] = Q15_TO_FLOAT(S[i][j]);
    softmax(Attn);

    // DEBUG: print Attn for sample 0
    if (idx == 0) {
        printf("A[0]=[%.4f,%.4f,%.4f,%.4f]\n\r",
               Attn[0][0],Attn[0][1],Attn[0][2],Attn[0][3]);
    }

    write_Attn_to_pl(Attn);
    reg_write(REG_CTRL, 0x0);

    timeout = 0;
    while (!(reg_read(REG_STATUS) & 0x2)) {
        if (++timeout > 200000000) {
            printf("[%2d] TIMEOUT pl_done! STATUS=0x%08X\n\r",
                   idx, reg_read(REG_STATUS));
            return -1;
        }
    }

    int16_t pooled[8];
    read_pooled_from_pl(pooled);

    // DEBUG: print pooled for sample 0
    if (idx == 0) {
        printf("pooled=[%d,%d,%d,%d,%d,%d,%d,%d]\n\r",
               pooled[0],pooled[1],pooled[2],pooled[3],
               pooled[4],pooled[5],pooled[6],pooled[7]);
    }

    float logits[3];
    int pred = classify(pooled, logits);

    int true_label = expected_labels[idx];
    printf("[%2d] true=%-12s pred=%-12s %s  "
           "logits=[%.3f,%.3f,%.3f]\n\r",
           idx,
           class_names[true_label],
           class_names[pred],
           (pred==true_label) ? "OK" : "XX",
           logits[0], logits[1], logits[2]);

    timeout = 0;
    while (reg_read(REG_STATUS) & 0x3) {
        if (++timeout > 200000000) {
            printf("[%2d] TIMEOUT IDLE!\n\r", idx);
            return -1;
        }
    }
    return pred;
}

int main() {
    int i, correct = 0, pred;
    printf("=== MedEdge Transformer - 15 Sample Test ===\n\r");
    for (i = 0; i < NUM_SAMPLES; i++) {
        pred = run_sample(i);
        if (pred >= 0 && pred == expected_labels[i])
            correct++;
    }
    printf("\n\r=== RESULTS: %d/%d correct (%.1f%%) ===\n\r",
           correct, NUM_SAMPLES,
           100.0f*correct/NUM_SAMPLES);
    return 0;
}