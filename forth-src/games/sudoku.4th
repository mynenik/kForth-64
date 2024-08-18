( 	
Newsgroup: comp.lang.forth
From: robert spykerman <robspyke_nospam@no_spam_iprimus.com.au_no_spam>
Date: Thu, 01 Sep 2005 18:53:01 +1000
Local: Thurs, Sep 1 2005 3:53 am
Subject: Re: Sudoku puzzle solver

A BETTER SOLVER ENGINE...

Improved solving engine - uses a bit of intelligence as well as
recursion, thanks to all of you, who suggested a more intelligent
approach.

The new solver finds a grid-position most likely to yield a good guess
by looking at the number sets first, instead of just blindly thumping
numbers in from start to end.

458 calls to solver versus 250,000+ initially...
Win32forth hesitated a couple of seconds on the old one.
Now it doesn't.  Wow...

Marcel, I haven't figured out your code yet, does yours do it in a
similar way?
)

\ ------------- SAMPLE RUN ( full source comes after)
(

PUZZLE
0 9 0 ! 0 0 4 ! 0 0 7
0 0 0 ! 0 0 7 ! 9 0 0
8 0 0 ! 0 0 0 ! 0 0 0
------+-------+------
4 0 5 ! 8 0 0 ! 0 0 0
3 0 0 ! 0 0 0 ! 0 0 2
0 0 0 ! 0 0 9 ! 7 0 6
------+-------+------
0 0 0 ! 0 0 0 ! 0 0 4
0 0 3 ! 5 0 0 ! 0 0 0
2 0 0 ! 6 0 0 ! 0 8 0

\ OLD solver:
solveit

Solution Found

5 9 1 ! 2 8 4 ! 3 6 7
6 4 2 ! 3 5 7 ! 9 1 8
8 3 7 ! 9 6 1 ! 4 2 5
------+-------+------
4 7 5 ! 8 2 6 ! 1 9 3
3 6 9 ! 7 1 5 ! 8 4 2
1 2 8 ! 4 3 9 ! 7 5 6
------+-------+------
7 5 6 ! 1 9 8 ! 2 3 4
9 8 3 ! 5 4 2 ! 6 7 1
2 1 4 ! 6 7 3 ! 5 8 9

Elapsed Time: 547 msec
Depth : 61
Calls : 254393
 ok

\ NEW solver:
solveit

Solution Found

5 9 1 ! 2 8 4 ! 3 6 7
6 4 2 ! 3 5 7 ! 9 1 8
8 3 7 ! 9 6 1 ! 4 2 5
------+-------+------
4 7 5 ! 8 2 6 ! 1 9 3
3 6 9 ! 7 1 5 ! 8 4 2
1 2 8 ! 4 3 9 ! 7 5 6
------+-------+------
7 5 6 ! 1 9 8 ! 2 3 4
9 8 3 ! 5 4 2 ! 6 7 1
2 1 4 ! 6 7 3 ! 5 8 9

Elapsed Time: 15 msec
Depth : 61
Calls : 458

)

\ ======== kForth interface ==========
include ans-words
include strings
\ ====================================


\ ------------- SOURCE
\  Sudoku Solver in Forth.
\  No special extensions were used.
\  Tested on in win32forth, VFX and Swift (evaluation).
\  No locals were harmed during this experiment.
\
\  Version: 1900 01092005 - Robert Spykerman
\  email: robspyke_nospam@iprimus_no_spam.com.au
\         (delete the obvious)
\


\  ---------------------
\  Variables
\  ---------------------

create sudokugrid 81 chars allot  \ PUZZLE fills this in

create sudoku_row 9 cells allot

create sudoku_col 9 cells allot

create sudoku_box 9 cells allot

\ 1024 allot      \ just to be sure there is no cache issue.


\  ---------------------
\  Logic
\  ---------------------
\  Basically :  
\     Grid is parsed. All numbers are put into sets, which are
\     implemented as bitmaps (sudoku_row, sudoku_col, sudoku_box)
\     which represent sets of numbers in each row, column, box.
\     only one specific instance of a number can exist in a
\     particular set.
\
\     SOLVER is recursively called
\     SOLVER looks for the next best guess using FINDNEXTSPACE
\     tries this trail down... if fails, backtracks... and tries
\     again.
\

\ Grid Related

: xy 9 * + ;   \  x y -- offset ;
: getrow 9 / ;
: getcol 9 mod ;
: getbox dup getrow 3 / 3 * swap getcol 3 / + ;

\ Puts and gets numbers from/to grid only
: setnumber sudokugrid + c! ;  \ n position --
: getnumber sudokugrid swap + c@ ;

: cleargrid sudokugrid 81 0 do dup i + 0 swap c! loop drop ;

\ --------------
\ Set related: sets are sudoku_row, sudoku_col, sudoku_box

\ ie x y --   ;  adds x into bitmap y
:noname ( ie x y a -- ) 
  >r 1 rot lshift swap cells 
  r> + dup @ rot or swap ! ;

dup  : addbits_row sudoku_row [ compile, ] ;
dup  : addbits_col sudoku_col [ compile, ] ;
     : addbits_box sudoku_box [ compile, ] ;

\ ie x y --  ; remove number x from bitmap y
:noname ( ie x y a -- )
  >r 1 rot lshift swap cells
  r> + dup @ rot invert and swap ! ;

dup : removebits_row sudoku_row [ compile, ] ;
dup : removebits_col sudoku_col [ compile, ] ;
    : removebits_box sudoku_box [ compile, ] ;

\ clears all bitsmaps to 0
: clearbitmaps 9 0 do i cells
                     0 over sudoku_row + !
                     0 over sudoku_col + !
                     0 swap sudoku_box + !
           loop ;

\ Adds number to grid and sets
: addnumber                   \ number position --
    2dup setnumber
    2dup getrow addbits_row
    2dup getcol addbits_col
         getbox addbits_box
;

\ Remove number from grid, and sets
: removenumber                \ position --
    dup getnumber swap    
    2dup getrow removebits_row
    2dup getcol removebits_col
    2dup getbox removebits_box
    nip 0 swap setnumber
;

\ gets bitmap at position, ie
\ position -- bitmap

: getrow_bits getrow cells sudoku_row + @ ;  
: getcol_bits getcol cells sudoku_col + @ ;  
: getbox_bits getbox cells sudoku_box + @ ;  

\ position -- composite bitmap  (or'ed)
: getbits
    dup getrow_bits
    over getcol_bits
    rot getbox_bits or or
;

\ algorithm from c.l.f circa 1995 ? Will Baden
0 [IF]
: countbits    ( number -- bits )
        [ HEX ] DUP  55555555 AND  SWAP  1 RSHIFT  55555555 AND  +
                DUP  33333333 AND  SWAP  2 RSHIFT  33333333 AND  +
                DUP  0F0F0F0F AND  SWAP  4 RSHIFT  0F0F0F0F AND  +
        [ DECIMAL ] 255 MOD
;
[ELSE]
: countbits    ( number -- bits )
        [: ( n u ushift -- ) >r swap 2dup and swap r> rshift rot and + ;]
        >r
        [ HEX ] 
        55555555 1  r@ execute
        33333333 2  r@ execute
        0F0F0F0F 4  r> execute
        [ DECIMAL ] 255 MOD
;
[THEN]

\ Try tests a number in a said position of grid
\ Returns true if it's possible, else false.
: try  \ number position -- true/false
    over 1 swap lshift
    over getbits and 0= rot rot 2drop
;

\ --------------
: parsegrid  \ Parses Grid to fill sets.. Run before solver.
   sudokugrid \ to ensure all numbers are parsed into sets/bitmaps
   81 0 do
     dup i + c@                            
       dup if                              
         dup i try if                    
           i addnumber                          
         else
           unloop drop drop FALSE exit      
         then  
       else
         drop
       then
   loop
   drop
   TRUE
;

\ Morespaces? manually checks for spaces ...
\ Obviously this can be optimised to a count var, done initially
\ Any additions/subtractions made to the grid could decrement
\ a 'spaces' variable.

: morespaces?
    0 81 0 do sudokugrid i + c@  0= if 1+ then loop ;

: findnextmove         \  -- n ; n = index next item, if -1 finished.

   -1  10                \  index  prev_possibilities  --
                         \  err... yeah... local variables, kind of...

   81 0 do
      i sudokugrid + c@ 0= IF
             i getbits countbits 9 swap -

             \ get bitmap and see how many possibilities
             \ stack diagram:
             \ index prev_possibilities  new_possiblities --

             2dup > if          
                     \ if new_possibilities < prev_possibilities...
                 nip nip i swap  
                     \ new_index new_possibilies --

             else \ else prev_possibilities < new possibilities, so:

                 drop  \ new_index new_possibilies --        

             then                
      THEN
   loop
   drop
;

\ findnextmove returns index of best next guess OR returns -1
\ if no more guesses. You then have to check to see if there are
\ spaces left on the board unoccupied. If this is the case, you
\ need to back up the recursion and try again.

: solver
     findnextmove
         dup 0< if
             morespaces? if
                drop false exit
             else
                drop true exit
             then
         then

     10 1 do
        i over try if          
           i over addnumber
           recurse  if
                drop unloop TRUE EXIT
           else
                dup removenumber
           then
        then
     loop

     drop FALSE
;

\ SOLVER

: startsolving        
   clearbitmaps  \ reparse bitmaps and reparse grid
   parsegrid     \ just in case..
   solver
   AND
;

\  ---------------------
\  Display Grid
\  ---------------------
\
\ Prints grid nicely

\ Updated to use Josh Grams' version of ".sudokugrid", below.
\ 8/11/2011

: |  ." ! " ;
: ---- ." ------+-------+------" CR ;
: ...  3 0 do dup char+ swap c@ . loop ;
: .gridline  ... | ... | ... CR ;
: .row  3 0 do .gridline loop ;
: .sudokugrid
  CR CR sudokugrid
  .row
  ----
  .row
  ----
  .row
  drop CR ; 

\  ---------------------
\  Higher Level Words
\  ---------------------

: checkifoccupied  \ offset -- t/f
    sudokugrid + c@
;

: add                 \ n x y --
    xy 2dup
      dup checkifoccupied if
        dup removenumber
      then
    try if
      addnumber
      .sudokugrid
    else
      CR ." Not a valid move. " CR
      2drop
    then
;

: rm
    xy removenumber
    .sudokugrid
;

: clearit
    cleargrid
    clearbitmaps
    .sudokugrid
;

: solveit
  CR CR
  startsolving
  if
    ." Solution Found " CR .sudokugrid
  else
    ." No Solution Found " CR CR
  then
;

: showit .sudokugrid ;

\ Print help menu
: help
  CR
  ." Type clearit     ; to clear grid " CR
  ."      1-9 x y add ; to add 1-9 to grid at x y (0 based) " CR
  ."      x y rm      ; to remove number at x y " CR
  ."      showit      ; redisplay grid " CR
  ."      solveit     ; to solve " CR
  ."      help        ; for help " CR
  ."      puzzle      ; make a new puzzle from the next" CR
  ."                  ; 81 whitespace delimited digits" CR
  CR
;


\  ----------------------
\  Full Puzzle Input (modified from DNW's version)
\  ----------------------

: is-digit-s  ( addr len -- digit flag )
(
Leave true and the value if the input string is a single decimal
digit, else leave false with digit undefined.  Based on Wil
Baden's IS-DIGIT.
)
  1 = IF c@ [char] 0 - dup 10 u< ELSE false THEN ;

: puzzle ( "digit_1<white>...digit_81<white>}" -- )
  sudokugrid
  81 0 DO
    bl word count dup 0= 
    IF 2drop refill 0= IF unloop exit ELSE bl word count THEN THEN 
    is-digit-s 0=
    ABORT" ***Illegal or missing decimal digit!"
    over c! char+
  LOOP ( &sudokugrid) drop
;


\  ---------------------
\  Execution starts here
\  ---------------------

puzzle
0 9 0    0 0 4   0 0 7
0 0 0    0 0 7   9 0 0
8 0 0    0 0 0   0 0 0
4 0 5    8 0 0   0 0 0
3 0 0    0 0 0   0 0 2
0 0 0    0 0 9   7 0 6
0 0 0    0 0 0   0 0 4
0 0 3    5 0 0   0 0 0
2 0 0    6 0 0   0 8 0

: godoit
    CR
    clearbitmaps
    parsegrid if
      CR ." Grid in source valid. "
    else
      CR ." Warning: Grid in source invalid. "
    then
    .sudokugrid
    help
;

godoit

\ ------------- END SOURCE
