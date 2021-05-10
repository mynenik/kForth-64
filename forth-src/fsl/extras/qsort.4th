\ qsort.4th
\
\ The quicksort algorithm, in Forth, from:
\
\   http://en.literateprograms.org/Quicksort_%28Forth%29
\
\ Original code from Wil Baden, circa 1983.
\ 
\ This version sorts cell sized values, via a user-specifiable
\ comparison word, "lessthan".
\
\
\ Revisions:
\   2010-07-21  km  test code using FSL style arrays and 
\                   ttester; demonstrate both ascending and
\                   descending sort.

-1 cells constant -cell
[UNDEFINED] cell- [IF] : cell-   -cell + ;  [THEN]

defer lessthan ( a b -- flag )   ' < is lessthan

: mid ( l r -- mid ) over - 2/ -cell and + ;

: exch ( addr1 addr2 -- ) dup @ >r over @ swap ! r> swap ! ;

: part ( l r -- l r r2 l2 )
  2dup mid @ >r ( r: pivot )
  2dup begin
    swap begin dup @  r@ lessthan while cell+ repeat
    swap begin r@ over @ lessthan while cell- repeat
    2dup <= if 2dup exch >r cell+ r> cell- then
  2dup > until  r> drop ;

: qsort ( l r -- )
  part  swap rot
  \ 2over 2over - + < if 2swap then
  2dup < if recurse else 2drop then 
  2dup < if recurse else 2drop then ;

: sort ( array len -- )
  dup 2 < if 2drop exit then
  1- cells over + qsort ;


TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
BASE @ DECIMAL

: }iput ( m1 ... m_n n 'a -- | store m1 ... m_n into array of size n )
     swap dup 0 ?DO  1- 2dup 2>r } ! 2r>  LOOP  2drop ;

: }@ ( n a -- m1 ... m_n ) swap 0 ?DO  dup I } @ swap  LOOP drop ;

\ Sort an array of ten integers
10 INTEGER ARRAY test{
 4  7  1  0  3  9  6  8  2  5 
10 test{ }iput

CR
TESTING SORT
\ Ascending sort
' <  is lessthan
T{  test{ 10 sort  ->  }T
T{  10 test{ }@  ->  0 1 2 3 4 5 6 7 8 9  }T 

\ Descending sort
' >  is lessthan
T{  test{ 10 sort  ->  }T
T{  10 test{ }@  ->  9 8 7 6 5 4 3 2 1 0  }T

\ Restore default meaning of lessthan
' <  is lessthan
 
BASE !
[THEN]

