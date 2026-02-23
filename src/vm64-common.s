// vm64-common.s
//
// Common declarations and data for kForth 64-bit Virtual Machine
//
// Copyright (c) 1998--2026 Krishna Myneni,
//   <krishna.myneni@ccreweb.org>
//
// This software is provided under the terms of the GNU
// Affero General Public License (AGPL), v3.0 or later.
//

.equ WSIZE,	8
.equ TRUE,     -1
.equ FALSE,     0
.equ OP_ADDR,	65
.equ OP_FVAL,	70
.equ OP_IVAL,	73
.equ OP_RET,	238
.equ SIGN_MASK,	0x80000000
.equ MAX_SHIFT_COUNT, WSIZE*8-1
	
// Error Codes must be same as those in VMerrors.h

.equ E_DIV_ZERO,          -10
.equ E_ARG_TYPE_MISMATCH, -12
.equ E_QUIT,              -56
.equ E_NOT_ADDR,          -256
.equ E_RET_STK_CORRUPT,   -258
.equ E_BAD_OPCODE,        -259
.equ E_DIV_OVERFLOW,      -270

.data
NDPcw: .quad 0
FCONST_180: .double 180.

// Jump table is read-only
.section        .rodata
.align WSIZE
JumpTable: .quad L_false, L_true, L_cells, L_cellplus # 0 -- 3
           .quad L_dfloats, L_dfloatplus, CPP_case, CPP_endcase  # 4 -- 7
           .quad CPP_of, CPP_endof, C_open, C_lseek     # 8 -- 11
           .quad C_close, C_read, C_write, C_ioctl # 12 -- 15
           .quad L_usleep, L_ms, C_msfetch, C_syscall  # 16 -- 19
           .quad L_fill, L_cmove, L_cmovefrom, CPP_dotparen # 20 -- 23
           .quad C_bracketsharp, L_execute_bc, C_fsync, C_sharpbracket  # 24 -- 27
           .quad C_sharps, CPP_squote, CPP_cr, L_bl    # 28 -- 31
           .quad CPP_spaces, L_store, CPP_cquote, C_sharp # 32 -- 35
           .quad C_sign, L_mod, L_and, CPP_tick    # 36 -- 39
           .quad CPP_lparen, C_hold, L_mul, L_add  # 40 -- 43
           .quad L_nop, L_sub, CPP_dot, L_div  # 44 -- 47
           .quad L_dabs, L_dnegate, L_umstar, L_umslashmod   # 48 -- 51
           .quad L_mstar, L_mplus, L_mslash, L_mstarslash # 52 -- 55
           .quad L_fmslashmod, L_smslashrem, CPP_colon, CPP_semicolon # 56 -- 59
           .quad L_lt, L_eq, L_gt, L_question      # 60 -- 63
           .quad L_fetch, L_addr, L_base, L_call   # 64 -- 67
           .quad L_definition, L_erase, L_fval, L_calladdr # 68 -- 71
           .quad CPP_tobody, L_ival, CPP_evaluate, C_key   # 72 -- 75
           .quad L_lshift, L_slashmod, L_ptr, CPP_dotr     # 76 -- 79
           .quad CPP_ddot, C_keyquery, L_rshift, CPP_dots  # 80 -- 83
           .quad C_accept, CPP_char, CPP_bracketchar, C_word  # 84 -- 87
           .quad L_starslash, L_starslashmod, CPP_udotr, CPP_lbracket  # 88 -- 91
           .quad L_backslash, CPP_rbracket, L_xor, CPP_literal  # 92 -- 95
           .quad CPP_queryallot, CPP_allot, L_binary, L_count # 96 -- 99
           .quad L_decimal, CPP_emit, CPP_fdot, CPP_cold # 100 -- 103
           .quad L_hex, L_i, L_j, CPP_brackettick         # 104 -- 107
           .quad CPP_fvariable, L_2store, CPP_find, CPP_constant # 108 -- 111
           .quad CPP_immediate, CPP_fconstant, CPP_create, CPP_dotquote  # 112 -- 115
           .quad CPP_type, CPP_udot, CPP_variable, CPP_words # 116 -- 119
           .quad CPP_does, L_2val, L_2fetch, C_search # 120 -- 123
           .quad L_or, C_compare, L_not, L_move    # 124 -- 127
           .quad L_fsin, L_fcos, L_ftan, L_fasin   # 128 -- 131
           .quad L_facos, L_fatan, L_fexp, L_fln   # 132 -- 135
           .quad L_flog, L_fatan2, L_ftrunc, L_ftrunctos    # 136 -- 139
           .quad C_fmin, C_fmax, L_floor, L_fround # 140 -- 143
           .quad L_dlt, L_dzeroeq, L_deq, L_twopush_r  # 144 -- 147
           .quad L_twopop_r, L_tworfetch, L_stod, L_stof # 148 -- 151
           .quad L_dtof, L_froundtos, L_ftod, L_degtorad  # 152 -- 155
           .quad L_radtodeg, L_dplus, L_dminus, L_dult   # 156 -- 159
           .quad L_inc, L_dec, L_abs, L_neg        # 160 -- 163
           .quad L_min, L_max, L_twostar, L_twodiv # 164 -- 167
           .quad L_twoplus, L_twominus, L_cfetch, L_cstore  # 168 -- 171
           .quad L_swfetch, L_wstore, L_dffetch, L_dfstore  # 172 -- 175
           .quad L_sffetch, L_sfstore, L_spfetch, L_plusstore # 176 -- 179
           .quad L_fadd, L_fsub, L_fmul, L_fdiv    # 180 -- 183
           .quad L_fabs, L_fneg, L_fpow, L_fsqrt   # 184 -- 187
           .quad CPP_spstore, CPP_rpstore, L_feq, L_fne  # 188 -- 191
           .quad L_flt, L_fgt, L_fle, L_fge        # 192 -- 195
           .quad L_fzeroeq, L_fzerolt, L_fzerogt, L_nop # 196 -- 199
           .quad L_drop, L_dup, L_swap, L_over     # 200 -- 203
           .quad L_rot, L_minusrot, L_nip, L_tuck  # 204 -- 207
           .quad L_pick, L_roll, L_2drop, L_2dup   # 208 -- 211
           .quad L_2swap, L_2over, L_2rot, L_depth # 212 -- 215
           .quad L_querydup, CPP_if, CPP_else, CPP_then # 216 -- 219
           .quad L_push_r, L_pop_r, L_puship, L_rfetch # 220 -- 223
           .quad L_rpfetch, L_afetch, CPP_do, CPP_leave # 224 -- 227
           .quad CPP_querydo, CPP_abortquote, L_jz, L_jnz  # 228 -- 231
           .quad L_jmp, L_rtloop, L_rtplusloop, L_rtunloop # 232 -- 235
           .quad L_execute, CPP_recurse, L_ret, L_abort  # 236 -- 239
           .quad L_quit, L_ge, L_le, L_ne          # 240 -- 243
           .quad L_zeroeq, L_zerone, L_zerolt, L_zerogt # 244 -- 247
           .quad L_ult, L_ugt, CPP_begin, CPP_while    # 248 -- 251
           .quad CPP_repeat, CPP_until, CPP_again, CPP_bye  # 252 -- 255
           .quad L_utmslash, L_utsslashmod, L_stsslashrem, L_udmstar   # 256 -- 259
           .quad CPP_included, CPP_include, CPP_source, CPP_refill # 260--263
           .quad CPP_state, CPP_allocate, CPP_free, CPP_resize  # 264--267
           .quad L_cputest, L_dsstar, CPP_compilecomma, CPP_compilename    # 268--271
           .quad CPP_postpone, CPP_nondeferred, CPP_forget, C_forth_signal # 272--275
           .quad C_raise, C_setitimer, C_getitimer, C_us2fetch  # 276--279
           .quad C_tofloat, L_fsincos, L_facosh, L_fasinh # 280--283
           .quad L_fatanh, L_fcosh, L_fsinh, L_ftanh   # 284--287
           .quad L_falog, L_dzerolt, L_dmax, L_dmin    # 288--291
           .quad L_dtwostar, L_dtwodiv, CPP_uddot, L_within  # 292--295
           .quad CPP_twoliteral, C_tonumber, C_numberquery, CPP_sliteral      # 296--299
           .quad CPP_fliteral, CPP_twovariable, CPP_twoconstant, CPP_synonym  # 300--303
           .quad CPP_tofile, CPP_console, CPP_loop, CPP_plusloop  # 304--307
           .quad CPP_unloop, CPP_noname, L_nop, L_blank           # 308--311
           .quad L_slashstring, C_trailing, C_parse, C_parsename  # 312--315
           .quad L_nop, L_nop, L_nop, L_nop            # 316--319
           .quad C_dlopen, C_dlerror, C_dlsym, C_dlclose # 320--323
           .quad C_usec, CPP_alias, C_system, C_chdir    # 324--327
           .quad C_timeanddate, CPP_interpret, CPP_wordlist, CPP_forthwordlist # 328--331
           .quad CPP_getcurrent, CPP_setcurrent, CPP_getorder, CPP_setorder  # 332--335
           .quad CPP_searchwordlist, CPP_definitions, CPP_vocabulary, L_nop  # 336--339
           .quad CPP_only, CPP_also, CPP_order, CPP_previous                 # 340--343
           .quad CPP_forth, CPP_assembler, CPP_traverse_wordlist, CPP_name_to_string # 344--347
           .quad CPP_name_to_interpret, CPP_name_to_compile, CPP_defined, CPP_undefined  # 348--351
           .quad L_nop, L_nop, L_nop, CPP_myname       # 352--355
           .quad L_nop, L_nop, C_used, L_vmthrow       # 356--359
           .quad L_precision, L_setprecision, L_nop, CPP_fsdot   # 360--363
           .quad L_nop, L_fpick, L_fexpm1, L_flnp1	    # 364--367
           .quad CPP_uddotr, CPP_ddotr, L_f2drop, L_f2dup   # 368--371
           .quad L_nop, L_nop, L_nop, L_nop                 # 372--375
           .quad L_nop, L_nop, L_nop, L_nop                 # 376--379
           .quad L_nop, L_fdepth, L_fpfetch, CPP_fpstore    # 380--383
           .quad CPP_fdots, L_fdup, L_fdrop, L_fswap        # 384--387
           .quad L_frot, L_fover, L_nop, L_nop              # 388--391
           .quad L_nop, L_nop, L_nop, L_nop                 # 392--395
           .quad CPP_find_name_in, CPP_find_name, L_nop, L_nop  # 396--399
           .quad L_bool_not, L_bool_and, L_bool_or, L_bool_xor  # 400--403 
           .quad L_boolean_query, L_uwfetch, L_ulfetch, L_slfetch  # 404--407
           .quad L_lstore, L_nop, L_nop, L_nop              # 408--411
           .quad L_nop, L_nop, L_nop, L_nop                 # 412--415
           .quad L_nop, L_udivmod, L_uddivmod, L_nop        # 416--419
           .quad L_sfloats, L_sfloatplus, L_floats, L_floatplus # 420--423
           .quad L_fplusstore, L_pi, L_fsquare, L_starplus  # 424--427
           .quad L_nop, L_nop, L_fsl_mat_addr, CPP_rec_name # 428--431
	   .quad C_rec_number, C_rec_float, L_nop, L_nop    # 432--435
.text
	.align WSIZE
.global JumpTable
.global L_initfpu, L_depth, L_fdepth, L_quit, L_abort
.global L_ret, L_dabs, L_dplus, L_dminus, L_dnegate
.global L_mstarslash, L_udmstar, L_uddivmod, L_utmslash

.global __floattidf, __fixdfti

// Regs: rbx
// In: none
// Out: rbx = DSP
.macro LDSP              # load global stack ptr into rbx
        movq GlobalSp(%rip), %rbx
.endm

// Regs: rbx
// In/Out: rbx = DSP
.macro STSP
	movq %rbx, GlobalSp(%rip)
.endm

// Regs: rax, rbx
// In: none 
// Out: rax = Fpsize, rbx = FSP
.macro LDFSP
	movq GlobalFp(%rip), %rbx
        movq FpSize(%rip), %rax
.endm

// Regs: rbx
// In/Out: rbx = FSP
.macro STFSP
	movq %rbx, GlobalFp(%rip)
.endm

// Regs: rbx
// In/Out: rbx = DSP
.macro INC_DSP
	addq $WSIZE, %rbx
.endm

// Regs: rbx
// In/Out: rbx = DSP
.macro DEC_DSP            # decrement DSP by 1 cell
	subq $WSIZE, %rbx
.endm

// Regs: rbx
// In/Out: rbx = DSP
.macro INC2_DSP           # increment DSP by 2 cells
	addq $2*WSIZE, %rbx
.endm

// Regs: rbx
// In/Out: rbx = FSP
.macro INC_FSP
	addq FpSize(%rip), %rbx
.endm

// Regs: rbx
// In/Out: rbx = FSP
.macro DEC_FSP
	subq FpSize(%rip), %rbx
.endm

// Regs: none
// In/Out: none
.macro INC_DTSP
  .ifndef __FAST__
       incq GlobalTp(%rip)
  .endif
.endm

// Regs: none
// In/Out: none
.macro DEC_DTSP
  .ifndef __FAST__
	decq GlobalTp(%rip)
  .endif
.endm

// Regs: none
// In/Out: none
.macro INC2_DTSP
  .ifndef __FAST__
	addq $2, GlobalTp(%rip)
  .endif
.endm

// Regs: rdx
// In/Out: none
.macro STD_IVAL
  .ifndef __FAST__
	movq GlobalTp(%rip), %rdx
	movb $OP_IVAL, (%rdx)
	decq GlobalTp(%rip)
  .endif
.endm

// Regs: rdx
// In/Out: none
.macro STD_ADDR
  .ifndef __FAST__
	movq GlobalTp(%rip), %rdx
	movb $OP_ADDR, (%rdx)
	decq GlobalTp(%rip)
  .endif
.endm

// Regs: none
// In/Out: none
.macro UNLOOP
	addq $3*WSIZE, GlobalRp(%rip)  # terminal count reached, discard top 3 items
  .ifndef __FAST__
	addq $3, GlobalRtp(%rip)
  .endif
.endm

// Regs: rax, rbx, rcx, rbp
// In: rax = 0; rbx = DSP, rbp = Ip
// Out: rax = 0, rbx = DSP, rcx = next word address, rbp = Ip;
.macro NEXT
	inc %rbp		 # increment the Forth instruction ptr
	movq %rbp, GlobalIp(%rip)
  .ifdef  __FAST__
	STSP
  .endif
	movb (%rbp), %al         # get the opcode
	leaq JumpTable(%rip), %rcx
	movq (%rcx,%rax,WSIZE), %rcx	# machine code address of word
	xor %rax, %rax	
	jmp *%rcx		# jump to next word
.endm

// Regs: rbx
// In/Out: rbx = DSP
.macro DROP                     # increment DSP by 1 cell
	INC_DSP
#   .ifndef __FAST__
#	STSP
	INC_DTSP
#   .endif
.endm

// Regs: rax, rbx, rcx
// In/Out: rbx = DSP
.macro DUP
	movq WSIZE(%rbx), %rcx
	movq %rcx, (%rbx)
	DEC_DSP
  .ifndef __FAST__
#	STSP
	movq GlobalTp(%rip), %rcx
	movb 1(%rcx), %al
	movb %al, (%rcx)
	xor %rax, %rax
  .endif
	DEC_DTSP
.endm

// Regs: none
// In/Out: rbx = DSP
.macro _NOT
	notq WSIZE(%rbx)
.endm

// use algorithm from DNW's vm-osxppc.s
// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro _ABS
        movq WSIZE(%rbx), %rcx
        xor %rax, %rax
        cmp %rax, %rcx
        setl %al
        neg %rax
        mov %rax, %rdx
        xor %rcx, %rdx
        sub %rax, %rdx
        movq %rdx, WSIZE(%rbx)
        xor %rax, %rax
.endm

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro STOD
	movq $WSIZE, %rcx
	movq WSIZE(%rbx), %rax
	cqo
	movq %rdx, (%rbx)
	sub %rcx, %rbx
	STD_IVAL
	xor %rax, %rax
.endm

// Regs: rax, rbx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro DPLUS
	INC2_DSP
	movq (%rbx), %rax
	clc
	addq 2*WSIZE(%rbx), %rax
	movq %rax, 2*WSIZE(%rbx)
	movq WSIZE(%rbx), %rax
	adcq -WSIZE(%rbx), %rax
	movq %rax, WSIZE(%rbx)
	INC2_DTSP
	xor %rax, %rax
.endm

// Regs: rax, rbx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro DMINUS
	INC2_DSP
	movq 2*WSIZE(%rbx), %rax
	clc
	subq (%rbx), %rax
	movq %rax, 2*WSIZE(%rbx)
	movq WSIZE(%rbx), %rax
	sbbq -WSIZE(%rbx), %rax
	movq %rax, WSIZE(%rbx)
	INC2_DTSP
	xor %rax, %rax
.endm

// signed single division
// Regs: rax, rbx, rcx, rdx
// In: rbx = TOS
// Out: rax = quot, rdx = rem, rbx = TOS
.macro DIV
       mov (%rbx), %rcx
       cmpq $0, %rcx
       jz E_div_zero
       INC_DSP
       mov (%rbx), %rax
       cqo
       idivq %rcx
.endm

// unsigned single division
// Regs: rax, rbx, rcx, rdx
// In: rbx = TOS
// Out: rax = quot, rdx = rem, rbx = TOS
.macro UDIV
       mov (%rbx), %rcx
       cmpq $0, %rcx
       jz E_div_zero
       INC_DSP
       mov (%rbx), %rax
       movq $0, %rdx
       divq %rcx
.endm
       
// Regs: rax, rbx, rcx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP                      
.macro DNEGATE
        INC_DSP
        mov %rbx, %rcx
        INC_DSP
        mov (%rbx), %rax
        not %rax
        clc
        addq $1, %rax
        mov %rax, (%rbx)
        mov %rcx, %rbx
        mov (%rbx), %rax
        not %rax
        adcq $0, %rax
        mov %rax, (%rbx)
        DEC_DSP
        xor %rax, %rax
.endm

// Regs: rax, rbx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP, rdx = remainder, TOS = quotient      
.macro STARSLASH
        cmpq $0, WSIZE(%rbx)
        jz E_div_zero
        INC2_DSP
        movq WSIZE(%rbx), %rax
        imulq (%rbx)
        idivq -WSIZE(%rbx)
        mov %rax, WSIZE(%rbx)
        INC2_DTSP
        xor %rax, %rax
.endm

// Regs: rax, rbx, rcx, rdx
// In: rbx = DSP
// Out: rax = 0, rbx = DSP
.macro TNEG
        mov  %rbx, %rdi
        movq $WSIZE, %rax
        add  %rax, %rbx
        movq (%rbx), %rdx
        add  %rax, %rbx
        movq (%rbx), %rcx
        add  %rax, %rbx
        movq (%rbx), %rax
        not  %rax
        not  %rcx
        not  %rdx
        clc
        addq $1, %rax
        adcq $0, %rcx
        adcq $0, %rdx
        movq %rax, (%rbx)
        movq $WSIZE, %rax
        sub  %rax, %rbx
        movq %rcx, (%rbx)
        sub  %rax, %rbx
        movq %rdx, (%rbx)
        mov  %rdi, %rbx
        xor  %rax, %rax
.endm

// Regs: rax, rbx, rdi, xmm0
// In: rbx = DSP
// Out: eax = 0, rbx = DSP
.macro DOUBLE_FUNC func
        push %rbx
        LDFSP   # rbx = fpsp, rax = fpsize
        add %rax, %rbx 
        movq (%rbx), %xmm0
        call \func
        movq %xmm0, (%rbx)
        pop %rbx
        xor %rax, %rax
.endm

// Error jumps
E_not_addr:
	mov $E_NOT_ADDR, %rax
	ret

E_ret_stk_corrupt:
	mov $E_RET_STK_CORRUPT, %rax
	ret

E_div_zero:
	mov $E_DIV_ZERO, %rax
	ret

E_div_overflow:
	mov $E_DIV_OVERFLOW, %rax
	ret

E_arg_type_mismatch:
        mov $E_ARG_TYPE_MISMATCH, %eax
        ret

L_cputest:
	ret

# set kForth's default fpu settings
L_initfpu:
	LDSP
	fnstcw NDPcw(%rip)     # save the NDP control word
	mov NDPcw(%rip), %rcx
	andb $240, %ch         # mask the high byte
	orb  $2,  %ch          # set double precision, round near
	mov %rcx, (%rbx)
	fldcw (%rbx)
	ret

L_nop:
	mov $E_BAD_OPCODE, %rax   # unknown operation
	ret

L_quit:
	mov BottomOfReturnStack(%rip), %rax	# clear the return stacks
	movq %rax, GlobalRp(%rip)
	movq %rax, vmEntryRp(%rip)
  .ifndef __FAST__
	movq BottomOfReturnTypeStack(%rip), %rax
	movq %rax, GlobalRtp(%rip)
  .endif
	movq $E_QUIT, %rax	# exit the virtual machine
	ret

L_abort:
	movq BottomOfStack(%rip), %rax
	movq %rax, GlobalSp(%rip)
        movq BottomOfFpStack(%rip), %rax
        movq %rax, GlobalFp(%rip)
  .ifndef __FAST__
	movq BottomOfTypeStack(%rip), %rax
	movq %rax, GlobalTp(%rip)
  .endif
	jmp L_quit

L_jnz:                          # not implemented
        ret

L_jmp:
	mov %rbp, %rcx
	inc %rcx
	mov (%rcx), %rax       # get the relative jump count
	add %rax, %rcx
	sub $2, %rcx
	mov %rcx, %rbp		# set instruction ptr
	xor %rax, %rax
	NEXT

L_calladdr:
	inc %rbp
	mov %rbp, %rcx # address to execute (intrinsic Forth word or other)
	add $WSIZE-1, %rbp
	mov %rbp, GlobalIp(%rip)
        jmpq *(%rcx)

L_binary:
	lea Base(%rip), %rcx
	movq $2, (%rcx)
	NEXT
L_decimal:	
	lea Base(%rip), %rcx
	movq $10, (%rcx)
	NEXT
L_hex:	
	lea Base(%rip), %rcx
	movq $16, (%rcx)
	NEXT

L_cellplus:
  .ifndef __FAST__
	LDSP
  .endif
	addq $WSIZE, WSIZE(%rbx)
	NEXT

L_cells:
  .ifndef __FAST__
	LDSP
  .endif
	salq $3, WSIZE(%rbx)
	NEXT

L_sfloatplus:
  .ifndef __FAST__
        LDSP
  .endif
        addq $4, WSIZE(%rbx)
        NEXT

L_sfloats:
  .ifndef __FAST__
        LDSP
  .endif
        salq $2, WSIZE(%rbx)
        NEXT

L_dfloatplus:
  .ifndef __FAST__	
	LDSP
  .endif
	addq $8, WSIZE(%rbx)
	NEXT				

L_dfloats:
  .ifndef __FAST__	
	LDSP
  .endif
	salq $3, WSIZE(%rbx)
	NEXT

L_floatplus:
  .ifndef __FAST__
        LDSP
  .endif
        movq FpSize(%rip), %rax
        addq %rax, WSIZE(%rbx)
        xor %rax, %rax
        NEXT

L_floats:
  .ifndef __FAST__
        LDSP
  .endif
        movq FpSize(%rip), %rax
        mulq WSIZE(%rbx)
        movq %rax, WSIZE(%rbx)
        xor %rax, %rax
        NEXT

L_inc:
  .ifndef __FAST__
	LDSP
  .endif
	incq WSIZE(%rbx)
	NEXT

L_dec:
  .ifndef __FAST__
	LDSP
  .endif
	decq WSIZE(%rbx)
	NEXT

L_neg:
  .ifndef __FAST__
	LDSP
  .endif
	negq WSIZE(%rbx)
	NEXT

L_twoplus:
  .ifndef __FAST__
	LDSP
  .endif
	incq WSIZE(%rbx)
	incq WSIZE(%rbx)
	NEXT

L_twominus:
  .ifndef __FAST__
	LDSP
  .endif
	decq WSIZE(%rbx)
	decq WSIZE(%rbx)
	NEXT

L_twostar:
  .ifndef __FAST__
	LDSP
  .endif
	salq $1, WSIZE(%rbx)
	NEXT

L_twodiv:
  .ifndef __FAST__
	LDSP
  .endif
	sarq $1, WSIZE(%rbx)
	NEXT

L_fabs:
        mov %rbx, %rdi
	LDFSP
        add %rax, %rbx
        fldl (%rbx)
	fabs
	fstpl (%rbx)
        mov %rdi, %rbx
        xor %rax, %rax
	NEXT

L_fneg:
        mov %rbx, %rdi
	LDFSP
        add %rax, %rbx
	fldl (%rbx)
	fchs
	fstpl (%rbx)
        mov %rdi, %rbx
        xor %rax, %rax
	NEXT

L_fsqrt:
        mov %rbx, %rdi
	LDFSP
        add %rax, %rbx
	fldl (%rbx)
	fsqrt
	fstpl (%rbx)
        mov %rdi, %rbx
        xor %rax, %rax
	NEXT

L_fsquare:
        mov %rbx, %rdi
        LDFSP
        add %rax, %rbx
        fldl (%rbx)
        fmul %st
	fstpl (%rbx)
        mov %rdi, %rbx
	xor %rax, %rax
	NEXT

L_pi:
        mov %rbx, %rdi
	LDFSP
        fldpi
        fstpl (%rbx)
        sub %rax, %rbx
        STFSP
        mov %rdi, %rbx
        xor %rax, %rax
        NEXT

L_degtorad:
        mov %rbx, %rdi
	LDFSP
	fldl FCONST_180(%rip)
	add %rax, %rbx
	fldl (%rbx)
	fdivp %st, %st(1)
	fldpi
	fmulp %st, %st(1)
	fstpl (%rbx)
        mov %rdi, %rbx
        xor %rax, %rax
	NEXT

L_radtodeg:
        mov %rbx, %rdi
	LDFSP
	add %rax, %rbx
	fldl (%rbx)
	fldpi
	fxch
	fdivp %st, %st(1)
	fldl FCONST_180(%rip)
	fmulp %st, %st(1)
	fstpl (%rbx)
        mov %rdi, %rbx
        xor %rax, %rax
	NEXT

// For native x86 FPU fcos and fsin instructions, use FSINCOS
L_fcos:
        DOUBLE_FUNC cos
        NEXT

L_fsin:
        DOUBLE_FUNC sin
        NEXT

L_ftan:
        DOUBLE_FUNC tan
        NEXT

L_facos:
        DOUBLE_FUNC acos
        NEXT

L_fasin:
        DOUBLE_FUNC asin
        NEXT

L_fatan:
        DOUBLE_FUNC atan
        NEXT

L_fsinh:
        DOUBLE_FUNC sinh
        NEXT

L_fcosh:
        DOUBLE_FUNC cosh
        NEXT

L_ftanh:
        DOUBLE_FUNC tanh
        NEXT

L_fasinh:
        DOUBLE_FUNC asinh
        NEXT

L_facosh:
        DOUBLE_FUNC acosh
        NEXT

L_fatanh:
        DOUBLE_FUNC atanh
        NEXT

L_fexp:
        DOUBLE_FUNC exp
        NEXT

L_fexpm1:
        DOUBLE_FUNC expm1
        NEXT

L_fln:
        DOUBLE_FUNC log
        NEXT

L_flnp1:
        DOUBLE_FUNC log1p
        NEXT

L_flog:
        DOUBLE_FUNC log10
        NEXT

L_falog:
        DOUBLE_FUNC exp10
        NEXT

L_floor:
        DOUBLE_FUNC floor
        NEXT

L_fatan2:
        mov %rbx, %rdi
	LDFSP
	add %rax, %rbx
	fldl (%rbx)
        add %rax, %rbx
	fldl (%rbx)
	fxch
	fpatan
	fstpl (%rbx)
        DEC_FSP
	STFSP
        mov %rdi, %rbx
        xor %rax, %rax
	NEXT

L_fpow:
  .ifndef __FAST__
        LDSP
  .endif
        push %rbx
        LDFSP
        add %rax, %rbx
        movq (%rbx), %xmm1
        add %rax, %rbx
        movq (%rbx), %xmm0
#        call powA
        call pow
        movq %xmm0, (%rbx)
        DEC_FSP
        STFSP
        pop %rbx
        xor %rax, %rax
        NEXT

L_fround:
        mov %rbx, %rdi
	LDFSP
	add %rax, %rbx
	fldl (%rbx)
	frndint
	fstpl (%rbx)
	mov %rdi, %rbx
        xor %rax, %rax
	NEXT

L_ftrunc:
        mov %rbx, %rdi
	LDFSP
	add %rax, %rbx
	fldl (%rbx)
	fnstcw NDPcw(%rip)            # save NDP control word
	mov NDPcw(%rip), %rcx
	movb $12, %ch
	mov %rcx, (%rbx)
	fldcw (%rbx)
	frndint
	fldcw NDPcw(%rip)             # restore NDP control word
	fstpl (%rbx)
	mov %rdi, %rbx
	NEXT

L_fadd:
        mov %rbx, %rdi
	LDFSP
	add %rax, %rbx
	fldl (%rbx)
	add %rax, %rbx
	faddl (%rbx)
	fstpl (%rbx)
	sub %rax, %rbx
        STFSP
        mov %rdi, %rbx
	xor %rax, %rax
	NEXT

L_fsub:
        mov %rbx, %rdi
	LDFSP
	add %rax, %rbx
	add %rax, %rbx
        fldl (%rbx)
        sub %rax, %rbx
	fsubl (%rbx)
        add %rax, %rbx
	fstpl (%rbx)
	sub %rax, %rbx
	STFSP
        mov %rdi, %rbx
	xor %rax, %rax
	NEXT

L_fmul:
        mov %rbx, %rdi
	LDFSP
	add %rax, %rbx
	fldl (%rbx)
	add %rax, %rbx
	fmull (%rbx)
	fstpl (%rbx)
	sub %rax, %rbx
	STFSP
        mov %rdi, %rbx
	xor %rax, %rax
	NEXT

L_fdiv:
        mov %rbx, %rdi
	LDFSP
	add %rax, %rbx
	fldl (%rbx)
	add %rax, %rbx
	fdivrl (%rbx)
	fstpl (%rbx)
        sub %rax, %rbx
	STFSP
        mov %rdi, %rbx
	xor %rax, %rax
	NEXT

L_backslash:
	mov pTIB(%rip), %rcx
	movb $0, (%rcx)
	NEXT


	.comm GlobalSp, WSIZE,WSIZE
	.comm GlobalFp, WSIZE,WSIZE
	.comm GlobalIp, WSIZE,WSIZE
	.comm GlobalRp, WSIZE,WSIZE
	.comm BottomOfStack, WSIZE,WSIZE
	.comm BottomOfReturnStack, WSIZE,WSIZE
	.comm vmEntryRp, WSIZE,WSIZE
	.comm Base, WSIZE,WSIZE
	.comm State, WSIZE,WSIZE
	.comm Precision, WSIZE,WSIZE
	.comm FpSize, WSIZE,WSIZE
	.comm pTIB, WSIZE,WSIZE
	.comm TIB, 256,1
	.comm WordBuf, 256,1
	.comm NumberCount, WSIZE,WSIZE
	.comm NumberBuf, 256,1

	
