( *
 * LANGUAGE    : ANS Forth with extensions
 * PROJECT     : Forth Environments
 * DESCRIPTION : Examples
 * CATEGORY    : Games
 * AUTHOR      : Dirk Uwe Zoller, April 5, 1994 
 * REVISED     : May 31, 1994, Marcel Hendrix
 * REVISED     : February 27, 2004, Krishna Myneni [for kForth] 
 * )

\
\ tetris.4th	Tetris for terminals, redone in ANSI-Forth.
\		Written 05Apr94 by Dirk Uwe Zoller, e-mail:
\			duz@roxi.rz.fht-mannheim.de.
\		Look&feel stolen from Mike Taylor's "TETRIS FOR TERMINALS"
\
\		Please copy and share this program, modify it for your system
\		and improve it as you like. But don't remove this notice.
\
\		Thank you.
\

\ ======= kForth requires
include ans-words.4th
include strings.4th
include ansi.4th
include utils.4th
: D<> D= INVERT ;
: >UPC 95 AND ;
: EKEY ( -- u | return extended key as concatenated byte sequence )
       BEGIN key? UNTIL
       0 BEGIN  key?  WHILE  8 LSHIFT key or  REPEAT ;

\ Pseudo-random number generation
variable last-rn
time&date 2drop 2drop drop last-rn !  \ seed the rng

: lcrng ( -- n ) last-rn @ 31415928 * 2171828 + 31415927 mod dup last-rn ! ;

: next_ran ( -- n | random number from 0 to 255 )
        0 8 0 do 1 lshift lcrng 1 and or loop ;

: choose ( n -- n' | arbitrarily choose a number between 0 and n-1)
        dup next_ran * 255 / swap 1- min ;

: ctable ( ... n -- ) dup >r create ?allot dup r> + 1-
    ?do  i c! -1 +loop ;

\ ========================

\ Variables, constants

BL BL 2CONSTANT empty		\ an empty position
0 VALUE wiping			\ if true: wipe brick, else draw brick
2 CONSTANT col0			\ position of the pit on screen
0 CONSTANT row0		
25 constant L/SCR

10 CONSTANT wide		\ size of pit in brick positions
20 CONSTANT deep		

\ Alter these key code sequences if your terminal handles
\   window provides different codes. The ones coded here are
\   for the xterm terminal window under X-windows.
HEX
1B5B44  CONSTANT  left-key     ( cursor left  )
1B5B43  CONSTANT  right-key    ( cursor right )
1B5B41  CONSTANT  rot-key      ( cursor up    )			
1B5B42  CONSTANT  drop-key     ( cursor down  )
    0C  CONSTANT  refresh-key  ( Ctrl-L       )    
CHAR P  CONSTANT  pause-key
CHAR Q  CONSTANT  quit-key
DECIMAL	

0 VALUE score		
0 VALUE pieces		
0 VALUE levels		
0 VALUE delay		

0 VALUE brow			\ where the brick is
0 VALUE bcol 		


\ Access pairs of characters in memory:

: 2C@		DUP 1+ C@  SWAP C@ ;
: 2C!		DUP >R C!  R> 1+ C! ;


\ Drawing primitives:

: 2EMIT		EMIT EMIT ;

: POSITION	\ row col --- ; cursor to the position in the pit
		2* col0 + SWAP row0 + AT-XY ;

: STONE		\ c1 c2 --- ; draw or undraw these two characters
		wiping IF  2DROP 2 SPACES  ELSE  2EMIT  THEN ;


\ Define the pit where bricks fall into:

: DEF-PIT	CREATE	
			wide deep * 2* ALLOT
		DOES>	ROT wide * ROT + 2* + ;

DEF-PIT PIT

: EMPTY-PIT	deep 0 DO 
			  wide 0 DO  empty J I PIT 2C! LOOP 
		     LOOP ;


\ Displaying:

: DRAW-BOTTOM	\ --- ; redraw the bottom of the pit
		deep -1 POSITION  [CHAR] + DUP STONE
		wide 0 DO  [CHAR] = DUP STONE  LOOP  [CHAR] + DUP STONE ;

: DRAW-FRAME	\ --- ; draw the border of the pit
		deep 
		0 DO
		    I -1   POSITION [CHAR] | DUP STONE
		    I wide POSITION [CHAR] | DUP STONE
		LOOP  DRAW-BOTTOM ;

: BOTTOM-MSG	\ addr cnt --- ; output a message in the bottom of the pit
		deep OVER 2/ wide SWAP - 2/ POSITION TYPE ;

: DRAW-LINE	\ line ---
		DUP 0 POSITION  wide 0 DO  DUP I PIT 2C@ 2EMIT  LOOP  DROP ;

: DRAW-PIT	\ --- ; draw the contents of the pit
		deep 0 DO  I DRAW-LINE  LOOP ;

: SHOW-HELP	\ --- ; display some explanations
		30   1 AT-XY ." ***** T E T R I S *****"
		30   2 AT-XY ." ======================="
		30   4 AT-XY ." Use keys:"
		32   5 AT-XY ." <--  Move left"
		32   6 AT-XY ." Up   Rotate"
		32   7 AT-XY ." -->  Move right"
		32   8 AT-XY ." Down Drop"
		32   9 AT-XY ." `P'  Pause"
		32  10 AT-XY ." ^L   Refresh"
		32  11 AT-XY ." `Q'  Quit"
		32  13 AT-XY ." -> "
		30  16 AT-XY ." Score:"
		30  17 AT-XY ." Pieces:"
		30  18 AT-XY ." Levels:"
		 0  22 AT-XY ."  ==== This program was written 1994 in pure dpANS Forth by Dirk Uwe Zoller ===="
		  0 23 at-xy ."  =================== Copy it, port it, play it, enjoy it! =====================" ;

: UPDATE-SCORE	\ --- ; display current score
		38 16 AT-XY score  3 .R
		38 17 AT-XY pieces 3 .R
		38 18 AT-XY levels 3 .R ;

: REFRESH	\ --- ; redraw everything on screen
		PAGE DRAW-FRAME DRAW-PIT SHOW-HELP UPDATE-SCORE ;


\ Define shapes of bricks:


: DEF-BRICK	CREATE 32 ?ALLOT
		4 0 DO NIP 2DUP 8 CMOVE NIP 8 + LOOP DROP
		DOES>	ROT 4 * ROT + 2* + ;


                	S"         "
			S" ######  "
			S"   ##    "
			S"         "
DEF-BRICK BRICK1
\ ------------------------------------------

                	S"         "
			S" <><><><>"
			S"         "
			S"         "
DEF-BRICK BRICK2
\ ------------------------------------------

                 	S"         "
			S"   {}{}{}"
			S"   {}    "
			S"         "
DEF-BRICK BRICK3
\ -----------------------------------------

                 	S"         "
			S" ()()()  "
			S"     ()  "
			S"         "
DEF-BRICK BRICK4
\ ------------------------------------------

                       	S"         "
			S"   [][]  "
			S"   [][]  "
			S"         "
DEF-BRICK BRICK5
\ ------------------------------------------

                       	S"         "
			S" @@@@    "
			S"   @@@@  "
			S"         "
DEF-BRICK BRICK6
\ ------------------------------------------

                   	S"         "
			S"   %%%%  "
			S" %%%%    "
			S"         "
DEF-BRICK BRICK7
\ ------------------------------------------

\ this brick is actually in use:

                	S"         "
			S"         "
			S"         "
			S"         "
DEF-BRICK BRICK
\ -------------------------------------------

                 	S"         "
			S"         "
			S"         "
			S"         "
DEF-BRICK SCRATCH
\ -------------------------------------------

		' BRICK1   ' BRICK2   ' BRICK3   ' BRICK4 
		' BRICK5   ' BRICK6   ' BRICK7 
7 table BRICKS


		1  2  3  3  4  5  5 
7 ctable brick-val

: IS-BRICK	\ brick --- ; activate a shape of brick
		>BODY ['] BRICK >BODY 32 CMOVE ;

: NEW-BRICK	\ --- ; select a new brick by random, count it
		1 pieces + TO pieces  
		7 CHOOSE BRICKS OVER CELLS + a@ IS-BRICK
		brick-val SWAP + C@ score + TO score ;

: ROTLEFT	4 0 DO 
			4 0 DO  J I BRICK 2C@  3 I - J SCRATCH 2C!  LOOP 
		  LOOP
		['] SCRATCH IS-BRICK ;

: ROTRIGHT	4 0 DO 
		 	4 0 DO   J I BRICK 2C@  I 3 J - SCRATCH 2C!  LOOP 
		  LOOP
		['] SCRATCH IS-BRICK ;

: DRAW-BRICK	\ row col ---
		4 0 DO 
			4 0 DO
				J I BRICK 2C@  empty D<>
				   IF   OVER J + OVER I +  POSITION
			 		J I BRICK 2C@  STONE
				THEN
			  LOOP 
		  LOOP  2DROP ;

: SHOW-BRICK	FALSE TO wiping DRAW-BRICK ;
: HIDE-BRICK	TRUE  TO wiping DRAW-BRICK ;

: PUT-BRICK	\ row col --- ; put the brick into the pit
		4 0 DO 4 0 DO
		    J I BRICK 2C@  empty D<>
		       IF  OVER J +  OVER I +  PIT
		  	   J I BRICK 2C@  ROT 2C!
		    THEN
		LOOP LOOP  2DROP ;

: REMOVE-BRICK	\ row col --- ; remove the brick from that position
		4 0 DO 4 0 DO
		    J I BRICK 2C@  empty D<>
		    IF  OVER J + OVER I + PIT empty ROT 2C!  THEN
		LOOP LOOP  2DROP ;

: TEST-BRICK	\ row col --- flag ; could the brick be there?
		4 0 DO 4 0 DO
		    J I BRICK 2C@ empty D<>
		       IF  OVER J +  OVER I +
		 	   OVER DUP 0< SWAP deep >= OR
			   OVER DUP 0< SWAP wide >= OR
			   2SWAP PIT 2C@  empty D<>
			   OR OR IF  UNLOOP UNLOOP 2DROP FALSE  EXIT  THEN
		    THEN
		LOOP LOOP  2DROP TRUE ;

: MOVE-BRICK	\ rows cols --- flag ; try to move the brick
		brow bcol REMOVE-BRICK
		SWAP brow + SWAP bcol + 2DUP TEST-BRICK
		   IF  brow bcol HIDE-BRICK
		       2DUP TO bcol TO brow  2DUP SHOW-BRICK PUT-BRICK  TRUE
		 ELSE  2DROP brow bcol PUT-BRICK  FALSE
		THEN ;

: ROTATE-BRICK	\ flag --- flag ; left/right, success
		brow bcol REMOVE-BRICK
		DUP IF  ROTRIGHT  ELSE  ROTLEFT   THEN
		brow bcol TEST-BRICK
		OVER IF  ROTLEFT  ELSE  ROTRIGHT  THEN
		   IF  brow bcol HIDE-BRICK
		       IF  ROTRIGHT  ELSE  ROTLEFT  THEN
		       brow bcol PUT-BRICK
		       brow bcol SHOW-BRICK  TRUE
		 ELSE  DROP FALSE  
		THEN ;

: INSERT-BRICK	\ row col --- flag ; introduce a new brick
		2DUP TEST-BRICK
		   IF  2DUP TO bcol TO brow 
		       2DUP PUT-BRICK  DRAW-BRICK  TRUE
		 ELSE  2DROP FALSE  
		THEN ;

: DROP-BRICK	\ --- ; move brick down fast
		BEGIN  1 0 MOVE-BRICK 0=  UNTIL ;

: MOVE-LINE	\ from to ---
		OVER 0 PIT  OVER 0 PIT  wide 2*  CMOVE  DRAW-LINE
		DUP 0 PIT  wide 2*  BLANK  DRAW-LINE ;

: LINE-FULL	\ line-no --- flag
		TRUE  wide 0
		  DO OVER I PIT 2C@ empty D=
		     IF  DROP FALSE  LEAVE  THEN
		LOOP NIP ;

: REMOVE-LINES	\ ---
		deep deep
		BEGIN
		    SWAP
		    BEGIN  1- DUP 0< IF  2DROP EXIT  THEN  DUP LINE-FULL
		    WHILE  1 levels + TO levels  10 score + TO score  
		    REPEAT
		    SWAP 1-  2DUP <> IF  2DUP MOVE-LINE  THEN
		AGAIN ;


: INTERACTION	\ --- flag
		CASE  EKEY DUP 255 < IF >UPC THEN
		    left-key	OF  0 -1 MOVE-BRICK DROP  ENDOF
		    right-key	OF  0  1 MOVE-BRICK DROP  ENDOF
		    rot-key	OF  0  ROTATE-BRICK DROP  ENDOF
		    drop-key	OF  DROP-BRICK   ENDOF
		    pause-key	OF  S"  Paused " BOTTOM-MSG  KEY DROP
				    DRAW-BOTTOM  ENDOF
		    refresh-key	OF  REFRESH      ENDOF
		    quit-key	OF  FALSE EXIT   ENDOF
		ENDCASE  TRUE ;

: INITIALIZE	\ --- ; prepare for playing
		EMPTY-PIT REFRESH
		0 TO score  
		0 TO pieces 
		0 TO levels  
		100 TO delay ;

: ADJUST-DELAY	\ --- ; make it faster with increasing score
		levels
		DUP  50 < 
		   IF 100 OVER -  
		 ELSE DUP 100  < IF  62 OVER 4 / -  
				ELSE  DUP 500  < IF  31 OVER 16 / -  
						ELSE  0  
					       THEN 
			       THEN 
		THEN TO delay  DROP ;

: PLAY-GAME	\ --- ; play one tetris game
		BEGIN
		    NEW-BRICK
		    -1 3 INSERT-BRICK
		WHILE
		    BEGIN  4 0
			DO  35 13 AT-XY
			    delay MS KEY?
			       IF  INTERACTION 0=
			 	   IF  UNLOOP EXIT  THEN
			    THEN
			LOOP
			1 0 MOVE-BRICK  0=
		    UNTIL
		    REMOVE-LINES
		    UPDATE-SCORE
		    ADJUST-DELAY
		REPEAT ;


: TT		\ --- ; play the tetris game
		INITIALIZE
		S"  Press any key " BOTTOM-MSG EKEY DROP DRAW-BOTTOM
		BEGIN
		    PLAY-GAME
		    S"  Again? " BOTTOM-MSG EKEY >UPC [CHAR] Y =
		WHILE  INITIALIZE  
		REPEAT
		0 L/SCR 1- AT-XY CR ;

CR .( Type: TT to play tetris.) CR
