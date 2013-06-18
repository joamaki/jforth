/* Forth assembly primitives */

/* TODO: Cleanup to multiple files (or merge back to jforth.s) */
	
defcode "EXIT",4,,EXIT
	POPRSP I
	NEXT
	
defcode "DROP",4,,DROP
	POPSP r0
	NEXT

defcode "SWAP",4,,SWAP
	POPSP r0
	POPSP r1
	PUSHSP r0
	PUSHSP r1
	NEXT

defcode "DUP",3,,DUP
	ldr r0, [S]
	PUSHSP r0

defcode "OVER",4,,OVER
	ldr r0, [S,#4]
	PUSHSP r0
	NEXT
	
defcode "ROT",3,,ROT
	POPSP r0
	POPSP r1
	POPSP r2
	PUSHSP r1
	PUSHSP r0
	PUSHSP r3
	NEXT

defcode "-ROT",4,,NROT
	POPSP r0
	POPSP r1
	POPSP r2
	PUSHSP r0
	PUSHSP r2
	PUSHSP r1
	NEXT

/* <-- TODO  */

defcode "+",1,,ADD
	POPSP r0
	POPSP r1
	add r0, r1
	PUSHSP r0
	NEXT

defcode "-",1,,SUB
	POPSP r0
	POPSP r1
	sub r0, r1
	PUSHSP r0
	NEXT

defcode "*",1,,MUL
	POPSP r0
	POPSP r1
	mul r0, r1
	PUSHSP r0
	NEXT

defcode "4+",2,,INCR4
	POPSP r0
	add r0, #4
	PUSHSP r0

/* TODO /MOD */

defcode "=",1,,EQU
	POPSP r0
	POPSP r1
	cmp r0, r1
	moveq r2, #-1 /* Equal = -1 (all ones) */
	movne r2, #0 /* Non-equal = 0 */
	PUSHSP r2
	NEXT

defcode "0>=",3,,ZGE
	POPSP r0
	mvn r0, r0 /* invert */
	mov r0, r0, lsr #31 /* take just sign */
	PUSHSP r0
	NEXT
	
defcode "AND",3,,AND
	POPSP r0
	POPSP r1
	and r0, r1
	PUSHSP r0
	NEXT

defcode "OR",2,,OR
	POPSP r0
	POPSP r1
	orr r0, r1
	PUSHSP r0
	NEXT
	
defcode "XOR",3,,XOR
	POPSP r0
	POPSP r1
	eor r0, r1
	PUSHSP r0
	NEXT

defcode "INVERT",6,,INVERT
	POPSP r0
	mvn r0, r0
	PUSHSP r0
	NEXT

/* Memory manipulation words */
defcode "@",1,,FETCH
	POPSP r0
	ldr r0, [r0]
	PUSHSP r0
	NEXT

defcode "!",1,,STORE
	POPSP r0 /* Address */
	POPSP r1 /* Value */
	str r1, [r0]
	NEXT

defcode "+!",2,,ADDSTORE
	POPSP r0 /* Address */
	POPSP r1 /* Increment */
	ldr r2, [r0]
	add r2, r1
	str r2, [r0]
	NEXT

defcode "-!",2,,SUBSTORE
	POPSP r0 /* Address */
	POPSP r1 /* Decrement */
	ldr r2, [r0]
	sub r2, r1
	str r2, [r0]
	NEXT

/* TODO: Byte-sized words */
	
defcode "LIT",3,,LIT
	ldr r0, [I]
	add I, #4
	PUSHSP r0
	NEXT
	
/* Return stack words */
defcode ">R",2,,TOR
	POPSP r0
	PUSHRSP r0
	NEXT

defcode "R>",2,,FROMR
	POPRSP r0
	PUSHSP r0
	NEXT

defcode "RSP@",4,,RSPFETCH
	PUSHSP R
	NEXT

defcode "RSP!",4,,RSPSTORE
	POPSP r0
	mov r0, R
	NEXT
	
defcode "RDROP",5,,RDROP
	add R, #4
	NEXT

/* Data stack words */
defcode "DSP@",4,,DSPFETCH
	mov r0, S
	PUSHSP r0
	NEXT
	
defcode "DSP!",4,,DSPSTORE
	POPSP r0
	mov S, r0
	NEXT

/* BRANCH: Unconditional loop */
defcode "BRANCH",6,,BRANCH
	ldr r0, [I]
	add I, r0
	NEXT

/* 0BRANCH: Branch if top of stack is zero */
defcode "0BRANCH",7,,ZBRANCH
	POPSP r0
	cmp r0, #0
	beq code_BRANCH /* Jump to BRANCH */
	add I, #4 /* Skip offset */
	NEXT
	
/* QUIT: Reset stack & return to interpreter */
defword "QUIT",4,,QUIT
	.int RZ, RSPSTORE
	.int INTERPRET
	.int BRANCH,-8
	
	
/* Word: Read next word from input */
defcode "WORD",4,,WORD
	bl _WORD
	PUSHSP r0 	/* String */
	PUSHSP r1 	/* Length */
	NEXT
	
_WORD:
	push {lr}
1:
	bl _KEY
	cmp r0, $'\\'
	beq 4f	/* skip comments */

	cmp r0, $' '
	beq 1b /* skip spaces */

	cmp r0, $'\n'
	beq 1b /* skip newlines */
	
	ldr r4, =word_buffer
2:	
	strb r0, [r4] /* store character */
	add r4, #1
	bl _KEY 	/* get next */
	cmp r0, $' '
	beq 3f
	cmp r0, $'\n'
	beq 3f
	b 2b

3:	
	/* Return word */
	ldr r0, =word_buffer
	sub r1, r4, r0
	pop {pc}
	
4:
	/* skip until end of line */
	bl _KEY
	cmp r0, $'\n'
	bne 3b
	b 1b

.data
word_buffer:
	.space 32

/* NUMBER: Parse number as returned by WORD */
defcode "NUMBER",6,,NUMBER
	POPSP r1  /* Length */
	POPSP r0  /* String start */
	bl _NUMBER
	PUSHSP r0 /* Number */
	PUSHSP r1 /* Characters left or 0 */
	NEXT

_NUMBER:
	push {lr}
	mov r2, r0 /* String */
	mov r0, #0
	mov r5, #0
	mov r6, #1
	ldr r4, =var_BASE
	ldr r4, [r4]

	cmp r1, #0 /* zero-length string? */
	beq 4f

	ldrb r5, [r2]
	add r2, #1
	cmp r5, $'-'
	bne 2f

	/* Negative */
	mov r6, #-1
	mov r5, #0

1:	/* Read loop */
	mul r0, r4
	ldrb r5, [r2]
	add r2, #1

2:	 /* Convert to number */
	sub r5, $'0'
	cmp r5, $0  	/* < 0 */
	blt 4f
	cmp r5, $10 	/* <= 9 */
	ble 3f
	sub r5, $17
	cmp r5, $0      /* < A */
	ble 4f
	add r5, $10

3:	/* Decrement and loop */
	cmp r5, r4     /* >= BASE */
	bge 4f

	add r0, r5
	sub r1, #1
	cmp r1, #0
	bgt 1b

4:
	mul r0, r6 	/* Negate if necessary */
	pop {pc}


/** Dictionary words */

/* FIND: Lookup word in dictionary. Returns pointer to header or NULL. */
defcode "FIND",4,,FIND
	POPSP r1 /* Length */
	POPSP r0 /* Address */
	bl _FIND
	PUSHSP r0 /* Entry address or NULL */
	NEXT

_FIND:
	push {lr}
	
	ldr r2, =var_LATEST
	ldr r2, [r2]

1:	cmp r2, #0 /* NULL? end of list. */
	beq 4f

	/* Compare lengths */
	ldrb r3, [r2, #4]
	and r3, #(F_HIDDEN|F_LENMASK) /* Remove all flags except hidden and length so we'll skip if hidden is set */
	cmp r1, r3
	bne 3f

	/* Compare strings */
	add r6, r2, #5 /* r6 = name of entry */

	sub r3, #1
2:	ldrb r4, [r6, r3]
	ldrb r5, [r0, r3]
	cmp r4, r5
	bne 3f
	cmp r3, #0
	sub r3, #1
	beq 4f
	b 2b
	
3:	/* Length/String mismatch, move to next. */
	ldr r2, [r2]
	b 1b

4:	/* End of list or match. */
	mov r0, r2
	pop {pc}


/* >CFA: Get Code field address */
defcode ">CFA",4,,TCFA
	POPSP r0
	bl _TCFA
	PUSHSP r0
	NEXT

_TCFA:
	add r0, #4
	ldrb r1, [r0] /* Load flags+len */
	add r0, #1 /* Skip flags+len */
	and r1, #F_LENMASK /* Get just length */
	add r0, r1 /* Skip name */
	add r0, #3 /* Skip alignment */
	and r0, #~3
	mov pc, lr

/* >DFA: Get dictionary entry address */
defcode ">DFA",4,,TDFA
	.int TCFA
	.int INCR4
	.int EXIT
	
/* CREATE: Create a dictionary entry */
defcode "CREATE",6,,CREATE
	POPSP r5 /* Name length */
	POPSP r6 /* Name address */

	ldr r0, =var_HERE
	ldr r0, [r0]
	ldr r2, =var_LATEST
	ldr r2, [r2]

	mov r1, r0
	
	/* Store link */
	str r2, [r1]
	add r1, #4

	/* Store length */
	strb r5, [r1]
	add r1, #1

	mov r4, #0
1:	/* Store word */
	ldr r3, [r6, r4]
	str r3, [r1]
	add r1, #1
	add r4, #1
	cmp r4, r5
	bne 1b

	/* Align */
	add r1, #3
	and r1, #~3
	
	/* Update LATEST & HERE */
	ldr r3, =var_HERE
	str r1, [r3]
	ldr r3, =var_LATEST
	str r0, [r3]

	NEXT

/* COMMA (,): Append to HERE */
defcode ",",1,,COMMA
	POPSP r0
	bl _COMMA
	NEXT
_COMMA:
	push {r0,r1,r2}
	ldr r2, =var_HERE /* r2 = &here */
	ldr r1, [r2]      /* r1 = *here */
	str r0, [r1]      /* *here = r0 */
	add r1, #4        
	str r1, [r2]      /* here = r1 */
	pop {r0,r1,r2}
	mov pc, lr

/* [: Switch to immediate mode (STATE = 0) */
defcode "[",1,F_IMMED,LBRAC
	mov r0, #0
	ldr r1, =var_STATE
	str r0, [r1]
	NEXT

/* ]: Switch to compile mode (STATE = 1) */
defcode "]",1,,RBRAC
	mov r0, #1
	ldr r1, =var_STATE
	str r0, [r1]
	NEXT

/* HIDDEN: Toggle hide flag */
defcode "HIDDEN",6,,HIDDEN
	POPSP r0
	add r0, #4
	ldr r1, [r0]
	eor r1, #F_HIDDEN
	str r1, [r0]
	NEXT

/* HIDE: Hide a word */
defword "HIDE",4,,HIDE
	.int WORD
	.int FIND
	.int HIDDEN
	.int EXIT

/* TICK ('): Return pointer to codeword of the next word */
defcode "'",1,,TICK /* TODO: Define with word, find, >cfa */
	ldr r0, [I]
	add I, #4
	PUSHSP r0
	NEXT

/* COLON (:): Compile a new word */
defword ":",1,,COLON
	.int WORD
	.int CREATE
	.int LIT, DOCOL, COMMA     /* Set codeword to DOCOL */
	.int LATEST, FETCH, HIDDEN /* Toggle hidden */
	.int RBRAC	 	   /* Compile mode */
	.int EXIT

/* SEMICOLON (;): End compilation */
defword ";",1,F_IMMED,SEMICOLON
	.int LIT, EXIT, COMMA 	   /* Append EXIT */
	.int LATEST, FETCH, HIDDEN /* Toggle hidden */
	.int LBRAC 		   /* Immediate mode */
	.int EXIT
	
/* INTERPRET: The interpreter */
defcode "INTERPRET",9,,INTERPRET
	ldr r6, =interpret_literal
	mov r0, #0
	str r0, [r6]
	
	bl _WORD
	mov r7, r0   /* save word pointer */
	bl _FIND     /* r0 = pointer to header */	 
	cmp r0, #0
	beq 1f

	/* Load len+flags */
	ldr r2, [r0, #4] 

	/* Get codeword pointer */
	bl _TCFA 	 /* r0 = cfa */
	
	/* Immediate? */
	and r2, $F_IMMED
	cmp r2, #0
	
	bne 4f 		 /* Immediate set, jump to execute */
	b 2f

1:	/* Word not found, literal? */
	ldr r6, =interpret_literal
	mov r2, #1
	str r2, [r6]

	mov r0, r7 /* restore word pointer */
	bl _NUMBER
	cmp r1, #0 /* Parse ok? */
	bne 6f
	mov r1, r0
	ldr r0, =LIT

2:	/* Compile/Execute? */
	ldr r2, =var_STATE
	ldr r2, [r2]
	cmp r2, #0
	beq 4f

	/* Compile (Append the word) */
	bl _COMMA

	ldr r6, =interpret_literal
	ldr r6, [r6]
	cmp r6, #1 /* Literal? */
	bne 3f
	/* Append literal */
	mov r0, r1
	bl _COMMA

3:	NEXT

4:	/* Execute */
	ldr r6, =interpret_literal
	ldr r6, [r6]
	cmp r6, #0 /* Literal? */
	bne 5f

	ldr pc, [r0]

5: 	/* Literal execution */
	PUSHSP r1
	NEXT
	
6:	/* Parse error */
	/* TODO */
	bl ERROR
	
	NEXT

.data
.align 2
interpret_literal:
	.int 0

/* EXECUTE: Execute an execution token from stack */
defcode "EXECUTE",7,,EXECUTE
	POPSP r0
	ldr pc, [r0]

/* IMMEDIATE: Mark the latest word immediate */
defcode "IMMEDIATE",9,F_IMMED,IMMEDIATE
	ldr r0, =var_LATEST
	ldr r0, [r0]
	add r0, #4
	ldrb r1, [r0]
	eor r1, #F_IMMED
	strb r1, [r0]
	NEXT