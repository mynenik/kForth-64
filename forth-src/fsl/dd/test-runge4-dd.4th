\ test-runge4-dd.4th
\

include ans-words
include strings
include modules
include ddarith
include dd_io
include fsl/fsl-util
include fsl/dynmem
cr .( Loading the Double Double precision RK4 integrator )
include fsl/dd/runge4-dd

\  Integrate the Lorenz equations,
\
\       dx/dt = sig * (y - x)
\       dy/dt = r * x - y - x * z
\       dz/dt = -bp * z + x * y
\
\  with the following parameters,
\
\       sig = 16, r = 45.92, bp = 4
\
\  and the following initial values,
\
\      x(t = 0) = 0
\      y(t = 0) = 1
\      z(t = 0) = 0

1000000 value nsteps

cr .( Integrate the Lorenz equations in double double precision )
cr .( using ) nsteps . .( steps and fixed-step RK4 integrator )
cr

\ Forth source derivatives

16.0E0  0.0E0  ddconstant  sig
4592e 0e 10e 0e -2 dd^n dd* ddconstant r
4.0E0   0.0E0  ddconstant bp

0 ptr der{
0 ptr func{

: derivs() ( t tt 'u 'dudt -- )
       to der{  to func{
       dddrop     \ does not use t

       func{ 1 } dd@ func{ 0 } dd@ dd- sig dd*
       der{ 0 }  dd!

       func{ 2 } dd@ ddnegate r dd+
       func{ 0 } dd@ dd*
       func{ 1 } dd@ dd-
       der{ 1 }  dd!

       func{ 0 } dd@ func{ 1 } dd@ dd* 
       func{ 2 } dd@ bp dd* dd-
       der{ 2 }  dd!
;


3 DDFLOAT array x{

: print-x ( -- )
    x{ 0 } dd@ ddfs. cr
    x{ 1 } dd@ ddfs. cr
    x{ 2 } dd@ ddfs. cr ;

DDVARIABLE  _dt
10e 0e -4 dd^n _dt dd!  \ 1e-4 in dd format

: dt   _dt dd@ ;
: dt!  _dt dd! ;

defer rk4_init
defer rk4_integrate
defer rk4_done

0e 0e ddconstant DD0.0
1e 0e ddconstant DD1.0

: lorenz ( nsteps xt -- )
     DD0.0 x{ 0 } dd!   DD1.0 x{ 1 } dd!   DD0.0 x{ 2 } dd!  \ initial conditions
     3 rk4_init
     >r
     DD0.0       \ t0
     r> 0 DO
        dt x{ 1 rk4_integrate
     LOOP
     DDDROP
     rk4_done ;

cr
' )runge_kutta4_init is rk4_init
' runge_kutta4_integrate() is rk4_integrate
' runge_kutta4_done is rk4_done
ms@ nsteps ' derivs() lorenz ms@ swap - . .(  ms ) cr
.( x_final = { ) cr print-x .(  } ) cr

