\ potential.4th
\
\ Module for reading/computing potential energy curve
\ for use by Schroedinger radial equation solver.
\
\ Copyright (c) 2012--2015, Krishna Myneni
\ Creative Consulting for Research and Education
\
\ This code may be used for any purpose, as long as the copyright
\ notice above is preserved.
\
\
\ Requires:
\
\   fsl/polrat
\   fsl/extras/read_xyfile
\   fsl/extras/find
\
\ Revisions:
\   2014-12-12  km  first working version.
\   2015-02-07  km  READ-POTNL returns number of points read from file.
\   2015-02-11  km  implemented GET-NPOTNL, }COPY-R, }COPY-V.

Module: qm.potential

Begin-Module

\ NPOTNL is the number of points in the potential energy 
\ function, V(r). 

\ Not yet implemented, but If NPOTNL < 0, and PPOTNL is set to
\ the xt of an analytic function to compute the potential, use 
\ the analytic function to compute V(r). 
variable Npotnl
-1 Npotnl !
 
Defer ppotnl

4096 constant MAX_POTNL

MAX_POTNL FLOAT ARRAY r{
MAX_POTNL FLOAT ARRAY V{

fvariable Rmin
fvariable Rmax
fvariable Vmin
fvariable Vmax
fvariable Rdel_min

Public:

\ Read the potential function data from a file, into the 1D 
\ arrays, r{, and V{, and find its characteristics.
  
: read-potnl ( caddr u -- n )
    r{ V{ 2swap read_xyfile ABORT" Unable to read input file!"
    dup Npotnl !
    dup r{ }fmin  Rmin  F!
    dup r{ }fmax  Rmax  F!
    dup V{ }fmin  Vmin  F!
    dup V{ }fmax  Vmax  F!
    \ Find minimum increment for r{ values
    >r
    r{ 1 } F@  r{ 0 } F@ F- fabs
    r> 2 DO  r{ I } F@  r{ I 1- } F@ F- fabs fmin  LOOP
    Rdel_min F!
    Npotnl @
;

: get-Npotnl ( -- n ) Npotnl @ ;  \ < 0 indicates no potential data available.
: get-Rlims ( -- Rmin Rmax )  Rmin F@  Rmax F@ ;
: get-Vlims ( -- Vmin Vmax )  Vmin F@  Vmax F@ ;

\ Copy values from arrays r{ and V{ to user arrays
: }copy-r   ( u 'rdst -- )  swap >r r{ swap r> }fcopy ;
: }copy-V   ( u 'Vdst -- )  swap >r V{ swap r> }fcopy ;

Private:

12 constant MAX_INTERP
MAX_INTERP FLOAT ARRAY rI{
MAX_INTERP FLOAT ARRAY VI{

variable interp_order
8 interp_order !      \ default polynomial order

Public:

: set-interpolation-order ( u -- )
    dup MAX_INTERP > ABORT" setup-mesh: interpolation order too large!"
    interp_order ! ;

\ Interpolate the value of V[r] for a given r, Rmin <= r <= Rmax
\ Assumes r{ and V{ arrays are in ascending order for r
: InterpolateV ( r -- V[r] )
    fdup Rmin F@ F<= IF fdrop V{ 0 } F@ EXIT THEN  \ return left end point
    fdup Rmax F@ F>= IF fdrop V{ Npotnl @ 1- } F@ EXIT THEN \ return right end point
    fdup Npotnl @ r{ }ffind >R
    fdup r{ R@ } F@ F= IF  fdrop V{ R> } F@ EXIT  THEN  \ exact match
    R> interp_order @ 2/ - 0 max
    dup interp_order @ + Npotnl @ > 
    IF drop Npotnl @ interp_order @ - THEN
    interp_order @ 0 DO  
      r{ over } F@  rI{ I } F!  
      V{ over } F@  VI{ I } F!
      1+
    LOOP drop 
    rI{  VI{ interp_order @ polint ( ratint) fdrop
;

End-Module


