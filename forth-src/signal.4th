\ signal.4th
\
\ Signals interface for kForth
\
\ Copyright (C) 2004 Krishna Myneni
\ Provided under the GNU General Public License
\
\ Revisions:
\	2004-09-04  created

 1  constant  SIGHUP     \  Hangup
 2  constant  SIGINT     \  Interrupt
 3  constant  SIGQUIT    \  Quit
 4  constant  SIGILL     \  Illegal instruction
 5  constant  SIGTRAP    \  Trace trap
 6  constant  SIGABRT    \  Abort
 7  constant  SIGBUS     \  Bus error
 8  constant  SIGFPE     \  Floating-point exception
 9  constant  SIGKILL    \  Kill (unblockable)
10  constant  SIGUSR1    \  User-defined
11  constant  SIGSEGV    \  Segmentation fault
12  constant  SIGUSR2    \  User-defined
13  constant  SIGPIPE    \  Broken pipe
14  constant  SIGALRM    \  Alarm clock
15  constant  SIGTERM    \  Termination
16  constant  SIGSTKFLT  \  Stack fault
17  constant  SIGCHLD    \  Child status changed
18  constant  SIGCONT    \  Continue execution
19  constant  SIGSTOP    \  Stop (unblockable)
20  constant  SIGTSTP    \  Keyboard stop
21  constant  SIGTTIN    \  Background read from tty
22  constant  SIGTTOU    \  Background write to tty
23  constant  SIGURG     \  Urgent condition on socket
24  constant  SIGXCPU    \  CPU time limit exceeded
25  constant  SIGXFSZ    \  File size limit exceeded
26  constant  SIGVTARM   \  Virtual alarm clock
27  constant  SIGPROF    \  Profiling alarm clock
28  constant  SIGWINCH   \  Window size change
29  constant  SIGPOLL    \  Pollable event occured
30  constant  SIGPWR     \  Power failure restart

 0  constant  SIG_DFL
 1  constant  SIG_IGN

 0  constant  ITIMER_REAL
 1  constant  ITIMER_VIRTUAL
 2  constant  ITIMER_PROF


\ Buffer to hold args to SET-ITIMER and GET-ITIMER
CREATE itimerdata  8 CELLS ALLOT 

\ Simplified interface for setup of timer signals

: ms>usec,sec ( ms -- usec sec | convert milliseconds to sec and usec )
      DUP 1000 / TUCK 1000 * - 1000 * SWAP ;

: set-timer ( msinterval msnow -- | generate SIGALRM every ms milli-seconds) 
      ms>usec,sec  itimerdata 2 CELLS + 2!  
      ms>usec,sec  itimerdata 2!
      ITIMER_REAL  itimerdata  itimerdata 4 CELLS +  SET-ITIMER
      ABORT" SET-ITIMER error" ;

: get-timer ( -- ms | get the countdown value for the real-time timer)
      ITIMER_REAL  itimerdata  GET-ITIMER 
      ABORT" GET-ITIMER error"
      itimerdata 2 CELLS + 2@ 1000 * SWAP 1000 / + ;

