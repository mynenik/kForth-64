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
\ Revs. 2020-08-27, 2022-08-02
\
\ References:
\ 1. David N. Williams, Proposal Drafts for Optional IEEE 754
\    Binary Floating Point Word Set, 27 August 2020.
\    http://www-personal.umich.edu/~williams/archive/forth/ieeefp-drafts/
\
BASE @
DECIMAL
0e fconstant F=ZERO
HEX


\ Make an IEEE 754 double precision floating point value from
\ the specified bits for the sign, binary fraction, and exponent.
\ Return the fp value and error code with the following meaning:
\   0  no error
\   1  exponent out of range
\   2  fraction out of range
fvariable temp

: MAKE-IEEE-DFLOAT ( signbit udfraction uexp -- r nerror )
    dup 800 u< invert IF 2drop 2drop F=ZERO 1 EXIT THEN
    14 lshift 3 pick 1F lshift or >r
    dup 100000 u< invert IF 
      r> 2drop 2drop F=ZERO 2 EXIT 
    THEN
    r> or [ temp 4 + ] literal L! temp L!
    drop temp df@ 0 ;

: FSIGNBIT ( F: r -- ) ( -- minus? )
    temp df! [ temp 4 + ] literal UL@ 80000000 and 0<> ;

: FEXPONENT ( F: r -- ) ( -- u )
    temp df! [ temp 4 + ] literal UL@ 14 rshift 7FF and ;

: FFRACTION ( F: r -- ) ( -- ud )
    temp df! temp UL@  [ temp 4 + ] literal UL@ 000FFFFF and ;

: FINITE?  ( F: r -- ) ( -- [normal|subnormal]? ) fexponent 7FF <> ;

: FNORMAL? ( F: r -- ) ( -- normal? )  fexponent 0<> ;

: FSUBNORMAL? ( F: r -- ) ( -- subnormal? )  fexponent 0= ;

: FINFINITE? ( F: r -- ) ( -- [+/-]Inf? )
   finite? invert ; 

: FNAN? ( F: r -- ) ( -- nan? ) 
   fdup FEXPONENT 7FF = >r FFRACTION D0= invert r> and ; 


\ Exception bits in fpu status word

 1  constant  FINVALID
 4  constant  FDIVBYZERO
 8  constant  FOVERFLOW
10  constant  FUNDERFLOW
20  constant  FINEXACT

FINVALID FDIVBYZERO or FOVERFLOW or FUNDERFLOW or FINEXACT or  
constant ALL-FEXCEPTS

1 cells 4 = [IF]

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

: FCOPYSIGN ( F: r1 r2 -- r3 )
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
cr .( Some functions are for 32-bit system only! ) cr
[THEN]

\ Constants representing  -INF  +INF  -NAN  +NAN
true  0 0 7FF make-ieee-dfloat 0= [IF] fconstant -INF [ELSE] fdrop [THEN]
[DEFINED] -INF [IF] -INF fnegate fconstant +INF [THEN]
true  1 0 7FF make-ieee-dfloat 0= [IF] fconstant -NAN [ELSE] fdrop [THEN]
[DEFINED] -NAN [IF] -NAN fnegate fconstant +NAN [THEN]


BASE !
