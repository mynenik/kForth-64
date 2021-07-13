\ gps.4th
\
\ A simplified version of the Newell-Simon General Problem Solver,
\ described in:
\
\	 "GPS, A Program That Simulates Human Thought", by
\	 Allen Newell and H. A. Simon
\
\ reprinted in "Computers and Thought", edited by E. A. Feigenbaum 
\ and J. Feldman, 1995, AAAI Press, pp. 279--293.
\
\ The GPS program demonstrates separation of the problem solving 
\ technique from the description of the problem. The implementation
\ given here is essentially that of the Common Lisp example given
\ in 
\
\	"Paradigms of Artificial Intelligence Programming", 
\	Peter Norvig, 1992, Morgan Kaufmann Publishers, pp. 109--120.
\
\ Ported to ANS Forth by Krishna Myneni
\
\ Revisions:
\
\	 2003-04-15  -- created
\
\
\ Requires:
\
\	ans-words.4th
\	struct.4th
\	strings.4th
\	lists.4th
\
include ans-words
include struct
include strings
include lists

struct
	cell%  field  action
	cell%  field  preconds
	cell%  field  add-list
	cell%  field  del-list
end-struct  op%

nil  ptr  *state*
nil  ptr  *ops*

: find-all ( ^val list1 predicate-xt -- list2 )
	-rot nil >r
	BEGIN  dup nil? 0=
	WHILE  dup car dup >r
	  2 pick swap 4 pick execute
	  IF    r> r> cons >r
	  ELSE  r> drop
	  THEN  cdr
	REPEAT 2drop drop r> ;


: appropriate-p  ( goal op -- flag )
     add-list a@ memberp ;


defer achieve

: apply-op ( op -- flag )
	dup preconds a@ ['] achieve every  IF
	  >r
	  ." EXECUTING " r@ action a@ print cr
	  *state*  r@ del-list a@  set-difference  to *state*
	  *state*  r> add-list a@  union           to *state*  
	  true 
	ELSE
	 drop false
	THEN ; 

	
 
:noname ( goal -- flag )
	dup  *state* memberp IF drop true
	ELSE
	  *ops*  ['] appropriate-p  find-all
	  ['] apply-op some 
	THEN ; 
  is achieve


: gps ( state-list  goals-list  ops-list -- )
	to *ops* swap to *state* 
	." Goals: " dup print cr
	." Current State: " *state* print cr
        ['] achieve  every IF ." Solved." THEN ;


\ ---------------------------------------------------------

\ Example of using the "General Problem Solver" (from Norvig, 1992):


create op  op% %allot  
quote  drive-son-to-school	 op  action !
'(  son-at-home  car-works  )    op  preconds !
'(  son-at-school  )	         op  add-list !
'(  son-at-home  )		 op  del-list !


create op  op% %allot
quote  shop-installs-battery    op action !
'(  car-needs-battery  shop-knows-problem  shop-has-money  )  op preconds !
'(  car-works  )                op add-list !
nil                             op del-list !


create op  op% %allot
quote  tell-shop-problem         op action !
'(  in-communication-with-shop  )  op preconds !
'(  shop-knows-problem  )       op add-list !
nil                             op del-list !


create op  op% %allot
quote  telephone-shop           op action !
'(  know-phone-number  )        op preconds !
'(  in-communication-with-shop  )  op add-list !
nil                             op del-list !


create op  op% %allot
quote  look-up-number           op action !
'(  have-phone-book  )          op preconds !
'(  know-phone-number  )        op add-list !
nil                             op del-list !


create op op% %allot
quote  give-shop-money          op action !
'(  have-money )                op preconds !
'(  shop-has-money  )           op add-list !
'(  have-money  )               op del-list !

6 make-non-atomic-list  ptr *school-ops*  \ list of structure addresses

\ ------------ Now solve some problems using GPS ------------

.( First Problem ) cr

'( son-at-home car-works )  '( son-at-school )  *school-ops*  gps

cr cr

.( Second Problem ) cr

'( son-at-home car-needs-battery have-money have-phone-book )
'( son-at-school )  *school-ops*  gps

cr cr

.( Third Problem ) cr

'( son-at-home  have-money car-works )  '( have-money  son-at-school )  
*school-ops*  gps


cr cr

.( Fourth Problem ) cr

'( son-at-home  car-needs-battery  have-money  have-phone-book )
'( have-money  son-at-school )  *school-ops*  gps

cr cr
.( The solution to the Fourth Problem is incorrect! See Norvig's book ) cr
.( for a discussion of why, and how the GPS routine may be modified to ) cr
.( fix the "sibling goal clobbering" problem. ) 
cr cr
