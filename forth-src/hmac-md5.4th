\ ANS Forth implementation of MD5 Hash Algorithm
\ Spec in IETF RFC 1321 at http://www.ietf.org/rfc/rfc1321.txt
\ HMAC-MD5 proposed structure in IETF RF 2202.
\ Code accommodates Big and Little Endian, byte addressable CPUs.
\ DEPENDENCIES: CORE EXT WORDSET ; COMMON USAGE ?DO
\ Use of this code is free subject to acknowledgment of copyright.
\ Copyright (c) 2001-2002 Jabari Zakiya - jzakiya@mail.com  4/17/2002
\ Adapted for kForth by Krishna Myneni 2/6/2003; revised 4/9/2004 km
\ Revisions:
\   2004-09-04  km
\   2006-04-18  revised setlen, storelen, hash>mackey, and keyxor
\               per Jabari's instructions so that MD5Test and
\               HMAC-TESTS will produce correct output on big
\		endian systems (e.g. kForth ppc-osx port).  km
\   2020-02-06  fixed defn of ]L for ANS-Forth compatibility.  km
\   2022-01-22  modified to work on both 32-bit and 64-bit
\               little-endian systems ( the word BYTES>< needs to
\               be updated to work on big-endian systems).  
\               CELLSIZE renamed to VCELLSIZE . km
\   2022-02-04  Fix STORELEN for 64-bit systems. km
\
\ ============== kForth requirements =========================
\ Requires kForth 1.7.2 or later, and the following libraries:
\   ans-words.4th
\   strings.4th
\   files.4th
\   macro.4th
\ ============== end of kForth requirements ===================

\ Code for MACROs has been moved to macro.4th so that it
\   may be reused easily.  KM 2/6/2003

\ ======================  Start MD5 Code ======================
  VARIABLE a   VARIABLE b   VARIABLE c   VARIABLE d  \ Hash values
  VARIABLE MD5len           \ Holds message length
  CREATE buf[]  64 ALLOT    \ Holds message block

: ]L ] POSTPONE LITERAL ; IMMEDIATE

32 constant VCELLSIZE
MACRO VCELLS " [ VCELLSIZE 8 / ]L * "
MACRO VCELL+ " [ VCELLSIZE 8 / ]L + "

HEX

\ FIXME: byte reversal for 64-bit needed. 
: bytes>< ( m -- w )  \ Reverse bytes of cell on stack
  DUP >R  18 LSHIFT  R@  FF00 AND  8 LSHIFT  OR
  R@  FF0000 AND  8 RSHIFT  OR  R>  18 RSHIFT  OR
;

1 a !     \ for endian testing
a C@ [IF] \ if little ENDIAN cpu (e.g. Intel x86 
       MACRO endian@  " sl@ "
       MACRO endian!  " l! "

[ELSE] \ big ENDIAN cpus (e.g. Power PCs)
cr .( Not ported yet for Big-Endian Systems! ) cr ABORT
       MACRO endian@  " sl@  bytes>< "
       MACRO endian!  " SWAP  bytes><  SWAP  l! "
[THEN]

1 CELLS 8 = [IF]
00000000FFFFFFFF    CONSTANT LO32_MASK
LO32_MASK 20 LSHIFT CONSTANT HI32_MASK 
MACRO >SL  "   DUP 80000000 AND IF HI32_MASK OR ELSE LO32_MASK AND THEN "
MACRO SEXT " \ >SL " 
MACRO SL+  " >SL SWAP >SL + "
MACRO rol\ " LO32_MASK AND DUP [ VCELLSIZE \ TUCK - ]L RSHIFT SWAP LITERAL LSHIFT OR "
MACRO sl+! " tuck sl@ SL+ swap l! "
[ELSE]
MACRO >SL  "  "
MACRO SEXT " \ "
MACRO SL+  " + "
MACRO rol\ " DUP [ VCELLSIZE \ TUCK - ]L RSHIFT SWAP LITERAL LSHIFT OR "
MACRO sl+! " +! "
[THEN]

MACRO M[]+ " R@  \  VCELLS +  ENDIAN@  SL+ "

\ Macros inserts 4 variable names at the '\' locations
MACRO F() " \ sl@ DUP >R INVERT \ sl@ AND R> \ sl@ AND OR \ sl@ SL+ "
MACRO G() " \ sl@ DUP >R INVERT \ sl@ AND R> \ sl@ AND OR \ sl@ SL+ "
MACRO H() " \ sl@ \ sl@ XOR \ sl@ XOR \ sl@ SL+ "
MACRO I() " \ sl@ INVERT \ sl@ OR \ sl@ XOR \ sl@ SL+ "

: MD5 ( adr -- )
  >R  a sl@  d sl@  c sl@  b sl@

\ round1 ( -- )   F(b,c,d) = (b&c)|(~b&d)
  F() b d c a  0d76aa478 SL+  M[]+ 00  rol\ 07  b sl@ SL+  a l!  \ 1
  F() a c b d  0e8c7b756 SL+  M[]+ 01  rol\ 0C  a sl@ SL+  d l!  \ 2
  F() d b a c  0242070db SL+  M[]+ 02  rol\ 11  d sl@ SL+  c l!  \ 3
  F() c a d b  0c1bdceee SL+  M[]+ 03  rol\ 16  c sl@ SL+  b l!  \ 4
  F() b d c a  0f57c0faf SL+  M[]+ 04  rol\ 07  b sl@ SL+  a l!  \ 5
  F() a c b d  04787c62a SL+  M[]+ 05  rol\ 0C  a sl@ SL+  d l!  \ 6
  F() d b a c  0a8304613 SL+  M[]+ 06  rol\ 11  d sl@ SL+  c l!  \ 7
  F() c a d b  0fd469501 SL+  M[]+ 07  rol\ 16  c sl@ SL+  b l!  \ 8
  F() b d c a  0698098d8 SL+  M[]+ 08  rol\ 07  b sl@ SL+  a l!  \ 9
  F() a c b d  08b44f7af SL+  M[]+ 09  rol\ 0C  a sl@ SL+  d l!  \ 10
  F() d b a c  0ffff5bb1 SL+  M[]+ 0A  rol\ 11  d sl@ SL+  c l!  \ 11
  F() c a d b  0895cd7be SL+  M[]+ 0B  rol\ 16  c sl@ SL+  b l!  \ 12
  F() b d c a  06b901122 SL+  M[]+ 0C  rol\ 07  b sl@ SL+  a l!  \ 13
  F() a c b d  0fd987193 SL+  M[]+ 0D  rol\ 0C  a sl@ SL+  d l!  \ 14
  F() d b a c  0a679438e SL+  M[]+ 0E  rol\ 11  d sl@ SL+  c l!  \ 15
  F() c a d b  049b40821 SL+  M[]+ 0F  rol\ 16  c sl@ SL+  b l!  \ 16

\ round2 ( -- )   G(b,c,d) = (d&b)|(~d&c)
  G() d c b a  0f61e2562 SL+  M[]+ 01  rol\ 05  b sl@ SL+  a l!  \ 1
  G() c b a d  0c040b340 SL+  M[]+ 06  rol\ 09  a sl@ SL+  d l!  \ 2
  G() b a d c  0265E5A51 SL+  M[]+ 0B  rol\ 0E  d sl@ SL+  c l!  \ 3
  G() a d c b  0e9b6c7aa SL+  M[]+ 00  rol\ 14  c sl@ SL+  b l!  \ 4
  G() d c b a  0d62f105d SL+  M[]+ 05  rol\ 05  b sl@ SL+  a l!  \ 5
  G() c b a d  002441453 SL+  M[]+ 0A  rol\ 09  a sl@ SL+  d l!  \ 6
  G() b a d c  0d8a1e681 SL+  M[]+ 0F  rol\ 0E  d sl@ SL+  c l!  \ 7
  G() a d c b  0e7d3fbc8 SL+  M[]+ 04  rol\ 14  c sl@ SL+  b l!  \ 8
  G() d c b a  021e1cde6 SL+  M[]+ 09  rol\ 05  b sl@ SL+  a l!  \ 9
  G() c b a d  0c33707d6 SL+  M[]+ 0E  rol\ 09  a sl@ SL+  d l!  \ 10
  G() b a d c  0f4d50d87 SL+  M[]+ 03  rol\ 0E  d sl@ SL+  c l!  \ 11
  G() a d c b  0455a14ed SL+  M[]+ 08  rol\ 14  c sl@ SL+  b l!  \ 12
  G() d c b a  0a9e3e905 SL+  M[]+ 0D  rol\ 05  b sl@ SL+  a l!  \ 13
  G() c b a d  0fcefa3f8 SL+  M[]+ 02  rol\ 09  a sl@ SL+  d l!  \ 14
  G() b a d c  0676f02d9 SL+  M[]+ 07  rol\ 0E  d sl@ SL+  c l!  \ 15
  G() a d c b  08d2a4c8a SL+  M[]+ 0C  rol\ 14  c sl@ SL+  b l!  \ 16

\ round3 ( -- )   H(b,c,d) = b^c^d
  H() b c d a  0fffa3942 SL+  M[]+ 05  rol\ 04  b sl@ SL+  a l!  \ 1
  H() a b c d  08771f681 SL+  M[]+ 08  rol\ 0B  a sl@ SL+  d l!  \ 2
  H() d a b c  06d9d6122 SL+  M[]+ 0B  rol\ 10  d sl@ SL+  c l!  \ 3
  H() c d a b  0fde5380c SL+  M[]+ 0E  rol\ 17  c sl@ SL+  b l!  \ 4
  H() b c d a  0a4beea44 SL+  M[]+ 01  rol\ 04  b sl@ SL+  a l!  \ 5
  H() a b c d  04bdecfa9 SL+  M[]+ 04  rol\ 0B  a sl@ SL+  d l!  \ 6
  H() d a b c  0f6bb4b60 SL+  M[]+ 07  rol\ 10  d sl@ SL+  c l!  \ 7
  H() c d a b  0bebfbc70 SL+  M[]+ 0A  rol\ 17  c sl@ SL+  b l!  \ 8
  H() b c d a  0289b7ec6 SL+  M[]+ 0D  rol\ 04  b sl@ SL+  a l!  \ 9
  H() a b c d  0eaa127fa SL+  M[]+ 00  rol\ 0B  a sl@ SL+  d l!  \ 10
  H() d a b c  0d4ef3085 SL+  M[]+ 03  rol\ 10  d sl@ SL+  c l!  \ 11
  H() c d a b  004881d05 SL+  M[]+ 06  rol\ 17  c sl@ SL+  b l!  \ 12
  H() b c d a  0d9d4d039 SL+  M[]+ 09  rol\ 04  b sl@ SL+  a l!  \ 13
  H() a b c d  0e6db99e5 SL+  M[]+ 0C  rol\ 0B  a sl@ SL+  d l!  \ 14
  H() d a b c  01fa27cf8 SL+  M[]+ 0F  rol\ 10  d sl@ SL+  c l!  \ 15
  H() c d a b  0c4ac5665 SL+  M[]+ 02  rol\ 17  c sl@ SL+  b l!  \ 16

\ round4 ( -- )   I(b,c,d) = c^(b|~d)
  I() d b c a  0f4292244 SL+  M[]+ 00  rol\ 06  b sl@ SL+  a l!  \ 1
  I() c a b d  0432aff97 SL+  M[]+ 07  rol\ 0A  a sl@ SL+  d l!  \ 2
  I() b d a c  0ab9423a7 SL+  M[]+ 0E  rol\ 0F  d sl@ SL+  c l!  \ 3
  I() a c d b  0fc93a039 SL+  M[]+ 05  rol\ 15  c sl@ SL+  b l!  \ 4
  I() d b c a  0655b59c3 SL+  M[]+ 0C  rol\ 06  b sl@ SL+  a l!  \ 5
  I() c a b d  08f0ccc92 SL+  M[]+ 03  rol\ 0A  a sl@ SL+  d l!  \ 6
  I() b d a c  0ffeff47d SL+  M[]+ 0A  rol\ 0F  d sl@ SL+  c l!  \ 7
  I() a c d b  085845dd1 SL+  M[]+ 01  rol\ 15  c sl@ SL+  b l!  \ 8
  I() d b c a  06fa87e4f SL+  M[]+ 08  rol\ 06  b sl@ SL+  a l!  \ 9
  I() c a b d  0fe2ce6e0 SL+  M[]+ 0F  rol\ 0A  a sl@ SL+  d l!  \ 10
  I() b d a c  0a3014314 SL+  M[]+ 06  rol\ 0F  d sl@ SL+  c l!  \ 11
  I() a c d b  04e0811a1 SL+  M[]+ 0D  rol\ 15  c sl@ SL+  b l!  \ 12
  I() d b c a  0f7537e82 SL+  M[]+ 04  rol\ 06  b sl@ SL+  a l!  \ 13
  I() c a b d  0bd3af235 SL+  M[]+ 0B  rol\ 0A  a sl@ SL+  d l!  \ 14
  I() b d a c  02ad7d2bb SL+  M[]+ 02  rol\ 0F  d sl@ SL+  c l!  \ 15
  I() a c d b  0eb86d391 SL+  M[]+ 09  rol\ 15  c sl@ SL+  b l!  \ 16

  b sl+!  c sl+!  d sl+!  a sl+!  R> DROP  \ Update hash values
;

: MD5int ( -- )
  067452301 a l!  0efcdab89 b l!  098badcfe c l!  010325476 d l!
;

 DECIMAL

: setlen ( -- )
  MD5len @  DUP  [ VCELLSIZE 3 - ]L  RSHIFT  
  [ buf[] 60 CHARS + ]L endian!
  3 LSHIFT  [ buf[] 56 CHARS + ]L endian!
;

\ Do all 64 byte blocks leaving remainder block
: dofullblocks ( adr1 count1 --  adr2 count2 )
  DUP  -64  AND  ( count 63 > - ?)
  IF  DUP >R  6 RSHIFT  ( count/64)
      0 DO  DUP  MD5  64 +  LOOP
      R> 63 AND
  THEN
;

: dofinal ( addr count -- )  \ Hash partial|last block
  DUP >R  buf[]  DUP >R  SWAP  CMOVE
  R> R@ +  128  OVER  C! CHAR+  55 R@ -  R> 55 >
  IF  8 + 0 FILL  buf[]  MD5  buf[] 56  THEN
  0 FILL  setlen  buf[]  MD5
;

\ compute MD5 from a counted buffer of text
: MD5buffer ( addr count -- )
  MD5int  DUP  MD5len !  dofullblocks  dofinal
;

\ ======================  HMAC MD5 Code ======================

 HEX  36363636 CONSTANT ipad   5C5C5C5C CONSTANT opad  DECIMAL
 CREATE mackey  64 CHARS  ALLOT
 CREATE iarray  64 CHARS  ALLOT
 CREATE oarray  64 CHARS  ALLOT

: hash>mackey  ( - )  \ Store hash values in mackey array 
  d sl@  c sl@  b sl@  a sl@  
  mackey  4 0 DO TUCK  endian!  VCELL+  LOOP  DROP ;

: keyxor ( #pad  kadr  iadr - )  
  16 0 DO  
    >R  2DUP  endian@  XOR  R@  endian!  
    VCELL+  R>  VCELL+  
  LOOP
  2DROP  DROP
;

: setkeys ( keyadr bytecnt - )  \ Process HMAC key, set arrays
  mackey  64  0  FILL                   \ Set key array to all '0'
  DUP  64 > IF  MD5buffer  hash>mackey  \ Hash key; store in mackey
            ELSE  mackey  SWAP  CMOVE   \ Put key vals in key array
            THEN
  ipad  mackey  iarray  keyxor          \ iarray = mackey XOR ipad
  opad  mackey  oarray  keyxor          \ oarray = mackey XOR opad
;

MACRO [MD5-MAC]  " MD5int  MD5  dofullblocks  dofinal"

: MD5-MAC  ( addr count - )  \ Perform HMAC on input data
  DUP  64 +  MD5len ! iarray  [MD5-MAC] \ Inner hash
  hash>mackey  mackey 16                \ ( mackey  16)
  80 MD5len !  oarray  [MD5-MAC]        \ Outer hash
;

: HMAC-MD5  ( datadr n1  keyadr n2 - )  setkeys  MD5-MAC ;

\ ===============  Hash string display wordset  ===============

\ Array of digits 0123456789abcdef
: digit$  ( -- adr )  S" 0123456789abcdef"  DROP  ;

: intdigits ( -- )  0 PAD ! ;
: savedigit ( n -- )  PAD C@ 1+ DUP PAD C! PAD + C! ;
: bytedigits ( n1 -- )
  DUP 4 RSHIFT digit$ + C@ savedigit 15 AND digit$ + C@ savedigit
;

a C@ [IF] \ little ENDIAN
: celldigits ( a1 -- )  DUP 4 + SWAP DO I C@ bytedigits LOOP ;
[ELSE]
 : celldigits ( a1 -- )  DUP 3 + DO I C@ bytedigits -1  +LOOP ;
[THEN]

: MD5string ( -- adr count ) \ return address of counted MD5 string
  intdigits  d  c  b  a  4 0 DO  celldigits  LOOP  PAD COUNT
;

: HMACstring ( -- adr count ) \ return address of counted HMAC string
  intdigits  c  b  a  3 0 DO  celldigits  LOOP  PAD COUNT
;

\ Display MD5 hash value in hex ( A B C D )
: .HASH  CR  MD5string  TYPE ;

\ =====================  MD5 Test Suite  ======================

: QuoteString ( adr count -- )  [CHAR] " EMIT  TYPE  [CHAR] " EMIT ;

: .MD5 ( adr count -- )
  CR CR  2DUP  MD5buffer  MD5string  TYPE  SPACE  QuoteString ;

: MD5Test ( -- )
  ." MD5 test suite results:"
  S" "  .MD5
  S" a" .MD5
  S" abc" .MD5
  S" abcdefghijklmnopqrstuvwxyz" .MD5
  S" ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" .MD5
  S" 12345678901234567890123456789012345678901234567890123456789012345678901234567890"
  .MD5
;

\ ==================  HMAC-MD5 Test Suite  ===================
  DECIMAL

  CREATE  testkey  80 CHARS  ALLOT
  CREATE  macdata  80 CHARS  ALLOT

: T1  ( - ) \ IETF RFC 2202 test case 1
  CR ." IETF RFC 2202 Test Case 1 for HMAC-MD5"
  CR ." Key  = 16 bytes of hex value 0b"
  CR ." Data = ASCII phrase 'Hi There'"
  CR ." Expected hash is: 9294727a3638bb1c13f48ef8158bfc9d"
  CR ." Computed hash is: " 
  testkey  16 11 FILL
  S" Hi There"  testkey 16  hmac-md5  MD5string  TYPE  CR
;

: T2  ( - ) \ IETF RFC 2202 test case 2
  CR ." IETF RFC 2202 Test Case 2 for HMAC-MD5"
  CR ." Key  = ASCII phrase 'Jefe'"
  CR ." Data = ASCII phrase 'what do ya want for nothing?'"
  CR ." Expected hash is: 750c783e6ab0b503eaa86e310a5db738"
  CR ." Computed hash is: " 
  S" what do ya want for nothing?"  
  S" Jefe"  hmac-MD5  MD5string  TYPE  CR
;

: T3  ( - ) \ IETF RFC 2202 test case 3
  CR ." IETF RFC 2202 Test Case 3 for HMAC-MD5"
  CR ." Key  = 16 bytes of hex value aa"
  CR ." Data = 50 bytes of hex value dd"
  CR ." Expected hash is: 56be34521d144c88dbb8c733f0e8b3f6"
  CR ." Computed hash is: " 
  [ HEX ] testkey 010 0aa FILL   macdata 032 0dd FILL  [ DECIMAL ]
  macdata 50  testkey 16  hmac-MD5  MD5string  TYPE  CR
;

: T4  ( - ) \ IETF RFC 2202 test case 4
  CR ." IETF RFC 2202 Test Case 4 for HMAC-MD5"
  CR ." Key  = 0102030405060708090a0b0c0d0e0f10111213141516171819"
  CR ." Data = 50 bytes of hex value cd"
  CR ." Expected hash is: 697eaf0aca3a3aea3a75164746ffaa79"
  CR ." Computed hash is: " 
  01 testkey 25 0 DO  2DUP C! SWAP 1+  SWAP  CHAR+  LOOP  2DROP   
  [ HEX ] macdata 032 0cd FILL  [ DECIMAL ]
  macdata 50  testkey 25  hmac-MD5  MD5string  TYPE  CR
;

: T5  ( - ) \ IETF RFC 2202 test case 5
  CR ." IETF RFC 2202 Test Case 5 for HMAC-MD5"
  CR ." Key  = 16 bytes of hex value 0c"
  CR ." Data = ASCII phrase 'Test With Truncation'"
  CR ." Expected hash is: 56461ef2342edc00f9bab995690efd4c"
  CR ." Computed hash is: " 
  [ HEX ] testkey 010 00c FILL  [ DECIMAL ]
  S" Test With Truncation"  testkey 16  hmac-MD5  MD5string  TYPE  CR
;

: T6  ( - ) \ IETF RFC 2202 test case 6
  CR ." IETF RFC 2202 Test Case 6 for HMAC-MD5"
  CR ." Key  = 80 bytes of hex value aa"
  CR ." Data = ASCII phrase 'Test Using Larger Than Block-Size Key - Hash Key First'"
  CR ." Expected hash is: 6b1ab7fe4bd7bf8f0b62e6ce61b9d0cd"
  CR ." Computed hash is: " 
  [ HEX ] testkey 050 0aa FILL  [ DECIMAL ]
  S" Test Using Larger Than Block-Size Key - Hash Key First"  
  testkey 80  hmac-MD5  MD5string  TYPE  CR
;

: T7  ( - ) \ IETF RFC 2202 test case 7
  CR ." IETF RFC 2202 Test Case 7 for HMAC-MD5"
  CR ." Key  = 80 bytes of hex value aa"
  CR ." Data = ASCII phrase 'Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data'"
  CR ." Expected hash is: 6f630fad67cda0ee1fb1f562db3aa53e"
  CR ." Computed hash is: " 
  [ HEX ] testkey 050 0aa FILL  [ DECIMAL ]
  S" Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data"  
  testkey 80  hmac-MD5  MD5string  TYPE  CR
;

: HMAC-TESTS ( - )  CR  T1  T2  T3  T4  T5  T6  T7 ;

\ ====================  File hash wordset  ====================

  VARIABLE  rfileid     \ Holds fileid number of input file

: InputFileName  ( -- ior)
  CR  CR  ." Filename: "  PAD  DUP  80  ACCEPT ( adr #)
  R/O BIN OPEN-FILE  SWAP  rfileid !  ( ior)
;

: TryAgain?  ( -- ?)
  CR CR ." Invalid input file, try again? (Y/N)"
  KEY  DUP  EMIT  DUP [CHAR] N =  SWAP [CHAR] n = OR
;

\ Read n bytes from input file, store at addr array
: bytes@  ( adr n - )  rfileid @  READ-FILE  2DROP ;

: storelen  ( ud - )
[ 1 CELLS 8 = ] [IF]
  IF rfileid @ CLOSE-FILE DROP 1 THROW THEN \ file too large
  2* 2* 2* DUP LO32_MASK AND SWAP 32 RSHIFT
[ELSE]
  D2*  D2*  D2*
[THEN]
  [ buf[] 60 CHARS + ]L endian!  
  [ buf[] 56 CHARS + ]L endian!
;

: getpartial ( cnt -- buf[] cnt2 ?)
  buf[] 2DUP  SWAP  DUP >R  bytes@     ( cnt1 adr1  )
  + 128 OVER C! CHAR+ 55 R@ - R> 55 >  ( adr2 cnt2 ?)
;

MACRO block@    " buf[]  64  bytes@ "
MACRO MD5trans  " buf[]  MD5  "


: MD5file ( -- )
  BL WORD COUNT DUP 0= IF 2DROP
    BEGIN  InputFileName  ( ior)          \ Enter filename
    WHILE  TryAgain? IF  EXIT  THEN       \ Not valid, try (not) again
    REPEAT
  ELSE
    R/O BIN OPEN-FILE  SWAP  rfileid !
    ABORT" Invalid input file."
  THEN    
  MD5int				\ Valid file, init transform
  rfileid @  FILE-SIZE  DROP  ( ud )    \ Get bytesize of input file
  CR ." Bytesize: " 2DUP  D.            \ Display filesize to screen
  2DUP  2>R                             \ Save message cnt on RETURN
  64  UM/MOD  ( rembytes nblocks )      \ Compute nblocks & rembytes
  0 ?DO  block@  MD5trans  Loop         \ Do n full blocks
  ( rembytes) ( dup) getpartial ( adr cnt ?)  \ Read remaining bytes
  IF 8 + 0 FILL MD5trans buf[] 56 THEN  \ Do if rembytes > 55
  0 FILL  2R> storelen  MD5trans        \ Do last block
  CR  ." MD5 Hash: " MD5string TYPE CR  \ Show MD5 hash for file
  rfileid @  CLOSE-FILE  DROP           \ Close the input file
;

\ =========== ( SwiftForth) kForth specific performance test ===========
CREATE testspace 10000 ALLOT  testspace 10000 BL FILL
  1000 VALUE N#

: speed-test
  cr ." MD5 test: buffer of 10,000 spaces done " N# . ." times is "
  ( ucounter) ms@ 
  N# 0 DO  testspace 10000 MD5buffer  LOOP  ( utimer) ms@ swap -
  ( ." microseconds ") . ." milliseconds"
  cr ." Hash is: " MD5string TYPE  cr
;

