\ tscp-tgfx.4th
\
\ TSCP chess program with Text Graphics
\
\ Copyright (c) 2006 Krishna Myneni,
\ Creative Consulting for Research and Education
\
\ Notes:
\
\  0. Command line input is still used, but the board and
\     pieces are displayed using color and multicharacter
\     ascii art.
\
\  1. A minimum console size of 45 rows is required.
\
\ Revisions:
\   2007-11-12  km; added help command
\   2007-11-14  km; revised handling of move output and status info;
\                   factored out unfinished code.
\   2020-11-12  km; include ans-words.4th

include ans-words
include games/tscp
include games/chessboard

0 value square

pawn   new  pawn-piece     \ 1 
knight new  knight-piece   \ 2 
bishop new  bishop-piece   \ 3 
rook   new  rook-piece     \ 4 
queen  new  queen-piece    \ 5
king   new  king-piece     \ 6
6 table tscp-pieces


: draw-grid-cell ( gx gy -- | draw the cell)
    2>r
    2r@ grid>xy CBWIDTH CBHEIGHT
    2r@ grid>darkcell? IF
      LIGHTCELL DARKCELL DARKCELL 
    ELSE
      DARKCELL LIGHTCELL LIGHTCELL 
    THEN
    cb1 tb-init
    cb1 tb-draw

    \ Draw the piece

    2r> frSq blackAtBottom? @ IF rotate THEN TO square
    square bd@ piece
    ?dup IF 
      1- cells tscp-pieces + a@
      square file square rank 2>R dup 2R> rot cp-init  
      square bd@ dark? IF BLACKPIECECOLOR ELSE WHITEPIECECOLOR THEN
      over cp-fg !
      cp-draw
    THEN       
;

: highlight-grid-cell ( gx gy -- | draw highlight border around specified grid cell)
    grid>xy AT-XY RED background 32 emit ;  

: show-grid-coords ( -- )
    showCoords? @ IF
      \ Show horizontal coords
      CBWIDTH 2/ 5 +  CBHEIGHT 8 * 2+ AT-XY
      blackAtBottom? @ IF 
        [char] H 8 0 DO DUP EMIT 1- CBWIDTH 1- SPACES LOOP 
      ELSE 
        [char] A 8 0 DO DUP EMIT 1+ CBWIDTH 1- SPACES LOOP  
      THEN
      DROP
      \ Show vertical coords 
      
      8 0 DO 
        2 CBHEIGHT I * CBHEIGHT 2/ + 1+ AT-XY
	blackAtBottom? @  IF  I 1+  ELSE  8 I -  THEN 1 .R
      LOOP
    THEN
;

\ Define .TEXTBOARD" to draw text graphics board
0 constant STATUS_ROW
8 CBHEIGHT * 3 + constant COMMAND_ROW


: .textboard ( -- | draw the board and pieces in their current positions)
    8 0 DO  8 0 DO J I draw-grid-cell LOOP LOOP
    text_normal
    show-grid-coords
;

: .status ( a u -- | display status message )
    0 STATUS_ROW AT-XY clrtoeol
    0 STATUS_ROW AT-XY TYPE ;

   
\ Redefine tscp user commands to use .TEXTBOARD 

: new init_board page .textboard ;            \ setup a new game

: go                  \ ask the computer to choose move
    s" Thinking ..." .status
    s" >file /dev/null" evaluate  \ redirect output
    think               \  press any key to stop thinking and make a move
    console  \ restore output to console
    pv @ ?DUP IF
	s" Move found: " .status DUP .move
	makeMove DROP .textboard
    THEN 0 STATUS_ROW at-xy .result? DROP ;

: mv ( "e2e4" -- )    \ for alternating turns with the computer
    inmv IF             \ if promoting:  "a7a8Q"
	makeMove IF
	    .textboard .result? 0= IF
		0 COMMAND_ROW at-xy go THEN
	ELSE s" Can't move there." .status THEN
    ELSE
	s" Can't move there." .status
    THEN ;

: undo retract .textboard ;   \ take back one ply (switches sides)

: undo2 retract retract .textboard ;   \ take back one full move

: whoseTurn? wtm? IF s" White to move." ELSE s" Black to move." THEN .status ;

: help
    PAGE
    CR
    CR ." User Commands:"
    CR
    CR ."    mv xnym    -- move a piece from its current position"
    CR ."                  xn to its new position ym, e.g. 'mv e2e4'"
    CR
    CR ."    go         -- let computer make your next move."
    CR
    CR ."    new        -- start a new game."
    CR
    CR ."    undo       -- take back one ply."
    CR
    CR ."    undo2      -- take back one full move."
    CR
    CR ."    whoseTurn? -- tell whose turn."
    CR
    CR ."    n sd       -- set level of difficulty to n, e.g. '4 sd'"
    CR
    CR ."    bye        -- quit the game and exit Forth"
    CR
    CR ." Press any key to continue."
    KEY DROP
    PAGE .textboard
;

create cmd 16 allot

: start
    PAGE .textboard
    s" TSCP 0.4  Type 'help' for list of commands" .status
    BEGIN
      0 COMMAND_ROW  AT-XY  12 spaces
      0 COMMAND_ROW  AT-XY  [char] > EMIT
      cmd 10 accept
      cmd swap evaluate
    AGAIN  
;

start

0 [IF] \ ============ keyboard mode (not yet implemented) =============
4 value gxCur
6 value gyCur

BASE @
hex

1B5B44  CONSTANT  left-key     ( cursor left  )
1B5B43  CONSTANT  right-key    ( cursor right )
1B5B41  CONSTANT  up-key      ( cursor up    )			
1B5B42  CONSTANT  down-key     ( cursor down  )

BASE !

: EKEY ( -- u | return extended key as concatenated byte sequence )
       BEGIN key? UNTIL
       0 BEGIN  key?  WHILE  8 LSHIFT key or  REPEAT ;

gxCur value gxCur0
gyCur value gyCur0
0 value gxSel
0 value gySel

: start-keymode
    PAGE .textboard
    s" TSCP 0.4  Type 'help' for list of commands" .status
    EKEY
    CASE
        27	  OF  text_normal EXIT         ENDOF
        32        OF  select-piece             ENDOF
	UP-KEY    OF  gyCur dup TO gyCur0 1- 0 MAX TO gyCur  ENDOF
	DOWN-KEY  OF  gyCur dup TO gyCur0 1+ 7 MIN TO gyCur  ENDOF
	LEFT-KEY  OF  gxCur dup TO gxCur0 1- 0 MAX TO gxCur  ENDOF
	RIGHT-KEY OF  gxCur dup TO gxCur0 1+ 7 MIN TO gxCur  ENDOF
    ENDCASE
    gxCur0 gyCur0 draw-grid-cell
    gxCur  gyCur  highlight-grid-cell
     
[THEN]
  
