\ epr-sim.4th
\
\ Simulate the EPR experiment for arbitrary two-particle
\ spin states.
\
\ Krishna Myneni, <krishna.myneni@ccreweb.org>
\
\ This program is provided under Creative Commons CC BY-SA.
\ For the terms of the license, please see
\
\   https://creativecommons.org/licenses/by-sa/2.0/
\
\ This program uses external Forth libraries which are either
\ public domain, or are provided under other free licenses.
\
\ Revisions:
\
\   2021-08-21  km  first working version.
\   2021-08-29  km  first release version.
\
\ References:
\
\ 1. A. Einstein, B. Podolsky, and N. Rosen, Phys. Rev. 47,
\    777 (1935), 
\    https://journals.aps.org/pr/abstract/10.1103/PhysRev.47.777
\
\ 2. J.S. Bell, Physics 1, p. 195 (1964), 
\    https://cds.cern.ch/record/111654/files/vol1p195-200_001.pdf
\
\ 3. N. David Mermin, Physics Today 38, p. 38 (1985), 
\    https://physicstoday.scitation.org/doi/10.1063/1.880968
\
\ Notes:
\
\   0. Recommended ansi terminal settings:
\        size: 80 columns, 24 lines min.
\        font: monospace
\        encoding: utf8
\
\   1. To exit the user interface and return to the Forth prompt,
\      press "Q". To start the interface again, with all settings
\      and data preserved, use the word, "GO". A key help menu for
\      the user interface is not yet implemented. Current key
\      commands are:
\
\         Q -- quit the user interface and return to the Forth prompt.
\         L -- select the left detector (for changing axis selector).
\         R -- select the right detector.
\         1 -- use measurement axis 1 for the selected detector.
\         2 -- use measurement axis 2  "
\         3 -- etc.
\         E -- perform and record a single two-particle measurement.
\         C -- perform continuous measurements.
\         H -- halt continuous measurements.
\         T -- perform a fixed number of trials (measurements).
\         X -- delete all recorded event data.
\
\   2. Some features are still missing, such as a user interface
\      for changing the two-particle quantum state produced by
\      the emitter, and changing angle assignments on the two 
\      detectors. At present, these operations can be done via 
\      commands at the Forth prompt, e.g. 
\
\        z1/2 zdup zdup zdup Q2p2s new constant ProductState
\
\      will create a two-particle state called "ProductState"
\      with C1 = C2 = C3 = C4 = z1/2 ( 0.50e0 + i0.0e0 ). This
\      state is not entangled. The emitter (source) may be
\      set to output this state using
\
\        ProductState EM set-qstate
\
\      Angle assignments for the three positions of a detector
\      (left or right) may be set via a command such as
\
\        0.0e 30.0e 45.0e leftDet axisSel a@ assign-angles
\
\      which will set the three selectable angles for the left
\      detector to 0 degrees, 30 deg, and 45 deg, for selector
\      positions 1, 2, and 3, respectively. Similarly for the
\      right detector.
\
\   3. Measurement of expectation values for particular detector
\      orientations, and computation of the Bell inequalities
\      (Bell's original inequality for the singlet state, and the 
\      Bell-CHSH inequality for general two-particle spin states)
\      must be performed manually, although it is not difficult
\      to write a Forth word to perform the simulated trials and
\      computation of the Bell inequalities.
\
\   4. This program was written to run as is under kForth-64. A
\      compatibility file to implement non-standard Forth words
\      is available for Gforth. FSL library modules from the
\      kForth-64 package should work as-is under Gforth. 
\      ans-words.4th and xchars.4th do not need to be included 
\      under Gforth. Gforth provides fsl-util.fs and mini-oof.fs.

include ans-words
include modules
include strings
include ansi
include xchars
include random
include fsl/fsl-util
include fsl/ran4
include fsl/complex
include mini-oof

DECIMAL

0.0e0 0.0e0 zconstant z0
1.0e0 0.0e0 zconstant z1
0.5e0 0.0e0 zconstant z1/2
1.0e0 2.0e0 fsqrt f/ 0e zconstant z1/sqrt2

[undefined] CELL [IF] 1 cells constant CELL [THEN]
[undefined] fsquare [IF] : fsquare fdup f* ; [THEN]

: ]f@   ( a i -- ) ( F: -- r )  floats + f@ ;
: ]f!   ( a i -- ) ( F: r -- )  floats + f! ;
: ]ev@  ( a i -- ) ( F: -- <ev|1> <ev|0> )
    floats 2* + dup >r f@ r> float+ f@ ;
: ]ev!  ( a i -- ) ( F: <ev|1> <ev|0> -- )
    floats 2* + dup >r float+ f! r> f! ;

: $input ( -- a count )  pad 64 accept pad swap ;
: $>u ( a count -- u ) 0 0 2swap >number 2drop drop ;
: u#in ( -- u ) $input $>u ;
: udefault#in ( udefault -- u )
    $input ?dup if  $>u nip  else  drop  then ;


: sincos>evectors 
( F: sin-theta cos-theta -- <e_up|1> <e_up|0> <e_dn|1> <e_dn|0> )
    1.0e0 f+ fdup         \ F: st 1+ct 1+ct
    2.0e0 f* fsqrt fswap  \ F: st sqrt(2*(1+ct)) 1+ct 
    fover f/              \ F: st sqrt(2*(1+ct)) <e_up|1>
    -frot f/              \ F: <e_up|1> <e_up|0>
    f2dup fnegate fswap ; \ F: <e_up|1> <e_up|0> <e_dn|1> <e_dn|0>

\ Default positions, dimensions, and colors of
\ text-graphic objects

 9 10  2constant  DET_LEFT_XY
41 10  2constant  DET_RIGHT_XY
 6  3  2constant  DET_DIMS
black yellow 
       2constant  DET_COLORS

 0  1  2constant  TAPE_LEFT_XY
46  1  2constant  TAPE_RIGHT_XY
 9 12  2constant  TAPE_DIMS
blue white 
       2constant  TAPE_COLORS
65536  constant   TAPE_BUF_SIZE  \ default size in bytes

55  1  2constant  INFO_XY
25 12  2constant  INFO_DIMS
white blue
       2constant  INFO_COLORS

14  1  2constant  HIST_XY
 1  5  2constant  HIST_DIMS
magenta black
       2constant  HIST_COLORS

26 11  2constant  EMITTER_XY
 3  1  2constant  EMITTER_DIMS
blue black
       2constant  EMITTER_COLORS

HEX

DEFER rng

\ select random number generator
cdefab21 
1 [IF]
seed !
' random2p is rng
[ELSE]
s>d ffff s>d start-sequence
: ran4d ran4 drop ; 
' ran4d is rng
[THEN]
: discard-random FFFF 0 do rng drop loop ;
discard-random

DECIMAL

\  Quantum Two-Particle State class and its methods

object class
    complex var C1  \ amplitude of |11> component
    complex var C2  \ amplitude of |10> component
    complex var C3  \    "         |01> component
    complex var C4  \    "         |00> component
    method init-2p2s ( o -- ) ( F: z1 z2 z3 z4 -- )
    method normalize ( o -- )
    method exchange  ( o -- )  \ exchange particle labels
    method P_up      ( o -- ) ( F: stheta ctheta -- P_up )
    method M_up      ( o -- ) ( F: stheta ctheta -- C1' C2' C3' C4' )
    method M_down    ( o -- ) ( F: stheta ctheta -- C1' C2' C3' C4' )
end-class Q2p2s  \ two-particle, bipartite quantum state

:noname ( o -- ) ( F: zC1 zC2 zC3 zC4 -- )
   dup >r C4 z! r@ C3 z! r@ C2 z! r> C1 z! ;
Q2p2s defines init-2p2s

fvariable fnorm
:noname ( o -- )
   >r
   r@ C1 z@ |z|^2
   r@ C2 z@ |z|^2 f+
   r@ C3 z@ |z|^2 f+
   r@ C4 z@ |z|^2 f+ fsqrt 1/f fnorm f!
   r@ C1 z@ fnorm f@ z*f  r@ C1 z!
   r@ C2 z@ fnorm f@ z*f  r@ C2 z!
   r@ C3 z@ fnorm f@ z*f  r@ C3 z!
   r@ C4 z@ fnorm f@ z*f  r@ C4 z!
   r> drop ;
Q2p2s defines normalize

:noname ( o -- )
   >r
   r@ C2 z@  r@ C3 z@
   r@ C2 z!  r@ C3 z! 
   r> drop ;
Q2p2s defines exchange

fvariable 1_plus_ct
fvariable 1_minus_ct
fvariable st

\ Probability of measuring UP for first particle of two-particle state
:noname ( o -- ) ( F: sin-theta cos-theta -- P_up ) 
   >r
   1.0e0 f+ fdup    1_plus_ct f!
   fnegate 2.0e0 f+ 1_minus_ct f!
   st f!
   r@ C1 z@ |z|^2
   r@ C2 z@ |z|^2 f+
   1_plus_ct f@ f*
   r@ C3 z@ |z|^2
   r@ C4 z@ |z|^2 f+
   1_minus_ct f@ f* f+
   r@ C1 z@ conjg  r@ C3 z@ z* real 2.0e0 f*
   r@ C2 z@ conjg  r@ C4 z@ z* real 2.0e0 f* f+
   st f@ f* f+
   2.0e0 f/
   r> drop ;
Q2p2s defines P_up

\ Apply single-particle measurement operator for UP 
\ for first particle
:noname ( o -- ) ( F: sin-theta cos-theta -- C1' C2' C3' C4' )
   >r
   1.0e0 f+ fdup    1_plus_ct f!
   fnegate 2.0e0 f+ 1_minus_ct f!
   st f!

   \ Coefficients of partially collapsed state vector
   r@ C1 z@ 1_plus_ct f@ z*f
   r@ C3 z@ st f@ z*f z+
   0.5e0 z*f  \ C1' 

   r@ C2 z@ 1_plus_ct f@ z*f
   r@ C4 z@ st f@ z*f z+
   0.5e0 z*f  \ C2'
 
   r@ C1 z@ st f@ z*f
   r@ C3 z@ 1_minus_ct f@ z*f z+
   0.5e0 z*f  \ C3'

   r@ C2 z@ st f@ z*f
   r@ C4 z@ 1_minus_ct f@ z*f z+
   0.5e0 z*f  \ C4'

   r> drop ;
Q2p2s defines M_up

:noname ( o -- ) ( F: stheta ctheta -- C1' C2' C3' C4' )
   >r
   1.0e0 f+ fdup    1_plus_ct f!
   fnegate 2.0e0 f+ 1_minus_ct f!
   st f!

   \ Coefficients of partially collapsed state vector
   r@ C1 z@ 1_minus_ct f@ z*f
   r@ C3 z@ st f@ z*f z-
   0.5e0 z*f  \ C1' 

   r@ C2 z@ 1_minus_ct f@ z*f
   r@ C4 z@ st f@ z*f z-
   0.5e0 z*f  \ C2'
 
   r@ C1 z@ st f@ fnegate z*f
   r@ C3 z@ 1_plus_ct f@ z*f z+
   0.5e0 z*f  \ C3'

   r@ C2 z@ st f@ fnegate z*f
   r@ C4 z@ 1_plus_ct f@ z*f z+
   0.5e0 z*f  \ C4'

   r> drop ;
Q2p2s defines M_down

Q2p2s new constant CollapsedState
z0 z0 z0 z0 CollapsedState init-2p2s


\  Text Graphic class and its methods

object class
 2 cells var topLeft   \ col row
 2 cells var dims      \ columns rows
 2 cells var colors    \ foreground and background colors
 4 cells var auxColors \ auxiliary colors
    method init          ( ... o -- )
    method get-height    ( o -- w )
    method get-width     ( o -- h )
    method set-fg-colors ( o -- )
    method fill-area     ( color o -- )
    method clear-area    ( o -- )
    method draw          ( ... o -- )
end-class text-graphic

:noname ( x y w h fcolor bcolor o -- )
   dup >r colors 2! r@ dims 2! r> topLeft 2! ;
text-graphic defines init

:noname ( o -- h ) dims @ ;       text-graphic defines get-height
:noname ( o -- w ) dims cell+ @ ; text-graphic defines get-width
:noname ( o -- ) colors 2@ background foreground ;
text-graphic defines set-fg-colors

:noname ( color o -- )
   over background
   swap foreground
   dup dims 2@  \ o w h
   0 ?do
     over topLeft 2@ I + at-xy
     dup spaces
   loop 2drop ;
text-graphic defines fill-area

:noname ( o -- ) 
   dup colors 2@ nip 
   swap fill-area ;
text-graphic defines clear-area

\  Three-angle selector widget class

text-graphic class
   cell var pos         \ selector position
 3 dfloats var theta[   \ angles (for pos=1 to 3)
 3 dfloats var ctheta[  \ cos(theta_i)
 3 dfloats var stheta[  \ sin(theta_i)
   method assign-angles ( o -- ) ( F: deg1 deg2 deg3 -- )
   method get-current-angle ( o -- ) ( F: -- deg )
   method get-sincos    ( o -- ) ( F: sintheta costheta )
end-class selector3A

:noname ( o -- ) ( F: theta1-deg theta2-deg theta3-deg -- )
   >r
   deg>rad 
   fdup    r@ theta[ 2 ]f!
   fsincos r@ ctheta[ 2 ]f! r@ stheta[ 2 ]f!
   deg>rad
   fdup    r@ theta[ 1 ]f!
   fsincos r@ ctheta[ 1 ]f! r@ stheta[ 1 ]f!
   deg>rad
   fdup    r@ theta[ 0 ]f!
   fsincos r@ ctheta[ 0 ]f! r@ stheta[ 0 ]f!
   r> drop ;
selector3A defines assign-angles

:noname ( o -- ) ( F: deg )  \ get current selector angle
   dup pos @ 1- swap theta[ swap ]f@
   rad>deg ;
selector3A defines get-current-angle

:noname ( o -- ) ( F: sin_theta cos_theta )
   dup pos @ 1- swap 2dup 
   2>r stheta[ swap ]f@
   2r> ctheta[ swap ]f@ ;
selector3A defines get-sincos

HEX

:noname ( o -- )
    dup >r 
    topLeft 2@ at-xy
    r@ set-fg-colors
    space
    r@ colors 2@ nip r@ auxColors @
    r@ pos @   \ bkg aux pos
    4 1 DO
      dup I = IF over ELSE 2 pick THEN background
      I 30 + emit 
    LOOP drop 2drop
    r@ colors 2@ nip background
    space r> drop ;
selector3A defines draw


\  Two-light indicator widget class

text-graphic class
   cell  var stateBits  \ bits 0 and 1 indicate status for each light
   method set-lights  ( bits o -- )
end-class indicator2L

:noname ( bits o -- )
   swap 3 and swap stateBits ! ;
indicator2L defines set-lights

:noname ( m o -- )
    dup topLeft 2@ at-xy
    dup colors  2@ nip 
    dup background foreground
    text_bold space
    dup >r set-lights
    r@ stateBits @
    case
      0 of  25ef 25ef  endof
      1 of  25cf 25ef  endof
      2 of  25ef 25cf  endof
      3 of  25ef 25ef  endof  \ this case should never happen
    endcase
    r@ auxColors 2@ foreground swap
    xemit space foreground xemit space
    r> drop ;
indicator2L defines draw

DECIMAL

\  Detector class and its methods

text-graphic class
    cell var facingLeft     \ true = facing left, false = facing right
    cell var axisSel        \ axis selector
    cell var udInd          \ up-down indicator
    cell var measurement    \ last reading from method MEASURE
 3 2* dfloats var e_up[     \ up eigenvectors for theta_i
 3 2* dfloats var e_down[   \ down eigenvectors for theta_i
    method compute-evs ( o -- )
    method map-angles ( o -- ) ( F: deg1 deg2 deg3 -- )
    method show-axis ( o -- )
    method set-axis ( u o -- )
    method measure ( ostate o -- ostate' m )
    method show-measurement ( m o -- )
end-class detector

:noname ( odet -- )
   >r
   r@ stheta[ 0 ]f@   r@ ctheta[ 0 ]f@ 
   sincos>evectors
   r@ e_down[ 0 ]ev!  r@ e_up[ 0 ]ev!
   r@ stheta[ 1 ]f@   r@ ctheta[ 1 ]f@
   sincos>evectors
   r@ e_down[ 1 ]ev!  r@ e_up[ 1 ]ev!
   r@ stheta[ 2 ]f@   r@ ctheta[ 2 ]f@
   sincos>evectors
   r@ e_down[ 2 ]ev!  r> e_up[ 2 ]ev! ;
detector defines compute-evs

:noname ( x y w h f b o -- ) 
   dup >r  [ text-graphic :: init ]
   selector3A  new   r@ axisSel !
   indicator2L new   r@ udInd !
   r@ topLeft 2@     r@ udInd   a@ topLeft 2!
   r@ dims 2@ drop 1 r@ udInd   a@ dims 2!
   r@ colors 2@      r@ udInd   a@ colors 2!
   r@ topLeft 2@ 2+  r@ axisSel a@ topLeft 2!
   r@ dims 2@ drop 2 r@ axisSel a@ dims 2!
   r@ colors 2@      r@ axisSel a@ colors 2!  
   0.0e 60.0e 120.0e r@ axisSel a@ assign-angles  \ default angles
   1         r@ axisSel a@ pos !
   white     r@ axisSel a@ auxColors !
   red green r@ udInd   a@ auxColors 2!
   0 r@ measurement !
   r> drop
; detector defines init

:noname ( o -- ) ( F: deg1 deg2 deg3 -- )
   axisSel a@ assign-angles ;
detector defines map-angles

:noname ( u o -- )
   swap 1 max 3 min swap axisSel a@ pos ! ;
detector defines set-axis

:noname ( ostate odet -- ostate' m )
   2dup 2>r 
   nip axisSel a@ get-sincos
   2r@ drop P_up 
   6.5535e4 f* fround>s        \ threshold for m=2 (up)
   rng 65535 and swap          \ 16-bit random value
   <= IF
     2  \ measurement = UP
     st f@ 1_plus_ct f@ 1.0e0 f- 2r@ drop M_up
   ELSE
     1  \ measurement = DOWN
     st f@ 1_plus_ct f@ 1.0e0 f- 2r@ drop M_down  
  THEN
  CollapsedState init-2p2s
  dup 2r> nip measurement !
  CollapsedState dup normalize
  swap ; 
detector defines measure

HEX

:noname ( o -- ) axisSel a@ draw ;
detector defines show-axis

:noname ( m o -- )
   udInd a@ draw ;
detector defines show-measurement

:noname ( o -- )
   dup >r measurement @
   r@ show-measurement
   r@ show-axis
   r@ topLeft 2@ 1+ at-xy
   r@ colors  2@ nip foreground
   5 spaces
   r@ facingLeft @ IF
      6 cur_left
      25d7
   ELSE
      25d6
   THEN
   black background xemit
   r> drop ;
detector defines draw


\ Tape Recorder class and its methods

text-graphic class
   cell var tapeBuffer
   cell var recordCount
   method   write-record ( setting measurement o -- )
   method   read-record ( i o -- setting measurement )
end-class tape

:noname ( x y w h f b o -- ) 
   dup >r [ text-graphic :: init ]
   0 r@ recordCount ! 
   TAPE_BUF_SIZE allocate
   ABORT" Unable to allocate tape buffer!"
   r> tapeBuffer ! ;
tape defines init

: pack-sm ( s m -- byte )
    3 and swap 3 and 2 lshift or ;

: unpack-sm ( byte -- s m )
    dup 3 and swap 2 rshift 3 and swap ;

:noname ( s m o -- ior )
   dup recordCount @ TAPE_BUF_SIZE < IF
     >r pack-sm
     r@ tapeBuffer a@ 
     r@ recordCount @ + c! 
     1 r> recordCount +!
     0
   ELSE  drop 2drop 1
   THEN ;
tape defines write-record

:noname ( idx o -- s m )
   tapeBuffer a@ + c@ unpack-sm ;
tape defines read-record
 
:noname ( o -- )
   dup colors  2@ nip background
   dup topLeft 2@ at-xy
   dup >r recordCount @  r@ get-height -
   dup 0> IF
     r@ swap over recordCount @ swap
   ELSE
     drop r@
     dup recordCount @ 0
   THEN
   ?DO
     dup colors 2@ drop foreground
     I 5 .r space 
     I over read-record
     black foreground
     swap 30 + emit
     case
       1 of red   foreground [char] D emit endof
       2 of green foreground [char] U emit endof
     endcase
     8 cur_left 1 cur_down
   LOOP
   drop r> drop 
   black background ;
tape defines draw

\  Emitter class and its methods

text-graphic class
   cell var qstate    \ object of type Q2p2s
   cell var emitCount 
   method   reset-emitter
   method   set-qstate ( ostate o -- )
   method   emit-pair
end-class emitter

:noname ( o -- )
   0 swap emitCount ! ;
emitter defines reset-emitter

:noname ( x y w h f b o -- )
   dup >r [ text-graphic :: init ] 
   r> reset-emitter ;
emitter defines init

:noname ( o -- )
   dup topLeft 2@ at-xy
       set-fg-colors
   25b6 xemit
   2588 xemit
   25c0 xemit ;
emitter defines draw

:noname ( ostate o -- )  qstate ! ;
emitter defines set-qstate

:noname ( o -- ostate ) 
   qstate a@ ;
emitter defines emit-pair

DECIMAL

\  Histogram class and its methods

text-graphic class
   cell var histCount  \ count of events
   cell var histTest   \ xt of classifier (xt stack: ( m1 m2 -- flag ))
   method   clear-hist  ( o -- )  \ clear histCount
   method   add-event?  ( m1 m2 o -- )
   method   show-hist-labels ( o -- )
end-class histogram

:noname ( o -- ) 0 swap histCount ! ;
histogram defines clear-hist

:noname ( xt x y w h f b o -- )
   dup >r [ text-graphic :: init ]
   r@ histTest ! 
   0 r> histCount ! ;
histogram defines init

:noname ( m1 m2 o -- )
   dup >r
   histTest a@ execute
   IF 1 r@ histCount +! THEN
   r> drop ;
histogram defines add-event?

:noname ( ntotalevents o -- )
   dup set-fg-colors
   dup >r topLeft 2@ at-xy
   r@ get-height 0 do space 1 cur_left 1 cur_down  loop
   r@ colors 2@ drop background
   s>f r@ histCount @ s>f fswap f/
   r@ get-height s>f f* fround>s
   0 ?do
     space
     1 cur_up 1 cur_left
   loop
   black background 
   r> drop ;
histogram defines draw


\  Information Box and its methods

text-graphic class
   cell var emitterObject
   cell var ldetObject
   cell var rdetObject
   method set-info ( oemitter oldet ordet o -- )
   method show-qstate ( o -- )
   method show-det-angles ( o -- )
   method show-key-commands ( o -- )
end-class InfoBox

:noname ( o -- )
   dup colors 2@ 
   nip dup background foreground
   dup get-height 0 ?do
     dup topLeft 2@ I + at-xy
     clrtoeol
   loop drop
   black background ;
InfoBox defines clear-area

:noname ( oEM oLdet oRdet o -- )
   dup >r rdetObject ! r@ ldetObject ! r@ emitterObject !
   r> drop ;
InfoBox defines set-info

\ Show the current emitter two-particle quantum state
:noname ( o -- )
   dup >r emitterObject a@ qstate a@ >r
   r@ C4 z@  r@ C3 z@  r@ C2 z@  r> C1 z@
   r@ topLeft   2@ at-xy
   r@ colors    2@ background drop
   r@ auxColors 2@ drop foreground
   space ." Two-Particle State"
   r@ topLeft   2@ 1+  at-xy
   r@ colors    2@ drop foreground
   space ." C1: " 
   r@ auxColors 2@ foreground drop z. clrtoeol
   r@ topLeft   2@ 2 + at-xy
   r@ colors    2@ drop foreground
   space ." C2: " 
   r@ auxColors 2@ foreground drop z. clrtoeol
   r@ topLeft   2@ 3 + at-xy
   r@ colors    2@ drop foreground
   space ." C3: " 
   r@ auxColors 2@ foreground drop z. clrtoeol
   r@ topLeft   2@ 4 + at-xy
   r@ colors    2@ drop foreground
   space ." C4: " 
   r@ auxColors 2@ foreground drop z. clrtoeol
   r> drop
   black background ;
InfoBox defines show-qstate

\ Show currently selected detector axes angles
:noname ( o -- )
   dup >r 
      topLeft   2@ 5 + at-xy
   r@ colors    2@ background drop
   r@ auxColors 2@ drop foreground
   space ." Axes Angles"
   r@ topLeft   2@ 6 + at-xy
   r@ colors    2@ drop foreground 
   space ." Left:  "
   r@ auxColors 2@ foreground drop
   r@ ldetObject a@ axisSel a@ get-current-angle 
   5 1 f.rd clrtoeol
   r@ topLeft   2@ 7 + at-xy
   r@ colors    2@ drop foreground 
   space ." Right: "
   r@ auxColors 2@ foreground drop
   r@ rdetObject a@ axisSel a@ get-current-angle
   5 1 f.rd clrtoeol
   r> drop
   black background ;
InfoBox defines show-det-angles

:noname ( o -- )
   dup >r
     topLeft    2@ 9 + at-xy
   r@ colors    2@ background drop
   r@ auxColors 2@ drop foreground
   space ." Key Commands:"
   r@ topLeft   2@ 10 + at-xy
   r@ auxColors 2@ foreground drop
   s"  L R 1 2 3 E H T X Q" type 
   r> drop
   black background ;
InfoBox defines show-key-commands
  
:noname ( o -- )
   dup show-qstate  
   dup show-det-angles  
       show-key-commands ;
InfoBox defines draw


2variable leftParticlePos
2variable rightParticlePos 

HEX

: show-particles ( -- )
    black background
    white foreground
    leftParticlePos  2@ at-xy space
    2 cur_left 22c5 xemit
    rightParticlePos 2@ at-xy space
    22c5 xemit 
    leftParticlePos 2@
    swap 1- swap leftParticlePos 2!
    rightParticlePos 2@
    swap 1+ swap rightParticlePos 2!
;

Q2p2s new constant Singlet
z0 z1/sqrt2 z1/sqrt2 znegate z0 Singlet init-2p2s

\ For diagnostics
Q2p2s new constant UpUp
z1 z0 z0 z0 UpUp init-2p2s

detector new constant leftDet  
DET_LEFT_XY  DET_DIMS  DET_COLORS leftDet  init
detector new constant rightDet 
DET_RIGHT_XY DET_DIMS  DET_COLORS rightDet init

false leftDet  facingLeft !
true  rightDet facingLeft !

emitter new constant EM   
EMITTER_XY EMITTER_DIMS EMITTER_COLORS EM init
\ Set the emitter to output the singlet two-particle state
Singlet EM set-qstate

tape new constant leftTape  
TAPE_LEFT_XY  TAPE_DIMS  TAPE_COLORS  leftTape  init
tape new constant rightTape 
TAPE_RIGHT_XY TAPE_DIMS  TAPE_COLORS  rightTape init

InfoBox new constant ConfigInfo
INFO_XY INFO_DIMS INFO_COLORS ConfigInfo init
EM leftDet rightDet ConfigInfo set-info
yellow cyan ConfigInfo auxColors 2!

\ Measurement tests
: uu? ( m1 m2 -- flag ) 2 = swap 2 = and ;
: ud? ( m1 m2 -- flag ) 1 = swap 2 = and ;
: du? ( m1 m2 -- flag ) 2 = swap 1 = and ;
: dd? ( m1 m2 -- flag ) 1 = swap 1 = and ;

histogram new constant H_P_uu
' uu? HIST_XY HIST_DIMS HIST_COLORS H_P_uu init
histogram new constant H_P_ud 
' ud? HIST_XY swap 2 + swap HIST_DIMS HIST_COLORS H_P_ud init
histogram new constant H_P_du
' du? HIST_XY swap 4 + swap HIST_DIMS HIST_COLORS H_P_du init
histogram new constant H_P_dd 
' dd? HIST_XY swap 6 + swap HIST_DIMS HIST_COLORS H_P_dd init

: joint-probabilities ( F: -- P_uu P_ud P_du P_dd )
    H_P_uu histCount @   H_P_ud histCount @ +
    H_P_du histCount @ + H_P_dd histCount @ + s>f
    H_P_uu histCount @ s>f fover f/ fswap
    H_P_ud histCount @ s>f fover f/ fswap
    H_P_du histCount @ s>f fover f/ fswap
    H_P_dd histCount @ s>f fover f/ fnip ;

: show-jp ( -- )
    joint-probabilities
    H_P_uu topLeft 2@ swap 10 + swap 4 + 2>r
    2r@    at-xy
    white foreground ." P_dd = " cyan foreground 5 3 f.rd
    2r@ 1- at-xy
    white foreground ." P_du = " cyan foreground 5 3 f.rd
    2r@ 2-  at-xy
    white foreground ." P_ud = " cyan foreground 5 3 f.rd
    2r> 3 - at-xy
    white foreground ." P_uu = " cyan foreground 5 3 f.rd 
    black background ; 
    
: expectation-value ( F: -- r )
    H_P_uu histCount @  H_P_dd histCount @ + dup >r
    H_P_ud histCount @  H_P_du histCount @ + dup >r
    - s>f 2r> + s>f f/ ;

: show-correlation ( F: -- )
    expectation-value
    H_P_uu topLeft 2@ 6 + swap A + swap at-xy
    white foreground ." E("
    leftDet  axisSel a@ pos @ 1 .R [char] , emit
    rightDet axisSel a@ pos @ 1 .R
    ." ) = "
    cyan foreground 7 4 f.rd ;
    
: draw-histogram-labels ( -- )
    H_P_uu dup get-height swap  \ h o
    topLeft 2@ 2 pick + 2dup      \ h x y+h x y+h 
    1+ swap 1- swap at-xy
    white foreground ." uu" blue foreground ." ud"
    white foreground ." du" blue foreground ." dd"
    swap 2- swap at-xy
    white foreground
    0 do
      [char] | emit 1 cur_up 1 cur_left
    loop ;

DECIMAL

: .status ( caddr u -- )
    blue background white foreground
    0 0 at-xy clrtoeol 
    0 0 at-xy
    type ;     

: draw-experiment ( -- )
    black background
    text_bold
    page
    leftDet   draw
    rightDet  draw
    EM        draw
    leftTape  dup clear-area draw
    rightTape dup clear-area draw
    draw-histogram-labels
    rightTape recordCount @ IF
      show-jp
      show-correlation
    THEN 
    ConfigInfo dup clear-area draw ;

: launch-particles ( -- qstate )
    EM topLeft 2@ swap 1-  swap leftParticlePos  2!
    EM topLeft 2@ swap 3 + swap rightParticlePos 2!
    EM emit-pair
    1 EM emitCount +!
;

: reached-detector? ( -- flag )
    leftParticlePos 2@ drop
    leftDet topLeft 2@ drop 6 + = ;

: record-measurements ( -- ior )
    leftDet   dup axisSel a@ pos @ swap measurement @ 
    leftTape  write-record
    rightDet  dup axisSel a@ pos @ swap measurement @ 
    rightTape write-record or ; 

: update-histograms ( -- )
    leftDet  measurement @ 
    rightDet measurement @
    2dup H_P_uu add-event?
    2dup H_P_ud add-event?
    2dup H_P_du add-event?
         H_P_dd add-event? ;

: show-histograms ( -- )
    leftTape recordCount @ 
    ?dup IF
      dup H_P_uu draw
      dup H_P_ud draw
      dup H_P_du draw
          H_P_dd draw
    THEN ;

: show-statistics ( -- )
    leftTape  draw
    rightTape draw
    show-histograms
    show-jp show-correlation ;

: trial ( -- ior )
    launch-particles  \ -- qstate
    0 leftDet  show-measurement
    0 rightDet show-measurement
    BEGIN
      reached-detector? 0=
    WHILE
      show-particles
      5000 usleep
    REPEAT
    leftParticlePos  2@ at-xy space
    rightParticlePos 2@ at-xy space
    \ -- qstate
    leftDet   measure leftDet  show-measurement
    dup exchange
    rightDet  measure rightDet show-measurement
    drop
    record-measurements dup
    0= IF
      update-histograms
      show-statistics 
    THEN ;

\ run trials with no graphics
: run-fixed-trials ( u -- ior )
    0 ?DO
      EM emit-pair  \ -- qstate
      leftDet  measure drop
      dup exchange
      rightDet measure drop
      drop
      record-measurements dup
      0= IF  update-histograms
      ELSE unloop EXIT THEN
      drop
    LOOP 0 ;


variable sel_det  \ selected detector: 0 = left, 1 = right
0 sel_det !

true value halted?

: set-det-axis ( n -- )
    sel_det @
    case
      0 of leftDet  set-axis  leftDet  draw  endof
      1 of rightDet set-axis  rightDet draw  endof
    endcase ;

: reset-counts ( -- )
    0 leftTape  recordCount !
    0 rightTape recordCount !
    0 EM        emitCount !
    0 H_P_uu    histCount !
    0 H_P_ud    histCount !
    0 H_P_du    histCount !
    0 H_P_dd    histCount ! ;

: delete-data ( -- )
    reset-counts
    page draw-experiment ;

\ Interface for fixed number of trials (with graphics at end)
variable lastTrials

: fixed-trials ( -- )
    true to halted?
    s" Enter number of trials"
    lastTrials @ ?dup 
    if  
      dup >r  u>string count 
      s"  [" 2swap strcat s" ]: " strcat strcat
      .status r> udefault#in
    else
      s" : " strcat  .status u#in
    then

    dup 20000 u> IF
      drop 
      s" Too many trials -- operation cancelled." .status
      EXIT
    THEN
    dup run-fixed-trials 0= IF
      dup lastTrials !
      s" Finished " rot u>string count strcat s"  trials." strcat
    ELSE
      drop
      s" Tape Recorder Write Error!"
    THEN 
    .status
    black background  
    show-statistics ;

: go ( -- )
    true to halted?
    s" Ready. Use key commands -- 'Q' to return to Forth." .status
    ConfigInfo draw
    BEGIN
      key?
      IF
        key
        case
          [char] L   of  0 sel_det !  s" Left Detector selected." .status endof
          [char] R   of  1 sel_det !  s" Right Detector selected." .status endof
          [char] 1   of  1 set-det-axis  ConfigInfo show-det-angles endof
          [char] 2   of  2 set-det-axis  ConfigInfo show-det-angles endof
          [char] 3   of  3 set-det-axis  ConfigInfo show-det-angles endof
          [char] H   of  true to halted? 
                         s" Halted." .status  endof
          [char] E   of  trial drop endof
          [char] T   of  fixed-trials     endof
          [char] X   of  delete-data 
                         s" Event data deleted." .status endof
          [char] C   of  false to halted? 
                         s" Taking measurements..." .status endof
          [char] Q   of  
                 s" Returned to Forth. Type 'go' to start user interface."
                 .status
                 black background white foreground
                 leftTape topLeft 2@ 
                 leftTape get-height + 1+ at-xy
                 exit  endof
        endcase
      ELSE
        halted? 0= IF 
          trial IF
            true to halted?
            s" Halted due to error!" .status
          THEN
        THEN
        30000 usleep
      THEN
    AGAIN
;

6 set-precision

draw-experiment
go

