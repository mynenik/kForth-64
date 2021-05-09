\ fsl-util.4th
\
\ An auxiliary file for the Forth Scientific Library
\ For kForth
\
\ Contains commonly needed definitions for the FSL modules.

\
\ dxor, dor, dand           double xor, or, and
\ sd*                       single * double = double_product
\ v: defines use( &         For defining and settting execution vectors
\ %                         Parse next token as a FLOAT
\ S>F  F>S                  Conversion between (single) integer and float
\ F,                        Store FLOAT at (aligned) HERE
\ F=                        Test for floating point equality
\ -FROT                     Reverse the effect of FROT
\ F2*  F2/                  Multiply and divide float by two
\ F2DUP                     FDUP two floats
\ F2DROP                    FDROP two floats
\ INTEGER, DOUBLE, FLOAT    For setting up ARRAY types
\ ARRAY DARRAY              For declaring static and dynamic arrays
\ }                         For getting an ARRAY or DARRAY element address
\ &!                        For storing ARRAY aliases in a DARRAY
\ PRINT-WIDTH               The number of elements per line for printing arrays
\ }FPRINT                   Print out a given array
\ }FCOPY
\ }FPUT
\ Matrix                    For declaring a 2-D array
\ }}                        gets a Matrix element address
\ }}FPRINT
\ }}FCOPY
\ }}FPUT
\ Public: Private: Reset_Search_Order   controls the visibility of words
\ frame| |frame             sets up/removes a local variable frame
\ a b c d e f g h           local FVARIABLE values
\ &a &b &c &d &e &f &g &h   local FVARIABLE addresses


\ This code conforms with ANS requiring:
\     	1. The Floating-Point word set
\       2. The words umd* umd/mod and d* are implemented
\          for ThisForth in the file umd.fo

\ This code is released to the public domain Everett Carter July 1994
\
\ Revisions:
\   1996-06-12  efc; Revision 1.17
\   2003-03-18  km;  Adapted for kForth
\   2003-11-16  km;  Fixed bug in }}, added }}FCOPY
\   2005-09-18  km;  Added }FPUT and }}FPUT, [DEFINED] and [UNDEFINED]
\   2005-09-19  km;  Removed DEFINED and ~DEFINED; moved [DEFINED] to ans-words.4th
\   2005-09-28  km;  Moved [UNDEFINED] to ans-words.4th
\   2006-10-31  km;  added PTR  (since it is widely used in kForth FSL routines)
\   2007-10-31  km;  revised implementation of floating point locals to work with
\                    kForth; implementation is not fully tested, and it is not
\                    loaded by default.
\   2008-03-08  km;  revised implementation of "}" and "}}" for higher efficiency.
\   2008-07-04  km;  removed defn of FLITERAL; intrinsic in kForth v >= 1.4.2
\   2009-10-06  km;  removed conditional defn of FLOATS; intrinsic in kFORTH v 1.5.x
\   2010-04-29  km;  uncommented search order control words for kForth v 1.5.x;
\                      also made defn of F2DROP conditional
\   2011-09-16  km;  commented out the original FSL code and data hiding
\                      mechanism in favor of Neal Bridges' anonymous module
\                      methods; requires revision of FSL modules.
\   2011-10-11  km;  replace Neal Bridges' modules.4th with KM's version
\                      of DNW's root-module.fs: modules.4th. No further revisions 
\                      needed to the FSL modules with this change.
\   2012-02-19  km;  we are now using the modules library of KM and DNW,
\                    modules.fs; see "A Forth Modules System with Name
\                    Reuse".
\   2017-05-03  km;  ARRAY now gives warning when creating zero length arrays,
\                    and aborts for negative array lengths. MATRIX now gives
\                    warning when creating matrix with zero number of rows and/or
\                    zero number of columns, and aborts for negative row or
\                    column count.
\   2017-05-19  km;  add the constant DFLOAT which has the value 1 DFLOATS.
\   2019-10-29  km;  conditional def. of F2DUP (intrinsic to some Forths).
\   2021-05-09  km;  provide defs. of  }FCOPY and }FPUT for separate FP stack. 
\ ================= kForth specific defs/notes ==============================
\ Requires ans-words.4th

[undefined] ptr [IF] : ptr create 1 cells allot? ! does> a@ ; [THEN]
\ ================= end of kForth specific defs ==============================

CR .( FSL-UTIL          V1.3           09 May 2021   EFC, KM )
BASE @ DECIMAL

\ ================= compilation control ======================================

\ for control of conditional compilation of test code
FALSE VALUE TEST-CODE?
FALSE VALUE ?TEST-CODE           \ obsolete, for backward compatibility


\ for control of conditional compilation of Dynamic memory
TRUE CONSTANT HAS-MEMORY-WORDS?

\ =============================================================================

\ FSL NonANS words

[undefined] s>f [IF] : s>f    S>D D>F ;  [THEN]

\ The following has been superceded by use of KM's modules.4th

0 [IF]    \ original FSL private wordlist methods
WORDLIST ptr hidden-wordlist

: Reset-Search-Order
	FORTH-WORDLIST 1 SET-ORDER
	FORTH-WORDLIST SET-CURRENT
;

: Public:
	FORTH-WORDLIST hidden-wordlist 2 SET-ORDER
	FORTH-WORDLIST SET-CURRENT
;

: Private:
	FORTH-WORDLIST hidden-wordlist 2 SET-ORDER
	hidden-wordlist SET-CURRENT
;

: Reset_Search_Order   Reset-Search-Order ;     \ these are
[ELSE]
\ Use KM/DNW's modules interface
[undefined] begin-module [IF] s" modules.4th" included [THEN]

[THEN]

CREATE fsl-pad	84 CHARS ( or more ) ALLOT

\ umd/mod     ( uquad uddiv -- udquot udmod ) unsigned quad divided by double
\ umd*        ( ud1 ud2 -- qprod )            unsigned double multiply
\ d*          ( d1 d2   -- dprod )            double multiply

: dxor       ( d1 d2 -- d )             \ double xor
	ROT XOR >R XOR R>
;

: dor       ( d1 d2 -- d )              \ double or
	ROT OR >R OR R>
;

: dand     ( d1 d2 -- d )               \ double and
	ROT AND >R AND R>
;

: d>  2SWAP D< ;  \ == fixme ==> should use D<=

\ : 2+    2 + ;
\ : >=     < 0= ;                        \ greater than or equal to
\ : <=       > 0= ;                        \ less than or equal to

\ single * double = double
: sd*   ( multiplicand  multiplier_double  -- product_double  )
    2 PICK * >R   UM*   R> + ;

: CELL-    [ 1 CELLS ] LITERAL - ;           \ backup one cell

0 VALUE TYPE-ID               \ for building structures
FALSE VALUE STRUCT-ARRAY?

\ for dynamically allocating a structure or array

TRUE  VALUE is-static?     \ TRUE for statically allocated structs and arrays
: dynamic ( -- )     FALSE TO is-static? ;

\ size of a regular integer
1 CELLS CONSTANT INTEGER

\ size of a double integer
2 CELLS CONSTANT DOUBLE

\ size of a default float
1 FLOATS CONSTANT FLOAT

\ size of an IEEE double-precision float
1 DFLOATS CONSTANT DFLOAT

\ size of a pointer (for readability)
1 CELLS CONSTANT POINTER

\ : % BL WORD COUNT >FLOAT 0= ABORT" NAN"
\                  STATE @ IF POSTPONE FLITERAL THEN ; IMMEDIATE
                  
: -FROT    FROT FROT ;
: F2*   2.0e0 F*     ;
: F2/   2.0e0 F/     ;
[undefined] F2DUP  [IF] : F2DUP     FOVER FOVER ; [THEN]
[undefined] F2DROP [IF] : F2DROP    FDROP FDROP ; [THEN]

\ : F,   HERE FALIGN 1 FLOATS ALLOT F! ;
\ 3.1415926536E0 FCONSTANT PI
[undefined] PI [IF] -1E FACOS FCONSTANT PI [THEN]
1.0E0 FCONSTANT F1.0

\ 1-D array definition
\    -----------------------------
\    | cell_size | data area     |
\    -----------------------------

\ monotype array
: MARRAY ( n cell_size -- | -- addr ) 
    CREATE
      \ DUP , * ALLOT
    2DUP SWAP 1+ * ?ALLOT ! DROP
    DOES> CELL+ ;

\    -----------------------------
\    | id | cell_size | data area |
\    -----------------------------

\ structure array
: SARRAY ( n cell_size -- | -- id addr ) 
    CREATE
      \ TYPE-ID ,
      \ DUP , * ALLOT
    2DUP SWAP 2+ * ?ALLOT
    TYPE-ID OVER !
    CELL+ ! DROP
     DOES> DUP @ SWAP [ 2 CELLS ] LITERAL + ;


: ARRAY ( n cell_size -- )  \ n >= 0
     OVER 0= IF cr ." WARNING: Creating zero length array!" THEN
     OVER 0< ABORT" Negative array length!"
     STRUCT-ARRAY? IF
       SARRAY FALSE TO STRUCT-ARRAY?
     ELSE MARRAY
     THEN ;

\ word for creation of a dynamic array (no memory allocated)

\ Monotype
\    ------------------------
\    | data_ptr | cell_size |
\    ------------------------

: DMARRAY   ( cell_size -- )   
    CREATE  
    \ 0 , ,
    2 CELLS allot?
    0 OVER ! CELL+ !
    DOES>  a@ CELL+  ;

\ Structures
\    ----------------------------
\    | data_ptr | cell_size | id |
\    ----------------------------

: DSARRAY   ( cell_size -- )  
    CREATE  
    \ 0 , , TYPE-ID ,
    3 CELLS ?ALLOT
    0 OVER ! CELL+ SWAP OVER !
    TYPE-ID SWAP CELL+ !
    DOES>
      DUP [ 2 CELLS ] LITERAL + @ SWAP @ CELL+ ;


: DARRAY   ( cell_size -- )
    STRUCT-ARRAY? IF
      DSARRAY FALSE TO STRUCT-ARRAY?
    ELSE DMARRAY
    THEN ;


\ word for aliasing arrays,
\  typical usage:  a{ & b{ &!  sets b{ to point to a{'s data

: &!  ( addr_a &b -- )  SWAP CELL- SWAP >BODY  ! ;

\ word that fetches 1-D array addresses
: }   ( addr n -- addr[n] ) OVER [ 1 CELLS ] LITERAL - @ * + ;

VARIABLE print-width      6 print-width !

: }fprint ( n addr -- )       \ print n elements of a float array
    SWAP 0 DO 
      I print-width @ MOD 0= I AND IF CR THEN
      DUP I } F@ F. 
    LOOP DROP ;

: }iprint ( n addr -- )       \ print n elements of an integer array
    SWAP 0 DO 
      I print-width @ MOD 0= I AND IF CR THEN
      DUP I } @ . 
    LOOP  DROP  ;

[DEFINED] FDEPTH [IF]

\ copy one array into another
: }fcopy ( 'src 'dest n -- ) 
    >R SWAP R>
    0 ?DO  2DUP I } F@ I } F!  LOOP 2DROP ;

\ store r1 ... r_n into array of size n 
: }fput ( n 'a -- ) ( F: r1 ... r_n -- ) 
    SWAP DUP 0 ?DO  1- 2DUP } F! LOOP  2DROP ;

[ELSE]

: }fcopy ( 'src 'dest n -- ) 
    >R SWAP R>
    0 ?DO  2DUP I } F@ ROT I } F!  LOOP  2DROP ;

\ store r1 ... r_n into array of size n
: }fput ( r1 ... r_n n 'a -- ) 
    SWAP DUP 0 ?DO  1- 2DUP 2>R } F! 2R>  LOOP  2DROP ;
[THEN]

\ 2-D array definition,

\ Monotype
\    ------------------------------
\    | m | cell_size |  data area |
\    ------------------------------

\ defining word for a 2-d matrix
: MMATRIX  ( n m size -- ) 
    CREATE
    \ OVER , DUP ,
    \ * * ALLOT
    >R 2DUP * R@ * 2 CELLS + ?ALLOT
    2DUP ! CELL+ R> SWAP ! 2DROP
    DOES>  [ 2 CELLS ] LITERAL + ;

\ Structures
\    -----------------------------------
\    | id | m | cell_size |  data area |
\    -----------------------------------

\ defining word for a 2-d matrix
: SMATRIX  ( n m size -- ) 
    CREATE 
    \ TYPE-ID ,
    \ OVER , DUP ,
    \ * * ALLOT
    >R 2DUP * R@ * 3 CELLS + allot?
    TYPE-ID OVER ! CELL+ 2DUP ! CELL+ R> SWAP ! 2DROP
    DOES>  DUP @ TO TYPE-ID [ 3 CELLS ] LITERAL + ;

\ defining word for a 2-d matrix
: MATRIX  ( n m size -- ) 
     >r 2dup 0= swap 0= or IF 
       ." WARNING: Creating matrix with zero rows or zero columns!"
     THEN 
     2dup 0< swap 0< or ABORT" Negative row or column count!"
     r>
     STRUCT-ARRAY? IF 
       SMATRIX FALSE TO STRUCT-ARRAY?
     ELSE MMATRIX
     THEN ;

: DMATRIX ( size -- )  DARRAY ;

\ word to fetch 2-D array addresses
: }}  ( addr i j -- addr[i][j] ) 
    >R >R
    DUP [ 2 CELLS ] LITERAL - 2@     \ &a[0][0] size m
    R> * R> + * + ;

\ print nXm elements of a float 2-D array
: }}fprint ( n m addr -- ) 
    ROT ROT SWAP 
    0 DO  DUP 
       0 DO
         OVER J I  }} F@ F.
       LOOP  CR
     LOOP
     2DROP ;

\ copy n m elements of 2-D array src to dest
: }}fcopy ( 'src 'dest n m  -- ) 
    SWAP 0 DO
      DUP 0 DO
        2 PICK J I  }} F@
        3 PICK J I  }} F!
      LOOP
    LOOP
    DROP 2DROP ;

\ store r11 ... r_nm into nxm matrix
: }}fput ( n m 'A -- ) ( F: r11 r12 ... r_nm -- ) 
     -ROT 2DUP * >R 1- SWAP 1- SWAP }} R> 
     0 ?DO  DUP >R F! R> FLOAT -  LOOP  DROP ;

: noop ; 

: use(  STATE @ IF POSTPONE ['] ELSE ' THEN ;  IMMEDIATE
: &     POSTPONE use( ; IMMEDIATE


(
  Code for local fvariables, loosely based upon Wil Baden's idea presented
  at FORML 1992.
  The idea is to have a fixed number of variables with fixed names.
  I believe the code shown here will work with any, case insensitive,
  ANS Forth.

  i/tForth users are advised to use FLOCALS| instead.

  example:  : test  2e 3e FRAME| a b |  a f. b f. |FRAME ;
            test <cr> 3.0000 2.0000 ok

  PS: Don't forget to use |FRAME before an EXIT .
)

\ Don't load flocals implementation by default.
\ The user can alter the statement below if desired.
0 [IF]    
    
0 ptr frame-ptr
8 CONSTANT /flocals
0 value flocal_cnt

: (frame-alloc) ( -- ptr )
    frame-ptr  R> SWAP >R >R  \ save current frame pointer
    /flocals FLOATS ALLOCATE ABORT" Unable to allocate frame"
    TO frame-ptr
    0 TO flocal_cnt ;

: (frame) ( n -- )
    drop ;

: F, ( f -- )
    frame-ptr flocal_cnt FLOATS + F!
    flocal_cnt 1+ TO flocal_cnt
;

: FRAME| ( -- )
    POSTPONE (frame-alloc)    \ In kForth, we must allocate beforehand

    0 >R
    BEGIN   BL WORD  COUNT  1 =
	    SWAP C@  [CHAR] | =
	    AND 0= 
    WHILE   POSTPONE F,  R> 1+ >R
    REPEAT
    /flocals R> - DUP 0< ABORT" too many flocals"
    POSTPONE LITERAL  POSTPONE (frame) ; IMMEDIATE

: |FRAME ( -- )
    frame-ptr FREE drop
    R> R> TO frame-ptr >R   \ restore previous frame pointer
;

: &a  frame-ptr ;
: &b  frame-ptr [ 1 FLOATS ] LITERAL + ;
: &c  frame-ptr [ 2 FLOATS ] LITERAL + ;
: &d  frame-ptr [ 3 FLOATS ] LITERAL + ;
: &e  frame-ptr [ 4 FLOATS ] LITERAL + ;
: &f  frame-ptr [ 5 FLOATS ] LITERAL + ;
: &g  frame-ptr [ 6 FLOATS ] LITERAL + ;
: &h  frame-ptr [ 7 FLOATS ] LITERAL + ;

: a   &a F@ ;
: b   &b F@ ;
: c   &c F@ ;
: d   &d F@ ;
: e   &e F@ ;
: f   &f F@ ;
: g   &g F@ ;
: h   &h F@ ;

[THEN]

BASE !
