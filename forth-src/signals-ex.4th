\ signals-ex.4th
\
\ Examples of signal handling in kForth
\
\ Copyright (c) 2004--2020 Krishna Myneni
\
\ Provided under the GNU Affero General Public License
\ (AGPL) v 3.0 or later.
\

include ans-words
include signal

: WINDOW-HANDLER ( n -- )
    DROP ." Window size changed!" CR ;

: TIMER-HANDLER ( n -- )
     DROP CR TIME&DATE 2DROP DROP
     . BL EMIT . BL EMIT . ;

: TEST1  ( -- )
    decimal
    ['] WINDOW-HANDLER  SIGWINCH  forth-signal  drop
    ['] TIMER-HANDLER   SIGALRM   forth-signal  drop
    CR ." Installed new handlers for SIGWINCH and SIGALRM"
    CR ." Try resizing the console --- Use ESC to halt"
    1000 1000 SET-TIMER     \ Send SIGALRM to kForth every 1000 ms
    BEGIN
      KEY 27 =
    UNTIL

    SIG_IGN SIGALRM  forth-signal  DROP  \ Stop sending SIGALRM
    CR ." Exiting TEST1 -- handler for SIGWINCH is still active" CR
;

: GPF-HANDLER ( -- )
    cr ." Protection Fault!" cr ABORT ;

0 ptr memAddr

create inbuf 16 allot
: input-an-address ( -- u )
    0 s>d inbuf 1 cells 2* accept 
    inbuf swap >number 2drop d>s ;

hex
variable v
BE v !
 
: TEST2
    hex
    ['] GPF-HANDLER SIGSEGV  forth-signal .
    cr ." Installed handler for SIGSEGV" cr
    cr ." Enter any memory address as a hex number and press"
    cr ." ENTER to read its value. For example, the address"
    cr v u. ." is valid and contains the value 'BE'" cr
    BEGIN
      cr ." Address: "
      input-an-address to memAddr
      memAddr c@ 2 spaces .  \ will likely generate a Protection Fault
    AGAIN
    decimal
;

cr .( Type 'TEST1 to test SIGALRM and SIGWINCH handlers. ) 
cr .( Type 'TEST2' to test the SIGSEGV handler. ) cr cr


