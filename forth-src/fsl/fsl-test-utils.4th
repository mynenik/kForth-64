\ fsl-test-utils
\
\  Utilities for generating element by element, Hayes-style tests on
\  arrays and matrices:
\
\ Requires: strings.4th
\
\ Use:
\          n  CompareArrays    a{  b{
\       n  m  CompareMatrices  a{{  b{{
\
\  K. Myneni
\  Revisions: 2007-08-25, 2007-09-22, 2007-10-23

BASE @ DECIMAL

create s1 64 allot
create s2 64 allot

\ Generate element by element tests for two fp arrays.
: CompareArrays ( n <a1> <a2> -- )
    bl word s1 strcpy  bl word s2 strcpy
    0 DO
	I 0 <# #S #> s"  } F@ " strcat
	s" t{ " s1 count strcat s"  " strcat 2over strcat
	s"  -> " strcat s2 count strcat s"  " strcat
	2swap strcat s"  r}t" strcat
	evaluate
    LOOP
;


0 value Nrows
0 value Ncols
\ Generate element by element tests for two fp matrices.
: CompareMatrices ( n m <m1> <m2> -- )
    to Ncols to Nrows
    bl word s1 strcpy  bl word s2 strcpy
    Nrows 0 DO
	Ncols 0 DO
	    J 0 <# #S #> s"  " strcat I 0 <# #S #> strcat  s"  " strcat  s" }} F@ " strcat
	    s" t{ " s1 count strcat s"  " strcat 2over strcat 
	    s"  -> " strcat s2 count strcat s"  " strcat
	    2swap strcat s"  r}t" strcat
	    ( type ) evaluate
	LOOP
    LOOP
;

BASE !
