	
	
/* Forth virtual machine register allocation */
S .req r8			/* Data stack */
R .req r9			/* Return stack */
I .req r10 			/* Instruction */
W .req r11			/* Word pointer */
U .req r12			/* User pointer */

/* Stack sizes */
.set DATA_STACK_SIZE, 8192
.set RETURN_STACK_SIZE, 8192
.set HERE_SIZE, 8192
	
/* Globals */
.bss
.align 2
data_stack:
	.space DATA_STACK_SIZE
data_stack_top:
	
return_stack:
	.space RETURN_STACK_SIZE
return_stack_top:
	
here_start:
	.space HERE_SIZE
	
/* NEXT: Load next code word from instruction register, increment it and jump */
.macro NEXT
	ldr r0, [I]     /* I points to code word address, fetch it */
	add I, #4       /* Advance I */
	ldr pc, [r0]    /* Jump to code word */
.endm

/* PUSHSP: Push to data stack */
.macro PUSHSP reg
	sub S, #4
	str \reg, [S]
.endm

/* POPSP: Pop from data stack */
.macro POPSP reg
	ldr \reg, [S]
	add S, #4
.endm
	
/* PUSHRSP: Push to return stack */
.macro PUSHRSP reg
	sub R, #4
	str \reg, [R]
.endm

/* POPRSP: Pop from return stack */
.macro POPRSP reg
	ldr \reg, [R]
	add R, #4
.endm

/* Dictionary flags */
.set F_IMMED, 0x80
.set F_HIDDEN, 0x20
.set F_LENMASK, 0x1f

.set link, 0

/* defword: Define a (FORTH) word */
.macro defword name, namelen, flags=0, label
.section .rodata
.global name_\label
name_\label:
	.int link
	.set link, name_\label  	/* Update link */
	.byte \flags + \namelen 	/* Flags and name length */
	.ascii "\name"
	.align 2
	.global \label
\label:
	.int DOCOL
	/* Words go here */
.endm

/* defcode: Define a code word */
.macro defcode name, namelen, flags=0, label
.section .rodata
.align 2
.global name_\label
name_\label:
	.int link
	.set link, name_\label
	.byte \flags + \namelen
	.ascii "\name"
	.align 2
	.global \label
\label:
	.int code_\label
	.text
	.global code_\label
code_\label:
	/* Assembler goes here */
	.endm

/* defvar: Define variable */
.macro defvar name, namelen, flags=0, label, initial=0
defcode \name, \namelen, \flags, \label
	ldr r0, =var_\name
	PUSHSP r0
	NEXT
.data
.align 2
.global var_\name
var_\name:
	.int \initial
.endm

/* Built-in variables */
defvar "STATE",5,,STATE
defvar "HERE",4,,HERE
defvar "LATEST",6,,LATEST,name_LAST
defvar "S0",2,,SZ
defvar "BASE",4,,BASE,10
	
.text
.align 2

/* defconst: Define constant */
.macro defconst name, namelen, flags=0, label, value
defcode \name, \namelen, \flags, \label
	ldr r0, =\value
	PUSHSP r0
	NEXT
.endm

/* Built-in constants */
defconst "R0",2,,RZ,return_stack_top
defconst "DOCOL",5,,__DOCOL,DOCOL
defconst "F_IMMED",7,,__F_IMMED,F_IMMED
defconst "F_HIDDEN",8,,__F_HIDDEN,F_HIDDEN
defconst "F_LENMASK",9,,__F_LENMASK,F_LENMASK
	
/* DOCOL: Do colon, i.e. execute word */
DOCOL:
	PUSHRSP I	/* Save return address */
	/* After NEXT r0 has the current code word. Add 4 to get first data word */
	add I, r0, #4
	NEXT		/* And we can jump to it with NEXT. */

/* jforth_start: Initialize and start the interpreter!
 */
.global jforth_init	
jforth_start:
	/* Setup data stack */
	ldr r0, =data_stack_top
	mov S, r0

	/* Setup return stack */
	ldr r0, =return_stack_top
	mov R, r0

	/* Setup HERE */
	ldr r0, =here_start
	ldr r1, =var_HERE
	str r0, [r1]
	

	ldr I, =cold_start
	NEXT

cold_start:
	.int QUIT

.include "prim.s"
.include "hal.s"

/* Last word defined */
defcode "LAST",4,,LAST
	NEXT