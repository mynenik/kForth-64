\ 2D_integral_01.4th
\
\ Demonstrate use of re-entrant version of Gauss-Legendre
\ integration to compute a two-dimensional integral.
\
\ Compute the integral of f(x, y) = x^2 + y^2, over
\ a rectangle: x: 0 -> 2, y: 0 -> 1
\
\ K. Myneni, 2022-03-25
\

include ans-words
include modules
include fsl/fsl-util
include fsl/gauleg

[undefined] fsquare [IF] : fsquare fdup f* ; [THEN]

0e fconstant xmin
2e fconstant xmax
0e fconstant ymin
1e fconstant ymax

0.1e  fconstant delx
0.1e  fconstant dely

xmax xmin f- delx f/ ftrunc>s constant nxIntervals
ymax ymin f- dely f/ ftrunc>s constant nyIntervals

3 constant nxWeights
3 constant nyWeights

nxWeights float array x{
nxWeights float array wx{
nyWeights float array y{
nyWeights float array wy{ 

nxIntervals nxWeights * constant nxTot
nyIntervals nyWeights * constant nyTot
nxTot float array xx{
nxTot float array wwx{
nyTot float array yy{
nyTot float array wwy{

: xIntervalLims ( idx -- x1 x2 ) s>f delx f* fdup delx f+ ;
: yIntervalLims ( idx -- y1 y2 ) s>f dely f* fdup dely f+ ;

: all-weights ( -- )
    nxIntervals 0 DO
      x{   wx{ nxWeights I xIntervalLims gauleg
      x{   xx{ I nxWeights * } nxWeights floats move
      wx{ wwx{ I nxWeights * } nxWeights floats move
    LOOP
    nyIntervals 0 DO
      y{   wy{ nyWeights I yIntervalLims gauleg
      y{   yy{ I nyWeights * } nyWeights floats move  
      wy{ wwy{ I nyWeights * } nyWeights floats move 
    LOOP ;

\ Compute all abscissas and weights over all intervals
all-weights
      
fvariable xx
: dy_Integrand ( F: y -- x^2+y^2 ) fsquare xx f@ fsquare f+ ;

: integral_y ( -- r )
    0.0e0
    nyIntervals 0 DO
      yy{  I nyWeights * } y{  nyWeights floats move
      wwy{ I nyWeights * } wy{ nyWeights floats move
      use( dy_Integrand y{ wy{ nyWeights )gl-integrate
      f+
    LOOP ;

: dx_Integrand ( F: x -- r )
    xx f! integral_y ;

: integral_xy ( -- r )
    0.0e0
    nxIntervals 0 DO
      xx{  I nxWeights * } x{  nxWeights floats move
      wwx{ I nxWeights * } wx{ nxWeights floats move
      use( dx_Integrand x{ wx{ nxWeights )gl-integrate
      f+
    LOOP ;


cr cr
.( Type 'integral_xy fs.' to compute the 2D integral of )cr
.( the function, f[x, y] = x^2 + y^2, over the rectangular ) cr
.( region: x: 0 -> 2, y: 0 -> 1 ) cr cr

 
