#define IO_BASE 0x2000000
#define LEDS 0x4
#define UART 0x8

#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>


/*
 * Wait (100Mhz == 100_000 / s)
 * 100 => 1ms
 * 
 * Don't let GCC optimize this.
 */
void sleep(uint32_t milliseconds) {
    uint64_t lim = milliseconds * 10;
    wait(lim);
}
#pragma GCC push_options
#pragma GCC optimize ("O0")
void wait(uint32_t lim)
{
    while (lim-- > 0);
}
#pragma GCC pop_options

/*
 * LEDs
 */
void put_leds_int32(const int32_t c)
{
    *((volatile int32_t *)(IO_BASE + LEDS)) = c;
}

void put_uart_int32(const int32_t c)
{
    *((volatile int32_t *)(IO_BASE + UART)) = c;
}

void print_string(const char *s)
{
    for (const char *p = s; *p; ++p)
    {
        put_uart_int32(*p);
    }
}

int puts(const char *s)
{
    print_string(s);
    put_uart_int32('\n');
    return 1;
}

void setup() {
    // Leds OFF
    puts("Testing leds");
    // Test leds
    uint16_t leds = 1;
    for (uint16_t i = 0; i < 61; i++)
    {
        put_leds_int32(leds);
        leds = ((i/15 % 2) == 0) ? (leds << 1): (leds >> 1);
        sleep(100);
    }
    put_leds_int32(-1);
    sleep(100);
    put_leds_int32(0);
    sleep(100);
    put_leds_int32(-1);
    puts("FPGA initilized");
}

int main(void) {
    setup();
    puts("Hello World!");
    return 0;
}