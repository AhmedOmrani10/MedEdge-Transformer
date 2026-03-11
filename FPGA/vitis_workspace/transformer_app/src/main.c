#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"
#include "math.h"

#define AXI_BASE    0x43C00000
#define STATUS_REG  (AXI_BASE + 0x00)
#define CTRL_REG    (AXI_BASE + 0x04)
#define S_BASE      (AXI_BASE + 0x08)
#define ATTN_BASE   (AXI_BASE + 0x48)

#define READ_REG(offset)        Xil_In32(offset)
#define WRITE_REG(offset, val)  Xil_Out32(offset, val)

#define Q15_TO_FLOAT(x)   ((float)(x) / 32768.0f)
#define FLOAT_TO_Q15(x)   ((int16_t)((x) * 32768.0f))

static void softmax(float *input, float *output) {
    float max_val = input[0];
    for (int i = 1; i < 4; i++) {
        if (input[i] > max_val) max_val = input[i];
    }
    float sum = 0.0f;
    for (int i = 0; i < 4; i++) {
        output[i] = expf(input[i] - max_val);
        sum += output[i];
    }
    for (int i = 0; i < 4; i++) {
        output[i] /= sum;
    }
}

int main() {
    xil_printf("\r\n=== Transformer PS/PL Test ===\r\n");
    usleep(100000);

    // Step 1 - Send pl_start = 1 and KEEP IT HIGH
    // The PL FSM looks for pl_start = 1 to trigger
    xil_printf("Sending pl_start...\r\n");
    WRITE_REG(CTRL_REG, 0x1);  // keep high!
    xil_printf("pl_start sent and held HIGH\r\n");

    // Step 2 - Wait for pl_busy = 1 first (PL started)
    xil_printf("Waiting for pl_busy...\r\n");
    u32 timeout = 0;
    u32 status;
    do {
        status = READ_REG(STATUS_REG);
        timeout++;
        if (timeout > 1000000) {
            xil_printf("ERROR: PL never went busy! STATUS=0x%08X\r\n", status);
            return -1;
        }
    } while ((status & 0x1) == 0);  // wait for bit0 (pl_busy) = 1
    xil_printf("PL is busy! STATUS=0x%08X\r\n", status);

    // Now clear pl_start
    WRITE_REG(CTRL_REG, 0x0);
    xil_printf("pl_start cleared\r\n");

    // Step 3 - Wait for pl_done = 1
    xil_printf("Waiting for PL done...\r\n");
    timeout = 0;
    do {
        status = READ_REG(STATUS_REG);
        timeout++;
        if (timeout % 100000 == 0) {
            xil_printf("STATUS = 0x%08X timeout=%d\r\n", status, timeout);
        }
        if (timeout > 2000000) {
            xil_printf("ERROR: PL timeout! STATUS=0x%08X\r\n", status);
            return -1;
        }
    } while ((status & 0x2) == 0);  // wait for bit1 (pl_done) = 1
    xil_printf("PL done! STATUS=0x%08X\r\n", status);

    // Step 4 - Read S matrix
    float S[4][4];
    xil_printf("\r\nS matrix:\r\n");
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            u32 reg_val = READ_REG(S_BASE + (i*4 + j)*4);
            int16_t raw = (int16_t)(reg_val & 0xFFFF);
            S[i][j] = Q15_TO_FLOAT(raw);
            xil_printf("S[%d][%d] = 0x%04X\r\n", i, j, (u16)raw);
        }
    }

    // Step 5 - Softmax row by row
    float Attn[4][4];
    xil_printf("\r\nAttn matrix:\r\n");
    for (int i = 0; i < 4; i++) {
        softmax(S[i], Attn[i]);
        for (int j = 0; j < 4; j++) {
            xil_printf("Attn[%d][%d] = %d (x10000)\r\n",
                       i, j, (int)(Attn[i][j] * 10000));
        }
    }

    // Step 6 - Write Attn matrix to PL
    xil_printf("\r\nWriting Attn to PL...\r\n");
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            int16_t attn_q15 = FLOAT_TO_Q15(Attn[i][j]);
            WRITE_REG(ATTN_BASE + (i*4 + j)*4, (u32)(u16)attn_q15);
        }
    }

    xil_printf("\r\n=== Cycle complete! ===\r\n");
    return 0;
}