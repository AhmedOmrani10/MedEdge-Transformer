#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"

#define AXI_BASE 0x43C00000
#define STATUS_REG  (AXI_BASE + 0x00)
#define CTRL_REG    (AXI_BASE + 0x04)

int main() {
    xil_printf("\r\n=== Transformer AXI Test ===\r\n");

    // Small delay to let PL settle
    usleep(100000);

    // Read STATUS register
    u32 status = Xil_In32(STATUS_REG);
    xil_printf("STATUS = 0x%08X\r\n", status);

    // Read CTRL register
    u32 ctrl = Xil_In32(CTRL_REG);
    xil_printf("CTRL   = 0x%08X\r\n", ctrl);

    xil_printf("AXI communication OK!\r\n");

    return 0;
}