\ chessboard.4th
\
\ Text mode graphics for TSCP chess program
\ 
\ Copyright (c) 2003 Krishna Myneni, Creative Consulting for
\   Research and Education
\
\ Provided under the GNU General Public License
\
\ Requires:
\
include strings
include ans-words
include utils
include ansi
include mini-oof
include textbox

textbox new cb1 drop
9 constant CBWIDTH
5 constant CBHEIGHT
3 constant CP_SIZE
( BLACK) GREEN  constant DARKCELL
 YELLOW ( WHITE) constant LIGHTCELL
( RED) MAGENTA  constant WHITEPIECECOLOR
BLACK  constant BLACKPIECECOLOR

cell constant pointer

: grid>xy ( gx gy -- col row | transform grid position to cursor position )
     swap CBWIDTH * 5 + swap CBHEIGHT * 1+ ;

: grid>alignedxy ( gx gy -- col row | grid pos to piece aligned pos )
     grid>xy CBHEIGHT CP_SIZE - 2/ + swap CBWIDTH CP_SIZE - 2/ + swap ;

: grid>darkcell? ( gx gy -- flag | true if grid pos is a dark cell)
     + 2 mod 0<> ;

: grid>cellcolors ( gx gy -- fg bg | foreground and background colors )
     DARKCELL LIGHTCELL 2swap grid>darkcell? if swap then ;

: chessboard ( -- | draw a chessboard )
    page
    1 1 CBWIDTH CBHEIGHT LIGHTCELL DARKCELL DARKCELL cb1 tb-init
    8 0 do
      8 0 do
        i j grid>darkcell? if
	  i j grid>xy cb1 tb-row ! cb1 tb-col !
	  cb1 tb-draw
	then
      loop
    loop
    1 1 CBWIDTH CBHEIGHT DARKCELL LIGHTCELL LIGHTCELL cb1 tb-init
    8 0 do
      8 0 do
        i j grid>darkcell? invert if
	  i j grid>xy cb1 tb-row ! cb1 tb-col !
	  cb1 tb-draw
	then
      loop
    loop
    cr text_normal ;


object class
       pointer var cp-picture
       cell var cp-col
       cell var cp-row
       cell var cp-fg
       cell var cp-bg
       method	cp-getpos
       method   cp-draw
       method   cp-init
end-class chess-piece

:noname ( o -- col row )  dup cp-col @ swap cp-row @ ;
chess-piece defines cp-getpos

:noname ( o -- )
    dup cp-getpos grid>cellcolors background drop
    dup cp-fg @ foreground
    CP_SIZE 0 do
      dup cp-getpos grid>alignedxy i + at-xy
      dup cp-picture a@ CP_SIZE i * + CP_SIZE type
    loop
    drop ;
chess-piece defines cp-draw

:noname ( col row o -- )  dup >r cp-row ! r> cp-col ! ;
chess-piece defines cp-init

: make-shape ( a1 u1 a2 u2 ... an un "name" -- )
    CREATE CP_SIZE dup * ?allot 
    CP_SIZE 0 do
      swap drop
      2dup CP_SIZE dup 1- i - * + CP_SIZE cmove
      nip
    loop drop ;

s"  0 "
s"  | "
s" /_\"
make-shape pawn-shape

s" -^-"
s" \ /"
s" [_]" 
make-shape queen-shape

s" _|_"
S"  | "
s" [_]"
make-shape king-shape

s" /@}"
s" \ }"
s" [_]"
make-shape knight-shape

s"  o "
s" ( )"
s" /_\"
make-shape bishop-shape

s" VVV"
s" \ /"
s" [_]"
make-shape rook-shape

chess-piece class
end-class pawn

:noname ( col row o -- ) >r pawn-shape r@ cp-picture ! r> 
	 [ chess-piece :: cp-init ] literal execute ;
pawn defines cp-init   

chess-piece class
end-class king

:noname ( col row o -- ) >r king-shape r@ cp-picture ! r>
	 [ chess-piece :: cp-init ] literal execute ;
king defines cp-init   

chess-piece class
end-class queen

:noname ( col row o -- ) >r queen-shape r@ cp-picture ! r>
	 [ chess-piece :: cp-init ] literal execute ;
queen defines cp-init   

chess-piece class
end-class bishop

:noname ( col row o -- ) >r bishop-shape r@ cp-picture ! r>
	 [ chess-piece :: cp-init ] literal execute ;
bishop defines cp-init   

chess-piece class
end-class knight

:noname ( col row o -- ) >r knight-shape r@ cp-picture ! r>
	 [ chess-piece :: cp-init ] literal execute ;
knight defines cp-init   

chess-piece class
end-class rook

:noname ( col row o -- ) >r rook-shape r@ cp-picture ! r>
	 [ chess-piece :: cp-init ] literal execute ;
rook defines cp-init   


\ Now we make and initialize the pieces

rook   new  b-q-rook
knight new  b-q-knight
bishop new  b-q-bishop
queen  new  b-queen
king   new  b-king
bishop new  b-k-bishop
knight new  b-k-knight
rook   new  b-k-rook
pawn   new  b-q-r-pawn
pawn   new  b-q-k-pawn
pawn   new  b-q-b-pawn
pawn   new  b-q-pawn
pawn   new  b-k-pawn
pawn   new  b-k-b-pawn
pawn   new  b-k-k-pawn
pawn   new  b-k-r-pawn

16 table black-pieces


rook   new  w-q-rook
knight new  w-q-knight
bishop new  w-q-bishop
queen  new  w-queen
king   new  w-king
bishop new  w-k-bishop
knight new  w-k-knight
rook   new  w-k-rook
pawn   new  w-q-r-pawn
pawn   new  w-q-k-pawn
pawn   new  w-q-b-pawn
pawn   new  w-q-pawn
pawn   new  w-k-pawn
pawn   new  w-k-b-pawn
pawn   new  w-k-k-pawn
pawn   new  w-k-r-pawn

16 table white-pieces

: init-pieces 

    \ initialize the black pieces
    8 0 do i 7 black-pieces i cells + a@ cp-init loop 
    8 0 do i 6 black-pieces i 8 + cells + a@ cp-init loop
    16 0 do 
      \ BLACKPIECECOLOR black-pieces i cells + a@ cp-bg !
      BLACKPIECECOLOR black-pieces i cells + a@ cp-fg ! 
    loop

    \ initialize the white pieces
    8 0 do i 0 white-pieces i cells + a@ cp-init loop 
    8 0 do i 1 white-pieces i 8 + cells + a@ cp-init loop 
    16 0 do 
      \ WHITEPIECECOLOR white-pieces i cells + a@ cp-bg !
      WHITEPIECECOLOR white-pieces i cells + a@ cp-fg !
    loop
;

init-pieces

: draw-pieces
    16 0 do black-pieces i cells + a@ cp-draw loop
    16 0 do white-pieces i cells + a@ cp-draw loop 
    text_normal ; 


\
\ Pieces
\
\ Queen:
\
\	-^-
\	\ /
\	[_]
\
\ King:
\
\	_|_
\	 |
\	[_]
\
\ Knight:
\
\	/@}
\	\ }
\	[_]
\
\ Rook:
\
\	VVV
\	\ /
\	[_]
\
\ Bishop:
\
\	 o
\	( )
\	/_\
\
\ Pawn:
\
\	 0
\	 |
\	/_\
