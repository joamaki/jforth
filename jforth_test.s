.include "jforth.s"

.section .bss
.align 4 
.lcomm test_buffer,128

.text
	
/* word2str: Convert register r0 to hexadecimal string pointed to by r1 */
word2str:
	push {r0, r1, r3, r4, lr}

	/* Count number of characters needed */
	mov r2, r0
	mov r3, #0
incr:
	lsr r2, #4
	cmp r2, #0
	add r3, #1
	bgt incr

	/* Make room for the string, store null character */
	add r1, r3
	mov r4, #0
	strb r4, [r1]
	sub r1, #1
	
more:	
	mov r3, r0
	and r3, #0xf
	cmp r3, #10
	bge A
	mov r4, #0x30 /* '0' */
	b store
A:	
	mov r4, #0x41 /* 'A' */
	sub r3, #10
store:
	/* Store character */
	add r4, r3
	strb r4, [r1]
	sub r1, #1

	/* More? */
	lsr r0, #4
	cmp r0, #0
	bgt more

	pop {r0, r1, r3, r4, pc}
	
.global main
main:
	push {lr}
	b jforth_start

	/* tests: */
	bl test_init
	bl word2str_test0
	bl rsp_test1
	bl next_test2
	bl docol_test3
	bl hal_test4
	bl word_test5
	bl number_test6
	pop {pc}


.set TESTVAL, 0xdeadbeef

test_init:
	ldr S, =data_stack_top
	ldr R, =return_stack_top
	mov pc, lr
	

word2str_test0:
	push {lr}

	ldr r0, =test0_msg
	bl puts
	
	ldr r0, =TESTVAL
	ldr r1, =test_buffer
	bl word2str
	
	ldr r0, =test_buffer
	bl puts
	
	pop {pc}

rsp_test1:
	push {lr}
	
	ldr r0, =test1_msg
	bl puts
	
	ldr r4, =TESTVAL
	PUSHRSP r4
	POPRSP r0

	ldr r1, =test_buffer
	bl word2str

	ldr r0, =test_buffer
	bl puts

	pop {pc}

next_test2:
	push {lr}

	ldr r0, =test2_msg
	bl puts

	ldr r2, =test_buffer
	ldr r1, =next_ok
	str r1, [r2]

	mov I, r2
	add I, #4
	str r2, [I]
	
	NEXT

	/* fail! */
	ldr r0, =fail_msg
	bl puts
	pop {pc}

next_ok:	
	ldr r0, =ok_msg
	bl puts
	pop {pc}

/** docol **/
	
docol_test3:
	push {lr}
	ldr r0, =test3_msg
	bl puts

	ldr r2, =test_buffer
	ldr r1, =docol_ok
	str r1, [r2]

	ldr r3, =test_buffer
	add r2, #4
	str r3, [r2]
	mov I, r2
	
	ldr r0, =docol_next /* "current" code word */

	b DOCOL

.align 4
docol_next:
	.int DOCOL
	.int EXIT

docol_ok:
	ldr r0, =ok_msg
	bl puts
	pop {pc}

.macro PRINTWORD
	bl word2str
	ldr r0, =test_buffer
	bl puts
.endm
	
.macro MAKENEXT ptr
	ldr r2, =test_buffer
	ldr r1, =\ptr
	str r1, [r2]

	add r2, #4
	ldr r1, =test_buffer
	str r1, [r2]
	mov I, r2
.endm
	
/** HAL **/
hal_test4:
	push {lr}
	MAKENEXT hal_next1
	b code_KEY
		
hal_next1:
	MAKENEXT hal_next2
	b code_EMIT

hal_next2:
	ldr r0, =ok_msg
	bl puts
	pop {pc}

/** Word **/
word_test5:
	push {lr}
	bl _WORD
	bl puts
	pop {pc}

number_test6:
	push {lr}
	bl _WORD
	mov r2, r0
	bl _NUMBER

	ldr r1, =test_buffer
	bl word2str

	ldr r0, =test_buffer
	bl puts

	pop {pc}

find_test7:
	push {lr}
	pop {pc}
	
	
.section .rodata
.align
fail_msg:
	.asciz "Failed!"

ok_msg:
	.asciz "Ok!"
	
test0_msg:
	.asciz "word2str: "
test1_msg:
	.asciz "rsp: "
test2_msg:
	.asciz "next: "
test3_msg:
	.asciz "docol: "


/* A test word for docol */
.int 0
.byte 4
.ascii "TEST"
.byte 0
TEST:
	.int DOCOL
	.int docol_ok
