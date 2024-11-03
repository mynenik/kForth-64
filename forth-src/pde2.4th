\ pde2.4th
\
\ Numerically solve the 1-D diffusion equation using the method
\ of finite differences:
\
\    u_t = D*u_xx
\
\ K. Myneni, 2013-02-26
\
\ Revisions:
\   2013-03-09  km  removes unneeded initialization of u_jp in EVOLVE
\
\ Notes:
\
\  The function at t=0 is given by,
\
\     u(x,0) = 1
\
\  The boundary conditions are:
\
\     u(10, t) = 20  for t > 0
\     u_x(0, t) = 0
\
\ References:
\
\ 1. S.J. Farlow, Partial Differential Equations for Scientists
\    and Engineers, Dover Publications (1982); see Lesson 38.

fvariable D        0.5e D f!      \ Diffusion coefficient
fvariable u_ext    20e  u_ext f!

0.01e fconstant dx
4e-5  fconstant dt

variable nx
10e dx f/ f>d d>s 1+ nx !

create x[      nx @ FLOATS allot
create u_x_0[  nx @ FLOATS allot
create u_j[    nx @ FLOATS allot
create u_jp1[  nx @ FLOATS allot

\ syntactic sugar for simple fp arrays
: ]F@ ( a u -- ) ( F: -- r) \ ( a n -- r)
    FLOATS + f@ ;
: ]F! ( a u -- ) ( F: r -- ) \ ( r a n -- )
    FLOATS + f! ; 

: init ( -- )
    0e nx @ 0 DO fdup x[ I ]F! dx f+  LOOP  fdrop
    nx @ 0 DO  1e u_x_0[ I ]F!  LOOP
    u_x_0[ u_j[ nx @ FLOATS move
;
init

fvariable fk
D f@ dt f* dx fdup f* f/  fk f! \ choose dt so that fk < 0.5

\ Evolve the solution by n time steps, i.e. by an elapsed time
\   of n*dt

: evolve ( n -- )
    0 ?DO  
      nx @ 1- 1 DO
        u_j[ I 1+ ]F@     u_j[ I ]F@ 2e f* f-  u_j[ I 1- ]F@ f+  fk f@ f*
        u_j[ I    ]F@ f+  u_jp1[ I ]F!
      LOOP
      u_jp1[ 1 ]F@ u_jp1[ F!             \ b.c.: u_x(0, t) = 0
      u_ext f@     u_jp1[ nx @ 1- ]F!   \ b.c.: u(10, t) = u_ext

      u_jp1[ u_j[ nx @ FLOATS move
    LOOP
;


\ Compute the solution at t=1
ms@ 
25000 evolve
ms@ swap - .

