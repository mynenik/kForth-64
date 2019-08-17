\ dummy-comm.4th
\
\   Module for dummy communication functions, to test a 
\   generic terminal application that can use various
\   asynchronous communications interfaces.

\ This module does not have any dependencies on other modules.

Module: dummy-comm
begin-module

create dummy-msg 64 allot
s" Dummy Terminal" dummy-msg swap move

3000 constant START_DELAY  \ delay from open to start of reception
10 constant RX_DELAY       \ 1 character rec'd every 10 ms

variable start-time
variable last-time

: total-elapsed ( -- u ) ms@ start-time @ - ;
: rx-elapsed    ( -- u ) ms@ last-time  @ - ;

Public:

variable config

\ Dummy Open
: open ( aconfig -- ) 
    drop  ms@ dup start-time ! last-time !
;

\ Dummy Get
: get ( -- c )  [char] A ;

\ Dummy Put
: put ( c -- ) drop ;

\ Dummy Rx-len
: Rx-len ( -- u )
	0
	total-elapsed START_DELAY > IF
	  rx-elapsed RX_DELAY > if  
	    drop 1  ms@ last-time !  
	  then 
	then  ;

\ Dummy Write
: write ( a u -- ) 2drop ;

\ Dummy Close
: close ( -- )  ;

end-module
