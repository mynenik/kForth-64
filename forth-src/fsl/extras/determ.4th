\ determ.4th
\
\ Return the determinant of a real square matrix.
\ The input matrix is destroyed in the process.

\ Krishna Myneni, Creative Consulting for Research and Education
\ http://ccreweb.org
\
\ Revisions: 
\
\   2007-09-16 km; extract word determ from original kForth matrix
\                  package into its own module, and modify to use
\                  FSL-style matrices; also use ttester for testing 
\   2017-06-11 km; rewrote determ.4th, factoring code for
\                  clarity of algorithm and improving execution
\                  efficiency.
\
\ determ is based on a similar routine from P.R. Bevington,
\   "Data Reduction and Error Analysis for the Physical Sciences",
\   1969, McGraw-Hill.
\

Begin-Module

0 value L
0 value Norder		\ order of matrix 
0 ptr arr{{		\ address of matrix ( ptr is same as VALUE in ANS-Forth)
variable roffs

Public:

: set-determ-params ( 'a N -- )
    to Norder  to arr{{
    Norder dfloats roffs !
;

\ find column with next non-zero element, starting at
\ row = col; column = col; return the column number, col',
\ with non-zero element, which will be equal to Norder
\ if no non-zero elements found.
: df_next_nonzero ( col -- col' )
    arr{{ swap 
    dup to L
    BEGIN
      2dup L }} F@ F0= 
      L Norder 1- < and
    WHILE
      L 1+ to L
    REPEAT
    2drop L
;

\ exchange the double floats at a1 and a2
: df_xchg ( a1 a2 -- )
    dup pad dfloat move
    2dup dfloat move
    drop pad swap dfloat move    
;

\ swap columns n and m of matrix
: df_swap_cols ( n m -- )
    2>r
    arr{{ 0 r> }} arr{{ 0 r> }}
    Norder 0 DO
      2dup df_xchg
      roffs @ + swap roffs @ +
    LOOP
    2drop
;

\ subtract scaled row L from rows below to put matrix
\ in diagonal form (only does needed parts of rows).
: df_sub_rows ( l -- )
    to L
    arr{{ L L }} f@
    Norder L 1+ DO
      arr{{ I L }} f@ fover f/ 
      Norder L 1+ DO
	arr{{ L I }} f@ fover f* fnegate
	arr{{ J I }} dup >r f@ f+ r> f!
      LOOP
      fdrop
    LOOP
    fdrop
;

: determ ( 'a n -- fdet | a is the matrix, n is its order )
    set-determ-params
    1e   
    Norder 0 DO
      arr{{ I I }} F@  F0= IF  \ zero on diagonal
	\ Find next element in row which is non-zero
	I df_next_nonzero
	dup Norder = IF drop fdrop 0e LEAVE  THEN
	to L
	arr{{ I L }} F@  F0= IF  fdrop 0e LEAVE  THEN
        L I df_swap_cols
	fnegate
      THEN
	
      \ Cumulative product of diagonal elements
      arr{{ I I }} F@ F*

      \ Subtract scaled row I from lower rows
      I Norder 1- < IF  I df_sub_rows  THEN
    LOOP
;

End-Module

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  s" ttester.4th" included  [THEN]
BASE @
DECIMAL

1e-15 rel-near F!
1e-15 abs-near F!
set-near

2 2 FLOAT MATRIX m2{{
    3e  1e
    5e  2e
2 2 m2{{ }}fput

3 3 FLOAT MATRIX m3{{
    1e  2e  3e
    2e  1e  1e
    3e  1e  2e
3 3 m3{{ }}fput

4 4 FLOAT MATRIX m4{{
    2e  1e  4e  2e
    0e  2e  1e  2e
    0e  2e  1e  1e
    2e  0e  1e  0e
4 4 m4{{ }}fput

TESTING DETERM
t{ m2{{ 2 determ  ->   1e  r}t
t{ m3{{ 3 determ  ->  -4e  r}t
t{ m4{{ 4 determ  -> -10e  r}t  

BASE !
[THEN]
