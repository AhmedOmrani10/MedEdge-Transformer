#include "xil_printf.h"
#include "sleep.h"

int main() {
    while(1) {
        xil_printf("Hello World\n\r");
        sleep(1);
    }
    return 0;
}