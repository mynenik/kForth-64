\ Please see copyright information at the following site:
\
\  http://www.tckerrigan.com/Chess/TSCP
\
\ It appears that the copyright notice for the derivative work
\ below is inconsistent with the original author's wishes. An
\ enhanced replacement, which resolves the copyright problem,
\ can be found at the following link. The kForth version of the
\ FCP program will soon replace the present version:
\
\ http://www.quirkster.com/iano/forth/FCP.html
\
\ TSCP.f, version 0.4  Copyright 2001 Ian Osgood  iano@quirkster.com
( numbers for PIII-550 MHz
ply    nodes    time score pv
  1       21   0.000    48 d2-d4
  2       93   0.030     0 d2-d4 d7-d5
  3      864   0.170    35 d2-d4 d7-d5 b1-c3
& 3     1652   0.330     0 d2-d4 d7-d5 b1-c3 g8-f6
& 3     3850   0.871     5 e2-e4 d7-d5 f1-b5 c8-d7 b5-d3
  4     5003   1.212     5 e2-e4 d7-d5 f1-b5 c8-d7 b5-d3
& 4    10707   2.473    35 e2-e4 e7-e5 d2-d4 d7-d5 g1-f3
  5    26639   5.257    35 e2-e4 e7-e5 d2-d4 d7-d5 g1-f3
& 5    59444  12.127    13 e2-e4 e7-e5 d2-d4 e5xd4 d1xd4 g8-f6
  6   188262  45.455    13 e2-e4 e7-e5 d2-d4 e5xd4 d1xd4 g8-f6
4370 nps Move found: e2-e4

TSCP.EXE v1.73
ply      nodes  time score  pv
  1         21  0.00    48  d2d4
  2         84  0.00     0  d2d4 d7d5
  3        800  0.00    35  d2d4 d7d5 b1c3
  4       4219  0.04     5  e2e4 d7d5 f1b5 c8d7 b5d3
  5      22461  0.23    35  e2e4 e7e5 d2d4 d7d5 g1f3
  6     138420  1.54    13  e2e4 e7e5 d2d4 e5d4 d1d4 g8f6
  7    1174526 12.43    30  e2e4 d7d5 e4d5 d8d5 d2d4 d5e4 g1e2 e7e5

       [ 94491 nps ]
)
\ !!! examining more nodes per iteration: move ordering still buggy?

\ Tom Kerrigan's TSCP chess engine (v1.73) ported from C to ANS Forth
\  with some modifications, such as:
\ 1* 0x88 vs. mailbox edge detection
\  * different piece & color values
\  * fine-grain factoring
\  * different command set, UI
\ 2* track king positions for inCheck?  [reps implemented]
\ 3* material and pawn files updated incrementally
\  * narrow starting a-b window with fail-high/low for more cutoffs
\  * setup EPD command
\ 4* style improvements based on c.l.f commentary
\  * fixed bugs in time display, reps
\  * use $ for hex constants instead of using DECIMAL & HEX
\  * .board options: showCoords, rotateBoard
\  * .epd command for recording a position, .moveList to list moves

\ Uses Core Extension words:  .( .R ?DO ERASE FALSE NIP TRUE TUCK \
\ Uses Tools Extension words: [IF] [ELSE] [THEN]
\ Uses String word:           TOLOWER
\ Uses Win32Forth utilities:  ms@ CELL-
\ Uses defacto-standard HEX constant specifier: $ff
\  (I would use decimal #99, but it isn't supported by Win32Forth.
\   Thus, BASE 10 is assumed.  Use the next line if this is not the case.)
\ VARIABLE __saveBase BASE @ __saveBase ! DECIMAL

\ Assumes 32-bit or 64-bit cells
\ Recursive: assumes a data stack larger than 2*MAX_PLY
\  and a return stack larger than 3*MAX_PLY.
\ Uses about 64K bytes of data space, mostly for the
\  history table.  Some structures (eval boards etc.)
\  could use signed char instead of cells for some space savings.
\ I might also use VALUE and TO to replace VARIABLE, @, ! for many
\  items, because I prefer the semantics for values.

\ ==================================================
\
\ This version is modified from Ian Osgood's original
\ code. It includes minor changes to permit the code
\ to run under kForth (1.6.x or later). The code will 
\ also run under ANS Forths (PFE, gforth, etc.)
\
\ Revisions:
\
\ 2002-07-16  modified for use with kForth; km
\ 2006-03-28  modified ".PIECE" to use @ instead of C@ to 
\               avoid ENDIAN dependence.  km
\ 2009-12-12  added definition of NOOP  km
\ 2020-01-26  removed definitions of [UNDEFINED] , [DEFINED],
\               CHARS and SPACE ; used fix for 64-bit
\               systems from more recent fcp.f
\ 2020-12-05  fix abort bug during search: v 0.4.2
\ 2020-12-11  fix to run on 64-bit systems: v 0.4.3
\ 2020-12-14  add time limit for search; backport other
\               modifications from versions: v 0.4.4
\ 2021-06-26  backports from FCP; remove use of PTR;
\               ver. 0.4.5
\ 2022-01-20  backports from FCP; use :INLINE ; ver 0.4.6

\ Requires (kForth only): ans-words.4th      
\ =================================================

\ ============= ANS Forth definitions =============
[UNDEFINED] A@ [IF] synonym a@ @ [THEN]
[UNDEFINED] ALLOT? [IF] : allot? HERE SWAP ALLOT ; [THEN]
\ ============= end ANS Forth definitions =========

[UNDEFINED] CELL [IF] 1 CELLS CONSTANT CELL [THEN]
[UNDEFINED] CELL- [IF] : CELL- POSTPONE CELL POSTPONE - ; IMMEDIATE [THEN]

FALSE [IF]
: :inline : ;    \ don't inline when profiling
[ELSE] [UNDEFINED] :inline [IF]
\ Wil Baden implements :inline for portably inlining code
: :inline ( "name <char> ccc<char>" -- )
  : [CHAR] ; PARSE  POSTPONE SLITERAL  POSTPONE EVALUATE
  POSTPONE ; IMMEDIATE
;
[THEN] [THEN]

: table ( v1 ... vn n -- )
	CREATE DUP CELLS allot? OVER 1- CELLS + SWAP
	0 ?DO DUP >R ! R> 1 CELLS - LOOP DROP ;

1120 CONSTANT GEN_STACK
  32 CONSTANT MAX_PLY
 400 CONSTANT HIST_STACK

 : MAX_PLY* 5 LSHIFT ;

HEX

CREATE inputBuf 10 CHARS ALLOT

: xPause ." Hit Enter: " inputBuf 10 accept IF QUIT THEN ;

\ *** Square (piece + color) ***

\ 0 CONSTANT EMPTY
10 CONSTANT LIGHT
20 CONSTANT DARK
30 CONSTANT COLORMASK

\ 0 CONSTANT EMPTY      \ and BLANK are taken; just use 0
1 CONSTANT PAWN
2 CONSTANT KNIGHT
3 CONSTANT BISHOP
4 CONSTANT ROOK
5 CONSTANT QUEEN
6 CONSTANT KING
F CONSTANT EDGE
7 CONSTANT PIECEMASK

DARK PAWN + CONSTANT DARKPAWN
LIGHT PAWN + CONSTANT LIGHTPAWN


:inline otherSide ( side -- ~side ) COLORMASK XOR ;
: color ( [sq] -- color ) COLORMASK AND ;
: light? ( [sq] -- nz ) LIGHT AND ;
: dark? ( [sq] -- nz ) DARK AND ;
: mine? ( [sq] color -- tf ) XOR COLORMASK AND 0= ;
: enemy? ( [sq] color -- tf ) XOR COLORMASK AND COLORMASK = ;
  \ color can also be a piece+color
:inline piece ( [sq] -- piece ) PIECEMASK AND ; 

\ *** Board ***

\ The board structure is changed from the original TSCP to this Forth
\  version.  This representation has the advantages of:
\  1. One board index is used both for the main board and the eval boards
\     The original TSCP had a 120 element board for the pieces and edge
\     detection, and 64 element boards for eval piece-square tables, requiring
\     extra tables for translating between the two indices.  This
\     design uses one half of a 128 element board for both functions.
\  2. Edge detection testing on board index vs. board contents
\  3. One board element contains both piece and color data.  The original
\     TSCP had two separate boards, one for color and one for piece type.
\  4. Easy to translate between rank/file and board index.
\  5. Efficient test for whether a piece on one square can attack a piece
\     on another square (heavily used by inCheck?)

CREATE board 80 ALLOT
: eraseBoard  board 80 erase ;

70 CONSTANT sqA1
72 CONSTANT sqC1
74 CONSTANT sqE1
76 CONSTANT sqG1
77 CONSTANT sqH1
00 CONSTANT sqA8
02 CONSTANT sqC8
04 CONSTANT sqE8
06 CONSTANT sqG8
07 CONSTANT sqH8

: edge? ( sq+offset -- nz ) 88 AND ;
:inline bd! ( piece sq -- ) board + c! ;
:inline bd@ ( sq -- piece ) board + c@ ;
: ?bd@ ( sq -- piece ) DUP edge? IF DROP EDGE ELSE bd@ THEN ;
:inline piece@ ( sq -- piece ) bd@ piece ;

: bdMove ( sqF sqT -- ) OVER bd@ SWAP bd! 0 SWAP bd! ;

:inline rank ( sq -- rank ) 4 rshift ; 
: file ( sq -- file ) F AND ;
: fileRank>sq ( file rank -- sq ) 4 lshift or ;

:inline rank8? ( sq -- tf ) rank 0= ;
:inline rank7? ( sq -- tf ) rank 1 = ; 
:inline rank2? ( sq -- tf ) rank 6 = ; 
:inline rank1? ( sq -- tf ) rank 7 = ;

: rotate ( sq -- sq ) NEGATE 77 + ;

: cRank ( sq -- c ) rank NEGATE [CHAR] 8 + ;
: cFile ( sq -- c ) file [CHAR] a + ;

\ *** Globals ***

VARIABLE side           \ color to move during search
VARIABLE ply            \ depth of search
VARIABLE ep             \ square for possible en-passant capture
VARIABLE castle         \ flags for castling capability
VARIABLE fifty          \ fifty move draw count

: wtm? ( -- tf ) side @ LIGHT = ;

: bd@mine? ( sq -- tf ) bd@ color side @ = ;
: ?bd@enemy? ( sq+dir -- tf ) ?bd@ side @ enemy? ;

\ *** Board Iterator ***

: forSomeSq ( [st] xt -- ) \ xt ( [st] sq -- [st] 0 / [any] nz )
  80 0 DO
    I 8 + I DO
      I SWAP DUP >R EXECUTE IF
        R> DROP UNLOOP UNLOOP EXIT
      THEN R>
    LOOP
  10 +LOOP DROP ;

: forEverySq ( [st] xt -- )
  80 0 DO
    I 8 + I DO
      I SWAP DUP >R EXECUTE R>
    LOOP
  10 +LOOP DROP ;

: onlyMyColor ( [st] xt sq -- xt )
  DUP bd@mine? IF OVER EXECUTE ELSE DROP THEN ;

: forEachMyColor ( [st] xt -- ) ['] onlyMyColor forEverySq ;

\ *** Board Display ***

  CHAR .   CHAR P   CHAR N   CHAR B 
  CHAR R   CHAR Q   CHAR K   CHAR # 
8 table symbols


[UNDEFINED] tolower [IF]
: tolower ( C -- c ) 20 OR ;   \ standard function?
[THEN]

: .piece ( piece[+color] -- )
  DUP piece CELLS symbols + @      \ symbol for piece
  SWAP dark? IF tolower THEN EMIT ; \ dark is lowercase

VARIABLE blackAtBottom?
VARIABLE showCoords?


: .aSq ( sq -- )
  showCoords? @ IF
    DUP 1- edge? IF
      DUP blackAtBottom? @ IF rotate THEN
      rank NEGATE [CHAR] 8 + EMIT 2 SPACES
    THEN
  THEN
  DUP blackAtBottom? @ IF rotate THEN bd@ .piece
  1+ edge? IF CR ELSE SPACE THEN ;

: .board ( -- )
  CR ['] .aSq forEverySq
  showCoords? @ IF CR 3 SPACES
    blackAtBottom? @ IF ." h g f e d c b a"
    ELSE ." a b c d e f g h" THEN CR
  THEN ;

: .sq ( sq -- )
  DUP file [CHAR] a + EMIT
  rank NEGATE [CHAR] 8 + EMIT ;

\ Display board as an Extended Position Definition (EPD) string

VARIABLE epdBlCount
: 0epdBl! ( -- ) 0 epdBlCount ! ;

: ?.epdBl ( -- )
  epdBlCount @ ?DUP IF
    [CHAR] 0 + EMIT
    0epdBl!
  THEN ;

: .epdSq ( sq -- )
  DUP bd@ ?DUP IF
    ?.epdBl .piece
  ELSE
    1 epdBlCount +!
  THEN
  DUP 1+ edge? IF
    ?.epdBl
    rank1? 0= IF [CHAR] / EMIT THEN
  ELSE DROP THEN ;

: .epd ( -- )
  CR 0epdBl! ['] .epdSq forEverySq SPACE
  wtm? IF [CHAR] w ELSE [CHAR] b THEN EMIT CR ;

\ *** Attack and check detection ***

  10 CONSTANT So        \ rank
 -10 CONSTANT No
   1 CONSTANT Ea        \ file
  -1 CONSTANT We
So Ea + CONSTANT SE
So We + CONSTANT SW
No Ea + CONSTANT NE
No We + CONSTANT NW

DECIMAL
0  0  0  -1  -1  -1   0   7 table slides?
0  0  1  10  15  20  20   7 table offsets
 
  0 No NE +  Ea NE +  Ea SE +  So SE + 
 So SW +  We SW +  We NW +  No NW +  0 
 NE  SE  SW  NW  0 
 No  Ea  So  We  0 
 No  NE  Ea  SE  So  SW  We  NW  0 
HEX
1D table offset

: pieceSlides? ( piece -- piece tf )
  DUP CELLS slides? + @ ;
: pieceOffsets ( piece -- ^offsets )
  CELLS offsets + @ CELLS offset + ;

\ !!! sqPieceAttacks, genPiece, and genPieceCaps are tantalizingly factorable

\ example: No $10 $40 - inLine? -> TRUE
: inLine? ( dir diff -- tf )
  2DUP 0< SWAP 0< = IF   \ same dir?
    OVER ABS 1 = IF
      ABS 8 < NIP  \ same rank: within rank?
    ELSE
      SWAP MOD 0=  \ !!! expensive division?
    THEN
  ELSE
    2DROP FALSE
  THEN ;

\ assumes dir sq sqSrc - inLine?  (so no need to check for edge)
: sqSliderAttacks? ( sq sqSrc dir -- tf )
  >R BEGIN
    R@ + 2DUP = IF              \ clear line
      R> DROP 2DROP TRUE EXIT
    THEN
  DUP bd@ UNTIL
  R> DROP 2DROP FALSE ;

: sqPieceAttacks? ( sq sqSrc -- tf )
  2DUP - >R                              \ save difference
  DUP bd@ piece pieceSlides? IF ( ... piece )
    pieceOffsets DUP @ BEGIN    ( ... ^offsets dir )
      R@ inLine? IF             ( ... ^offsets )
        R> DROP
        @ sqSliderAttacks? EXIT
      THEN
    CELL+ DUP @ DUP 0= UNTIL
  ELSE
    pieceOffsets DUP @ BEGIN
      R@ = IF                   ( ... ^offsets )
        R> 2DROP 2DROP TRUE EXIT
      THEN
    CELL+ DUP @ DUP 0= UNTIL
  THEN
  ( ... ^offsets dir )
  R> DROP 2DROP 2DROP FALSE ;

: sqLPAttacks? ( sq sqSrc -- tf )
  - DUP NW = SWAP NE = OR ;

: sqDPAttacks? ( sq sqSrc -- tf )
  - DUP SW = SWAP SE = OR ;

: sqAttacks? ( sq sqSrc -- tf )
  DUP bd@ DUP LIGHTPAWN = IF DROP sqLPAttacks?
  ELSE DARKPAWN = IF sqDPAttacks?
  ELSE sqPieceAttacks? THEN THEN ;

: attacks? ( sq side -- tf )
  80 0 DO
    I 8 + I DO
      DUP I bd@ color = IF
        OVER I sqAttacks? IF
          2DROP TRUE
          UNLOOP UNLOOP EXIT
        THEN
      THEN
    LOOP
  10 +LOOP
  2DROP FALSE ;

VARIABLE lkSq   VARIABLE dkSq

: inCheck? ( side -- tf )
  LIGHT = IF lkSq @ DARK ELSE dkSq @ LIGHT THEN attacks? ;

\ *** Move Type ***

1 CELLS CONSTANT moveSize

 1 CONSTANT captureBit
 2 CONSTANT castleBit
 4 CONSTANT epBit
 8 CONSTANT 2sqBit
10 CONSTANT pawnBit

 1000000 CONSTANT mvCaptureBit
 2000000 CONSTANT mvCastleBit
 4000000 CONSTANT mvEPBit
 8000000 CONSTANT mv2sqBit
10000000 CONSTANT mvPawnBit
20000000 CONSTANT mvPromoteBit

3F000000 mvCastleBit XOR CONSTANT mvReset50Bits

: packMove ( from to bits -- move32 )
  10 LSHIFT OR 8 LSHIFT OR ;

: mvPromote! ( mv piece -- mv ) 10 LSHIFT OR mvPromoteBit OR ;

: mvFrom ( mv -- sqFrom ) FF AND ;
: mvTo ( mv -- sqTo ) 8 RSHIFT FF AND ;
: mvPromote ( mv -- piece ) 10 RSHIFT piece ;

: epSq ( from to -- ep ) + 2/ ; 
: epCapSq ( from to -- epCap ) F AND SWAP F0 AND OR ;

: .move ( mv -- )
  DUP mvFrom .sq
  DUP mvCaptureBit AND IF [CHAR] x ELSE [CHAR] - THEN EMIT
  DUP mvTo .sq
  DUP mvPromoteBit AND IF
    [CHAR] = EMIT
    DUP mvPromote CELLS symbols + @ EMIT
  THEN
  mvEPBit AND IF ." ep" THEN ;

\ *** History (for improved move ordering) ***

40 CONSTANT numSquares         \ 64

CREATE history numSquares DUP * CELLS ALLOT
  \ tradeoff: make 3*64*64 to use sq as index directly
  \ !!! c,

: historyErase history numSquares DUP * CELLS ERASE ;

: asIndex ( sq -- 0-63 ) DUP file SWAP rank 3 LSHIFT OR ;

: ^history ( from to -- ^hist )
  asIndex 6 LSHIFT SWAP asIndex + CELLS history + ;


\ *** Move Generation ***

moveSize CELL+ CONSTANT genSize
: genSize* 2* CELLS ;

CREATE gen_dat GEN_STACK genSize* ALLOT
\ gen_t accessors: move, score

CREATE firstMove MAX_PLY CELLS ALLOT  \ stores addresses within gen_dat

: init_first ( -- ) gen_dat firstMove ! ;

:inline ^firstMovePly ( -- ^first ) firstMove ply @ CELLS + ;
: firstMovePly ( -- ^gen ) ^firstMovePly A@ ;
: lastMovePly ( -- ^gen ) ^firstMovePly CELL+ A@ ;

: forMovesAtPly ( -- lastMovePly firstMovePly )  \ init ?DO LOOP
  ^firstMovePly DUP CELL+ A@ SWAP A@ ;

: genPutMove ( score mv -- ) \ gen_dat[firstMove[ply+1]++] = mv+score
  ^firstMovePly CELL+ DUP A@ DUP genSize + ROT ! 2! ;

: xGenDump ( -- )
  CR
  forMovesAtPly ?DO
    I DUP @ DUP .move SPACE . CELL+ @ . CR
  genSize +LOOP ;

100000 CONSTANT mvSortFirst

: genPromote ( from to bits -- )
  packMove
  KING KNIGHT DO
    mvSortFirst I 4 LSHIFT +    \ score: sort promotions first
    OVER I mvPromote!   \ move
    genPutMove          \ push it
  LOOP DROP ;

: genPush ( from to bits -- )
  DUP pawnBit AND IF
    wtm? IF
      OVER rank8? IF genPromote EXIT THEN
    ELSE
      OVER rank1? IF genPromote EXIT THEN
    THEN
  THEN
  OVER bd@ IF
    \ most-valuable-victim least-valuable-attacker
    ROT DUP bd@ piece >R           \ piece moved
    ROT DUP bd@ piece 4 LSHIFT     \ piece captured * 16
    R> + mvSortFirst +             \ sort captures first
  ELSE
    ROT ROT 2DUP ^history @
  THEN  ( bits from to score -- )
  >R ROT packMove
  R> SWAP genPutMove ;

: genInitPly ( -- )        \ firstMove[ply+1] = firstMove[ply];
  ^firstMovePly DUP @ SWAP CELL+ ! ;

captureBit epBit pawnBit OR OR CONSTANT epBits

: genEP ( -- )
  ep @ IF
    ep @ DUP
    wtm? IF
      SW + ?bd@ LIGHTPAWN = IF
        DUP DUP SW + SWAP epBits genPush
      THEN
      SE + ?bd@ LIGHTPAWN = IF
        ep @ DUP SE + SWAP epBits genPush
      THEN
    ELSE
      NW + ?bd@ DARKPAWN = IF
        DUP DUP NW + SWAP epBits genPush
      THEN
      NE + ?bd@ DARKPAWN = IF
        ep @ DUP NE + SWAP epBits genPush
      THEN
    THEN
  THEN ;

1 CONSTANT wkCastleBit
2 CONSTANT wqCastleBit
4 CONSTANT bkCastleBit
8 CONSTANT bqCastleBit

: genCastle ( -- )
  castle @ DUP
  wtm? IF
    wkCastleBit AND IF
      sqE1 sqG1 castleBit genPush
    THEN
    wqCastleBit AND IF
      sqE1 sqC1 castleBit genPush
    THEN
  ELSE
    bkCastleBit AND IF
      sqE8 sqG8 castleBit genPush
    THEN
    bqCastleBit AND IF
      sqE8 sqC8 castleBit genPush
    THEN
  THEN ;

pawnBit captureBit OR CONSTANT pawnCaptBits

: genLPCaps ( sq -- )
  DUP NW + ?bd@ dark? IF
    DUP DUP NW + pawnCaptBits genPush
  THEN
  DUP NE + ?bd@ dark? IF
    DUP NE + pawnCaptBits genPush
  ELSE DROP THEN ;

: genDPCaps ( sq -- )
  DUP SW + ?bd@ light? IF
    DUP DUP SW + pawnCaptBits genPush
  THEN
  DUP SE + ?bd@ light? IF
    DUP SE + pawnCaptBits genPush
  ELSE DROP THEN ;

: genToStop ( sq dir -- dest )       \ gen moves until edge or other piece
  >R DUP BEGIN R@ + DUP ?bd@ 0= WHILE
    2DUP 0 genPush
  REPEAT  ( sq dest )
  R> ROT 2DROP ;

: genPiece ( piece sq -- )
  >R pieceSlides? IF            ( piece )
    pieceOffsets DUP @ BEGIN    ( ^offs dir )  \ for all directions...
      R@ SWAP genToStop
      DUP ?bd@enemy? IF
        R@ SWAP captureBit genPush
      ELSE DROP THEN
    CELL+ DUP @ DUP 0= UNTIL
  ELSE
    pieceOffsets DUP @ BEGIN
      R@ +    ( ^offs dest )
      DUP ?bd@                     ( o d e/p )
      DUP 0= IF
        DROP R@ SWAP 0 genPush     ( o )
      ELSE side @ enemy? IF        ( o d )
        R@ SWAP captureBit genPush ( o )
      ELSE DROP THEN THEN          ( o )
    CELL+ DUP @ DUP 0= UNTIL       ( o+ dir )
  THEN
  ( ^offsets dir )
  R> DROP 2DROP ;

pawnBit 2sqBit OR CONSTANT pawn2sqBits

: gen ( -- )
  genInitPly
  80 0 DO
    I 8 + I DO
      I bd@mine? IF
        I bd@
        DUP LIGHTPAWN = IF
          DROP I genLPCaps
          I No + bd@ 0= IF
            I I No + pawnBit genPush
            I rank2? I No 2* + bd@ 0= AND IF
              I I No 2* + pawn2sqBits genPush
            THEN
          THEN
        ELSE DUP DARKPAWN = IF
          DROP I genDPCaps
          I So + bd@ 0= IF
            I I So + pawnBit genPush
            I rank7? I So 2* + bd@ 0= AND IF
              I I So 2* + pawn2sqBits genPush
            THEN
          THEN
        ELSE
          piece I genPiece
        THEN THEN
      THEN
    LOOP
  10 +LOOP
  genCastle
  genEP ;

: slideToStop ( dir sq -- dest )        \ slide to edge or other piece
  BEGIN OVER + DUP ?bd@ UNTIL NIP ;

: genPieceCaps ( piece sq -- )
  >R pieceSlides? IF            ( piece )
    pieceOffsets DUP @ BEGIN    ( ^offs dir )  \ for all directions...
      R@ slideToStop
      DUP ?bd@enemy? IF
        R@ SWAP captureBit genPush
      ELSE DROP THEN
    CELL+ DUP @ DUP 0= UNTIL
  ELSE
    pieceOffsets DUP @ BEGIN
      R@ +    ( ^offs dest )
      DUP ?bd@enemy? IF
        R@ SWAP captureBit genPush
      ELSE DROP THEN
    CELL+ DUP @ DUP 0= UNTIL
  THEN
  ( ^offsets dir )
  R> DROP 2DROP ;

: genCaps ( -- )
  genInitPly
  80 0 DO
    I 8 + I DO
      I bd@mine? IF
        I bd@
        DUP LIGHTPAWN = IF
          DROP I genLPCaps
          I rank7? I No + bd@ 0= AND IF
            I I No + pawnBit genPromote
          THEN
        ELSE DUP DARKPAWN = IF
          DROP I genDPCaps
          I rank2? I So + bd@ 0= AND IF
            I I So + pawnBit genPromote
          THEN
        ELSE
          piece I genPieceCaps
        THEN THEN
      THEN
    LOOP
  10 +LOOP
  genEP ;

\ *** Move History Stack ***

VARIABLE histTop

2 CELLS CONSTANT histSize
: histSize* 2* CELLS ;

CREATE hist_dat HIST_STACK histSize* ALLOT
hist_dat HIST_STACK histSize* + CONSTANT histMax

: initHist ( -- ) hist_dat histTop ! ;

: .moveList ( -- )
  CR 5 SPACES ." White  Black" 0   ( halfmoveNumber )
  histTop a@ hist_dat ?DO
    DUP 1 AND 0= IF
      CR DUP 2/ 1+ 3 .R SPACE
    THEN
    SPACE I @ .move SPACE
    1+
  histSize +LOOP DROP CR ;

: .xHist ( ply -- )
  ?DUP IF
    histTop a@ DUP ROT histSize* - DO
      I @ .move SPACE
    histSize +LOOP
  THEN ;

: xHistDump ( -- )
  CR
  histTop a@ hist_dat ?DO
    I @ DUP .move SPACE .
    I CELL+ @
    DUP FF AND DUP IF [CHAR] x EMIT .piece SPACE ELSE DROP THEN
    DUP 8 RSHIFT
     DUP wkCastleBit AND IF [CHAR] K EMIT THEN
     DUP wqCastleBit AND IF [CHAR] Q EMIT THEN
     DUP bkCastleBit AND IF [CHAR] k EMIT THEN
     bqCastleBit AND IF [CHAR] q EMIT THEN
     SPACE
    DUP 10 RSHIFT FF AND ?DUP IF ." ep:" .sq SPACE THEN
    18 RSHIFT . ." /50"
    CR
  histSize +LOOP ;

: histPush ( mv -- )
  histTop a@                    \ move (32 bits)
  2DUP ! CELL+ SWAP
  mvTo bd@                      \ captured piece (w\color 6 bits)
  castle @ 8 LSHIFT OR          \ castle (4 bits)
  ep @ 10 LSHIFT OR             \ ep square (7 bits)
  fifty @ 18 LSHIFT OR          \ fifty move count (7 bits)
  OVER ! CELL+ histTop ! ;

[UNDEFINED] CELL- [IF]
: CELL- 1 CELLS - ;
[THEN]

: histPop ( -- capt mv )
  histTop a@
  CELL- DUP @
  DUP 18 RSHIFT fifty !
  DUP 10 RSHIFT FF AND ep !
  DUP 8 RSHIFT FF AND castle !
  FF AND SWAP
  CELL- DUP histTop ! a@ ;

\ *** Move and Undo ***

\ these items are updated incrementally to save time in eval
\ pawnRank[c][f] is the rank of the least advanced pawn of color c
\  on file f - 1.  If no pawn, set to promotion rank.

CREATE darkPawnRank 10 CELLS ALLOT      \ !!! use chars?
CREATE lightPawnRank 10 CELLS ALLOT

: openFile? ( f+1 -- tf )
  CELLS DUP lightPawnRank + @ 0=
  SWAP darkPawnRank + @ 7 = AND ;

\ pawn moved, captured, or promoted: update the file (both sides)

: updatePawnFile ( file -- )
  DUP 1+ CELLS
  0 OVER lightPawnRank + !
  7 OVER darkPawnRank + !
  SWAP 70 + DUP 60 - DO
    I bd@ DUP LIGHTPAWN = IF DROP
      DUP lightPawnRank + DUP @ I rank MAX SWAP !
    ELSE DARKPAWN = IF
      DUP darkPawnRank + DUP @ I rank MIN SWAP !
    THEN THEN
  10 +LOOP DROP ;

VARIABLE lightPieceMat   VARIABLE darkPieceMat
VARIABLE lightPawnMat    VARIABLE darkPawnMat


DECIMAL
100 CONSTANT pawnValue
0  pawnValue  300  300  500  900  0   7 table pieceValues
HEX

\ Update material and pawn files incrementally during move and takeback:
\ 1. captures 1a. pawn captured 2. promotions 3. en passant 4. pawn moves

: takeBack ( -- )
  side @ otherSide side !
  -1 ply +!
  histPop       ( capt mv )

  DUP mvPromoteBit AND IF
    PAWN side @ OR OVER mvFrom bd!
    \ update material
    pawnValue OVER mvPromote CELLS pieceValues + @ NEGATE
    wtm? IF lightPieceMat +! lightPawnMat
    ELSE darkPieceMat +! darkPawnMat THEN +!
  ELSE
    DUP mvTo bd@
    DUP piece KING = IF
      OVER mvFrom DUP wtm? IF lkSq ELSE dkSq THEN ! bd!
    ELSE
      OVER mvFrom bd!
    THEN
  THEN
  SWAP DUP IF  ( mv capt )
    \ capture: update material
    DUP piece DUP PAWN = IF DROP
      pawnValue wtm? IF darkPawnMat ELSE lightPawnMat THEN +!
      OVER mvPawnBit AND 0= IF
        OVER mvTo 2DUP bd!   file updatePawnFile
      THEN
    ELSE
      CELLS pieceValues + @
      wtm? IF darkPieceMat ELSE lightPieceMat THEN +!
    THEN
  THEN
  OVER mvTo bd!    ( mv )

  DUP mvCastleBit AND IF
    DUP mvTo DUP sqG1 = OVER sqG8 = OR IF           \ O-O
      DUP 1- SWAP 1+ bdMove      \ undo the rook
    ELSE DUP sqC1 = OVER sqC8 = OR IF               \ O-O-O
      DUP 1+ SWAP 1- 1- bdMove   \ undo the rook
    THEN THEN
  THEN

  DUP mvPawnBit AND IF
    DUP mvEPBit AND IF
      \ update material
      pawnValue wtm? IF darkPawnMat ELSE lightPawnMat THEN +!
      DUP mvFrom OVER mvTo epCapSq
      PAWN side @ otherSide OR SWAP bd!
    THEN
    DUP mvFrom file SWAP mvTo file 2DUP = IF
      DROP ELSE updatePawnFile THEN
    updatePawnFile
  ELSE DROP THEN ;

wkCastleBit wqCastleBit OR CONSTANT wCastleBits
bkCastleBit bqCastleBit OR CONSTANT bCastleBits

: sqCastleMask ( sq -- mask )
  F SWAP DUP rank8? IF
    DUP sqA8 = IF DROP bqCastleBit XOR
    ELSE DUP sqE8 = IF DROP bCastleBits XOR
    ELSE sqH8 = IF bkCastleBit XOR
    THEN THEN THEN
  ELSE DUP rank1? IF
    DUP sqA1 = IF DROP wqCastleBit XOR
    ELSE DUP sqE1 = IF DROP wCastleBits XOR
    ELSE sqH1 = IF wkCastleBit XOR
    THEN THEN THEN
  ELSE DROP THEN THEN ;

: makeMove ( mv -- legal? )
  DUP mvCastleBit AND IF
    side @ inCheck? IF DROP FALSE EXIT THEN
    DUP mvTo DUP sqG1 = OVER sqG8 = OR IF           \ O-O
      DUP bd@ OVER 1- bd@ OR color IF 2DROP FALSE EXIT THEN
      DUP side @ otherSide attacks? IF 2DROP FALSE EXIT THEN
      DUP 1- side @ otherSide attacks? IF 2DROP FALSE EXIT THEN
      DUP 1+ SWAP 1- bdMove      \ OK: move the rook
    ELSE DUP sqC1 = OVER sqC8 = OR IF               \ O-O-O
      DUP bd@ OVER 1- bd@ OR OVER 1+ bd@ OR IF
        2DROP FALSE EXIT THEN
      DUP side @ otherSide attacks? IF 2DROP FALSE EXIT THEN
      DUP 1+ side @ otherSide attacks? IF 2DROP FALSE EXIT THEN
      DUP 1- 1- SWAP 1+ bdMove      \ OK: move the rook
    ELSE
      DROP .move ." :bad castle" FALSE EXIT
    THEN THEN
  THEN
  DUP histPush
  1 ply +!
  castle @ DUP IF
    OVER DUP mvTo sqCastleMask SWAP mvFrom sqCastleMask AND AND castle !
  ELSE DROP THEN

  DUP mv2sqBit AND IF
    DUP mvFrom OVER mvTo epSq
  ELSE 0 THEN ep !

  DUP mvReset50Bits AND IF 0 fifty ! ELSE 1 fifty +! THEN
  DUP mvTo
  DUP bd@ ?DUP IF
    \ capture: update material
    piece DUP PAWN = IF DROP
      pawnValue NEGATE wtm? IF darkPawnMat ELSE lightPawnMat THEN +!
      OVER mvPawnBit AND 0= IF DUP file updatePawnFile THEN
    ELSE
      CELLS pieceValues + @ NEGATE
      wtm? IF darkPieceMat ELSE lightPieceMat THEN +!
    THEN
  THEN
  OVER mvFrom TUCK bd@
  DUP piece KING = IF
    OVER wtm? IF lkSq ELSE dkSq THEN !
  THEN
  SWAP bd! 0 SWAP bd!           \ move made
  DUP mvPromoteBit AND IF
    DUP mvPromote side @ OR OVER mvTo bd!
    \ update material
    pawnValue NEGATE OVER mvPromote CELLS pieceValues + @
    wtm? IF lightPieceMat +! lightPawnMat
    ELSE darkPieceMat +! darkPawnMat THEN +!
  THEN

  DUP mvPawnBit AND IF
    DUP mvEPBit AND IF
      \ update material
      pawnValue NEGATE wtm? IF darkPawnMat ELSE lightPawnMat THEN +!
      DUP mvFrom OVER mvTo epCapSq 0 SWAP bd!
    THEN
    DUP mvFrom file SWAP mvTo file 2DUP = IF
      DROP ELSE updatePawnFile THEN
    updatePawnFile
  ELSE DROP THEN

  side @ DUP otherSide side !
  inCheck? IF
    takeBack FALSE
  ELSE TRUE THEN ;

\ *** Evaluation ***
DECIMAL

: evalSetupSq ( sq -- sq )
  DUP >R bd@ ?DUP IF
    DUP light? IF 
      DUP LIGHTPAWN = IF
        DROP pawnValue lightPawnMat +!
        R@ file 1+ CELLS lightPawnRank + ( sq ^lpr )
        DUP @ R@ rank MAX SWAP !
      ELSE
        piece CELLS pieceValues + @ lightPieceMat +!
      THEN
    ELSE 
      DUP DARKPAWN = IF
        DROP pawnValue darkPawnMat +!
        R@ file 1+ CELLS darkPawnRank +
        DUP @ R@ rank MIN SWAP !
      ELSE
        piece CELLS pieceValues + @ darkPieceMat +!
      THEN 
    THEN 
  THEN R> DROP ;

\ !!! piece lists

: evalSetup ( -- )      \ call after setting up a position or new game
  10 0 DO
    0 lightPawnRank I CELLS + !
    7  darkPawnRank I CELLS + !
  LOOP
  0 lightPieceMat ! 0 darkPieceMat !
  0 lightPawnMat  ! 0 darkPawnMat  !
  ['] evalSetupSq forEverySq ;

-10 CONSTANT DOUBLED_PAWN_PENALTY
-20 CONSTANT ISOLATED_PAWN_PENALTY
 -8 CONSTANT BACKWARD_PAWN_PENALTY
 20 CONSTANT PASSED_PAWN_BONUS
 10 CONSTANT ROOK_SEMI_OPEN_FILE_BONUS
 15 CONSTANT ROOK_OPEN_FILE_BONUS
 20 CONSTANT ROOK_ON_SEVENTH_BONUS

\ The following tables are 128 * 64 piece square tables.
\ Each table has two "entry points" so that sq values
\ can act directly as indices and we save space.

\ The tables are flipped vertically if used for black.
\ Since they are all symetrical horizontally, we can rotate them instead.
\  exception: king table has light and dark versions
\  exception: king endgame table is 8-fold symmetric, can be used unrotated

 0    0    0    0    0    0    0    0 
   -10  -10  -10  -10  -10  -10  -10  -10 
 5   10   15   20   20   15   10    5 
   -10    0    0    0    0    0    0  -10 
 4    8   12   16   16   12    8    4 
   -10    0    5    5    5    5    0  -10 
 3    6    9   12   12    9    6    3 
   -10    0    5   10   10    5    0  -10 
 2    4    6    8    8    6    4    2 
   -10    0    5   10   10    5    0  -10 
 1    2    3  -10  -10    3    2    1 
   -10    0    5    5    5    5    0  -10 
 0    0    0  -40  -40    0    0    0 
   -10    0    0    0    0    0    0  -10 
 0    0    0    0    0    0    0    0 
   -10  -30  -10  -10  -10  -10  -30  -10 
16 8 * table pawnPcSq

pawnPcSq 8 CELLS + CONSTANT knightPcSq


-10  -10  -10  -10  -10  -10  -10  -10 
    0   10   20   30   30   20   10    0 
-10    0    0    0    0    0    0  -10 
   10   20   30   40   40   30   20   10 
-10    0    5    5    5    5    0  -10 
   20   30   40   50   50   40   30   20 
-10    0    5   10   10    5    0  -10 
   30   40   50   60   60   50   40   30 
-10    0    5   10   10    5    0  -10 
   30   40   50   60   60   50   40   30 
-10    0    5    5    5    5    0  -10 
   20   30   40   50   50   40   30   20 
-10    0    0    0    0    0    0  -10 
   10   20   30   40   40   30   20   10 
-10  -10  -20  -10  -10  -20  -10  -10 
    0   10   20   30   30   20   10    0 
16 8 * table bishopPcSq

bishopPcSq 8 CELLS + CONSTANT kingEndgamePcSq


-40  -40  -40  -40  -40  -40  -40  -40 
    0   20   40  -20    0  -20   40   20 
-40  -40  -40  -40  -40  -40  -40  -40 
  -20  -20  -20  -20  -20  -20  -20  -20 
-40  -40  -40  -40  -40  -40  -40  -40 
  -40  -40  -40  -40  -40  -40  -40  -40 
-40  -40  -40  -40  -40  -40  -40  -40 
  -40  -40  -40  -40  -40  -40  -40  -40 
-40  -40  -40  -40  -40  -40  -40  -40 
  -40  -40  -40  -40  -40  -40  -40  -40 
-40  -40  -40  -40  -40  -40  -40  -40 
  -40  -40  -40  -40  -40  -40  -40  -40 
-20  -20  -20  -20  -20  -20  -20  -20 
  -40  -40  -40  -40  -40  -40  -40  -40 
  0   20   40  -20    0  -20   40   20 
  -40  -40  -40  -40  -40  -40  -40  -40 
16 8 * table kingLtPcSq

kingLtPcSq 8 CELLS + CONSTANT kingDkPcSq

VARIABLE lightScore      VARIABLE darkScore

  -20   0  -10  -20  -20  -20  -20  -25
8 table myCastledPawnRankPenalties

    0    0    0    0   -5  -10    0  -15 
8 table enemyCastledPawnRankPenalties

: evalLightKP ( file+1 -- value )
  DUP CELLS lightPawnRank + @ NEGATE 7 +
  CELLS myCastledPawnRankPenalties + @
  SWAP CELLS darkPawnRank + @
  CELLS enemyCastledPawnRankPenalties + @
  + ;

: evalDarkKP ( file+1 -- value )
  DUP CELLS darkPawnRank + @
  CELLS myCastledPawnRankPenalties + @
  SWAP CELLS lightPawnRank + @ NEGATE 7 +
  CELLS enemyCastledPawnRankPenalties + @
  + ;

1200 CONSTANT endgameThreshold
3100 CONSTANT maxPieceMat

: evalLK ( sq -- )
  darkPieceMat @ endgameThreshold U< IF
    CELLS kingEndgamePcSq + @
  ELSE
    DUP CELLS kingLtPcSq + @              ( sq value )
    SWAP file 
    DUP 3 U< IF DROP
      1 evalLightKP +
      2 evalLightKP +
      3 evalLightKP 2/ +
    ELSE 
      4 OVER U< IF DROP
        8 evalLightKP +
        7 evalLightKP +
        6 evalLightKP 2/ +
      ELSE
        DUP 3 + SWAP DO
          I openFile? IF 10 - THEN
        LOOP
      THEN 
    THEN
    darkPieceMat @ maxPieceMat */
  THEN
  lightScore +! ;

: evalDK ( sq -- )
  lightPieceMat @ endgameThreshold U< IF
    CELLS kingEndgamePcSq + @
  ELSE
    DUP CELLS kingDkPcSq + @              ( sq value )
    SWAP file 
    DUP 3 U< IF DROP
      1 evalDarkKP +
      2 evalDarkKP +
      3 evalDarkKP 2/ +
    ELSE 
      4 OVER U< IF DROP
        8 evalDarkKP +
        7 evalDarkKP +
        6 evalDarkKP 2/ +
      ELSE
        DUP 3 + SWAP DO
          I openFile? IF 10 - THEN
        LOOP
      THEN 
    THEN
    lightPieceMat @ maxPieceMat */
  THEN
  darkScore +! ;

: evalLP ( sq -- )
  DUP CELLS pawnPcSq + @                        ( sq value )
  SWAP DUP file 1+ CELLS 
  DUP lightPawnRank + 
  ROT rank  ( value f+1 ^lpr r )
  OVER @ OVER > IF
    DOUBLED_PAWN_PENALTY 
  ELSE 0 THEN >R
  OVER DUP CELL+ @ SWAP CELL- @ OR 
  0= IF
    R> ISOLATED_PAWN_PENALTY + >R NIP
  ELSE 
    OVER CELL+ @ ROT CELL- @ MAX 
    OVER U< IF
      R> BACKWARD_PAWN_PENALTY + >R 
    THEN 
  THEN          ( value f+1 r )
  SWAP darkPawnRank +
  DUP CELL+ @ OVER CELL- @ MIN SWAP @ MIN OVER U< 0= IF  ( value r )
    NEGATE 7 + PASSED_PAWN_BONUS * R> +
  ELSE 
    DROP R> 
  THEN 
  + lightScore +! ;

: evalDP ( sq -- )
  DUP rotate CELLS pawnPcSq + @                        ( sq value )
  SWAP DUP file 1+ CELLS 
  DUP darkPawnRank + 
  ROT rank  ( value f+1 ^lpr r )
  OVER @ OVER U< IF
    DOUBLED_PAWN_PENALTY 
  ELSE 0 THEN >R
  OVER DUP CELL+ @ SWAP CELL- @ AND 
  7 = IF
    R> ISOLATED_PAWN_PENALTY + >R NIP
  ELSE 
    OVER CELL+ @ ROT CELL- @ MIN OVER > IF
      R> BACKWARD_PAWN_PENALTY + >R 
    THEN 
  THEN          ( value f+1 r )
  SWAP lightPawnRank +
  DUP CELL+ @ OVER CELL- @ MAX SWAP @ MAX OVER > 0= IF  ( value r )
    PASSED_PAWN_BONUS * R> +
  ELSE DROP R> THEN
  +  darkScore +! ;

: evalLR ( sq -- )
  DUP file 1+ CELLS DUP lightPawnRank + @ 0= IF
    darkPawnRank + @ 7 = IF 
      ROOK_OPEN_FILE_BONUS
    ELSE 
      ROOK_SEMI_OPEN_FILE_BONUS 
    THEN  lightScore +!
  ELSE  DROP  THEN

  rank7? IF
    ROOK_ON_SEVENTH_BONUS lightScore +!
  THEN ;

: evalDR ( sq -- )
  DUP file 1+ CELLS DUP darkPawnRank + @ 7 = IF
    lightPawnRank + @ 0= IF 
      ROOK_OPEN_FILE_BONUS
    ELSE 
      ROOK_SEMI_OPEN_FILE_BONUS 
    THEN  darkScore +!
  ELSE  DROP  THEN

  rank2? IF
    ROOK_ON_SEVENTH_BONUS darkScore +!
  THEN ;

\ all the evalVector words are ( sq -- )
: noop ;
: evalLN        CELLS knightPcSq + @  lightScore +! ;
: evalLB        CELLS bishopPcSq + @  lightScore +! ;
: evalDN rotate CELLS knightPcSq + @   darkScore +! ;
: evalDB rotate CELLS bishopPcSq + @   darkScore +! ;
: evalQ  drop ;
: evalNil DROP ;

  ' noop    ' evalLP   ' evalLN   ' evalLB 
  ' evalLR  ' evalNil  ' evalLK   ' evalNil 
  ' noop    ' noop     ' noop     ' noop  
  ' noop    ' noop     ' noop     ' evalNil 
  ' noop    ' evalDP   ' evalDN   ' evalDB 
  ' evalDR  ' evalNil  ' evalDK   ' evalNil 
24 table evalVector

: evalSq ( sq -- )
    DUP bd@ ?DUP 
      IF 16 - CELLS evalVector + a@ EXECUTE 
    ELSE DROP THEN ;

: eval ( -- value )
  lightPieceMat @ lightPawnMat @ + lightScore !
   darkPieceMat @  darkPawnMat @ +  darkScore !
  ['] evalSq forEverySq
  wtm? IF lightScore @ darkScore @ -
  ELSE darkScore @ lightScore @ - THEN ;

: xEvalDump
  BASE @ >R DECIMAL CR
  lightScore @ . ." =" lightPieceMat @ . ." +" lightPawnMat @ . ." (P) / "
   darkScore @ . ." ="  darkPieceMat @ . ." +"  darkPawnMat @ . ." (p)" CR
  10 0 DO I CELLS lightPawnRank + @ . LOOP ." /"
  10 0 DO I CELLS  darkPawnRank + @ . LOOP CR
  R> BASE ! ;

\ *** Search ***

VARIABLE nodes          \ must be 32-bit (or higher for long searches)

\ Win32Forth word ms@ returns number of milliseconds since system start.
\ More accurate is GetTickCount
\ Define as appropriate for your Forth dialect

1000 CONSTANT msPerS
3600000 VALUE msMaxThinkTime

[UNDEFINED] ms@ [IF]
  [DEFINED] ?MS [IF]
  : ms@ ?MS ;           \ iForth
  [ELSE]
  [DEFINED] utime [IF]
  : ms@ utime 1000 um/mod nip ;  \ gforth
  [ELSE]
  5 CONSTANT npms
  : ms@  nodes @ npms / ;
  [THEN] [THEN]
[THEN]

: .ms ( n -- )
  msPerS /MOD 4 .R ." ." 0 <# # # # #> TYPE ;

VARIABLE msStart
: startTimer ms@ msStart ! ;
: readTimer ( -- ms ) ms@ msStart @ - ;

VARIABLE stopSearch
0 VALUE keyHit

: checkTime ( -- tf )
  readTimer msMaxThinkTime >
  KEY? DUP IF 
    KEY to keyHit
  THEN
  OR DUP IF
    DUP stopSearch ! 
    ." Time's up! " readTimer .ms ."  seconds" CR 
  THEN ;

\ pick the best move from those generated: move it to the front

: sort ( ^from -- )             \ from points into gen_dat
  DUP -1                    ( ^from ^best bestScore )
  OVER lastMovePly SWAP ?DO
    DUP  I CELL+ @ < IF
      2DROP  I  I CELL+ @
    THEN
  genSize +LOOP
  >R  DUP @ >R               \ best -> temp ( ^from ^best  R: bScore bMove )
  OVER @ OVER !  OVER CELL+ @ SWAP CELL+ !    \ from -> best ( ^from )
  R> OVER !  R> SWAP CELL+ ! ;     \ temp -> from

\ principal variation tracking

VARIABLE followPV
CREATE pv MAX_PLY MAX_PLY* CELLS ALLOT
CREATE pvEnd MAX_PLY CELLS ALLOT        \ pointer into pv

: pvErase pv MAX_PLY MAX_PLY* CELLS ERASE ;

: getPV ( ply -- ^mv ) CELLS DUP MAX_PLY* + pv + ;
: getPVend ( ply -- ^mv ) CELLS pvEnd + @ ;
: setPVend ( end ply -- ) CELLS pvEnd + ! ;
: resetPVend ( ply -- ) DUP getPV SWAP setPVend ;

\ iterative deepening search is optimal if we first follow the previous PV

: sortPV ( -- )
  FALSE followPV !
  ply @ CELLS pv + @            \ pv[0][ply]
  forMovesAtPly ?DO
    DUP I @ = IF
      TRUE followPV !
      mvSortFirst 4 LSHIFT I CELL+ +!         \ update score to sort first
      LEAVE
    THEN
  genSize +LOOP         \ test with .xHist here
  DROP ;

: updatePV ( mv -- )            \ copy mv + pv[ply+1] to pv[ply]
  ply @ getPV TUCK !
  CELL+
  ply @ 1+ DUP getPVend SWAP getPV ?DO
    I @ OVER ! CELL+
  moveSize +LOOP
  ply @ setPVend ;

: .pv ( -- )
  pvEnd @ pv ?DO I @ .move SPACE moveSize +LOOP ;

CREATE repsBd numSquares CELLS ALLOT

: reps ( -- n )
  fifty @ 4 U< IF 0 EXIT THEN
  repsBd numSquares CELLS ERASE 0 0  ( reps count )
  histTop a@ histSize - DUP fifty @ 1- histSize* - SWAP DO
    I @ mvFrom asIndex CELLS  repsBd +  DUP >R  @ 1+  DUP >R
    0= IF 1- ELSE 1+ THEN R> R> !
    I @ mvTo asIndex CELLS  repsBd +  DUP >R  @ 1-  DUP >R
    0= IF 1- ELSE 1+ THEN R> R> !
    DUP 0= IF >R 1+ R> THEN
  histSize NEGATE +LOOP DROP ;

0 CONSTANT drawScore
100 CONSTANT 50moveCount        \ ply 2*
-10000 CONSTANT mateScore
-100000 CONSTANT abortScore

: quiesce ( a b -- value )   ( adds -b -a -- when recursing )
  nodes @ 1+ DUP nodes !
  [ hex 3FF decimal ] literal  AND 0= 
  IF checkTime IF 2DROP abortScore EXIT THEN THEN
  ply @ DUP resetPVend
  1+ MAX_PLY > histTop a@ 1+ histMax > OR IF 2DROP eval EXIT THEN
  eval ( a b e )
  2DUP > 0= IF DROP NIP EXIT THEN      \ b <= e: return beta 
  ROT MAX ( b a )               \ a < e:  a = e
  genCaps
  followPV @ IF sortPV THEN
  forMovesAtPly ?DO          \ foreach move
    I sort
    I @ makeMove IF
      \ ply @ dup 1- spaces ." q " .xHist depth . xPause cr
      OVER NEGATE OVER NEGATE RECURSE NEGATE  ( b a value )   \ negamax
      takeBack
      2DUP < IF                         \ value > a: new best move
        stopSearch @ IF DROP 2DROP abortScore UNLOOP EXIT THEN
        >R OVER R@ > 0= IF       \ value >= b: cutoff
          R> 2DROP UNLOOP EXIT THEN     \ return beta
        DROP R>                         \ a = value
        I @ updatePV
      ELSE DROP THEN
    THEN
  genSize +LOOP
  NIP ;            \ return alpha

\ these two things would normally be on the call frame

VARIABLE _depth

CREATE searchFlags MAX_PLY CELLS ALLOT

\ For MAX_PLY 32, we could also use two unsigned 32-bit cells
\  with flags addressed by "1 ply @ LSHIFT"

: sfPly ( -- ^flags ) ply @ CELLS searchFlags + ;
: sfClear 0 sfPly ! ;
: sfCheck! 1 sfPly +! ;
: sfCheck? sfPly @ 15 AND ;
: sfMoves!  16 sfPly +! ;
: sfMoves?  sfPly @ [ hex FF0 decimal ] literal AND ;

VARIABLE lastScore

: .searchHeader ." ply    nodes    time score pv" CR ;

\ code char: BL depth complete, '&' new best move, '-' '+' fail low/high

: .searchStatus ( value codeChar -- )
  \ BASE @ >R DECIMAL
  EMIT DUP lastScore !
  _depth @ 2 .R nodes @ 9 .R
  readTimer .ms
  ( value ) 6 .R SPACE .pv CR ;
  \ R> BASE ! ;

: _search ( a b -- value )     \ recursive
  nodes @ 1+ DUP nodes !
  [ hex 3FF decimal ] literal AND 0= 
  IF checkTime IF 2DROP abortScore EXIT THEN THEN
  ply @ DUP resetPVend
  DUP IF reps IF DROP 2DROP drawScore EXIT THEN THEN    \ draw: repeated pos
  1+ MAX_PLY > histTop a@ 1+ histMax > OR IF 2DROP eval EXIT THEN
  sfClear
  side @ inCheck? IF sfCheck! ( ." +" ) \ extend search a ply
  ELSE -1 _depth +! THEN     \ need to undo before exit
  NEGATE SWAP  ( -b a )
  gen
  followPV @ IF sortPV THEN
  forMovesAtPly ?DO          \ foreach move
    I sort
    I @ makeMove IF          \ ply++
      \ ply @ dup 1- spaces .xHist depth . xPause cr
      2DUP NEGATE _depth @ IF RECURSE ELSE quiesce THEN NEGATE  \ negamax
      ( -b a value )
      takeBack               \ ply--
      sfMoves!
      \ ply @ spaces ." v,a=" 2dup . . xPause cr
      2DUP < IF                         \ value > a: new best move
        stopSearch @ IF DROP 2DROP abortScore UNLOOP EXIT THEN
        _depth @ 1+ I @ DUP mvFrom SWAP mvTo ^history +!
        >R OVER NEGATE R@ > 0= IF R>    \ value >= b: cutoff
          sfCheck? 0= IF 1 _depth +! THEN
          ply @ 0= IF I @ pv !  pv CELL+ pvEnd ! THEN  \ save fail-high move
          2DROP NEGATE UNLOOP EXIT      \ return beta
        THEN
        DROP R>                         \ a = value
        I @ updatePV
        ply @ 0= IF 2 _depth @ U< IF DUP [CHAR] & .searchStatus THEN THEN
      ELSE DROP THEN
    THEN
  genSize +LOOP

  sfMoves? IF
    sfCheck? 0= IF 1 _depth +! THEN
    fifty @ 50moveCount U< IF NIP        \ return alpha
    ELSE 2DROP drawScore THEN           \ draw, 50-move rule
  ELSE
    \ ." mate" sfPly @ . .board xgendump xPause
    2DROP
    sfCheck? IF mateScore ply @ +       \ checkmate
    ELSE 1 _depth +! drawScore THEN     \ stalemate
  THEN ;

VARIABLE maxDepth

: startDepth ( -- n )
\ experiment: jumpstart search if played expected move
\  histTop @ histSize 2* - DUP hist_dat - 0< 0= IF
\    DUP @ pv @ = IF
\      histSize + @ pv CELL+ @ = IF
\        pvEnd @ pv - 2 RSHIFT 2 - DUP 1 > IF     ( depth )
\          pvEnd @ pv CELL+ CELL+ DO
\            I @ I CELL- CELL- !
\          moveSize +LOOP
\          0 CELL- CELL- pvEnd +!
\          EXIT
\        ELSE DROP THEN
\      THEN
\    ELSE DROP THEN
\  ELSE DROP THEN
  pvErase 1 ;

: think ( -- )
  0 stopSearch !
  0 ply !
  historyErase
  CR .searchHeader
  startTimer
  mateScore DUP NEGATE quiesce lastScore !
  0 nodes !
  maxDepth @ startDepth DO                       \ iterative deepening
    TRUE followPV !
    I _depth !
    lastScore @ DUP pawnValue 2/ - SWAP pawnValue 2/ +
    2DUP _search  ( l-p l+p value )
    mateScore ABS OVER ABS U< IF I _depth ! DROP 2DROP LEAVE THEN \ time ran out
    2DUP > 0= IF   \ fail high: re-search l+p inf
      [CHAR] + .searchStatus
      mateScore NEGATE _search
    ELSE NIP
    2DUP < 0= IF    \ fail low: re-search -inf l-p
      [CHAR] - .searchStatus
      mateScore OVER _search
    THEN THEN NIP ( value )
    DUP BL .searchStatus
    ABS 100 + mateScore ABS > IF LEAVE THEN
  LOOP
  \ lastScore @ [CHAR] ! .searchStatus
  readTimer ?DUP IF
    nodes @ msPerS ROT */
  ELSE
    ." at least " nodes @
  THEN . ." nps " ;

\ *** high level (validated) ***

: initVars ( -- )
  0 ply !  0 ep !  0 fifty !
  evalSetup  initHist 
  init_first  ;

HEX

: initBoard ( -- )
  eraseBoard
  ROOK KNIGHT BISHOP KING QUEEN BISHOP KNIGHT ROOK
  08 00 DO 
    DUP DARK + I      bd!         \ top row of pieces
    DARKPAWN   I 10 + bd!         \ pawns
    LIGHTPAWN  I 60 + bd!         \ pawns
    LIGHT +    I 70 + bd!         \ bottom row of pieces
  LOOP
  sqE1 lkSq ! sqE8 dkSq !
  F castle !
  LIGHT side !
  initVars ;

: str>sq ( c-addr -- sq T | F )
  DUP c@ tolower [CHAR] a - ( ^c file )
  SWAP CHAR+ c@ [CHAR] 8 SWAP - ( file rank )
  2DUP OR 0 8 WITHIN IF
    fileRank>sq TRUE
  ELSE 2DROP FALSE THEN ;

: charPiece ( c -- piece | 0 )
  0 SWAP
  KING 1+ PAWN DO
    I CELLS symbols + @
    2DUP = IF 2DROP
      LIGHT I OR SWAP LEAVE
    ELSE tolower OVER = IF DROP
      DARK I OR SWAP LEAVE
    THEN THEN
  LOOP DROP ;

: inmv ( "e2e4" -- mv T | F )        \ usage: inmv e2e4
  BASE @ >R DECIMAL              \ important! e2e4 is a hex number!
  BL WORD COUNT   ( str count )
  R> BASE !
  3 > IF
    DUP str>sq IF
      OVER CHAR+ CHAR+ str>sq IF  ( str from to )
        8 LSHIFT OR  ( str packedMv )
        0 ply !
        gen
        forMovesAtPly ?DO
          DUP I @ FFFF AND = IF
            DROP I        \ found! its legal
            DUP @ mvPromoteBit AND IF   \ get promotion piece
              3 \ default to queen
              ROT 4 CHARS + c@
              charPiece piece KNIGHT -
              DUP 0< 0= OVER 4 < AND IF NIP ELSE DROP THEN
              genSize* +
            ELSE NIP THEN
            @ TRUE UNLOOP EXIT
          THEN
        genSize +LOOP
        CR ." Illegal move." 2DROP FALSE EXIT
      ELSE 2DROP THEN
    ELSE DROP THEN
  ELSE DROP THEN CR ." Malformed move." FALSE ;

: epd ( "epd" "w|b" -- tf )
  0 >R                             \ R: current sq
  eraseBoard
  BL WORD COUNT OVER + SWAP   ( ^end ^cur )
  DUP c@ [CHAR] / = IF CHAR+ THEN
  BEGIN
    DUP c@
    DUP [CHAR] 1 -
    DUP 0 8 WITHIN IF
      R> + 1+ >R                \ 1-8 empty squares
    ELSE DROP DUP [CHAR] / = IF
      R> rank 1+ 4 LSHIFT >R    \ next rank, 1st file
    ELSE DUP charPiece ?DUP IF
      DUP piece KING = IF
        \ !!! check for multiple kings
        DUP light? IF R@ lkSq ELSE R@ dkSq THEN !
      THEN
      R> TUCK bd! 1+ >R         \ piece
    ELSE
      ." Bad EPD character: " EMIT ." at " R> .sq CR 2DROP FALSE EXIT
    THEN THEN THEN
  DROP CHAR+ 2DUP = UNTIL 2DROP
  R> DROP
  \ !!! check that each has a king
  BL WORD COUNT 1 = IF
    c@ tolower DUP [CHAR] w = IF DROP LIGHT side !
    ELSE [CHAR] b = IF DARK side !
    ELSE ." Bad color" CR FALSE EXIT THEN THEN
  ELSE DROP ." Bad color " CR FALSE EXIT THEN
  0 castle !            \ !!! read a KQkq|- word
  initVars
  side @ otherSide inCheck? 0= ;

: .result? ( -- tf )
  FALSE 0 ply ! gen
  TRUE forMovesAtPly ?DO
    I @ makeMove IF takeBack DROP FALSE LEAVE THEN
  genSize +LOOP
  IF CR
    side @ inCheck? IF
      wtm? IF ." White " ELSE ." Black " THEN ." is checkmated."
    ELSE
      ." Stalemate."
    THEN
    DROP TRUE
  ELSE reps 3 = IF
    CR ." Draw by repetition." DROP TRUE
  ELSE fifty @ 50moveCount = IF
    CR ." Draw by fifty-move rule." DROP TRUE
  THEN THEN THEN ;

: retract histTop @ hist_dat = 0= IF takeback THEN ;

\ *** User Commands ***

: newGame initBoard .board ;            \ setup a new game

: sd ( n -- ) 1+ MAX_PLY 2/ MIN maxDepth ! ;

: st ( seconds -- ) msPerS * TO msMaxThinkTime ;

: go                  \ ask the computer to choose move
  think               \  press any key to stop thinking and make a move
  pv @ ?DUP IF
    ." Move found: " DUP .move CR
    makeMove DROP .board
  THEN .result? DROP ;

: mv ( "e2e4" -- )    \ for alternating turns with the computer
  inmv IF             \ if promoting:  "a7a8Q"
    makeMove IF .board .result? 0= IF go THEN
    ELSE CR ." Can't move there." THEN
  THEN ;

: domove ( "e2e4" -- )  \ for forcing a sequence of moves
  inmv IF
    makeMove IF .board .result? DROP
    ELSE CR ." Can't move there." THEN
  THEN ;

: undo retract .board ;   \ take back one ply (switches sides)

: undo2 retract retract .board ;   \ take back one full move

: whoseTurn? wtm? IF ." White to move." ELSE ." Black to move." THEN CR ;
: .whoseTurn whoseTurn? ;

: rotateBoard blackAtBottom? @ 0= blackAtBottom? ! .board ;
: showCoords showCoords? @ 0= showCoords? ! .board ;

: auto ( d1 d2 -- )
  BEGIN
    OVER sd go .result? IF 2DROP EXIT THEN
    DUP sd go .result? IF 2DROP EXIT THEN
  KEY? UNTIL 2DROP ;

\ : putPiece ( "[.PNBRQK]" "sq" ) ;

\ EPD position setup (great for testing)
\ examples:  setup rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR W
\ setup 2r2rk1/1bqnbpp1/1p1ppn1p/pP6/N1P1P3/P2B1N1P/1B2QPP1/R2R2K1 b

: setup ( "epd" "w|b" -- )
  epd IF .board whoseTurn? THEN ;

: bench   \ Fischer-Sherwin NJ Championships 1957, move 17 
  S" setup 1rb2rk/p4ppp/1p1qp1n/3n2N/2pP4/2P3P/PPQ2PBP/R1B1R1K w" evaluate
  5 sd  
  think readTimer      \ best of three
  think readTimer MIN
  think readTimer MIN 
  CR ." Results: "
  DUP nodes @ msPerS ROT */ . ." nps" 
  DROP ;

\ !!! need validation routines for regression testing?

\ __saveBase @ BASE !

: tscp-help  CR
." tscp-help    Show this help list of commands" CR
." go           Make the computer move (hit any key to stop thinking)" CR
." domove e2e4  Move a piece from square e2 to square e4" CR
." undo         Take back the last move" CR
." mv h7h8Q     domove h7h8Q go (promote to a queen)" CR
." mv e1g1      castle kingside" CR
." undo2        undo undo" CR
." 5 sd         Set maximum depth for computer search" CR
." 10 st        Set maximum thinking time in seconds" CR
." newGame      Start a new game" CR
." rotateBoard  Display board rotated by 180 degrees" CR
." showCoords   Display toggle algebraic coordinates" CR
." .board       Display the board" CR
." .moveList    Display the list of moves played so far" CR
." .epd         Display the EPD description of the board" CR
." .whoseTurn   Display which color moves next" CR
." setup EPD    Setup an EPD position" CR
;

\ *** EXECUTE WHEN LOADING ***

CR .( TSCP 0.4.6 loaded ) CR
tscp-help CR
4 sd
true showCoords? !
newGame

DECIMAL

