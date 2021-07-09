\ lorenz.4th
\
\ Test the FSL routines in runge4.4th by integrating the
\   Lorenz equations:
\
\       dx/dt = sig * (y - x)
\       dy/dt = r * x - y - x * z
\       dz/dt = -bp * z + x * y
\
\
\ This code was originally part of the FSL file runge4.seq --
\ it has been adapted for integrated stack Forths.
\
\   K. Myneni, 19 March 2003
\
include ans-words
include fsl/fsl-util
include fsl/dynmem
include fsl/runge4

\ With the following constants, the Lorenz equations produce
\ chaos. A three-dimensional plot of x(t), y(t), z(t) will
\ show you the famous "butterfly attractor".

16.0E0  FCONSTANT sig
45.92E0 FCONSTANT r
4.0E0   FCONSTANT bp


: derivs() ( ft 'u 'dudt -- )

[ fp-stack? invert ] [IF] 2SWAP [THEN]
      FDROP     \ does not use t

       >R	\ 'u
       DUP DUP 1 } F@
[ fp-stack? invert ] [IF] ROT [THEN]
       0 } F@ F- sig F*
       R@ 0 } F!

       DUP 2DUP 2 } F@ FNEGATE r F+
[ fp-stack? invert ] [IF] ROT [THEN]
       0 } F@ F*
[ fp-stack? invert ] [IF] ROT [THEN]
       1 } F@ F-
       R@ 1 } F!

       DUP 2DUP 0 } F@ 
[ fp-stack? invert ] [IF] ROT [THEN]
       1 } F@ F* 
[ fp-stack? invert ] [IF] ROT [THEN]
       2 } F@ bp F* F-
       R> 2 } F!
       DROP
;


: do_output ( t n 'x  -- )
       CR
[ fp-stack? invert ] [IF] 2SWAP [THEN]
       F. }fprint
;


3 float array x{


FVARIABLE  _dt  
1e-4 _dt F!

: dt   _dt F@ ;
: dt!  _dt F! ;


: lorenz ( n -- )               \ n is the number of time steps to run

     0e x{ 0 } F!   1e x{ 1 } F!   0e x{ 2 } F!     
     use( derivs() 3 )runge_kutta4_init
     CR
     >R
     0e       \ initial time
     FDUP 3 x{  do_output

     R> 0 DO
        dt x{ 1 runge_kutta4_integrate()
        FDUP 3 x{  do_output               
     LOOP

     FDROP  CR
     runge_kutta4_done ;



fvariable tend

: lorenz2 ( tend -- )

     0e x{ 0 } F!   1e x{ 1 } F!   0e x{ 2 } F!     

     1e-2	\ max step size 
     1e-5 	\ eps (max fractional error)
     use( derivs() 3 x{ )rk4qc_init

     tend f!
     1e-2  0e       ( maxstep tstart )          

     BEGIN
	FDUP 3 x{ do_output
        rk4qc_step 0= >R
 	FDUP tend f@ F> R> OR
     UNTIL

     3 x{ do_output  FDROP CR

     rk4qc_done  ;


CR CR
.( Solve the Lorenz differential equations: ) CR CR

.( FIXED STEP RK4 INTEGRATOR 'runge_kutta4_integrate' ) CR 
.( Type '10000 lorenz' to integrate over 10,000 fixed time steps with dt=1e-4.)
CR CR

.( ADAPTIVE STEP INTEGRATOR 'rk4qc_step' ) CR
.( Type '1e lorenz2' to use the adaptive step size solver up to t=1.) CR CR

.( Compare the outputs of the two routines, and notice how much ) CR
.( faster it is, and how many fewer steps are required, to obtain ) CR
.( an accurate solution of the Lorenz equations by using the adaptive ) CR
.( step integrator. ) CR CR
.( The ouptut may be saved to a file by using >FILE and CONSOLE, e.g. ) CR CR
.(        >file lorenz.dat  10000 lorenz  console  ) CR CR
.( To view the attractor, you must generate enough data. ) CR
.( Try '100e lorenz2' and plot column 4 versus column 2 to see the ) CR
.( "butterfly". You can use the XYPLOT program to draw the plot.)
CR CR

