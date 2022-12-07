.equ IO_BASE, 0x2000000

.text
.global _start
.type _start, @function

_start:
    li   gp, IO_BASE
	li   sp, 0x800
	call main
	ebreak
