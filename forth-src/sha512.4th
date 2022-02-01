\ sha512.4th
\
\ SHA-512 64-bit      Version 0.00
\ Posted to comp.lang.forth on January 29, 2022 by Marcel Hendrix
\
\  LANGUAGE    : ANS Forth with extensions
\  PROJECT     : Forth Environments
\  DESCRIPTION : Based on SHA-512 from Aaron D. Gifford,
\                http://www.aarongifford.com/
\  CATEGORY    : Encrypter tool
\  AUTHOR      : Marcel Hendrix
\  LAST CHANGE : December 1, 2012, Marcel Hendrix
\                January 31, 2022, Adapted for kforth64 by K. Myneni
\
\ Requires (for kForth-64):
\   ans-words.4th
\   modules.4th
\   strings.4th
\   utils.4th
\   dump.4th
\
\  Examples of SHA-1, SHA-224, SHA-256, SHA-384, SHA-512,
\  SHA-512/224 and SHA512/256 are available at 
\  http://csrc.nist.gov/groups/ST/toolkit/examples.html
\

BASE @

MODULE: sha512
BEGIN-MODULE

Public: 
DECIMAL
128 CONSTANT SHA512_BLOCK_LENGTH
64  CONSTANT SHA512_DIGEST_LENGTH
SHA512_DIGEST_LENGTH   2* 1+  CONSTANT SHA512_DIGEST_STRING_LENGTH
SHA512_BLOCK_LENGTH    16 -   CONSTANT SHA512_SHORT_BLOCK_LENGTH

0 VALUE bitcount

CREATE W512[]       SHA512_BLOCK_LENGTH  CHARS ALLOT
CREATE digest[]     SHA512_DIGEST_LENGTH CHARS ALLOT
CREATE digesttext[] SHA512_DIGEST_STRING_LENGTH CHARS ALLOT

: CELL[] ( a1 u -- a2 ) POSTPONE CELLS POSTPONE + ; IMMEDIATE

\ From Wil Baden's Toolbelt
: @+  ( a1 -- a2 n ) DUP CELL+ SWAP @ ;
: !+  ( a1 n -- a2 ) OVER ! CELL+ ;
: BOUNDS OVER + SWAP ;
: PLACE+ ( caddr u ^str -- ) 
    2DUP 2>R DUP C@ + 1+ SWAP MOVE 2R@ C@ + 2R> NIP C! ;
: ?EXIT POSTPONE IF POSTPONE EXIT POSTPONE THEN ; IMMEDIATE
: ?ALLOCATE ( addr ior -- ) 0< IF -59 THROW THEN ;
: (H.) ( u -- caddr u) BASE @ >R HEX 0 <# #S #> R> BASE ! ;
: H. ( u -- ) (H.) TYPE ;

HEX

\ Rotate u1 right by u2 bits to give u3
: ROR ( u1 u2 -- u3 ) 2DUP RSHIFT >R 40 - NEGATE LSHIFT R> OR ;

\ BSWAP is REVERSE64 from original C code (sha2.c)
: BSWAP ( u1 -- u2 )
    DUP  20 RSHIFT SWAP 20 LSHIFT OR
    DUP  FF00FF00FF00FF00 AND  8 RSHIFT 
    SWAP 00FF00FF00FF00FF AND  8 LSHIFT OR
    DUP  FFFF0000FFFF0000 AND 10 RSHIFT
    SWAP 0000FFFF0000FFFF AND 10 LSHIFT OR ;

\ Hash constant words K for SHA-512

  428A2F98D728AE22  7137449123EF65CD 	B5C0FBCFEC4D3B2F  E9B5DBA58189DBBC
  3956C25BF348B538  59F111F1B605D019 	923F82A4AF194F9B  AB1C5ED5DA6D8118
  D807AA98A3030242  12835B0145706FBE 	243185BE4EE4B28C  550C7DC3D5FFB4E2
  72BE5D74F27B896F  80DEB1FE3B1696B1 	9BDC06A725C71235  C19BF174CF692694
  E49B69C19EF14AD2  EFBE4786384F25E3 	0FC19DC68B8CD5B5  240CA1CC77AC9C65
  2DE92C6F592B0275  4A7484AA6EA6E483 	5CB0A9DCBD41FBD4  76F988DA831153B5
  983E5152EE66DFAB  A831C66D2DB43210 	B00327C898FB213F  BF597FC7BEEF0EE4
  C6E00BF33DA88FC2  D5A79147930AA725 	06CA6351E003826F  142929670A0E6E70
  27B70A8546D22FFC  2E1B21385C26C926 	4D2C6DFC5AC42AED  53380D139D95B3DF
  650A73548BAF63DE  766A0ABB3C77B2A8 	81C2C92E47EDAEE6  92722C851482353B
  A2BFE8A14CF10364  A81A664BBC423001 	C24B8B70D0F89791  C76C51A30654BE30
  D192E819D6EF5218  D69906245565A910 	F40E35855771202A  106AA07032BBD1B8
  19A4C116B8D2D0C8  1E376C085141AB53 	2748774CDF8EEB99  34B0BCB5E19B48A8
  391C0CB3C5C95A63  4ED8AA4AE3418ACB 	5B9CCA4F7763E373  682E6FF3D6B2B8A3
  748F82EE5DEFB2FC  78A5636F43172F60 	84C87814A1F0AB72  8CC702081A6439EC
  90BEFFFA23631E28  A4506CEBDE82BDE9 	BEF9A3F7B2C67915  C67178F2E372532B
  CA273ECEEA26619C  D186B8C721C0C207 	EADA7DD6CDE0EB1E  F57D4F7FEE6ED178
  06F067AA72176FBA  0A637DC5A2C898A6 	113F9804BEF90DAE  1B710B35131C471B
  28DB77F523047D84  32CAAB7B40C72493 	3C9EBE0A15C9BEBC  431D67C49C100D4C
  4CC5D4BECB3E42B6  597F299CFC657E2A 	5FCB6FAB3AD6FAEC  6C44198C4A475817
50 table K512[]


DECIMAL
: Ch  ( x y z -- u ) >R  OVER AND  SWAP INVERT	                R> AND   XOR ;
: Maj ( x y z -- u ) >R  DUP >R  OVER AND  R> R@  AND XOR SWAP  R> AND   XOR ;
: sigma0_512u ( x -- u ) DUP >R   28 ROR  R@ 34 ROR XOR  R>  39 ROR   XOR ;
: sigma1_512u ( x -- u ) DUP >R   14 ROR  R@ 18 ROR XOR  R>  41 ROR   XOR ;
: sigma0_512l ( x -- u ) DUP >R    1 ROR  R@  8 ROR XOR  R>   7 RSHIFT XOR ;
: sigma1_512l ( x -- u ) DUP >R   19 ROR  R@ 61 ROR XOR  R>   6 RSHIFT XOR ;

\ SHA-512: *********************************************************

HEX

0 VALUE a  0 VALUE b  0 VALUE c  0 VALUE d
0 VALUE e  0 VALUE f  0 VALUE g  0 VALUE h
0 VALUE jj 

0 ptr data

: SHA512_Init ( -- )
    6A09E667F3BCC908 TO a  BB67AE8584CAA73B TO b
    3C6EF372FE94F82B TO c  A54FF53A5F1D36F1 TO d
    510E527FADE682D1 TO e  9B05688C2B3E6C1F TO f
    1F83D9ABFB41BD6B TO g  5BE0CD19137E2179 TO h
    W512[] SHA512_BLOCK_LENGTH ERASE
    0 TO bitcount ;

DECIMAL
: ROUND512_0_TO_15_a ( u -- ) 
    >R  data @+ SWAP TO data
    BSWAP  W512[] R@ CELL[] !
    h  e sigma1_512u +  
    e f g Ch  +   
    K512[] R@ CELL[] @ +  
    W512[] R> CELL[] @ +  
    DUP d + TO d ( T1 )
    a sigma0_512u +
    a b c Maj + TO h ;

: ROUND512_0_TO_15_b ( u -- )
    >R  data @+ SWAP TO data
    BSWAP  W512[] R@ CELL[] !
    a  f sigma1_512u +
    f g h Ch  +
    K512[] R@ CELL[] @ +
    W512[] R> CELL[] @ +
    DUP e + TO e ( T1 )
    b sigma0_512u +
    b c d Maj + TO a ;

: ROUND512_0_TO_15_c ( u -- )
    >R  data @+ SWAP TO data
    BSWAP  W512[] R@ CELL[] !
    b  g sigma1_512u +  
    g h a Ch  +   
    K512[] R@ CELL[] @ +  
    W512[] R> CELL[] @ +  
    DUP f + TO f ( T1 )
    c sigma0_512u + 
    c d e Maj + TO b ;

: ROUND512_0_TO_15_d ( u -- )
    >R  data @+ SWAP TO data
    BSWAP  W512[] R@ CELL[] !
    c  h sigma1_512u +  
    h a b Ch  +   
    K512[] R@ CELL[] @ +  
    W512[] R> CELL[] @ +  
    DUP g + TO g ( T1 ) 
    d sigma0_512u +  
    d e f Maj + TO c ;

: ROUND512_0_TO_15_e ( u -- ) 
    >R  data @+ SWAP TO data
    BSWAP  W512[] R@ CELL[] !
    d  a sigma1_512u +  
    a b c Ch  +   
    K512[] R@ CELL[] @ +  
    W512[] R> CELL[] @ +  
    DUP h + TO h ( T1 )
    e sigma0_512u +
    e f g Maj + TO d ;

: ROUND512_0_TO_15_f ( u -- )
    >R  data @+ SWAP TO data 
    BSWAP  W512[] R@ CELL[] !  	
    e  b sigma1_512u +
    b c d Ch  +
    K512[] R@ CELL[] @ +  
    W512[] R> CELL[] @ +  
    DUP a + TO a ( T1 ) 
    f sigma0_512u +  
    f g h Maj + TO e ;

: ROUND512_0_TO_15_g ( u -- ) 
    >R  data @+ SWAP TO data  
    BSWAP  W512[] R@ CELL[] !
    f  c sigma1_512u +
    c d e Ch  +
    K512[] R@ CELL[] @ +
    W512[] R> CELL[] @ +
    DUP b + TO b ( T1 )
    g sigma0_512u +  
    g h a Maj + TO f ;

: ROUND512_0_TO_15_h ( u -- ) 
    >R  data @+ SWAP TO data
    BSWAP  W512[] R@ CELL[] !
    g  d sigma1_512u +
    d e f Ch  +
    K512[] R@ CELL[] @ +
    W512[] R> CELL[] @ +
    DUP c + TO c ( T1 )
    h sigma0_512u +
    h a b Maj + TO g ;

: ROUND512_a ( u -- )
    >R
    W512[] R@    1+ 15 AND CELL[] @  sigma0_512l ( s0)
    W512[] R@  14 + 15 AND CELL[] @  sigma0_512l ( s1) +
    W512[] R@   9 + 15 AND CELL[] @ +  
    DUP W512[] R@   15 AND CELL[] +! ( -- u )
    h +  
    e sigma1_512u +  
    e f g Ch  +  
    K512[] R> CELL[] @ +  
    DUP d + TO d ( T1 )
    a sigma0_512u +  
    a b c Maj + TO h ;

: ROUND512_b ( u -- )
    >R
    W512[] R@    1+ 15 AND CELL[] @  sigma0_512l ( s0)
    W512[] R@  14 + 15 AND CELL[] @  sigma0_512l ( s1) +
    W512[] R@   9 + 15 AND CELL[] @ +  
    DUP W512[] R@   15 AND CELL[] +! ( -- u )
    a +  
    f sigma1_512u +  
    f g h Ch  +  
    K512[] R> CELL[] @ +  
    DUP e + TO e ( T1 )
    b sigma0_512u +  
    b c d Maj + TO a ;

: ROUND512_c ( u -- )
    >R
    W512[] R@    1+ 15 AND CELL[] @  sigma0_512l ( s0)
    W512[] R@  14 + 15 AND CELL[] @  sigma0_512l ( s1) +
    W512[] R@   9 + 15 AND CELL[] @ +  
    DUP W512[] R@   15 AND CELL[] +! ( -- u )
    b +  
    g sigma1_512u +
    g h a Ch  +
    K512[] R> CELL[] @ +
    DUP f + TO f ( T1 )
    c sigma0_512u +
    c d e Maj + TO b ;

: ROUND512_d ( u -- )
    >R
    W512[] R@    1+ 15 AND CELL[] @  sigma0_512l ( s0)
    W512[] R@  14 + 15 AND CELL[] @  sigma0_512l ( s1) +
    W512[] R@   9 + 15 AND CELL[] @ +  
    DUP W512[] R@   15 AND CELL[] +! ( -- u )
    c +  
    h sigma1_512u +
    h a b Ch  +
    K512[] R> CELL[] @ +
    DUP g + TO g ( T1 )
    d sigma0_512u +
    d e f Maj + TO c ;

: ROUND512_e ( u -- )
    >R
    W512[] R@    1+ 15 AND CELL[] @  sigma0_512l ( s0)
    W512[] R@  14 + 15 AND CELL[] @  sigma0_512l ( s1) +
    W512[] R@   9 + 15 AND CELL[] @ +  
    DUP W512[] R@   15 AND CELL[] +! ( -- u )
    d +
    a sigma1_512u +
    a b c Ch  +
    K512[] R> CELL[] @ +
    DUP h + TO h ( T1 )
    e sigma0_512u +
    e f g Maj + TO d ;

: ROUND512_f ( u -- )
    >R
    W512[] R@    1+ 15 AND CELL[] @  sigma0_512l ( s0)
    W512[] R@  14 + 15 AND CELL[] @  sigma0_512l ( s1) +
    W512[] R@   9 + 15 AND CELL[] @ +  
    DUP W512[] R@   15 AND CELL[] +! ( -- u )
    e +  
    b sigma1_512u +
    b c d Ch  +
    K512[] R> CELL[] @ +
    DUP a + TO a ( T1 )
    f sigma0_512u +
    f g h Maj + TO e ;

: ROUND512_g ( u -- )
    >R
    W512[] R@    1+ 15 AND CELL[] @  sigma0_512l ( s0)
    W512[] R@  14 + 15 AND CELL[] @  sigma0_512l ( s1) +
    W512[] R@   9 + 15 AND CELL[] @ +  
    DUP W512[] R@   15 AND CELL[] +! ( -- u )
    f +  
    c sigma1_512u +  
    c d e Ch  +  
    K512[] R> CELL[] @ +  
    DUP b + TO b ( T1 )
    g sigma0_512u +  
    g h a Maj + TO f ;

: ROUND512_h ( u -- )
    >R
    W512[] R@    1+ 15 AND CELL[] @  sigma0_512l ( s0)
    W512[] R@  14 + 15 AND CELL[] @  sigma0_512l ( s1) +
    W512[] R@   9 + 15 AND CELL[] @ +  
    DUP W512[] R@   15 AND CELL[] +! ( -- u )
    g +
    d sigma1_512u +  
    d e f Ch  +  
    K512[] R> CELL[] @ +  
    DUP c + TO c ( T1 )
    h sigma0_512u +
    h a b Maj + TO g ;

Public:
DECIMAL

0 VALUE r#
: shows CR r# 2 .R SPACE a H. space  b H. space  c H. space  d H.
    CR 3 SPACES  e H. space  f H. space  g H. space  h H. 
    1 r# + TO r#
    r# ?EXIT  W512[] 16 CELLS DUMP ;

\ Private:
DECIMAL

: SHA512_Transform ( addr -- )
    TO data
    ( 16 rounds )	
    ( a b c d e f g h )   0 ROUND512_0_TO_15_a  
    ( h a b c d e f g )   1 ROUND512_0_TO_15_h
    ( g h a b c d e f )   2 ROUND512_0_TO_15_g	
    ( f g h a b c d e )   3 ROUND512_0_TO_15_f
    ( e f g h a b c d )   4 ROUND512_0_TO_15_e	
    ( d e f g h a b c )   5 ROUND512_0_TO_15_d
    ( c d e f g h a b )   6 ROUND512_0_TO_15_c	
    ( b c d e f g h a )   7 ROUND512_0_TO_15_b
    ( a b c d e f g h )   8 ROUND512_0_TO_15_a
    ( h a b c d e f g )   9 ROUND512_0_TO_15_h
    ( g h a b c d e f )  10 ROUND512_0_TO_15_g
    ( f g h a b c d e )  11 ROUND512_0_TO_15_f
    ( e f g h a b c d )  12 ROUND512_0_TO_15_e	
    ( d e f g h a b c )  13 ROUND512_0_TO_15_d
    ( c d e f g h a b )  14 ROUND512_0_TO_15_c	
    ( b c d e f g h a )  15 ROUND512_0_TO_15_b

    ( 64 rounds )
    ( a b c d e f g h ) 16 ROUND512_a
    ( h a b c d e f g ) 17 ROUND512_h
    ( g h a b c d e f ) 18 ROUND512_g
    ( f g h a b c d e ) 19 ROUND512_f
    ( e f g h a b c d ) 20 ROUND512_e
    ( d e f g h a b c ) 21 ROUND512_d
    ( c d e f g h a b ) 22 ROUND512_c
    ( b c d e f g h a ) 23 ROUND512_b

    ( a b c d e f g h ) 24 ROUND512_a
    ( h a b c d e f g ) 25 ROUND512_h
    ( g h a b c d e f ) 26 ROUND512_g
    ( f g h a b c d e ) 27 ROUND512_f
    ( e f g h a b c d ) 28 ROUND512_e
    ( d e f g h a b c ) 29 ROUND512_d
    ( c d e f g h a b ) 30 ROUND512_c
    ( b c d e f g h a ) 31 ROUND512_b

    ( a b c d e f g h ) 32 ROUND512_a
    ( h a b c d e f g ) 33 ROUND512_h
    ( g h a b c d e f ) 34 ROUND512_g
    ( f g h a b c d e ) 35 ROUND512_f
    ( e f g h a b c d ) 36 ROUND512_e
    ( d e f g h a b c ) 37 ROUND512_d
    ( c d e f g h a b ) 38 ROUND512_c
    ( b c d e f g h a ) 39 ROUND512_b

    ( a b c d e f g h ) 40 ROUND512_a
    ( h a b c d e f g ) 41 ROUND512_h
    ( g h a b c d e f ) 42 ROUND512_g
    ( f g h a b c d e ) 43 ROUND512_f
    ( e f g h a b c d ) 44 ROUND512_e
    ( d e f g h a b c ) 45 ROUND512_d
    ( c d e f g h a b ) 46 ROUND512_c
    ( b c d e f g h a ) 47 ROUND512_b

    ( a b c d e f g h ) 48 ROUND512_a
    ( h a b c d e f g ) 49 ROUND512_h
    ( g h a b c d e f ) 50 ROUND512_g
    ( f g h a b c d e ) 51 ROUND512_f
    ( e f g h a b c d ) 52 ROUND512_e
    ( d e f g h a b c ) 53 ROUND512_d
    ( c d e f g h a b ) 54 ROUND512_c
    ( b c d e f g h a ) 55 ROUND512_b

    ( a b c d e f g h ) 56 ROUND512_a
    ( h a b c d e f g ) 57 ROUND512_h
    ( g h a b c d e f ) 58 ROUND512_g
    ( f g h a b c d e ) 59 ROUND512_f
    ( e f g h a b c d ) 60 ROUND512_e
    ( d e f g h a b c ) 61 ROUND512_d
    ( c d e f g h a b ) 62 ROUND512_c
    ( b c d e f g h a ) 63 ROUND512_b

    ( a b c d e f g h ) 64 ROUND512_a
    ( h a b c d e f g ) 65 ROUND512_h
    ( g h a b c d e f ) 66 ROUND512_g
    ( f g h a b c d e ) 67 ROUND512_f
    ( e f g h a b c d ) 68 ROUND512_e
    ( d e f g h a b c ) 69 ROUND512_d
    ( c d e f g h a b ) 70 ROUND512_c
    ( b c d e f g h a ) 71 ROUND512_b

    ( a b c d e f g h ) 72 ROUND512_a
    ( h a b c d e f g ) 73 ROUND512_h
    ( g h a b c d e f ) 74 ROUND512_g
    ( f g h a b c d e ) 75 ROUND512_f
    ( e f g h a b c d ) 76 ROUND512_e
    ( d e f g h a b c ) 77 ROUND512_d
    ( c d e f g h a b ) 78 ROUND512_c
    ( b c d e f g h a ) 79 ROUND512_b ;

0 value freespace
0 value usedspace
0 value len
0 ptr addr

HEX

: SHA512_Update ( c-addr u -- )
    0 0 \ LOCALS| freespace usedspace len addr |
    to freespace to usedspace to len to addr
    len 0= ?EXIT
    bitcount 3 RSHIFT  SHA512_BLOCK_LENGTH MOD  TO usedspace
    usedspace  IF
      SHA512_BLOCK_LENGTH usedspace - TO freespace
      len freespace >= IF
         addr W512[] usedspace +  freespace MOVE
         freespace 3 LSHIFT bitcount + TO bitcount
         len freespace - TO len  
         freespace addr + TO addr
         W512[] SHA512_Transform
      ELSE
        addr  W512[] usedspace +  len MOVE
        len 3 LSHIFT bitcount + TO bitcount
        0 TO usedspace  0 TO freespace  
        EXIT
      THEN
    THEN

    BEGIN
      len SHA512_BLOCK_LENGTH >=
    WHILE 
      addr SHA512_Transform
      SHA512_BLOCK_LENGTH 3 LSHIFT bitcount + TO bitcount
      len SHA512_BLOCK_LENGTH - TO len
      SHA512_BLOCK_LENGTH addr + TO addr
    REPEAT

    len IF  
      addr W512[] len MOVE 	
      len 3 LSHIFT bitcount + TO bitcount
    THEN ;

0 value usedspace

: SHA512_Last ( -- )
    bitcount 3 RSHIFT  SHA512_BLOCK_LENGTH MOD  TO usedspace
    bitcount BSWAP TO bitcount
    usedspace IF
      80 W512[] usedspace + C!  1 usedspace + TO usedspace
      usedspace SHA512_SHORT_BLOCK_LENGTH <= IF	
        W512[] usedspace +  SHA512_SHORT_BLOCK_LENGTH usedspace -  ERASE
      ELSE
        usedspace SHA512_BLOCK_LENGTH < IF
          W512[] usedspace +  SHA512_BLOCK_LENGTH usedspace - ERASE  
        THEN
        W512[] SHA512_Transform
        W512[] SHA512_BLOCK_LENGTH 2- ERASE
      THEN
    ELSE
      W512[] SHA512_SHORT_BLOCK_LENGTH ERASE
      80 W512[] C!
    THEN
    0  W512[] SHA512_SHORT_BLOCK_LENGTH       + !
    bitcount W512[] SHA512_SHORT_BLOCK_LENGTH CELL+ + !
    W512[] SHA512_Transform ;


: SHA512_Final ( -- )
    SHA512_Last
    digest[] a BSWAP  !+  b BSWAP  !+
             c BSWAP  !+  d BSWAP  !+
             e BSWAP  !+  f BSWAP  !+
             g BSWAP  !+  h BSWAP  SWAP ! ;

: SHA512_End ( -- c-addr u )
    SHA512_Final
    0 digesttext[] C!
    digest[] SHA512_DIGEST_LENGTH BOUNDS
    DO  
      I @ BSWAP (H.) ( 1 /STRING) digesttext[] PLACE+  
    8 +LOOP
    digesttext[] COUNT ;

Public:
DECIMAL

: SHA512_Data ( addr len -- c-addr u ) 
    SHA512_Init  
    SHA512_Update
    SHA512_End ;

0 value crs
: .SHA512 ( c-addr u -- ) 
    0 TO crs  
    BOUNDS ?DO  
      crs 6 MOD 0= IF CR THEN
      I 8 TYPE SPACE 1 crs + TO crs  
    8 +LOOP ;

0 ptr buf
: SHAspeed ( -- )
    40000000 ALLOCATE ?ALLOCATE TO buf
    buf 40000000 [CHAR] a FILL
    CR ." Processing 40 Mbytes ... " 
    ms@
    buf 40000000 SHA512_Data 2DROP
    ms@ swap - 6 .R ."  ms elapsed" CR
    buf FREE ?ALLOCATE ;


BASE !
END-MODULE


0 [IF]
: ABOUT	
   CR .~ Try: S" abc" SHA512_Data TYPE~
   CR ."      =  DDAF35A1 93617ABA CC417349 AE204131"
   CR ."         12E6FA4E 89A97EA2 0A9EEEE6 4B55D39A"
   CR ."         2192992A 274FC1A8 36BA3C23 A3FEEBBD"
   CR ."         454D4423 643CE80E 2A9AC94F A54CA49F"
   CR
   CR .~      S" abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu" SHA512_Data TYPE
   CR ."      =  8E959B75 DAE313DA 8CF4F728 14FC143F"
   CR ."         8F7779C6 EB9F7FA1 7299AEAD B6889018"
   CR ."         501D289E 4900F7E4 331B99DE C4B5433A"
   CR ."         C7D329EE B6DD2654 5E96E55B 874BE909"
   CR
   CR ."      SHAspeed -- test speed with a 40 MB buffer (>181 MB/sec)." ;

   ABOUT CR
[THEN]
                              ( End of Source )

