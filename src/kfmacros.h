// kfmacros.h
//
// Useful macros for kForth C and C++ source files, following
// the convention established by DNW in vm-osxppc.s
//
// Copyright (c) 2009--2026, Krishna Myneni
//   <krishna.myneni@ccreweb.org>
//
// This software is provided under the terms of the GNU
// Affero General Public License (AGPL), v3.0 or later.
//

#define INC_DSP   ++GlobalSp;
#define DEC_DSP   --GlobalSp;
#define TOS       (*GlobalSp)

#ifndef __NO_FPSTACK__
#define INC_FSP   (GlobalFp = (void*)((byte*)GlobalFp + FpSize));
#define DEC_FSP   (GlobalFp = (void*)((byte*)GlobalFp - FpSize));
#endif

#ifndef __FAST__

#define INC_DTSP  ++GlobalTp;
#define DEC_DTSP  --GlobalTp;
#define INC2_DTSP  GlobalTp += 2;
#define IS_ADDR   (*GlobalTp == OP_ADDR)
#define CHK_ADDR  if (*GlobalTp != OP_ADDR) return E_V_NOT_ADDR;
#define STD_IVAL  *GlobalTp-- = OP_IVAL;
#define STD_ADDR  *GlobalTp-- = OP_ADDR;
#define DROP      INC_DSP INC_DTSP
#define UNDROP    DEC_DSP DEC_DTSP

#else

#define INC_DTSP 
#define DEC_DTSP 
#define INC2_DTSP
#define IS_ADDR    ( FALSE )
#define CHK_ADDR 
#define STD_IVAL
#define STD_ADDR
#define DROP       INC_DSP
#define UNDROP     DEC_DSP

#endif

#define PUSH_IVAL(x) TOS = (x); DEC_DSP  STD_IVAL
#define PUSH_ADDR(x) TOS = (x); DEC_DSP  STD_ADDR
#define PUSH_CSTRING(x) TOS=((long int)x); DEC_DSP STD_ADDR TOS=(strlen(x)); DEC_DSP STD_IVAL

