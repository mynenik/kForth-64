\ pcylfun     Parabolic Cylinder Functions U and V,
\             plus related confluent hypergeometric functions

\ Forth Scientific Library Algorithm #20

\ Evaluates the Parabolic Cylinder functions,
\     Upcf              U(nu,x)
\ and 
\     Vpcf              V(nu,x)
\ In addition the following related functions are provided,
\ U()        U(a,b,x)      Hypergeometric function U for real args
\ M()        M(a,b,x)      Hypergeometric function M for real args
\ Wwhit      W(k,mu,z)     Whittaker function W for real args
\ Mwhit      M(k,mu,z)     Whittaker function M for real args


\ This code conforms with ANS requiring:
\      1. The Floating-Point word set
\      2. Uses the word 'GAMMA' to evaluate the gamma function
\      3 The FCONSTANT PI (3.1415926536...)
\      4 The compilation of the test code is controlled by VALUE TEST_CODE?
\         and the conditional compilation words in the Programming-Tools wordset.

\ There is a bit of stack gymnastics in this code particularly in U() and M()
\ but that seems to be in the nature of the algorithm.

\ Baker, L., 1992; C Mathematical Function Handbook, McGraw-Hill,
\ New York, 757 pages,  ISBN 0-07-911158-0


\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.
\
\ Revisions:
\    2005-01-23  cgm; replaced ?TEST-CODE with TEST-CODE?  
\    2006-11-07  km;  ported to kForth with minor revisions
\    2007-11-30  km;  modified test code for automated tests
\    2010-04-30  km;  re-introduced Private: and Public:
\    2011-09-16  km;  use Neal Bridges' anonymous modules
\    2012-02-19  km;  use KM/DNW's modules library
cr .( PCYLFUN      V1.1d               19 February  2012   EFC )
BEGIN-MODULE

BASE @ DECIMAL

Private:

FVARIABLE SUM
FVARIABLE TERM
FVARIABLE OLD-TERM

\ scratch space for stack conservation
FVARIABLE XX-TMP
FVARIABLE A-TMP
FVARIABLE B-TMP
FVARIABLE C-TMP
FVARIABLE D-TMP
FVARIABLE U-TMP

FVARIABLE AV-TMP
FVARIABLE BV-TMP
FVARIABLE CV-TMP
FVARIABLE XV-TMP
FVARIABLE NV-TMP
FVARIABLE XU-TMP
FVARIABLE NU-TMP
FVARIABLE AU-TMP
FVARIABLE BU-TMP

: FRAC ( fx -- fractional_part_of_x )
    FDUP ( F>S S>F) FTRUNC F- ;

: FAC ( fx -- fz )
    1.0e F+ GAMMA ;


: ?big-x ( fnu fx -- fnu  fx  t/f )
    FOVER FOVER
    4.0e F> >R FABS 4.0e F* FOVER FSWAP F> R> AND ;

: asymptotic-u ( fnu fx -- U[nu,x] )

    0.5e FOVER FSQUARE F/
    A-TMP F!

    FDUP FSQUARE -0.25e F*
    FEXP D-TMP F!

    FOVER 0.5e F+ F** D-TMP F@ FSWAP F/
    D-TMP F!
                                                   
    FDUP FDUP
    3.5e F+ FSWAP 2.5e F+ F* A-TMP F@ F* 0.5e F* 1.0e F-
    A-TMP F@ F*
    FOVER 0.5e F+ F*
    FSWAP 1.5e F+ F*
    1.0e F+

    D-TMP F@ F*

;

: simple-u ( fb fa -- fz )
    FSWAP FDROP XX-TMP F@ FSWAP F**
    SUM F@ FSWAP F/
;


: asymptotic-v ( fnu fx -- V[nu,x] )

    0.5e FOVER FSQUARE F/
    A-TMP F!

    FDUP FSQUARE 0.25e F*
    FEXP D-TMP F!

    FOVER 0.5e F- F** D-TMP F@ F*

    2.0e PI F/ FSQRT F*
    D-TMP F!
                                                   
    FDUP FDUP
    3.5e F- FSWAP 2.5e F- F* A-TMP F@ F* 0.5e F* 1.0e F+
    A-TMP F@ F*
    FOVER 0.5e F- F*
    FSWAP 1.5e F- F*
    1.0e F+

    D-TMP F@ F*

;

: ?bad-M-parameters ( fa  fb -- fa  fb  t/f )
    FDUP F0<  >R
    FOVER FOVER FSWAP F<  R> AND >R
    FOVER FRAC F0= R> AND >R
    FDUP FRAC F0= R> AND
;

Public:

: M()  ( fa fb fx --- fu )

       XX-TMP F!

       ?bad-M-parameters abort" M() bad parameters "

       XX-TMP F@ F0= IF
                     FDROP FDROP 1.0e
                ELSE
                     1.0e TERM F!     1.0e SUM F!

                     XX-TMP F@ 10.0e F>

                                   IF
                                      1.0e30 OLD-TERM F!

                                      40 0 DO
                                             FOVER FOVER FOVER F- I S>F F+
                                             FSWAP I 1+ S>F FSWAP F- F*
                                             I 1+ S>F XX-TMP F@ F* F/
                                             TERM F@ F* FDUP TERM F!
                                              
                                             FABS OLD-TERM F@ F> IF LEAVE THEN
                                             TERM F@ FDUP FABS OLD-TERM F!
                                             SUM F@ F+ SUM F!

                                             OLD-TERM F@ FDUP 1.0e-6 F< >R
                                             SUM F@ FABS  1.0e-6 F* F<  R>
                                             OR IF LEAVE THEN
                                             
                                      LOOP

                                      FOVER FOVER F- XX-TMP F@ FSWAP F**
                                      XX-TMP F@ FEXP F* SUM F@ F*
                                      FSWAP GAMMA F*
                                      FSWAP GAMMA F/

                                   ELSE

                                       40 0 DO
                                              FOVER I S>F F+ XX-TMP F@ F*

                                              FOVER I S>F F+
                                              I 1+ S>F F* F/

                                              TERM F@ F* FDUP TERM F!

                                              FABS
                                              SUM F@ FABS  1.0e-6 F*
                                              F< IF LEAVE THEN
                                              SUM F@ TERM F@ F+ SUM F! 

                                       LOOP

                                       FDROP FDROP SUM F@

                                    THEN


                THEN

;

Private:

: u-small-x ( fa fb  -- fu )
            \ wont work if b is an integer, so tweak it slightly if it is
            FDUP FRAC F0= IF 1.0e-6 F+ THEN

            BU-TMP F!  AU-TMP F!

            XX-TMP F@ 0.0e F> IF    \ 0 > x > 5

                                           
                                 PI BU-TMP F@ PI F* FSIN F/
                                 


                                 AU-TMP F@ BU-TMP F@ F- 1.0e F+ GAMMA
                                 BU-TMP F@ GAMMA F* U-TMP F!

                                 AU-TMP F@ BU-TMP F@ XX-TMP F@ M() U-TMP F@ F/
                                 U-TMP F!

                                 BU-TMP F@ FNEGATE FDUP BU-TMP F!    \ b is now -b
                                 1.0e F+ FAC

                                 AU-TMP F@ GAMMA F*
                                 XX-TMP F@ BU-TMP F@ 1.0e F+ F**
                                 FSWAP F/

                                 AU-TMP F@ BU-TMP F@ F+ 1.0e F+
                                 2.0e BU-TMP F@ F+
                                 XX-TMP F@     M()

                                 F* FNEGATE

                                 U-TMP F@ F+ F*


                              ELSE    \ -5 < x < 0

                                  PI BU-TMP F@ PI F* FSIN F/

                                  XX-TMP F@ FEXP F*

                                  BU-TMP F@ AU-TMP F@ F-
                                  BU-TMP F@
                                  XX-TMP F@ FNEGATE M()
                                  U-TMP F!

                                  \ NOTE: side effect recovery !!!!
                                  \ M() stores last parameter in XX-TMP
                                  \ which is now the original XX-TMP
                                  \ with it sign changed, so we have
                                  \ to fix it here,
                                  XX-TMP F@ FNEGATE XX-TMP F!

                                  AU-TMP F@ BU-TMP F@ F- 1.0e F+ GAMMA
                                  BU-TMP F@ GAMMA F* U-TMP F@ FSWAP F/
                                  U-TMP F!

                                  BU-TMP F@ FNEGATE FDUP BU-TMP F!    \ b is now -b
                                  
                                  2.0e F+ GAMMA AU-TMP F@ GAMMA F*


                                  BU-TMP F@ 1.0e F+ PI F* FCOS FSWAP F/

                                  XX-TMP F@ FNEGATE
                                  BU-TMP F@ 1.0e F+  F** F*


                                  1.0e AU-TMP F@ F-
                                  BU-TMP F@ 2.0e F+
                                  XX-TMP F@    M()

                                           
                                  F* FNEGATE

                                  U-TMP F@ F+ F*

            THEN
;

Public:

: U()  ( fa fb fx --- fu )

       FDUP XX-TMP F!
       FABS 5.0e F< IF
                         u-small-x
                     ELSE
                         1.0e TERM F!   1.0e SUM F!
                         FSWAP
                         40 0 DO
                                FOVER FOVER FSWAP F- I 1+ S>F F+
                                FOVER I S>F F+ F*
                                I 1+ S>F XX-TMP F@ F* F/ FNEGATE

                                FDUP FABS 1.0e F> IF

                                              TERM F@ SUM F@ F/ FABS 1.0e-3 F<
                                              IF   FDROP simple-u
                                              ELSE

                                                   FDROP FSWAP u-small-x
                                              THEN

                                              LEAVE

                                ELSE
                                              TERM F@ F* FDUP TERM F!
                                              SUM F@ F+ SUM F!

                                              TERM F@ SUM F@ F/ FABS 1.0e-6 F<
                                              IF   simple-u
                                                   LEAVE
                                              THEN

                                THEN
                         LOOP


                     THEN

;


: Upcf ( fnu fx  -- U[nu,x] ) 

        ?big-x IF
                   asymptotic-u
               ELSE

                  FSWAP 0.5e F* FSWAP         \ nu is now 0.5*nu

                  FDUP FSQUARE -0.25e F* FEXP A-TMP F!
                  FOVER 0.25e F+ 2.0e FSWAP F**
                  A-TMP F@ FSWAP F/  A-TMP F!

                  FDUP 0.0e F> IF

                              FSQUARE 0.5e F*
                              FSWAP 0.25e F+ FSWAP
                              0.5e FSWAP

                              U()

                           ELSE                \ x <= 0

                              PI FSQRT A-TMP F@ F* A-TMP F!

                              \ saving params in TMPs to conserve stack space
                              XU-TMP F!    FDUP NU-TMP F!

                              0.75e F+ GAMMA           B-TMP F!
                              NU-TMP F@ 0.25e F+ GAMMA C-TMP F!

                              NU-TMP F@ 0.25e F+ 
                              0.5e
                              XU-TMP F@ FSQUARE 0.5e F*

                              M() B-TMP F@ F/ B-TMP F!

                              NU-TMP F@ 0.75e F+
                              1.5e
                              XU-TMP F@ FSQUARE 0.5e F*

                              M() C-TMP F@ F/ 2.0e FSQRT F* XU-TMP F@ F* FNEGATE

                              B-TMP F@ F+

                           THEN
                           
 
                            A-TMP F@ F*
               THEN

;

: Vpcf ( fnu fx -- V[nu,x] )
        
        ?big-x IF
                   asymptotic-v
               ELSE
                   \ saving params in TMPs to conserve stack space
                   XV-TMP F!    FDUP NV-TMP F!

                   0.5e F+ GAMMA PI F/         AV-TMP F!
                   NV-TMP F@ PI F* FSIN        BV-TMP F!

                   NV-TMP F@ XV-TMP F@
                               Upcf            CV-TMP F!
                   NV-TMP F@ XV-TMP F@ FNEGATE
                               Upcf            D-TMP F!

                   BV-TMP F@ CV-TMP F@ F* D-TMP F@ F+ AV-TMP F@ F*
               THEN

;

: Mwhit ( fk fmu fz -- M[k,mu,z] )
         FOVER FOVER FSWAP 0.5e F+ FSWAP F**
         FOVER -0.5e F* FEXP F*
         D-TMP F!

         FROT FNEGATE 0.5e F+
         FROT FSWAP FOVER F+

         FSWAP 2.0e F* 1.0e F+
         FROT     M()
         D-TMP F@ F*
;

: Wwhit ( fk fmu fz -- W[k,mu,z] )
         FOVER FOVER FSWAP 0.5e F+ FSWAP F**
         FOVER -0.5e F* FEXP F*
         D-TMP F!

         FROT FNEGATE 0.5e F+
         FROT FSWAP FOVER F+

         FSWAP 2.0e F* 1.0e F+
         FROT     U()
         D-TMP F@ F*
;

BASE !
END-MODULE

TEST-CODE? [IF]     \ Test Code =============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
BASE @ DECIMAL

1e-6 rel-near F!
1e-6 abs-near F!
set-near

CR
TESTING UPCF  VPCF

\ compares against test values given in Baker, 1992

(   nu    x   )
t{ -2.0e  0.0e Upcf  ->  -0.6081402e  r}t
t{ -2.0e  0.0e Vpcf  ->  -0.4574753e  r}t

t{  2.0e  0.0e Upcf  ->   0.8108537e  r}t
t{  2.0e  0.0e Vpcf  ->   0.3431063e  r}t

t{ -2.0e  1.0e Upcf  ->   0.5156671e  r}t
t{ -2.0e  1.0e Vpcf  ->  -0.5417693e  r}t

t{  2.0e  1.0e Upcf  ->   0.1832067e  r}t
t{  2.0e  1.0e Vpcf  ->   1.439015e   r}t

BASE !

[THEN]

