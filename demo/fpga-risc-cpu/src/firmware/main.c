#define IO_BASE 0x2000000
#define KERNEL_SPACE 0x0000
#define USER_SPACE 0x1000
#define LEDS 0x4
#define UART 0x8

#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>

/*
 * UART interface.
 */
int32_t get_uart_int32()
{
    return *((volatile int32_t *)(IO_BASE + UART));
}

void put_uart_int32(const int32_t c)
{
    *((volatile int32_t *)(IO_BASE + UART)) = c;
}

int32_t get_uart_txn_int32()
{
    int32_t res;
    // Read char
    while ((res = get_uart_int32()) == -1)
        ;
    return res;
}

/*
 * LEDs
 */
void put_leds_int32(const int32_t c)
{
    *((volatile int32_t *)(IO_BASE + LEDS)) = c;
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

void print_dec(int val)
{
    char buffer[255];
    char *p = buffer;
    if (val < 0)
    {
        put_uart_int32('-');
        print_dec(-val);
        return;
    }
    while (val || p == buffer)
    {
        *(p++) = val % 10;
        val = val / 10;
    }
    while (p != buffer)
    {
        put_uart_int32('0' + *(--p));
    }
}

void print_hex(unsigned int val)
{
    print_hex_digits(val, 8);
}

void print_hex_digits(unsigned int val, int nbdigits)
{
    for (int i = (4 * nbdigits) - 4; i >= 0; i -= 4)
    {
        put_uart_int32("0123456789ABCDEF"[(val >> i) % 16]);
    }
}

int printf(const char *fmt, ...)
{
    va_list ap;

    for (va_start(ap, fmt); *fmt; fmt++)
    {
        if (*fmt == '%')
        {
            fmt++;
            if (*fmt == 's')
                print_string(va_arg(ap, char *));
            else if (*fmt == 'x')
                print_hex(va_arg(ap, int));
            else if (*fmt == 'd')
                print_dec(va_arg(ap, int));
            else if (*fmt == 'c')
                put_uart_int32(va_arg(ap, int));
            else
                put_uart_int32(*fmt);
        }
        else
            put_uart_int32(*fmt);
    }

    va_end(ap);

    return 0;
}

uint8_t compute_crc8_atm(uint8_t *data, uint32_t len)
{
    uint8_t crc = 0xff;
    for (uint32_t i = 0; i < len; i++) {
        uint8_t byte = data[i];
        for (uint32_t j = 0; j < 8; j++) {
            if ((crc >> 7) ^ (byte & 0x01)) {
                crc = ((crc << 1) ^ 0x07) & 0xff;
            } else {
                crc = (crc << 1) & 0xff;
            }
            byte = byte >> 1;
        }
    }
    return crc;
}

void load_user_program() {
    puts("[INFO] Waiting for user program size...");
    uint8_t bit0 = get_uart_txn_int32();
    uint8_t bit1 = get_uart_txn_int32();
    uint8_t bit2 = get_uart_txn_int32();
    uint8_t bit3 = get_uart_txn_int32();
    uint32_t program_size = bit3 + (bit2 << 8) + (bit1 << 16) + (bit0 << 32);
    printf("[INFO] Got program size %d\n", program_size);
    puts("[INFO] Waiting for user program...");
    for (uint32_t i = 0; i < program_size; i++) {
        uint8_t data = get_uart_txn_int32();
        *((uint8_t*)(USER_SPACE + i)) = data;
    }
    uint8_t control_byte = compute_crc8_atm((uint8_t*)(USER_SPACE), program_size);
    uint8_t origin_control_byte = get_uart_txn_int32();
    if (control_byte != origin_control_byte) {
        printf("[ERROR] Invalid Control byte. Got %d, expected %d\n", origin_control_byte, control_byte);
        return;
    }
    puts("[INFO] CRC OK");
    puts("[INFO] Calling user program...");
    (*(int (*)(void))USER_SPACE)();
}

int main()
{
    while (true)
    {
        load_user_program();
    }
}