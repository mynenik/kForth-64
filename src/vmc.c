/*
vmc.c

  C portion of the kForth Virtual Machine

  Copyright (c) 1998--2020 Krishna Myneni, 
  <krishna.myneni@ccreweb.org>

  This software is provided under the terms of the GNU
  Affero General Public License (AGPL), v3.0 or later.

*/

#define _GNU_SOURCE

#include <sys/types.h>
#include <sys/time.h>
#include <sys/timeb.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <stdio.h>
#include <signal.h>
#include <dlfcn.h>
#include <unistd.h>
#include <time.h>
#include <fcntl.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <malloc.h>
#include <math.h>
#include "fbc.h"
#include "VMerrors.h"
#include "kfmacros.h"

#define WSIZE 8
#define TRUE -1
#define FALSE 0

#define byte unsigned char

//  Provided by ForthVM.cpp
extern long int* GlobalSp;
extern void* GlobalFp;
extern byte* GlobalIp;
extern long int* GlobalRp;
extern long int* BottomOfStack;
extern long int* BottomOfReturnStack;
extern long int FpSize;
#ifndef __FAST__
extern byte* GlobalTp;
extern byte* GlobalRtp;
extern byte* BottomOfTypeStack;
extern byte* BottomOfReturnTypeStack;
#endif
extern int CPP_bye();

// Provided by vmxx-common.s
extern long int Base;
extern long int State;
extern char* pTIB;
extern long int NumberCount;
extern long int JumpTable[];
extern char WordBuf[];
extern char TIB[];
extern char NumberBuf[];
extern char ParseBuf[];

//  Provided by vmxx.s/vmxx-fast.s
int L_dnegate();
int L_dplus();
int L_dminus();
int L_udmstar();
int L_utmslash();
int L_quit();
int L_abort();
int vm(byte*);

struct timeval ForthStartTime;
struct termios tios0;
struct mallinfo ForthStartMem;
double* pf;
double f;
char temp_str[256];
char key_query_char = 0;

/*  signal dispatch table  */

void** signal_xtmap [32] =
{
    NULL,              //  1  SIGHUP, Hangup
    NULL,              //  2  SIGINT, Interrupt
    NULL,              //  3  SIGQUIT, Quit
    NULL,              //  4  SIGILL, Illegal instruction
    NULL,              //  5  SIGTRAP, Trace trap
    NULL,              //  6  SIGABRT, Abort
    NULL,              //  7  SIGBUS,  Bus error
    NULL,              //  8  SIGFPE,  Floating-point exception
    NULL,              //  9  SIGKILL, Kill (unblockable)
    NULL,              // 10  SIGUSR1, User-defined
    NULL,              // 11  SIGSEGV, Segmentation fault
    NULL,              // 12  SIGUSR2, User-defined
    NULL,              // 13  SIGPIPE, Broken pipe
    NULL,              // 14  SIGALRM, Alarm clock
    NULL,              // 15  SIGTERM, Termination
    NULL,              // 16  SIGSTKFLT, Stack fault
    NULL,              // 17  SIGCHLD, Child status changed
    NULL,              // 18  SIGCONT, Continue execution
    NULL,              // 19  SIGSTOP, Stop (unblockable)
    NULL,              // 20  SIGTSTP, Keyboard stop
    NULL,              // 21  SIGTTIN, Background read from tty
    NULL,              // 22  SIGTTOU, Background write to tty
    NULL,              // 23  SIGURG, Urgent condition on socket
    NULL,              // 24  SIGXCPU, CPU time limit exceeded
    NULL,              // 25  SIGXFSZ, File size limit exceeded
    NULL,              // 26  SIGVTARM, Virtual alarm clock
    NULL,              // 27  SIGPROF, Profiling alarm clock
    NULL,              // 28  SIGWINCH, Window size change
    NULL,              // 29  SIGPOLL,  Pollable event occured
    NULL,              // 30  SIGPWR,  Power failure restart
    NULL,              // 31  SIGUNUSED,  Not used
    NULL
};

static void forth_signal_handler (int, siginfo_t*, void*); 

// powA  is copied from the source of the function pow() in paranoia.c,
//   at  http://www.math.utah.edu/~beebe/software/ieee/ 
double powA(double x, double y) /* return x ^ y (exponentiation) */
{
    double xy, ye;
    long i;
    int ex, ey = 0, flip = 0;

    if (!y) return 1.0;

    if ((y < -1100. || y > 1100.) && x != -1.) return exp(y * log(x));

    if (y < 0.) { y = -y; flip = 1; }
    y = modf(y, &ye);
    if (y) xy = exp(y * log(x));
    else xy = 1.0;
    /* next several lines assume >= 32 bit integers */
    x = frexp(x, &ex);
    if ((i = (long)ye, i)) for(;;) {
        if (i & 1) { xy *= x; ey += ex; }
        if (!(i >>= 1)) break;
        x *= x;
        ex *= 2;
        if (x < .5) { x *= 2.; ex -= 1; }
    }
    if (flip) { xy = 1. / xy; ey = -ey; }
    return ldexp(xy, ey);
} 

#define DOUBLE_FUNC(x)   pf = (double*)((byte*)GlobalFp+FpSize); *pf=x(*pf);
  
int C_ftan  () { DOUBLE_FUNC(tan)  return 0; }
int C_facos () { DOUBLE_FUNC(acos) return 0; }
int C_fasin () { DOUBLE_FUNC(asin) return 0; }
int C_fatan () { DOUBLE_FUNC(atan) return 0; }
int C_fsinh () { DOUBLE_FUNC(sinh) return 0; }
int C_fcosh () { DOUBLE_FUNC(cosh) return 0; }
int C_ftanh () { DOUBLE_FUNC(tanh) return 0; }
int C_fasinh () { DOUBLE_FUNC(asinh) return 0; }
int C_facosh () { DOUBLE_FUNC(acosh) return 0; }
int C_fatanh () { DOUBLE_FUNC(atanh) return 0; }
int C_fexp  () { DOUBLE_FUNC(exp)   return 0; }
int C_fexpm1() { DOUBLE_FUNC(expm1) return 0; }
int C_fln   () { DOUBLE_FUNC(log)   return 0; }
int C_flnp1 () { DOUBLE_FUNC(log1p) return 0; }
int C_flog  () { DOUBLE_FUNC(log10) return 0; }
int C_falog () { DOUBLE_FUNC(exp10) return 0; }

int C_fpow ()
{
	pf = (double*)((byte*) GlobalFp + FpSize);
	f = *pf;
	++pf;
	*pf = powA (*pf, f);
	INC_FSP
	return 0;
}				

int C_fmin ()
{
	pf = (double*)((byte*) GlobalFp + FpSize);
	f = *pf;
	++pf;
	if (f < *pf) *pf = f;
	INC_FSP
	return 0;
}

int C_fmax ()
{
	pf = (double*)((byte*) GlobalSp + FpSize);
	f = *pf;
	++pf;
	if (f > *pf) *pf = f;
	INC_FSP
	return 0;
}

int C_open ()
{
  /* stack: ( ^str flags -- fd | return the file descriptor )
     ^str is a counted string with the pathname, flags
     indicates the method of opening (read, write, etc.)  */

  int flags, mode = 0;
  char* pname;

  DROP
  flags = TOS;
  DROP
  CHK_ADDR
  pname = *((char**)GlobalSp);
  ++pname;
  if (flags & O_CREAT) mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
  PUSH_IVAL( open (pname, flags, mode) )
  return 0;
}
      
int C_lseek ()
{
  /* stack: ( fd offset mode -- error | set file position in fd ) */

  int fd, mode;
  unsigned long int offset;
  DROP
  mode = TOS;
  DROP
  offset = TOS;
  INC_DSP
  fd = TOS;
  TOS = lseek (fd, offset, mode);
  DEC_DSP
  return 0;
}

int C_close ()
{

  /* stack: ( fd -- err | close the specified file and return error code ) */

  int fd;
  INC_DSP
  fd = TOS;
  TOS = close(fd);
  DEC_DSP
  return 0;
}

int C_read ()
{
  /* stack: ( fd buf count -- length | read count bytes into buf from fd ) */
  int fd, count;
  void* buf;

  DROP
  count = (int)(TOS);
  DROP
  CHK_ADDR
  buf = *((void**)GlobalSp);
  DROP
  fd = (int)(TOS);
  PUSH_IVAL( read (fd, buf, count) )
  return 0;
}

int C_write ()
{
  /* stack: ( fd buf count  -- length | write count bytes from buf to fd ) */
  int fd, count;
  void* buf;

  DROP
  count = TOS;
  DROP
  CHK_ADDR
  buf = *((void**)GlobalSp);
  DROP
  fd = TOS;
  PUSH_IVAL( write (fd, buf, count) )
  return 0;
}

// FSYNC ( fd -- ior )
// Flush all buffered data written to file to the storage device
// Low-level interface for implementation of standard Forth
// word, FLUSH-FILE (Forth 94/Forth 2012)
int C_fsync ()
{
  /* stack: ( fd -- ior )  */
  int fd;
  DROP
  fd = TOS;
  PUSH_IVAL( fsync(fd) )
  return 0;
}
  

int C_ioctl ()
{
  /* stack: ( fd request addr -- err | device control function ) */
  int fd, request;
  char* argp;

  DROP
  argp = *((char**) GlobalSp);  /* don't do type checking on argp */
  DROP
  request = TOS;
  INC_DSP
  fd = TOS;
  TOS = ioctl(fd, request, argp);
  DEC_DSP
  return 0;
}
/*----------------------------------------------------------*/

int C_dlopen ()
{
   /* stack: ( azLibName flag -- handle | NULL) */
   unsigned long flags;
   long int handle;
   char *pLibName;

   DROP
   flags = TOS;
   DROP
   CHK_ADDR
   pLibName = *((char**) GlobalSp);  // pointer to a null-terminated string

   handle = (long int) dlopen((const char*) pLibName, flags);
   PUSH_IVAL(handle)
   return 0;
}

int C_dlerror ()
{
   /* stack: ( -- addrz) ; Returns address of null-terminated string*/
   char *errMsg;
   errMsg = dlerror();
   PUSH_ADDR((long int) errMsg)
   return 0;
}

int C_dlsym ()
{
    /* stack: ( handle azsymbol -- addr ) */
    long int handle;
    char *pSymbol;
    void *pSymAddr;

    DROP
    CHK_ADDR
    pSymbol = *((char**)GlobalSp);  // pointer to a null-terminated string
    DROP
    handle = TOS;

    pSymAddr = dlsym((void*)handle, (const char*) pSymbol);
    PUSH_ADDR((long int) pSymAddr)
    return 0;
}

int C_dlclose ()
{
    /* stack: ( handle -- error | 0) */
    long int handle;
    INC_DSP
    handle = TOS;
    TOS = dlclose((void*)handle);
    DEC_DSP
    return 0;
}
/*----------------------------------------------------------*/

void save_term ()
{
    tcgetattr(0, &tios0);
}

void restore_term ()
{
    tcsetattr(0, TCSANOW, &tios0);
}

void echo_off ()
{
  struct termios t;
  tcgetattr(0, &t);
  t.c_lflag &= ~ECHO;
  tcsetattr(0, TCSANOW, &t);
}

void echo_on ()
{
  struct termios t;
  tcgetattr(0, &t);
  t.c_lflag |= ECHO;
  tcsetattr(0, TCSANOW, &t);
}
/*----------------------------------------------------------*/

int C_key ()
{
  /* stack: ( -- n | wait for keypress and return key code ) */

  char ch;
  int n;
  struct termios t1, t2;

  if (key_query_char)
    {
      ch = key_query_char;
      key_query_char = 0;
    }
  else
    {
      tcgetattr(0, &t1);
      t2 = t1;
      t2.c_lflag &= ~ICANON;
      t2.c_lflag &= ~ECHO;
      t2.c_cc[VMIN] = 1;
      t2.c_cc[VTIME] = 0;
      tcsetattr(0, TCSANOW, &t2);

      do {
	n = read(0, &ch, 1);
      } while (n != 1);

      tcsetattr(0, TCSANOW, &t1);
    }

  PUSH_IVAL(ch)
  return 0;
}
/*----------------------------------------------------------*/

int C_keyquery ()
{
  /* stack: ( a -- b | return true if a key is available ) */

  char ch = 0;
  struct termios t1, t2;

  if (key_query_char)
    {
      TOS = -1;
    }
  else
    {
      tcgetattr(0, &t1);
      t2 = t1;
      t2.c_lflag &= ~ICANON;
      t2.c_lflag &= ~ECHO;
      t2.c_cc[VMIN] = 0;
      t2.c_cc[VTIME] = 0;
      tcsetattr(0, TCSANOW, &t2);

      TOS = read(0, &ch, 1) ? -1 : 0;
      if (ch) key_query_char = ch;  
      tcsetattr(0, TCSANOW, &t1);
    }
  DEC_DSP
  STD_IVAL

  return 0;
}      
/*----------------------------------------------------------*/

int C_accept ()
{
  /* stack: ( a n1 -- n2 | wait for n characters to be received ) */

  char *cp, *cpstart, *bksp = "\010 \010";
  long int n1, n2, nr;
  struct termios t1, t2;

  DROP
  n1 = TOS;
  DROP
  CHK_ADDR
  cp = *((char**)GlobalSp);
  cpstart = cp;

  tcgetattr(0, &t1);
  t2 = t1;
  t2.c_lflag &= ~ICANON;
  t2.c_lflag &= ~ECHO;
  t2.c_cc[VMIN] = 1;
  t2.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &t2);


  n2 = 0;
  // while (n2 < n1)
  while (1)
    {
      nr = read (0, cp, 1);
      if (nr == 1) 
	{
	  if (*cp == 10) 
	    break;
	  else if (*cp == 127)
	  {
	    write (0, bksp, 3);
	    --cp; --n2;
	    if (cp < cpstart) cp = cpstart;
	    if (n2 < 0) n2 = 0;
	  }
	  else if (n2 < n1) {
	      write (0, cp, 1);
	      ++n2; ++cp;
	  }
	  else
	    ;
	}
    }
  PUSH_IVAL(n2)
  tcsetattr(0, TCSANOW, &t1);
  return 0;
}
/*----------------------------------------------------------*/

void strupr (char* p)
{
/* convert string to upper case  */

  while (*p) {*p = toupper(*p); ++p;}
}

char* ExtractName (char* str, char* name)
{
/*
Starting at ptr str, extract the non delimiter text into
a buffer starting at name with null terminator appended
at the end. Return a pointer to the next position in str.
*/

    const char* delim = "\n\r\t ";
    char *pStr = str, *pName = name;

    if (*pStr)
      {
	while (strchr(delim, *pStr)) ++pStr;
	while (*pStr && (strchr(delim, *pStr) == NULL))
	  {
	    *pName = *pStr;
	    ++pName;
	    ++pStr;
	  }
      }
    *pName = 0;
    return pStr;
}
/*----------------------------------------------------------*/

int IsFloat (char* token, double* p)
{
/*
Check the string token to see if it is an LMI style floating point
number; if so set the value of *p and return True, otherwise
return False.
*/
    char *pStr = token;

    if (strchr(pStr, 'E'))
    {
        while ((isdigit(*pStr)) || (*pStr == '-')
          || (*pStr == 'E') || (*pStr == '+') || (*pStr == '.'))
        {
            ++pStr;
        }
        if (*pStr == 0)
        {
            /* LMI Forth style */

            --pStr;
            if (*pStr == 'E') *pStr = '\0';
            *p = atof(token);
            return TRUE;
        }
    }

    return FALSE;
}
/*----------------------------------------------------------*/

int isBaseDigit (int c)
{
   int u = toupper(c);

   return ( (isdigit(u) && ((u - 48) < Base)) || 
	    (isalpha(u) && (Base > 10) && ((u - 55) < Base)) );
}
/*---------------------------------------------------------*/

int IsInt (char* token, long int* p)
{
/* Check the string token to see if it is an integer number;
   if so set the value of *p and return True, otherwise return False. */

  int b = FALSE, sign = FALSE;
  unsigned long u = 0;
  char *pStr = token, *endp;

  if ((*pStr == '-') || isBaseDigit(*pStr))
    {
      if (*pStr == '-') {sign = TRUE;}
      ++pStr;
      while (isBaseDigit(*pStr))	    
	{
	  ++pStr;
	}
      if (*pStr == 0)
        {
	  u = strtoul(token, &endp, Base);
	  b = TRUE;
        }

    }

  *p = u;
  return b;
}
/*---------------------------------------------------------*/

int C_word ()
{
  /* stack: ( n -- ^str | parse next word in input stream )
     n is the delimiting character and ^str is a counted string. */
  DROP
  char delim = TOS;
  char *dp = WordBuf + 1;

  while (*pTIB)  /* skip leading delimiters */
    {
      if (*pTIB != delim) break;
      ++pTIB;
    }
  if (*pTIB)
    {
      long int count = 0;
      while (*pTIB)
	{
	  if (*pTIB == delim) break;
	  *dp++ = *pTIB++;
	  ++count;
	}
      if (*pTIB) ++pTIB;  /* consume the delimiter */
      *WordBuf = count;
      *dp = ' ';
    }
  else
    {
      *WordBuf = 0;
    }
  PUSH_ADDR((long int) WordBuf)
  return 0;
}

// PARSE  ( char "ccc<char>" -- c-addr u )
// Parse text delimited by char; return string address and count.
// Forth 2012 Core Extensions wordset 6.2.2008
int C_parse ()
{
  DROP
  char delim = TOS;
  char *dp = ParseBuf;
  long int count = 0;
  if (*pTIB)
    {

      while (*pTIB)
	{
	  if (*pTIB == delim) break;
	  *dp++ = *pTIB++;
	  ++count;
	}
      if (*pTIB) ++pTIB;  /* consume the delimiter */
    }
  PUSH_ADDR((long int) ParseBuf)
  PUSH_IVAL(count)
  return 0;
}

// PARSE-NAME  ( "<spaces>name<space>" -- c-addr u )
// Skip leading spaces and parse name delimited by space;
//   return string address and count.
// Forth 2012 Core Extensions wordset 6.2.2020
int C_parsename ()
{
  long int count = 0;
  char *cp;
  cp = ExtractName(pTIB, ParseBuf);
  count = strlen(ParseBuf);
  PUSH_ADDR((long int) pTIB)
  PUSH_IVAL(count)
  pTIB = cp;
  return 0;
}

/*----------------------------------------------------------*/

int C_trailing ()
{
  /* stack: ( a n1 -- a n2 | adjust count n1 to remove trailing spaces ) */
  long int n1;
  char *cp;
  DROP
  n1 = TOS;
  if (n1 > 0) {
    DROP
    CHK_ADDR
    cp = (char *) TOS + n1 - 1;
    while ((*cp == ' ') && (n1 > 0)) { --n1; --cp; }
    DEC_DSP
    DEC_DTSP
    TOS = n1;
  }
  DEC_DSP
  DEC_DTSP
  return 0;
}
/*----------------------------------------------------------*/

int C_bracketsharp()
{
  /* stack: ( -- | initialize for number conversion ) */

  NumberCount = 0;
  NumberBuf[255] = 0;
  return 0;
}


int C_sharp()
{
  /* stack: ( ud1 -- ud2 | convert one digit of ud1 ) */

  unsigned long int u1, u2, rem;
  char ch;

  *GlobalSp = *(GlobalSp+2); --GlobalSp;
  *GlobalSp = *(GlobalSp+2); --GlobalSp;  /* 2dup */
#ifndef __FAST__
  *GlobalTp = *(GlobalTp+2); --GlobalTp;
  *GlobalTp = *(GlobalTp+2); --GlobalTp;  /*  "  */
#endif
  TOS = 0; /* pad to triple length */
  DEC_DSP
  DEC_DTSP
  TOS = Base;
  DEC_DSP
  DEC_DTSP

  L_utmslash();
  u1 = *(GlobalSp + 1);  /* quotient */
  u2 = *(GlobalSp + 2);

  /* quotient is on the stack; we need the remainder */

  TOS = Base;
  DEC_DSP
  DEC_DTSP
  L_udmstar();
  DROP

  L_dminus();
  rem = *(GlobalSp + 2);  /* get the remainder */

  *(GlobalSp + 1) = u1;   /* replace rem with quotient on the stack */
  *(GlobalSp + 2) = u2;
  ch = (rem < 10) ? (rem + 48) : (rem + 55);
  ++NumberCount;
  NumberBuf[255 - NumberCount] = ch;

  return 0;
}


int C_sharps()
{
  /* stack: ( ud -- 0 0 | finish converting all digits of ud ) */

  unsigned long int u1=1, u2=0;

  while (u1 | u2)
    {
      C_sharp();
      u1 = *(GlobalSp + 1);
      u2 = *(GlobalSp + 2);
    }
  return 0;
}


int C_hold()
{
  /* stack: ( n -- | insert character into number string )  */
  DROP
  char ch = TOS;
  ++NumberCount;
  NumberBuf[255-NumberCount] = ch;
  return 0;
}


int C_sign()
{
  /* stack: ( n -- | insert sign into number string if n < 0 ) */
  DROP
  long int n = TOS;
  if (n < 0)
    {
      ++NumberCount;
      NumberBuf[255-NumberCount] = '-';
    }
  return 0;
}


int C_sharpbracket()
{
  /* stack: ( 0 0 -- | complete number conversion ) */

  DROP
  DROP
  PUSH_ADDR( (long int) (NumberBuf + 255 - NumberCount) )
  PUSH_IVAL(NumberCount)
  return 0;
}
/*--------------------------------------------------------------*/

int C_tonumber ()
{
  /* stack: ( ud1 a1 u1 -- ud2 a2 u2 | translate characters into ud number ) */

  unsigned long i, ulen, uc;
  int c;
  char *cp;
  ulen = (unsigned long) *(GlobalSp + 1);
  if (ulen == 0) return 0;
  uc = ulen;
  DROP
  DROP
  CHK_ADDR
  cp = (char*) TOS;
  for (i = 0; i < ulen; i++) {
	c = (int) *cp;
  	if (!isBaseDigit(c)) break;
        if (c > '9') {
	  c &= 223;
          c -= 'A';
          c += 10;
        }
	else c -= '0';
        TOS = Base;
        DEC_DSP
        DEC_DTSP
        L_udmstar();
        DROP
        if (TOS) return E_V_DBL_OVERFLOW;
        TOS = c;
        DEC_DSP
        TOS = 0;
        DEC_DSP
        DEC_DTSP
        DEC_DTSP
        L_dplus();
        --uc; ++cp;
  }

  TOS = (long int) cp;
  DEC_DSP
  TOS = uc;
  DEC_DSP
  DEC_DTSP;
  DEC_DTSP;

  return 0;
}
/*-----------------------------------------------------------*/
 
int C_tofloat ()
{
  /* stack: ( a u -- f true | false ; convert string to floating point number ) */

  char s[256], *cp;
  double f;
  unsigned long nc, u;
  long int b;

  DROP
  nc = TOS;
  DROP
  cp = (char*) TOS;

  b = FALSE; f = 0.;

  if (nc < 256) {
      /* check for a string of blanks */
      u = nc;
      while ((*(cp+u-1) == ' ') && u ) --u;
      if (u == 0) { /* Forth-94 spec:  */
	b = TRUE;    /* "A string of blanks is a special case representing zero."  */
      }              /* "A null string will be converted as a valid 0E."  */
      else {
	/* Verify there is a numeric digit in the string */
	u = 0;
	for (u = 0; u < nc; ++u) if (isdigit(*(cp+u))) break; 
	if (u == nc) {
	  b = FALSE;                   /* no numeric digit in string */
        }
	else {
          memcpy (s, cp, nc);
          s[nc] = 0;
          strupr(s);

	  /* Replace 'D' with 'E'  (Fortran double precision float exponent indicator) */
	  for (u = 0; u < nc; u++)
	    if (s[u] == 'D') s[u] = 'E';

	  /* '+' and '-' may also be indicators of the exponent if
             they are used internally, following the significand; 
             Replace with or insert 'E', as appropriate */

	  if ((! strchr(s, 'E')) && (nc > 2)) {
	    for (u = 1; u < (nc-1); u++) {
	      if (s[u] == '+') {
		if ((isdigit(s[u-1]) || s[u-1] =='.') && isdigit(s[u+1])) s[u] = 'E'; 
	        }
	      else if (s[u] == '-')
	        {
		   if ((isdigit(s[u-1]) || s[u-1] =='.') && isdigit(s[u+1])) {
		      memmove(s+u+1, s+u, nc-u+1);
		      s[u]='E';
		   }
	         }
	       else
	         ;
	     }
	  }

          /* Tack on power of ten (0), if it is missing */
          if (! strchr(s, 'E')) strcat(s, "E0"); 
          if (s[0]) b = IsFloat(s, &f);
        }
      }
    }
    

  if (b) {
      *((double*)(GlobalFp)) = f;
      DEC_FSP
  }
  PUSH_IVAL(b)
  return 0;
}
/*-------------------------------------------------------------*/

int C_numberquery ()
{
  /* stack: ( ^str -- d b | translate characters into number using current base ) */

  char *pStr;
  long int b, sign, nc;

  b = FALSE;
  sign = FALSE;

  DROP
  if (GlobalSp > BottomOfStack) return E_V_STK_UNDERFLOW;
  CHK_ADDR
  pStr = *((char**)GlobalSp);
  PUSH_IVAL(0)
  PUSH_IVAL(0)
  nc = *pStr;
  ++pStr;

  if (*pStr == '-') {
    sign = TRUE; ++pStr; --nc;
  }
  if (nc > 0) {
        PUSH_ADDR((long int) pStr)
        PUSH_IVAL(nc)
        C_tonumber();
	DROP
        b = TOS;
	DROP
	b = (b == 0) ? TRUE : FALSE ;
  }

  if (sign) L_dnegate();

  PUSH_IVAL(b)
  return 0;
}
/*----------------------------------------------------------*/

int C_syscall ()
{
    /* stack: ( arg1 ... arg_n nargs nsyscall -- err | 0 <= n <= 6) */

    long int nargs, nsyscall, args[6];
    int i;
    DROP
    nsyscall = TOS; 
    DROP
    nargs = TOS;
    if (nargs > 6) nargs = 6;  // this should be an error
    for (i = 0; i < nargs; i++)
    {
        DROP
	args[i] = TOS;
    }

    switch (nargs)
    {
	case 0:
	    TOS = syscall(nsyscall);
	    break;
	case 1:
	    TOS = syscall(nsyscall, args[0]);
	    break;
	case 2:
	    TOS = syscall(nsyscall, args[1], args[0]);
	    break;
	case 3:
	    TOS = syscall(nsyscall, args[2], args[1], args[0]);
	    break;
	case 4:
	    TOS = syscall(nsyscall, args[3], args[2], args[1], args[0]);
	    break;
	case 5:
	    TOS = syscall(nsyscall, args[4], args[3], args[2], args[1], args[0]);
	    break;
	case 6:
	    TOS = syscall(nsyscall, args[5], args[4], args[3], args[2], args[1], args[0]);
	    break;
	default:
	    ; // Illegal number or args
    }
    DEC_DSP
    STD_IVAL

    return 0;
}
/*----------------------------------------------------------*/

int C_system ()
{
  /* stack: ( ^str -- n | n is the return code for the command in ^str ) */

  char* cp;
  long int nc, nr;

  DROP
  CHK_ADDR
  cp = (char*) TOS;
  nc = *cp;
  strcpy (temp_str, "exec ");
  strncpy (temp_str+5, cp+1, nc);
  temp_str[5 + nc] = 0;
  nr = system(temp_str);
  PUSH_IVAL(nr)

  return 0;
}
/*----------------------------------------------------------*/

int C_chdir ()
{
  /* stack: ( ^path -- n | set working directory to ^path; return error code ) */

  char* cp;
  int nc;

  DROP
  CHK_ADDR
  cp = (char*) TOS;
  nc = (int) (*cp);
  strncpy (temp_str, cp+1, nc);
  temp_str[nc] = 0;
  PUSH_IVAL( chdir(temp_str) )
  return 0;
}
/*-----------------------------------------------------------*/

int C_timeanddate ()
{
  /* stack: ( -- sec min hr day mo yr | fetch local time ) */

  time_t t;
  struct tm t_loc;

  time (&t);
  t_loc = *(localtime (&t));

  PUSH_IVAL( t_loc.tm_sec )
  PUSH_IVAL( t_loc.tm_min )
  PUSH_IVAL( t_loc.tm_hour )
  PUSH_IVAL( t_loc.tm_mday )
  PUSH_IVAL( 1 + t_loc.tm_mon )
  PUSH_IVAL( 1900 + t_loc.tm_year )
  return 0;
}
/*---------------------------------------------------------*/

int C_usec ()
{
  /* stack: ( u -- | delay for u microseconds ) */

  struct timeval tv1, tv2;
  unsigned long int usec;

  DROP
  usec = TOS;

  gettimeofday (&tv1, NULL);
  tv1.tv_usec += usec;

  while (tv1.tv_usec >= 1000000)
    {
      tv1.tv_sec++;
      tv1.tv_usec -= 1000000;
    }

  do
    {
      gettimeofday (&tv2, NULL);
    } while (timercmp(&tv1, &tv2, >)) ;

  return 0;
}
/*------------------------------------------------------*/

void set_start_time ()
{
  /* this is not a word in the Forth dictionary; it is
     used by the initialization routine on startup     */

  gettimeofday (&ForthStartTime, NULL);
}

int C_msfetch ()
{
  /* stack: ( -- msec | return msec elapsed since start of Forth ) */
  
  struct timeval tv;
  gettimeofday (&tv, NULL);
  TOS = (tv.tv_sec - ForthStartTime.tv_sec)*1000 + 
    (tv.tv_usec - ForthStartTime.tv_usec)/1000;
  DEC_DSP
  STD_IVAL
  return 0;
}

int C_us2fetch ()
{
  /* stack: ( -- ud | return microseconds elapsed since start of Forth ) */
  
  struct timeval tv;
  gettimeofday (&tv, NULL);
  unsigned long long int usec;
  usec = (tv.tv_sec - ForthStartTime.tv_sec)*1000000ULL+
     (tv.tv_usec - ForthStartTime.tv_usec);
  TOS = *((long int*)&usec);
  DEC_DSP
#if WSIZE == 4
  TOS = *((long int*)&usec + 1);
#else
  TOS = 0;
#endif
  DEC_DSP
  STD_IVAL
  STD_IVAL

  return 0;
}

void set_start_mem ()
{
  /* initialize starting memory usage */
  ForthStartMem = mallinfo();
}

int C_used ()
{
  /* stack: ( -- u | return bytes used since start of Forth ) */
  unsigned long u0, u1;
  struct mallinfo mi = mallinfo();
  u0 = ForthStartMem.arena + ForthStartMem.hblkhd;
  u1 = mi.arena + mi.hblkhd;
  TOS = (u1 - u0);
  DEC_DSP
  STD_IVAL
  return 0;
}
/*------------------------------------------------------*/

int C_search ()
{
  /* stack: ( a1 u1 a2 u2 -- a3 u3 flag ) */

  char *str1, *str2, *cp, *cp2;
  unsigned long int n, n_needle, n_haystack, n_off, n_rem;
  DROP
  n = TOS;
  DROP
  CHK_ADDR
  str2 = (char*) TOS;
  DROP
  if (n > 255) n = 255;
  n_needle = n;
  n_haystack = TOS;    // size of search buffer
  DROP
  CHK_ADDR
  str1 = (char*) TOS;  
  n_rem = n_haystack;
  n_off = 0;
  cp = str1;
  cp2 = NULL;

  if (n_needle > 0)
  {
      while (n_rem >= n_needle)
      {
	  cp = (char *) memchr(cp, *str2, n_rem);
	  if (cp && (n_rem >= n_needle))
	  {
	      n_rem = n_haystack - (cp - str1);
	      if (memcmp(cp, str2, n_needle) == 0)
	      {
		  cp2 = cp;
		  n_off = (int)(cp - str1);
		  break;
	      }
	      else
	      {
		  ++cp; --n_rem;
	      }
	  }
	  else
	      n_rem = 0;
      }
  }
  else if (n_needle == 0)
	cp2 = cp;
  else
    ;

  if (cp2 == NULL) n_off = 0;
  TOS = (long int)(str1 + n_off);
  DEC_DSP
  TOS = n_haystack - n_off;
  DEC_DSP
  TOS = cp2 ? -1 : 0 ;
  DEC_DSP
  STD_ADDR
  STD_IVAL
  STD_IVAL

  return 0;
}
/*------------------------------------------------------*/

int C_compare ()
{
  /* stack: ( a1 u1 a2 u2 -- n ) */

  char *str1, *str2;
  long int n1, n2, n, ncmp, nmin;
  DROP
  n2 = TOS;
  DROP
  CHK_ADDR
  str2 = (char*) TOS;
  DROP 
  n1 = TOS;
  DROP
  CHK_ADDR
  str1 = (char*) TOS;

  nmin = (n1 < n2) ? n1 : n2;
  ncmp = memcmp(str1, str2, nmin);

  if (ncmp == 0) {
    if (n1 == n2) n = 0;
    else if (n1 < n2) n = -1;
    else n = 1;
  }
  else if (ncmp < 0)  n = -1;
  else n = 1;

  PUSH_IVAL(n)
  return 0;
}
/*------------------------------------------------------*/

int C_setitimer ()
{
    /* stack: ( timer-type avalue aoldvalue -- flag ) */
    
    long int type;
    struct itimerval *v1, *v2;

    DROP
    v2 = (struct itimerval*) TOS;
    CHK_ADDR
    DROP
    v1 = (struct itimerval*) TOS;
    CHK_ADDR
    DROP
    type = TOS;
    PUSH_IVAL( setitimer (type, v1, v2) )
    return 0;
}

int C_getitimer ()
{
    /* stack: ( timer-type  avalue -- flag )  */
    
    long int type;
    struct itimerval *v;

    DROP
    v = (struct itimerval*) TOS;
    CHK_ADDR
    DROP
    type = TOS;
    PUSH_IVAL( getitimer (type, v) )
    return 0;
}

int C_raise ()
{
    /* stack: ( signum -- ior ) */
    INC_DSP
    int signum = TOS;
    TOS = raise(signum);
    DEC_DSP
    return 0;
}

int C_forth_signal ()
{
    /* Install a Forth handler for specified signal 
       stack: ( xt n -- oldxt )  */

    int signum;
    struct sigaction action;
    void **xt, **oldxt;

    DROP
    signum = TOS;
    if ((signum > 0) && (signum < 31))
    {
	DROP
	oldxt = signal_xtmap[signum-1];
	memset( &action, 0, sizeof(struct sigaction));
	action.sa_flags = SA_SIGINFO;
	xt = (void**) TOS;
	switch ((long int) xt)
	{
	    case (long int) SIG_DFL:
		// Reset the default signal handler if xt = 0
	        action.sa_sigaction = (void*) SIG_DFL;
		sigaction( signum, &action, NULL );
		xt = 0;
		break;
	    case (long int) SIG_IGN:
		// Ignore the signal if xt = 1
	        action.sa_sigaction = (void*) SIG_IGN;
		sigaction( signum, &action, NULL );
		xt = 0;
		break;
	    default:
		// All other xt s must be valid addresses to opcodes
		CHK_ADDR
	        action.sa_sigaction = forth_signal_handler;
		sigaction( signum, &action, NULL );
		break;
	}
        signal_xtmap[signum-1] = xt;
        PUSH_ADDR( (long int) oldxt )
    }
    else
	return E_V_BAD_OPCODE;

    return 0;
}
/*-----------------------------------------------------*/

static void forth_signal_handler (int signum, siginfo_t* si, void* vcontext)
{
    /* Take the required action for the signal by looking up 
       and executing the appropriate Forth word which has been 
       designated to handle this signal.

       Since we can jump into this function at any point in the
       execution of the vm(), i.e. during the middle of a word,
       we must preserve the stack states and restore them
       after the handler has finished executing. The vm()
       already takes care of preserving and restoring the virtual
       instruction ptr (GlobalIp).
    */
    long int e, *sp = GlobalSp, *rp = GlobalRp;
#ifndef __FAST__ 
    unsigned char* tp = GlobalTp, *rtp = GlobalRtp;
#endif
    byte opcode;
    void* pCode;
    char* msg;
    ucontext_t* context = (ucontext_t*) vcontext;

    // Lookup the execution token of Forth word for this signal.
    void** xt = signal_xtmap[signum-1];
    if (xt == 0) return;

    opcode = *((byte*) (*xt));
    if ((opcode == OP_QUIT) || (opcode == OP_ABORT) || (opcode == OP_BYE)) {
      // Handle special signals requiring immediate exit from the VM,
      // without execution of Forth handler, e.g. SIGSEGV
      pCode = (void*) JumpTable[opcode];
      switch (signum) {
        case SIGSEGV:
          msg = "Segmentation fault\n";
          write(1, msg, 19);
          context->uc_mcontext.gregs[REG_RIP] = (unsigned long int) pCode;
          return;
        case SIGINT:
	  msg = "Interrupted by user\n";
          write(1, msg, 20);
          context->uc_mcontext.gregs[REG_RIP] = (unsigned long int) pCode;
          return;
        case SIGFPE:
          msg = "Floating point exception\n";
          write(1, msg, 25);
          context->uc_mcontext.gregs[REG_RIP] = (unsigned long int) pCode;
          return;
        case SIGBUS:
          msg = "Bus error\n";
          write(1, msg, 10);
          context->uc_mcontext.gregs[REG_RIP] = (unsigned long int) pCode;
          return;
        case SIGILL:
          msg = "Illegal instruction\n";
          write(1, msg, 20);
          context->uc_mcontext.gregs[REG_RIP] = (unsigned long int) pCode;
          return;
        case SIGQUIT:
          msg = "SIGQUIT\n";
          write(1, msg, 8);
          context->uc_mcontext.gregs[REG_RIP] = (unsigned long int) pCode;
          return;
        case SIGABRT:
          msg = "SIGABRT\n";
          write(1, msg, 8);
          context->uc_mcontext.gregs[REG_RIP] = (unsigned long int) pCode;
          return;
        default:
          msg = "Signal received\n";
          write(1, msg, 16);
          context->uc_mcontext.gregs[REG_RIP] = (unsigned long int) pCode;
          return;
	  break;
       }
    }

    // We must offset the stack pointers so the Forth handler will not
    //   overwrite intermediate stack values in the primary vm(). An offset 
    //   of 16 elements should be safe (worst case is L_utmslash, which
    //   uses about 12 elements above the current stack position for 
    //   intermediate calculations).
    GlobalSp -= 16; GlobalRp -= 16;
#ifndef __FAST__ 
    GlobalTp -= 16; GlobalRtp -= 16;
#endif
    PUSH_IVAL(signum);
    e = vm((byte*) *xt);
    if (e == E_V_QUIT) {
      context->uc_mcontext.gregs[REG_RIP] = (unsigned long int) L_quit;
    }

    // Restore data stack and return stack pointers
    GlobalSp = sp; GlobalRp = rp;
#ifndef __FAST__ 
    GlobalTp = tp; GlobalRtp = rtp;
#endif
}
