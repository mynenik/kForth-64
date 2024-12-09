\ lists.4th
( *
 * LANGUAGE    : ANS Forth with extensions
 * PROJECT     : Forth Environments
 * DESCRIPTION : A Lisp-like List Processor written in Forth
 * CATEGORY    : Experimental Tools
 * AUTHOR      : David Sharp
 * LAST CHANGE : May 22, 1994, Marcel Hendrix, docs, testing. CLEAN-UP crashes!
 * LAST CHANGE : May 21, 1994, Marcel Hendrix, seems ok
 * LAST CHANGE : May 14, 1994, Marcel Hendrix, port
 * EXTENSIVE REVISIONS: March--April 2003, Krishna Myneni
 * Revisions   : Mar 18, 2005, Krishna Myneni, multi-line lists
 *             : Dec 28, 2006, km; added set-difference:test
 *             : Jun 20, 2010, km; removed dependence on strings module;
 *             :   should work without change under ANS Forths which provides 
 *             :   VOCABULARY and sufficient dictionary space.
 *             : Sep 26, 2022, km; remove dependency on specific implementation
 *             :   of PTR; use POSTPONE instead of EVALUATE.
 * )

\ version 1.1a, 2003-04-15
\ Copyright (c) 199? David Sharp, 1994 Marcel Hendrix, and 2003 Krishna Myneni

(  COMMENTS FROM THE ORIGINAL CODE:
\ REVISION -lisp "=== Lisp-like Lists     Version 1.04 ==="

This is not LISP. The vocabulary contains words to define and process lists
of other lists, strings, and numbers. This is done using a model that
resembles LISP. Most notably, LISP functions are absent, because you should
use Forth for that.

The given list-processing tools are very nice, even when you leave out the
'oh boy, a Lisp written in Forth' hype. It could be immediately useful in some
sort of string package, database or AI-tool.

The biggest problem with the code is the garbage collector. It has crashed
on me occasionally. Please let me know if you succeed in making it more robust.
One cause for a crash is when you try to forget a list, that screws up the
administration of the heap and the gc algorithm fails.
A second cause is when you have mixed NEWLIST and SET-TO .
I strongly suspect a stack size / recursion problem for some degenerated
lists.
)

VOCABULARY LISP
ONLY  FORTH ALSO  LISP DEFINITIONS

DECIMAL

[UNDEFINED] a@ [IF]    \ provide kForth-compatible defns.
  [DEFINED] synonym [IF]
    synonym a@  @ 
    synonym ptr value
  [ELSE]
    : a@ @ ;
    : ptr value ;
  [THEN]
: allot? here swap allot ;
: nondeferred ;
[THEN]

variable dsign
: >d? ( c-addr u -- d flag ) 
    -trailing
    0 0 2swap
    \ skip leading spaces and tabs
    BEGIN over c@ dup BL = swap 9 = or WHILE 1 /string REPEAT
    ?dup IF
	FALSE dsign !
	over c@
	CASE
	    [char] - OF TRUE dsign ! 1 /string ENDOF
	    [char] + OF 1 /string ENDOF
	ENDCASE
	>number nip 0= IF
	  dsign @ IF dnegate THEN true
        ELSE false THEN
    ELSE drop false THEN ;

: 3dup ( a b c -- a b c a b c ) 2 pick 2 pick 2 pick ;

512 1024 *  CONSTANT HEAPSIZE
CREATE heap HEAPSIZE ALLOT
heap ptr hptr

\ halloc allocates specified number of bytes and returns
\   a *handle*. The address of the allocated region
\   may be fetched from the handle, and the size of the
\   allocated region is obtained from the handle by "size?".

: halloc ( u -- hndl | allocate u bytes in the heap )
    DUP >R hptr SWAP 2 CELLS + OVER + TO hptr
    hptr heap HEAPSIZE + >= ABORT" ERROR: HEAP OVERFLOW!" 
    DUP CELL+ CELL+ OVER ! DUP CELL+ R> SWAP ! ;

: size? ( hndl -- u | return size of region)
    postpone cell+ postpone @ ; immediate nondeferred

\ allocate a section of the heap for the linked lists

  16384 CONSTANT #LINKS       	\ 2-cells*#links must be less than HEAPSIZE
                                \ and, most likely, 2-cells*#links should be
                                \ less than half HEAPSIZE

2 cells CONSTANT LINKSIZE     	\ CDR and CAR - two pointers
      2 CONSTANT PROPERTIES   	\ two property bytes per atom$.

\ ---------------------------------------------------------------

\  NIL is the empty list, e.g  NIL -type ---> nil

\ NIL ( -- list )               \ LISP  "nil"
   0 ptr NIL                    \ see FREE-ALL-LINKS .

\ nil is used to mark the last cell of a list.
\ e.g. '( ape 123 '456 ) set-to hicky  hicky cdr cdr cdr -type ---> nil

: nil? ( list -- flag )                            \ LISP  "null"
        nil = ;

: null  nil = ;	\ same as nil?  for Common Lisp compatibility

#links linksize * halloc        \ This is our heap for links.
     ptr links			\ Rest is for atoms.

\ First link in list of free cells made by free-all-links.

variable  free-links
links ptr link-space	\ address of beginning of link space

(
free-all-links turns the space we allocated for links into one long linked
list, "free-links", which we then use as a reservoir of cells to construct
our own lists. When we are through with a particular cell, it can be
returned to the free links list by "cons-ing" it back to the beginning of
the free list with free-a-cell.
)

: free-all-links ( -- )                 \ LISP  "free-all-links"
        link-space
        #links linksize *   erase       \ init link-heap to 0's
        link-space   #links 1- 0        \ set up loop for all but last cell
        DO
          dup linksize + over !		\ each cell points to next
          linksize +			\ creating one long list of 0's
        LOOP
        ( ^last.cell ) TO nil
        nil  nil         !              \ last cell value is "nil" address
        nil  nil cell+   !              \  and contents
        link-space  free-links ! ;      \ make the first cell the value
                                        \ of free-link list
free-all-links


(
the terms cell, link and node are used pretty much interchangeably.
Let's call a cell a link when we are mainly concerned with its role as
a list member.
)

: free-a-cell ( cell -- )       \ returns "cell" to the free-links list
        free-links a@           \ get the current first cell  of free-links
        OVER !                  \ and have our cell point to it.
        free-links ! ;          \ make cell the first cell of free-links list

: get-a-cell ( -- cell )
        free-links a@           \ get 1st free-link
        DUP nil? ABORT" No more links"
        DUP a@ free-links ! ;   \ and make its cdr the new first free-link



(
 We accumulate atom$'s as strings, allocating out of the heap as we go,
 using "halloc" so that each atom$ has its own distinct "heap handle" which
 will be the string's value in a list.
 " 0 halloc TO atom$" will give us "atom$" as a marker to the 1st atom$
 handle. Note that "atom$ @" also marks the end of link space.
)

0 halloc ptr atom$

\ Allocate space for atom$ and its properties

: $>atom$ ( c-addr u -- hndl )
	DUP properties + halloc
	DUP >R a@			\ c-addr u 'heap --
	SWAP CMOVE R> ;			\ copy string 

: >$  ( hndl -- c-addr u)
	DUP a@ SWAP size? ;		\ hndl -- c-addr u

: atom$-length  ( hndl -- #characters )
        >$ nip properties - ;

: cons  ( ^val list1 -- list2 ) \ LISP  "cons"
        get-a-cell              \ ^val list cell
        DUP >R   !              \ "list" is now cdr in new cell
        R@ CELL+ !  R> ;

: $cons ( addr list -- list )		\ cons an atom$
	>R count $>atom$ R> cons ;

: quote-atom$ ( "name" -- hndl )	\ Lisp "quote-atom-string"
	bl word count $>atom$ ;

: (quote-number)  ( "numstr" -- list )     \ literal number-atoms go
        bl word count  >d? drop d>s  0 cons ;  \ into the list space with cdr=0
       
: $>hndl ( caddr u -- hndl )
	2dup >d? 
	if d>s >r 2drop r> 0 cons 
	else
	  2drop
	  over c@
	  [char] ' = if 1 /string then
	  $>atom$ then ;
  
: quote-atom    ( "str" -- hndl )       \ LISP  "quote-atom"
        bl word count $>hndl ;

: (quote-dot)   ( -- hndl )
        quote-atom  
        bl word drop \ consume the trailing ')'
;

: car ( list -- ^value )                        \ LISP  "car"
    state @ if postpone cell+ postpone a@ 
    else cell+ a@ then ; IMMEDIATE nondeferred

: first ( list -- ^value )                      \ LISP  "first"
    state @ if postpone cell+ postpone a@
    else cell+ a@ then ; IMMEDIATE nondeferred

: cdr ( list -- list )                          \ LISP  "c-d-r"
    state @ if postpone a@ else a@ then ; IMMEDIATE nondeferred

: rest ( list -- list )                         \ Common LISP  "rest"
    state @ if postpone a@ else a@ then ; IMMEDIATE nondeferred

: second ( list -- ^value )			\ LISP  "second"
    state @ if postpone a@ postpone cell+ postpone a@
    else a@ cell+ a@ then ; IMMEDIATE nondeferred 

: reverse  ( list -- reversed-list )    \ LISP  "reverse"
        nil swap
        BEGIN  dup nil? 0=
        WHILE  dup car rot cons swap cdr
        REPEAT drop ;

: atom$p  ( hndle|cell.value -- f )     \ LISP  "atom-string-pee"
	atom$ hptr within ;

: numberp   ( handle|cell.value -- f )  \ LISP  "number-pee"
        dup link-space atom$ a@
         within IF cdr 0=
              ELSE drop false
             THEN ;

: atomp ( hndle|cell.value -- f )       \ LISP  "atom-pee"
        dup atom$p swap numberp or ;

: atom atomp ;  \ for consistency with Common Lisp

: listp ( addr -- f )                   \ LISP  "list-pee"
        dup link-space atom$ a@
         within IF cdr 0<>
              ELSE nil?
             THEN ;

: dotp  ( list -- f )                   \ LISP  "dot-pee"
        cdr listp 0= ;

: latp  ( list -- f )                   \ LISP  "lat-pee"
         dup  nil?     IF  drop true  exit  THEN
         dup  listp 0= IF  drop false exit  THEN
         dup car atomp IF  cdr recurse
                     ELSE  drop false
                    THEN ;

: length  ( list -- n )                 \ LISP  "length"
        dup dotp IF drop 1 exit THEN
        0
        BEGIN  over nil? 0=
        WHILE  1+ swap cdr swap
        REPEAT nip ;


: #atoms  ( list -- n )		\ total number of atoms in a list
        0 swap
        dup nil?  IF  drop exit  THEN
        dup atomp IF  drop 1+
                ELSE  dup latp  IF  length + exit  THEN
                      dup   car recurse   rot +
                      swap  cdr recurse   +
               THEN ;

: plus  ( l-num1 l-num2 -- l-num3 )		\ LISP  "plus"
        car swap car + 0 cons ;

: zerop ( l-number -- flag )  car 0= ; 		\ LISP  "zero-pee"
        
: number-eq ( number.hndl1 number.hndl2 -- flag )
        car swap car = ;

: eq    ( atom1.hndl atom2.hndl -- flag )	\ LISP  "eq"
        2dup = IF 2drop true exit THEN \ same atom or list (or whatever)
        over atom$p                     \ if they are atom$'s then compare
        over atom$p  and                \ their contents, including properties.
           IF >$ rot >$ compare 0= exit \ we could subtract PROPERTIES
        THEN                           \ from counts if they're unimportant.
        over numberp
        over numberp  and
           IF number-eq  exit
        THEN
        2drop false ;

: list-equal    ( list1 list2 -- flag )    \ LISP  "list-equal"
        over nil?  over nil?
        and IF  2drop true exit  THEN  \ two nils?
        2dup = IF 2drop true exit THEN  \ save time if same list
        over car  over car
        eq IF  cdr swap  cdr recurse
         ELSE  over car listp   over car listp
              and IF  car swap  car recurse
                ELSE  2drop false exit
               THEN
        THEN ;

: equal  ( ^val1 ^val2 -- flag )		\ LISP "equal"
	2dup listp swap listp and IF list-equal ELSE eq THEN ;
	

: memberp ( expression list -- flag )		\ LISP  "member-pee"
        dup  nil?   IF 2drop false exit THEN
        2dup car eq IF 2drop true  exit THEN
        cdr recurse ;


: last  ( list -- last.member )			\ LISP  "last"
        dup nil? IF exit THEN
        dup listp 0= abort" LAST : not a list"
        BEGIN  dup cdr nil? 0=
        WHILE  cdr
        REPEAT ;


: nconc ( list1 list2 -- list1 )		\ LISP  "nconc"
        over listp  over listp  and 0= abort" Not a list, can't NCONC"
        dup  nil? IF drop nil cons car exit THEN
        over nil? IF nip ELSE over last ! THEN ;


: copy-list  ( list1 -- list1' )
        dup nil? IF exit THEN
        dup car dup listp if recurse THEN
        swap cdr recurse cons ;


: append ( list1 list2 -- list3 )		\ LISP "append"
        over listp  over listp  and 0= abort" Not a list, can't APPEND"
        dup  nil? IF drop copy-list exit THEN
        over nil? IF nip copy-list exit 
	  ELSE swap copy-list swap nconc
        THEN ;


: remove   ( atom list1 --- list2 )		\ LISP  "remove"
        dup nil? IF nip exit THEN
        dup car 2 pick eq IF  cdr recurse exit  THEN
        dup car -rot cdr recurse cons ;

: delete  ( atom list -- list )			\ LISP "delete"
	dup nil? IF nip exit THEN
	dup >r
	BEGIN
	  dup car 2 pick eq IF  \ atom link
	    dup cdr over linksize cmove
	  ELSE cdr THEN
	  dup nil?
	UNTIL
	2drop r> ;


: _substitute ( ^val1 ^val2 list -- )
        BEGIN  dup nil? 0=
        WHILE  dup car atomp
                   IF 2dup
                      car eq IF  2 pick over cell+ ! THEN
                THEN cdr
        REPEAT drop 2drop ;

: substitute ( ^val1 ^val2 list -- list )		\ LISP "substitute"
        dup listp 0= abort" not a list, can't SUBSTITUTE"
        dup >r _substitute r> ;

: _subst ( ^val1 ^val2 list -- )
        BEGIN  dup nil? 0=
        WHILE  dup car atomp
                   IF 2dup
                      car eq IF  2 pick over cell+ !  THEN
                 ELSE 3dup car recurse
                THEN cdr
        REPEAT drop 2drop ;


: subst ( ^val1 ^val2 list -- list )			\ LISP  "subst"
        dup listp 0= abort" not a list, can't SUBST"
        dup >r _subst r> ;


: position ( ^val1 list -- n | n is -1 if not found)	\ LISP "position"
    dup listp 0= abort" not a list, can't find POSITION"
    0 >r 
    BEGIN dup nil? 0= 
    WHILE dup car atomp
      IF  2dup car eq IF  2drop r> exit  THEN  THEN 
      r> 1+ >r cdr  
    REPEAT
    r> drop 2drop -1 ;

: position:test ( ^val1 list xt -- n | n is nil if found)
    over listp 0= abort" not a list, can't find POSITION"
    0 >r >r
    BEGIN dup nil? 0= 
    WHILE 2dup car r@ execute 
      IF  2drop r> drop r> exit  THEN
      r> r> 1+ >r >r cdr  
    REPEAT
    2r> 2drop 2drop -1 ;
    

: nth ( n list -- ^val )			\ LISP "nth"
    swap 0 ?do cdr loop car ;
            
: list  ( list1  list2 -- list3 )		\ LISP "list"
    swap nil cons swap nil cons append  ;


: member ( ^val list1 -- list2 )		\ LISP "member"
    dup >r position r> swap 
    dup -1 = IF 2drop nil ELSE 0 ?do cdr loop THEN ;

: member:test ( ^val list1 xt -- list2 )  \ LISP "member" with :test function
    over >r position:test r> swap 
    dup -1 = IF 2drop nil ELSE 0 ?do cdr loop THEN ;

: assoc ( -- )
;
    
: subsetp ( list1 list2 -- flag )		\ LISP "subsetp"
	2dup nil? swap nil? and IF 2drop true exit THEN  \ both are nil
	dup nil? IF 2drop false exit THEN
	over nil? IF 2drop true exit THEN  \ nil is a subset of non-empty set
	true >r swap
	BEGIN		\ list2 list1
	  dup nil? 0=
	WHILE
	  over over car swap memberp
	  r> and >r cdr
	REPEAT
	2drop r> ;


: set-difference ( list1 list2 -- list3 )	\ LISP "set-difference"
	dup nil? IF drop copy-list exit THEN
	over nil? IF drop exit THEN
	nil >r swap
	BEGIN		\ list2 list1
	  dup nil? 0=
	WHILE
	  dup car dup >r
	  2 pick memberp
	  IF  r> drop  ELSE  r> r> cons >r THEN cdr
	REPEAT 2drop r> ;

nil ptr temp-list
: set-difference:test  ( list1 list2 xt -- list3 )  \ LISP "set-difference" with test
        >r
	dup nil? IF drop copy-list r> drop exit THEN
	over nil? IF drop r> drop exit THEN
	nil to temp-list
	swap r>
	BEGIN  over nil? 0=  WHILE   	\ list2 list1 xt
		>r dup car dup >r
		2 pick 2r@ drop member:test nil? 0=
		IF  2r> drop  ELSE  2r> temp-list cons to temp-list THEN
		swap cdr swap
	REPEAT drop 2drop temp-list ;

 
: intersection ( list1 list2 -- list3 )		\ LISP "intersection"
	2dup nil? swap nil? or IF 2drop nil exit THEN
	nil >r
	BEGIN
	  dup nil? 0=
	WHILE
	  dup car dup >r 2 pick memberp
	  IF r> r> cons >r ELSE r> drop THEN
	  cdr
	REPEAT 2drop r> ; 	

: adjoin ( ^val list1 -- list2 )		\ LISP "adjoin"
	 2dup memberp  IF nip ELSE cons THEN ;

: union ( list1 list2 -- list3 )		\ LISP "union"
	dup nil? IF drop copy-list exit THEN
	over nil? IF nip copy-list exit THEN 
	BEGIN		\ list1 list2
	  dup nil? 0=
	WHILE 
	  dup car rot adjoin swap cdr
	REPEAT drop ;


: mapcar ( list1 xt -- list2 )			\  LISP  "mapcar" with one
    >r nil swap 				\    list argument
    BEGIN dup nil? 0=
    WHILE dup car r@ execute rot cons swap cdr 
    REPEAT drop r> drop reverse
;

: mapcar2 ( list1 list2 xt -- list3 ) 		\ LISP "mapcar" with two
    nil >r >r swap  				\    list arguments
    BEGIN dup nil? 0=
    WHILE dup car r@ execute rot cons swap cdr 
    REPEAT drop r> drop reverse						\   list args
;

: every  ( list xt -- flag )			\ LISP "every"
    >r true swap  \ flag list
    BEGIN dup nil? 0= 
    WHILE dup car r@ execute rot and swap cdr
    REPEAT drop r> drop ;

: some  ( list xt -- flag )			\ LISP "some"
    >r false swap
    BEGIN dup nil? 0=
    WHILE dup car r@ execute rot or swap cdr
    REPEAT drop r> drop ;
 
: reduce  ( n1|^val1|list1  list2  xt -- n2|^val2|list3 )     \ LISP "reduce"
    >r
    BEGIN dup nil? 0= 
    WHILE tuck first r@ execute swap rest
    REPEAT drop r> drop ;

0 value ]?

\ Create a list.
\ e.g. "quote-list ( snimp ( blaggle ) ( morkle . glork ) ( 22 skid doo )]"
\ "]" closes all right parentheses still open. Other special characters are
\ "@" and ".". "@L1" in the quoted list puts the already defined L1 into the
\ list and the quote character for an atomic string. "." creates a dotted pair.
\ The above list should print:
\ ( snimp ( blaggle ) ( morkle . glork ) ( #22 skid doo ) )

: quote-list    ( -- list )             \ LISP  "quote-list"
	false to  ]?
	nil
	begin
	  bl word count dup   \ list c-addr u u 
	  if  over c@
	    case		\ list c-addr u char
	      [char] (  of  2drop recurse swap cons false  endof
	      [char] )  of  2drop true                     endof
	      [char] ]  of  2drop true dup to ]?           endof
              [char] .  of  2drop (quote-dot) over ! true  endof
              [char] @  of  1 /string pad pack pad find
                            IF ( >body a@) execute ELSE drop nil THEN
                            swap cons false               endof
	      [char] "  of  2drop postpone s" $>hndl
	                    swap cons false	          endof
	      >r  $>hndl swap cons false r>
	    endcase
	    ]? if drop true then
	  else
	    2drop refill invert ( true)
	  then
	until
	dup dotp 0= if reverse then ;


: '(    ( -- list )             \ LISP  "quote-list"
        quote-list ;


: quote ( "str" -- list|^val )            \ LISP  "quote"
        bl word count dup
	IF  over c@
          CASE 
	    [char] (  of  2drop quote-list  endof
	    [char] "  of  2drop postpone s" $>hndl endof
	    >r  $>hndl  r>
	  ENDCASE 
	ELSE drop THEN ;

: make-non-atomic-list ( ^val1 ^val2 ... ^valn  n -- list )
    nil swap 0 ?do cons loop ;

: make-token-list ( a u -- list | make a flat list of tokens from a string )
	nil >r 
	begin  parse-token dup
	while  $>hndl r> cons >r	  
	repeat
	2drop 2drop r> reverse ;


: type-atom$    ( hndl -- )             \ display atom$
        >$ properties - type ;

: (type-car)    ( list -- )             \ display car of list
        dup nil? if drop exit THEN
        car dup numberp IF ." #" car .  \ type literal number
                      ELSE type-atom$ space
                     THEN ;

: _type-list    ( list -- )             \ the recursive part of TYPE-LIST
        dup nil? IF drop exit THEN
        dup car listp
        IF  dup car nil? 
	  IF ." nil "
          ELSE ." ( " dup car recurse ." ) "
          THEN
        ELSE  dup (type-car)
        THEN
        cdr dup atomp
	IF ." . " dup numberp	\ "dotted pairs"
	  IF ." #" cell+ @ . ELSE type-atom$ space THEN
	ELSE recurse 
	THEN ;


: type-list     ( list -- )             \ LISP  "type-list"
        dup listp 0= IF ." not a list "  drop exit THEN
        dup  nil?    IF ." nil"          drop exit THEN
        ." ( " _type-list  ." )" ;



: -type  ( expression -- )              \ LISP  "dash-type"
        dup numberp IF  ." #" car .     \ type literal number
                  ELSE dup listp
                             IF  type-list
                           ELSE  dup atom$p
                                     IF type-atom$
                                   ELSE ." ??"
                                  THEN
                          THEN
                 THEN ;

: print ( expression -- ) -type ;

: .stat ( -- )
     cr ." There are " free-links length 5 .r ."  links available."
     cr heap HEAPSIZE + hptr - 6 .r 
     ."  bytes are available for storing atoms." cr ;   

ALSO FORTH DEFINITIONS

