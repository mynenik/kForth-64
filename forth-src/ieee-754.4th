\ ieee-754.4th
\ 
\ Provides additional definitions for IEEE 754 double-precision
\ floating point arithmetic on x87 FPU.
\
\ GLOSSARY:
\
\ Generic construction of a double-precision float from its
\ binary fields:
\
\   MAKE-IEEE-DFLOAT ( signbit udfraction uexp -- r nerror )
\                    ( signbit udfraction uexp -- nerror ) ( F: -- r)
\
\ Binary fields of IEEE 754 floating point values
\
\   FSIGNBIT    ( F: r -- ) ( -- minus? )
\   FEXPONENT   ( F: r -- ) ( -- uexp )
\   FFRACTION   ( F: r -- ) ( -- udfraction )
\
\   FINITE?     ( F: r -- ) ( -- flag )
\   FNORMAL?    ( F: r -- ) ( -- flag )
\   FSUBNORMAL? ( F: r -- ) ( -- flag )
\   FINFINITE?  ( F: r -- ) ( -- flag )
\   FNAN?       ( F: r -- ) ( -- flag )
\
\ Exception flag words
\
\   GET-FFLAGS  ( excpts -- flags )
\   CLEAR-ALL-FFLAGS  ( -- )
\
\ IEEE 754 special values:
\
\   +INF        ( F: -- r )
\   -INF        ( F: -- r )
\   +NAN        ( F: -- r )
\   -NAN        ( F: -- r )
\
\ To be implemented:
\
\   FCOPYSIGN     ( F: r1 r2 -- r3 )
\   FNEARBYINT    ( F: r1 -- r2 )
\   FNEXTUP       ( F: r1 -- r2 )
\   FNEXTDOWN     ( F: r1 -- r2 )
\   FSCALBN       ( n -- ) ( F: r -- r*2^n )
\   FLOGB         ( F: r -- e )    
\   FREMAINDER    ( F: x y -- r q )
\   CLEAR-FFLAGS  ( excepts -- )
\   SET-FFLAGS    ( excepts -- )
\   FENABLE       ( excepts -- )
\   FDISABLE      ( excepts -- )
\   
\
\ These words are based on the Optional IEEE 754 Binary Floating
\ Point word set(s) proposed by David N. Williams [1]. A few of 
\ the words provided here are additional convenience words which
\ are not part of the proposals in Ref. 1.
\
\ K. Myneni, 2020-08-20
\ Revs. 2020-08-27, 2022-08-02, 2026-02-08, 2026-08-04, 2026-09-01
\
\ References:
\ 1. David N. Williams, Proposal Drafts for Optional IEEE 754
\    Binary Floating Point Word Set, 27 August 2020.
\    http://www-personal.umich.edu/~williams/archive/forth/ieeefp-drafts/
\
BASE @
DECIMAL
0e fconstant F=ZERO
 1023 constant DP_EXPONENT_BIAS
 2046 constant DP_EXPONENT_MAX_NORM   \ max exponent for normalized numbers
    1 constant DP_EXPONENT_MIN_NORM   \ min exponent for normalized numbers

1 cells 4 = constant 32-bit?
1 cells 8 = constant 64-bit?
HEX


\ Make an IEEE 754 double precision floating point value from
\ the specified bits for the sign, binary fraction, and exponent.
\ Return the fp value and error code with the following meaning:
\   0  no error
\   1  exponent out of range
\   2  fraction out of range
fvariable temp

32-bit? [IF]
: MAKE-IEEE-DFLOAT ( signbit udfraction uexp -- r nerror )
    dup 800 u< invert IF 2drop 2drop F=ZERO 1 EXIT THEN
    14 lshift 
    3 pick 1F lshift or >r
    2dup 0 100000  du< invert IF 
      r> 2drop 2drop F=ZERO 2 EXIT 
    THEN
    r> or [ temp 4 + ] literal L! temp L!
    drop temp df@ 0 ;
[ELSE]
: MAKE-IEEE-DFLOAT ( signbit udfraction uexp -- r nerror )
    dup 800 u< invert IF 2drop 2drop F=ZERO 1 EXIT THEN
    34 lshift 
    3 pick 3F lshift or >r    \ set sign bit   
    2dup $10000000000000. du< invert IF
      r> 2drop 2drop F=ZERO 2 EXIT
    THEN drop 
    r> or temp !
    drop temp df@ 0 ;
[THEN]

: FSIGNBIT ( F: r -- ) ( -- minus? )
    temp df! [ temp 4 + ] literal UL@ 80000000 and 0<> ;

: FEXPONENT ( F: r -- ) ( -- u )
    temp df! [ temp 4 + ] literal UL@ 14 rshift 7FF and ;

32-bit? [IF]
: FFRACTION ( F: r -- ) ( -- ud )
    temp df! temp UL@  [ temp 4 + ] literal UL@ 000FFFFF and ;
[ELSE]
: FFRACTION ( F: r -- ) ( -- ud)
    temp df! temp @ 000FFFFFFFFFFFFF and 0 ;
[THEN]
    
: FINITE?  ( F: r -- ) ( -- [normal|subnormal]? ) 
    fexponent 7FF <> ;

: FNORMAL? ( F: r -- ) ( -- normal? )
    fdup  
    fexponent 1 DP_EXPONENT_MAX_NORM 1+ within >r
    F0= r> or ;

: FSUBNORMAL? ( F: r -- ) ( -- subnormal? ) 
    fdup ffraction D0= invert >r fexponent 0= r> and ;

: FINFINITE? ( F: r -- ) ( -- [+/-]Inf? )
    fdup fexponent 7FF = >r ffraction D0= r> and ; 

: FNAN? ( F: r -- ) ( -- nan? ) 
    fdup fexponent 7FF = >r ffraction D0= invert r> and ; 

: FCOPYSIGN ( F: r1 r2 -- r3 )
    fswap FSIGNBIT >r temp df!
    [ temp 4 + ] literal UL@
    r> IF  80000000 or  ELSE  7fffffff and  THEN
    [ temp 4 + ] literal L!
    temp df@
;


\ Exception bits in fpu status word

 1  constant  FINVALID
 4  constant  FDIVBYZERO
 8  constant  FOVERFLOW
10  constant  FUNDERFLOW
20  constant  FINEXACT

FINVALID FDIVBYZERO or FOVERFLOW or FUNDERFLOW or FINEXACT or  
constant ALL-FEXCEPTS

32-bit? [IF]

[DEFINED] getFPUstatusX86 [IF]

: GET-FFLAGS ( excepts -- flags )
    getFPUstatusX86 fpu-status @ and ;

: CLEAR-ALL-FFLAGS ( -- ) clearFPUexceptionsX86 ;

: CLEAR-FFLAGS ( excepts -- )
;

: SET-FFLAGS ( excepts -- )
;

: FENABLE ( excepts -- )
;

: FDISABLE ( excepts -- )
;

: FNEARBYINT ( F: r1 -- r2 )
;

: FNEXTUP ( F: r1 -- r2 )
;

: FNEXTDOWN ( F: r1 -- r2 )
;

: FSCALBN ( r n -- r*2^n )
;

: FLOGB ( F: r -- e )
;

: FREMAINDER ( F: x y -- r q )

;
[ELSE]
cr .( Some functions are not available.) cr
[THEN]
[ELSE]
cr .( Some functions are for 32-bit system only!) cr
[THEN]

\ Constants representing  -INF  +INF  -NAN  +NAN
true  0 0 7FF make-ieee-dfloat 0= [IF] fconstant -INF [ELSE] fdrop [THEN]
[DEFINED] -INF [IF] -INF fnegate fconstant +INF [THEN]
true  1 0 7FF make-ieee-dfloat 0= [IF] fconstant -NAN [ELSE] fdrop [THEN]
[DEFINED] -NAN [IF] -NAN fnegate fconstant +NAN [THEN]


BASE !

[DEFINED] test-code? [IF]
test-code? [IF]
[UNDEFINED] T{ [IF] include ttester [THEN]

BASE @
DECIMAL
fvariable r1
fvariable r2
-4.4501477170144022e-308 FCONSTANT DFLOAT_MIN
 1.7976931348623157e+308 FCONSTANT DFLOAT_MAX

TESTING FSIGNBIT FFRACTION FEXPONENT
DECIMAL
t{  0.0e0   FSIGNBIT  -> false }t
t{ -0.0e0   FSIGNBIT  -> true  }t
t{  1.0e-3  FSIGNBIT  -> false }t
t{ -1.0e+3  FSIGNBIT  -> true  }t
t{ +INF     FSIGNBIT  -> false }t
t{ -INF     FSIGNBIT  -> true  }t
t{ DFLOAT_MIN  FSIGNBIT  -> true  }t
t{ DFLOAT_MAX  FSIGNBIT  -> false }t

t{  0.0e0   FFRACTION  -> 0 S>D }t
t{ -0.0e0   FFRACTION  -> 0 S>D }t
t{  1.0e0   FFRACTION  -> 0 S>D }t
t{ -1.0e0   FFRACTION  -> 0 S>D }t

HEX
64-bit? [IF]
t{ DFLOAT_MIN  FFRACTION  ->  FFFFFFFFFFFFF S>D }t
t{ DFLOAT_MAX  FFRACTION  ->  FFFFFFFFFFFFF S>D }t
[ELSE]
t{ DFLOAT_MIN  FFRACTION  ->  FFFFFFFF FFFFF }t
t{ DFLOAT_MAX  FFRACTION  ->  FFFFFFFF FFFFF }t
[THEN]

DECIMAL
t{ 0.0e0   FEXPONENT  ->  0 }t
t{ 1.0e-1  FEXPONENT  DP_EXPONENT_BIAS -  ->  -4  }t
t{ DFLOAT_MIN  FEXPONENT  ->  DP_EXPONENT_MIN_NORM }t
t{ DFLOAT_MAX  FEXPONENT  ->  DP_EXPONENT_MAX_NORM }t 

TESTING MAKE-IEEE-DFLOAT
HEX
64-bit? [IF]
t{ 1 FFFFFFFFFFFFF 0   1 MAKE-IEEE-DFLOAT -> DFLOAT_MIN 0 rx}t
t{ 0 FFFFFFFFFFFFF 0 7FE MAKE-IEEE-DFLOAT -> DFLOAT_MAX 0 rx}t
[ELSE]
t{ 1 FFFFFFFF FFFFF    1 MAKE-IEEE-DFLOAT -> DFLOAT_MIN 0 rx}t
t{ 0 FFFFFFFF FFFFF  7FE MAKE-IEEE-DFLOAT -> DFLOAT_MAX 0 rx}t
[THEN]
DECIMAL
t{ 1.508e1 r1 df! -> }t
t{ r1 df@ fsignbit r1 df@ ffraction r1 df@ fexponent MAKE-IEEE-DFLOAT -> 1.508e1 0 rx}t

TESTING FINITE? FINFINITE? FNAN?
t{ +NAN    finite?  -> false }t
t{ -NAN    finite?  -> false }t
t{ +INF    finite?  -> false }t
t{ -INF    finite?  -> false }t

t{ 0.0e0   finite?  -> true }t
t{ -0.0e0  finite?  -> true }t
t{ DFLOAT_MIN  finite?  -> true }t
t{ DFLOAT_MAX  finite?  -> true }t
pad 8 erase
1 pad ! 
t{ pad f@  finite?  -> true  }t

t{ +INF    finfinite?  -> true }t
t{ -INF    finfinite?  -> true }t
t{ +NAN    finfinite?  -> false }t
t{ -NAN    finfinite?  -> false }t
t{ DFLOAT_MAX  finfinite? -> false }t
t{ DFLOAT_MIN  finfinite? -> false }t
t{ -0.0e0      finfinite? -> false }t

t{ +NAN    fnan?  -> true }t
t{ -NAN    fnan?  -> true }t
t{ +INF    fnan?  -> false }t
t{ -INF    fnan?  -> false }t
t{ DFLOAT_MAX  fnan?  -> false }t
t{ DFLOAT_MIN  fnan?  -> false }t

TESTING FNORMAL? FSUBNORMAL?
t{ DFLOAT_MIN  fnormal?  ->  true }t
t{ DFLOAT_MAX  fnormal?  ->  true }t
t{  0.0e0      fnormal?  ->  true }t
t{ -0.0e0      fnormal?  ->  true }t
t{ +INF        fnormal?  ->  false }t
t{ -INF        fnormal?  ->  false }t
t{ +NAN        fnormal?  ->  false }t
t{ -NAN        fnormal?  ->  false }t
t{ pad df@     fnormal?  ->  false }t

t{ DFLOAT_MIN  fsubnormal?  ->  false }t
t{ DFLOAT_MAX  fsubnormal?  ->  false }t
t{ +INF        fsubnormal?  ->  false }t
t{ -INF        fsubnormal?  ->  false }t
t{ +NAN        fsubnormal?  ->  false }t
t{ -NAN        fsubnormal?  ->  false }t
t{ pad df@     fsubnormal?  ->  true }t

TESTING FCOPYSIGN
t{ -1.0e0  2.0e0  fcopysign -> -2.0e0 }t
t{  1.0e0  2.0e0  fcopysign ->  2.0e0 }t
t{  1.0e0 -2.0e0  fcopysign ->  2.0e0 }t
t{ -1.0e0 -2.0e0  fcopysign -> -2.0e0 }t

BASE !

[THEN]
[THEN]


