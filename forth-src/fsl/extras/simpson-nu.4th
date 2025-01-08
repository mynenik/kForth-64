\ simpson-nu.4th
\
\ Simpson's Rule Integration for Non-Uniform Abscissas
\
\ Requires:
\   ans-words
\   modules

BEGIN-MODULE

BASE @
DECIMAL

[undefined] ]F@ [IF]
: ]F@ ( a idx -- ) ( F: -- r )
   postpone floats postpone + postpone f@ ; immediate
: ]F! ( a idx -- ) ( F: r -- )
   postpone floats postpone + postpone f! ; immediate
[THEN]

0 ptr x[
0 ptr f[
0 ptr h[

variable npts 
variable nint  \ number of intervals will be npts-1 

: alloc-mem ( -- )
    nint @ floats allocate IF -59 throw THEN to h[
;

: free-mem ( -- ) h[ dup IF free THEN drop ;

fvariable h0
fvariable h1
fvariable hph
fvariable hph2
fvariable hdh
fvariable hmh

Public:

\ ax0 and af0 are pointers to start elements in x and f arrays
: simp-nu-integrate ( F: -- integral ) ( ax0 af0 npts -- )
   dup npts ! 1- nint ! to f[ to x[
   alloc-mem

   nint @ 0 DO  x[ I 1+ ]f@ x[ I ]f@ f- h[ I ]f!  LOOP

   0.0e0  \ F: sum
   nint @ 1 DO
     h[ I ]f@  h[ I 1- ]f@   \ F: sum h1 h0
     f2dup f+ fdup hph f! fsquare hph2 f!
     f2dup f/ hdh f!
           f* hmh f!   \ F: sum
     f[ I 1- ]f@  2.0e0 hdh f@ f- f*
     f[ I ]f@  hph2 f@ hmh f@ f/ f* f+
     f[ I 1+ ]f@  2.0e0 1.0e0 hdh f@ f/ f- f* f+
     hph f@ f* 6.0e0 f/ f+
   2 +LOOP

   nint @ 2 mod IF
     h[ nint @ 2- ]f@  h0 f!   h[ nint @ 1- ]f@  h1 f!

     h1 f@ fsquare 2.0e0 f*  h0 f@ h1 f@ f* 3.0e0 f* f+
     h0 f@ h1 f@ f+ 6.0e0 f* f/
     f[ nint @ ]f@ f* f+

     h1 f@ fsquare h1 f@ h0 f@ f* 3.0e0 f* f+
     h0 f@ 6.0e0 f* f/
     f[ nint @ 1- ]f@ f* f+

     h1 f@ fdup fsquare f*
     h0 f@ fdup h1 f@ f+ f* 6.0e0 f* f/
     f[ nint @ 2- ]f@ f* fnegate f+
   THEN

    free-mem
;

BASE !
END-MODULE

