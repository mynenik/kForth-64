// vm64.s
//
// The assembler portion of kForth 64-bit Virtual Machine
//
// Copyright (c) 1998--2025 Krishna Myneni,
//   <krishna.myneni@ccreweb.org>
//
// This software is provided under the terms of the GNU 
// Affero General Public License (AGPL), v3.0 or later.
//
// Usage from C++
//
//       extern "C" int vm (byte* ip);
//       ecode = vm(ip);
//
.include "vm64-common.s"

	.comm GlobalTp, WSIZE,WSIZE
	.comm GlobalRtp, WSIZE,WSIZE
	.comm BottomOfTypeStack, WSIZE,WSIZE
	.comm BottomOfReturnTypeStack, WSIZE,WSIZE

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro SWAP
        mov  %rbx, %rdx
	INC_DSP
	movq (%rbx), %rax
	INC_DSP
	movq (%rbx), %rcx
	movq %rax, (%rbx)
	movq %rcx, -WSIZE(%rbx)
# begin ts
	movq GlobalTp(%rip), %rbx
	inc  %rbx
	movb (%rbx), %al
	inc  %rbx
	movb (%rbx), %cl
	movb %al, (%rbx)
	movb %cl, -1(%rbx)
# end ts
        mov  %rdx, %rbx
	xor  %rax, %rax
.endm

// Regs: rax, rbx, rcx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro OVER
	movq 2*WSIZE(%rbx), %rax
	movq %rax, (%rbx)
	DEC_DSP
# begin ts
	movq GlobalTp(%rip), %rcx
	movb 2(%rcx), %al
	movb %al, (%rcx)
	decq GlobalTp(%rip)
# end ts
	xor %rax, %rax
.endm

// Regs: rax, rbx, rcx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro TWO_DUP
        OVER
        OVER
.endm

// Regs: rbx
// In: rbx = DSP
// Out: rbx = DSP	
.macro TWO_DROP
        INC2_DSP
	INC2_DTSP
.endm

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro TWO_SWAP
	movq $WSIZE, %rcx
	add  %rcx, %rbx
	movq (%rbx), %rdx
	add  %rcx, %rbx
	movq (%rbx), %rax
	add  %rcx, %rbx
	xchgq %rdx, (%rbx)
	add  %rcx, %rbx
	xchgq %rax, (%rbx)
	sub  %rcx, %rbx
	sub  %rcx, %rbx
	movq %rax, (%rbx)
	sub  %rcx, %rbx
	movq %rdx, (%rbx)
        sub  %rcx, %rbx
        mov  %rbx, %rcx  # store DSP
# begin ts
	movq GlobalTp(%rip), %rbx
	inc  %rbx
	movw (%rbx), %ax
	addq $2, %rbx
	xchgw %ax, (%rbx)
	subq $2, %rbx
	movw %ax, (%rbx)
# end ts
        mov %rcx, %rbx     # restore DSP
	xor %rax, %rax
.endm

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: eax = 0, rbx = DSP
.macro TWO_OVER
	mov  %rbx, %rcx
	addq $3*WSIZE, %rbx
	movq (%rbx), %rdx
	INC_DSP
	movq (%rbx), %rax
	mov  %rcx, %rbx
	movq %rax, (%rbx)
	DEC_DSP
	movq %rdx, (%rbx)
	DEC_DSP
	mov  %rbx, %rcx    # save DSP
# begin ts
	movq GlobalTp(%rip), %rbx
	mov  %rbx, %rdx
	addq $3, %rbx
	movw (%rbx), %ax
	mov  %rdx, %rbx
	dec  %rbx
	movw %ax, (%rbx)
	dec  %rbx
	movq %rbx, GlobalTp(%rip)
# end ts
        mov  %rcx, %rbx   # restore DSP
	xor  %rax, %rax	
.endm

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro PUSH_R
	movq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rcx
	movq GlobalRp(%rip), %rdx
	movq %rcx, (%rdx)
	sub  %rax, %rdx
	movq %rdx, GlobalRp(%rip)
        mov  %rbx, %rcx     # save DSP
# begin ts
	movq GlobalTp(%rip), %rbx
	inc  %rbx
	movq %rbx, GlobalTp(%rip)
	movb (%rbx), %al
	movq GlobalRtp(%rip), %rbx
	movb %al, (%rbx)
	dec  %rbx
	movq %rbx, GlobalRtp(%rip)
# end ts
        mov  %rcx, %rbx     # restore DSP
	xor  %rax, %rax
.endm

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro POP_R
	movq $WSIZE, %rax
	movq GlobalRp(%rip), %rdx
	add  %rax, %rdx
	movq %rdx, GlobalRp(%rip)
	movq (%rdx), %rcx
	movq %rcx, (%rbx)
	sub  %rax, %rbx
	mov  %rbx, %rcx      # save DSP
# begin ts
	movq GlobalRtp(%rip), %rbx
	inc  %rbx
	movq %rbx, GlobalRtp(%rip)
	movb (%rbx), %al
	movq GlobalTp(%rip), %rbx
	movb %al, (%rbx)
	dec  %rbx
	movq %rbx, GlobalTp(%rip)
# end ts
        mov  %rcx, %rbx    # restore DSP
	xor  %rax, %rax
.endm

// Regs: rax, rbx, rcx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro FETCH op
# begin ts
	movq GlobalTp(%rip), %rcx
	inc  %rcx
	movb (%rcx), %al
	cmpb $OP_ADDR, %al
	jnz E_not_addr
	movb \op, (%rcx)
# end ts
	movq WSIZE(%rbx), %rax
	movq (%rax), %rax
	movq %rax, WSIZE(%rbx)
	xor  %rax, %rax
.endm


// Dyadic Logic operators 
// Regs: rax, rbx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro LOGIC_DYADIC op
	movq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rax
	\op %rax, WSIZE(%rbx)
# begin ts
	movq GlobalTp(%rip), %rax
	inc  %rax
	movq %rax, GlobalTp(%rip)
	movb $OP_IVAL, 1(%rax)
# end ts	
	xor  %rax, %rax 
.endm
	
.macro _AND
	LOGIC_DYADIC and
.endm
	
.macro _OR
	LOGIC_DYADIC or
.endm
	
.macro _XOR
	LOGIC_DYADIC xor
.endm
	
// Dyadic relational operators (single length numbers) 
// Regs: rax, rbx, rcx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro REL_DYADIC setx
	movq $WSIZE, %rcx
	add  %rcx, %rbx
	movq (%rbx), %rax
        add  %rcx, %rbx
	cmpq %rax, (%rbx)
	movq $0, %rax
	\setx %al
	neg  %rax
	movq %rax, (%rbx)
        sub  %rcx, %rbx
# begin ts
	movq GlobalTp(%rip), %rax
	inc  %rax
	movq %rax, GlobalTp(%rip)
	movb $OP_IVAL, 1(%rax)
# end ts
	xor %rax, %rax
.endm

// Relational operators for zero (single length numbers)
// Regs: rax, rbx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP	
.macro REL_ZERO setx
	INC_DSP
	movq (%rbx), %rax
	cmpq $0, %rax
	movq $0, %rax
	\setx %al
	neg  %rax
	movq %rax, (%rbx)
        DEC_DSP
# begin ts
	movq GlobalTp(%rip), %rax
	movb $OP_IVAL, 1(%rax)
# end ts
	xor %rax, %rax
.endm

// Regs: rax, rbx, rcx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro FREL_DYADIC logic arg set
        mov  %rbx, %rcx  # save DSP
	LDFSP
	add %rax, %rbx
	fldl (%rbx)
	add %rax, %rbx
	STFSP
	fcompl (%rbx)
	fnstsw %ax
	andb $65, %ah
	\logic \arg, %ah
	movq $0, %rax
	\set %al
	negq %rax
        mov  %rcx, %rbx   # restore DSP
	movq %rax, (%rbx)
	DEC_DSP
# begin ts
	STD_IVAL
# end ts
	xor  %rax, %rax
.endm
				
# b = (d1.hi < d2.hi) OR ((d1.hi = d2.hi) AND (d1.lo u< d2.lo))
// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro DLT
	movq $WSIZE, %rcx
	xor  %rdx, %rdx
	add  %rcx, %rbx
	movq (%rbx), %rax
	cmpq %rax, 2*WSIZE(%rbx)
	sete %dl
	setl %dh
	add  %rcx, %rbx
	movq (%rbx), %rax
	add  %rcx, %rbx
	add  %rcx, %rbx
	cmpq %rax, (%rbx)
	setb %al
	andb %al, %dl
	orb  %dh, %dl
	xor  %rax, %rax
	movb %dl, %al
	neg  %rax
	movq %rax, (%rbx)
        sub  %rcx, %rbx
# begin ts
	movq GlobalTp(%rip), %rax
	addq $4, %rax
	movb $OP_IVAL, (%rax)
	dec  %rax
	movq %rax, GlobalTp(%rip)
# end ts
	xor  %rax, %rax
.endm

# b = (d1.hi > d2.hi) OR ((d1.hi = d2.hi) AND (d1.lo u> d2.lo))
// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro DGT
	movq $WSIZE, %rcx
	xor  %rdx, %rdx
	add  %rcx, %rbx
	movq (%rbx), %rax
	cmpq %rax, 2*WSIZE(%rbx)
	sete %dl
	setl %dh
	add  %rcx, %rbx
	movq (%rbx), %rax
	add  %rcx, %rbx
	add  %rcx, %rbx
	cmpq %rax, (%rbx)
	setb %al
	andb %al, %dl
	orb  %dh, %dl
	xor  %rax, %rax
	movb %dl, %al
	neg  %rax
	movq %rax, (%rbx)
        sub  %rcx, %rbx
# begin ts
	movq GlobalTp(%rip), %rax
	addq $4, %rax
	movb $OP_IVAL, (%rax)
	dec  %rax
	movq %rax, GlobalTp(%rip)
# end ts
	xor  %rax, %rax
.endm

// Regs: rax, rbx, rcx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro BOOLEAN_QUERY
        DUP
        REL_ZERO setz
        SWAP
        movq $TRUE, (%rbx)
        DEC_DSP
        DEC_DTSP
        REL_DYADIC sete
        _OR
.endm

// Regs: rax, rbx, rcx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro TWO_BOOLEANS
        TWO_DUP
        BOOLEAN_QUERY
        SWAP
        BOOLEAN_QUERY
        _AND
.endm

// Regs: rbx
// In: rbx = DSP
// Out: rbx = DSP
.macro  CHECK_BOOLEAN
        DROP
        cmpq $TRUE, (%rbx)
        jnz E_arg_type_mismatch
.endm


// VIRTUAL MACHINE 
						
.global vm
	.type	vm,@function
vm:
	push %rbp
	push %rbx
	push %r12
	pushq GlobalIp(%rip)
	pushq vmEntryRp(%rip)
	movq %rdi, %rbp         # load the Forth instruction pointer
	movq %rbp, GlobalIp(%rip)
	movq GlobalRp(%rip), %rax
	movq %rax, vmEntryRp(%rip)
	xor %rax, %rax
next:
	movb (%rbp), %al         # get the opcode
	leaq JumpTable(%rip), %rcx
	movq (%rcx,%rax,WSIZE), %rbx	# machine code address of word
	xor %rax, %rax           # clear error code
	mov %rsp, %r12   # save rsp in r12, which is callee-saved
	and $-16, %rsp   # align rsp to 16-byte boundary
	call *%rbx		 # call the word
	mov %r12, %rsp   # restore rsp for the next pops and ret to work
	movq GlobalIp(%rip), %rbp      # resync ip (possibly changed in call)
	inc %rbp		 # increment the Forth instruction ptr
	movq %rbp, GlobalIp(%rip)
	cmpq $0, %rax		 # check for error
	jz next        
exitloop:
	cmpq $OP_RET, %rax       # return from vm?
	jnz vmexit
	xor %rax, %rax           # clear the error
vmexit:
	popq vmEntryRp(%rip)
	popq GlobalIp(%rip)
	pop %r12
	pop %rbx
	pop %rbp
	ret

L_ret:
	movq vmEntryRp(%rip), %rax		# Return Stack Ptr on entry to VM
	movq GlobalRp(%rip), %rcx
	cmp %rax, %rcx
	jl ret1
	movq $OP_RET, %rax             # exhausted the return stack so exit vm
	ret
ret1:
	addq $WSIZE, %rcx
	movq %rcx, GlobalRp(%rip)
	incq GlobalRtp(%rip)
	movq GlobalRtp(%rip), %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jnz  E_ret_stk_corrupt
	mov (%rcx), %rax
	movq %rax, GlobalIp(%rip)		# reset the instruction ptr
	xor %rax, %rax
retexit:
	ret

L_jz:
        LDSP
        DROP
        STSP
        mov (%rbx), %rax
        cmpq $0, %rax
        jz jz1
        movq $WSIZE, %rax
        add %rax, %rbp       # do not jump
        xor %rax, %rax
        NEXT
jz1:    mov %rbp, %rcx
        inc %rcx
        mov (%rcx), %rax       # get the relative jump count
        dec %rax
        add %rax, %rbp
        xor %rax, %rax
        NEXT

L_vmthrow:      # throw VM error (used as default exception handler)
        LDSP
        DROP
        movq (%rbx), %rax
        STSP
        ret

L_base:
        LDSP
        lea Base(%rip), %rcx
        movq %rcx, (%rbx)
        DEC_DSP
        STSP
        STD_ADDR
        NEXT

L_precision:
        LDSP
        movq Precision(%rip), %rcx
        movq %rcx, (%rbx)
        DEC_DSP
        STSP
        STD_IVAL
        NEXT

L_setprecision:
        LDSP
        DROP
        STSP
        mov (%rbx), %rcx
        mov %rcx, Precision(%rip)
        NEXT

L_false:
        LDSP
        movq $FALSE, (%rbx)
        DEC_DSP
        STSP
        STD_IVAL
        NEXT

L_true:
        LDSP
        movq $TRUE, (%rbx)
        DEC_DSP
        STSP
        STD_IVAL
        NEXT

L_bl:
        LDSP
        movq $32, (%rbx)
        DEC_DSP
        STSP
        STD_IVAL
        NEXT

L_lshift:
        LDSP
        DROP
        STSP
        mov (%rbx), %rcx
        cmp $MAX_SHIFT_COUNT, %rcx
        jbe lshift1
        movq $0, WSIZE(%rbx)
        NEXT
lshift1:
        shlq %cl, WSIZE(%rbx)
        NEXT

L_rshift:
        LDSP
        DROP
        STSP
        mov (%rbx), %rcx
        cmp $MAX_SHIFT_COUNT, %rcx
        jbe rshift1
        movq $0, WSIZE(%rbx)
        NEXT
rshift1:
        shrq %cl, WSIZE(%rbx)
        NEXT

# For precision delays, use US or MS instead of USLEEP
# Use USLEEP when task can be put to sleep and reawakened by OS
#
L_usleep:
	LDSP
	DROP
	mov (%rbx), %rdi
	call usleep@plt
	xor %rax, %rax
	ret

L_ms:
	LDSP
	movq WSIZE(%rbx), %rax
	imulq $1000, %rax
	mov %rax, WSIZE(%rbx)
	call C_usec
        INC_DSP
	NEXT

L_fill:
	LDSP
        DROP
	movq (%rbx), %rsi       # fill byte
        DROP
	movq (%rbx), %rdx       # byte count
	DROP
	movq (%rbx), %rdi       # address
	movq GlobalTp(%rip), %rax
	movb (%rax), %al
	cmpb $OP_ADDR, %al
	jnz E_not_addr
	call memset@plt
        STSP
	xor %rax, %rax	
	ret

L_erase:
	LDSP
	movq $0, (%rbx)
	DEC_DSP
	STSP
	DEC_DTSP
	call L_fill
	NEXT

L_blank:
	LDSP
	movq $32, (%rbx)
	DEC_DSP
	STSP
	DEC_DTSP
	call L_fill
	NEXT

L_move:
	LDSP
        DROP
	mov (%rbx), %rdx  # count
	DROP
	mov (%rbx), %rdi   # dest addr
	DROP
	mov (%rbx), %rsi   # source addr
        STSP
	movq GlobalTp(%rip), %rcx
	movb (%rcx), %al
	cmpb $OP_ADDR, %al # verify src is type addr
	jnz E_not_addr
	movb -1(%rcx), %al
	cmpb $OP_ADDR, %al  # verify dst is type addr
	jnz E_not_addr
	call memmove@plt
	xor %rax, %rax				
	NEXT

L_cmove:
	LDSP
	movq $WSIZE, %rax
	add %rax, %rbx
	movq (%rbx), %rcx		# nbytes in rcx
	cmpq $0, %rcx
	jnz  cmove1
	INC2_DSP
	STSP
	addq $3, GlobalTp(%rip)
	xor %rax, %rax
	NEXT		
cmove1:	INC_DTSP
	add %rax, %rbx
	mov (%rbx), %rdx		# dest addr in rdx
	add %rax, %rbx
        mov %rbx, %rdi
	INC_DTSP
	movq GlobalTp(%rip), %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jz cmove2
        mov %rdi, %rbx
        STSP
        INC_DTSP
        jmp E_not_addr
cmove2:	mov  %rdi, %rbx
	movq (%rbx), %rax		# src addr in rax
	INC_DTSP
	movq GlobalTp(%rip), %rbx
	movb (%rbx), %bl
	cmpb $OP_ADDR, %bl
	jz cmove3
        mov %rdi, %rbx
        STSP
	jmp E_not_addr
cmove3:	mov %rax, %rbx			# src addr in rbx
cmoveloop: movb (%rbx), %al
	movb %al, (%rdx)
	inc %rbx
	inc %rdx
	loop cmoveloop
        mov %rdi, %rbx
        STSP
	xor %rax, %rax				
	NEXT
				
L_cmovefrom:
	movq $WSIZE, %rax
	addq %rax, GlobalSp(%rip)
	INC_DTSP
	LDSP
	mov (%rbx), %rcx	# load count register
	addq %rax, GlobalSp(%rip)
	INC_DTSP
	movq GlobalTp(%rip), %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jz cmovefrom2
	jmp E_not_addr						
cmovefrom2:
	LDSP
	mov (%rbx), %rbx
	mov %rcx, %rax
	dec %rax
	add %rax, %rbx
	mov %rbx, %rdx		# dest addr in %rdx
	movq $WSIZE, %rax
	addq %rax, GlobalSp(%rip)
	INC_DTSP
	movq GlobalTp(%rip), %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jz cmovefrom3
	movq $E_NOT_ADDR, %rax
	ret
cmovefrom3:
	LDSP
	mov (%rbx), %rbx
	mov %rcx, %rax
	cmpq $0, %rax
	jnz cmovefrom4
	ret
cmovefrom4:	
	dec %rax
	add %rax, %rbx		# src addr in %rbx
cmovefromloop:	
	movb (%rbx), %al
	dec %rbx
	xchg %rbx, %rdx
	movb %al, (%rbx)
	dec %rbx
	xchg %rbx, %rdx
	loop cmovefromloop	
	xor %rax, %rax
	ret

L_slashstring:
	LDSP
	DROP
        STSP
	movq (%rbx), %rcx
	INC_DSP
	subq %rcx, (%rbx)
	INC_DSP
	addq %rcx, (%rbx)
	NEXT

L_call:
	LDFSP
	add %rax, %rbx
	mov %rbx, %rcx  # rcx = top of fp stack
	LDSP
	DROP
        STSP
	jmpq *(%rbx)

L_push_r:
        LDSP
	PUSH_R
        STSP
	NEXT

L_pop_r:
        LDSP
	POP_R
        STSP
	NEXT

L_twopush_r:
	LDSP
	INC_DSP
	movq (%rbx), %rdx
	INC_DSP
	movq (%rbx), %rax
	STSP
	movq GlobalRp(%rip), %rbx
	movq %rax, (%rbx)
	subq $WSIZE, %rbx
	movq %rdx, (%rbx)
	subq $WSIZE, %rbx
	movq %rbx, GlobalRp(%rip)
	movq GlobalTp(%rip), %rbx
	inc %rbx
	movw (%rbx), %ax
	inc %rbx
	movq %rbx, GlobalTp(%rip)
	movq GlobalRtp(%rip), %rbx
	dec %rbx
	movw %ax, (%rbx)
	dec %rbx
	movq %rbx, GlobalRtp(%rip)
	xor %rax, %rax
	NEXT

L_twopop_r:
	movq GlobalRp(%rip), %rbx
	addq $WSIZE, %rbx
	movq (%rbx), %rdx
	addq $WSIZE, %rbx
	movq (%rbx), %rax
	movq %rbx, GlobalRp(%rip)
	LDSP
	mov %rax, (%rbx)
	subq $WSIZE, %rbx
	mov %rdx, (%rbx)
	subq $WSIZE, %rbx
	STSP
	movq GlobalRtp(%rip), %rbx
	inc %rbx
	movw (%rbx), %ax
	inc %rbx
	movq %rbx, GlobalRtp(%rip)
	movq GlobalTp(%rip), %rbx
	dec %rbx
	movw %ax, (%rbx)
	dec %rbx
	movq %rbx, GlobalTp(%rip)
	xor %rax, %rax				
	NEXT

L_puship:
	mov  %rbp, %rax
	movq GlobalRp(%rip), %rbx
	movq %rax, (%rbx)
	movq $WSIZE, %rax
	subq %rax, GlobalRp(%rip)
	movq GlobalRtp(%rip), %rbx
	movb $OP_ADDR, %al
	movb %al, (%rbx)
	decq GlobalRtp(%rip)
	xor %rax, %rax
	NEXT

L_execute_bc:	
	mov  %rbp, %rcx
	movq GlobalRp(%rip), %rbx
	movq %rcx, (%rbx)
	movq $WSIZE, %rax 
	sub  %rax, %rbx
	movq %rbx, GlobalRp(%rip)
	movq GlobalRtp(%rip), %rbx
	movb $OP_ADDR, (%rbx)
	dec  %rbx
	movq %rbx, GlobalRtp(%rip)
	LDSP
	add  %rax, %rbx
	STSP
	movq (%rbx), %rax
	dec  %rax
	mov  %rax, %rbp
	INC_DTSP
	xor  %rax, %rax
	NEXT

L_execute:
        mov  %rbp, %rcx
        movq GlobalRp(%rip), %rbx
        movq %rcx, (%rbx)
        movq $WSIZE, %rax
        sub  %rax, %rbx
        movq %rbx, GlobalRp(%rip)
        movq GlobalRtp(%rip), %rbx
        movb $OP_ADDR, (%rbx)
        dec  %rbx
        movq %rbx, GlobalRtp(%rip)
        LDSP
        add  %rax, %rbx
        STSP
        movq (%rbx), %rax
	movq (%rax), %rax
        dec  %rax
        mov  %rax, %rbp
        INC_DTSP
        xor  %rax, %rax
        NEXT

L_definition:
	mov  %rbp, %rbx
	movq $WSIZE, %rax
	inc  %rbx
	movq (%rbx), %rcx # address to execute
	addq $WSIZE-1, %rbx
	mov  %rbx, %rdx
	movq GlobalRp(%rip), %rbx
	movq %rdx, (%rbx)
	sub  %rax, %rbx
	movq %rbx, GlobalRp(%rip)
	movq GlobalRtp(%rip), %rbx
	movb $OP_ADDR, (%rbx)
	dec  %rbx
	movq %rbx, GlobalRtp(%rip)
	dec  %rcx
	mov  %rcx, %rbp
	xor  %rax, %rax
	NEXT

L_rfetch:
	movq GlobalRp(%rip), %rbx
	addq $WSIZE, %rbx
	movq (%rbx), %rax
	LDSP
	movq %rax, (%rbx)
	movq $WSIZE, %rax
	subq %rax, GlobalSp(%rip)
	movq GlobalRtp(%rip), %rbx
	inc  %rbx
	movb (%rbx), %al
	movq GlobalTp(%rip), %rbx
	movb %al, (%rbx)
	DEC_DTSP
	xor  %rax, %rax
	NEXT

L_tworfetch:
	movq GlobalRp(%rip), %rbx
	addq $WSIZE, %rbx
	movq (%rbx), %rdx
	addq $WSIZE, %rbx
	movq (%rbx), %rax
	LDSP
	movq %rax, (%rbx)
	DEC_DSP
	movq %rdx, (%rbx)
	DEC_DSP
	STSP
	movq GlobalRtp(%rip), %rbx
	inc  %rbx
	movw (%rbx), %ax
	inc  %rbx
	movq GlobalTp(%rip), %rbx
	dec  %rbx
	movw %ax, (%rbx)
	dec  %rbx
	movq %rbx, GlobalTp(%rip)
	xor  %rax, %rax				
	NEXT

L_rpfetch:
	LDSP
	movq GlobalRp(%rip), %rax
	addq $WSIZE, %rax
	mov  %rax, (%rbx)
	DEC_DSP
        STD_ADDR
	STSP
	xor  %rax, %rax
	NEXT

L_spfetch:
	movq GlobalSp(%rip), %rax
	mov  %rax, %rbx
	addq $WSIZE, %rax
	movq %rax, (%rbx)
	DEC_DSP
        STD_ADDR
	STSP
	xor %rax, %rax 
	NEXT

L_fpfetch:
        LDSP
	movq GlobalFp(%rip), %rax
        addq FpSize(%rip), %rax
	movq %rax, (%rbx)
	DEC_DSP
	STD_ADDR
	STSP
	xor %rax, %rax
	NEXT

L_i:
	movq GlobalRtp(%rip), %rbx
	movb 3(%rbx), %al
	movq GlobalTp(%rip), %rbx
	movb %al, (%rbx)
	dec  %rbx
	movq %rbx, GlobalTp(%rip)
	movq GlobalRp(%rip), %rbx
	movq 3*WSIZE(%rbx), %rax
	LDSP
	movq %rax, (%rbx)
	subq $WSIZE, %rbx
	STSP
	xor  %rax, %rax
	NEXT

L_j:
	movq GlobalRtp(%rip), %rbx
	movb 6(%rbx), %al
	movq GlobalTp(%rip), %rbx
	movb %al, (%rbx)
	dec  %rbx
	movq %rbx, GlobalTp(%rip)
	movq GlobalRp(%rip), %rbx
	movq 6*WSIZE(%rbx), %rax
	LDSP
	movq %rax, (%rbx)
	movq $WSIZE, %rax
	sub %rax, %rbx
	STSP
	xor %rax, %rax
	NEXT

L_rtloop:
	movq GlobalRtp(%rip), %rbx
	inc  %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jnz  E_ret_stk_corrupt
	movq GlobalRp(%rip), %rbx
	movq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rdx
	add  %rax, %rbx
	movq (%rbx), %rcx
	add  %rax, %rbx
	movq (%rbx), %rax
	inc  %rax
	cmp %rcx, %rax	
	jz L_rtunloop
	movq %rax, (%rbx)	# set loop counter to next value
	mov  %rdx, %rbp		# set instruction ptr to start of loop
	xor  %rax, %rax
	NEXT

L_rtunloop:
	UNLOOP
	xor %rax, %rax
	NEXT

L_rtplusloop:
	push %rbp
	movq GlobalRtp(%rip), %rbx
	inc  %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jnz  E_ret_stk_corrupt
	movq $WSIZE, %rax
	LDSP
	add  %rax, %rbx
	movq (%rbx), %rbp	# get loop increment 
	STSP
	INC_DTSP		
	movq GlobalRp(%rip), %rbx
	add  %rax, %rbx		# get ip and save in rdx
	movq (%rbx), %rdx
	add  %rax, %rbx
	movq (%rbx), %rcx	# get terminal count in rcx
	add  %rax, %rbx
	movq (%rbx), %rax	# get current loop index
	add  %rbp, %rax         # new loop index
	cmpq $0, %rbp           
	jl plusloop1            # loop inc < 0?

     # positive loop increment
	cmp %rcx, %rax
	jl plusloop2            # is new loop index < rcx?
	add %rbp, %rcx
	cmp %rcx, %rax
	jge plusloop2            # is new index >= rcx + inc?
	pop %rbp
	xor %rax, %rax
	UNLOOP
	NEXT

plusloop1:       # negative loop increment
	dec %rcx
	cmp %rcx, %rax
	jg plusloop2           # is new loop index > rcx-1?
	add %rbp, %rcx
	cmp %rcx, %rax
	jle plusloop2           # is new index <= rcx + inc - 1?
	pop %rbp
	xor %rax, %rax
	UNLOOP
	NEXT

plusloop2:
	pop %rbp
	mov %rax, (%rbx)
	mov %rdx, %rbp
	xor %rax, %rax
	NEXT

L_count:
	movq GlobalTp(%rip), %rbx
	movb 1(%rbx), %al
	cmpb $OP_ADDR, %al
	jnz  E_not_addr
	movb $OP_IVAL, (%rbx)
	DEC_DTSP
	LDSP
	movq WSIZE(%rbx), %rbx
	xor  %rax, %rax
	movb (%rbx), %al
	LDSP
	incq WSIZE(%rbx)
	movq %rax, (%rbx)
	movq $WSIZE, %rax
	subq %rax, GlobalSp(%rip)
	xor  %rax, %rax
	NEXT

L_ival:
	LDSP
        inc  %rbp
        movq (%rbp), %rcx
        addq $WSIZE-1, %rbp
	movq %rcx, (%rbx)
	DEC_DSP
	STSP
	STD_IVAL
	NEXT

L_addr:
	LDSP
        inc  %rbp
        movq (%rbp), %rcx
        addq $WSIZE-1, %rbp
	movq %rcx, (%rbx)
	DEC_DSP
	STSP
	STD_ADDR
	NEXT

L_ptr:
	LDSP
	mov  %rbp, %rcx
	inc  %rcx
	movq (%rcx), %rax
	addq $WSIZE-1, %rcx
	mov  %rcx, %rbp
	movq (%rax), %rax
	movq %rax, (%rbx)
	DEC_DSP
	STSP
	STD_ADDR
	xor %rax, %rax
	NEXT

L_2val:
	LDSP
	mov %rbp, %rcx
	inc %rcx
	mov (%rcx), %rax  # top cell
	addq $WSIZE, %rcx
	mov (%rcx), %rdx  # bottom cell
	addq $WSIZE-1, %rcx
	mov %rcx, %rbp
	mov %rdx, (%rbx)
	DEC_DSP
	mov %rax, (%rbx)
	DEC_DSP
	STSP
	STD_IVAL
	STD_IVAL
	xor %rax, %rax
	NEXT

L_fval:
        LDFSP
	movq 1(%rbp), %rcx
	movq %rcx, (%rbx)
	sub %rax, %rbx
	STFSP
	add %rax, %rbp
	xor %rax, %rax 
	NEXT

L_and:
        LDSP
	_AND
        STSP
	NEXT

L_or:
        LDSP
	_OR
        STSP
	NEXT

L_not:
	LDSP
	_NOT
	NEXT

L_xor:
        LDSP
	_XOR
        STSP
	NEXT

L_boolean_query:
        LDSP
        BOOLEAN_QUERY
        STSP
        NEXT

L_bool_not:
        LDSP
        DUP
        BOOLEAN_QUERY
        CHECK_BOOLEAN
        _NOT
        STSP
        NEXT

L_bool_and:
        LDSP
        TWO_BOOLEANS
        CHECK_BOOLEAN
        _AND
        STSP
        NEXT

L_bool_or:
        LDSP
        TWO_BOOLEANS
        CHECK_BOOLEAN
        _OR
        STSP
        NEXT

L_bool_xor:
        LDSP
        TWO_BOOLEANS
        CHECK_BOOLEAN
        _XOR
        STSP
        NEXT

L_eq:
        LDSP
	REL_DYADIC sete
        STSP
	NEXT

L_ne:
        LDSP
	REL_DYADIC setne
        STSP
	NEXT

L_ult:
        LDSP
	REL_DYADIC setb
        STSP
	NEXT

L_ugt:
        LDSP
	REL_DYADIC seta
        STSP
	NEXT

L_lt:
        LDSP
	REL_DYADIC setl
        STSP
	NEXT

L_gt:
        LDSP
	REL_DYADIC setg
        STSP
	NEXT

L_le:
        LDSP
	REL_DYADIC setle
        STSP
	NEXT

L_ge:
        LDSP
	REL_DYADIC setge
        STSP
	NEXT

L_zeroeq:
        LDSP
	REL_ZERO setz
	NEXT

L_zerone:
        LDSP
	REL_ZERO setnz
	NEXT

L_zerolt:
        LDSP
	REL_ZERO setl
	NEXT

L_zerogt:
        LDSP
	REL_ZERO setg
	NEXT

L_within:
	LDSP                       # stack: a b c
	movq 2*WSIZE(%rbx), %rcx   # rcx = b
	movq WSIZE(%rbx), %rax     # rax = c
	sub %rcx, %rax            # rax = c - b
	INC_DSP     
	INC_DSP
	movq WSIZE(%rbx), %rdx     # rdx = a
	sub %rcx, %rdx            # rdx = a - b
	cmp %rax, %rdx
	movq $0, %rax
	setb %al
	neg %rax
	movq %rax, WSIZE(%rbx)
	STSP
	movq GlobalTp(%rip), %rbx
	addq $3, %rbx
	movb $OP_IVAL, (%rbx)
	dec %rbx
	movq %rbx, GlobalTp(%rip)
	xor %rax, %rax
	NEXT

L_deq:
	movq GlobalTp(%rip), %rbx
	addq $4, %rbx
	movb $OP_IVAL, (%rbx)
	dec  %rbx
	movq %rbx, GlobalTp(%rip)
	LDSP
	INC_DSP
	movq (%rbx), %rdx
	INC_DSP
	movq (%rbx), %rcx
	INC_DSP
	STSP
	movq (%rbx), %rax
	sub  %rdx, %rax
	INC_DSP
	movq (%rbx), %rdx
	sub  %rcx, %rdx
	or   %rdx, %rax
	cmpq $0, %rax
	movq $0, %rax
	setz %al
	neg  %rax
	movq %rax, (%rbx)
	xor  %rax, %rax
	NEXT

L_dzeroeq:
	movq GlobalTp(%rip), %rbx
	addq $2, %rbx
	movb $OP_IVAL, (%rbx)
	dec  %rbx
	movq %rbx, GlobalTp(%rip)
	LDSP
	INC_DSP
	STSP
	movq (%rbx), %rax
	INC_DSP
	orq  (%rbx), %rax
	cmpq $0, %rax
	movq $0, %rax
	setz %al
	neg  %rax
	movq %rax, (%rbx)
	xor  %rax, %rax
	NEXT

L_dzerolt:
        LDSP
	REL_ZERO setl
        INC_DSP
	movq (%rbx), %rax
	movq %rax, WSIZE(%rbx)
	STSP
	INC_DTSP
	xor %rax, %rax
	NEXT	

L_dlt:
        LDSP
	DLT
        STSP
	NEXT

L_dult:	# b = (d1.hi u< d2.hi) OR ((d1.hi = d2.hi) AND (d1.lo u< d2.lo)) 
	LDSP
	movq $WSIZE, %rcx
	xor  %rdx, %rdx
	add  %rcx, %rbx
	movq (%rbx), %rax
	cmpq %rax, 2*WSIZE(%rbx)
	sete %dl
	setb %dh
	add  %rcx, %rbx
	movq (%rbx), %rax
	add  %rcx, %rbx
	STSP
	add  %rcx, %rbx
	cmpq %rax, (%rbx)
	setb %al
	andb %al, %dl
	orb  %dh, %dl
	xor  %rax, %rax
	movb %dl, %al
	neg  %rax
	movq %rax, (%rbx)
	movq GlobalTp(%rip), %rax
	addq $4, %rax
	movb $OP_IVAL, (%rax)
	dec  %rax
	movq %rax, GlobalTp(%rip)
	xor  %rax, %rax
	NEXT
	
L_querydup:
	LDSP
	movq WSIZE(%rbx), %rax
	cmpq $0, %rax
	je L_querydupexit
	movq %rax, (%rbx)
	DEC_DSP
	STSP
	movq GlobalTp(%rip), %rbx
	movb 1(%rbx), %al
	movb %al, (%rbx)
	DEC_DTSP
	xor  %rax, %rax
L_querydupexit:
	NEXT

L_dup:
        LDSP
        DUP
        STSP
        NEXT

L_drop:
        LDSP
        DROP
        STSP 
        NEXT

L_swap:
        LDSP
	SWAP
	NEXT

L_over:
        LDSP
	OVER
        STSP
	NEXT

L_rot:
#	pushl %rbp
	LDSP
	movq $WSIZE, %rax
	add %rax, %rbx
	mov %rbx, %rdi
	add %rax, %rbx
	add %rax, %rbx
	mov (%rbx), %rcx
	mov (%rdi), %rdx
	mov %rcx, (%rdi)
	add %rax, %rdi
	mov (%rdi), %rcx
	mov %rdx, (%rdi)
	mov %rcx, (%rbx)
	movq GlobalTp(%rip), %rbx
	inc %rbx
	mov %rbx, %rdi
	movw (%rbx), %cx
	addq $2, %rbx
	movb (%rbx), %al
	movb %al, (%rdi)
	inc %rdi
	movw %cx, (%rdi)
	xor %rax, %rax
#	pop %rbp
	NEXT

L_minusrot:
	LDSP
	movq WSIZE(%rbx), %rax
	movq %rax, (%rbx)
	INC_DSP
	movq WSIZE(%rbx), %rax
	movq %rax, (%rbx)
	INC_DSP
	movq WSIZE(%rbx), %rax
	movq %rax, (%rbx)
	movq -2*WSIZE(%rbx), %rax
	movq %rax, WSIZE(%rbx)
	movq GlobalTp(%rip), %rbx
	movb 1(%rbx), %al
	movb %al, (%rbx)
	inc  %rbx
	movw 1(%rbx), %ax
	movw %ax, (%rbx)
	movb -1(%rbx), %al
	movb %al, 2(%rbx)
	xor  %rax, %rax
	NEXT

L_nip:
        LDSP
        INC_DSP
        movq (%rbx), %rax
        movq %rax, WSIZE(%rbx)
        STSP
        movq GlobalTp(%rip), %rbx
        inc %rbx
        movb (%rbx), %al
        movb %al, 1(%rbx)
        movq %rbx, GlobalTp(%rip)
        xor  %rax, %rax
	NEXT

L_tuck:
        LDSP
	SWAP
	OVER
        STSP
	NEXT

L_pick:
	LDSP
	addq $WSIZE, %rbx
	mov  %rbx, %rdx
	movq (%rbx), %rax
	inc  %rax
	mov  %rax, %rcx
	imulq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rax
	mov  %rdx, %rbx
	movq %rax, (%rbx)
	movq GlobalTp(%rip), %rbx
	inc  %rbx
	mov  %rbx, %rdx
	add  %rcx, %rbx
	movb (%rbx), %al
	mov  %rdx, %rbx
	movb %al, (%rbx)
	xor  %rax, %rax
	NEXT

L_roll:
	movq $WSIZE, %rax
	addq %rax, GlobalSp(%rip)
	INC_DTSP
	LDSP 
	movq (%rbx), %rax
	inc  %rax
	push %rax
	push %rax
	push %rax
	push %rbx
	imulq $WSIZE, %rax
	add  %rax, %rbx		# addr of item to roll
	movq (%rbx), %rax
	pop  %rbx
	movq %rax, (%rbx)
	pop  %rax		# number of cells to copy
	mov  %rax, %rcx
	imulq $WSIZE, %rax
	add  %rax, %rbx
	mov  %rbx, %rdx		# dest addr
	subq $WSIZE, %rbx	# src addr
rollloop:
	mov (%rbx), %rax
	subq $WSIZE, %rbx
	xchg %rbx, %rdx
	mov %rax, (%rbx)
	subq $WSIZE, %rbx
	xchg %rbx, %rdx
	loop rollloop

	pop %rax		# now we have to roll the typestack
	movq GlobalTp(%rip), %rbx
	add %rax, %rbx
	movb (%rbx), %al
	movq GlobalTp(%rip), %rbx
	movb %al, (%rbx)
	pop %rax
	mov %rax, %rcx
	add %rax, %rbx
	mov %rbx, %rdx
	dec %rbx
rolltloop:
	movb (%rbx), %al
	dec %rbx
	xchg %rbx, %rdx
	movb %al, (%rbx)
	dec %rbx
	xchg %rbx, %rdx
	loop rolltloop
	xor %rax, %rax
	ret

L_depth:
	LDSP
	movq BottomOfStack(%rip), %rax
	sub  %rbx, %rax
	movq $WSIZE, (%rbx)
	movq $0, %rdx
	idivq (%rbx)
	movq %rax, (%rbx)
	subq $WSIZE, %rbx
	STSP
	STD_IVAL
	xor  %rax, %rax
	ret

L_fdepth:
	movq GlobalFp(%rip), %rbx
	movq BottomOfFpStack(%rip), %rax
        sub  %rbx, %rax
        LDSP
        movq FpSize(%rip), %rcx
	movq $0, %rdx
	idivq %rcx
	movq %rax, (%rbx)
	subq $WSIZE, %rbx
	STSP
	STD_IVAL
        xor %rax, %rax
	ret
 
L_2drop:
        LDSP
	TWO_DROP
        STSP
	NEXT

L_fdrop:
	LDFSP
	add %rax, %rbx
	STFSP
        xor %rax, %rax
	NEXT

L_fdup:
        LDFSP
        mov %rbx, %rcx
        add %rax, %rcx
        movq (%rcx), %rcx
        movq %rcx, (%rbx)
        sub %rax, %rbx
        STFSP
        xor %rax, %rax
        NEXT

L_fswap:
        LDFSP
        addq %rax, %rbx
        movq (%rbx), %rcx
        add %rax, %rbx
        movq (%rbx), %rdx
        movq %rcx, (%rbx)
        sub %rax, %rbx
        movq %rdx, (%rbx)
#        sub %rax, %rbx
        xor %rax, %rax
	NEXT

L_fover:
	LDFSP
	mov %rbx, %rcx
        add %rax, %rcx
	add %rax, %rcx
	movq (%rcx), %rcx
	movq %rcx, (%rbx)
	sub %rax, %rbx
	STFSP
	xor %rax, %rax
	NEXT

L_frot:
        LDFSP
        add %rax, %rbx
        movq (%rbx), %rcx
        add %rax, %rbx
        movq (%rbx), %rdx
        movq %rcx, (%rbx)
        add %rax, %rbx
        movq (%rbx), %rcx
        movq %rdx, (%rbx)
        sub %rax, %rbx
        sub %rax, %rbx
        movq %rcx, (%rbx)
#        sub %rax, %rbx
        xor %rax, %rax 
	NEXT

L_fpick:
        LDSP
        DROP
        STSP
        movq (%rbx), %rcx  # pick offset
        LDFSP
        movq %rbx, %rdx  # rdx = dest addr
        addq %rax, %rbx
        imulq %rcx, %rax
        addq %rax, %rbx  # rbx = src addr
        movq (%rbx), %rcx
        movq %rdx, %rbx
        movq %rcx, (%rbx)
        DEC_FSP
        STFSP
        xor %rax, %rax
        NEXT
        
L_f2drop:
	LDFSP
	add %rax, %rbx
	add %rax, %rbx
	STFSP
        xor %rax, %rax
	NEXT

L_f2dup:
	LDFSP
        push %rbx
        add %rax, %rbx
        movq (%rbx), %rcx
        add %rax, %rbx
        movq (%rbx), %rdx
        pop %rbx
        movq %rdx, (%rbx)
        sub %rax, %rbx
        movq %rcx, (%rbx)
        sub %rax, %rbx
 	STFSP
        xor %rax, %rax
	NEXT

L_2dup:
        LDSP
	TWO_DUP
        STSP
	NEXT

L_2swap:
        LDSP
	TWO_SWAP
        STSP	
	NEXT

L_2over:
        LDSP
	TWO_OVER
        STSP
	NEXT

L_2rot:
	LDSP
	INC_DSP
	mov  %rbx, %rcx
	movq (%rbx), %rdx
	INC_DSP
	movq (%rbx), %rax
	INC_DSP
	xchgq %rdx, (%rbx)
	INC_DSP
	xchgq %rax, (%rbx)
	INC_DSP
	xchgq %rdx, (%rbx)
	INC_DSP
	xchgq %rax, (%rbx)
	mov  %rcx, %rbx
	movq %rdx, (%rbx)
	addq $WSIZE, %rbx
	movq %rax, (%rbx)
	movq GlobalTp(%rip), %rbx
	inc  %rbx
	mov  %rbx, %rcx
	movw (%rbx), %ax
	addq $2, %rbx
	xchgw %ax, (%rbx)
	addq $2, %rbx
	xchgw %ax, (%rbx)
	mov  %rcx, %rbx
	movw %ax, (%rbx)
	xor  %rax, %rax
	NEXT

L_question:
        LDSP
	FETCH $OP_IVAL
	call CPP_dot	
	ret	

L_fetch:
        LDSP
	FETCH $OP_IVAL
	NEXT

L_2fetch:
	LDSP
	movq WSIZE(%rbx), %rcx
        push %rcx
	addq $WSIZE, %rcx
        mov %rcx, WSIZE(%rbx)
	FETCH $OP_IVAL
        pop %rcx
	mov %rcx, (%rbx)
	DEC_DSP
	STD_ADDR
	FETCH $OP_IVAL
        STSP
	NEXT

L_store:
	movq GlobalTp(%rip), %rbx
	inc  %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jnz E_not_addr
	INC2_DTSP
	LDSP
	movq $WSIZE, %rax
	add %rax, %rbx
	mov (%rbx), %rcx	# address to store to in rcx
	add %rax, %rbx
	mov (%rbx), %rax	# value to store in rax
	mov %rax, (%rcx)
	STSP
	xor %rax, %rax
	NEXT

L_2store:
	movq GlobalTp(%rip), %rbx
	inc %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jnz E_not_addr
	movq $WSIZE, %rax
	LDSP
	add  %rax, %rbx
	movq (%rbx), %rcx	# target address in rcx
	add  %rax, %rbx
	movq (%rbx), %rdx	# upper 64-bits to store in rdx
	add  %rax, %rbx
	movq (%rbx), %rax  # lower 64-bit to store in rax
	STSP
	movq %rdx, (%rcx)
	addq $WSIZE, %rcx
	movq %rax, (%rcx)
	INC2_DTSP
	INC_DTSP
	xor  %rax, %rax
	NEXT

L_afetch:
        LDSP
	FETCH $OP_ADDR
	NEXT

L_cfetch:
	movq GlobalTp(%rip), %rbx
	inc  %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jnz E_not_addr
	movb $OP_IVAL, (%rbx)
	xor  %rax, %rax
	LDSP
	INC_DSP
	movq (%rbx), %rcx
	movb (%rcx), %al
	movq %rax, (%rbx)
	xor  %rax, %rax
	NEXT

L_cstore:
	movq GlobalTp(%rip), %rdx
	inc  %rdx
	movb (%rdx), %al
	cmpb $OP_ADDR, %al
	jnz E_not_addr
	LDSP
	INC_DSP
	movq (%rbx), %rcx	# address to store
	INC_DSP
	movq (%rbx), %rax	# value to store
	movb %al, (%rcx)
	STSP
	inc  %rdx
	movq %rdx, GlobalTp(%rip)
	xor  %rax, %rax
	NEXT	

L_swfetch:
	movq GlobalTp(%rip), %rcx
	movb 1(%rcx), %al
	cmpb $OP_ADDR, %al
	jnz E_not_addr
	movb $OP_IVAL, 1(%rcx)
	LDSP
	movq WSIZE(%rbx), %rcx
	movw (%rcx), %ax
	cwde
	cdqe
	movq %rax, WSIZE(%rbx)
	xor  %rax, %rax
	NEXT

L_uwfetch:
        movq GlobalTp(%rip), %rcx
        movb 1(%rcx), %al
        cmpb $OP_ADDR, %al
        jnz E_not_addr
        movb $OP_IVAL, 1(%rcx)
        LDSP
        movq WSIZE(%rbx), %rcx
        movw (%rcx), %ax
        movq %rax, WSIZE(%rbx)
        xor  %rax, %rax
        NEXT

L_wstore:
	movq GlobalTp(%rip), %rcx
	movb 1(%rcx), %al
	cmpb $OP_ADDR, %al
	jnz E_not_addr
	LDSP
        INC_DSP
	movq (%rbx), %rcx
	INC_DSP
	movq (%rbx), %rax
	movw %ax, (%rcx)
	STSP
	INC2_DTSP
	xor  %rax, %rax
	NEXT

L_slfetch:
        movq GlobalTp(%rip), %rcx
        movb 1(%rcx), %al
        cmpb $OP_ADDR, %al
        jnz E_not_addr
        movb $OP_IVAL, 1(%rcx)
        LDSP
        movq WSIZE(%rbx), %rcx
        movl (%rcx), %eax
        cdqe
        movq %rax, WSIZE(%rbx)
        xor  %rax, %rax
        NEXT

L_ulfetch:
        movq GlobalTp(%rip), %rcx
        movb 1(%rcx), %al
        cmpb $OP_ADDR, %al
        jnz E_not_addr
        movb $OP_IVAL, 1(%rcx)
        LDSP
        movq WSIZE(%rbx), %rcx
        movl (%rcx), %eax
        movq %rax, WSIZE(%rbx)
        xor %rax, %rax
        NEXT

L_lstore:
        movq GlobalTp(%rip), %rcx
	inc  %rcx
        movb (%rcx), %al
        cmpb $OP_ADDR, %al
        jnz E_not_addr
        LDSP
        movq $WSIZE, %rax
        add  %rax, %rbx
        mov  (%rbx), %rcx  # address in rcx
        add  %rax, %rbx
        mov  (%rbx), %rax  # value in rax
        movl %eax, (%rcx)
        STSP
        INC2_DTSP
        xor %rax, %rax
        NEXT

L_sffetch:
	movq GlobalTp(%rip), %rbx
	inc %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jnz E_not_addr
	movb $OP_IVAL, (%rbx)
	movq %rbx, GlobalTp(%rip)
        LDSP
        INC_DSP
        mov (%rbx), %rcx  # rcx = sfloat src addr
	STSP
	LDFSP
	flds (%rcx)
	fstpl (%rbx)
	sub %rax, %rbx
	STFSP
	xor %rax, %rax
	NEXT

L_sfstore:
	movq GlobalTp(%rip), %rbx
        inc  %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jnz  E_not_addr
        movb $OP_IVAL, (%rbx)
        movq %rbx, GlobalTp(%rip)
	LDSP
	INC_DSP
        mov  (%rbx), %rcx  # rcx = sfloat dest addr
        STSP
        LDFSP
        add  %rax, %rbx
	fldl (%rbx)        # load the double f number into NDP
	fstps (%rcx)
        STFSP
	xor  %rax, %rax
	NEXT

L_dffetch:	
	movq GlobalTp(%rip), %rbx
	inc %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jnz E_not_addr
	movb $OP_IVAL, (%rbx)
	movq %rbx, GlobalTp(%rip)
	LDSP
	INC_DSP
	mov (%rbx), %rcx  # rcx = fpaddr
	STSP
	mov (%rcx), %rcx
        LDFSP
	mov %rcx, (%rbx) 
        sub %rax, %rbx
        STFSP
	xor %rax, %rax
	NEXT

L_dfstore:
	movq GlobalTp(%rip), %rbx
	inc %rbx
	movb (%rbx), %al
	cmpb $OP_ADDR, %al
	jnz  E_not_addr
        movq %rbx, GlobalTp(%rip)
	LDSP
	INC_DSP
	mov (%rbx), %rcx  # address to store
	STSP
	LDFSP
	add %rax, %rbx
	mov (%rbx), %rax
	mov  %rax, (%rcx)
	STFSP
	xor %rax, %rax
	NEXT

L_abs:
        LDSP
	_ABS
	NEXT

L_max:
	LDSP
        DROP
        STSP 
	movq (%rbx), %rax
	movq WSIZE(%rbx), %rcx
	cmpq %rax, %rcx
	jl max1
	movq %rcx, WSIZE(%rbx)
        xor  %rax, %rax
	NEXT
max1:
	movq %rax, WSIZE(%rbx)
	xor %rax, %rax
	NEXT

L_min:
	LDSP
        DROP
        STSP
	mov  (%rbx), %rax
	mov  WSIZE(%rbx), %rcx
	cmpq %rax, %rcx
	jg min1
	mov  %rcx, WSIZE(%rbx)
	xor  %rax, %rax
        NEXT
min1:
	mov %rax, WSIZE(%rbx)
	xor %rax, %rax
	NEXT

L_stod:
        LDSP
        STOD 
        STSP
        NEXT

L_dmax:
        LDSP
	TWO_OVER
	TWO_OVER
	DLT
	DROP
	mov  (%rbx), %rax
	cmpq $0, %rax
	jne dmin1
	TWO_DROP
        STSP
	xor %rax, %rax
	NEXT

L_dmin:
        LDSP
	TWO_OVER
	TWO_OVER
	DLT
	DROP
	movq (%rbx), %rax
	cmpq $0, %rax
	je dmin1
	TWO_DROP
        STSP
	xor %rax, %rax
	NEXT
dmin1:
	TWO_SWAP
	TWO_DROP
        STSP
	xor %rax, %rax
	NEXT

#  L_dtwostar and L_dtwodiv are valid for two's-complement systems
L_dtwostar:
	LDSP
	INC_DSP
	movq WSIZE(%rbx), %rax
	mov  %rax, %rcx
	salq $1, %rax
	movq %rax, WSIZE(%rbx)
	shrq $8*WSIZE-1, %rcx
	mov  (%rbx), %rax
	salq $1, %rax
	or   %rcx, %rax
	mov  %rax, (%rbx)
	xor  %rax, %rax
	NEXT

L_dtwodiv:
	LDSP
	INC_DSP
	mov  (%rbx), %rax
	mov  %rax, %rcx
	sarq $1, %rax
	mov  %rax, (%rbx)
	shlq $8*WSIZE-1, %rcx
	movq WSIZE(%rbx), %rax
	shrq $1, %rax
	or   %rcx, %rax
	movq %rax, WSIZE(%rbx)
	xor  %rax, %rax
	NEXT

L_add:
	LDSP
	INC_DSP
	movq (%rbx), %rax
	addq %rax, WSIZE(%rbx)
	STSP
	movq GlobalTp(%rip), %rbx
	inc  %rbx
	movq %rbx, GlobalTp(%rip)
	movw (%rbx), %ax
	andb %ah, %al	# and two types to preserve addr
	inc  %rbx
	movb %al, (%rbx)
	xor  %rax, %rax
	NEXT

L_sub:
        LDSP
        DROP         # result will have type of first operand
        movq (%rbx), %rax
        subq %rax, WSIZE(%rbx)
        STSP
        xor  %rax, %rax
        NEXT

L_mul:
        LDSP
        movq $WSIZE, %rcx
        add  %rcx, %rbx
        STSP
        mov (%rbx), %rax
        add  %rcx, %rbx
        imulq (%rbx)
        mov %rax, (%rbx)
        INC_DTSP
        xor  %rax, %rax
        NEXT

L_starplus:
	LDSP
	INC_DSP
	mov (%rbx), %rcx
	INC_DSP 
	STSP
	mov (%rbx), %rax
	INC_DSP
	imulq (%rbx)
	add %rcx, %rax
	mov %rax, (%rbx)
	INC2_DTSP
	xor  %rax, %rax
	NEXT

L_fsl_mat_addr:
	LDSP
	INC_DSP
	mov (%rbx), %rcx   # rcx = j (column index)
	INC_DSP
	STSP
	mov (%rbx), %rdx   # rdx = i (row index)
	mov WSIZE(%rbx), %rax   # adress of first element
	sub $2*WSIZE, %rax # rax = a - 2 cells
	mov %rax, %rdi
	mov (%rax), %rax   # rax = ncols
	imulq %rdx         # rax = i*ncols 
        add %rax, %rcx     # rcx = i*ncols + j 
	mov %rdi, %rax
	add $WSIZE, %rax
	mov (%rax), %rax   # rax = size
	imulq %rcx         # rax = size*(i*ncols + j)
	add %rax, WSIZE(%rbx)   # TOS = a + rax
	INC2_DTSP
	xor %rax, %rax
	NEXT

L_div:
        LDSP
        INC_DSP
        DIV
	mov %rax, (%rbx)
        DEC_DSP
        STSP
        INC_DTSP
        xor %rax, %rax
	NEXT

L_mod:
        LDSP
        INC_DSP
	DIV
	mov %rdx, (%rbx)
        DEC_DSP
        STSP
        INC_DTSP
        xor %rax, %rax
	NEXT

L_slashmod:
        LDSP
        INC_DSP
        DIV
        mov %rdx, (%rbx)
        DEC_DSP
        mov %rax, (%rbx)
	DEC_DSP
	STSP
        xor %rax, %rax
	NEXT

L_udivmod:
        LDSP
        INC_DSP
        UDIV
        mov %rdx, (%rbx)
        DEC_DSP
        mov %rax, (%rbx)
        DEC_DSP
        STSP
        xor %rax, %rax
        NEXT

L_starslash:
        LDSP
	STARSLASH
        STSP
	NEXT

L_starslashmod:
        LDSP
	STARSLASH
	mov %rdx, (%rbx)
	DEC_DSP
	STSP
	DEC_DTSP
	SWAP
	ret

L_plusstore:
	movq GlobalTp(%rip), %rbx
	movb 1(%rbx), %al
	cmpb $OP_ADDR, %al
	jnz  E_not_addr
	LDSP
	INC_DSP
	mov (%rbx), %rdx   # rdx = addr
        INC_DSP
        mov (%rbx), %rax 
	add %rax, (%rdx)
	STSP
	INC2_DTSP
	xor %rax, %rax
	NEXT

L_dabs:
	LDSP
	INC_DSP
	mov (%rbx), %rcx  # high dword
	mov %rcx, %rax
	cmpq $0, %rax
	jl dabs_go
        DEC_DSP
	xor %rax, %rax
	ret
dabs_go:
	INC_DSP
	mov (%rbx), %rax  # low dword
	clc
	subq $1, %rax
	not %rax
	mov %rax, (%rbx)
	mov %rcx, %rax
	sbbq $0, %rax
	not %rax
	movq %rax, -WSIZE(%rbx)
        subq $2*WSIZE, %rbx
	xor %rax, %rax
	ret

L_dnegate:
        LDSP
	DNEGATE
	ret

L_dplus:
        LDSP
	DPLUS
        STSP
	ret

L_dminus:
        LDSP
	DMINUS
        STSP
	ret

L_umstar:
	LDSP
	movq $WSIZE, %rax
	add %rax, %rbx
	mov (%rbx), %rcx
	add %rax, %rbx
	mov %rcx, %rax
	mulq (%rbx)
	mov %rax, (%rbx)
	DEC_DSP
	mov %rdx, (%rbx)
	xor %rax, %rax				
	NEXT

L_dsstar:
	# multiply signed double and signed to give triple length product
	LDSP
	movq $WSIZE, %rcx
	add %rcx, %rbx
	mov (%rbx), %rdx
	cmpq $0, %rdx
	setl %al
	add %rcx, %rbx
	mov (%rbx), %rdx
	cmpq $0, %rdx
	setl %ah
	xorb %ah, %al      # sign of result
	andq $1, %rax
	push %rax
        LDSP
	_ABS
	INC_DSP
	STSP
	INC_DTSP
	call L_dabs
#	LDSP
	DEC_DSP
	STSP
	DEC_DTSP
	call L_udmstar
#       LDSP
	pop %rax
	cmpq $0, %rax
	jne dsstar1
	NEXT
dsstar1:
	TNEG
	NEXT

L_umslashmod:
# Divide unsigned double length by unsigned single length to
# give unsigned single quotient and remainder. A "Divide overflow"
# error results if the quotient doesn't fit into a single word.
	LDSP
	movq $WSIZE, %rax
	add %rax, %rbx
	STSP
	mov (%rbx), %rcx
	cmpq $0, %rcx
	jz   E_div_zero
	add %rax, %rbx
	movq $0, %rdx
	mov (%rbx), %rax
	divq %rcx
	cmpq $0, %rax
	jne  E_div_overflow
	mov (%rbx), %rdx
	INC_DSP
	mov (%rbx), %rax
	divq %rcx
	mov %rdx, (%rbx)
	DEC_DSP
	mov %rax, (%rbx)
	INC_DTSP
	xor %rax, %rax		
	NEXT

L_uddivmod:
# Divide unsigned double length by unsigned single length to
# give unsigned double quotient and single remainder.
        LDSP
        movq $WSIZE, %rax
        add %rax, %rbx
        mov (%rbx), %rcx
        cmpq $0, %rcx
        jz E_div_zero
        add %rax, %rbx
        movq $0, %rdx
        mov (%rbx), %rax
        divq %rcx
        mov %rax, %r8  # %r8 = hi quot
        INC_DSP
        mov (%rbx), %rax
        divq %rcx
        mov %rdx, (%rbx)
        DEC_DSP
        mov %rax, (%rbx)
        DEC_DSP
        mov %r8, (%rbx)
        DEC_DSP
        xor %rax, %rax
        ret

L_mstar:
	LDSP
	movq $WSIZE, %rax
	add %rax, %rbx
	mov (%rbx), %rcx
	add %rax, %rbx
	mov %rcx, %rax
	imulq (%rbx)
	mov %rax, (%rbx)
	DEC_DSP
	mov %rdx, (%rbx)
	xor %rax, %rax		
	NEXT

L_mplus:
        LDSP
	STOD
	DPLUS
        STSP
	NEXT

L_mslash:
	LDSP
	movq $WSIZE, %rax
	INC_DTSP
	add %rax, %rbx
	mov (%rbx), %rcx
	INC_DTSP
	add %rax, %rbx
	STSP
	cmpq $0, %rcx
	je  E_div_zero
	mov (%rbx), %rdx
	add %rax, %rbx
	mov (%rbx), %rax
	idivq %rcx
	mov %rax, (%rbx)
	xor %rax, %rax		
	NEXT

L_udmstar:
# Multiply unsigned double and unsigned single to give 
# the triple length product.
	LDSP
	INC_DSP
	mov (%rbx), %rcx
	INC_DSP
	mov (%rbx), %rax
	mulq %rcx
	movq %rdx, -WSIZE(%rbx)
	mov %rax, (%rbx)
	INC_DSP
	mov %rcx, %rax
	mulq (%rbx)
	mov %rax, (%rbx)
	DEC_DSP
	mov (%rbx), %rax
	DEC_DSP
	clc
	add %rdx, %rax
	mov %rax, WSIZE(%rbx)
	mov (%rbx), %rax
	adcq $0, %rax
	mov %rax, (%rbx)
        DEC_DSP
	xor %rax, %rax 		
	ret

L_utsslashmod:
# Divide unsigned triple length by unsigned single length to
# give an unsigned triple quotient and single remainder.
	LDSP
	INC_DSP
	mov (%rbx), %rcx		# divisor in rcx
	cmpq $0, %rcx
	jz  E_div_zero
	INC_DSP
	mov (%rbx), %rax		# ut3
	movq $0, %rdx
	divq %rcx			# ut3/u
	call utmslash1
	LDSP
	movq WSIZE(%rbx), %rax
	mov %rax, (%rbx)
	INC_DSP
	movq WSIZE(%rbx), %rax
	mov %rax, (%rbx)
	INC_DSP	
	movq -17*WSIZE(%rbx), %rax       # r7
	mov %rax, (%rbx)
	subq $3*WSIZE, %rbx
	movq -5*WSIZE(%rbx), %rax        # q3
	mov %rax, (%rbx)
	DEC_DSP
	STSP
	DEC_DTSP
	DEC_DTSP
	xor %rax, %rax	
	ret

L_tabs:
# Triple length absolute value (needed by L_stsslashrem, STS/REM)
	LDSP
	INC_DSP
	mov (%rbx), %rcx
	mov %rcx, %rax
	cmpq $0, %rax
	jl tabs1
        DEC_DSP
	xor %rax, %rax
	ret
tabs1:
	INC2_DSP
	mov (%rbx), %rax
	clc
	subq $1, %rax
	not %rax
	mov %rax, (%rbx)
	DEC_DSP
	mov (%rbx), %rax
	sbbq $0, %rax
	not %rax
	mov %rax, (%rbx)
        DEC_DSP
	mov %rcx, %rax
	sbbq $0, %rax
	not %rax
	mov %rax, (%rbx)
        DEC_DSP
	xor %rax, %rax
	ret

L_stsslashrem:
# Divide signed triple length by signed single length to give a
# signed triple quotient and single remainder, according to the
# rule for symmetric division.
	LDSP
	DROP
        STSP
	mov (%rbx), %rcx		# divisor in rcx
	cmpq $0, %rcx
	jz   E_div_zero
	movq WSIZE(%rbx), %rax		# t3
	push %rax
	cmpq $0, %rax
	movq $0, %rax
	setl %al
	neg %rax
	mov %rax, %rdx
	cmpq $0, %rcx
	movq $0, %rax
	setl %al
	neg %rax
	xor %rax, %rdx			# sign of quotient
	push %rdx
	call L_tabs
#       LDSP
        DEC_DSP
        DEC_DTSP
#       STSP
	_ABS
        STSP
	call L_utsslashmod
        LDSP
	pop %rdx
	cmpq $0, %rdx
	jz stsslashrem1
	TNEG
stsslashrem1:	
	pop %rax
	cmpq $0, %rax
	jz stsslashrem2
	addq $4*WSIZE, %rbx
	negq (%rbx)	
stsslashrem2:
	xor %rax, %rax
	ret

L_utmslash:
# Divide unsigned triple length by unsigned single to give 
# unsigned double quotient. A "Divide Overflow" error results
# if the quotient doesn't fit into a double word.
	LDSP
	INC_DSP
	mov (%rbx), %rcx		# divisor in rcx
	cmpq $0, %rcx
	jz   E_div_zero	
	INC_DSP
#	mov (%rbx), %rax		# ut3
#	movq $0, %rdx
	movq (%rbx), %rdx               # ut3
	movq WSIZE(%rbx), %rax          # ut2
	divq %rcx			# ut3:ut2/u  generates INT 0 on ovflow
#	cmpq $0, %rax
#	jnz  E_div_overflow
	xor %rdx, %rdx
	movq (%rbx), %rax
	divq %rcx
	xor %rax, %rax
utmslash1:	
	push %rbx			# keep local stack ptr
	LDSP
	movq %rax, -4*WSIZE(%rbx)	# q3
	movq %rdx, -5*WSIZE(%rbx)	# r3
	pop %rbx
	INC_DSP
	mov (%rbx), %rax		# ut2
	movq $0, %rdx
	divq %rcx			# ut2/u
	push %rbx
	LDSP
	movq %rax, -2*WSIZE(%rbx)	# q2
	movq %rdx, -3*WSIZE(%rbx)	# r2
	pop %rbx
	INC_DSP
	mov (%rbx), %rax		# ut1
	movq $0, %rdx
	divq %rcx			# ut1/u
	push %rbx
	LDSP
	mov %rax, (%rbx)		# q1
	movq %rdx, -WSIZE(%rbx)		# r1
	movq -5*WSIZE(%rbx), %rdx	# r3 << 32
	movq $0, %rax
	divq %rcx			# (r3 << 32)/u
	movq %rax, -6*WSIZE(%rbx)	# q4
	movq %rdx, -7*WSIZE(%rbx)	# r4
	movq -3*WSIZE(%rbx), %rdx	# r2 << 32
	movq $0, %rax
	divq %rcx			# (r2 << 32)/u
	movq %rax, -8*WSIZE(%rbx)	# q5
	movq %rdx, -9*WSIZE(%rbx)	# r5
	movq -7*WSIZE(%rbx), %rdx	# r4 << 32
	movq $0, %rax
	divq %rcx			# (r4 << 32)/u
	movq %rax, -10*WSIZE(%rbx)	# q6
	movq %rdx, -11*WSIZE(%rbx)	# r6
	movq $0, %rdx
	movq -WSIZE(%rbx), %rax		# r1
	addq -9*WSIZE(%rbx), %rax	# r1 + r5
	jnc   utmslash2
	inc %rdx
utmslash2:			
	addq -11*WSIZE(%rbx), %rax	# r1 + r5 + r6
	jnc  utmslash3
	inc %rdx
utmslash3:
	divq %rcx
	movq %rax, -12*WSIZE(%rbx)	# q7
	movq %rdx, -13*WSIZE(%rbx)	# r7
	movq $0, %rdx
	addq -10*WSIZE(%rbx), %rax	# q7 + q6
	jnc  utmslash4
	inc %rdx
utmslash4:	
	addq -8*WSIZE(%rbx), %rax	# q7 + q6 + q5
	jnc  utmslash5
	inc %rdx
utmslash5:	
	add (%rbx), %rax		# q7 + q6 + q5 + q1
	jnc utmslash6
	inc %rdx
utmslash6:
	pop %rbx
	mov %rax, (%rbx)
	DEC_DSP
	push %rbx
	LDSP
	movq -2*WSIZE(%rbx), %rax	# q2
	addq -6*WSIZE(%rbx), %rax	# q2 + q4
	add %rdx, %rax
	pop %rbx
	mov %rax, (%rbx)
	DEC_DSP
	STSP
	INC2_DTSP
	xor %rax, %rax
	ret

L_mstarslash:
	LDSP
	INC_DSP
        movq (%rbx), %rax  # rax = +n2
        cmpq $0, %rax
        jz E_div_zero
	INC_DSP
	mov (%rbx), %rax   # rax = n1
	INC_DSP
	xor (%rbx), %rax
	shrq $8*WSIZE-1, %rax  # eax = sign(n1) xor sign(d1)
	push %rax	# keep sign of result -- negative is nonzero
        subq $2*WSIZE, %rbx
        INC_DTSP
	_ABS            # abs(n1)
	INC_DSP
	STSP
	INC_DTSP
	call L_dabs
#	LDSP
	DEC_DSP         # TOS = +n2
	STSP
	DEC_DTSP
	call L_udmstar
#	LDSP
	DEC_DSP
	STSP
	DEC_DTSP
	call L_utmslash	
	pop %rax
	cmpq $0, %rax
	jnz mstarslash_neg
	xor %rax, %rax
	ret
mstarslash_neg:
	DNEGATE
	xor %rax, %rax
	ret
		
L_fmslashmod:
	LDSP
	movq $WSIZE, %rax
	add %rax, %rbx
	STSP
	mov (%rbx), %rcx
	cmpq $0, %rcx
	jz   E_div_zero
	add %rax, %rbx
	mov (%rbx), %rdx
	add %rax, %rbx
	mov (%rbx), %rax
	idivq %rcx
	mov %rdx, (%rbx)
	DEC_DSP
	mov %rax, (%rbx)
	INC_DTSP
	cmpq $0, %rcx
	jg fmslashmod2
	cmpq $0, %rdx
	jg fmslashmod3
	xor %rax, %rax
	NEXT
fmslashmod2:		
	cmpq $0, %rdx
	jge fmslashmodexit
fmslashmod3:	
	dec %rax		# floor the result
	mov %rax, (%rbx)
	INC_DSP
	add %rcx, (%rbx)
fmslashmodexit:
	xor %rax, %rax
	NEXT

L_smslashrem:
	LDSP
	movq $WSIZE, %rax
	add %rax, %rbx
	STSP
	mov (%rbx), %rcx
	cmpq $0, %rcx
	jz   E_div_zero
	add %rax, %rbx
	mov (%rbx), %rdx
	add %rax, %rbx
	mov (%rbx), %rax
	idivq %rcx
	mov %rdx, (%rbx)
	DEC_DSP
	mov %rax, (%rbx)
	INC_DTSP
	xor %rax, %rax		
	NEXT

L_stof:
	LDSP
        INC_DSP
	fildq (%rbx)
	STSP
        INC_DTSP
	LDFSP
	fstpl (%rbx)
	DEC_FSP
	STFSP
	xor %rax, %rax
	NEXT

L_dtof:
	LDSP
	INC_DSP
	movq (%rbx), %rsi
        INC_DSP
        movq (%rbx), %rdi
        STSP
        INC2_DTSP
        call __floattidf
        LDFSP
        movq %xmm0, (%rbx)
        DEC_FSP
        STFSP
	xor %rax, %rax	
	NEXT	

L_froundtos:
	LDFSP
        add %rax, %rbx
	fldl (%rbx)
	STFSP
        LDSP
	fistpq (%rbx)
	DEC_DSP
        STSP
	STD_IVAL
	xor %rax, %rax
	NEXT

L_ftrunctos:
        LDFSP
        add %rax, %rbx
	fldl (%rbx)
        STFSP
        LDSP
	fnstcw (%rbx)
	mov (%rbx), %rcx	# save NDP control word		
	mov %rcx, %rdx	
	movb $12, %dh
	mov %rdx, (%rbx)
	fldcw (%rbx)	
	fistpq (%rbx)
	DEC_DSP
        STSP
	mov %rcx, (%rbx)
	fldcw (%rbx)		# restore NDP control word
	STD_IVAL
	xor %rax, %rax	
	NEXT
	
L_ftod:
	LDFSP
	add %rax, %rbx
        movsd (%rbx), %xmm0
        STFSP
        call __fixdfti
        LDSP
        movq %rax, (%rbx)
        DEC_DSP
        movq %rdx, (%rbx)
        DEC_DSP
        STSP
	STD_IVAL
	STD_IVAL
        xor %rax, %rax 
	NEXT

L_fne:
        LDSP
	FREL_DYADIC xorb $64 setnz
        STSP
	NEXT
L_feq:
        LDSP
	FREL_DYADIC andb $64 setnz
        STSP
	NEXT
L_flt:
        LDSP
	FREL_DYADIC andb $65 setz
        STSP
	NEXT
L_fgt:
        LDSP
	FREL_DYADIC andb $1 setnz
        STSP
	NEXT	
L_fle:
        LDSP
	FREL_DYADIC xorb $1 setnz
        STSP
	NEXT
L_fge:
        LDSP
	FREL_DYADIC andb $65 setnz
        STSP
	NEXT
L_fzeroeq:
	LDFSP
	add %rax, %rbx
        STFSP
        xor %rcx, %rcx
	movl (%rbx), %ecx
	add $4, %rbx            
	movl (%rbx), %eax
	shll $1, %eax
	or %ecx, %eax
	movq $0, %rax
	setz %al
frelzero:
	neg %rax
        LDSP
	movq %rax, (%rbx)
        DEC_DSP
        STSP
	STD_IVAL
	xor %rax, %rax
	NEXT
L_fzerolt:
	LDFSP
	add %rax, %rbx
	STFSP
	fldl (%rbx)
	fldz
	fcompp	
	fnstsw %ax
	andb $69, %ah
	movq $0, %rax
	setz %al
	jmp frelzero
L_fzerogt:
	LDFSP
	add %rax, %rbx
	STFSP
	fldz
	fldl (%rbx)
	fucompp	
	fnstsw %ax
	sahf 
	movq $0, %rax
	seta %al
	jmp frelzero

L_fsincos:
	LDFSP
	add %rax, %rbx
	fldl (%rbx)
	fsincos
	fxch
	fstpl (%rbx)
        sub %rax, %rbx
	fstpl (%rbx)
	sub %rax, %rbx
	STFSP
	NEXT

L_fplusstore:
        movq GlobalTp(%rip), %rbx
        inc %rbx
        movb (%rbx), %al
        cmpb $OP_ADDR, %al
        jnz E_not_addr
        movb $OP_IVAL, (%rbx)
        movq %rbx, GlobalTp(%rip)
        LDFSP
        add %rax, %rbx
        fldl (%rbx)
        STFSP
        LDSP
        INC_DSP
        mov (%rbx), %rcx
        fldl (%rcx)
        faddp
        fstpl (%rcx)
        STSP
        xor %rax, %rax
        NEXT

