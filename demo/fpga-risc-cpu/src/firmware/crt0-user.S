.text
.global _start
.type _start, @function

_start:
	/* Save caller registers */
	addi    sp,sp,-16
	sw      ra,12(sp)
 	sw      s0,8(sp)
 	sw      s1,4(sp)
 	sw      s2,0(sp)
	call main
	/* Restore caller registers */
	lw      ra,12(sp)
 	lw      s0,8(sp)
 	lw      s1,4(sp)
 	lw      s2,0(sp)
 	addi    sp,sp,16
	ret
