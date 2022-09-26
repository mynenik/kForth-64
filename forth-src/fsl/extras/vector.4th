\ vector.4th
\
\ Utility words for working with floating point vectors
\ in the Forth Scientific Library (FSL).
\
\ A "vector" is synonymous with an FSL "FLOAT ARRAY".
\
\ Copyright (c) 2017--2019 Krishna Myneni <krishna.myneni@ccreweb.org>
\ This work may be used for any purpose provided the original
\ copyright notice is carried into the derived work.
\
\  Requires:
\    fsl/fsl-util.4th
\    modules.fs
\
\  Glossary:
\
\    VECTOR   ( N <name> -- )     Defining word for a vector of N floats
\    VCOPY    ( N 'v1 'v2 -- )    Copy vector v1 to v2
\    VMAG     ( N 'v -- r )       Return the magnitude (length) of vector
\    VSCALE   ( r N 'v -- )       Scale a vector by a number
\    VNORM    ( N 'v -- )         Normalize vector (make length = 1.e0)
\    VMAXABS  ( N 'v -- r )       Return element with largest abs value
\    VDOT     ( N 'v1 'v2 -- r )  Return dot product of two vectors
\    VPROJECT ( N 'v1 'v2 'v3 -- ) Project v1 along v2; projection in v3
\    V+       ( N 'v1 'v2 'v3 -- ) Add two vectors: v3 = v1 + v2
\    V-       ( N 'v1 'v2 'v3 -- ) Subtract two vectors: v3 = v1 - v2
\    VGET-COL ( c1 'M N 'v -- )   Get column c1 from matrix M into vector v
\    VPUT-COL ( N 'v c1 'M -- )   Put vector v into column c1 of matrix M
\

CR .( VECTOR            V1.0           13 Jan  2019 )

Begin-Module

BASE @
DECIMAL

Public:

\ Defining word for a vector
: vector ( N <name> -- ) FLOAT ARRAY ;

\ Copy vector v1 to v2
: vcopy ( N 'v1 'v2 -- ) 
    0 } swap 0 } swap rot floats move ;

\ Return magnitude of vector
0 ptr vec{
: vmag ( N 'v -- r )
    to vec{ >r
    0e  
    r> 0 ?DO  vec{ I } f@ fdup f* f+  LOOP 
    fsqrt ;

\ Scale the components of a vector by r
0 ptr vec{
: vscale ( r N 'v -- )
    to vec{ 
    0 ?DO
      vec{ I } dup >r f@ fover f* r> f!  
    LOOP
    fdrop ;

\ Normalize a vector
: vnorm ( N 'v -- )
    2dup 2>r vmag 1e fswap f/ 2r> vscale ;

\ Return element with max absolute value for a vector
0 ptr vec{
: vmaxabs ( N 'v -- r )
    to vec{ >r
    0e 
    r> 0 ?DO  vec{ I } f@ fabs fmax  LOOP  ;

\ Return dot product of two vectors
0 ptr  v1{
0 ptr  v2{
: vdot ( N 'v1 'v2 -- r )
    to v2{  to v1{  >r
    0e
    r> 0 ?DO  
      v1{ I } f@  v2{ I } f@ f* f+ 
    LOOP
;

\ Project vector v1 along v2, store resulting vector in v3
0 ptr v1{
0 ptr v2{
0 ptr v3{
: vproject ( N 'v1 'v2 'v3 -- )
    to v3{  to v2{  to v1{  >r
    r@ v2{ v3{ vcopy
    r@ v3{     vnorm
    r@ v1{ v2{ vdot
    r> v3{     vscale
;

\ Add two vectors: v3 = v1 + v2
0 ptr v1{
0 ptr v2{
0 ptr v3{
: v+ ( N 'v1 'v2 'v3 -- )
    to v3{  to v2{  to v1{
    0 ?DO  v1{ I } f@ v2{ I } f@ f+  v3{ I } f! LOOP ;

\  Subtract two vectors: v3 = v1 - v2
0 ptr v1{
0 ptr v2{
0 ptr v3{
: v- ( N 'v1 'v2 'v3 -- )
    to v3{  to v2{  to v1{
    0 ?DO  v1{ I } f@ v2{ I } f@ f- v3{ I } f! LOOP ;

\ Get column c1 from matrix M into vector v
0 ptr vec{
0 ptr mat{{
variable c1
: vget-col ( c1 'M N 'v -- )
    to vec{  >r  to mat{{  c1 !
    r> 0 ?DO  mat{{ I c1 @ }} f@ vec{ I } f!  LOOP ;

\ Put vector v into column c1 of matrix M
0 ptr vec{
0 ptr mat{{
variable c1
: vput-col ( N 'v c1 'M -- )
   to mat{{  c1 !  to vec{
   0 ?DO  vec{ I } f@  mat{{ I c1 @ }} f!  LOOP ;

BASE !

End-Module

TEST-CODE? [IF]
[undefined] T{ [IF] s" ttester.4th" included  [THEN]

base @
decimal

\ Need test code for the vector words here

base !
[THEN]

