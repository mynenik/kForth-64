// vm64-fast.s
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
.set __FAST__, -1
.include "vm64-common.s"

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro SWAP
        mov %rbx, %rdx
        INC_DSP
	movq (%rbx), %rax
	INC_DSP
	mov (%rbx), %rcx
	mov %rax, (%rbx)
        DEC_DSP
        mov %rcx, (%rbx)
	mov %rdx, %rbx
	xor %rax, %rax
.endm

// Regs: rbx, rcx
// In: rbx = DSP
// Out: rbx = DSP
.macro OVER
	movq 2*WSIZE(%rbx), %rcx
	mov %rcx, (%rbx)
	DEC_DSP
.endm

// Regs: rbx, rcx
// In: rbx = DSP
// Out: rbx = DSP
.macro TWO_DUP
        OVER
        OVER
.endm

// Regs: rbx
// In: rbx = DSP
// Out: rbx = DSP	
.macro TWO_DROP
	INC2_DSP
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
	mov  %rax, (%rbx)
	sub  %rcx, %rbx
	mov  %rdx, (%rbx)
        sub  %rcx, %rbx
	xor %rax, %rax
.endm

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: eax = 0, rbx = DSP
.macro TWO_OVER
	mov %rbx, %rcx
	addq $3*WSIZE, %rbx
	mov (%rbx), %rdx
	INC_DSP
	mov (%rbx), %rax
	mov %rcx, %rbx
	mov %rax, (%rbx)
	DEC_DSP
	mov %rdx, (%rbx)
	DEC_DSP
	xor %rax, %rax	
.endm

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro PUSH_R
	movq $WSIZE, %rax
	add %rax, %rbx	
	mov (%rbx), %rcx
	movq GlobalRp(%rip), %rdx
	mov %rcx, (%rdx)
	sub %rax, %rdx
	movq %rdx, GlobalRp(%rip)
	xor %rax, %rax
.endm

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro POP_R
	movq $WSIZE, %rax
	movq GlobalRp(%rip), %rdx
	add %rax, %rdx
	movq %rdx, GlobalRp(%rip)
	mov (%rdx), %rcx
	mov %rcx, (%rbx)
	sub %rax, %rbx
	xor %rax, %rax
.endm

// Regs: rax, rbx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro FETCH
        mov %rbx, %rdx
        add $WSIZE, %rdx
	mov (%rdx), %rax
	mov (%rax), %rax
	mov %rax, (%rdx)
	xor %rax, %rax
.endm

// Dyadic Logic operators 
// Regs: rax, rbx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro LOGIC_DYADIC op
	movq $WSIZE, %rax
	add %rax, %rbx
	mov (%rbx), %rax
	\op %rax, WSIZE(%rbx)
	xor %rax, %rax 
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
	add %rcx, %rbx
	movq (%rbx), %rax
	cmpq %rax, WSIZE(%rbx)
	movq $0, %rax
	\setx %al
	neg %rax
	mov %rax, WSIZE(%rbx)
	xor %rax, %rax
.endm

// Relational operators for zero (single length numbers)
// Regs: rax, rbx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro REL_ZERO setx
	INC_DSP
	mov (%rbx), %rax
	cmpq $0, %rax
	movq $0, %rax
	\setx %al
	neg %rax
	mov %rax, (%rbx)
        DEC_DSP
	xor %rax, %rax
.endm

// Regs: rax, rbx, rcx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro FREL_DYADIC logic arg set
        mov %rbx, %rcx  # save DSP
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
        mov %rcx, %rbx   # restore DSP
	mov %rax, (%rbx)
	DEC_DSP
	xor %rax, %rax
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
	xor  %rax, %rax
.endm

# b = (d1.hi > d2.hi) OR ((d1.hi = d2.hi) AND (d1.lo u> d2.lo))
# not completed
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
        LDSP
next:
	movb (%rbp), %al         # get the opcode
	leaq JumpTable(%rip), %rcx
	movq (%rcx,%rax,WSIZE), %rcx	# machine code address of word
	xor %rax, %rax   # clear error code
#	mov %rsp, %r12   # save rsp in r12, which is callee-saved
#	and $-16, %rsp   # align rsp to 16-byte boundary
	call *%rcx	 # call the word
#	mov %r12, %rsp   # restore rsp for the next pops and ret to work
        LDSP
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
	mov (%rcx), %rax
	movq %rax, GlobalIp(%rip)     # reset the instruction ptr
	xor %rax, %rax
retexit:
	ret

L_jz:
        DROP
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
        INC_DSP
        movq (%rbx), %rax
        STSP
        ret

L_base:
        lea Base(%rip), %rcx
        movq %rcx, (%rbx)
        DEC_DSP
        NEXT

L_precision:
        mov Precision(%rip), %rcx
        mov %rcx, (%rbx)
        DEC_DSP
        NEXT

L_setprecision:
        DROP
        mov (%rbx), %rcx
        mov %rcx, Precision(%rip)
        NEXT

L_false:
        movq $FALSE, (%rbx)
        DEC_DSP
        NEXT

L_true:
        movq $TRUE, (%rbx)
        DEC_DSP
        NEXT

L_bl:
        movq $32, (%rbx)
        DEC_DSP
        NEXT

L_lshift:
        DROP
        movq (%rbx), %rcx
        cmpq $MAX_SHIFT_COUNT, %rcx
        jbe lshift1
        movq $0, WSIZE(%rbx)
        NEXT
lshift1:
        shlq %cl, WSIZE(%rbx)
        NEXT

L_rshift:
        DROP
        movq (%rbx), %rcx
        cmpq $MAX_SHIFT_COUNT, %rcx
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
	DROP
	movq (%rbx), %rdi
	call usleep@plt
	xor %rax, %rax
	NEXT

L_ms:
	movq WSIZE(%rbx), %rax
	imulq $1000, %rax
	mov %rax, WSIZE(%rbx)
	call C_usec
        INC_DSP
	NEXT

L_fill:
        movq $WSIZE, %rax
        add  %rax, %rbx
	movq (%rbx), %rsi  # fill byte
	add  %rax, %rbx
	movq (%rbx), %rdx  # byte count
	add %rax, %rbx
	mov (%rbx), %rdi   # address
	call memset@plt
        STSP
        xor %rax, %rax
	ret

L_erase:
	movq $0, (%rbx)
	DEC_DSP
	call L_fill
	NEXT

L_blank:
	movq $32, (%rbx)
	DEC_DSP
	call L_fill
	NEXT

L_move:
	movq $WSIZE, %rax
	add %rax, %rbx
	mov (%rbx), %rdx  # count
	add %rax, %rbx
	mov (%rbx), %rdi  # dest addr
	add %rax, %rbx
	mov (%rbx), %rsi  # src addr
	call memmove@plt
	xor %rax, %rax				
	NEXT

L_cmove:
	movq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rcx	# nbytes in rcx
	cmpq $0, %rcx
	jnz  cmove1
	add  %rax, %rbx
        add  %rax, %rbx
	xor  %rax, %rax
	NEXT		
cmove1:
	add  %rax, %rbx
	movq (%rbx), %rdx	# dest addr in rdx
	add  %rax, %rbx
	movq (%rbx), %rdi	# src addr in rdi
cmoveloop: 
        movb (%rdi), %al
	movb %al, (%rdx)
	inc  %rdx
	inc  %rdi
	loop cmoveloop
	xor %rax, %rax				
	NEXT
				
L_cmovefrom:
	movq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rcx	# load count register
	add  %rax, %rbx
	movq (%rbx), %rdx
	add  %rcx, %rdx
	dec  %rdx               # dest addr in %rdx
	add  %rax, %rbx
        mov  %rcx, %rax
	cmpq $0, %rax
	jnz cmovefrom4
	NEXT
cmovefrom4:	
	movq (%rbx), %rdi
        dec  %rax
	add  %rax, %rdi		# src addr in %rdi
cmovefromloop:	
	movb (%rdi), %al
	dec  %rdi
	movb %al, (%rdx)
	dec  %rdx
	loop cmovefromloop	
	xor  %rax, %rax
	NEXT

L_slashstring:
	INC_DSP
	movq (%rbx), %rcx
	INC_DSP
	sub %rcx, (%rbx)
	INC_DSP
	add %rcx, (%rbx)
        subq $2*WSIZE, %rbx
	NEXT

L_call:
        mov %rbx, %rdi
	LDFSP  # rbx = GlobalFp, rax = FpSize
	add %rax, %rbx
	mov %rbx, %rcx  # rcx = top of fp stack
	mov %rdi, %rbx
        INC_DSP
        STSP
        push %r12
        call *(%rbx)
        pop %r12
        LDSP
        ret

L_push_r:
	PUSH_R
	NEXT

L_pop_r:
	POP_R
	NEXT

L_twopush_r:
	INC_DSP
	movq (%rbx), %rdx
	INC_DSP
	movq (%rbx), %rax
	movq GlobalRp(%rip), %rcx
	movq %rax, (%rcx)
	subq $WSIZE, %rcx
	mov %rdx, (%rcx)
	subq $WSIZE, %rcx
	movq %rcx, GlobalRp(%rip)
	xor %rax, %rax
	NEXT

L_twopop_r:
	movq GlobalRp(%rip), %rcx
	addq $WSIZE, %rcx
	movq (%rcx), %rdx
	addq $WSIZE, %rcx
	movq (%rcx), %rax
	movq %rcx, GlobalRp(%rip)
	mov  %rax, (%rbx)
	DEC_DSP
	mov  %rdx, (%rbx)
	DEC_DSP
	xor  %rax, %rax				
	NEXT

L_puship:
	mov  %rbp, %rax
	movq GlobalRp(%rip), %rcx
	mov  %rax, (%rcx)
	movq $WSIZE, %rax
	subq %rax, GlobalRp(%rip)
	xor  %rax, %rax
	NEXT

L_execute_bc:	
	mov  %rbp, %rcx
	movq GlobalRp(%rip), %rdx
	mov  %rcx, (%rdx)
	movq $WSIZE, %rax 
	sub  %rax, %rdx
	movq %rdx, GlobalRp(%rip)
	add  %rax, %rbx
	movq (%rbx), %rax
	dec  %rax
	mov  %rax, %rbp
	xor  %rax, %rax
	NEXT

L_execute:
        mov  %rbp, %rcx
        movq GlobalRp(%rip), %rdx
        mov  %rcx, (%rdx)
        movq $WSIZE, %rax
        sub  %rax, %rdx
        movq %rdx, GlobalRp(%rip)
        add  %rax, %rbx
        movq (%rbx), %rax
	movq (%rax), %rax
        dec  %rax
        mov  %rax, %rbp
        xor  %rax, %rax
        NEXT

L_definition:
	mov  %rbp, %rax
	inc  %rax
	movq (%rax), %rcx # address to execute
	addq $WSIZE-1, %rax
	mov  %rax, %rdx
	movq GlobalRp(%rip), %rax
	mov  %rdx, (%rax)
	subq $WSIZE, %rax
	movq %rax, GlobalRp(%rip)
	dec  %rcx
	mov  %rcx, %rbp
	xor  %rax, %rax
	NEXT

L_rfetch:
	movq GlobalRp(%rip), %rcx
        movq $WSIZE, %rax
	add  %rax, %rcx
	movq (%rcx), %rcx
	mov  %rcx, (%rbx)
	sub  %rax, %rbx
	xor  %rax, %rax
	NEXT

L_tworfetch:
	movq GlobalRp(%rip), %rcx
	movq $WSIZE, %rax
        add  %rax, %rcx
	movq (%rcx), %rdx
	add  %rax, %rcx
	movq (%rcx), %rcx
	mov  %rcx, (%rbx)
	sub  %rax, %rbx
	mov  %rdx, (%rbx)
	sub  %rax, %rbx
	xor  %rax, %rax				
	NEXT

L_rpfetch:
	movq GlobalRp(%rip), %rcx
	movq $WSIZE, %rax
        add  %rax, %rcx
	mov  %rcx, (%rbx)
	sub  %rax, %rbx
	xor %rax, %rax
	NEXT

L_spfetch:
	mov  %rbx, %rcx
	movq $WSIZE, %rax
	add  %rax, %rcx
	mov  %rcx, (%rbx)
	sub  %rax, %rbx
	xor  %rax, %rax 
	NEXT

L_fpfetch:
	movq GlobalFp(%rip), %rcx
        addq FpSize(%rip), %rcx
	mov  %rcx, (%rbx)
	DEC_DSP
	NEXT

L_i:
	movq GlobalRp(%rip), %rcx
	movq 3*WSIZE(%rcx), %rcx
	mov  %rcx, (%rbx)
	DEC_DSP
	NEXT

L_j:
	movq GlobalRp(%rip), %rcx
	movq 6*WSIZE(%rcx), %rcx
	mov  %rcx, (%rbx)
	DEC_DSP
	NEXT

L_rtloop:
       # mov  %rbx, %r8   # keep stack ptr
	movq GlobalRp(%rip), %rbx
	movq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rdx
	add  %rax, %rbx
	movq (%rbx), %rcx
	add  %rax, %rbx
	movq (%rbx), %rax
	inc  %rax
	cmp  %rcx, %rax	
	jz L_rtunloop
	mov  %rax, (%rbx)	# set loop counter to next value
	mov  %rdx, %rbp		# set instruction ptr to start of loop
#        mov  %r8, %rbx
        LDSP
	xor  %rax, %rax
	NEXT

L_rtunloop:
	UNLOOP
        # mov %r8, %rbx
        LDSP
	xor %rax, %rax
	NEXT

L_rtplusloop:
	push %rbp
	movq $WSIZE, %rax
	add %rax, %rbx
	mov (%rbx), %rbp	# get loop increment 
	STSP
	movq GlobalRp(%rip), %rbx
	add %rax, %rbx		# get ip and save in rdx
	mov (%rbx), %rdx
	add %rax, %rbx
	mov (%rbx), %rcx	# get terminal count in rcx
	add %rax, %rbx
	mov (%rbx), %rax	# get current loop index
	add %rbp, %rax         # new loop index
	cmpq $0, %rbp           
	jl plusloop1            # loop inc < 0?

     # positive loop increment
	cmp %rcx, %rax
	jl plusloop2            # is new loop index < rcx?
	add %rbp, %rcx
	cmp %rcx, %rax
	jge plusloop2            # is new index >= rcx + inc?
	pop %rbp
        LDSP
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
        LDSP
	xor %rax, %rax
	UNLOOP
	NEXT

plusloop2:
	pop %rbp
	mov %rax, (%rbx)
	mov %rdx, %rbp
        LDSP
	xor %rax, %rax
	NEXT

L_count:
	movq WSIZE(%rbx), %rcx
	xor  %rax, %rax
	movb (%rcx), %al
	incq WSIZE(%rbx)
	mov  %rax, (%rbx)
	movq $WSIZE, %rax
	DEC_DSP
	xor %rax, %rax
	NEXT

L_ival:
L_addr:
	inc  %rbp
	mov  (%rbp), %rcx
	addq $WSIZE-1, %rbp
	mov  %rcx, (%rbx)
	DEC_DSP
	NEXT

L_ptr:
	mov  %rbp, %rcx
	inc  %rcx
	movq (%rcx), %rax
	addq $WSIZE-1, %rcx
	mov  %rcx, %rbp
	movq (%rax), %rax
	mov  %rax, (%rbx)
	DEC_DSP
	xor %rax, %rax
	NEXT

L_2val:
	mov  %rbp, %rcx
	inc  %rcx
        DEC_DSP
	movq (%rcx), %rax  # top cell
	mov  %rax, (%rbx)
	movq WSIZE (%rcx), %rax  # bottom cell
	mov  %rax, WSIZE(%rbx)
	DEC_DSP
	addq $2*WSIZE-1, %rcx
	mov  %rcx, %rbp
	xor  %rax, %rax
	NEXT

L_fval:
        mov %rbx, %rdi
        LDFSP
	movq 1(%rbp), %rcx
	movq %rcx, (%rbx)
	sub %rax, %rbx
	STFSP
	add %rax, %rbp
        mov %rdi, %rbx
	xor %rax, %rax 
	NEXT

L_and:
	_AND
	NEXT
L_or:
	_OR
	NEXT
L_not:
	_NOT
	NEXT
L_xor:
	_XOR
	NEXT

L_boolean_query:
        BOOLEAN_QUERY
        NEXT

L_bool_not:
        DUP
        BOOLEAN_QUERY
        CHECK_BOOLEAN
        _NOT
        NEXT

L_bool_and:
        TWO_BOOLEANS
        CHECK_BOOLEAN
        _AND
        NEXT

L_bool_or:
        TWO_BOOLEANS
        CHECK_BOOLEAN
        _OR
        NEXT

L_bool_xor:
        TWO_BOOLEANS
        CHECK_BOOLEAN
        _XOR
        NEXT

L_eq:
	REL_DYADIC sete
	NEXT

L_ne:
	REL_DYADIC setne
	NEXT

L_ult:
	REL_DYADIC setb
	NEXT

L_ugt:
	REL_DYADIC seta 
	NEXT

L_lt:
	REL_DYADIC setl
	NEXT

L_gt:
	REL_DYADIC setg
	NEXT

L_le:
	REL_DYADIC setle
	NEXT

L_ge:
	REL_DYADIC setge
	NEXT

L_zeroeq:
	REL_ZERO setz
	NEXT

L_zerone:
	REL_ZERO setnz
	NEXT

L_zerolt:
	REL_ZERO setl
	NEXT

L_zerogt:
	REL_ZERO setg
	NEXT

L_within:                          # stack: a b c
	movq 2*WSIZE(%rbx), %rcx   # rcx = b
	movq WSIZE(%rbx), %rax     # rax = c
	sub  %rcx, %rax             # rax = c - b
	INC2_DSP     
	movq WSIZE(%rbx), %rdx     # rdx = a
	sub  %rcx, %rdx             # rdx = a - b
	cmp  %rax, %rdx
	movq $0, %rax
	setb %al
	neg  %rax
	movq %rax, WSIZE(%rbx)
	xor  %rax, %rax
	NEXT

L_deq:
	INC_DSP
	movq (%rbx), %rdx
	INC_DSP
	movq (%rbx), %rcx
	INC_DSP
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
	mov  %rax, (%rbx)
        DEC_DSP
	xor  %rax, %rax
	NEXT

L_dzeroeq:
	INC_DSP
        mov  %rbx, %rcx
	movq (%rbx), %rax
	INC_DSP
	orq  (%rbx), %rax
	cmpq $0, %rax
	movq $0, %rax
	setz %al
	neg  %rax
	mov  %rax, (%rbx)
        mov  %rcx, %rbx
	xor  %rax, %rax
	NEXT

L_dzerolt:
	REL_ZERO setl
        INC_DSP
	movq (%rbx), %rax
	movq %rax, WSIZE(%rbx)
	xor  %rax, %rax
	NEXT	

L_dlt:	
	DLT
	NEXT

L_dult:	# b = (d1.hi u< d2.hi) OR ((d1.hi = d2.hi) AND (d1.lo u< d2.lo)) 
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
	mov  %rbx, %rdi  # save DSP
	add  %rcx, %rbx
	cmpq %rax, (%rbx)
	setb %al
	andb %al, %dl
	orb  %dh, %dl
	xor  %rax, %rax
	movb %dl, %al
	neg  %rax
	mov  %rax, (%rbx)
        mov  %rdi, %rbx
	xor  %rax, %rax
	NEXT
	
L_querydup:
	movq WSIZE(%rbx), %rax
	cmpq $0, %rax
	je L_querydupexit
	mov  %rax, (%rbx)
	DEC_DSP
	xor %rax, %rax
L_querydupexit:
	NEXT

L_dup:
        DUP
        NEXT

L_drop:
        DROP
        NEXT

L_swap:
	SWAP
	NEXT

L_over:
	OVER
	NEXT

L_rot:
	push %rbp
        mov  %rbx, %rdi
	movq $WSIZE, %rax
	add %rax, %rbx
	mov %rbx, %rbp
	add %rax, %rbx
	add %rax, %rbx
	mov (%rbx), %rcx
	mov (%rbp), %rdx
	mov %rcx, (%rbp)
	add %rax, %rbp
	mov (%rbp), %rcx
	mov %rdx, (%rbp)
	mov %rcx, (%rbx)
	xor %rax, %rax
        mov %rdi, %rbx
	pop %rbp
	NEXT

L_minusrot:
        mov  %rbx, %rdi
	movq WSIZE(%rbx), %rax
	mov  %rax, (%rbx)
	INC_DSP
	movq WSIZE(%rbx), %rax
	mov  %rax, (%rbx)
	INC_DSP
	movq WSIZE(%rbx), %rax
	mov  %rax, (%rbx)
	movq -2*WSIZE(%rbx), %rax
	movq %rax, WSIZE(%rbx)
        mov  %rdi, %rbx
	xor  %rax, %rax
	NEXT

L_nip:
        INC_DSP
        movq (%rbx), %rax
        movq %rax, WSIZE(%rbx)
        xor %rax, %rax
	NEXT

L_tuck:
	SWAP
	OVER
	NEXT

L_pick:
	mov  %rbx, %rcx
	movq WSIZE(%rbx), %rax  # pick depth
	inc  %rax
        inc  %rax
	imulq $WSIZE, %rax
	add  %rax, %rcx
	movq (%rcx), %rax
	mov  %rax, WSIZE(%rbx)
	xor  %rax, %rax
	NEXT

L_roll:
	movq $WSIZE, %rax
	add  %rax, %rbx
	STSP
	movq (%rbx), %rax
	inc  %rax
	push %rax
	push %rbx
	imulq $WSIZE, %rax
	add  %rax, %rbx		# addr of item to roll
	movq (%rbx), %rax
	pop  %rbx
	mov  %rax, (%rbx)
	pop  %rax		# number of cells to copy
	mov  %rax, %rcx
	imulq $WSIZE, %rax
	add  %rax, %rbx
	mov  %rbx, %rdx		# dest addr
	subq $WSIZE, %rbx	# src addr
rollloop:
	movq (%rbx), %rax
	subq $WSIZE, %rbx
	xchg %rbx, %rdx
	mov %rax, (%rbx)
	subq $WSIZE, %rbx
	xchg %rbx, %rdx
	loop rollloop
        LDSP
	xor %rax, %rax
	ret

L_depth:
        LDSP
	movq BottomOfStack(%rip), %rax
	sub  %rbx, %rax
	movq $WSIZE, (%rbx)
	movq $0, %rdx
	idivq (%rbx)
	mov  %rax, (%rbx)
	movq $WSIZE, %rax
	subq %rax, GlobalSp(%rip)
	xor %rax, %rax
	ret

L_fdepth:
	movq GlobalFp(%rip), %rbx
	movq BottomOfFpStack(%rip), %rax
        sub  %rbx, %rax
        LDSP
        movq FpSize(%rip), %rcx
	movq $0, %rdx
	idivq %rcx
	mov  %rax, (%rbx)
	subq $WSIZE, %rbx
	STSP
        xor %rax, %rax
	ret
 
L_2drop:
	TWO_DROP
	NEXT

L_fdrop:
        mov %rbx, %rdi
	LDFSP
	add %rax, %rbx
	STFSP
        mov %rdi, %rbx
        xor %rax, %rax
	NEXT

L_fdup:
        mov  %rbx, %rdi
        LDFSP
        mov  %rbx, %rcx
        add  %rax, %rcx
        movq (%rcx), %rcx
        movq %rcx, (%rbx)
        sub  %rax, %rbx
        STFSP
        mov  %rdi, %rbx
        xor  %rax, %rax
        NEXT

L_fswap:
        mov  %rbx, %rdi
        LDFSP
        addq %rax, %rbx
        movq (%rbx), %rcx
        add  %rax, %rbx
        movq (%rbx), %rdx
        movq %rcx, (%rbx)
        sub  %rax, %rbx
        movq %rdx, (%rbx)
#       sub  %rax, %rbx
        mov  %rdi, %rbx
        xor  %rax, %rax
	NEXT

L_fover:
        mov  %rbx, %rdi
	LDFSP
	mov  %rbx, %rcx
        add  %rax, %rcx
	add  %rax, %rcx
	movq (%rcx), %rcx
	movq %rcx, (%rbx)
	sub  %rax, %rbx
	STFSP
        mov  %rdi, %rbx
	xor  %rax, %rax
	NEXT

L_frot:
        mov  %rbx, %rdi
        LDFSP
        add  %rax, %rbx
        movq (%rbx), %rcx
        add  %rax, %rbx
        movq (%rbx), %rdx
        movq %rcx, (%rbx)
        add  %rax, %rbx
        movq (%rbx), %rcx
        movq %rdx, (%rbx)
        sub  %rax, %rbx
        sub  %rax, %rbx
        movq %rcx, (%rbx)
#        sub  %rax, %rbx
        mov  %rdi, %rbx
        xor  %rax, %rax 
	NEXT

L_fpick:
        DROP
        mov  %rbx, %rdi
        movq (%rbx), %rcx  # pick offset
        LDFSP
        mov  %rbx, %rdx  # rdx = dest addr
        add  %rax, %rbx
        imulq %rcx, %rax
        add  %rax, %rbx  # rbx = src addr
        movq (%rbx), %rcx
        mov  %rdx, %rbx
        movq %rcx, (%rbx)
        DEC_FSP
        STFSP
        mov %rdi, %rbx
        xor  %rax, %rax
        NEXT
        
L_f2drop:
        mov %rbx, %rdi
	LDFSP
	add %rax, %rbx
	add %rax, %rbx
	STFSP
        mov %rdi, %rbx
        xor %rax, %rax
	NEXT

L_f2dup:
        mov  %rbx, %rdi
	LDFSP
        push %rbx
        add  %rax, %rbx
        movq (%rbx), %rcx
        add  %rax, %rbx
        movq (%rbx), %rdx
        pop  %rbx
        movq %rdx, (%rbx)
        sub  %rax, %rbx
        movq %rcx, (%rbx)
        sub  %rax, %rbx
 	STFSP
        mov  %rdi, %rbx
        xor  %rax, %rax
	NEXT

L_2dup:
	TWO_DUP
	NEXT

L_2swap:
	TWO_SWAP	
	NEXT

L_2over:
	TWO_OVER
	NEXT

L_2rot:
        mov  %rbx, %rdi
	INC_DSP
	mov  %rbx, %rcx
	movq (%rbx), %rdx
	INC_DSP
	movq (%rbx), %rax
	INC_DSP
	xchg %rdx, (%rbx)
	INC_DSP
	xchg %rax, (%rbx)
	INC_DSP
	xchg %rdx, (%rbx)
	INC_DSP
	xchg %rax, (%rbx)
	mov  %rcx, %rbx
	mov  %rdx, (%rbx)
	INC_DSP
	mov  %rax, (%rbx)
        mov  %rdi, %rbx
	xor %rax, %rax
	NEXT

L_question:
	FETCH
        STSP
	call CPP_dot	
	ret	

L_afetch:
L_fetch:
	FETCH
	NEXT

L_store:
        movq $WSIZE, %rax
        add %rax, %rbx
        mov (%rbx), %rcx        # address to store to in rcx
        add %rax, %rbx
        mov (%rbx), %rax        # value to store in rax
        mov %rax, (%rcx)
        xor %rax, %rax
        NEXT

L_cfetch:
	xor  %rax, %rax
        mov  %rbx, %rdx
        addq $WSIZE, %rdx
	movq (%rdx), %rcx
	movb (%rcx), %al    # 8-bit move
	mov  %rax, (%rdx)
	xor  %rax, %rax
	NEXT

L_cstore:
	movq $WSIZE, %rax
        add  %rax, %rbx
	movq (%rbx), %rcx	# address to store
	add  %rax, %rbx
	movq (%rbx), %rax	# value to store
	movb %al, (%rcx)
	xor %rax, %rax
	NEXT	

L_swfetch:
	movq WSIZE(%rbx), %rcx
	movw (%rcx), %ax
	cwde
	cdqe
	movq %rax, WSIZE(%rbx)
	xor %rax, %rax
	NEXT

L_uwfetch:
        movq WSIZE(%rbx), %rcx
        movw (%rcx), %ax
        movq %rax, WSIZE(%rbx)
        xor  %rax, %rax
        NEXT

L_wstore:
	movq $WSIZE, %rax
	addq %rax, %rbx
	movq (%rbx), %rcx
	add  %rax, %rbx
	movq (%rbx), %rdx
	movw %dx, (%rcx)
	xor  %rax, %rax
	NEXT

L_sffetch:
        INC_DSP
        movq (%rbx), %rcx  # rcx = sfloat src addr
	mov  %rbx, %rdi
	LDFSP
	flds (%rcx)
	fstpl (%rbx)
	sub  %rax, %rbx
	STFSP
        mov  %rdi, %rbx
	xor  %rax, %rax
	NEXT

L_sfstore:
	INC_DSP
        movq (%rbx), %rcx  # rcx = sfloat dest addr
        mov  %rbx, %rdi
        LDFSP
        add  %rax, %rbx
	fldl (%rbx)        # load the double f number into NDP
	fstps (%rcx)
        STFSP
        mov  %rdi, %rbx
	xor %rax, %rax
	NEXT


L_2fetch:
        mov  %rbx, %rdx
        INC_DSP
	movq (%rbx), %rcx
        movq (%rcx), %rax
	mov  %rax, (%rdx) 
        addq $WSIZE, %rcx
	movq (%rcx), %rax
        mov  %rax, (%rbx)
	subq $WSIZE, %rdx
	mov  %rdx, %rbx
	xor  %rax, %rax
	NEXT

L_2store:
        movq $WSIZE, %rdx
	add  %rdx, %rbx
        mov  %rbx, %rax
	movq (%rbx), %rbx  # address to store
	add  %rdx, %rax
	movq (%rax), %rcx
        mov  %rcx, (%rbx)
	add  %rdx, %rax
        add  %rdx, %rbx 
	movq (%rax), %rcx
	mov  %rcx, (%rbx)
	mov  %rax, %rbx
	xor %rax, %rax
	NEXT


L_slfetch:
        movq WSIZE(%rbx), %rcx
        movl (%rcx), %eax  # 32-bit move
        cdqe
        movq %rax, WSIZE(%rbx)
        xor %rax, %rax
        NEXT

L_ulfetch:
        movq WSIZE(%rbx), %rcx
        movl (%rcx), %eax  # 32-bit move
        movq %rax, WSIZE(%rbx)
        xor %rax, %rax
        NEXT

L_lstore:
        movq $WSIZE, %rax
        addq %rax, %rbx
        mov (%rbx), %rcx  # address in rcx
        addq %rax, %rbx
        mov (%rbx), %rax  # value in rax
        movl %eax, (%rcx)
        xor %rax, %rax
        NEXT

L_dffetch:	
	INC_DSP
	movq (%rbx), %rcx  # rcx = fpaddr
	mov  %rbx, %rdi
	movq (%rcx), %rcx
        LDFSP
	mov  %rcx, (%rbx) 
        sub  %rax, %rbx
        STFSP
        mov  %rdi, %rbx
	xor  %rax, %rax
	NEXT

L_dfstore:
	INC_DSP
	movq (%rbx), %rcx  # address to store
	mov  %rbx, %rdi
	LDFSP
	add  %rax, %rbx
	movq (%rbx), %rax
	mov  %rax, (%rcx)
	STFSP
        mov  %rdi, %rbx
	xor  %rax, %rax
	NEXT

L_abs:
	_ABS
	NEXT

L_max:
	INC_DSP
	movq (%rbx), %rax
	movq WSIZE(%rbx), %rcx
	cmp %rax, %rcx
	jl max1
	movq %rcx, WSIZE(%rbx)
	jmp maxexit
max1:
	movq %rax, WSIZE(%rbx)
maxexit:
	xor  %rax, %rax
	NEXT

L_min:
	INC_DSP
	movq (%rbx), %rax
	movq WSIZE(%rbx), %rcx
	cmp %rax, %rcx
	jg min1
	mov %rcx, WSIZE(%rbx)
	jmp minexit
min1:
	movq %rax, WSIZE(%rbx)
minexit:
	xor %rax, %rax
	NEXT

L_stod:
        STOD 
        NEXT

L_dmax:
	TWO_OVER
	TWO_OVER
	DLT
	DROP
	movq (%rbx), %rax
	cmpq $0, %rax
	jne dmin1
	TWO_DROP
	xor %rax, %rax
	NEXT

L_dmin:
	TWO_OVER
	TWO_OVER
	DLT
        DROP
        movq (%rbx), %rax
	cmpq $0, %rax
	je dmin1
	TWO_DROP
	xor %rax, %rax
	NEXT
dmin1:
	TWO_SWAP
	TWO_DROP
	xor %rax, %rax
	NEXT

#  L_dtwostar and L_dtwodiv are valid for two's-complement systems
L_dtwostar:
	INC_DSP
	movq WSIZE(%rbx), %rax
	mov  %rax, %rcx
	salq $1, %rax
	movq %rax, WSIZE(%rbx)
	shrq $8*WSIZE-1, %rcx
	movq (%rbx), %rax
	salq $1, %rax
	or   %rcx, %rax
	mov  %rax, (%rbx)
        DEC_DSP
	xor  %rax, %rax
	NEXT

L_dtwodiv:
	INC_DSP
	movq (%rbx), %rax
	mov  %rax, %rcx
	sarq $1, %rax
	mov  %rax, (%rbx)
	shlq $8*WSIZE-1, %rcx
	movq WSIZE(%rbx), %rax
	shrq $1, %rax
	or   %rcx, %rax
	movq %rax, WSIZE(%rbx)
        DEC_DSP
	xor  %rax, %rax
	NEXT

L_add:
	INC_DSP
	movq (%rbx), %rax
	addq %rax, WSIZE(%rbx)
	xor  %rax, %rax
	NEXT

L_sub:
        INC_DSP
        movq (%rbx), %rax  
        subq %rax, WSIZE(%rbx)
        xor  %rax, %rax
        NEXT

L_mul:
        movq $WSIZE, %rcx
        add  %rcx, %rbx
        movq (%rbx), %rax
        add  %rcx, %rbx
        imulq (%rbx)
        mov  %rax, (%rbx)
        sub  %rcx, %rbx
        xor  %rax, %rax
        NEXT

L_starplus:
	INC_DSP
	movq (%rbx), %rcx
	INC_DSP 
	movq (%rbx), %rax
	INC_DSP
	imulq (%rbx)
	add  %rcx, %rax
	mov  %rax, (%rbx)
	DEC_DSP
	xor  %rax, %rax
	NEXT

L_fsl_mat_addr:
	INC_DSP
	mov (%rbx), %rcx   # rcx = j (column index)
	INC_DSP
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
	xor %rax, %rax
	NEXT

L_div:
        INC_DSP
        DIV
	mov %rax, (%rbx)
        DEC_DSP
        xor %rax, %rax
	NEXT

L_mod:
        INC_DSP
	DIV
	mov %rdx, (%rbx)
        DEC_DSP
        xor %rax, %rax
	NEXT

L_slashmod:
        INC_DSP
        DIV
        mov %rdx, (%rbx)
        DEC_DSP
        mov %rax, (%rbx)
	DEC_DSP
        xor %rax, %rax
	NEXT

L_udivmod:
        INC_DSP
        UDIV
        mov %rdx, (%rbx)
        DEC_DSP
        mov %rax, (%rbx)
        DEC_DSP
        xor %rax, %rax
        NEXT

L_starslash:
	STARSLASH
	NEXT

L_starslashmod:
	STARSLASH
	mov %rdx, (%rbx)
	DEC_DSP
	SWAP
        STSP
	ret

L_plusstore:
        movq $WSIZE, %rdx
        add  %rdx, %rbx
	movq (%rbx), %rcx
        movq (%rcx), %rax
        add  %rdx, %rbx
        movq (%rbx), %rdx
        add  %rdx, %rax 
	mov  %rax, (%rcx)
	xor %rax, %rax
	NEXT

L_dabs:
	LDSP
        mov  %rbx, %rdx
	INC_DSP
	movq (%rbx), %rcx  # high qword
	mov  %rcx, %rax
	cmpq $0, %rax
	jl dabs_go
        mov  %rdx, %rbx
        STSP
	xor  %rax, %rax
	ret
dabs_go:
	INC_DSP
	movq (%rbx), %rax  # low qword
	clc
	subq $1, %rax
	not  %rax
	mov  %rax, (%rbx)
	mov  %rcx, %rax
	sbbq $0, %rax
	not  %rax
	movq %rax, -WSIZE(%rbx)
        mov  %rdx, %rbx
        STSP
	xor  %rax, %rax
	ret

L_dnegate:
        LDSP
	DNEGATE
        STSP
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
	movq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rcx
	add  %rax, %rbx
	mov  %rcx, %rax
	mulq (%rbx)
	mov  %rax, (%rbx)
	DEC_DSP
	mov  %rdx, (%rbx)
        DEC_DSP
	xor %rax, %rax				
	NEXT

L_dsstar:
# multiply signed double and signed to give triple length product
	movq $WSIZE, %rcx
	add  %rcx, %rbx
	movq (%rbx), %rdx
	cmpq $0, %rdx
	setl %al
	add  %rcx, %rbx
	movq (%rbx), %rdx
	cmpq $0, %rdx
	setl %ah
	xorb %ah, %al      # sign of result
	andq $1, %rax
	push %rax
        LDSP
	_ABS
	INC_DSP
	STSP
	call L_dabs
#	LDSP
	DEC_DSP
	STSP
	DEC_DTSP
	call L_udmstar
#       LDSP
	pop  %rax
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
	movq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rcx
	cmpq $0, %rcx
	jz   E_div_zero
	add  %rax, %rbx
	movq $0, %rdx
	movq (%rbx), %rax
	divq %rcx
	cmpq $0, %rax
	jne  E_div_overflow
	movq (%rbx), %rdx
	INC_DSP
	movq (%rbx), %rax
	divq %rcx
	mov %rdx, (%rbx)
	DEC_DSP
	mov %rax, (%rbx)
	DEC_DSP
	xor %rax, %rax		
	NEXT

L_uddivmod:
# Divide unsigned double length by unsigned single length to
# give unsigned double quotient and single remainder.
        LDSP
        movq $WSIZE, %rax
        add  %rax, %rbx
        movq (%rbx), %rcx
        cmpq $0, %rcx
        jz E_div_zero
        add  %rax, %rbx
        movq $0, %rdx
        movq (%rbx), %rax
        divq %rcx
        mov %rax, %r8  # %r8 = hi quot
        INC_DSP
        movq (%rbx), %rax
        divq %rcx
        mov  %rdx, (%rbx)
        DEC_DSP
        mov  %rax, (%rbx)
        DEC_DSP
        mov  %r8, (%rbx)
        DEC_DSP
        STSP
        xor %rax, %rax
        ret

L_mstar:
	movq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rcx
	add  %rax, %rbx
	mov  %rcx, %rax
	imulq (%rbx)
	mov  %rax, (%rbx)
	DEC_DSP
	mov  %rdx, (%rbx)
        DEC_DSP
	xor  %rax, %rax		
	NEXT

L_mplus:
	STOD
	DPLUS
	NEXT

L_mslash:
	movq $WSIZE, %rax
	add  %rax, %rbx
	movq (%rbx), %rcx
	add  %rax, %rbx
	cmpq $0, %rcx
	je  E_div_zero
	movq (%rbx), %rdx
	add  %rax, %rbx
	movq (%rbx), %rax
	idivq %rcx
	mov  %rax, (%rbx)
        DEC_DSP
	xor %rax, %rax		
	NEXT

L_udmstar:
# Multiply unsigned double and unsigned single to give 
# the triple length product.
	LDSP
	INC_DSP
	movq (%rbx), %rcx
	INC_DSP
	movq (%rbx), %rax
	mulq %rcx
	movq %rdx, -WSIZE(%rbx)
	mov  %rax, (%rbx)
	INC_DSP
	mov  %rcx, %rax
	mulq (%rbx)
	mov  %rax, (%rbx)
	DEC_DSP
	movq (%rbx), %rax
	DEC_DSP
	clc
	add  %rdx, %rax
	mov  %rax, WSIZE(%rbx)
	movq (%rbx), %rax
	adcq $0, %rax
	mov  %rax, (%rbx)
        DEC_DSP
	xor %rax, %rax 		
	ret

L_utsslashmod:
# Divide unsigned triple length by unsigned single length to
# give an unsigned triple quotient and single remainder.
	INC_DSP
	movq (%rbx), %rcx		# divisor in rcx
	cmpq $0, %rcx
	jz  E_div_zero
	INC_DSP
	movq (%rbx), %rax		# ut3
	movq $0, %rdx
	divq %rcx			# ut3/u
	call utmslash1
	LDSP
	movq WSIZE(%rbx), %rax
	mov  %rax, (%rbx)
	INC_DSP
	movq WSIZE(%rbx), %rax
	mov  %rax, (%rbx)
	INC_DSP	
	movq -17*WSIZE(%rbx), %rax       # r7
	mov  %rax, (%rbx)
	subq $3*WSIZE, %rbx
	movq -5*WSIZE(%rbx), %rax        # q3
	mov  %rax, (%rbx)
	DEC_DSP
	STSP
	xor %rax, %rax	
	ret

L_tabs:
# Triple length absolute value (needed by L_stsslashrem, STS/REM)
	movq WSIZE(%rbx), %rcx
	mov  %rcx, %rax
	cmpq $0, %rax
	jl tabs1
	xor  %rax, %rax
	ret
tabs1:
	addq $3*WSIZE, %rbx
	movq (%rbx), %rax
	clc
	subq $1, %rax
	not  %rax
	mov  %rax, (%rbx)
	DEC_DSP
	movq (%rbx), %rax
	sbbq $0, %rax
	not  %rax
	mov  %rax, (%rbx)
	mov  %rcx, %rax
	sbbq $0, %rax
	not  %rax
	mov  %rax, -WSIZE(%rbx)
        subq $2*WSIZE, %rbx
	xor  %rax, %rax
	ret

L_stsslashrem:
# Divide signed triple length by signed single length to give a
# signed triple quotient and single remainder, according to the
# rule for symmetric division.
	INC_DSP
	movq (%rbx), %rcx		# divisor in rcx
	cmpq $0, %rcx
	jz   E_div_zero
	movq WSIZE(%rbx), %rax		# t3
	push %rax
	cmpq $0, %rax
	movq $0, %rax
	setl %al
	neg  %rax
	mov  %rax, %rdx
	cmpq $0, %rcx
	movq $0, %rax
	setl %al
	neg  %rax
	xor  %rax, %rdx			# sign of quotient
	push %rdx
	call L_tabs
        DEC_DSP
	_ABS
        STSP
	call L_utsslashmod
        LDSP
	pop  %rdx
	cmpq $0, %rdx
	jz stsslashrem1
	TNEG
stsslashrem1:	
	pop  %rax
	cmpq $0, %rax
	jz stsslashrem2
	addq $4*WSIZE, %rbx
	negq (%rbx)	
stsslashrem2:
	xor  %rax, %rax
	ret

L_utmslash:
# Divide unsigned triple length by unsigned single to give 
# unsigned double quotient. A "Divide Overflow" error results
# if the quotient doesn't fit into a double word.
	LDSP
	INC_DSP
	movq (%rbx), %rcx		# divisor in rcx
	cmpq $0, %rcx
	jz   E_div_zero	
	INC_DSP
	movq (%rbx), %rdx               # ut3
	movq WSIZE(%rbx), %rax          # ut2
	divq %rcx			# ut3:ut2/u  generates INT 0 on ovflow
	xor  %rdx, %rdx
	movq (%rbx), %rax
	divq %rcx
	xor  %rax, %rax
utmslash1:	
	push %rbx			# keep local stack ptr
	LDSP
	movq %rax, -4*WSIZE(%rbx)	# q3
	movq %rdx, -5*WSIZE(%rbx)	# r3
	pop  %rbx
	INC_DSP
	movq (%rbx), %rax		# ut2
	movq $0, %rdx
	divq %rcx			# ut2/u
	push %rbx
	LDSP
	movq %rax, -2*WSIZE(%rbx)	# q2
	movq %rdx, -3*WSIZE(%rbx)	# r2
	pop  %rbx
	INC_DSP
	movq (%rbx), %rax		# ut1
	movq $0, %rdx
	divq %rcx			# ut1/u
	push %rbx
	LDSP
	mov  %rax, (%rbx)		# q1
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
	jnc  utmslash2
	inc  %rdx
utmslash2:			
	addq -11*WSIZE(%rbx), %rax	# r1 + r5 + r6
	jnc  utmslash3
	inc  %rdx
utmslash3:
	divq %rcx
	movq %rax, -12*WSIZE(%rbx)	# q7
	movq %rdx, -13*WSIZE(%rbx)	# r7
	movq $0, %rdx
	addq -10*WSIZE(%rbx), %rax	# q7 + q6
	jnc  utmslash4
	inc  %rdx
utmslash4:	
	addq -8*WSIZE(%rbx), %rax	# q7 + q6 + q5
	jnc  utmslash5
	inc %rdx
utmslash5:	
	add (%rbx), %rax		# q7 + q6 + q5 + q1
	jnc utmslash6
	inc %rdx
utmslash6:
	pop  %rbx
	mov  %rax, (%rbx)
	DEC_DSP
	push %rbx
	LDSP
	movq -2*WSIZE(%rbx), %rax	# q2
	addq -6*WSIZE(%rbx), %rax	# q2 + q4
	add  %rdx, %rax
	pop  %rbx
	mov  %rax, (%rbx)
	DEC_DSP
	STSP
	xor  %rax, %rax
	ret

L_mstarslash:
	LDSP
	INC_DSP
        movq (%rbx), %rax  # rax = +n2
        cmpq $0, %rax
        jz E_div_zero
	INC_DSP
	movq (%rbx), %rax   # rax = n1
	INC_DSP
	xorq (%rbx), %rax
	shrq $8*WSIZE-1, %rax  # eax = sign(n1) xor sign(d1)
	push %rax	# keep sign of result -- negative is nonzero
        subq $2*WSIZE, %rbx
	_ABS            # abs(n1)
	INC_DSP
	STSP
	call L_dabs
#	LDSP
	DEC_DSP         # TOS = +n2
	STSP
	call L_udmstar
#	LDSP
	DEC_DSP
	STSP
	call L_utmslash
        LDSP	
	pop  %rax
	cmpq $0, %rax
	jnz mstarslash_neg
	xor  %rax, %rax
	ret
mstarslash_neg:
	DNEGATE
	xor %rax, %rax
	ret
		
L_fmslashmod:
	movq $WSIZE, %rax
	add %rax, %rbx
	STSP
	movq (%rbx), %rcx
	cmpq $0, %rcx
	jz   E_div_zero
	add  %rax, %rbx
	movq (%rbx), %rdx
	add  %rax, %rbx
	movq (%rbx), %rax
	idivq %rcx
	mov  %rdx, (%rbx)
	DEC_DSP
	mov  %rax, (%rbx)
	cmpq $0, %rcx
	jg fmslashmod2
	cmpq $0, %rdx
	jg fmslashmod3
        LDSP
	xor %rax, %rax
	NEXT
fmslashmod2:		
	cmpq $0, %rdx
	jge fmslashmodexit
fmslashmod3:	
	dec  %rax		# floor the result
	mov  %rax, (%rbx)
	INC_DSP
	add  %rcx, (%rbx)
fmslashmodexit:
        LDSP
	xor  %rax, %rax
	NEXT

L_smslashrem:
	movq $WSIZE, %rax
	add  %rax, %rbx
	STSP
	movq (%rbx), %rcx
	cmpq $0, %rcx
	jz   E_div_zero
	add  %rax, %rbx
	movq (%rbx), %rdx
	add  %rax, %rbx
	movq (%rbx), %rax
	idivq %rcx
	mov  %rdx, (%rbx)
	DEC_DSP
	mov  %rax, (%rbx)
	LDSP
	xor %rax, %rax		
	NEXT

L_stof:
        INC_DSP
	fildq (%rbx)
        mov %rbx, %rdi
	LDFSP
	fstpl (%rbx)
	DEC_FSP
	STFSP
        mov %rdi, %rbx
	xor %rax, %rax
	NEXT

L_dtof:
	INC_DSP
	movq (%rbx), %rsi
        INC_DSP
        movq (%rbx), %rdi
        push %rbx
        call __floattidf
        LDFSP
        movq %xmm0, (%rbx)
        DEC_FSP
        STFSP
        pop %rbx
	xor %rax, %rax	
	NEXT	

L_froundtos:
        mov %rbx, %rdi
        LDFSP
        add %rax, %rbx
	fldl (%rbx)
	STFSP
        mov %rdi, %rbx
	fistpq (%rbx)
	DEC_DSP
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
	mov %rcx, (%rbx)
	fldcw (%rbx)		# restore NDP control word
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
        xor %rax, %rax 
	NEXT

L_fne:
	FREL_DYADIC xorb $64 setnz
	NEXT

L_feq:
	FREL_DYADIC andb $64 setnz
	NEXT

L_flt:
	FREL_DYADIC andb $65 setz
	NEXT

L_fgt:
	FREL_DYADIC andb $1 setnz
	NEXT	

L_fle:
	FREL_DYADIC xorb $1 setnz
	NEXT

L_fge:
	FREL_DYADIC andb $65 setnz
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
        mov %rbx, %rdi
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
        mov %rdi, %rbx
	NEXT

L_fplusstore:
        mov %rbx, %rdi
        LDFSP
        add %rax, %rbx
        fldl (%rbx)
        STFSP
        mov %rdi, %rbx
        INC_DSP
        mov (%rbx), %rcx
        fldl (%rcx)
        faddp
        fstpl (%rcx)
        xor %rax, %rax
        NEXT

