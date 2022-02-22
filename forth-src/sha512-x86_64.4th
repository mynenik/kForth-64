\ sha512-x86_64.4th
\
\ SHA-512 64-bit      Version 0.04  Hybrid Forth/machine code
\ Forth version posted to comp.lang.forth on Jan 29, 2022 by Marcel Hendrix
\
\  LANGUAGE    : ANS Forth with extensions
\  PROJECT     : Forth Environments
\  DESCRIPTION : Based on SHA-512 from Aaron D. Gifford,
\                http://www.aarongifford.com/
\  CATEGORY    : Encrypter tool
\  AUTHOR      : Marcel Hendrix
\  LAST CHANGE : December 1, 2012, Marcel Hendrix
\                January 31, 2022, Adapted for kforth64 by K. Myneni
\                Feb 2, 2022, Working version for example; K. Myneni
\                Feb 5, 2022, Use inline code to improve efficiency by ~20%  km
\                Feb 8, 2022, Inline code for fixed RORs for more speed km
\                Feb 9, 2022, Use of "shift register" for a--h; km
\                Feb 19, 2022, Machine code implementation of SHA2 functions km
\                Feb 21, 2022, Optimized machine code  km
\
\ Requires (for kForth-64):
\   ans-words.4th
\   modules.4th
\   syscalls.4th
\   mc.4th
\   strings.4th
\   utils.4th
\   dump.4th
\
\ References:
\
\ 1. SHA512 algorithm is described in "Secure Hash Standard (SHS)",
\    NIST publication FIPS 180-4 (2015). See
\    https://csrc.nist.gov/csrc/media/publications/fips/180/4/final/documents/fips180-4-draft-aug2014.pdf
\
\ 2. Examples of SHA-1, SHA-224, SHA-256, SHA-384, SHA-512,
\    SHA-512/224 and SHA512/256 are available at 
\    http://csrc.nist.gov/groups/ST/toolkit/examples.html
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

CREATE W512[]       SHA512_BLOCK_LENGTH  CHARS ALLOT
CREATE digest[]     SHA512_DIGEST_LENGTH CHARS ALLOT
CREATE digesttext[] SHA512_DIGEST_STRING_LENGTH CHARS ALLOT

Private:

0 VALUE bitcount
: CELL[] ( a1 u -- a2 ) POSTPONE CELLS POSTPONE + ; IMMEDIATE
: ]L ] POSTPONE LITERAL ; IMMEDIATE

\ From Wil Baden's Toolbelt
: :inline ( "name <char> ccc<char>" -- )
  : [CHAR] ; PARSE  POSTPONE SLITERAL  POSTPONE EVALUATE
  POSTPONE ; IMMEDIATE ;
:inline @+  ( a1 -- a2 n ) DUP CELL+ SWAP @ ;
:inline !+  ( a1 n -- a2 ) OVER ! CELL+ ;
:inline BOUNDS OVER + SWAP ;
: PLACE+ ( caddr u ^str -- ) 
    2DUP 2>R DUP C@ + 1+ SWAP MOVE 2R@ C@ + 2R> NIP C! ;
: ?EXIT POSTPONE IF POSTPONE EXIT POSTPONE THEN ; IMMEDIATE
: (H.) ( u -- caddr u) BASE @ >R HEX 0 
   <# # # # # # # # # # # # # # # # # #> R> BASE ! ;
: H. ( u -- ) (H.) TYPE SPACE ;

HEX

\ machine code for BSWAP
\ bswap-code ( u1 -- u2 )
   48 8b 43 08    \ 8 [rbx] rax  mov,
   48 0f c8       \         rax  bswap,
   48 89 43 08    \ rax 8 [rbx]  mov,
   48 31 c0       \ rax     rax  xor,
   c3             \              ret,
0f dup MC-Table bswap-code  MC-Put

:inline BSWAP [ bswap-code ]L call ;

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

6A09E667F3BCC908 CONSTANT H0
BB67AE8584CAA73B CONSTANT H1
3C6EF372FE94F82B CONSTANT H2
A54FF53A5F1D36F1 CONSTANT H3
510E527FADE682D1 CONSTANT H4
9B05688C2B3E6C1F CONSTANT H5
1F83D9ABFB41BD6B CONSTANT H6
5BE0CD19137E2179 CONSTANT H7

DECIMAL

CREATE sreg_acc 8 CELLS ALLOT
:inline &sa sreg_acc ;
:inline &sb [ sreg_acc CELL+ ]L ;
:inline &sc [ sreg_acc 2 CELLS + ]L ;
:inline &sd [ sreg_acc 3 CELLS + ]L ;
:inline &se [ sreg_acc 4 CELLS + ]L ;
:inline &sf [ sreg_acc 5 CELLS + ]L ;
:inline &sg [ sreg_acc 6 CELLS + ]L ;
:inline &sh [ sreg_acc 7 CELLS + ]L ;


Public:

: SHA512_Init ( -- )
    sreg_acc 
    H0 !+  H1 !+  H2 !+  H3 !+
    H4 !+  H5 !+  H6 !+  H7 !+ drop 
    W512[] SHA512_BLOCK_LENGTH ERASE
    0 TO bitcount ;

Private:

\ Define a shift register of 8 cells to hold a...h
CREATE shiftreg 8 CELLS ALLOT

:inline &a shiftreg ;
:inline &b [ shiftreg CELL+ ]L ;
:inline &c [ shiftreg 2 CELLS + ]L ;
:inline &d [ shiftreg 3 CELLS + ]L ;
:inline &e [ shiftreg 4 CELLS + ]L ;
:inline &f [ shiftreg 5 CELLS + ]L ;
:inline &g [ shiftreg 6 CELLS + ]L ;
:inline &h [ shiftreg 7 CELLS + ]L ;
:inline a &a @ ;
:inline b &b @ ;
:inline c &c @ ;
:inline d &d @ ;
:inline e &e @ ;
:inline f &f @ ;
:inline g &g @ ;
:inline h &h @ ;

Public:

0 VALUE r#
: shows CR r# 2 .R SPACE a H.  b H.  c H.  d H.
    CR 3 SPACES  e H.  f H.  g H.  h H. 
    1 r# + TO r#
    r# ?EXIT  W512[] 16 CELLS DUMP ;

Private:

HEX
\ Ch(x, y, z) = (x ∧ y) ⊕ (¬x ∧ z)  
\ in:  rax = x, rcx = y, rdx = z
\ out: rax = Ch(x,y,z)
: Ch
   48 21 c1     \ rax     rcx  and,
   48 f7 d0     \         rax  not,
   48 21 d0     \ rdx     rax  and,
   48 31 c8     \ rcx     rax  xor,
;

\ Maj(x, y, z) = (x ∧ y) ⊕ (x ∧ z) ⊕ (y ∧ z)
\ in:  rax = x, rcx = y, rdx = z
\ out: rax = Maj(x,y,z)
\ uses: rdi
: Maj ( -- i*x )
   48 89 cf     \ rcx     rdi  mov,
   48 21 c7     \ rax     rdi  and,
   48 21 d0     \ rdx     rax  and,
   48 31 f8     \ rdi     rax  xor,
   48 21 d1     \ rdx     rcx  and,
   48 31 c8     \ rcx     rax  xor,
;

\ sigma0_512u(x) = ror28(x) ⊕ ror34(x) ⊕ ror39(x)
\ in:  rax = x
\ out: rax = sigma0_512u(x)
\ uses: rcx, rdx
: sigma0_512u ( -- i*x )
   48 c1 c8 1c  \ 28 #    rax  ror,
   48 c1 ca 22  \ 34 #    rdx  ror,
   48 31 d0     \ rdx     rax  xor,
   48 c1 c9 27  \ 39 #    rcx  ror,
   48 31 c8     \ rcx     rax  xor,
;

\ sigma1_512u(x) = ror14(x) ⊕ ror18(x) ⊕ ror41(x)
\ in:  rax = x
\ out: rax = sigma1_512u(x)
\ uses: rcx, rdx
: sigma1_512u ( -- i*x )
   48 c1 c8 0e  \ 14 #    rax  ror,
   48 c1 ca 12  \ 18 #    rdx  ror,
   48 31 d0     \ rdx     rax  xor,
   48 c1 c9 29  \ 41 #    rcx  ror,
   48 31 c8     \ rcx     rax  xor,
;

\ sigma0_512l(x) = ror1(x) ⊕ ror8(x) ⊕ shr7(x)
\ in:  rax = x
\ out: rax = sigma0_512l(x)
\ uses: rcx, rdx
: sigma0_512l ( -- i*x )
   48 d1 c8     \ 1 #     rax  ror,
   48 c1 ca 08  \ 8 #     rdx  ror,
   48 31 d0     \ rdx     rax  xor,
   48 c1 e9 07  \ 7 #     rcx  shr,
   48 31 c8     \ rcx     rax  xor,
;

\ sigma1_512l(x) = ror19(x) ⊕ ror61(x) ⊕ shr6(x)
\ in:  rax = x
\ out: rax = sigma1_512l(x)
\ uses: rcx, rdx
: sigma1_512l ( -- i*x )
   48 c1 c8 13  \ 19 #    rax  ror,
   48 c1 ca 3d  \ 61 #    rdx  ror,
   48 31 d0     \ rdx     rax  xor,
   48 c1 e9 06  \ 6 #     rcx  shr,
   48 31 c8     \ rcx     rax  xor,
;

\ in: rdi = idx, r9 = aK512, r11 = ashiftreg
\ out: (places T1 on Forth stack )
\ uses: rax, rcx, rdx, r8 
: compute_T1 ( -- i*x )
   4d 89 c8     \ r9      r8   mov,  \ r8 = aK512
   49 8b 04 f8  \ [r8,rdi,8]  rax  mov,
   48 01 03     \ rax 0 [rbx]  add,
   49 8b 43 38  \ 56 [r11] rax mov,  \ rax = h
   48 01 03     \ rax 0 [rbx]  add,
   49 8b 43 20  \ 32 [r11] rax  mov, \ rax = e
   49 89 c1     \ rax     r9   mov,
   48 89 c1     \ rax     rcx  mov,
   48 89 c2     \ rax     rdx  mov,
   sigma1_512u
   48 01 03     \ rax 0 [rbx]  add,
   4c 89 c8     \ r9      rax  mov,  \ rax = e
   49 8b 4b 28  \ 40 [r11] rcx mov,  \ rcx = f
   49 8b 53 30  \ 48 [r11] rdx mov,  \ rdx = g
   Ch
   48 01 03     \ rax 0 [rbx]  add,
;

\ in: r11 = ashiftreg
\ out: (places T2 on Forth stack)
\ uses: rax, rcx, rdx, rdi
: compute_T2
   49 8b 03     \ [r11]   rax  mov, \ rax = a
   49 89 c1     \ rax     r9   mov, 
   48 89 c1     \ rax     rcx  mov,
   48 89 c2     \ rax     rdx  mov,
   sigma0_512u
   48 89 03     \ rax   [rbx]  mov,
   4c 89 c8     \ r9      rax  mov,  \ rax = a
   49 8b 4b 08  \ 8 [r11] rcx  mov,  \ rcx = b
   49 8b 53 10  \ 16 [r11] rdx mov,  \ rdx = c
   Maj
   48 01 03     \ rax   [rbx]  add,
;

\ roundA-code ( ashiftreg aK512 aW512 idx aData -- T1 T2 aW512 idx aData )
\ in: (takes parameters from the Forth stack)
\ uses: rax, rcx, rdx, rdi, r8, r9, r11
   48 83 c3 08  \ 8 # rbx add,
   48 8b 03     \ 0 [rbx] rax mov,  \ rax = aData
   48 83 c3 08  \ 8 #     rbx add,
   48 8b 3b     \ 0 [rbx] rdi mov,  \ rdi = idx
   48 83 c3 08  \ 8 #     rbx add,
   4c 8b 03     \ 0 [rbx] r8  mov,  \ r8 = aW512
   48 83 c3 08  \ 8 #     rbx add,
   4c 8b 0b     \ 0 [rbx] r9  add,  \ r9 = aK512
   48 83 c3 08  \ 8 #     rbx add,
   4c 8b 1b     \ 0 [rbx] r11 mov,  \ r11 = ashiftreg 
   48 8b 10     \ [rax]   rdx mov,  \ rdx = aData a@
   48 8b 0a     \ [rdx]   rcx mov,  \ rcx = value
   48 83 c2 08  \ 8 #     rdx add,
   48 89 10     \ rdx   [rax] mov,
   48 89 c8     \ rcx     rax mov,
   48 0f c8     \         rax bswap,
   49 89 04 f8  \ rax   [r8,rdi,8] mov,
   48 89 03     \ rax 0 [rbx] mov,
   compute_T1
   48 83 eb 08  \ 8 #     rbx  sub,
   compute_T2
   48 31 c0     \ rax     rax  xor,
   48 83 eb 20  \ 32 #    rbx  sub,
   c3           \              ret,
d7 dup MC-Table roundA-code  MC-Put

:inline roundA [ roundA-code ]L call 2drop drop ;

\ roundB-code ( shiftreg aK512 aW512 idx  -- T1 T2 aK512 aW512 )
\ in: (takes parameters from the Forth stack)
\ uses: rax, rcx, rdx, rdi, r8, r9, r10, r11
   48 83 c3 08  \ 8 #     rbx  add,
   48 8b 3b     \ 0 [rbx] rdi  mov,  \ rdi = idx
   48 83 c3 08  \ 8 #     rbx  add,
   4c 8b 03     \ 0 [rbx] r8   mov,  \ r8 = aW512
   48 83 c3 08  \ 8 #     rbx  add,
   4c 8b 0b     \ 0 [rbx] r9   mov,  \ r9 = aK512
   48 83 c3 08  \ 8 #     rbx  add,
   4c 8b 1b     \ 0 [rbx] r11  mov,  \ r11 = shiftreg
   48 89 f8     \ rdi     rax  mov,
   48 ff c0     \         rax  inc,
   48 83 e0 0f  \ 15 #    rax  and,
   49 8b 04 c0  \ [r8,rax,8] rax  mov,
   48 89 c1     \ rax     rcx  mov,
   48 89 c2     \ rax     rdx  mov,
   sigma0_512l
   49 89 c2     \ rax     r10  mov,
   48 89 f8     \ rdi     rax  mov,
   48 83 c0 0e  \ 14 #    rax  add,
   48 83 e0 0f  \ 15 #    rax  and,
   49 8b 04 c0  \ [r8,rax,8] rax  mov,
   48 89 c1     \ rax     rcx  mov,
   48 89 c2     \ rax     rdx  mov,
   sigma1_512l
   49 01 c2     \ rax     r10  add,
   48 89 f8     \ rdi     rax  mov,
   48 83 c0 09  \ 9 #     rax  add,
   48 83 e0 0f  \ 15 #    rax  and,
   49 8b 04 c0  \ [r8,rax,8] rax  mov,
   49 01 c2     \ rax     r10  add,
   48 89 f8     \ rdi     rax  mov,
   48 83 e0 0f  \ 15 #    rax  and,
   48 89 c1     \ rax     rcx  mov,
   49 8b 04 c0  \ [r8,rax,8] rax  mov,
   49 01 c2     \ rax     r10  add,
   4c 89 13     \ r10 0 [rbx]  mov,
   4d 89 14 c8  \ r10 [r8,rcx,8]  mov,
   compute_T1 
   48 83 eb 08  \ 8 #     rbx  sub,
   compute_T2
   48 31 c0     \ rax     rax  xor,
   48 83 eb 18  \ 24 #    rbx  sub,
   c3           \              ret,
132 dup MC-Table roundB-code  MC-Put

:inline roundB [ roundB-code ]L call 2drop ;

:inline shift_with_add  ( T1 T2 -- ) shiftreg &b [ 7 CELLS ]L MOVE OVER + &a ! &e +! ;

DECIMAL

Public:

variable data

: SHA512_Transform ( addr -- )
    data ! sreg_acc shiftreg 8 CELLS MOVE

    16 0 DO
      shiftreg K512[] W512[] I data roundA 
      shift_with_add
    LOOP

    80 16 DO
      shiftreg K512[] W512[] I roundB 
      shift_with_add
    LOOP

    a &sa +!  b &sb +!  c &sc +!  d &sd +!
    e &se +!  f &sf +!  g &sg +!  h &sh +!
;

Private:

0 value freespace
0 value usedspace
0 value len
0 ptr addr

Public:

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
      128 W512[] usedspace + C!  usedspace 1+ TO usedspace
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
      128 W512[] C!
    THEN
    0  W512[] SHA512_SHORT_BLOCK_LENGTH       + !
    bitcount W512[] SHA512_SHORT_BLOCK_LENGTH CELL+ + !
    W512[] SHA512_Transform ;


: SHA512_Final ( -- )
    SHA512_Last
    digest[] &sa @ BSWAP  !+  &sb @ BSWAP  !+
             &sc @ BSWAP  !+  &sd @ BSWAP  !+
             &se @ BSWAP  !+  &sf @ BSWAP  !+
             &sg @ BSWAP  !+  &sh @ BSWAP  SWAP ! ;

Public:

: SHA512_End ( -- c-addr u )
    SHA512_Final
    0 digesttext[] C!
    digest[] SHA512_DIGEST_LENGTH BOUNDS
    DO  
      I @ BSWAP (H.) digesttext[] PLACE+  
    8 +LOOP
    digesttext[] COUNT ;


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
    40000000 ALLOCATE 0< IF -59 THROW THEN TO buf
    buf 40000000 [CHAR] a FILL
    CR ." Processing 40 Mbytes ... " 
    ms@
    buf 40000000 SHA512_Data 2DROP
    ms@ swap - 6 .R ."  ms elapsed" CR
    buf FREE IF -60 THROW THEN ;


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

