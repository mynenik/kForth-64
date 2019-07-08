// vm32-fast.s
//
// The assembler portion of the kForth 32-bit Virtual Machine
// (fast version)
//
// Copyright (c) 1998--2018 Krishna Myneni,
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
.include "vm32-common.s"

.macro SWAP
	movl %ebx, %eax
        addl $WSIZE, %eax
	movl (%eax), %ecx
	addl $WSIZE, %eax
	movl (%eax), %edx
	movl %ecx, (%eax)
	subl $WSIZE, %eax
	movl %edx, (%eax)
	xorl %eax, %eax
.endm


.macro OVER
        movl 2*WSIZE(%ebx), %ecx
        movl %ecx, (%ebx)
	DEC_DSP
.endm
	
.macro FDUP
	movl %ebx, %ecx
	INC_DSP
	movl (%ebx), %edx
	INC_DSP
	movl (%ebx), %eax
	movl %ecx, %ebx
	movl %eax, (%ebx)
	DEC_DSP
	movl %edx, (%ebx)
	DEC_DSP
	xor %eax, %eax
.endm
	
.macro FDROP
	INC2_DSP
.endm
	
.macro FSWAP
	movl $WSIZE, %ecx
	addl %ecx, %ebx
	movl (%ebx), %edx
	addl %ecx, %ebx
	movl (%ebx), %eax
	addl %ecx, %ebx
	xchgl %edx, (%ebx)
	addl %ecx, %ebx
	xchgl %eax, (%ebx)
	subl %ecx, %ebx
	subl %ecx, %ebx
	movl %eax, (%ebx)
	subl %ecx, %ebx
	movl %edx, (%ebx)
	subl %ecx, %ebx
	xorl %eax, %eax
.endm
		
.macro FOVER
	movl %ebx, %ecx
	addl $3*WSIZE, %ebx
	movl (%ebx), %edx
	INC_DSP
	movl (%ebx), %eax
	movl %ecx, %ebx
	movl %eax, (%ebx)
	DEC_DSP
	movl %edx, (%ebx)
	DEC_DSP
	xor %eax, %eax
.endm
	
.macro PUSH_R
	movl $WSIZE, %eax
	addl %eax, %ebx	
	movl (%ebx), %ecx
	movl GlobalRp, %edx
	movl %ecx, (%edx)
	subl %eax, %edx
	movl %edx, GlobalRp
        xor %eax, %eax
.endm

.macro POP_R
	movl $WSIZE, %eax
	movl GlobalRp, %edx
	addl %eax, %edx
	movl %edx, GlobalRp
	movl (%edx), %ecx
	movl %ecx, (%ebx)
	subl %eax, %ebx
	xor %eax, %eax
.endm

.macro FETCH
	movl %ebx, %edx	
	addl $WSIZE, %edx
        movl (%edx), %eax	
        movl (%eax), %eax
	movl %eax, (%edx)
	xor %eax, %eax
.endm
	
.macro STORE
	movl $WSIZE, %eax
        addl %eax, %ebx
        movl (%ebx), %ecx	# address to store to in ecx
	addl %eax, %ebx
	movl (%ebx), %edx	# value to store in edx
	movl %edx, (%ecx)
	xor %eax, %eax
.endm

// Dyadic Logic operators 
	
.macro LOGIC_DYADIC op
	movl $WSIZE, %ecx
	addl %ecx, %ebx
	movl (%ebx), %eax
	addl %ecx, %ebx
	\op (%ebx), %eax
	movl %eax, (%ebx)
	subl %ecx, %ebx
	xorl %eax, %eax 
.endm
	
.macro _AND
	LOGIC_DYADIC andl
.endm

.macro _OR
	LOGIC_DYADIC orl
.endm

.macro _XOR
	LOGIC_DYADIC xorl
.endm


// use algorithm from DNW's vm-osxppc.s
.macro _ABS	
	INC_DSP
	movl (%ebx), %ecx
	xorl %eax, %eax
	cmpl %eax, %ecx
	setl %al
	negl %eax
	movl %eax, %edx
	xorl %ecx, %edx
	subl %eax, %edx
	movl %edx, (%ebx)
	DEC_DSP
	xorl %eax, %eax
.endm

// Dyadic relational operators (single length numbers) 
	
.macro REL_DYADIC setx
	movl $WSIZE, %ecx
	addl %ecx, %ebx
	movl (%ebx), %eax
	addl %ecx, %ebx
	cmpl %eax, (%ebx)
	movl $0, %eax
	\setx %al
	negl %eax
	movl %eax, (%ebx)
	subl %ecx, %ebx
	xorl %eax, %eax
.endm

	
// Relational operators for zero (single length numbers)
	
.macro REL_ZERO setx
	INC_DSP
	movl (%ebx), %eax
	cmpl $0, %eax
	movl $0, %eax
	\setx %al
	negl %eax
	movl %eax, (%ebx)
	DEC_DSP
	xorl %eax, %eax
.endm

.macro FREL_DYADIC logic arg set
	movl $WSIZE, %ecx
	addl %ecx, %ebx
	fldl (%ebx)
	addl %ecx, %ebx
	addl %ecx, %ebx
	fcompl (%ebx)
	fnstsw %ax
	andb $65, %ah
	\logic \arg, %ah
	movl $0, %eax
	\set %al
	negl %eax
	addl %ecx, %ebx
	movl %eax, (%ebx)
	subl %ecx, %ebx
	xorl %eax, %eax
.endm

	# b = (d1.hi < d2.hi) OR ((d1.hi = d2.hi) AND (d1.lo u< d2.lo))
.macro DLT
	movl $WSIZE, %ecx
	xorl %edx, %edx
	addl %ecx, %ebx
	movl (%ebx), %eax
	cmpl %eax, 2*WSIZE(%ebx)
	sete %dl
	setl %dh
	addl %ecx, %ebx
	movl (%ebx), %eax
	addl %ecx, %ebx
	addl %ecx, %ebx
	cmpl %eax, (%ebx)
	setb %al
	andb %al, %dl
	orb  %dh, %dl
	xorl %eax, %eax
	movb %dl, %al
	negl %eax
	movl %eax, (%ebx)
	subl %ecx, %ebx	
	xorl %eax, %eax
.endm

		
.macro DNEGATE
	INC_DSP
	movl %ebx, %ecx
	INC_DSP
	movl (%ebx), %eax
	notl %eax
	clc
	addl $1, %eax
	movl %eax, (%ebx)
	movl %ecx, %ebx
	movl (%ebx), %eax
	notl %eax
	adcl $0, %eax
	movl %eax, (%ebx)
	DEC_DSP
	xor %eax, %eax
.endm


.macro STARSLASH
	movl $2*WSIZE, %eax
        addl %eax, %ebx
        movl WSIZE(%ebx), %eax
        imull (%ebx)
	idivl -WSIZE(%ebx)
	movl %eax, WSIZE(%ebx)
	xor %eax, %eax
.endm

.macro TNEG
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %edx
	addl %eax, %ebx
	movl (%ebx), %ecx
	addl %eax, %ebx
	movl (%ebx), %eax
	notl %eax
	notl %ecx
	notl %edx
	clc
	addl $1, %eax
	adcl $0, %ecx
	adcl $0, %edx
	movl %eax, (%ebx)
	movl $WSIZE, %eax
	subl %eax, %ebx
	movl %ecx, (%ebx)
	subl %eax, %ebx
	movl %edx, (%ebx)
	movl GlobalSp, %ebx
	xor %eax, %eax	
.endm

// VIRTUAL MACHINE 
					
.global vm
	.type	vm,@function
vm:	
        pushl %ebp
        pushl %ebx
        pushl %ecx
        pushl %edx
	pushl GlobalIp
	pushl vmEntryRp
        movl %esp, %ebp
        movl 28(%ebp), %ebp     # load the Forth instruction pointer
        movl %ebp, GlobalIp
	movl GlobalRp, %eax
	movl %eax, vmEntryRp
	xor %eax, %eax
	movl GlobalSp, %ebx
next:
        movb (%ebp), %al         # get the opcode
	movl JumpTable(,%eax,4), %ecx	# machine code address of word
	xor %eax, %eax          # clear error code
	call *%ecx		# call the word
	movl GlobalSp, %ebx
	movl GlobalIp, %ebp
	incl %ebp		 # increment the Forth instruction ptr
	movl %ebp, GlobalIp
	cmpb $0, %al		 # check for error
	jz next        
exitloop:
        cmpl $OP_RET, %eax         # return from vm?
        jnz vmexit
        xor %eax, %eax            # clear the error
vmexit:
	pop vmEntryRp
	pop GlobalIp
	pop %edx
        pop %ecx
        pop %ebx
        pop %ebp
        ret

L_ret:
	movl vmEntryRp, %eax		# Return Stack Ptr on entry to VM
	movl GlobalRp, %ecx
	cmpl %eax, %ecx
	jl ret1
        movl $OP_RET, %eax             # exhausted the return stack so exit vm
        ret
ret1:
	addl $WSIZE, %ecx
        movl %ecx, GlobalRp
ret2:   movl (%ecx), %eax
	movl %eax, GlobalIp		# reset the instruction ptr
        xorl %eax, %eax
retexit:
        ret

L_tobody:
	INC_DSP
	movl (%ebx), %ecx	# code address
	incl %ecx		# the data address is offset by one
	movl (%ecx), %ecx
	movl %ecx, (%ebx)
	DEC_DSP
	movl %ebx, GlobalSp
	ret

#
# For precision delays, use MS instead of USLEEP
# Use USLEEP when task can be put to sleep and reawakened by OS
#
L_usleep:
	movl $WSIZE, %eax
	addl %eax, %ebx
	pushl %ebx
	movl (%ebx), %eax
	pushl %eax
	call usleep
	popl %eax
	popl %ebx
	movl %ebx, GlobalSp
	xorl %eax, %eax
	ret

L_ms:
	movl WSIZE(%ebx), %eax
	imull $1000, %eax
	movl %eax, WSIZE(%ebx)
	movl %ebx, GlobalSp
	call C_usec
	ret

L_fill:
	SWAP
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx
	pushl %ecx
	addl %eax, %ebx
	movl (%ebx), %ecx
	pushl %ecx
	addl %eax, %ebx
	movl %ebx, GlobalSp
	movl (%ebx), %ecx
	pushl %ecx
	call memset
	addl $3*WSIZE, %esp
	xorl %eax, %eax
fillexit:	
	ret

L_erase:
	movl $0, (%ebx)
	DEC_DSP
	call L_fill
	ret

L_blank:
	movl $32, (%ebx)
	DEC_DSP
	call L_fill
	ret

L_move:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx
	pushl %ecx
	SWAP
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx
	pushl %ecx
	addl %eax, %ebx
	movl (%ebx), %ecx
	pushl %ecx
	movl %ebx, GlobalSp
	call memmove
	addl $12, %esp
	xorl %eax, %eax				
	ret

L_cmove:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx		# nbytes in ecx
	cmpl $0, %ecx
	jnz  cmove1
	INC2_DSP
	xorl %eax, %eax
	NEXT		
cmove1:	addl %eax, %ebx
	movl (%ebx), %edx		# dest addr in edx
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %eax		# src addr in eax
	movl %ebx, GlobalSp
	movl %eax, %ebx			# src addr in ebx
cmoveloop: movb (%ebx), %al
	movb %al, (%edx)
	incl %ebx
	incl %edx
	loop cmoveloop
	movl GlobalSp, %ebx
	xor %eax, %eax				
	NEXT

L_cmovefrom:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx	# load count register
	addl %eax, %ebx
cmovefrom2:
	movl (%ebx), %edx
	addl %ecx, %edx         
	decl %edx               # dest addr in %edx
	addl %eax, %ebx
cmovefrom3:
	movl %ebx, GlobalSp
	movl %ecx, %eax
	cmpl $0, %eax
	jnz cmovefrom4
	ret
cmovefrom4:
	movl (%ebx), %ebx	
	decl %eax
	addl %eax, %ebx		# src addr in %ebx
cmovefromloop:	
	movb (%ebx), %al
	decl %ebx
	xchgl %ebx, %edx
	movb %al, (%ebx)
	decl %ebx
	xchgl %ebx, %edx
	loop cmovefromloop	
	xor %eax, %eax
	ret

L_slashstring:
	INC_DSP
	movl (%ebx), %ecx
	INC_DSP
	subl %ecx, (%ebx)
	INC_DSP
	addl %ecx, (%ebx)
	subl $2*WSIZE, %ebx
	NEXT

L_call:	
	INC_DSP
	movl %ebx, GlobalSp
	call *(%ebx)
	movl GlobalSp, %ebx
	ret

L_push_r:
	PUSH_R
        NEXT

L_pop_r:
	POP_R
	NEXT

L_twopush_r:
	INC_DSP
	movl (%ebx), %edx
	INC_DSP
	movl (%ebx), %eax
	movl GlobalRp, %ecx
	movl %eax, (%ecx)
	subl $WSIZE, %ecx
	movl %edx, (%ecx)
	subl $WSIZE, %ecx
	movl %ecx, GlobalRp
	xor %eax, %eax
	NEXT

L_twopop_r:
	movl GlobalRp, %ecx
	addl $WSIZE, %ecx
	movl (%ecx), %edx
	addl $WSIZE, %ecx
	movl (%ecx), %eax
	movl %ecx, GlobalRp
	movl %eax, (%ebx)
	DEC_DSP
	movl %edx, (%ebx)
	DEC_DSP
	xor %eax, %eax				
	NEXT

L_puship:
        movl %ebp, %eax
        movl GlobalRp, %ecx
        mov %eax, (%ecx)
	movl $WSIZE, %eax
        subl %eax, GlobalRp
        xor %eax, %eax
        NEXT

L_execute:	
        movl %ebp, %ecx
        movl GlobalRp, %edx
        movl %ecx, (%edx)
	movl $WSIZE, %eax 
        subl %eax, %edx 
	movl %edx, GlobalRp
        addl %eax, %ebx
        movl (%ebx), %eax
	decl %eax
	movl %eax, %ebp
        xorl %eax, %eax
        NEXT

L_definition:
        movl %ebp, %eax
	incl %eax
	movl (%eax), %ecx # address to execute
	addl $3, %eax
	movl %eax, %edx
	movl GlobalRp, %eax
	movl %edx, (%eax)
	subl $WSIZE, %eax
	movl %eax, GlobalRp
	decl %ecx
	movl %ecx, %ebp
        xorl %eax, %eax	
	NEXT

L_rfetch:
        movl GlobalRp, %ecx
	movl $WSIZE, %eax
        addl %eax, %ecx
        movl (%ecx), %ecx
        movl %ecx, (%ebx)
        subl %eax, %ebx
        xorl %eax, %eax
	NEXT

L_tworfetch:
	movl GlobalRp, %ecx
	movl $WSIZE, %eax
	addl %eax, %ecx
	movl (%ecx), %edx
	addl %eax, %ecx
	movl (%ecx), %ecx
	movl %ecx, (%ebx)
	subl %eax, %ebx
	movl %edx, (%ebx)
	subl %eax, %ebx
	xorl %eax, %eax				
	NEXT

L_rpfetch:
	movl GlobalRp, %ecx
	movl $WSIZE, %eax
	addl %eax, %ecx
	movl %ecx, (%ebx)
	subl %eax, %ebx
	xorl %eax, %eax
	NEXT

L_spfetch:
	movl %ebx, %ecx
	movl $WSIZE, %eax
	addl %eax, %ecx
	movl %ecx, (%ebx)
	subl %eax, %ebx
	xorl %eax, %eax 
	NEXT

L_i:
        movl GlobalRp, %ecx
        movl 3*WSIZE(%ecx), %eax
        movl %eax, (%ebx)
	movl $WSIZE, %eax
        subl %eax, %ebx 
        xorl %eax, %eax
        NEXT

L_j:
        movl GlobalRp, %ecx
        movl 6*WSIZE(%ecx), %eax
        movl %eax, (%ebx)
	movl $WSIZE, %eax
        subl %eax, %ebx
        xorl %eax, %eax
        NEXT	

L_loop:
        movl GlobalRp, %ebx	
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %edx
	addl %eax, %ebx
	movl (%ebx), %ecx
	addl %eax, %ebx
        movl (%ebx), %eax
        incl %eax
	cmpl %ecx, %eax	
        jz L_unloop
loop1:	
        movl %eax, (%ebx)	# set loop counter to next value
	movl %edx, %ebp		# set instruction ptr to start of loop
	movl GlobalSp, %ebx
        xorl %eax, %eax
        NEXT

L_unloop:  
	UNLOOP
	movl GlobalSp, %ebx
	xorl %eax, %eax
        NEXT

L_plusloop:
	pushl %ebp
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ebp	# get loop increment 
	movl %ebx, GlobalSp
        movl GlobalRp, %ebx
	addl %eax, %ebx		# get ip and save in edx
	movl (%ebx), %edx
	addl %eax, %ebx
	movl (%ebx), %ecx	# get terminal count in ecx
	addl %eax, %ebx
	movl (%ebx), %eax	# get current loop index
	addl %ebp, %eax         # new loop index
	cmpl $0, %ebp           
	jl plusloop1            # loop inc < 0?

     # positive loop increment
	cmpl %ecx, %eax
	jl plusloop2            # is new loop index < ecx?
	addl %ebp, %ecx
	cmpl %ecx, %eax
	jge plusloop2            # is new index >= ecx + inc?
	popl %ebp
	movl GlobalSp, %ebx
	xorl %eax, %eax
	UNLOOP
	NEXT

plusloop1:       # negative loop increment
	decl %ecx
	cmpl %ecx, %eax
	jg plusloop2           # is new loop index > ecx-1?
	addl %ebp, %ecx
	cmpl %ecx, %eax
	jle plusloop2           # is new index <= ecx + inc - 1?
	popl %ebp
	movl GlobalSp, %ebx
	xorl %eax, %eax
	UNLOOP
	NEXT

plusloop2:
	popl %ebp
	movl %eax, (%ebx)
	movl %edx, %ebp
	movl GlobalSp, %ebx
	xorl %eax, %eax
	NEXT

L_count:
	movl WSIZE(%ebx), %ecx
	xorl %eax, %eax
	movb (%ecx), %al
	incl WSIZE(%ebx)
	movl %eax, (%ebx)
	movl $WSIZE, %eax
	subl %eax, %ebx
	xorl %eax, %eax
	NEXT

L_ival:
        movl %ebp, %ecx
        incl %ecx
        movl (%ecx), %eax
	addl $WSIZE-1, %ecx
	movl %ecx, %ebp
	movl %eax, (%ebx)
	DEC_DSP
	xorl %eax, %eax
	NEXT

L_addr:
	movl %ebp, %ecx
	incl %ecx
	movl (%ecx), %eax
	addl $WSIZE-1, %ecx
	movl %ecx, %ebp
	movl %eax, (%ebx)
	DEC_DSP
	xorl %eax, %eax
	NEXT

L_ptr:
	movl %ebp, %ecx
	incl %ecx
	movl (%ecx), %eax
	addl $WSIZE-1, %ecx
	movl %ecx, %ebp
	movl (%eax), %eax
	movl %eax, (%ebx)
	DEC_DSP
	xorl %eax, %eax
	NEXT

L_fval:
        movl %ebp, %ecx
        incl %ecx
        DEC_DSP
        movl (%ecx), %eax
	movl %eax, (%ebx)
	movl WSIZE(%ecx), %eax
	movl %eax, WSIZE(%ebx)
	DEC_DSP
	addl $2*WSIZE-1, %ecx
	movl %ecx, %ebp
	xorl %eax, %eax
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
        movl 2*WSIZE(%ebx), %ecx   # ecx = b
	movl WSIZE(%ebx), %eax     # eax = c
	subl %ecx, %eax            # eax = c - b
	INC_DSP     
	INC_DSP
	movl WSIZE(%ebx), %edx     # edx = a
        subl %ecx, %edx            # edx = a - b
	cmpl %eax, %edx
	movl $0, %eax
	setb %al
	negl %eax
	movl %eax, WSIZE(%ebx)
	xorl %eax, %eax      
        NEXT

L_deq:
	INC_DSP
	movl (%ebx), %edx
	INC_DSP
	movl (%ebx), %ecx
	INC_DSP
	movl %ebx, GlobalSp
	movl (%ebx), %eax
	subl %edx, %eax
	INC_DSP
	movl (%ebx), %edx
	subl %ecx, %edx
	orl %edx, %eax
	cmpl $0, %eax
	movl $0, %eax
	setz %al
	negl %eax
	movl %eax, (%ebx)
	movl GlobalSp, %ebx
	xorl %eax, %eax
	NEXT

L_dzeroeq:
	INC_DSP
	movl %ebx, %ecx
	movl (%ebx), %eax
	INC_DSP
	orl (%ebx), %eax
	cmpl $0, %eax
	movl $0, %eax
	setz %al
	negl %eax
	movl %eax, (%ebx)
	movl %ecx, %ebx
	xorl %eax, %eax
	NEXT

L_dzerolt:
	REL_ZERO setl
	INC_DSP
	movl (%ebx), %eax
	movl %eax, WSIZE(%ebx)
	xorl %eax, %eax
	NEXT

L_dlt:
	DLT
	NEXT

L_dult:	# b = (d1.hi u< d2.hi) OR ((d1.hi = d2.hi) AND (d1.lo u< d2.lo))
	movl $WSIZE, %ecx
	xorl %edx, %edx
	addl %ecx, %ebx
	movl (%ebx), %eax
	cmpl %eax, 2*WSIZE(%ebx)
	sete %dl
	setb %dh
	addl %ecx, %ebx
	movl (%ebx), %eax
	addl %ecx, %ebx
	movl %ebx, GlobalSp
	addl %ecx, %ebx
	cmpl %eax, (%ebx)
	setb %al
	andb %al, %dl
	orb  %dh, %dl
	xorl %eax, %eax
	movb %dl, %al
	negl %eax
	movl %eax, (%ebx)
	movl GlobalSp, %ebx
	xorl %eax, %eax
	NEXT

L_querydup:
	movl WSIZE(%ebx), %eax
	cmpl $0, %eax
	je L_querydupexit
	movl %eax, (%ebx)
	DEC_DSP
	xorl %eax, %eax
L_querydupexit:
	NEXT

L_swap:
	SWAP
        NEXT

L_over:
	OVER
        NEXT

L_rot:
	pushl %ebp
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl %ebx, %ebp
	addl %eax, %ebx
	addl %eax, %ebx
	movl (%ebx), %ecx
	movl (%ebp), %edx
	movl %ecx, (%ebp)
	addl %eax, %ebp
	movl (%ebp), %ecx
	movl %edx, (%ebp)
	movl %ecx, (%ebx)
	xorl %eax, %eax
	popl %ebp
	movl GlobalSp, %ebx
	NEXT

L_minusrot:
	movl WSIZE(%ebx), %eax
	movl %eax, (%ebx)
	INC_DSP
	movl WSIZE(%ebx), %eax
	movl %eax, (%ebx)
	INC_DSP
	movl WSIZE(%ebx), %eax
	movl %eax, (%ebx)
	movl -2*WSIZE(%ebx), %eax
	movl %eax, WSIZE(%ebx)
	movl GlobalSp, %ebx
	xorl %eax, %eax
	NEXT

L_nip:
        SWAP
        addl $WSIZE, %ebx
        NEXT

L_tuck:
        SWAP
        OVER
        NEXT

L_pick:                        
	movl %ebx, %ecx
	movl WSIZE(%ebx), %eax
	addl $2, %eax
	imul $WSIZE, %eax
	addl %eax, %ecx
	movl (%ecx), %eax
	movl %eax, WSIZE(%ebx)
	xorl %eax, %eax
	NEXT

L_roll:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl %ebx, GlobalSp
	movl (%ebx), %eax
	incl %eax
	pushl %eax
	pushl %ebx
	imul $WSIZE, %eax
	addl %eax, %ebx		# addr of item to roll
	movl (%ebx), %eax
	popl %ebx
	movl %eax, (%ebx)
	popl %eax		# number of cells to copy
	movl %eax, %ecx
	imul $WSIZE, %eax
	addl %eax, %ebx
	movl %ebx, %edx		# dest addr
	subl $WSIZE, %ebx	# src addr
rollloop:
	movl (%ebx), %eax
	sub $WSIZE, %ebx
	xchgl %ebx, %edx
	movl %eax, (%ebx)
	sub $WSIZE, %ebx
	xchgl %ebx, %edx
	loop rollloop

	movl GlobalSp, %ebx
	xorl %eax, %eax
	ret

L_depth:
	movl GlobalSp, %ebx
	movl BottomOfStack, %eax
	subl %ebx, %eax
	movl $WSIZE, (%ebx)
	movl $0, %edx
	idivl (%ebx)
	movl %eax, (%ebx)
	movl $WSIZE, %eax
	subl %eax, GlobalSp
	xorl %eax, %eax
        ret

L_2drop:
	FDROP
        NEXT

L_f2drop:
	FDROP
	FDROP
	NEXT

L_f2dup:
	FOVER
	FOVER
	NEXT

L_2dup:
	FDUP
        NEXT

L_2swap:
	FSWAP	
        NEXT

L_2over:
	FOVER
        NEXT

L_2rot:
	INC_DSP
	movl %ebx, %ecx
	movl (%ebx), %edx
	INC_DSP
	movl (%ebx), %eax
	INC_DSP
	xchgl %edx, (%ebx)
	INC_DSP
	xchgl %eax, (%ebx)
	INC_DSP
	xchgl %edx, (%ebx)
	INC_DSP
	xchgl %eax, (%ebx)
	movl %ecx, %ebx
	movl %edx, (%ebx)
	INC_DSP
	movl %eax, (%ebx)
	movl GlobalSp, %ebx
	xorl %eax, %eax
        NEXT

L_question:
	FETCH
	movl %ebx, GlobalSp
	call CPP_dot	
	ret

L_fetch:
	FETCH
	NEXT

L_store:
	STORE
	NEXT

L_afetch:
	FETCH
	NEXT

L_cfetch:
	xorl %eax, %eax
	movl %ebx, %edx
	addl $WSIZE, %edx
	movl (%edx), %ecx
	movb (%ecx), %al
	movl %eax, (%edx)
	xorl %eax, %eax
        NEXT

L_cstore:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx	# address to store
	addl %eax, %ebx
	movl (%ebx), %eax	# value to store
	movb %al, (%ecx)
	xorl %eax, %eax
	NEXT

L_wfetch:
	movl WSIZE(%ebx), %ecx
	movw (%ecx), %ax
	cwde
	movl %eax, WSIZE(%ebx)
	xorl %eax, %eax
        NEXT

L_wstore:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx
	addl %eax, %ebx
	movl (%ebx), %edx
	movw %dx, (%ecx)
	xorl %eax, %eax
        NEXT

L_sffetch:
	movl $WSIZE, %eax
	movl %ebx, %ecx
        addl %eax, %ecx
        movl (%ecx), %ecx
        flds (%ecx)
        fstpl (%ebx)
        subl %eax, %ebx
	xorl %eax, %eax
        NEXT

L_sfstore:
	movl $WSIZE, %eax
        addl %eax, %ebx
        addl %eax, %ebx
        fldl (%ebx)              # load the f number into NDP
	movl %ebx, %edx
        subl %eax, %ebx
        movl (%ebx), %ebx          # load the dest address
        fstps (%ebx)             # store as single precision float
	movl %edx, %ebx
        addl %eax, %ebx
	xorl %eax, %eax
        NEXT

L_dffetch:
	movl %ebx, %edx
	INC_DSP
	movl (%ebx), %ecx
	movl (%ecx), %eax
	movl %eax, (%edx)
	addl $WSIZE, %ecx
	movl (%ecx), %eax
	movl %eax, (%ebx)
	subl $WSIZE, %edx
	movl %edx, %ebx
	xorl %eax, %eax
	NEXT

L_dfstore:
	movl $WSIZE, %edx
	addl %edx, %ebx
	movl %ebx, %eax
	movl (%ebx), %ebx  # address to store
	addl %edx, %eax
	movl (%eax), %ecx
	movl %ecx, (%ebx)
	addl %edx, %eax
	addl %edx, %ebx
	movl (%eax), %ecx
	movl %ecx, (%ebx)
	movl %eax, %ebx
	xorl %eax, %eax
	NEXT

L_abs:
	_ABS
	NEXT

L_max:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %eax
	movl WSIZE(%ebx), %ecx
	cmpl %eax, %ecx
	jl max1
	movl %ecx, WSIZE(%ebx)
	jmp maxexit
max1:
	movl %eax, WSIZE(%ebx)
maxexit:
	xorl %eax, %eax
        NEXT

L_min:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %eax
	movl WSIZE(%ebx), %ecx
	cmpl %eax, %ecx
	jg min1
	movl %ecx, WSIZE(%ebx)
	jmp minexit
min1:
	movl %eax, WSIZE(%ebx)
minexit:
	xorl %eax, %eax
        NEXT

L_dmax:
	FOVER
	FOVER
	DLT
	INC_DSP
	movl (%ebx), %eax
	cmpl $0, %eax
	jne dmin1
	FDROP
	xorl %eax, %eax
	NEXT

L_dmin:
	FOVER
	FOVER
	DLT
	movl $WSIZE, %ecx
	addl %ecx, %ebx
	movl (%ebx), %eax
	cmpl $0, %eax
	je dmin1
	FDROP
	xorl %eax, %eax
	NEXT

dmin1:
	FSWAP
	FDROP
	xorl %eax, %eax
	NEXT

#  L_dtwostar and L_dtwodiv are valid for two's-complement systems 
L_dtwostar:
        INC_DSP
        movl WSIZE(%ebx), %eax
        movl %eax, %ecx
        sall $1, %eax
        movl %eax, WSIZE(%ebx)
        shrl $31, %ecx
        movl (%ebx), %eax
        sall $1, %eax
        orl  %ecx, %eax
        movl %eax, (%ebx)
        DEC_DSP
        xorl %eax, %eax
        NEXT

L_dtwodiv:
	INC_DSP
	movl (%ebx), %eax
        movl %eax, %ecx
        sarl $1, %eax
        movl %eax, (%ebx)
        shll $31, %ecx
        movl WSIZE(%ebx), %eax
        shrl $1, %eax
        orl %ecx, %eax
        movl %eax, WSIZE(%ebx)
        DEC_DSP
        xorl %eax, %eax
        NEXT

L_add:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %eax
	addl %eax, WSIZE(%ebx)
        xorl %eax, %eax
        NEXT

L_div:
	movl $WSIZE, %eax
        addl %eax, %ebx
        movl (%ebx), %eax
        cmpl $0, %eax
	jz   E_div_zero
	INC_DSP
        movl (%ebx), %eax
	cdq
        idivl -WSIZE(%ebx)
        movl %eax, (%ebx)
	DEC_DSP
	xorl %eax, %eax
divexit:
	movl %ebx, GlobalSp
        ret

L_mod:
	call L_div
	cmpl $0, %eax
	jnz  divexit
	movl %edx, WSIZE(%ebx)
	NEXT

L_slashmod:
	call L_div
	cmpl $0, %eax
	jnz  divexit
	movl %edx, (%ebx)
	DEC_DSP
	SWAP
	NEXT

L_starslash:
	STARSLASH	
	NEXT

L_starslashmod:
	STARSLASH
	movl %edx, (%ebx)
	DEC_DSP
	SWAP
	movl %ebx, GlobalSp
	ret

L_plusstore:
	movl $WSIZE, %edx
	addl %edx, %ebx
	movl (%ebx), %ecx
	movl (%ecx), %eax
	addl %edx, %ebx
	movl (%ebx), %edx
	addl %edx, %eax
	movl %eax, (%ecx)
	xorl %eax, %eax
	NEXT

L_dabs:
	movl GlobalSp, %ebx
	movl %ebx, %edx
	INC_DSP
	movl (%ebx), %ecx
	movl %ecx, %eax
	cmpl $0, %eax
	jl dabs_go
	movl %edx, GlobalSp
	xorl %eax, %eax
	ret
dabs_go:
	INC_DSP
	movl (%ebx), %eax
	clc
	subl $1, %eax
	notl %eax
	movl %eax, (%ebx)
	movl %ecx, %eax
	sbbl $0, %eax
	notl %eax
	movl %eax, -WSIZE(%ebx)
	movl %edx, GlobalSp
	xorl %eax, %eax
	ret

L_dnegate:
	movl GlobalSp, %ebx
	DNEGATE
#	NEXT
	movl %ebx, GlobalSp
	ret

L_dplus:
        movl GlobalSp, %ebx
	DPLUS
#	NEXT
        movl %ebx, GlobalSp
        ret

L_dminus:
	movl GlobalSp, %ebx
	DMINUS
	movl %ebx, GlobalSp
	ret

L_umstar:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx
	addl %eax, %ebx
	movl %ecx, %eax
	mull (%ebx)
	movl %eax, (%ebx)
	DEC_DSP
	movl %edx, (%ebx)
	DEC_DSP
	xorl %eax, %eax				
	NEXT

L_dsstar:
	# multiply signed double and signed to give triple length product
	movl $WSIZE, %ecx
	addl %ecx, %ebx
	movl (%ebx), %edx
	cmpl $0, %edx
	setl %al
	addl %ecx, %ebx
	movl (%ebx), %edx
	cmpl $0, %edx
	setl %ah
	xorb %ah, %al      # sign of result
	andl $1, %eax
	pushl %eax
	movl GlobalSp, %ebx
	_ABS
	INC_DSP
	movl %ebx, GlobalSp
	call L_dabs
	movl GlobalSp, %ebx
	DEC_DSP
	movl %ebx, GlobalSp
	call L_udmstar
	movl GlobalSp, %ebx
	popl %eax
	cmpl $0, %eax
	jne dsstar1
	NEXT
dsstar1:
	TNEG
	NEXT

L_umslashmod:
# Divide unsigned double length by unsigned single length to
# give unsigned single quotient and remainder. A "Divide overflow"
# error results if the quotient doesn't fit into a single word.
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx
	cmpl $0, %ecx
	jz   E_div_zero
	addl %eax, %ebx
	movl $0, %edx
	movl (%ebx), %eax
	divl %ecx
	cmpl $0, %eax
	jne E_div_overflow
	movl (%ebx), %edx
	INC_DSP
	movl (%ebx), %eax
	divl %ecx	
	movl %edx, (%ebx)
	DEC_DSP
	movl %eax, (%ebx)
	DEC_DSP
	xorl %eax, %eax		
	NEXT

L_mstar:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx
	addl %eax, %ebx
	movl %ecx, %eax
	imull (%ebx)
	movl %eax, (%ebx)
	DEC_DSP
	movl %edx, (%ebx)
	DEC_DSP
	xorl %eax, %eax		
	NEXT

L_mplus:
	STOD
	DPLUS
	NEXT

L_mslash:
	movl $WSIZE, %eax
	addl %eax, %ebx
        movl (%ebx), %ecx
	addl %eax, %ebx
        cmpl $0, %ecx
	je   E_div_zero
        movl (%ebx), %edx
	addl %eax, %ebx
	movl (%ebx), %eax
        idivl %ecx
        movl %eax, (%ebx)
	DEC_DSP
	xor %eax, %eax		
	NEXT

L_udmstar:
# Multiply unsigned double and unsigned single to give 
# the triple length product.
	movl GlobalSp, %ebx
	INC_DSP
	movl (%ebx), %ecx
	INC_DSP
	movl (%ebx), %eax
	mull %ecx
	movl %edx, -WSIZE(%ebx)
	movl %eax, (%ebx)
	INC_DSP
	movl %ecx, %eax
	mull (%ebx)
	movl %eax, (%ebx)
	DEC_DSP
	movl (%ebx), %eax
	DEC_DSP
	clc
	addl %edx, %eax
	movl %eax, WSIZE(%ebx)
	movl (%ebx), %eax
	adcl $0, %eax
	movl %eax, (%ebx)
	xor %eax, %eax
	ret

L_utsslashmod:
# Divide unsigned triple length by unsigned single length to
# give an unsigned triple quotient and single remainder.
	INC_DSP
	movl (%ebx), %ecx		# divisor in ecx
	cmpl $0, %ecx
	jz   E_div_zero
	INC_DSP
	movl (%ebx), %eax		# ut3
	movl $0, %edx
	divl %ecx			# ut3/u
	call utmslash1
	movl GlobalSp, %ebx
	movl WSIZE(%ebx), %eax
	movl %eax, (%ebx)
	INC_DSP
	movl WSIZE(%ebx), %eax
	movl %eax, (%ebx)
	INC_DSP	
	movl -17*WSIZE(%ebx), %eax       # r7
	movl %eax, (%ebx)
	subl $3*WSIZE, %ebx
	movl -5*WSIZE(%ebx), %eax        # q3
	movl %eax, (%ebx)
	DEC_DSP
	movl %ebx, GlobalSp
	xorl %eax, %eax	
	ret

L_tabs:
# Triple length absolute value (needed by L_stsslashrem, STS/REM)
        movl WSIZE(%ebx), %ecx
        movl %ecx, %eax
        cmpl $0, %eax
        jl tabs1
        xor %eax, %eax
        ret
tabs1:
        addl $3*WSIZE, %ebx
        movl (%ebx), %eax
        clc
        subl $1, %eax
        notl %eax
        movl %eax, (%ebx)
	DEC_DSP
	movl (%ebx), %eax
	sbbl $0, %eax
	notl %eax
	movl %eax, (%ebx)
        movl %ecx, %eax
        sbbl $0, %eax
        notl %eax
        movl %eax, -WSIZE(%ebx)
	subl $2*WSIZE, %ebx
	movl %ebx, GlobalSp
        xor %eax, %eax
        ret

L_stsslashrem:
# Divide signed triple length by signed single length to give a
# signed triple quotient and single remainder, according to the
# rule for symmetric division.
	INC_DSP
	movl (%ebx), %ecx		# divisor in ecx
	cmpl $0, %ecx
	jz   E_div_zero
	movl WSIZE(%ebx), %eax		# t3
	pushl %eax
	cmpl $0, %eax
	movl $0, %eax
	setl %al
	negl %eax
	movl %eax, %edx
	cmpl $0, %ecx
	movl $0, %eax
	setl %al
	negl %eax
	xorl %eax, %edx			# sign of quotient
	pushl %edx
	call L_tabs
	DEC_DSP
	_ABS
	movl %ebx, GlobalSp
	call L_utsslashmod
	popl %edx
	cmpl $0, %edx
	jz stsslashrem1
	TNEG
stsslashrem1:	
	popl %eax
	cmpl $0, %eax
	jz stsslashrem2
	movl GlobalSp, %ebx
	addl $4*WSIZE, %ebx
	negl (%ebx)	
stsslashrem2:
	xorl %eax, %eax
	ret

L_utmslash:
# Divide unsigned triple length by unsigned single to give 
# unsigned double quotient. A "Divide Overflow" error results
# if the quotient doesn't fit into a double word.
	movl GlobalSp, %ebx
	INC_DSP
	movl (%ebx), %ecx		# divisor in ecx
	cmpl $0, %ecx
	jz   E_div_zero
	INC_DSP
	movl (%ebx), %eax		# ut3
	movl $0, %edx
	divl %ecx			# ut3/u
	cmpl $0, %eax
	jnz  E_div_overflow
utmslash1:	 
	pushl %ebx			# keep local stack ptr
	movl GlobalSp, %ebx
	movl %eax, -4*WSIZE(%ebx)	# q3
	movl %edx, -5*WSIZE(%ebx)	# r3
	popl %ebx
	INC_DSP
	movl (%ebx), %eax		# ut2
	movl $0, %edx
	divl %ecx			# ut2/u
	pushl %ebx
	movl GlobalSp, %ebx
	movl %eax, -2*WSIZE(%ebx)	# q2
	movl %edx, -3*WSIZE(%ebx)	# r2
	popl %ebx
	INC_DSP
	movl (%ebx), %eax		# ut1
	movl $0, %edx
	divl %ecx			# ut1/u
	pushl %ebx
	movl GlobalSp, %ebx
	movl %eax, (%ebx)		# q1
	movl %edx, -WSIZE(%ebx)		# r1
	movl -5*WSIZE(%ebx), %edx	# r3 << 32
	movl $0, %eax
	divl %ecx			# (r3 << 32)/u
	movl %eax, -6*WSIZE(%ebx)	# q4
	movl %edx, -7*WSIZE(%ebx)	# r4
	movl -3*WSIZE(%ebx), %edx	# r2 << 32
	movl $0, %eax
	divl %ecx			# (r2 << 32)/u
	movl %eax, -8*WSIZE(%ebx)	# q5
	movl %edx, -9*WSIZE(%ebx)	# r5
	movl -7*WSIZE(%ebx), %edx	# r4 << 32
	movl $0, %eax
	divl %ecx			# (r4 << 32)/u
	movl %eax, -10*WSIZE(%ebx)	# q6
	movl %edx, -11*WSIZE(%ebx)	# r6
	movl $0, %edx
	movl -WSIZE(%ebx), %eax		# r1
	addl -9*WSIZE(%ebx), %eax	# r1 + r5
	jnc  utmslash2
	incl %edx
utmslash2:
	addl -11*WSIZE(%ebx), %eax	# r1 + r5 + r6
	jnc  utmslash3
	incl %edx
utmslash3:
	divl %ecx
	movl %eax, -12*WSIZE(%ebx)      # q7
	movl %edx, -13*WSIZE(%ebx)      # r7	
	movl $0, %edx
	addl -10*WSIZE(%ebx), %eax	# q7 + q6
	jnc  utmslash4
	incl %edx
utmslash4:	
	addl -8*WSIZE(%ebx), %eax	# q7 + q6 + q5
	jnc  utmslash5
	incl %edx
utmslash5:	
	addl (%ebx), %eax		# q7 + q6 + q5 + q1
	jnc  utmslash6
	incl %edx
utmslash6:	
	popl %ebx
	movl %eax, (%ebx)
	DEC_DSP
	pushl %ebx
	movl GlobalSp, %ebx
	movl -2*WSIZE(%ebx), %eax	# q2
	addl -6*WSIZE(%ebx), %eax	# q2 + q4
	addl %edx, %eax
	popl %ebx
	movl %eax, (%ebx)
	DEC_DSP
	movl %ebx, GlobalSp
	xorl %eax, %eax
	ret

L_mstarslash:
	movl GlobalSp, %ebx
	INC2_DSP
	movl (%ebx), %eax
	INC_DSP
	xorl (%ebx), %eax
	shrl $31, %eax
	pushl %eax	# keep sign of result -- negative is nonzero
	movl GlobalSp, %ebx
	INC_DSP
	movl %ebx, GlobalSp
	_ABS
	INC_DSP
	movl %ebx, GlobalSp
	call L_dabs
	movl GlobalSp, %ebx
	DEC_DSP
	movl %ebx, GlobalSp
	call L_udmstar
	movl GlobalSp, %ebx
	DEC_DSP
	movl %ebx, GlobalSp
	call L_utmslash
	movl GlobalSp, %ebx
	popl %eax
	cmpl $0, %eax
	jnz mstarslash_neg
	xor %eax, %eax
	ret
mstarslash_neg:
	DNEGATE
	movl %ebx, GlobalSp
	xorl %eax, %eax
	ret
	
L_fmslashmod:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl %ebx, GlobalSp
	movl (%ebx), %ecx
	cmpl $0, %ecx
	jz   E_div_zero
	addl %eax, %ebx
	movl (%ebx), %edx
	addl %eax, %ebx
	movl (%ebx), %eax
	idivl %ecx
	movl %edx, (%ebx)
	DEC_DSP
	movl %eax, (%ebx)
	cmpl $0, %ecx
	jg fmslashmod2
	cmpl $0, %edx
	jg fmslashmod3
	movl GlobalSp, %ebx
	xor %eax, %eax
	NEXT
fmslashmod2:		
	cmpl $0, %edx
	jge fmslashmodexit
fmslashmod3:	
	decl %eax		# floor the result
	movl %eax, (%ebx)
	INC_DSP
	addl %ecx, (%ebx)
fmslashmodexit:
	movl GlobalSp, %ebx
	xorl %eax, %eax
	NEXT

L_smslashrem:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl %ebx, GlobalSp
	movl (%ebx), %ecx
	cmpl $0, %ecx
	jz   E_div_zero
	addl %eax, %ebx
	movl (%ebx), %edx
	addl %eax, %ebx
	movl (%ebx), %eax
	idivl %ecx
	movl %edx, (%ebx)
	DEC_DSP
	movl %eax, (%ebx)
	movl GlobalSp, %ebx
	xorl %eax, %eax		
	NEXT

L_stof:
	movl $WSIZE, %eax
	movl %ebx, %ecx
        addl %eax, %ecx
        fildl (%ecx)
        fstpl (%ebx)
        subl %eax, %ebx
	xorl %eax, %eax
        NEXT

L_dtof:
	movl $WSIZE, %eax
	movl %ebx, %ecx
	addl %eax, %ecx
	movl (%ecx), %eax
	xchgl WSIZE(%ecx), %eax
	movl %eax, (%ecx)
        fildq (%ecx)
        fstpl (%ecx)
	xorl %eax, %eax	
	NEXT
	
L_froundtos:
	movl $WSIZE, %eax
        addl %eax, %ebx
	movl %ebx, %ecx
        fldl (%ecx)
        addl %eax, %ecx
        fistpl (%ecx)
	xorl %eax, %eax
        NEXT

L_ftrunctos:
	movl $WSIZE, %eax
	addl %eax, %ebx
	fldl (%ebx)
	fnstcw (%ebx)
	movl (%ebx), %ecx	# save NDP control word		
	movl %ecx, %edx	
	movb $12, %dh
	movl %edx, (%ebx)
	fldcw (%ebx)
	addl %eax, %ebx	
	fistpl (%ebx)
	subl %eax, %ebx
	movl %ecx, (%ebx)
	fldcw (%ebx)		# restore NDP control word
	xorl %eax, %eax	
	NEXT
	
L_ftod:
	movl $WSIZE, %eax
	addl %eax, %ebx
	fldl (%ebx)
	subl %eax, %ebx
	fnstcw (%ebx)
	movl (%ebx), %ecx	# save NDP control word	
	movl %ecx, %edx
	movb $12, %dh		
	movl %edx, (%ebx)
	fldcw (%ebx)
	addl %eax, %ebx	
	fistpq (%ebx)
	subl %eax, %ebx
	movl %ecx, (%ebx)
	fldcw (%ebx)		# restore NDP control word
	addl %eax, %ebx 
	movl (%ebx), %eax
	xchgl WSIZE(%ebx), %eax
	movl %eax, (%ebx)
	movl GlobalSp, %ebx
	xorl %eax, %eax	
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
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl (%ebx), %ecx
	movl %ebx, %edx
	addl %eax, %ebx
	movl (%ebx), %eax
	shll $1, %eax
	orl %ecx, %eax
	movl $0, %eax
	setz %al
	negl %eax
	movl %eax, (%ebx)
	movl %edx, %ebx
	xorl %eax, %eax
	NEXT

L_fzerolt:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl %ebx, %ecx 
	fldl (%ebx)
	add %eax, %ebx
	fldz
	fcompp	
	fnstsw %ax
	andb $69, %ah
	movl $0, %eax
	setz %al
	negl %eax
	movl %eax, (%ebx)
	movl %ecx, %ebx
	xorl %eax, %eax
	NEXT

L_fzerogt:
	movl $WSIZE, %eax
	addl %eax, %ebx
	movl %ebx, %ecx
	fldz
	fldl (%ebx)
	addl %eax, %ebx
	fucompp	
	fnstsw %ax
	sahf 
	movl $0, %eax
	seta %al
	negl %eax
	movl %eax, (%ebx)
	movl %ecx, %ebx
	xorl %eax, %eax
	NEXT

L_fsincos:
	fldl WSIZE(%ebx)
	fsincos
	fstpl -WSIZE(%ebx)
	fstpl WSIZE(%ebx)
	subl $2*WSIZE, %ebx	
	NEXT

