\ ans-words.4th
\
\ Some ANS Forth words which are not a part of the intrinsic
\ dictionary of kForth are implemented here in source code.
\ Use with kForth version 1.4.x or higher.
\
\ Some other words, which are not part of the ANS specification,
\ but which are so commonly used that they are effectively
\ standard Forth words, are also defined here.
\
\ Also, see the following files for the source code definitions 
\ of other ANS Forth words which are not a part of kForth's 
\ dictionary:   
\ 
\     strings.4th 
\     files.4th 
\     ansi.4th 
\     dump.4th
\
\ Copyright (c) 2002--2021 Krishna Myneni
\
\ Provided under the GNU Lesser General Public License (LGPL)
\
\ Revisions:
\   2002-09-06  Created    km
\   2002-10-27  added F~   km
\   2003-02-15  added D2*, D2/, DMIN, DMAX, 2CONSTANT, 2VARIABLE, 
\                 2LITERAL  km
\   2003-03-02  fixed F~ for case of exact equality test  km
\   2003-03-09  added >NUMBER, DEFER, and IS  km
\   2003-09-28  added [IF], [ELSE], [THEN]  km
\   2004-09-10  added CATCH and THROW  km
\   2005-09-19  added [DEFINED] and [UNDEFINED]  km
\   2005-09-28  commented out defn of D>S km
\   2006-04-06  replaced M*/ by UDM* for ppc version dnw
\   2006-04-09  removed DMIN, DMAX, now intrinsic dnw
\   2006-05-30  commented out MOVE, now intrinsic km
\   2007-07-15  removed obsolete defs, which were commented out  km
\   2008-03-16  removed 2CONSTANT and 2VARIABLE, now intrinsic  km
\   2008-03-28  removed 2LITERAL, now intrinsic  km
\   2009-09-20  removed >NUMBER, now intrinsic  km
\   2009-09-26  removed WITHIN, now intrinsic  km
\   2009-10-01  modified [ELSE] to be case insensitive  km
\   2009-11-26  removed D2* and D2/, now intrinsic  km
\   2010-12-23  added $ucase and revised [ELSE] to use $ucase  km
\   2011-02-05  km  removed [DEFINED] and [UNDEFINED], now intrinsic 
\   2020-01-21  km  added SYNONYM
\   2020-01-25  km  revised defn. of VALUE for improved efficiency.
\   2021-05-08  km  added defn. of F~ for 64-bit separate fp stack.
\   2021-07-11  km  add DEFER@ and DEFER! and ACTION-OF.
\                   use standard definition of IS .
\   2021-07-13  km  added alignment words (for structures support).
\   2021-08-14  km  fix of FP@ required change to F~
\   2021-09-18  km  replace instances of ?ALLOT with ALLOT?
BASE @
DECIMAL

\ ============== From the CORE wordset

: SPACE BL EMIT ;
: CHARS ;

\ ============ From the CORE EXT wordset

CREATE PAD 512 ALLOT

: TO ' >BODY STATE @ IF POSTPONE LITERAL POSTPONE ! ELSE ! THEN ; IMMEDIATE
: VALUE CREATE 1 CELLS allot? ! IMMEDIATE DOES> POSTPONE LITERAL POSTPONE @ ;

\ ============== Alignment words: from CORE and Extended Wordsets
: UNITS-ALIGNED ( a xt -- a' )
   >R ?DUP IF 
     1- 1 R@ EXECUTE / 1+ R> EXECUTE 
   ELSE R> DROP 0 THEN ;

: ALIGNED   ( a -- a' ) ['] CELLS   UNITS-ALIGNED ;
: FALIGNED  ( a -- a' ) ['] FLOATS  UNITS-ALIGNED ;
: SFALIGNED ( a -- a' ) ['] SFLOATS UNITS-ALIGNED ;
: DFALIGNED ( a -- a' ) ['] DFLOATS UNITS-ALIGNED ;

\ ============ From the PROGRAMMING TOOLS wordset

\ $ucase is not a standard word; it is provided here as a helper.
: $ucase ( a u -- a u )  \ transform string to upper case
     2DUP  0 ?DO                    
       DUP C@ 
       DUP [CHAR] a [ CHAR z 1+ ] LITERAL WITHIN 
       IF 95 AND THEN OVER C! 1+
     LOOP  DROP ;

( see DPANS94, sec. A.15)

: [ELSE]  ( -- )
    1 BEGIN                                  \ level
      BEGIN
        BL WORD COUNT DUP  WHILE            \ level adr len
            $ucase
	    2DUP  S" [IF]"  COMPARE 0=
            IF                               \ level adr len
              2DROP 1+                       \ level'
            ELSE                             \ level adr len
	      2DUP  S" [ELSE]"  COMPARE 0=
	      IF                             \ level adr len
                2DROP 1- DUP IF 1+ THEN      \ level'
	      ELSE                           \ level adr len
	        S" [THEN]"  COMPARE 0=
	        IF                           \ level
                  1-                         \ level'
                THEN
              THEN
            THEN ?DUP 0=  IF EXIT THEN       \ level'
      REPEAT  2DROP                          \ level
    REFILL 0= UNTIL                          \ level
    DROP
;  IMMEDIATE

: [IF]  ( flag -- )
   0= IF POSTPONE [ELSE] THEN ;  IMMEDIATE

: [THEN]  ( -- )  ;  IMMEDIATE

\ Forth-2012 Programming Tools 15.6.2.2264
: SYNONYM ( "<newname>" "<oldname>" -- )
   CREATE ' 1 CELLS allot? ! DOES> a@ EXECUTE ; 

\ ============ From the FLOATING EXT wordset

[DEFINED] FDEPTH [IF]
\ Separate FP stack version of F~
fvariable r3
fvariable rhs
1 CELLS 8 = [IF]  \ 64-bit, separate stack version
: F~ ( -- flag ) ( F: r1 r2 r3 -- )
    fdup r3 f!  \ ( -- flag1 ) ( F: -- r1 r2 )
    f0> IF  f- fabs r3 f@ f<
    ELSE
      r3 f@ 
      f0= IF  
        fp@ 
        dup >r @ r> dfloat+ @ =
        f2drop
      ELSE  
        fover fabs fover fabs f+ r3 f@ fabs f* rhs f!
        f- fabs rhs f@ f<
      THEN
    THEN ;
[THEN]
[ELSE]
\ Integrated stack, 32-bit version of F~
: F~ ( r1 r2 r3 -- flag )
     FDUP F0> 
     IF 2>R F- FABS 2R> F<
     ELSE FDUP F0=
       IF FDROP		  \ are f1 and f2 *exactly* equal 
         ( F=)		  \ F= cannot distinguish between -0e and 0e
	 D=
       ELSE FABS 2>R FOVER FABS FOVER FABS F+ 2>R
         F- FABS 2R> 2R> F* F<
       THEN
     THEN ;
[THEN]

\ ============= From the EXCEPTION wordset
( see DPANS94, sec. A.9 )

variable handler
: empty-handler ;

' empty-handler  handler !

: CATCH ( xt -- exception# | 0 )
    SP@ >R  ( xt )  \ save data stack pointer
    HANDLER a@ >R   \ and previous handler
    RP@ HANDLER !   \ save return point for THROW
    EXECUTE	    \ execute returns if no THROW
    R> HANDLER !    \ restore previous handler
    R> DROP         \ discard saved state
    0               \ normal completion
;

: THROW ( ??? exception# -- ??? exception# )
    ?DUP IF
      HANDLER a@ RP!   \ restore previous return stack
      R> HANDLER !     \ restore prev handler
      R> SWAP >R
      SP! DROP R>      \ restore stack
        \  Return to the caller of CATCH because return
        \  stack is restored to the state that existed
        \  when CATCH began execution
    THEN
;

\ ============= Forth 200x Standard Words

: DEFER  ( "name" -- )
      CREATE 1 CELLS allot? ['] ABORT SWAP ! 
      DOES> ( ... -- ... ) a@ EXECUTE ;

: DEFER@ ( xt1 -- xt2 )  >BODY a@ ;
: DEFER! ( xt2 xt1 -- )  >BODY ! ;

: IS  ( xt "name" -- )
    STATE @ IF
      POSTPONE ['] POSTPONE DEFER!
    ELSE
      ' DEFER!
    THEN ; IMMEDIATE

: ACTION-OF ( "name" -- xt )
    STATE @ IF
      POSTPONE ['] POSTPONE DEFER@
    ELSE
      ' DEFER@
    THEN ; IMMEDIATE
 
\ === Non-standard words commonly needed for kForth programs ===
: PTR ( a "name" -- ) CREATE 1 CELLS allot? ! DOES> a@ ;

BASE !
