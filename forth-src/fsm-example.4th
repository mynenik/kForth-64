\ fsm-example.4th
\
\ Finite State Machine example in kForth
\
\ Based on the finite state machine examples in 
\ "Finite State Machines in Forth", J. V. Noble, 1995,
\ Journal of Forth Applications and Research.
\
\ Adapted to kForth by K. Myneni, 9-3-2001
\
\ Requires:
\   ans-words.4th
\   fsm2.4th
\
\ Revisions: 
\   2010-05-24  km; include fsm code from fsm2.4th
\   2011-03-06  km; added Requires: comments.
\

\ The defining words for creating state machines
[undefined] fsm: [IF]  s" fsm2.4th" included  [THEN]

\ Fixed point number entry example of a finite state machine
\   ( from Noble in J. Forth Appl. and Res.)

: digit? ( n -- flag ) [char] 0 [char] : within ;

: dp? ( n -- flag ) [char] . = ;

: minus? ( n -- flag ) [char] - = ;

: cat->col# ( c -- n )
	\ Determine the input condition for the entered character
	dup digit? 1 and	\ digit -> 1
	over minus? 2 and +	\ -     -> 2
	swap dp? 3 and +	\ dp    -> 3
;				\ other -> 0


\ Create a finite state machine with 3 states and 4 inputs
\   and define its action table. Each entry in the action table
\   consists of the pair:
\
\ 	{ word_to_be_executed next_state_number }

3 4 fsm: <Fixed.Pt#>
\
\ 			    input:
\
\	  other?	num?	  minus?	dp?	
\ state:
\
  ( 0 )	|| drop  >0   || emit >1   || emit >1   || emit >2 
  ( 1 )	|| drop  >1   || emit >1   || drop >1   || emit >2 
  ( 2 )	|| drop  >2   || emit >2   || drop >2   || drop >2 

;fsm

: Getafix ( -- | allow user to enter valid fixed point number )
	0 >state <Fixed.Pt#>	\ initialize the state to zero
	begin
	  key dup 13 <> over 10 <> and
	while
	  dup cat->col#		\ determine input condition 
	  <Fixed.Pt#>		\ execute the state machine
	repeat 
	drop ;


