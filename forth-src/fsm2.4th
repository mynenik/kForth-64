\ fsm2.4th
\
\ Code to create state machines from tabular representations

\ ---------------------------------------------------
\     (c) Copyright 2001  Julian V. Noble.          \
\       Permission is granted by the author to      \
\       use this software for any application pro-  \
\       vided this copyright notice is preserved.   \
\ ---------------------------------------------------

\ This is an ANS Forth program requiring the
\    CORE
\
\ Adapted for kForth to avoid use of ","
\
\ Note that the arguments to the defining word FSM: are
\ different in this version, since we need to allocate
\ the memory for the state machine a-priori.

\ This code also compiles and runs without change on other
\ Forth systems (e.g. PFE, GFORTH, ...)  with the definitions:
\
\       : A@ @ ;
\       : ALLOT? HERE SWAP ALLOT ;
\       : 2+ 2 + ; ( needed for GFORTH)


\ Revisions:
\   2010-05-24 km  fixed various problems with the source;
\                  definition of WIDE is commented out.
\   
0 [IF]
: ||   ' ,  ' ,  ;            \ add two xt's to data field
: wide   0  ;                 \ aesthetic, initial state = 0

: fsm:   ( width state --)    \ define fsm
    CREATE  , ( state) ,  ( width in double-cells)  ;


: ;fsm   DOES>                ( x col# adr -- x' )
         DUP >R  2@           ( x col# width state)
         *  +                 ( x col#+width*state )
         2*  2 +  CELLS       ( x relative_offset )
         R@  +                ( x adr[action] )
         DUP >R               ( x adr[action] )
         a@  EXECUTE          ( x' )
         R> CELL+             ( x' adr[update] )
         a@  EXECUTE          ( x' state')
         R> !   ;             ( x' )  \ update state

[THEN]


: || ' OVER ! CELL+ ' OVER ! CELL+ ;


: fsm: ( nstates ninputs -- ) 
	create
	  2dup * cells 2*	\ Number of cells for actions and transition 
	  2 cells + allot?	\ Two more cells to hold the state and width
	  dup >r cell+ ! drop r>  \ Store the width of the table in 2nd cell;
	  2 cells +		\ leave pfa + 2 cells on stack
;


: ;fsm  drop 
	does> ( n a -- ) 	\ n is the input condition
	  dup >r 2@ * + 	\ n+width*state
	  2* 2+ cells		\ offset to action
	  r@ +  		\ add offset to address
	  dup >r		\ push for future use	
	  a@ execute 		\ execute the action
	  r> cell+ 
	  a@ execute r> !	\ transition to the next state 
;


\ set fsm's state, as in:  0 >state fsm-name
: >state ( state "fsm-name -- )  
    ' >BODY 
    POSTPONE LITERAL POSTPONE !  ; IMMEDIATE   ( state "fsm-name" --)

\ query current state, as in:  state: fsm-name
: state: ( "fsm-name" -- state)
    ' >BODY                     \ get dfa
    POSTPONE LITERAL  POSTPONE @   ;   IMMEDIATE

0 CONSTANT >0   3 CONSTANT >3   6 CONSTANT >6    \ these indicate state
1 CONSTANT >1   4 CONSTANT >4   7 CONSTANT >7    \ transitions in tabular
2 CONSTANT >2   5 CONSTANT >5                    \ representations
\ end fsm code


