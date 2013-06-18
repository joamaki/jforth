/* HAL library for qemu user */

defcode "KEY",3,,KEY
	bl _KEY
	PUSHSP r0
	NEXT
_KEY:
	push {lr}
	bl getchar
	pop {pc}
	
defcode "EMIT",4,,EMIT
	POPSP r0
	bl putchar
	NEXT

defcode "TELL",4,,TELL
	mov r0, #1
	POPSP r1
	POPSP r2
	bl write
	NEXT

defcode "SAYTEST",7,,SAYTEST
	ldr r0, =testmsg
	bl puts
	NEXT

.section .rodata
testmsg:	.ascii "TEST\n\0"
.text

/* TODO: Remove. */
ERROR:
	push {lr}
	ldr r0, =errmsg
	bl puts
	pop {pc}

.section .rodata
errmsg:	.ascii "?\0"
.text