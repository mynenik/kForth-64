// ForthWords.h
//
// The intrinsic Forth word list for kForth
//
// Copyright (c) 2008--2023 Krishna Myneni,
//   <krishna.myneni@ccreweb.org> 
//
// This software is provided under the terms of the GNU
// Affero General Public License (AGPL), v3.0 or later.
//

// The minimum search-order set of words
WordTemplate RootWords[] =
{
#ifdef _WIN32_
    { "_WIN32_",        OP_TRUE,          0 },
#endif
    { "ORDER",          OP_ORDER,         0 },
    { "SET-ORDER",      OP_SETORDER,      NONDEFERRED },
    { "FORTH-WORDLIST", OP_FORTHWORDLIST, 0 },
    { "FORTH",          OP_FORTH,         NONDEFERRED },
    { "WORDS",          OP_WORDS,         0 },
};

WordTemplate ForthWords[] =
{
//    { "CPUTEST",   OP_CPUTEST,	    0 },
    { "DEFINITIONS", OP_DEFINITIONS,  NONDEFERRED },
    { "WORDLIST",  OP_WORDLIST,     NONDEFERRED },
    { "GET-CURRENT", OP_GETCURRENT, 0 },
    { "SET-CURRENT", OP_SETCURRENT, NONDEFERRED },
    { "GET-ORDER",   OP_GETORDER,      0 },
    { "SEARCH-WORDLIST", OP_SEARCHWORDLIST, 0 },
    { "TRAVERSE-WORDLIST", OP_TRAVERSE_WORDLIST, 0 },
    { "NAME>STRING", OP_NAME2STRING,          0 },
    { "NAME>INTERPRET", OP_NAME2INTERPRET,    0 },
    { "NAME>COMPILE", OP_NAME2COMPILE,        0 },
    { "MY-NAME",   OP_MYNAME,                 0 },
    { "ALSO",      OP_ALSO,         NONDEFERRED },
    { "ONLY",      OP_ONLY,         NONDEFERRED },
    { "PREVIOUS",  OP_PREVIOUS,     NONDEFERRED },
    { "VOCABULARY", OP_VOCABULARY,  NONDEFERRED },
    { "ASSEMBLER", OP_ASSEMBLER,    NONDEFERRED },
    { "PARSE",     OP_PARSE,        NONDEFERRED },
    { "PARSE-NAME", OP_PARSENAME,   NONDEFERRED },
    { "WORD",      OP_WORD,         NONDEFERRED },
    { "FIND",      OP_FIND,         0 },
    { "FIND-NAME-IN", OP_FIND_NAME_IN, 0 },
    { "FIND-NAME", OP_FIND_NAME,    0 },
    { "'",         OP_TICK,         NONDEFERRED },
    { "[']",       OP_BRACKETTICK,  IMMEDIATE },
    { "[DEFINED]", OP_DEFINED,      IMMEDIATE | NONDEFERRED },
    { "[UNDEFINED]", OP_UNDEFINED,  IMMEDIATE | NONDEFERRED },
    { "COMPILE,",  OP_COMPILECOMMA, NONDEFERRED },
    { "COMPILE-NAME", OP_COMPILENAME, NONDEFERRED },
    { "POSTPONE",  OP_POSTPONE,     IMMEDIATE },
    { "[",         OP_LBRACKET,     IMMEDIATE },
    { "]",         OP_RBRACKET,     NONDEFERRED },
    { "STATE",     OP_STATE,        0 },
    { "CREATE",    OP_CREATE,       NONDEFERRED },
    { "DOES>",     OP_DOES,         0 },
    { ">BODY",     OP_TOBODY,       0 },
    { "ALIAS",     OP_ALIAS,        NONDEFERRED },
    { "FORGET",    OP_FORGET,       NONDEFERRED },
    { "COLD",      OP_COLD,         NONDEFERRED },
    { ":NONAME",   OP_NONAME,       NONDEFERRED },
    { ":",         OP_COLON,        NONDEFERRED },
    { ";",         OP_SEMICOLON,    IMMEDIATE },
    { "USED",      OP_USED,         0 },
    { "ALLOCATE",  OP_ALLOCATE,     0 },     
    { "FREE",      OP_FREE,         0 },
    { "RESIZE",    OP_RESIZE,       0 },
    { "ALLOT",     OP_ALLOT,        NONDEFERRED },
    { "?ALLOT",    OP_QUERYALLOT,   NONDEFERRED },
    { "ALLOT?",    OP_QUERYALLOT,   NONDEFERRED },
#ifdef _WIN32_
    { "VALLOC",    OP_VALLOC,       NONDEFERRED },
    { "VFREE",     OP_VFREE,        NONDEFERRED },
    { "VPROTECT",  OP_VPROTECT,     NONDEFERRED },
#endif
    { "LITERAL",   OP_LITERAL,      IMMEDIATE },
    { "2LITERAL",  OP_2LITERAL,     IMMEDIATE },
    { "SLITERAL",  OP_SLITERAL,     IMMEDIATE },
    { "FLITERAL",  OP_FLITERAL,     IMMEDIATE },
    { "EVALUATE",  OP_EVALUATE,     0 },
    { "INCLUDED",  OP_INCLUDED,     NONDEFERRED },
    { "INCLUDE",   OP_INCLUDE,      NONDEFERRED },
    { "SOURCE",    OP_SOURCE,       0 },
    { "REFILL",    OP_REFILL,       0 }, 
    { "IMMEDIATE", OP_IMMEDIATE,    0 },
    { "NONDEFERRED", OP_NONDEFERRED, 0 },
    { "CONSTANT",  OP_CONSTANT,     NONDEFERRED },
    { "2CONSTANT", OP_2CONSTANT,    NONDEFERRED },
    { "FCONSTANT", OP_FCONSTANT,    NONDEFERRED },
    { "VARIABLE",  OP_VARIABLE,     NONDEFERRED },
    { "2VARIABLE", OP_2VARIABLE,    NONDEFERRED },
    { "FVARIABLE", OP_FVARIABLE,    NONDEFERRED },
    { "CELLS",     OP_CELLS,        0 },
    { "CELL+",     OP_CELLPLUS,     0 },
    { "CHAR+",     OP_INC,          0 },
    { "DFLOATS",   OP_DFLOATS,      0 },
    { "DFLOAT+",   OP_DFLOATPLUS,   0 },
#ifdef __NO_FPSTACK__
    { "FLOATS",    OP_DFLOATS,      0 },
    { "FLOAT+",    OP_DFLOATPLUS,   0 },
    { "SFLOATS",   OP_CELLS,        0 },
    { "SFLOAT+",   OP_CELLPLUS,     0 },
#else
    { "FLOATS",    OP_FLOATS,       0 },
    { "FLOAT+",    OP_FLOATPLUS,    0 },
    { "SFLOATS",   OP_SFLOATS,      0 },
    { "SFLOAT+",   OP_SFLOATPLUS,   0 },
#endif
    { "}}",        OP_FSL_MAT_ADDR, 0 },
    { "?",         OP_QUESTION,     0 },
    { "@",         OP_FETCH,        0 },
    { "!",         OP_STORE,        0 },
    { "2@",        OP_2FETCH,       0 },
    { "2!",        OP_2STORE,       0 },
    { "A@",        OP_AFETCH,       0 },
    { "C@",        OP_CFETCH,       0 },
    { "C!",        OP_CSTORE,       0 },
    { "W@",        OP_SWFETCH,      0 },
    { "SW@",       OP_SWFETCH,      0 },
    { "UW@",       OP_UWFETCH,      0 },
    { "W!",        OP_WSTORE,       0 },
    { "SL@",       OP_SLFETCH,      0 },
    { "UL@",       OP_ULFETCH,      0 },
    { "L!",        OP_LSTORE,       0 },
    { "F@",        OP_DFFETCH,      0 },
    { "F!",        OP_DFSTORE,      0 },
    { "DF@",       OP_DFFETCH,      0 },
    { "DF!",       OP_DFSTORE,      0 },
    { "SF@",       OP_SFFETCH,      0 },
    { "SF!",       OP_SFSTORE,      0 },
    { "SP@",       OP_SPFETCH,      0 },
    { "SP!",       OP_SPSTORE,      0 },
    { "RP@",       OP_RPFETCH,      0 },
    { "RP!",       OP_RPSTORE,      0 },
#ifndef __NO_FPSTACK__
    { "FP@",       OP_FPFETCH,      0 },
    { "FP!",       OP_FPSTORE,      0 },
#endif
    { ">R",        OP_PUSH,         0 },
    { "R>",        OP_POP,          0 },
    { "R@",        OP_RFETCH,       0 },
    { "2>R",       OP_TWOPUSH,      0 }, 
    { "2R>",       OP_TWOPOP,       0 },
    { "2R@",       OP_TWORFETCH,    0 }, 
    { "?DUP",      OP_QUERYDUP,     0 },
    { "DUP",       OP_DUP,          0 },
    { "DROP",      OP_DROP,         0 },
    { "SWAP",      OP_SWAP,         0 },
    { "OVER",      OP_OVER,         0 },
    { "ROT",       OP_ROT,          0 }, 
    { "-ROT",      OP_MINUSROT,     0 }, 
    { "NIP",       OP_NIP,          0 },
    { "TUCK",      OP_TUCK,         0 }, 
    { "PICK",      OP_PICK,         0 },
    { "ROLL",      OP_ROLL,         0 },
    { "2DUP",      OP_2DUP,         0 },
    { "2DROP",     OP_2DROP,        0 },
    { "2SWAP",     OP_2SWAP,        0 },
    { "2OVER",     OP_2OVER,        0 },
    { "2ROT",      OP_2ROT,         0 },
    { "DEPTH",     OP_DEPTH,        0 },
#ifndef __NO_FPSTACK__
    { "FDEPTH",    OP_FDEPTH,       0 },
#endif
    { "BASE",      OP_BASE,         0 },
    { "BINARY",    OP_BINARY,       NONDEFERRED },
    { "DECIMAL",   OP_DECIMAL,      NONDEFERRED },
    { "HEX",       OP_HEX,          NONDEFERRED },
    { "PRECISION", OP_PRECISION,    0 },
    { "SET-PRECISION", OP_SET_PRECISION, NONDEFERRED },
    { "1+",        OP_INC,          0 },
    { "1-",        OP_DEC,          0 },
    { "2+",        OP_TWOPLUS,      0 },
    { "2-",        OP_TWOMINUS,     0 },
    { "2*",        OP_TWOSTAR,      0 },
    { "2/",        OP_TWODIV,       0 },
    { "DO",        OP_DO,           IMMEDIATE },
    { "?DO",       OP_QUERYDO,      IMMEDIATE },
    { "LOOP",      OP_LOOP,         IMMEDIATE },
    { "+LOOP",     OP_PLUSLOOP,     IMMEDIATE },
    { "LEAVE",     OP_LEAVE,        IMMEDIATE },
    { "UNLOOP",    OP_UNLOOP,       IMMEDIATE },
    { "I",         OP_I,            0 },
    { "J",         OP_J,            0 },
    { "BEGIN",     OP_BEGIN,        IMMEDIATE },
    { "WHILE",     OP_WHILE,        IMMEDIATE },
    { "REPEAT",    OP_REPEAT,       IMMEDIATE },
    { "UNTIL",     OP_UNTIL,        IMMEDIATE },
    { "AGAIN",     OP_AGAIN,        IMMEDIATE },
    { "IF",        OP_IF,           IMMEDIATE },
    { "ELSE",      OP_ELSE,         IMMEDIATE },
    { "THEN",      OP_THEN,         IMMEDIATE },
    { "CASE",      OP_CASE,         IMMEDIATE },
    { "ENDCASE",   OP_ENDCASE,      IMMEDIATE },
    { "OF",        OP_OF,           IMMEDIATE },
    { "ENDOF",     OP_ENDOF,        IMMEDIATE },
    { "RECURSE",   OP_RECURSE,      IMMEDIATE },
    { "BYE",       OP_BYE,          0 },
    { "EXIT",      OP_RET,          0 },
    { "QUIT",      OP_QUIT,         0 },
    { "ABORT",     OP_ABORT,        0 },
    { "ABORT\x22", OP_ABORTQUOTE,   IMMEDIATE },
    { "VMTHROW",   OP_VMTHROW,      0 },
    { "USLEEP",    OP_USLEEP,       0 },
    { "EXECUTE-BC", OP_EXECUTE_BC,  0 },
    { "EXECUTE",   OP_EXECUTE,      0 },
    { "CALL",      OP_CALL,         0 },
    { "SYSTEM",    OP_SYSTEM,       0 },
#ifndef _WIN32_
    { "SYSCALL",   OP_SYSCALL,      0 },
#endif
    { "DLOPEN",    OP_DLOPEN,       0 },
    { "DLERROR",   OP_DLERROR,      0 },
    { "DLSYM",     OP_DLSYM,        0 },
    { "DLCLOSE",   OP_DLCLOSE,      0 },
#ifndef _WIN32_
    { "FORTH-SIGNAL", OP_FORTHSIGNAL, 0 },
    { "RAISE",     OP_RAISE,        0 },
    { "SET-ITIMER", OP_SETITIMER,   0 },
    { "GET-ITIMER", OP_GETITIMER,   0 },
#endif
    { "TIME&DATE", OP_TIMEANDDATE,  0 },
    { "MS",        OP_MS,           0 },
    { "MS@",       OP_MSFETCH,      0 },
#ifndef _WIN32_
    { "US",        OP_US,           0 },
    { "US2@",      OP_US2FETCH,     0 },
#endif
    { "CHDIR",     OP_CHDIR,        0 },
    { ">FILE",     OP_TOFILE,       NONDEFERRED },
    { "CONSOLE",   OP_CONSOLE,      NONDEFERRED },
    { "\\",        OP_BACKSLASH,    IMMEDIATE | NONDEFERRED },
    { "#!",        OP_BACKSLASH,    IMMEDIATE | NONDEFERRED },
    { "(",         OP_LPAREN,       IMMEDIATE },
    { ".(",        OP_DOTPAREN,     IMMEDIATE | NONDEFERRED },
    { "C\x22",     OP_CQUOTE,       IMMEDIATE },
    { "S\x22",     OP_SQUOTE,       IMMEDIATE },
    { "/STRING",   OP_SLASHSTRING,  0 },
    { "-TRAILING", OP_TRAILING,     0 },
    { "COUNT",     OP_COUNT,        0 },
    { ">NUMBER",   OP_TONUMBER,     0 },
    { "NUMBER?",   OP_NUMBERQUERY,  0 },
    { "<#",        OP_BRACKETSHARP, 0 },
    { "#",         OP_SHARP,        0 },
    { "#S",        OP_SHARPS,       0 },
    { "#>",        OP_SHARPBRACKET, 0 },
    { "SIGN",      OP_SIGN,         0 },
    { "HOLD",      OP_HOLD,         0 },
    { ">FLOAT",    OP_TOFLOAT,      0 },
    { ".",         OP_DOT,          0 },
    { ".R",        OP_DOTR,         0 },
    { "U.",        OP_UDOT,         0 },
    { "U.R",       OP_UDOTR,        0 },
    { "D.",        OP_DDOT,         0 },
    { "D.R",       OP_DDOTR,        0 },
    { "UD.",       OP_UDDOT,        0 },
    { "UD.R",      OP_UDDOTR,       0 },
    { "F.",        OP_FDOT,         0 },
    { "FS.",       OP_FSDOT,        0 },
    { ".\x22",     OP_DOTQUOTE,     IMMEDIATE },
    { ".S",        OP_DOTS,         0 },
#ifndef __NO_FPSTACK__
    { "F.S",       OP_FDOTS,        0 },
#endif
    { "CR",        OP_CR,           0 },
    { "SPACES",    OP_SPACES,       0 },
    { "EMIT",      OP_EMIT,         0 },
    { "TYPE",      OP_TYPE,         0 },
    { "BL",        OP_BL,           0 },
    { "[CHAR]",    OP_BRACKETCHAR,  IMMEDIATE },
    { "CHAR",      OP_CHAR,         NONDEFERRED },
    { "KEY",       OP_KEY,          0 },
    { "KEY?",      OP_KEYQUERY,     0 },
    { "ACCEPT",    OP_ACCEPT,       0 },
    { "SEARCH",    OP_SEARCH,       0 },
    { "COMPARE",   OP_COMPARE,      0 },
    { "WITHIN",    OP_WITHIN,       0 },
    { "=",         OP_EQ,           0 },
    { "<>",        OP_NE,           0 },
    { "<",         OP_LT,           0 },
    { ">",         OP_GT,           0 },
    { "<=",        OP_LE,           0 },
    { ">=",        OP_GE,           0 },
    { "U<",        OP_ULT,          0 },
    { "U>",        OP_UGT,          0 },
    { "0=",        OP_ZEROEQ,       0 },
    { "0<>",       OP_ZERONE,       0 },
    { "0<",        OP_ZEROLT,       0 },
    { "0>",        OP_ZEROGT,       0 },
    { "D=",        OP_DEQ,          0 },
//  { "D<>",       OP_DNE,          0 },
    { "D<",        OP_DLT,          0 },
//  { "D>",        OP_DGT,          0 },
//  { "D<=",       OP_DLE,          0 },
//  { "D>=",       OP_DGE,          0 },
    { "DU<",       OP_DULT,         0 },
    { "D0=",       OP_DZEROEQ,      0 },
    { "D0<",       OP_DZEROLT,      0 },
    { "FALSE",     OP_FALSE,        0 },
    { "TRUE",      OP_TRUE,         0 },
    { "AND",       OP_AND,          0 },
    { "OR",        OP_OR,           0 },
    { "XOR",       OP_XOR,          0 },
    { "NOT",       OP_NOT,          0 },
    { "INVERT",    OP_NOT,          0 },
    { "BOOLEAN?",  OP_BOOLEAN_QUERY, 0 },
    { ".NOT.",     OP_BOOL_NOT,     0 },
    { ".AND.",     OP_BOOL_AND,     0 },
    { ".OR.",      OP_BOOL_OR,      0 },
    { ".XOR.",     OP_BOOL_XOR,     0 },
    { "LSHIFT",    OP_LSHIFT,       0 },
    { "RSHIFT",    OP_RSHIFT,       0 },
    { "+",         OP_ADD,          0 },
    { "-",         OP_SUB,          0 },
    { "*",         OP_MUL,          0 },
    { "*+",        OP_STARPLUS,     0 },
    { "/",         OP_DIV,          0 },
    { "MOD",       OP_MOD,          0 },
    { "/MOD",      OP_SLASHMOD,     0 },
    { "U/MOD",     OP_UDIVMOD,      0 },
    { "*/",        OP_STARSLASH,    0 },
    { "*/MOD",     OP_STARSLASHMOD, 0 },
    { "UD/MOD",    OP_UDDIVMOD,     0 },
    { "+!",        OP_PLUSSTORE,    0 },
    { "D+",        OP_DPLUS,        0 },
    { "D-",        OP_DMINUS,       0 },
    { "D2*",       OP_DTWOSTAR,     0 },
    { "D2/",       OP_DTWODIV,      0 },
    { "DMAX",      OP_DMAX,         0 },
    { "DMIN",      OP_DMIN,         0 },
    { "M+",        OP_MPLUS,        0 },
    { "M*",        OP_MSTAR,        0 },
    { "M/",        OP_MSLASH,       0 },
    { "M*/",       OP_MSTARSLASH,   0 },
    { "UM*",       OP_UMSTAR,       0 },
    { "DS*",       OP_DSSTAR,       0 },
    { "UM/MOD",    OP_UMSLASHMOD,   0 },
    { "FM/MOD",    OP_FMSLASHMOD,   0 },
    { "SM/REM",    OP_SMSLASHREM,   0 },
    { "UTM/",      OP_UTMSLASH,     0 },
    { "UTS/MOD",   OP_UTSSLASHMOD,  0 },
    { "STS/REM",   OP_STSSLASHREM,  0 },
    { "UDM*",      OP_UDMSTAR,      0 },
    { "ABS",       OP_ABS,          0 },
    { "NEGATE",    OP_NEG,          0 },
    { "MIN",       OP_MIN,          0 },
    { "MAX",       OP_MAX,          0 },
    { "DABS",      OP_DABS,         0 },
    { "DNEGATE",   OP_DNEGATE,      0 },
    { "OPEN",      OP_OPEN,         0 },
    { "LSEEK",     OP_LSEEK,        0 },
    { "CLOSE",     OP_CLOSE,        0 },
    { "READ",      OP_READ,         0 },
    { "WRITE",     OP_WRITE,        0 },
    { "FSYNC",     OP_FSYNC,        0 },
    { "IOCTL",     OP_IOCTL,        0 },
    { "FILL",      OP_FILL,         0 },
    { "ERASE",     OP_ERASE,        0 },
    { "BLANK",     OP_BLANK,        0 },
    { "MOVE",      OP_MOVE,         0 },
    { "CMOVE",     OP_CMOVE,        0 },
    { "CMOVE>",    OP_CMOVEFROM,    0 },
#ifdef __NO_FPSTACK__
    { "FDUP",      OP_2DUP,         0 },
    { "FDROP",     OP_2DROP,        0 },
    { "FSWAP",     OP_2SWAP,        0 },
    { "FOVER",     OP_2OVER,        0 },
    { "FROT",      OP_2ROT,         0 },
#else
    { "FDUP",      OP_FDUP,         0 },
    { "FDROP",     OP_FDROP,        0 },
    { "FSWAP",     OP_FSWAP,        0 },
    { "FOVER",     OP_FOVER,        0 },
    { "FROT",      OP_FROT,         0 },
    { "FPICK",     OP_FPICK,        0 },
#endif
    { "F2DROP",    OP_F2DROP,       0 },
    { "F2DUP",     OP_F2DUP,        0 },
    { "F=",        OP_FEQ,          0 },
    { "F<>",       OP_FNE,          0 },
    { "F<",        OP_FLT,          0 },
    { "F>",        OP_FGT,          0 },
    { "F<=",       OP_FLE,          0 },
    { "F>=",       OP_FGE,          0 },
    { "F0=",       OP_FZEROEQ,      0 },
    { "F0<",       OP_FZEROLT,      0 },
    { "F0>",       OP_FZEROGT,      0 },
    { "F+",        OP_FADD,         0 },
    { "F-",        OP_FSUB,         0 },
    { "F*",        OP_FMUL,         0 },
    { "F/",        OP_FDIV,         0 },
    { "F**",       OP_FPOW,         0 },
    { "F+!",       OP_FPLUSSTORE,   0 },
    { "FSQRT",     OP_FSQRT,        0 },
    { "FSQUARE",   OP_FSQUARE,      0 },
    { "FABS",      OP_FABS,         0 },
    { "FNEGATE",   OP_FNEG,         0 },
    { "FLOOR",     OP_FLOOR,        0 },
    { "FROUND",    OP_FROUND,       0 },
    { "FTRUNC",    OP_FTRUNC,       0 },
    { "FMIN",      OP_FMIN,         0 },
    { "FMAX",      OP_FMAX,         0 },
    { "FSIN",      OP_FSIN,         0 },
    { "FCOS",      OP_FCOS,         0 },
    { "FSINCOS",   OP_FSINCOS,      0 },
    { "FTAN",      OP_FTAN,         0 },
    { "FACOS",     OP_FACOS,        0 },
    { "FASIN",     OP_FASIN,        0 },
    { "FATAN",     OP_FATAN,        0 },
    { "FATAN2",    OP_FATAN2,       0 },
    { "FSINH",     OP_FSINH,        0 },
    { "FCOSH",     OP_FCOSH,        0 },
    { "FTANH",     OP_FTANH,        0 },
    { "FASINH",    OP_FASINH,       0 },
    { "FACOSH",    OP_FACOSH,       0 },
    { "FATANH",    OP_FATANH,       0 },
    { "FLOG",      OP_FLOG,         0 },
    { "FALOG",     OP_FALOG,        0 },
    { "FLN",       OP_FLN,          0 },
    { "FLNP1",     OP_FLNP1,        0 },
    { "FEXP",      OP_FEXP,         0 },
    { "FEXPM1",    OP_FEXPM1,       0 },
    { "PI",        OP_PI,           0 },
    { "DEG>RAD",   OP_DEGTORAD,     0 },
    { "RAD>DEG",   OP_RADTODEG,     0 },
    { "S>D",       OP_STOD,         0 },
    { "D>S",       OP_DROP,         0 },
    { "S>F",       OP_STOF,         0 },
    { "D>F",       OP_DTOF,         0 },
    { "F>D",       OP_FTOD,         0 },
    { "FROUND>S",  OP_FROUNDTOS,    0 },
    { "FTRUNC>S",  OP_FTRUNCTOS,    0 }
};
