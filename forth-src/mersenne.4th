
\ ANEW --MT19937--                              \  Wil Baden  2003-01-31

\  *******************************************************************
\  *                                                                 *
\  *  Makoto Matsumoto and Takuji Nishimura  2002-01-09              *
\  *                                                                 *
\  *          Mersenne Twister 2002 Update                           *
\  *                                                                 *
\  *  http://www.math.keio.ac.jp/matumoto/MT2002/emt19937ar.html     *
\  *                                                                 *
\  *  Generate sequence of "random" numbers with a cycle of          *
\  *  2^19937-1.  That is 6001 decimal digits.                       *
\  *                                                                 *
\  *  Each block of 19937 bits is different.  Every possible block   *
\  *  (except all zeros) is generated.                               *
\  *                                                                 *
\  *  This is a scrambled linear congruential sequence of binary     *
\  *  vectors of length 19937 bits.                                  *
\  *                                                                 *
\  *    A C-program for MT19937, with initialization improved        *
\  *    2002/1/26. Coded by Takuji Nishimura and Makoto Matsumoto.   *
\  *                                                                 *
\  *    Before using, initialize the state by using                  *
\  *    init_genrand(seed) or init_by_array(init_key, key_length).   *
\  *                                                                 *
\  *    Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji       *
\  *    Nishimura, All rights reserved.                              *
\  *                                                                 *
\  *  Forthed by Wil Baden  2003-01-30                               *
\  *                                                                 *
\  *   genrand_int31  genrand_real1  genrand_real3   init_by_array   * 
\  *   genrand_int32  genrand_real2  genrand_real53  init_genrand    *
\  *                                                                 *
\  *******************************************************************

\ =========== kForth requires =======================
include ans-words.4th
include strings.4th
include utils.4th
: FE. ( f -- ) 9 f>string count type ;
\ ===================================================

\ TRUE 0<> [IF]  \  Comment out what you already have.

    : H#  ( "hexnumber" -- u )  \  Simplified for easy porting.
        0 0 BL WORD COUNT             ( 0 0 str len)
        BASE @ >R  HEX  >NUMBER  R> BASE !
            ABORT" Not Hex " 2DROP      ( u)
        STATE @ IF  postpone LITERAL  THEN
        ; IMMEDIATE

    : 'th                             ( n "addr" -- &addr[n] )
        S" CELLS "    EVALUATE
        BL WORD COUNT EVALUATE
        S" + "        EVALUATE
        ; IMMEDIATE
        
    : THIRD  ( x y z -- x y z x )      2 PICK ;  \  Should be in CODE.
    
    : FOURTH ( w x y z -- w x y z w )  3 PICK ;  \  Should be in CODE.

\ [THEN]

\  *******************************************************************
\  *                        Period Parameters                        *
\  *******************************************************************

624 CONSTANT  N
397 CONSTANT  M
H# 9908B0DF CONSTANT  MATRIX_A    \  constant vector a
H# 80000000 CONSTANT  UPPER_MASK  \  most significant w-r bits
H# 7FFFFFFF CONSTANT  LOWER_MASK  \  least significant r bits

CREATE  MT  N CELLS ALLOT  \  the array for the state vector
VARIABLE  MTI  N 1+ MTI !  \  mti==N+1 means mt[N] is not initialized

\  *******************************************************************
\  *                  init_genrand  init_by_array                    *
\  *******************************************************************

\  init_genrand      ( s -- )
\     initialize mt[N] with a seed

\  init_by_array     ( &init_key key_length -- )
\     initialize by an array with array-length
\     init_key is the array for initializing keys
\     key_length is its length

: init_genrand      ( s -- )
    H# FFFFFFFF AND  MT !   ( )
    N 1 DO
        1812433253  \  Borosch-Niederreiter
            I 1- 'th MT @  dup 30 RSHIFT  XOR  *  I +      
        I 'th MT !
        \  See Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier. In the
        \  previous versions, MSBs of the seed affect only MSBs of
        \  the array mt[]. 2002/01/09 modified by Makoto Matsumoto
        I 'th MT dup @  H# FFFFFFFF AND  SWAP !
        \  for >32 bit machines
    LOOP 
    N MTI ! ;

: init_by_array     ( &init_key key_length -- )
    19650218 init_genrand
    N over > IF  N  ELSE  dup  THEN  >R  ( R: k)
    0 1                                    ( &init_key key_length j i)
    1 R> ( 1 k) DO
        dup 1- 'th MT @  
        dup 30 RSHIFT XOR  
        1664525 *  
        over 'th MT @ XOR
        >R  FOURTH THIRD CELLS + @  R> +  
        THIRD +  
        over 'th MT !  \  non-linear
        
        dup 'th MT  dup @  H# FFFFFFFF AND  SWAP !
                                     \  for WORDSIZE > 32 machines
        1+ >R  1+ R>
        dup N < NOT IF  N 1- 'th MT @  MT !  DROP 1  THEN
        >R  2dup > NOT IF  DROP 0  THEN  R>
    -1 +LOOP
    1 N 1- DO
        dup 1- 'th MT @  
        dup 30 RSHIFT XOR  
        1566083941 * 
        over 'th MT @ XOR  
        over -  
        over 'th MT !
        dup 'th MT  dup @  H# FFFFFFFF AND  SWAP !
                                     \  for WORDSIZE > 32 machines
        1+
        dup N < NOT IF  N 1- 'th MT @  MT !  DROP 1  THEN
    -1 +LOOP
    2drop 2drop                                                    ( )
    H# 80000000  MT !  \  MSB is 1; assuring non-zero initial array
    ;

\  *******************************************************************
\  *                  genrand_int32  genrand_int31                   *
\  *******************************************************************

\  genrand_int32            ( -- u )
\     generate a random number on [0,0xffffffff]-interval

\  genrand_int31             ( -- u )
\     generate a random number on [0,0x7fffffff]-interval 

\    CREATE  MAG01  0 , MATRIX_A ,
0 MATRIX_A  2 table MAG01

    \  mag01[x] = x * MATRIX_A  for x=0,1

: genrand_int32             ( -- u )
    MTI @ N < NOT IF  \  generate N words at one time
        MTI @ N 1+ = IF  \  if init_genrand() has not been called,
            5489 init_genrand  \  a default initial seed is used
        THEN
        N M -  0  DO
            I 'th MT @ UPPER_MASK AND  I 1+ 'th MT @ LOWER_MASK AND  OR
                dup 1 RSHIFT  SWAP  1 AND  'th MAG01 @ XOR
                I M + 'th MT @ XOR  
                I 'th MT !
        LOOP
        N 1-  N M -  DO
            I 'th MT @ UPPER_MASK AND  I 1+ 'th MT @ LOWER_MASK AND  OR
                dup 1 RSHIFT  SWAP  1 AND  'th MAG01 @ XOR
                I M + N - 'th MT @ XOR  
                I 'th MT !
        LOOP
        N 1- 'th MT @ UPPER_MASK AND  MT @ LOWER_MASK AND  OR
        dup 1 RSHIFT  SWAP  1 AND  'th MAG01 @ XOR
            N 1- 'th MT @ XOR  N 1- 'th MT !
        0 MTI !
    THEN
    MTI @ 'th MT @  1 MTI +!
    \  Tempering
        dup 11 RSHIFT XOR
        dup 7 LSHIFT  H# 9D2C5680 AND XOR
        dup 15 LSHIFT  H# EFC60000 AND XOR
        dup 18 RSHIFT XOR 
    ;

: genrand_int31              ( -- u )
    genrand_int32  1 rshift ;

\  **********  genrand_real1  genrand_real2  genrand_real3  **********

\  genrand_real1             ( F: -- r )
\     generate a random number on [0,1]-real-interval 

\  genrand_real2             ( F: -- r )
\     generate a random number on [0,1)-real-interval 

\  genrand_real3             ( F: -- r )
\     generate a random number on (0,1)-real-interval 

    1.0E 4294967295.0E F/  FCONSTANT  (1.0/4294967295.0)

: genrand_real1             ( F: -- r )
    genrand_int32 0 D>F  (1.0/4294967295.0) F* ;
    \  divided by 2^32-1 

    1.0E 4294967296.0E F/  FCONSTANT  (1.0/4294967296.0)

:  genrand_real2             ( F: -- r )
     genrand_int32 0 D>F (1.0/4294967296.0) F* ;
    \  divided by 2^32 
    
: genrand_real3              ( F: -- r )
    genrand_int32 0 D>F 0.5E F+ (1.0/4294967296.0) F* ;
    \  divided by 2^32 

\  ************************  genrand_real53  *************************

\  genrand_real53             ( F: -- r )
\     generate a random number on [0,1) with 53-bit resolution

    1.0E 9007199254740992.0E F/  FCONSTANT  (1.0/9007199254740992.0)

: genrand_real53              ( F: -- r )
    genrand_int32 5 RSHIFT  0 D>F  
    67108864.0E  F*  genrand_int32 6 RSHIFT  0 D>F  F+
    (1.0/9007199254740992.0) F* ;

\  These real versions are due to Isaku Wada, 2002/01/09 added 

\  ***************************  MAIN DEMO  ***************************

\ MARKER DEMO

\    CREATE INIT  H# 123 , H# 234 , H# 345 , H# 456 ,
H# 123  H# 234  H# 345  H# 456  4 table INIT

: MAIN  CR
    INIT 4 init_by_array 
    ." 1000 outputs of genrand_int32 " CR
    1000 0 DO
        genrand_int32 12 U.R
        I 5 MOD 4 = IF  CR  THEN
    LOOP CR
    ." 1000 outputs of genrand_real2 " CR
    1000 0 DO
        genrand_real2 FE.
        I 5 MOD 4 = IF  CR  THEN
    LOOP CR ;

MAIN ( DEMO)

\ \   //   \\   //   \\   //   \\   //   \\   //   \\   //   \\   //
