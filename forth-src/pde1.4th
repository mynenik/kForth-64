\ pde1.4th
\
\ Numerical Solution of Electrostatics Boundary-Value Problems.
\ Solve Laplace's Equation in 2 Dimensions:
\
\	D_xx u(x,y) + D_yy u(x,y) = 0
\
\ Copyright (c) 2003--2013 Krishna Myneni, Creative Consulting
\ for Research and Education, http://www.ccreweb.org
\
\ Provided under the terms of the GNU General Public License.
\
\ This program demonstrates a method of solving one kind of a partial 
\ differential equation (PDE) for a function u(x,y), a function
\ of the two variables x and y. In Laplace's Equation above, 
\ D_xx represents taking the second partial derivative with respect to 
\ x of u(x,y), and D_yy the second partial derivative w.r.t. y. This 
\ equation holds for the electrostatic potential u(x,y) inside
\ a charge-free two dimensional region. If we know the values of
\ u(x,y) along a boundary enclosing the region, Laplace's equation
\ may be solved to obtain the values of u(x,y) at all interior points
\ of the region. 
\
\ In this demonstration, we can setup two different bounding regions:
\
\ 1) a hollow rectangular box with voltages defined on the edges,
\
\ 2) a hollow circular region with the top half boundary at one voltage,
\      and the bottom half boundary at a second voltage.
\
\ Very thin insulators are assumed to be separating the regions which 
\ are at different potentials on the bounding region.
\ 
\ Laplace's equation is solved by an iterative application of the 
\ "mean value theorem for the electrostatic potential" (see 
\ "Classical Electrodynamics", 2nd ed, by J.D. Jackson) to each grid 
\ point inside the boundary until the solution converges. For more 
\ information on solving PDEs and boundary value problems, 
\ see "Partial differential equations for engineers and scientists", 
\ by Stanley J. Farlow, 1982, Dover. The method of solving Laplace's 
\ equation used in this example is known as Liebmann's method.
\
\ If your system has installed the "R" package for statistical computing 
\ (see www.r-project.org) and ghostview, you can generate and
\ view a contour plot of the equipotential lines for the solution.
\
\ K. Myneni, 1998-10-23
\
\ Revisions:
\   2013-03-11  km; revised code to remove dependency on obsolete
\                   matrix package (matrix.4th). Simple fp matrices
\                   defined in this program give better performance.
\                   Also fixed bug in R output code, and revised
\                   R-OUTPUT and PLOT to work on modern Linux
\                   systems.
\   2020-03-14  km; added code to validate the pde solution by
\                   computing the Laplacian in the grid.
\   2023-12-19  km; use *+ for speeding up addressing; other minor changes.

include ans-words

[undefined] 2- [if] : 2- 1- 1- ; [then]
[undefined] fround>s [if] : fround>s fround f>d d>s ; [then]
[undefined] f2drop [if] : f2drop fdrop fdrop ; [then]

\ Create a floating pt matrix to hold the grid values

64 constant GRIDSIZE
create grid[[ GRIDSIZE dup * FLOATS allot
\ copy of last grid values for convergence test
create last_grid[[ GRIDSIZE dup * FLOATS allot	

[DEFINED] *+ [IF]
: ]]F@ ( a row col -- ) ( F: -- r) GRIDSIZE swap *+ floats + f@ ;
: ]]F! ( a row col -- ) ( F: r --) GRIDSIZE swap *+ floats + f! ;
[ELSE]
: ]]F@ ( a row col -- ) ( F: -- r) >r GRIDSIZE * r> + floats + f@ ;
: ]]F! ( a row col -- ) ( F: r --) >r GRIDSIZE * r> + floats + f! ;
[THEN]

: zero-matrix ( a -- ) GRIDSIZE dup * floats erase ;
: copy-matrix ( a1 a2 n m -- ) * floats move ;
 
\ Rectangular Region Boundary Values

100e  FCONSTANT  TOP_EDGE	\ Top edge at   100.0 V
0e    FCONSTANT  RIGHT_EDGE	\ Right edge at   0.0 V
0e    FCONSTANT  BOTTOM_EDGE	\ Bottom edge at  0.0 V
50e   FCONSTANT  LEFT_EDGE	\ Left edge at   50.0 V

: inside_rectangle? ( row col -- flag | inside rectangular boundary?)
    dup 0> swap GRIDSIZE 1- < AND swap
    dup 0> swap GRIDSIZE 1- < AND AND
;

: set_rectangular_bvs ( -- | setup the rectangular boundary values)
    GRIDSIZE 0 DO  TOP_EDGE    grid[[ 0 I ]]F!  LOOP
    GRIDSIZE 0 DO  RIGHT_EDGE  grid[[ I GRIDSIZE 1- ]]F! LOOP
    GRIDSIZE 0 DO  BOTTOM_EDGE grid[[ GRIDSIZE 1- I ]]F! LOOP
    GRIDSIZE 0 DO  LEFT_EDGE   grid[[ I 0 ]]F!  LOOP
;

: init_rectangular_grid ( -- | set up the starting grid values )
    set_rectangular_bvs
    TOP_EDGE BOTTOM_EDGE RIGHT_EDGE LEFT_EDGE f+ f+ f+ 4e f/
    GRIDSIZE 0 DO
      GRIDSIZE 0 DO
        J I inside_rectangle? IF fdup grid[[ J I ]]F! THEN
      loop
    loop fdrop ;

\ Circular Region Boundary Values

100e  FCONSTANT  TOP_HALF	\ Top half of boundary region at 100. V
0e    FCONSTANT  BOTTOM_HALF    \ Bottom half at 0.0 V
GRIDSIZE 2- 2/ CONSTANT RADIUS  \ Radius of boundary region

: inside_circle? ( row col -- flag | inside circular boundary? )
     1+ GRIDSIZE 2/ - dup * swap 
     1+ GRIDSIZE 2/ - dup * + s>f fsqrt fround>s
     RADIUS < ;
 
: set_circular_bvs ( -- | setup the circular boundary region )
    GRIDSIZE 0 DO
      GRIDSIZE 0 DO
        J I inside_circle? 0= IF
	  J 1+ GRIDSIZE 2/ < IF TOP_HALF ELSE BOTTOM_HALF THEN
	  grid[[ J I ]]F!
	THEN 
      LOOP
    LOOP ;

: init_circular_grid ( -- | set starting values of the grid)
    set_circular_bvs
    TOP_HALF BOTTOM_HALF f+ 2e f/
    GRIDSIZE 0 DO
      GRIDSIZE 0 DO
        J I inside_circle? IF fdup grid[[ J I ]]F! THEN
      LOOP
    LOOP fdrop ;
	    
defer inside?

: circ ( -- | use the two semi-circle boundary values )
    grid[[ zero-matrix
    ['] inside_circle? is inside? 
    init_circular_grid ;

: rect ( -- | use rectangular boundary values )
    grid[[ zero-matrix
    ['] inside_rectangle? is inside?
    init_rectangular_grid ;

\ Fetch the nearest neighbor grid values )
: nearest@ ( i j -- ) ( F: -- r1 r2 r3 r4 )
    2>R
    grid[[ 2R@ 1- 0 MAX ]]F@            \ left nn
    grid[[ 2R@ 1+ GRIDSIZE 1- MIN ]]F@  \ right nn
    grid[[ 2R@ SWAP 1- 0 MAX SWAP ]]F@  \ up nn
    grid[[ 2R> SWAP 1+ GRIDSIZE 1- MIN SWAP ]]F@ \ down nn
;	    	  

\ Apply the mean value theorem once to each of the interior grid values:
\   Replace each grid value with the average of the four nearest
\   neighbor values.

: iterate ( -- ) 
	GRIDSIZE 0 ?DO
	  GRIDSIZE 0 ?DO
	    J I inside? IF
	      J I nearest@	\ fetch four nearest neighbors
	      f+ f+ f+ 4e f/	\ take average of the four values
	      grid[[ J I ]]F!	\ store at this position
	    THEN
	  LOOP
	LOOP
;



fvariable tol	\ tolerance for solution
1e-16 tol f!

: converged? ( -- flag | test for convergence between current and last grid)
    GRIDSIZE 0 DO
      GRIDSIZE 0 DO
        J I inside? IF grid[[ J I ]]F@  last_grid[[ J I ]]F@ f-
	               fabs tol f@ f> IF FALSE UNLOOP UNLOOP EXIT THEN
		    THEN
      LOOP
    LOOP TRUE ;


\ Iterate until the solution converges to the specified tolerance 
\ at all interior points.

: solve ( -- )
	BEGIN
          grid[[ last_grid[[ GRIDSIZE GRIDSIZE copy-matrix
	  iterate
	  converged?
	UNTIL
;


fvariable temp
: grid_minmax ( F: -- rmin rmax | find min and max of grid values )
	grid[[ 0 0 ]]F@ fdup
	GRIDSIZE 0 DO
	  GRIDSIZE 0 DO
	    grid[[ J I ]]F@ fswap fover fmax temp f! fmin temp f@
	  LOOP
	LOOP
;

: display_grid ( -- | display the grid values as a character map )
	grid_minmax
	fover f- 
	15e fswap f/	\ scale factor to scale grid value from 0 to 15
	fswap
	cr
	GRIDSIZE 0 ?DO
	  GRIDSIZE 0 ?DO
	    f2dup
	    grid[[ J I ]]F@ fswap f- f*
	    fround>s dup 9 >
	    if 55 + else 48 + then emit
	  LOOP
	  cr
	LOOP

	f2drop
;

\ Compute and return the two terms in the Laplacian 
\ at row, col, returning 2nd partial derivative w.r.t. x,
\ and 2nd partial w.r.t. y. Uses 2nd order central 
\ derivative approximation:
\ https://en.wikipedia.org/wiki/Finite_difference
: Del^2 ( row col -- p2col p2row ) 
    2>r
    \ 2nd partial along columns
    grid[[ 2r@ 1+ ]]f@ grid[[ 2r@ ]]f@ 2e f* f-
    grid[[ 2r@ 1- ]]f@ f+  
    2r> swap 2>r
    \ 2nd partial along rows
    grid[[ 2r@ 1+ swap ]]f@ grid[[ 2r@ swap ]]f@ 2e f* f-
    grid[[ 2r@ 1- swap ]]f@ f+ 
    2r> 2drop ;

48 constant INNER_GRIDSIZE
GRIDSIZE INNER_GRIDSIZE - 2/ 1- constant RC_OFFSET
fvariable max_partial2_x
fvariable max_partial2_y
\ Check validity of solution by computing max abs value of the Laplacian 
: validate ( -- r )
    0e fdup max_partial2_x f! max_partial2_y f!

    0e
    INNER_GRIDSIZE 0 DO
      INNER_GRIDSIZE 0 DO
        J RC_OFFSET + I RC_OFFSET + Del^2 
        f2dup
        fabs max_partial2_y f@ fmax max_partial2_y f!
        fabs max_partial2_x f@ fmax max_partial2_x f!
        f+
        fabs fmax
      LOOP
    LOOP ;

\ Optional script code for generating a contour plot with "R"  
\ (see www.r-project.org). Also requires a postscript file
\ viewer (evince).
\
\ To use, redirect the R output to a file, e.g.
\
\	>file pde1-out.R R-output console
\
\ Then, from the shell, use R to generate the encapsulated
\ postscript (eps) output:
\
\	$ R --vanilla < pde1-out.R 
\
\ Finally, to view, use evince (or ghostview) to look at the
\ R-generated eps file:
\
\	$ evince pde1-out.eps
\
\ Under Linux, this procedure is automated with the word "PLOT"
\ 
variable nout

: R-output ( -- | generate graphics output; redirect to a file and use R)
     ." x <- seq(1:" GRIDSIZE . [char] ) emit CR
     ." y <- seq(1:" GRIDSIZE . [char] ) emit CR
     ." z <- matrix(data = " CR
     ." c( "
     0 nout !
     0 GRIDSIZE 1- DO		\ reverse order for row output
       GRIDSIZE 0 DO
         grid[[ J I ]]F@ f. 
	 I GRIDSIZE 1- < J or IF [char] , emit THEN
	 1 nout +!
	 nout @ 8 mod 0= IF CR THEN
       LOOP
     -1 +LOOP
     [char] ) emit [char] , emit CR
     ." nrow = " GRIDSIZE . [char] , emit
     ." ncol = " GRIDSIZE . [char] ) emit CR
     ." postscript(" [char] " emit ." pde1-out.eps" [char] " emit 
     [char] , emit ."  horizontal=FALSE" [char] , emit
     ."  height = 6" [char] , emit ."  width = 6" [char] ) emit CR
     ." contour(x,y,z)" CR
     ." dev.off()" CR
;

: plot ( -- | generate and show a contour plot of the grid values )
     ." Generating contour plot ... please wait" CR
     S" >file pde1-out.R R-output console" evaluate
     c" R --vanilla < pde1-out.R > /dev/null" system drop
     c" evince pde1-out.eps &" system drop ;
  

rect
CR CR
.( Numerical Solution of Electrostatics Boundary-Value Problems ) CR 
GRIDSIZE dup 3 .r char x emit .    
.( grid has been setup. Type: ) CR CR
.(    rect           to use the rectangular boundary values) CR
.(    circ           to use the circular boundary values) CR
.(    solve          to find the solution) CR
.(    display_grid   to view grid as a character map) CR
.(    plot           to view contour plot [Linux only]) CR
CR
    
