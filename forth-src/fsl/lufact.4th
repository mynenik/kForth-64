\ lufact      Does a LU factorization of a matrix

\ Forth Scientific Library Algorithm #33

\ lufact ( 'a{{ 'lu -- )
\     Factors matrix a{{ into the LUMATRIX stucture lu such that
\     a{{ = P L U   (P is a permutation matrix implied by the pivots)

\     The LUMATRIX data structure is initialized in one of two ways:
\        * Using lumatrix-init ( 'lu 'mat{{ 'piv{ n -- )
\          to build the LUMATRIX data structure in lu from existing
\          matrix mat{{ and integer array piv{ using size n.
\        * Using lu-malloc ( 'lu n -- )
\          to dynamically allocate the LUMATRIX data structure internals
\          for the structure 'dlu.  (In this case the space should
\          eventually be released with a call to lu-free ( 'lu -- ) ).

\     The routines, 'lu->l', 'lu->u' and 'lu->p' are provided to unpack the
\     appropriate component of the LU structure:
\ lu->l ( 'lu 'l{{ -- )
\     Fills the matrix l{{ with the L part of the LU structure.
\ lu->u ( 'lu 'u{{ -- )
\     Fills the matrix u{{ with the U part of the LU structure.
\ lu->p ( 'lu 'p{{ -- )
\     Fills the matrix p{{ with the P part of the LU structure.


\ This is an ANS Forth program requiring:
\      1. This is the integrated data/fp stack version
\      2. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\      3. Uses the words 'FLOAT' and ARRAY to create floating point arrays.
\      4. The word '}' to dereference a one-dimensional array.
\      5. Uses the words 'DARRAY' and '&!' to set array pointers.
\      6. Uses the FSL utility word '}}fcopy' to copy one (float) array to another
\      7. FSL data structures as given in structs.fth
\      8. The FSL dynamic allocation words '}malloc' and '}free' are needed if
\         the data structures are dynamically allocated with 'lu-malloc'
\      9. The compilation of the test code is controlled by VALUE TEST-CODE?
\         and the conditional compilation words in the Programming-Tools
\         wordset
\     10. The test code uses the FSL routine HILBERT to generate test matrices.


\  (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\  author to use this software for any application provided this
\  copyright notice is preserved.

\ Revisions:
\   2005-01-22  cgm; replaced obsolescent words
\   2005-08-28  km; ported to kForth
\   2005-09-06  km; define LUMATRIX, using Gforth structures
\   2006-10-31  km; include hilbert.4th, and use }}fput in test code
\   2007-09-14  km; replace test code with automated tests
\   2007-10-27  km; save base, switch to decimal, and restore base
\   2010-12-19  km; reintroduce Private: and Public: and revised test code
\   2011-09-16  km; use Neal Bridges' anonymous modules
\   2012-02-19  km; use KM/DNW's modules library     
\   2021-05-16  km; update for use in separate fp stack system.
\   2021-07-22  km; use Forth 200x data structures.
\   2023-12-11  km; use F+! to simplify calc.
CR .( LUFACT            V1.6j         11 December  2023   EFCikm)
BEGIN-MODULE

BASE @ DECIMAL

Public:

\ a data structure for LU factored matrices
begin-structure lumatrix%
      field:  ->matrix{{
      field:  ->pivot{
      field:  ->N                  \ the size of the matrix
      field:  ->status             \ = 0 if Ok
end-structure

: LUMATRIX  create lumatrix% allot ;  \ defining word for data structure

Private:

\ pointer to users LU data structure
VARIABLE LU

: LU@    LU a@ ;


INTEGER DARRAY  t-piv       \ temporaries used for the dynamic allocation
FLOAT   DMATRIX  t-mat      \ of the LU data structure

FLOAT   DMATRIX a{{         \ pointer to matrix to factor

FLOAT   DMATRIX matrix{{    \ pointer to LU ->matrix{{  for faster dereferencing
INTEGER DARRAY pivot{       \ pointer to LU ->pivot{

Public:

\ For aliasing the internal structures to pre-exisiting arrays
: lumatrix-init ( 'lu 'mat 'piv n -- )
        3 PICK >R    
        R@ ->N !             \ store N
        R@ ->pivot{ !        \ store pointer to pivot array
        R> ->matrix{{ !      \ store pointer to matrix
	DROP ;

\ For dynamically allocating the whole structure
: lu-malloc ( 'lu n -- )

     & t-piv OVER }malloc
     malloc-fail? ABORT" LU-MALLOC failure (1) "

     & t-mat OVER DUP }}malloc
     malloc-fail? ABORT" LU-MALLOC failure (2) "

     t-mat t-piv ROT lumatrix-init
;

\ for freeing a dynamically allocated structure
: lu-free ( 'lu -- )
     DUP ->matrix{{ a@   & t-mat &!  & t-mat }}free
     DUP ->pivot{   a@   & t-piv &!  & t-piv }free
     0 SWAP ->N !
;

Private:

: lufact-init ( 'a 'lu -- n )

    LU !
    & a{{ &!

    LU@  ->N @
    0 LU@  ->status !

    LU@ ->pivot{   a@  & pivot{    &!
    LU@ ->matrix{{ a@  & matrix{{  &!

    DUP
    
    a{{ matrix{{ ROT DUP }}fcopy ;

: lufact-finish ( n -- flag )
     1- DUP
     pivot{ OVER } !

     matrix{{ OVER DUP }} F@ F0= IF 
       LU@ ->status !
     ELSE
       DROP
     THEN

     LU@ ->status @ ;

FVARIABLE fpivot

: partial-pivot ( n k  -- n l )
        \ ." partial pivot k = " DUP . CR
        \ over DUP matrix{{ }}fprint

        0.0E0  fpivot F!
        DUP DUP
        3 PICK SWAP  DO
          matrix{{ I 3 PICK  }} F@ FABS
          fpivot F@ FOVER F< IF
            fpivot F! 
            DROP I
          ELSE FDROP
          THEN
        LOOP

         DUP ROT pivot{ SWAP } !
 \ ." l = " DUP . CR
;

: singular-pivot ( k -- )
     LU@ ->status ! ;

FVARIABLE ftemp

fp-stack? [IF]
: interchange ( n l k -- n )      
       2 PICK 0 DO  \ -- n l
           matrix{{ 2 PICK I }} DUP F@   \ -- n l a1 ; F: m[n,i]  
           matrix{{ 2 PICK I }} DUP F@   \ -- n l a1 a2 ; F: m[n,i]  m[l,i]
           SWAP F! F!
       LOOP
       2DROP ;
[ELSE]
: interchange ( n l k -- n )

        \ OVER OVER ." interchanging k = " . ." l = " . CR

        2 PICK 0 DO
           matrix{{ 2 PICK I }} DUP F@  ftemp F!
           matrix{{ 2 PICK I }} DUP F@  2>R
           SWAP 2R> ROT F!  ftemp F@ ROT F!
       LOOP
       2DROP ;
[THEN]

FVARIABLE fscale1
FVARIABLE fscale2 

: scale-row ( n k -- n )

       \ ." scale-row, k = " DUP . CR

       matrix{{ OVER DUP }} F@ 1.0E0 FSWAP F/ fscale1 F!
       
       2DUP 1+ DO
         matrix{{ I 2 PICK }} DUP >R F@ fscale1 F@ F*
         FDUP  fscale2 F! R> F!

         OVER OVER 1+ DO
           matrix{{ OVER I }} F@ fscale2 F@ F* FNEGATE 
           matrix{{ J I }} F+!
         LOOP
              
       LOOP

     DROP ;


\ Make an NxN identity matrix
0 ptr m{{

: build-identity ( 'p n -- 'p )
     SWAP TO m{{
     0 DO
       I 1+ 0 DO
         I J = IF
           1.0E0 m{{ I J }} F!
         ELSE
           0.0E0 m{{ J I }} F!
           0.0E0 m{{ I J }} F!
         THEN
       LOOP
     LOOP ;

fp-stack? [IF] 
: column_swap ( 'p n k1 k2 -- 'p n )
     2 PICK 0 DO
       3 PICK I 3 PICK }} DUP F@  \ -- 'p n k1 k2 a1  F: p{{ I k1 }}
       4 PICK I 3 PICK }} DUP F@  \ -- 'p n k1 k2 a1 a2  F: p{{ I k1 }} p{{ I k2 }}
       SWAP F! F!
     LOOP
     2DROP ;
[ELSE]
: column_swap ( 'p n k1 k2 -- 'p n )
     2 PICK 0 DO
       3 PICK I 3 PICK }} DUP F@ ftemp F!
       4 PICK I 3 PICK }} DUP F@ 2>R
       SWAP 2R> ROT F! ftemp F@ ROT F!
     LOOP
     2DROP ;
[THEN]

Public:

: lufact ( 'a 'lu --  )

     lufact-init

     DUP 2 < IF
       lufact-finish
       ABORT" lufact failed! (1) "
     THEN

     DUP 1- 0 DO
       I partial-pivot

       matrix{{ OVER I }} F@ F0= IF
         DROP I singular-pivot
       ELSE
         I OVER = IF
           DROP
         ELSE
           I interchange
         THEN

         I scale-row

       THEN
     LOOP

     lufact-finish

     ABORT" lufact failed! (2) " ;


\ Unpack L matrix from LU structure
: LU->L  ( 'lu 'l{{ -- ) 
         >R
         DUP  ->matrix{{ a@    \ get base address of matrix
         >R
         ->N @                 \ get N
         R> R>

         ROT 0 DO
           I 1+ 0 DO
             I J = IF
               DUP I J }} >R 1.0E0 R> F!
             ELSE
               DUP I J }} >R 0.0E0 R> F!
               OVER  J I }} F@  ftemp F! 
               DUP J I }} >R ftemp F@ R> F!
             THEN
           LOOP
         LOOP

         2DROP ;

\ unpack U matrix from LU struture
: LU->U  ( 'lu 'u{{ -- )         
         >R
         DUP  ->matrix{{ a@    \ get base address of matrix
         >R
         ->N @                 \ get N
         R> R>

         ROT 0 DO
           I 1+ 0 DO
             DUP J I }} >R 0.0E0 R> F!
             OVER  I J }} F@  ftemp F! 
             DUP I J }} >R ftemp F@ R> F!
           LOOP
         LOOP

         2DROP ;

\ Extract P matrix from LU struture
: LU->P  ( 'lu 'p{{ -- )         
         >R
         DUP  ->pivot{    \ get base address of pivot
         >R
         ->N @            \ get N
         R> R>

         ROT DUP >R          ( 'pivot 'p n )
         build-identity     \ build identity matrix first
        
         R>

         \ now swap the appropriate columns
         DUP 0 DO
           2 PICK I } @ I OVER OVER =
           IF  2DROP   ELSE  column_swap   THEN
         LOOP

         DROP 2DROP ;

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]
    include ttester
    include fsl/fsl-test-utils
[THEN]
[undefined] hilbert [IF] include fsl/hilbert  [THEN]
BASE @ DECIMAL

1e-14 abs-near F!
1e-14 rel-near F!
set-near

4 4 FLOAT   matrix  mat{{
4 4 FLOAT   matrix  lmat{{
  4 INTEGER array   piv{

3 3 FLOAT   matrix  mat3{{
	2.0e0  3.0e0  -1.0e0 
        4.0e0  4.0e0  -3.0e0
       -2.0e0  3.0e0  -1.0e0
3 3 mat3{{ }}fput

\ actual LU FACTORED 3x3 matrix
3 3 FLOAT MATRIX actual-3{{
       4.0e      4.0e      -3.0e
      -0.5e      5.0e      -2.5e
       0.5e      0.2e       1.0e 
3 3 actual-3{{ }}fput

LUMATRIX lu4

\ actual LU FACTORED 4x4 matrix:
4 4 FLOAT MATRIX actual-4{{
       1.0e         1/2          1/3              1/4  
       1/3          1e 12e f/    4e 45e f/        1e 12e f/ 
       1/2          1.0e        -1e 180e f/      -1e 120e f/ 
       1/4          0.90e       -0.6e             1e 2800e f/ ( 0.00357e) 
4 4 actual-4{{ }}fput

CR
TESTING LUMATRIX-INIT  LUFACT  LU-MALLOC  LU-FREE
t{ lu4 lmat{{ piv{ 3 lumatrix-init -> }t   \ aliasing lu to pre-existing arrays
t{ mat3{{ lu4 lufact -> }t
3 3 CompareMatrices lmat{{ actual-3{{

t{ lu4 lmat{{ piv{ 4 lumatrix-init -> }t   \ aliasing lu to pre-existing arrays
t{ mat{{ 4 hilbert ->  }t
t{ mat{{ lu4 lufact -> }t
4 4 CompareMatrices lmat{{  actual-4{{ 

t{ lu4 4 lu-malloc  ->  }t                  \ uses dynamically allocated space
t{ mat{{ 4 hilbert  ->  }t
t{ mat{{ lu4 lufact ->  }t

FLOAT DMATRIX mx{{
t{ lu4 ->matrix{{ @  & mx{{  &! -> }t   \ must use ->MATRIX{{ to get to the matrix
4 4 CompareMatrices mx{{ actual-4{{
t{ lu4 lu-free -> }t

BASE !
[THEN]

