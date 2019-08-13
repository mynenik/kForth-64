\ signals-ex.4th
\
\ Examples of signal handling in kForth
\
\ Copyright (c) 2004 Krishna Myneni
\ Provided under the GNU General Public License
\
\ Requires:
\
\	signal.4th
\
\ Revisions:
\       2004-09-04  created  km
\

include signal.4th


: WINDOW-HANDLER ( n -- )
    DROP ." Window size changed!" CR
;

: TIMER-HANDLER ( n -- )
     DROP CR TIME&DATE 2DROP DROP
     . BL EMIT . BL EMIT . ;

CR .( Installing new handlers for SIGWINCH and SIGALRM)

' WINDOW-HANDLER  SIGWINCH  forth-signal  drop
' TIMER-HANDLER   SIGALRM   forth-signal  drop

CR .( Try resizing the console --- Use ESC to halt)

: TEST  ( -- )
    1000 1000 SET-TIMER     \ Send SIGALRM to kForth every 1000 ms
    BEGIN
      KEY 27 =
    UNTIL

    SIG_IGN SIGALRM  forth-signal  DROP  \ Stop sending SIGALRM

    CR ." Exiting TEST -- handler for SIGWINCH is still active" CR
;
    
TEST


\ -------------------------------

\ Not implemented yet: Handlers which need to perform a nonlocal jump.
\   This is required for signals such as SIGFPE, SIGSEGV, etc.
\
\ : GPF-HANDLER ( n -- )
\     DROP ." Invalid address" abort ;
\ CR .( Installing new handler for SIGSEGV )
\ ' GPF-HANDLER SIGSEGV  forth-signal .
 

