/*****************************************************************************
 * main.c — MedEdge Transformer Glucose Inference on ZedBoard
 * Architecture: d_model=9, d_ff=22, n_tokens=16
 * 
 * AXI Register Map (base = 0x43C00000):
 *   reg0        (+0x000): STATUS   [bit0=pl_done, bit1=pl_busy]
 *   reg1        (+0x004): CTRL     [bit0=pl_start]
 *   reg2-145    (+0x008 to +0x244): X_mat[144]  16x9 tokens (RW)
 *   reg146-401  (+0x248 to +0x644): S_mat[256]  16x16 attn scores (RO)
 *   reg402-657  (+0x648 to +0xA44): Attn[256]   16x16 softmax (RW)
 *   reg658-666  (+0xA48 to +0xA68): pooled[9]   1x9 output (RO)
 *****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include "xil_io.h"
#include "xil_printf.h"
#include "sleep.h"

/* ── AXI base address ─────────────────────────────────────────────────── */
#define AXI_BASE        0x43C00000

/* ── Register offsets ─────────────────────────────────────────────────── */
#define REG_STATUS      (AXI_BASE + 0x000)   /* RO: bit0=done, bit1=busy */
#define REG_CTRL        (AXI_BASE + 0x004)   /* RW: bit0=pl_start        */
#define REG_X_BASE      (AXI_BASE + 0x008)   /* RW: X_mat[0..143]        */
#define REG_S_BASE      (AXI_BASE + 0x248)   /* RO: S_mat[0..255]        */
#define REG_ATTN_BASE   (AXI_BASE + 0x648)   /* RW: Attn[0..255]         */
#define REG_POOL_BASE   (AXI_BASE + 0xA48)   /* RO: pooled[0..8]         */

/* ── Architecture constants ───────────────────────────────────────────── */
#define N_TOKENS        16
#define D_MODEL         9
#define SCALE           32768.0f
#define GLUCOSE_MIN     0.0f
#define GLUCOSE_MAX     50.0f

/* ── Q15 helpers ──────────────────────────────────────────────────────── */
#define F2Q15(x)   ((int16_t)((x) * SCALE))
#define Q152F(x)   ((float)(x) / SCALE)

/* ── AXI read/write ───────────────────────────────────────────────────── */
#define AXI_WRITE(addr, val)  Xil_Out32((addr), (val))
#define AXI_READ(addr)        Xil_In32((addr))

/* ═══════════════════════════════════════════════════════════════════════
 * Trained weights (from Python export, Q15)
 * ═══════════════════════════════════════════════════════════════════════ */

/* Embedding: 9 weights + 9 biases */
static const int16_t W_emb[D_MODEL] = {
    -1322, -683, -3669, 820, -6206, -2476, -4010, -5063, 4919
};
static const int16_t b_emb[D_MODEL] = {
    -3206, -6992, -5702, 7733, 2331, -4668, 2138, 7176, -3253
};

/* LayerNorm 1 (applied on PS after residual add 1) */
static const float ln1_weight[D_MODEL] = {
    0.42194f, 0.85717f, 0.84891f, 0.91483f, 0.78129f,
    1.01704f, 0.31461f, 0.74526f, 1.50832f
};
static const float ln1_bias[D_MODEL] = {
    0.00155f, 0.18809f, 0.20206f, -0.26205f, -0.04275f,
    -0.04754f, -0.24998f, -0.16107f, -0.00489f
};

/* LayerNorm 2 (applied on PS after residual add 2) */
static const float ln2_weight[D_MODEL] = {
    0.78654f, 1.26151f, 1.16109f, 1.38152f, 1.52737f,
    0.99739f, 0.75785f, 1.05596f, 1.13758f
};
static const float ln2_bias[D_MODEL] = {
    0.49910f,  0.02607f, -0.05542f, 0.16014f, -0.03651f,
   -0.14090f, -0.76041f, -0.03987f, 0.02647f
};

/* Pool weights (softmax, floats — used on PS) */
static const float pool_w[N_TOKENS] = {
    0.004121f, 0.022229f, 0.158733f, 0.058486f, 0.011117f,
    0.141242f, 0.004855f, 0.010264f, 0.099267f, 0.015157f,
    0.019176f, 0.045108f, 0.285119f, 0.042371f, 0.074944f,
    0.007813f
};

/* Regression head */
static const int16_t W_fc[D_MODEL] = {
    -32767, -32767, -32767, 32765, -32767, 32765, -32767, -32767, 32765
};
static const int16_t b_fc = 1584;

/* Feature scaler (from Python StandardScaler) — FILL IN YOUR VALUES */
static const float scaler_mean[16] = {
    0.00981965f, 0.01485424f, 0.01243419f, 0.01719154f, 0.01347255f, 0.01628659f, 0.00930187f, -0.01535558f, -0.02172390f, -0.01367557f, 0.00043971f, 0.00813761f, -0.00856763f, -0.01251204f, 0.01765054f, -0.00527652f, -0.00327971f, -0.02352411f, -0.02558139f, -0.01615506f, -0.02496304f, -0.02280451f, -0.00325553f, -0.01833763f, -0.01451453f, -0.01407757f, -0.01785623f, -0.01578011f, 0.03280430f, -0.01516126f, -0.01789356f, -0.00707138f
};
static const float scaler_std[16] = {
    0.96689330f, 1.00670702f, 0.99601250f, 1.00803075f, 1.00490063f, 0.99715080f, 0.99038007f, 1.01017474f, 1.01395993f, 1.01301393f, 0.99637313f, 0.99561577f, 0.99949183f, 1.01657037f, 1.01185380f, 1.00031133f, 1.01134315f, 1.01181474f, 1.01323393f, 1.01108735f, 1.01052658f, 1.01292235f, 1.00648032f, 1.00739884f, 1.00743039f, 1.00744383f, 1.00891258f, 1.00599648f, 0.98474950f, 1.00900877f, 1.01364036f, 1.00025980f
};

/* ═══════════════════════════════════════════════════════════════════════
 * Helper functions
 * ═══════════════════════════════════════════════════════════════════════ */

/* Saturating Q15 add */
static int16_t q15_add(int16_t a, int16_t b) {
    int32_t s = (int32_t)a + (int32_t)b;
    if (s >  32767) s =  32767;
    if (s < -32768) s = -32768;
    return (int16_t)s;
}

/* Saturating Q15 clamp */
static int16_t q15_clamp(float x) {
    float v = x * SCALE;
    if (v >  32767.0f) return  32767;
    if (v < -32768.0f) return -32768;
    return (int16_t)v;
}

/* LayerNorm in float on PS */
static void layer_norm(float out[D_MODEL], int16_t in_q15[D_MODEL],
                       const float weight[D_MODEL], const float bias[D_MODEL])
{
    float x[D_MODEL];
    float mean = 0.0f, var = 0.0f;
    int i;

    for (i = 0; i < D_MODEL; i++) x[i] = Q152F(in_q15[i]);
    for (i = 0; i < D_MODEL; i++) mean += x[i];
    mean /= D_MODEL;
    for (i = 0; i < D_MODEL; i++) var += (x[i]-mean)*(x[i]-mean);
    var = sqrtf(var/D_MODEL + 1e-5f);
    for (i = 0; i < D_MODEL; i++)
        out[i] = ((x[i]-mean)/var) * weight[i] + bias[i];
}

/* Softmax in float */
static void softmax_2d(float A[N_TOKENS][N_TOKENS]) {
    int i, j;
    for (i = 0; i < N_TOKENS; i++) {
        float mx = A[i][0], s = 0.0f;
        for (j = 1; j < N_TOKENS; j++)
            if (A[i][j] > mx) mx = A[i][j];
        for (j = 0; j < N_TOKENS; j++) {
            A[i][j] = expf(A[i][j] - mx);
            s += A[i][j];
        }
        for (j = 0; j < N_TOKENS; j++)
            A[i][j] /= s;
    }
}

/* ═══════════════════════════════════════════════════════════════════════
 * Main inference function
 * ═══════════════════════════════════════════════════════════════════════ */
float transformer_infer(float raw_features[N_TOKENS])
{
    int i, j;
    uint32_t status;

    /* ── Step 1: Scale features and compute embedding on PS ─────────── */
    /* X_emb[token][feature]: 16 tokens, 9 features each                */
    int16_t X_emb[N_TOKENS][D_MODEL];

    for (i = 0; i < N_TOKENS; i++) {
        /* SNV features: each wavelength becomes one token               */
        float x_scaled = (raw_features[i] - scaler_mean[i]) / scaler_std[i];

        /* Embedding: linear projection from 1D input to D_MODEL         */
        /* emb[i][j] = x_scaled * W_emb[j] + b_emb[j]  (Q15)          */
        for (j = 0; j < D_MODEL; j++) {
            float emb_f = x_scaled * Q152F(W_emb[j]) + Q152F(b_emb[j]);
            /* Clamp to Q15 range [-1, 1) */
            if (emb_f >  0.9999f) emb_f =  0.9999f;
            if (emb_f < -1.0f)   emb_f = -1.0f;
            X_emb[i][j] = F2Q15(emb_f);
        }
    }

    /* ── Step 2: Write X_mat to PL via AXI ──────────────────────────── */
    /* Layout: reg2 = X_emb[0][0], reg3 = X_emb[0][1], ...             */
    /* reg2 + row*D_MODEL + col                                          */
    for (i = 0; i < N_TOKENS; i++) {
        for (j = 0; j < D_MODEL; j++) {
            uint32_t offset = ((i * D_MODEL + j) * 4);
            AXI_WRITE(REG_X_BASE + offset, (uint32_t)(uint16_t)X_emb[i][j]);
        }
    }

    /* ── Step 3: Start PL and wait for S_mat ────────────────────────── */
    AXI_WRITE(REG_CTRL, 0x1);    /* pl_start = 1 */
    usleep(10);
    AXI_WRITE(REG_CTRL, 0x0);    /* pl_start = 0 */

    /* Wait for PL to finish QKV + attention score (SEND_S state)        */
    /* PL asserts pl_busy, then enters SEND_S waiting for pl_start=0    */
    do {
        status = AXI_READ(REG_STATUS);
    } while ((status & 0x2) == 0);  /* wait for pl_busy=1 */

    /* Wait until PL reaches SEND_S (pl_busy still 1, not done yet)     */
    usleep(100);  /* give PL time to compute QKV+attn_score             */

    /* ── Step 4: Read S_mat, apply softmax on PS ────────────────────── */
    float S_float[N_TOKENS][N_TOKENS];
    for (i = 0; i < N_TOKENS; i++) {
        for (j = 0; j < N_TOKENS; j++) {
            uint32_t reg_val = AXI_READ(REG_S_BASE +
                               ((i * N_TOKENS + j) * 4));
            int16_t s_q15 = (int16_t)(reg_val & 0xFFFF);
            S_float[i][j] = Q152F(s_q15);
        }
    }
    softmax_2d(S_float);

    /* ── Step 5: Apply LayerNorm 1 to emb+O (approximated on PS) ───── */
    /* Write Attn (softmax result) back to PL                            */
    for (i = 0; i < N_TOKENS; i++) {
        for (j = 0; j < N_TOKENS; j++) {
            int16_t a_q15 = q15_clamp(S_float[i][j]);
            uint32_t offset = ((i * N_TOKENS + j) * 4);
            AXI_WRITE(REG_ATTN_BASE + offset, (uint32_t)(uint16_t)a_q15);
        }
    }

    /* Apply LayerNorm 1 to X_emb (PS-side approximation)               */
    /* Full LN1 would need O_mat from PL — for now apply to embedding   */
    int16_t ln1_out_q15[N_TOKENS][D_MODEL];
    for (i = 0; i < N_TOKENS; i++) {
        float ln1_f[D_MODEL];
        layer_norm(ln1_f, X_emb[i], ln1_weight, ln1_bias);
        for (j = 0; j < D_MODEL; j++)
            ln1_out_q15[i][j] = q15_clamp(ln1_f[j]);
    }

    /* Re-write X_mat with LN1 output for FF stage                       */
    for (i = 0; i < N_TOKENS; i++) {
        for (j = 0; j < D_MODEL; j++) {
            uint32_t offset = ((i * D_MODEL + j) * 4);
            AXI_WRITE(REG_X_BASE + offset,
                      (uint32_t)(uint16_t)ln1_out_q15[i][j]);
        }
    }

    /* Signal PL to continue (pl_start goes low triggers SEND_S exit)   */
    /* PL is already waiting in SEND_S for pl_start=0 — already done    */

    /* ── Step 6: Wait for full PL computation to finish ────────────── */
    do {
        status = AXI_READ(REG_STATUS);
    } while ((status & 0x1) == 0);  /* wait for pl_done=1 */

    /* ── Step 7: Read pooled output from PL ─────────────────────────── */
    int16_t pooled_q15[D_MODEL];
    for (j = 0; j < D_MODEL; j++) {
        uint32_t reg_val = AXI_READ(REG_POOL_BASE + (j * 4));
        pooled_q15[j] = (int16_t)(reg_val & 0xFFFF);
    }

    /* ── Step 8: Apply LayerNorm 2 on PS then regression head ───────── */
    float ln2_f[D_MODEL];
    layer_norm(ln2_f, pooled_q15, ln2_weight, ln2_bias);

    /* Regression head: y = sum(ln2_f[j] * W_fc[j]) + b_fc  (Q15)     */
    float y = 0.0f;
    for (j = 0; j < D_MODEL; j++)
        y += ln2_f[j] * Q152F(W_fc[j]);
    y += Q152F(b_fc);

    /* Clamp to [-1, 1] */
    if (y >  1.0f) y =  1.0f;
    if (y < -1.0f) y = -1.0f;

    /* ── Step 9: Denormalise to glucose mM ──────────────────────────── */
    float glucose_mM = (y + 1.0f) / 2.0f * (GLUCOSE_MAX - GLUCOSE_MIN)
                       + GLUCOSE_MIN;

    return glucose_mM;
}

/* ═══════════════════════════════════════════════════════════════════════
 * Entry point
 * ═══════════════════════════════════════════════════════════════════════ */
int main(void)
{
    xil_printf("MedEdge Transformer — NIR Glucose Detection\r\n");
    xil_printf("Architecture: d_model=%d, d_ff=22, n_tokens=%d\r\n",
               D_MODEL, N_TOKENS);
    xil_printf("============================================\r\n");

    /* ── TODO: Replace with real NIR measurements ───────────────────── */
    /* Features are SNV-normalised NIR values at 16 wavelengths          */
    /* Wavelengths: 1764.5, 1640.5, 2166.5, 1620.5, 1660.5, 2146.5,    */
    /*              1744.5, 1879.5, 1387.5, 1859.5, 2212.5, 2186.5,    */
    /*              964.5, 1839.5, 1600.5, 2284.5                       */
    float nir_sample[N_TOKENS] = {
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f
    };

    float glucose = transformer_infer(nir_sample);
    xil_printf("Predicted glucose: %d.%02d mM\r\n",
               (int)glucose,
               (int)((glucose - (int)glucose) * 100));

    return 0;
}