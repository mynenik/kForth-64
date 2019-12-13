// VMerrors.h
//
// Copyright (c) 1996--2019, Krishna Myneni
//   <krishna.myneni@ccreweb.org>
//
// This software is provided under the terms of the GNU
// Affero General Public License (AGPL), v3.0 or later.
//

#ifndef __VMERRORS_H__
#define __VMERRORS_H__

#define MAX_V_RESERVED    80
#define MAX_V_SYS_DEFINED 25

// Forth 2012 Reserved Throw Codes
// (see Forth-2012 standard, Table 9.1)
#define E_V_NOERROR            0
#define E_V_ABORT             -1
#define E_V_ABORTQUOTE        -2
#define E_V_STK_OVERFLOW      -3
#define E_V_STK_UNDERFLOW     -4
#define E_V_RET_STK_OVERFLOW  -5
#define E_V_RET_STK_UNDERFLOW -6
#define E_V_DO_NESTING        -7
#define E_V_DICT_OVERFLOW     -8
#define E_V_INVALID_ADDR      -9
#define E_V_DIV_ZERO         -10
#define E_V_OUT_OF_RANGE     -11
#define E_V_ARGTYPE_MISMATCH -12
#define E_V_UNDEFINED_WORD   -13
#define E_V_COMPILE_ONLY     -14
#define E_V_INVALID_FORGET   -15
#define E_V_ZEROLENGTH_NAME  -16
#define E_V_OUTSTR_OVERFLOW  -17
#define E_V_PARSE_OVERFLOW   -18
#define E_V_DEFNAME_TOOLONG  -19
#define E_V_READONLY         -20
#define E_V_UNSUPPORTED      -21
#define E_V_CONTROL_MISMATCH -22
#define E_V_ADDR_ALIGN       -23
#define E_V_INVALID_ARG      -24
#define E_V_RET_STK_BALANCE  -25
#define E_V_LOOP_PARAMS      -26
#define E_V_INVALID_RECURSE  -27
#define E_V_USER_INTERRUPT   -28
#define E_V_COMPILER_NESTING -29
#define E_V_OBSCOLESCENT     -30
#define E_V_TOBODY           -31
#define E_V_INVALID_NAMEARG  -32
#define E_V_BLK_READ         -33
#define E_V_BLK_WRITE        -34
#define E_V_INVALID_BLKNUM   -35
#define E_V_INVALID_FILEPOS  -36       
#define E_V_FILE_IO          -37
#define E_V_FILE_NOEXIST     -38
#define E_V_EOF              -39
#define E_V_INVALID_BASE     -40
#define E_V_PRECISION_LOSS   -41
#define E_V_FDIVZERO         -42
#define E_V_FPRANGE          -43
#define E_V_FP_STK_OVERFLOW  -44
#define E_V_FP_STK_UNDERFLOW -45
#define E_V_FP_INVALID_ARG   -46
#define E_V_WLCOMP_DELETED   -47
#define E_V_INVALID_POSTPONE -48
#define E_V_SO_OVERFLOW      -49
#define E_V_SO_UNDERFLOW     -50
#define E_V_WLCOMP_CHANGED   -51
#define E_V_CF_STK_OVERFLOW  -52
#define E_V_EX_STK_OVERFLOW  -53
#define E_V_FP_UNDERFLOW     -54
#define E_V_FP_FAULT         -55
#define E_V_QUIT             -56
#define E_V_EXC_TXRXCHAR     -57
#define E_V_EXC_BRACKETCTL   -58
#define E_V_ALLOCATE         -59
#define E_V_FREE             -60
#define E_V_RESIZE           -61
#define E_V_CLOSE_FILE       -62
#define E_V_CREATE_FILE      -63
#define E_V_DELETE_FILE      -64
#define E_V_FILE_POSITION    -65
#define E_V_FILE_SIZE        -66
#define E_V_FILE_STATUS      -67
#define E_V_FLUSH_FILE       -68
#define E_V_OPEN_FILE        -69
#define E_V_READ_FILE        -70
#define E_V_READ_LINE        -71
#define E_V_RENAME_FILE      -72
#define E_V_REPOSITION_FILE  -73
#define E_V_RESIZE_FILE      -74
#define E_V_WRITE_FILE       -75
#define E_V_WRITE_LINE       -76
#define E_V_BAD_XCHAR        -77
#define E_V_SUBSTITUTE       -78
#define E_V_REPLACES         -79

// kForth System-defined THROW code assignments
#define E_V_NOT_ADDR         -256
#define E_V_NOT_IVAL         -257
#define E_V_RET_STK_CORRUPT  -258
#define E_V_BAD_OPCODE       -259
#define E_V_REALLOT          -260
#define E_V_CREATE           -261
#define E_V_NO_EOS           -262
#define E_V_NO_DO            -263
#define E_V_NO_BEGIN         -264
#define E_V_ELSE_NO_IF       -265
#define E_V_THEN_NO_IF       -266
#define E_V_ENDOF_NO_OF      -267
#define E_V_NO_CASE          -268
#define E_V_BAD_STACK_ADDR   -269
#define E_V_DIV_OVERFLOW     -270
#define E_V_DBL_OVERFLOW     -271
#define E_V_INCOMPLETE_IF    -272
#define E_V_INCOMPLETE_BEGIN -273
#define E_V_INCOMPLETE_LOOP  -274
#define E_V_INCOMPLETE_CASE  -275
#define E_V_END_OF_DEF       -276
#define E_V_NOT_IN_DEF       -277
#define E_V_END_OF_STREAM    -278
#define E_V_END_OF_STRING    -279
#define E_V_VM_UNKNOWN_ERROR -280

#endif

