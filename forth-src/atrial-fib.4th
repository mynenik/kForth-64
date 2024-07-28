\ atrial-fib.4th
\
\ A cellular-automata model of atrial fibrillation, based on
\ reference 1.
\
\ In this model, the atrial muscle wall is idealized as a
\ 2D sheet of discrete cells, with a cylindrical geometry
\ along the horizontal axis. From the left side, pacemaker
\ cells periodically self-excite. The excitation couples to
\ adjacent horizontal cells, and with a probability, nu, for
\ vertically adjacent cells. Under normal operation, the
\ excitation propagates along the tissue in planar wavefronts
\ in the idealized model and provides regular pumping; however,
\ if the probability for vertical coupling, nu, is too low, a
\ condition simulating the effect of increasing fibrosis with
\ age, the planar wavefronts give way spontaneously to 
\ rotary-like excitations, associated with atrial fibrillation
\ (AF) and stroke.
\
\ This program displays the excitation wave in an animated
\ text display on ANSI terminals. The excitation wavefront
\ is displayed. A finding of ref. [1] is that there is a
\ threshold value of nu, around 14%, for spontaneous atrial
\ fibrillation within the model. The value of nu may be
\ adjusted, and by default it is set near the threshold to
\ show the onset of AF, followed by a return to normal
\ heartbeat.
\
\ Copyright (c) 2015--2020 Krishna Myneni
\
\ This code may be used for any purpose, as long as the copyright
\ notice above is preserved.
\
\ Revisions:
\   2015-02-15  km; first working version.
\   2015-02-16  km; minor cleanup; set initial value of RNG seed.
\   2019-09-18  km; revised def. of uw@ to mask 16 bits;
\                     use USLEEP delay instead of MS .
\   2019-09-27  km; implemented moment of inertia method for detecting
\                   AF at a given instant; record moments for up to
\                   MAX_HC heart clock cycles; determine fraction of
\                   time in AF for a single trial; compute analytic
\                   risk probability of AF.
\ References:
\
\  1. K. Christensen, K.A. Manani, and N.S. Peters, "Simple Model
\     for Identifying Critical Regions in Atrial Fibrillation",
\     Physical Review Letters vol. 114, 028104 (2015).
\
include ans-words
include strings
include ansi
include modules
include fsl/fsl-util

\ === Memory utility words
hex
[UNDEFINED] uw@ [IF]
: uw@ ( a -- u ) dup 1+ >r c@ r> c@ 8 lshift or ;
[THEN]

\ === Simple random number generator
hex
ff800000 constant ROL9MASK
decimal

variable seed

: rol9 ( u1 -- u2 | rotate u1 left by 9 bits )
    dup ROL9MASK and 23 rshift swap 9 lshift or ;     

: random2 ( -- u ) seed @ 107465 * 234567 + rol9 dup seed ! ;

: random2p ( -- u )
	   random2 255 and 24 lshift
	   random2 255 and 16 lshift or
	   random2 255 and  8 lshift or
	   random2 255 and or ;

\ Generate a random number, 0 <= u2 < u1, and u2 is uniformly
\ distributed within the interval [0, u1). Restriction: u1 < 256
: get-random ( u1 -- u2 )
    BEGIN
      random2p
      16 rshift 255 and
      2dup <=
    WHILE
      drop
    REPEAT
    nip
;

: random-init ( -- )
    time&date * * 
    >r 1 max r> * 
    >r 1 max r> *
    >r 1 max r> * seed !  \ initialize the seed
    BEGIN random2p dup 1000 1000000 within invert WHILE drop REPEAT
    0 DO random2p drop LOOP
;

random-init

\ === Model parameters
0 [IF]
\ parameters T, tau, and L used in ref. [1] 
220 constant PACE       \ heartbeat period
50  constant REF_TIME   \ refractory time
200 constant L
[ELSE]
\ scaled down parameters for text-mode animation, using b=10
110  constant PACE
25   constant REF_TIME
100  constant L
[THEN]

5   constant DELTA      \ percentage of dysfunctional cells
5   constant EPSILON    \ probability of not exciting a dysfunctional cell
                        \   expressed as a percentage 
\ Adustable parameter for percent of cells with functional transverse 
\ (up/down) connections.
variable nu
14 nu !

\ == Data structure for information about the cell
\
\ Information about each cell includes its state, whether or
\ not it is a dysfunctional cell, the functionality of its 
\ transverse (up and down) connections, and time remaining in
\ its refractory state. This information is encoded in two
\ bytes within the cell info value as follows:
\
\ Total bytes: 2
\
\ Byte 1: b0--b2  cell state (resting, excited, refractory)
\         b3      1 indicates dysfunctional cell
\         b4      1 indicates up connection is bad
\         b5      1 indicates down connection is bad
\         b6--b7  unused
\
\ Byte 2: refractory state time remaining (unsigned byte)
\
[UNDEFINED] binary [IF] : binary 2 base ! ; [THEN]
 
binary
000111 constant STATE_MASK
001000 constant DYSFUNCTIONAL_MASK
010000 constant UP_CONNECTION_MASK
100000 constant DOWN_CONNECTION_MASK
110000 constant TRANSVERSE_CONNECTION_MASK
DECIMAL
        
\ Cell States
0  constant  RESTING
1  constant  EXCITED
2  constant  REFRACTORY

variable heart-clock
variable nbeats

\ The matrix of cell information. Column 1 will be
\ the special pacemaker cells, which alternate
\ with a fixed period between RESTING and EXCITED
\ states.

L dup 2 matrix CellInfo{{
L dup 2 matrix CellInfoNew{{

\ Array for storing "moments of inertia" at each heart clock cycle,
\ for determining when AF occurs.
100000 constant MAX_HC
MAX_HC INTEGER ARRAY moments{
 
\ === Basic manipulation of cell info values

: excited? ( cellinfo -- flag ) STATE_MASK and EXCITED = ;
: resting? ( cellinfo -- flag ) STATE_MASK and RESTING = ;
: refractory? ( cellinfo -- flag ) STATE_MASK and REFRACTORY = ;

: dysfunctional? ( cellinfo -- flag ) DYSFUNCTIONAL_MASK and ;
: up-bad? ( cellinfo -- flag ) UP_CONNECTION_MASK and ;
: down-bad? ( cellinfo -- flag ) DOWN_CONNECTION_MASK and ;

: get-reftime ( cellinfo -- utimeleft ) 8 rshift 255 and ;

: set-reftime ( cellinfo reftime -- newinfo )
    >r 255 and r> 8 lshift or ;

: set-cell-state ( cellinfo cellstate -- newinfo )
    >r 255 and [ STATE_MASK invert ] literal and r> or ;

: set-cell-dysfunctional ( cellinfo -- newinfo )
    DYSFUNCTIONAL_MASK or ;

: disable-up   ( cellinfo -- newinfo ) UP_CONNECTION_MASK or ;
: disable-down ( cellinfo -- newinfo ) DOWN_CONNECTION_MASK or ;
 
: excite-cell ( cellinfo -- newinfo )
    dup dysfunctional?
    IF
      100 get-random EPSILON > 
      IF EXCITED ELSE RESTING THEN
    ELSE
      EXCITED
    THEN
    set-cell-state
;

: excited->refractory ( cellinfo -- newinfo )
    REFRACTORY set-cell-state
    REF_TIME   set-reftime ;

: advance-reftime ( cellinfo -- newinfo )
    dup get-reftime
    1-            \ decrement time left in refractory state
    dup >r
    set-reftime
    r> 0= IF RESTING set-cell-state THEN
;

: ncells ( -- u ) L dup * ;  \ return total number of cells
: ndys ( -- u ) ncells DELTA * 100 / ;  \ number of dysfunctional cells

\ Return number of functional transverse connections
: ntransverse ( -- u ) ncells nu @ * 100 / ;
\ Return number of transverse connection breaks
: nbreaks ( -- u ) ncells ntransverse - ;

\ Reference words for adjacent cells

\ Use open boundary conditions horizontally.
: left ( row col -- row col-1 )  1- ;
: right ( row col -- row col+1 ) 1+ ;

\ Use periodic boundary conditions vertically.
: up   ( row col -- row-1|L-1 col )  
    >r dup 0= IF drop L THEN 1- r> ;
: down ( row col -- row+1|0 col )
    >r 1+ L mod r> ;

\ Return the cell's info at the specified row and column
: @CellInfo ( row col -- cellinfo ) 2>r CellInfo{{ 2r> }} uw@ ;
: !CellInfo ( cellinfo row col -- ) 2>r CellInfo{{ 2r> }}  w! ;

\ Make a randomly selected set of NDYS cells (DELTA percent
\ of all cells) dysfunctional.
: make-dysfunctional-cells ( -- )
    ndys 0 DO
      \ Generate a random row and column
      L 1- get-random  \ row
      L 1- get-random  \ col
      2dup @CellInfo
      set-cell-dysfunctional
      -rot !CellInfo
    LOOP
;

\ Choose at random a cell with at least one transverse connection
: choose-connected-cell ( -- row col )
      BEGIN
        L 1- get-random  \ row
        L 1- get-random  \ col
        2dup @CellInfo
        TRANSVERSE_CONNECTION_MASK and
        TRANSVERSE_CONNECTION_MASK = 
      WHILE
        2drop
      REPEAT
;

2variable pos

\ Break transverse connections between cells 
: make-transverse-breaks ( -- )
    nbreaks 0 DO
      choose-connected-cell
      2dup pos 2! @CellInfo
      dup up-bad? IF
        disable-down pos 2@ !CellInfo
        pos 2@ down 
        2dup @CellInfo disable-down 
        -rot !CellInfo
      ELSE
        disable-up pos 2@ !CellInfo
        pos 2@ up 
        2dup @CellInfo disable-down
        -rot !CellInfo
      THEN
    LOOP    
;

\ initialize all cells to the specified value
: all-cells ( cellinfo -- )
    L 0 DO
	L 0 DO
	  dup CellInfo{{ J I }} w!
        LOOP
    LOOP
    drop 
;

\ Initialize all cells in the matrix to the resting state,
\ randomly select dysfunctional cells, and setup transverse
\ (up/down) connections.
: init-cells ( -- )
    RESTING all-cells
    make-dysfunctional-cells
    make-transverse-breaks
;


: get-surrounding-info ( row col -- leftinfo rightinfo upinfo downinfo)
    2>r
    \ get info for cells to left and right
    2r@ left   @CellInfo
    2r@ right  dup L = 
               IF 2drop RESTING ELSE @CellInfo THEN

    \ check connections for cells up and down, and, if functioning,
    \   get info for these cells; otherwise, indicate they are resting.

    2r@ @CellInfo up-bad? 
        IF RESTING 
        ELSE 2r@ up @CellInfo 
        THEN

    2r@ @CellInfo down-bad? 
        IF RESTING 
        ELSE 2r@ down @CellInfo 
        THEN

    2r> 2drop   
;

2variable pos

: new-cell-info ( row col -- newinfo )
    2dup pos 2! @CellInfo

    \ If the cell is in a refractory state, update
    \ its recovery time, and transition to resting if time is up.
    dup refractory? IF  advance-reftime EXIT  THEN

    dup excited? IF  excited->refractory EXIT  THEN 

    \ Resting cell; get surrounding cell info.
    drop
    pos 2@ get-surrounding-info

    \ Are any of the four surrounding cells excited?
    excited? >r excited? >r excited? >r excited?
    r> or r> or r> or
    pos 2@ @CellInfo swap
    IF  \ yes, at least one surrounding cell is excited.
       excite-cell
    THEN
;


: set-pacemakers ( EXCITED|RESTING -- )
    dup EXCITED = IF 1 nbeats +! THEN
    L 0 DO dup CellInfoNew{{ I 0 }} w! LOOP drop
;

: display-beat ( -- )
    nbeats @ 4 .r heart-clock @ 8 .r 
    moments{ heart-clock @ } @ 6 .r 
;

: display-cells ( -- )
    page
    80 0 DO
      100 L min 0 DO
        J I @CellInfo
        excited? IF [char] * ELSE bl THEN emit
      LOOP
      cr
    LOOP
    display-beat ;

\ Fetch column values of all excited cells and store in
\ array; return number of excited cells.
L 10 * INTEGER ARRAY ExcitedCellCols{

: fetch-exc-cols ( -- n )
    0
    L 0 DO
        L 0 DO
          CellInfo{{ J I }} uw@ excited? IF
            ExcitedCellCols{ over } I swap !
            1+
          THEN
        LOOP
    LOOP
;

\ Compute center of mass column for n excited cells
: center-of-mass ( n -- u )
    0 over 0 ?DO  ExcitedCellCols{ I } @ +  LOOP 
    swap dup 0= IF drop ELSE / THEN
;

\ Compute "moment of inertia" about center of mass column
\ for excited cells
variable cm
: moment-of-inertia ( -- u )
    fetch-exc-cols
    dup center-of-mass cm !
    0 swap 0 ?DO  ExcitedCellCols{ I } @ cm @ - abs +  LOOP 
    L / ;

true value display?

: resume-heartbeat ( -- )
    BEGIN      
      \ Make my heart beat!    
      heart-clock @ PACE MOD 0= 
      IF EXCITED ELSE RESTING THEN set-pacemakers

      \ Compute new cell states for non-pacemaker cells
      L 0 DO  
        L 1 DO
           J I new-cell-info  CellInfoNew{{ J I }} w!
        LOOP
      LOOP

      \ Copy new cell info to current info
      CellInfoNew{{ 0 0 }} CellInfo{{ 0 0 }} L DUP * 2* MOVE
      
      \ Compute and store "moment of inertia" for excited cells
      moment-of-inertia moments{ heart-clock @ } !

      display? IF
        display-cells ( 30 ms ) 10000 usleep
      ELSE
        heart-clock @ 100 mod 0= IF 
          cr display-beat THEN
      THEN

      1 heart-clock +!

      heart-clock @ MAX_HC = key? or
   UNTIL
   key? IF  key drop 
   ELSE  cr ." Maximum heart cycles reached!" 
   THEN ;

\ Compute fraction of time in which AF occurred within a single run 
\ (trial) by thresholding the recorded moments.
: f_AF ( -- r )
    heart-clock @ MAX_HC 10 / < ABORT" Insufficient data!"
    0
    heart-clock @ 0 DO
      moments{ I } @ 15 > IF 1+ THEN
    LOOP
    s>f heart-clock @ s>f f/ ;

\ Probability of having at least one fibrillation-inducing
\ structure, computed by the analytic formula given in [1], eq. 2.,
\ using the current value of NU and other parameters.
: P_risk ( -- r )
    nu @ s>f 100e f/
    1e fswap f- REF_TIME s>f f**
    1e fswap f- DELTA s>f 100e f/ L s>f fdup f* f* f**
    1e fswap f- ;
 
: beat ( -- )
    0 nbeats !
    0 heart-clock !
    init-cells
    resume-heartbeat  
 ;

cr 
cr .( NU        -- variable containing percentage of transverse connections.)
cr .( DISPLAY?  -- true/false value to enable/disable text graphic display.)
cr .( BEAT      -- begin a trial.)
cr .( f_AF      -- return fraction of time in AF during last trial.)
cr .( P_risk    -- return theoretical probability of AF for current params.)
cr cr

