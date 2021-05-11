\ Super Star Trek
\
\   Translated from the book BASIC COMPUTER GAMES, edited by
\   David Ahl, 1978, New York: Workman Publishing.
\
\   Original program by Mike Mayfield, May 16, 1978
\
\   Here is the original BASIC header:
\
\   SUPER STARTREK - MAY 16, 1978 - REQUIRES 24K MEMORY
\ 
\ ***        **** STAR TREK ****        ****
\ *** SIMULATION OF A MISSION OF THE STARSHIP ENTERPRISE,
\ *** AS SEEN ON THE STAR TREK TV SHOW.
\ *** ORIGINAL PROGRAM BY MIKE MAYFIELD, MODIFIED VERSION
\ *** PUBLISHED IN DEC'S "101 BASIC GAMES", BY DAVE AHL.
\ *** MODIFICATIONS TO THE LATTER (PLUS DEBUGGING) BY BOB
\ *** LEEDOM - APRIL & DECEMBER 1974,
\ *** WITH A LITTLE HELP FROM HIS FRIENDS . . .
\ *** COMMENTS, EPITHETS, AND SUGGESTIONS SOLICITED --
\ *** SEND TO:  R. C. LEEDOM
\ ***           WESTINGHOUSE DEFENSE & ELECTRONICS SYSTEMS CNTR.
\ ***           BOX 746, M.S. 338
\ ***           BALTIMORE, MD  21203
\ ***
\ *** CONVERTED TO MICROSOFT 8 K BASIC 3/16/78 BY JOHN BORDERS
\ *** LINE NUMBERS FROM VERSION STREK7 OF 1/12/75 PRESERVED AS
\ *** MUCH AS POSSIBLE WHILE USING MULTIPLE STATMENTS PER LINE
\
\ Revisions:
\   2006-10-14  ported to ANS-Forth by Krishna Myneni,
\               Creative Consulting for Research and Education
\               (krishna.myneni@ccreweb.org)
\   2006-10-15  new random number generator (thanks to Marcel
\               Hendrix), additional logic for ShieldControl and
\               DamageControl when docked at starbase.  km
\   2006-10-22  fixed logic in KlingonsShoot, CheckEnergy,
\               and cleaned up CommandInput using suggestions
\               from Ed Beroset and Albert van der Horst.
\               Reworked logic for DamageControl and for
\               FirePhotonTorpedo to destroy the Enterprise
\               if we blow up the starbase to which we are docked.
\               Also modified #in to prevent problems with handling
\               non-numeric input.
\  2008-09-19   Bug fixes: 
\               Increased insufficient size of array n{, used in
\               word LongRangeSensors, by 1; bug found by Hans Bezemer.
\               Fixed incorrect use of variable "d1" as an fvariable
\               in word RepairDamage; bug found by Doug Hoffman.
\  2008-09-28   Improved ANS-Forth compatibility. Following Doug
\               Hoffman's suggestion, added leading zero to fractional
\               fp numbers, and provided definitions of non-ANS words,
\               F<=, F>=, F<>. Fixed a bug in QuadrantName, found
\               by Doug --- quadrant name didn't match quadrant
\               coordinates.
\ ----------------------------------------------------------------
\
\ Notes (by Krishna Myneni):
\
\ 0) This program, and its various ports, appear to be in the public
\    domain. If you modify and/or redistribute this Forth version,
\    please include the above header. 
\
\ 1) The history of this program may be found at:
\
\      http://www3.sympatico.ca/maury/games/space/star_trek.html
\      http://www.cactus.org/%7Enystrom/startrek.html
\      http://www.dunnington.u-net.com/public/startrek/
\
\ 2) I first encountered this game in the late 70's in David Ahl's
\    book, and I ported it then to my Commodore Vic-20 computer.
\    Later, in the 80's, I ported the program to QuickBasic v4.5.
\    In the 90's, I began an on and off port to Forth, but it wasn't
\    until the fall of 2006 that I found some time to finish the port
\    of this classic program to kForth. With trivial mods, documented
\    below, this program should run on any ANS-Forth system. The
\    floating point wordset is required, but does (should) not have
\    a dependency on whether an integrated fp/data stack or separate
\    fp stack is used.
\
\ 3) This port is based on my earlier QuickBasic version, as well
\    as on Chris Nystrom's well-structured C version of the game,
\    The latter is easily found on the Web.
\
\ 4) I've pretty much refrained from making any significant changes to
\    the program. I also refrained from changing variable names to 
\    preserve some of the code's history --- there is some nostalgia
\    for those of us who started programming in the 70's using
\    unstructured BASIC. This version retains the look and feel
\    of the original game, and is, I believe, functionally equivalent
\    to the 1978 version.
\
\    Some changes I *have* made are:
\
\      a) I included the instructions as part of a very simple help
\         system within the program.
\
\      b) I couldn't follow the logic of the original distance and
\         direction calculator, so I rewrote it (DirectionCalc).
\
\      c) The quadrant and sector coordinate pairs are (row,col)
\         pairs. For motion of the ship, or torpedo trajectories,
\         intermediate variables with x,y naming are provided.
\         The mapping of row with "x" and of col with "y", as was done
\         in the original program, is confusing to me. Therefore,
\         I inverted the use of the x,y variables to correspond
\         to their ordinary meaning in a Cartesian coordinate system:
\         the "x" variables now represent a horizontal coordinate,
\         and the "y" variables represent a vertical coordinate.
\         Ship motion and torpedo motion calculations have been
\         reworked. All of these changes are internal to the
\         program and do not affect the output of sector and
\         quadrant coordinate pairs.
\
\      d) I found and fixed some bugs in the original code and/or
\         the C version. These are documented in the next note.
\
\ 5) The following bugs are fixed in this Forth version:
\
\    5.1: In line 4480 in the original BASIC version, and in
\         phaser_control() in the C version, the phaser hit
\         energy is not calculated with the correct distance:
\         FND(0) should be FND(I). The formula also appears to
\         allow the hit energy to be greater than the energy
\         fired from the ship. These problems are fixed in this
\         version, in FirePhasers.
\
\    5.2: In line 6060 of the BASIC version from Ahl, the incorrect
\         distance is used, FND(1) should be FND(I), to compute hit
\         energy. This is fixed in KlingonsShoot.
\
\    5.3: In the C version, in klingons_shoot(), when a Klingon
\         ship's energy is low, and it shoots at the Enterprise,
\         its energy can diminish to zero due to its integer
\         representation. The program logic then no longer treats
\         the ship correctly. It remains in the game, but does not
\         appear on the SRS display. The problem has been fixed
\         in KlingonsShoot, by not allowing the Klingon ship energy
\         to go entirely to zero until it is destroyed.
\
\    5.4: If we are docked at a starbase and we move the ship,
\         the docked flag appears to remain set. This has been
\         fixed in CourseControl.
\  
\ 6) This program is a great way to teach conversion between polar
\    coordinates and rectangular coordinates. Locations are given as
\    quadrant and sector coordinates (rectangular), while the user
\    must input a polar angle (scaled) when firing photon torpedos
\    or moving through the galaxy. The user also has to take into
\    account the radial distance from the ship when firing phasers,
\    or in selecting a warp factor to reach a destination quadrant.
\


include ans-words    \ comment this line if not using kForth 
TRUE value kForth?   \ change to FALSE if not using kForth

\ --- Select Forth system: kForth or strict ANS? ---
kForth? [IF]
    [undefined] blank [IF] : blank ( a u -- ) bl fill ; [THEN]
    : page ( -- ) 27 emit ." [2J" 27 emit ." [0;0H" ;
[ELSE]
    [undefined] pi  [IF] -1e facos fconstant pi [THEN]
    [undefined] f<= [IF] : f<= fover fover f< >r f= r> or ; [THEN]
    [undefined] f>= [IF] : f>= fover fover f> >r f= r> or ; [THEN]
    [undefined] f<> [IF] : f<> f= 0= ; [THEN]
    [undefined] s>f [IF] : s>f s>d d>f ; [THEN]
    [undefined] ftrunc [IF] : ftrunc f>d d>f ; [THEN]
    : ?allot here swap allot ;
    : a@ @ ;
    : ftrunc>s f>d d>s ;
    : fround>s fround f>d d>s ;
    : rad>deg  180e f* pi f/ ;
    : deg>rad  pi f* 180e f/ ;
[THEN]


\ --- UTILITIES (for strings, input, arrays, random numbers, doc) ---

: cell- ( a1 -- a2 | backup 1 cell)
    [ 1 cells ] literal - ;

\ --- Small strings package ---

: is_lc_alpha? ( u -- flag | true if u is a lower case alphabetical character)
    dup 96 > swap 123 < and ;	

: $const  ( a u <name> -- | create a string constant )
    create dup >r cell+ ?allot dup r@ swap ! cell+ r> cmove  
    does> ( -- a' u ) dup @ swap cell+ swap ;  

: $var ( umax <name> -- | create a string variable of max length umax)
    create dup >r 2 cells + ?allot dup r@ swap ! cell+ r> swap !
    does> ( -- a$ u$ ) dup @ swap [ 2 cells ] literal + swap ;
    
: $max-length ( a$ u$ -- umax | return maximum length of string)
    drop cell- @ ;

: $set-length ( ulen a$ u$ -- | reset string variable length to ulen)
    rot >r 2dup $max-length r@ < ABORT" String variable too short."
    drop [ 2 cells ] literal - r> swap ! ;

: $space ( ulen a$ u$ -- | set string variable to be of length ulen, filled with spaces)
    2>r dup 2r@ $set-length 2r> drop swap blank ;

: $copy ( a u a$ u$ -- | copy string to string variable)
    2over 2over $set-length 2drop swap cmove ;

\ --- Generic string words ---
( args don't have to be string variables ) 

16384 constant STR_BUF_SIZE
create string_buf STR_BUF_SIZE allot	\ dynamic string buffer
variable str_buf_ptr
string_buf str_buf_ptr !

: adjust_str_buf_ptr ( u -- | adjust pointer to accomodate u bytes )
    str_buf_ptr a@ + string_buf STR_BUF_SIZE + >=
    IF  string_buf str_buf_ptr !  THEN ;

: $cat ( a1 u1 a2 u2 -- a3 u3 )
    rot 2dup + 1+ adjust_str_buf_ptr 
    -rot
    2swap dup >r
    str_buf_ptr a@ swap cmove
    str_buf_ptr a@ r@ +
    swap dup r> + >r
    cmove 
    str_buf_ptr a@
    dup r@ + 0 swap c!
    dup r@ + 1+ str_buf_ptr !
    r> ;

: $mid ( a u pos len -- a2 u2 | return a substring)
    >r 1- nip + r> ; \ origin is 1 for "pos"

: $left ( a u u2 -- a2 u2 | return left substring)
    nip ;

: $right ( a u n -- a2 u2 | return right substring)
    dup >r - 0 max + r> ;

: $ucase ( a u -- a u | convert string to upper case)
    2dup 0 ?DO
	dup c@ dup is_lc_alpha? IF 95 and THEN
	over c! 1+
    LOOP drop ;

: u>$ ( u -- a u2 | return string representing u)
    0 <# #s #> ;

\ --- String and numeric input ---

: $input ( -- a u )
    pad 64 accept pad swap ;

: #in ( -- n | positive integer or -1 )
    $input  over c@ [char] 0 [char] : within IF
	evaluate  ELSE -1  THEN ; 

: f#in ( -- f )
    $input >float drop ;

\ --- Arrays and matrices (FSL-style) ---

1 cells   constant  INTEGER
1 dfloats constant  FLOAT

\ defining word for 1-d array
: array ( n cell_size -- | -- addr )
    create 2dup swap 1+ * ?allot ! drop does> cell+ ;

: }   ( addr n -- addr[n] | fetch 1-D array address)
    over cell- @ * swap + ;

\ defining word for a 2-d matrix
: matrix  ( n m size -- )          
    create >r 2dup * r@ * 2 cells + ?allot
    2dup ! cell+ r> swap ! 2drop does>  [ 2 cells ] literal + ;

: }}  ( addr i j -- addr[i][j] | fetch 2-D array address)
    >r >r dup cell- cell- 2@ r> * r> + * + ;

\ --- Random number generation ---
hex 
ff800000 constant ROL9MASK
decimal
-1 0 d>f fconstant RAND_SCALE

variable seed

: rol9 ( u1 -- u2 | rotate u1 left by 9 bits )
    dup ROL9MASK and 23 rshift swap 9 lshift or ;     

: random2 ( -- u ) seed @ 107465 * 234567 + rol9 dup seed ! ;

: ran0 ( -- f )
    random2 s>f RAND_SCALE f/ 0.5e f+ ;

time&date 2drop 2drop + seed !

: % ( n -- f ) s>f 100e f/ ;

: chance ( f -- flag | return a true flag f*100 percent of the time)
    ran0 fswap f<= ;

: rnd() ( n -- f | return random number between 0e0 and [n]e0 )
    s>f ran0 f* ;


\ --- Simple help system ---

10 constant  NL
s"  " $const EOL$  NL EOL$ drop c!

: doc( ( buf <doc> -- u | parse text into buffer ) \ terminates on ")doc"
    dup >r
    BEGIN
	refill IF
	    dup NL word count
	    2dup 2>r
	    $ucase s" )DOC" search >r 2drop r>
	    IF   2r> 2drop drop true
	    ELSE 2r@ rot swap move
		2r> nip + NL over c! 1+
		false
	    THEN
	ELSE true THEN
    UNTIL
    r> - 
;

create help_buf 8192 allot
0 value HELP_SIZE
variable help_line

: help ( -- )
    page
    0 help_line !
    help_buf HELP_SIZE
    BEGIN
	dup 0= IF 2drop EXIT THEN
	2dup EOL$ search
    WHILE
	    2dup 2>r 2over drop nip - nip type cr
	    2r> 1- swap 1+ swap
	    1 help_line +!
	    help_line @ 24 mod 0= IF
		." [More (y/n)?] " key 95 and [char] N =
		IF 2drop EXIT THEN page
	    THEN
    REPEAT
    2drop 2drop ;


\ --- GAME STARTS HERE -------------------------------------------


9 9 INTEGER matrix g{{  \ the galaxy     	
4 4 INTEGER matrix k{{  \ Klingon data		
9 9 INTEGER matrix z{{  \ cumulative record of galaxy

9 FLOAT array d{        \ damage array

variable b3    \ number of starbases in quadrant
variable b4    \ starbase coordinate in sector
variable b5    \   "  "
variable b9    \ number of starbases
variable d0    \ docked flag
variable d1    \ damage flag
variable e     \ current energy
variable e0    \ starting energy
variable h     \ phaser hit energy
variable h8
variable k3    \ number of Klingons in quadrant
variable k7    \ number of Klingons at start
variable k9    \ number of Klingons remaining
variable n     \ number of sectors to travel
variable p     \ number of photon torpedos remaining
variable p0    \ photon torpedo capacity
variable q1    \ quadrant coordinat of Enterprise
variable q2    \   "         "
variable r1
variable r2
variable s     \ current shield value
variable s1    \ current sector coordinate of Enterprise
variable s2    \   "         "
variable s3    \ number of stars in quadrant
variable s9    \ Klingon power
variable t0    \ starting stardate
variable t9    \ end time

fvariable c1
fvariable t   \ current stardate
fvariable w1  \ warp factor
fvariable x
fvariable y

   8  $var  X$
  64  $var  O1$
  64  $var  C$        \ condition string
 256  $var  Q$        \ display of quadrant

\ String constants

s"  * "  $const  STAR$
s" <*>"  $const  ENTERPRISE$
s" +K+"  $const  KLINGON$
s" >!<"  $const  STARBASE$
s"    "  $const  EMPTY$

s" NAVSRSLRSPHATORSHEDAMCOMXXXHEL" $const COMMANDS$


: fnr() ( n1 -- n2 | return a random integer between n1 and n1*8)
    rnd() 7.98e f* 1.01e f+ ftrunc>s ;

: RandomLocation ( -- s1|q1 s2|q2 | return a random sector or quadrant location)
    1 fnr() 1 fnr() ;

: Location>Index ( s1 s2 -- u | return display string index for given location)
    1- 3 * swap 1- 24 * + 1+ ;

\ convert angle in degrees to direction [1,9)
: Angle>Dir ( fangle -- fdir ) 
    fdup f0< IF 360e f+ THEN 45e f/ 1e f+ ;

\ convert direction [1,9) to angle in degrees
: Dir>Angle ( fdir -- fangle )
    1e f- 45e f* ;
    
\ Distance and direction between two pairs of sector coordinates:
\
\   z1,z2 are the sector coords of the first point.
\   z3,z4 are  "                    "  second point.
\
: Distance ( z1 z2 z3 z4 -- fdistance )
    rot - dup * >r - dup * r> + s>f fsqrt ;

\ Direction is a real number in the interval [1,9), with
\ 1 corresponding to 0 degrees from horizontal and proceeding
\ counter-clockwise. The direction is from the first point
\ to the second point.
: Direction ( z1 z2 z3 z4 -- fdirection )
    rot 2>r - 2r> -                        \ -- (z1-z3) (z4-z2)
    >r s>f r> s>f fatan2  rad>deg  Angle>Dir ;    
    
: DirectionCalc  ( z1 z2 z3 z4 -- )
    2over 2over Direction cr ." DIRECTION = " f. 2 spaces     
    Distance ." DISTANCE = " f.  
;

: ShipKlingonDistance ( u -- f | distance between ship and u^th Klingon in quadrant)
    >r s1 @ s2 @ k{{ r@ 1 }} @ k{{ r> 2 }} @ Distance ;


0 constant END_NO_WIN
1 constant END_WON_GAME
2 constant END_SHIP_DESTROYED
3 constant END_SHIP_STRANDED

false value GameEnded?
false value PlayAgain?

: EndOfGame ( n -- )
    true  to GameEnded?
    false to PlayAgain?
    CASE
	END_WON_GAME OF
	    cr ." CONGRATULATIONS, CAPTAIN! THE LAST KLINGON BATTLE CRUISER"
	    cr ." MENACING THE FEDERATION HAS BEEN DESTROYED."
	    cr
	    cr ." YOUR EFFICIENCY RATING IS "
	    k7 @ s>f t f@ t0 @ s>f f- f/ fdup f* 1000e f* ftrunc>s . 
	ENDOF

	END_SHIP_DESTROYED OF
	    cr
	    ." THE ENTERPRISE HAS BEEN DESTROYED. THE FEDERATION WILL BE CONQUERED."
	ENDOF

	END_SHIP_STRANDED OF
	    cr ." ** FATAL ERROR **  YOU HAVE JUST STRANDED YOUR SHIP IN" 
	    cr ." SPACE!" 
	    cr ."  YOU HAVE INSUFFICIENT MANEUVERING ENERGY, AND SHIELD" 
	    cr ."  CONTROL IS PRESENTLY INCAPABLE OF CROSS-CIRCUITING" 
	    cr ."  TO ENGINE ROOM!!" cr
	ENDOF

	END_NO_WIN OF
	ENDOF
    ENDCASE

    k9 @ IF
	cr ." IT IS STARDATE " t f@ f.
	cr ." THERE WERE " k9 ? ." KLINGON BATTLE CRUISERS LEFT AT"
	cr ." THE END OF YOUR MISSION."
    THEN
    
    b9 @ IF
	cr cr
	cr ." THE FEDERATION IS IN NEED OF A NEW STARSHIP COMMANDER"
	cr ." FOR A SIMILAR MISSION -- IF THERE IS A VOLUNTEER,"
	cr ." LET HIM STEP FORWARD AND ENTER 'AYE' "
	$input $ucase s" AYE" compare 0= to PlayAgain?
    THEN
;


: Initialize ( -- )
    
    20 rnd() 20e f+ ftrunc 100e f* t f!	
    t f@ ftrunc>s t0 !
    10 rnd() ftrunc>s 25 + t9 !

    false to GameEnded?
    
\  Initialize Enterprise's Position and State

    RandomLocation q1 ! q2 !     \ quadrant
    RandomLocation s1 ! s2 !     \ sector

    false d0 !
    3000 dup e ! e0 !
    10   dup p ! p0 !
    0 s !
    
    9 0 DO 0e d{ I } f! LOOP
    
\  Set up what exists in galaxy
\
\  k3 = Number of Klingons in quadrant
\  b3 = Number of Starbases in quadrant
\  s3 = Number of Stars in quadrant

    0 b9 !  0 k9 !  200 s9 !
    
    9 1 DO
	9 1 DO

	    0 z{{ J I }} !
	    100 rnd() ftrunc>s r1 !
	    
	    r1 @ 98 > IF  3 
	    ELSE  r1 @ 95 > IF  2 
		ELSE  r1 @ 80 > IF 1 
		    ELSE 0 THEN
		THEN
	    THEN 
	    dup k3 ! k9 +!
	    
	    4 % chance IF  1  ELSE  0  THEN
	    dup b3 ! b9 +!

	    k3 @ 100 * b3 @ 10 * + 1 fnr() +  g{{ J I }} !
	LOOP
    LOOP

    k9 @ t9 @ > IF k9 @ 1+ t9 ! THEN

    b9 @ 0= IF
	g{{ q1 @ q2 @ }} @ 200 < IF
	    g{{ q1 @ q2 @ }} @ 100 + g{{ q1 @ q2 @ }} !
	    1 k9 +!
	THEN

	1 b9 !
	g{{ q1 @ q2 @ }} @ 10 + g{{ q1 @ q2 @ }} !
	RandomLocation q1 ! q2 !
    THEN

    k9 @ k7 !
    
    page
    ." YOUR ORDERS ARE AS FOLLOWS:" cr
    cr
    cr ."     DESTROY THE " k9 ? ." KLINGON WARSHIPS WHICH HAVE INVADED" 
    cr ."     THE GALAXY BEFORE THEY CAN ATTACK FEDERATION HEADQUARTERS"
    cr ."     ON STARDATE " t0 @ t9 @ + .
    cr
    cr ."     THIS GIVES YOU " t9 ? ." DAYS."
    
    b9 @ 1 > IF  s" S"  s" ARE"  ELSE  s" "   s" IS "  THEN
    cr
    cr ."     THERE " type BL emit b9 ? ." STARBASE" type
    ."  IN THE GALAXY FOR"
    cr ."     RESUPPLYING YOUR SHIP."
    cr
    cr ." HIT ANY KEY WHEN READY TO ACCEPT COMMAND."

    key drop page
;



: QuadrantName ( q1 q2 flag -- a u | flag=true to get region name only)
    >r 2dup
    4 <= IF
	CASE
	    1 of s" ANTARES" endof
	    2 of s" RIGEL" endof
	    3 of s" PROCYON" endof
	    4 of s" VEGA" endof
	    5 of s" CANOPUS" endof
	    6 of s" ALTAIR" endof
	    7 of s" SAGITTARIUS" endof
	    8 of s" POLLUX" endof
	    s" UNKNOWN" rot
	ENDCASE
    ELSE
	CASE
	    1 of s" SIRIUS" endof
	    2 of s" DENEB" endof
	    3 of s" CAPELLA" endof
	    4 of s" BETELGUESE" endof
	    5 of s" ALDEBARAN" endof
	    6 of s" REGULUS" endof
	    7 of s" ARCTURUS" endof
	    8 of s" SPICA" endof
	    s" UNKNOWN" rot
	ENDCASE
    THEN
    
    \ -- q1 q2 a u
    
    r> invert IF
	2>r nip ( 4 mod 1+) dup 4 > IF 4 - THEN
	CASE
	    1 of s"  I" endof
	    2 of s"  II" endof
	    3 of s"  III" endof
	    4 of s"  IV" endof
	    s" " rot
	ENDCASE
	2r> 2swap $cat 
    ELSE
	2swap 2drop
    THEN ;


\  Print cumulative galaxy record or galaxy name map
\  depending on flag h8
: PrintGalaxy  ( -- )
    cr
    ."     1      2      3      4      5      6      7      8"
    s"   _____  _____  _____  _____  _____  _____  _____  _____" O1$ $copy
    cr O1$ type cr
    9 1 DO  
	I .

        h8 @ 0= IF
	    I 1 true QuadrantName  11 over 2/ - spaces type     
            I 5 true QuadrantName  24 over 2/ - spaces type 
	ELSE
            9 1 DO
		space
		z{{ J I }} @ 0= IF
		    ." ***"
		ELSE
		    z{{ J I }} @ 1000 + u>$ 3 $right type 
		THEN
		3 spaces
	    LOOP
	THEN

	cr
        O1$ type cr
    LOOP
    cr
;


: IsAt?  ( s1 s2 a u -- flag | string comparison in quadrant array)
    2>r Location>Index Q$ rot 3 $mid 2r> compare 0= ;

: IsEmpty? ( s1 s2 -- flag | is sector location empty?)
    EMPTY$ IsAt? ;
    
: EmptyLocation  ( -- s1 s2 | Find random place in quadrant which is empty)
    BEGIN
	RandomLocation 2dup IsEmpty? invert
    WHILE 2drop
    REPEAT
;

variable s8
: PlaceAt ( s1 s2 a u -- | Insert in string array for quadrant)
    2>r Location>Index s8 !
    r@ 3 <> ABORT" ERROR: Incorrect Length"
    s8 @ 1 = IF
	2r> Q$ 189 $right  
    ELSE s8 @ 190 = IF
	Q$ 189 $left 2r> 
	ELSE
	    Q$ s8 @ 1- $left 2r> $cat
	    Q$ 190 s8 @ - $right
	THEN
    THEN
    $cat Q$ $copy    
;

fvariable d4
: EnterNewQuadrant  ( -- | here any time new quadrant entered)

    \ Clear number of Klingons, starbases, stars, in quadrant 
    0 k3 !
    0 b3 !
    0 s3 !
    192 Q$ $space     \ clear the quadrant display
    
    ran0 0.5e f* d4 f!
    g{{ q1 @ q2 @ }} @  z{{ q1 @ q2 @ }} !

    q1 @ 1 9 within  q2 @ 1 9 within and IF
	q1 @ q2 @ false QuadrantName       
	t f@ t0 @ s>f f= IF
	    cr ." YOUR MISSION BEGINS WITH YOUR STARSHIP LOCATED" 
            cr ." IN THE GALACTIC QUADRANT, '" type ." '."
	ELSE
	    cr ." NOW ENTERING " type ."  QUADRANT . . ." 
	THEN
        

	g{{ q1 @ q2 @ }} @ s>f 0.01e f* ftrunc>s k3 !
	g{{ q1 @ q2 @ }} @ s>f 0.1e f* ftrunc>s k3 @ 10 * - b3 !
	g{{ q1 @ q2 @ }} @ k3 @ 100 * - b3 @ 10 * - s3 !

        k3 @ IF
            cr ." COMBAT AREA    CONDITION RED"
            s @ 200 <= IF
		cr ."     SHIELDS DANGEROUSLY LOW"
            THEN
	THEN

        4 0 DO 4 0 DO 0 k{{ J I }} ! LOOP LOOP  
    THEN


\ Position Enterprise in quadrant, then place Klingons, Starbases,
\   and Stars elsewhere.

    s1 @ s2 @ ENTERPRISE$ PlaceAt

    k3 @ 1+ 1 ?DO
	EmptyLocation 2dup KLINGON$ PlaceAt
        k{{ I 2 }} !  k{{ I 1 }} !
        s9 @ s>f I rnd() 0.5e f+ f* fround>s k{{ I 3 }} !  
    LOOP

    b3 @ IF
	EmptyLocation 2dup STARBASE$ PlaceAt
	b5 ! b4 !
    THEN

    s3 @ 0 ?DO  EmptyLocation STAR$ PlaceAt  LOOP
;


: DeviceName  ( n -- a u | return name associated with device number)
    CASE
	1  OF  s" WARP ENGINES"          ENDOF
        2  OF  s" SHORT RANGE SENSORS"   ENDOF
        3  OF  s" LONG RANGE SENSORS"    ENDOF
        4  OF  s" PHASER CONTROL"        ENDOF
        5  OF  s" PHOTON TUBES"          ENDOF
        6  OF  s" DAMAGE CONTROL"        ENDOF
        7  OF  s" SHIELD CONTROL"        ENDOF
        8  OF  s" LIBRARY COMPUTER"      ENDOF
               s" UNKNOWN DEVICE"  rot
    ENDCASE
;


: KlingonsShoot ( -- )

    k3 @ 0 <= IF EXIT THEN 
    d0 @ IF
	cr ." STARBASE SHIELDS PROTECT THE ENTERPRISE" cr
        EXIT
    THEN

    4 1 DO
	k{{ I 3 }} @ 0> IF
	    k{{ I 3 }} @ s>f I ShipKlingonDistance f/ ran0 2e f+ f* ftrunc>s h ! 
            h @ negate s +!
	    k{{ I 3 }} @ s>f 3e ran0 f+ f/ ftrunc>s
	    1 max          \ add this to prevent Klingon ship from becoming ghost -- km
	    k{{ I 3 }} ! 
            cr h ?  ." UNIT HIT ON ENTERPRISE FROM SECTOR "
	    k{{ I 1 }} ?  ." ,"  k{{ I 2 }} ?
            s @ 0 <= IF  END_SHIP_DESTROYED EndOfGame UNLOOP EXIT  THEN                        
            cr ."      <SHIELDS DOWN TO "  s ? ." UNITS>"
            H @ 20 >= IF
		60 % chance
		h @ s>f s @ s>f f/ 0.02e f> and IF
		    1 fnr() r1 !
		    d{ r1 @ } f@ h @ s>f s @ s>f f/ f- ran0 0.5e f* f-
		    d{ r1 @ } f!
		    cr ." DAMAGE CONTROL REPORTS, '" 		    
		    r1 @ DeviceName type ."  DAMAGED BY THE HIT'" 
		THEN
	    THEN
	THEN
    LOOP
    cr
;

: NoEnemyShips  ( -- )         
    cr ." SCIENCE OFFICER SPOCK REPORTS, 'SENSORS SHOW NO ENEMY SHIPS" cr
       ."                                 IN THIS QUADRANT'" cr
;

: NoStarbases  ( -- )
    cr ." MR. SPOCK REPORTS, 'SENSORS SHOW NO STARBASES IN THIS "
    cr ." QUADRANT.'" cr
;


: TacticalDisplay ( -- )
    cr ." =============================" cr
    9 1 DO
	Q$ I 1- 24 * 1+ 24 $mid type
	I CASE
	    1 OF ."      STARDATE             " t f@ f. ENDOF
            2 OF ."      CONDITION            " C$ type ENDOF 
            3 OF ."      QUADRANT             " q1 ? ." ," q2 ?  ENDOF
            4 OF ."      SECTOR               " s1 ? ." ," s2 ?  ENDOF
            5 OF ."      PHOTON TORPEDOES     " p ?  ENDOF
            6 OF ."      TOTAL ENERGY         " e @ s @ + .  ENDOF
            7 OF ."      SHIELDS              " s ?  ENDOF
            8 OF ."      KLINGONS REMAINING   " k9 ? ENDOF
	ENDCASE
	cr
    LOOP
    ." ============================="
;

: NearStarbase? ( -- flag | scan adjacent sectors for starbase)
    false
    s1 @ 2 + s1 @ 1- DO     
	s2 @ 2 + s2 @ 1- DO
            J 1 9 within  I 1 9 within and IF
		J I STARBASE$ IsAt? or
	    THEN
	    dup IF LEAVE THEN
	LOOP
	dup IF LEAVE THEN
    LOOP ;

		
: DockAtStarbase ( -- )
    cr ." SHIELDS DROPPED FOR DOCKING"
    0 s !
    true d0 !
    s" DOCKED" C$ $copy
    e0 @ e !  p0 @ p !
;

    
: ShortRangeScan ( -- | Short range sensor scan )
    NearStarbase? IF  DockAtStarbase  THEN

    d0 @ invert IF
	k3 @ 0> IF  s" *RED*" 
	ELSE
	    e @ e0 @ 10 / < IF  s" YELLOW"  ELSE  s" GREEN"  THEN
	THEN
	C$ $copy
    THEN
    
    d{ 2 } f@ f0< IF  cr ." *** SHORT RANGE SENSORS ARE OUT ***" 
    ELSE  TacticalDisplay  THEN
;


4 INTEGER array n{
: LongRangeSensors  ( -- )
    d{ 3 } f@ f0< IF
	cr ." LONG RANGE SENSORS ARE INOPERABLE"
    ELSE
	cr ." LONG RANGE SCAN FOR QUADRANT " q1 ? ." ," q2 ?
        cr ." ------------" cr
        q1 @ 2 + q1 @ 1- DO 
            -1  n{ 1 } ! 
            -2  n{ 2 } !
            -3  n{ 3 } !
            q2 @ 2 + q2 @ 1- DO
		J 1 9 within  I 1 9 within and IF 
		    g{{ J I }} @  n{ I q2 @ - 2 + } ! 
		    g{{ J I }} @  z{{ J I }} ! 
		THEN
            LOOP
	    4 1 DO 
		n{ I } @ 0< IF
		    ." *** "
		ELSE
		    n{ I } @ 1000 + u>$ 3 $right type bl emit
		THEN
            LOOP
            cr
	LOOP
        ." ------------" cr
    THEN
;



variable h1
: FirePhasers  ( -- )
    
    d{ 4 } f@ f0< IF  cr ." PHASERS INOPERATIVE" EXIT  THEN
    k3 @ 0 <= IF  NoEnemyShips  EXIT  THEN

    d{ 8 } f@ f0< IF  cr ." COMPUTER FAILURE HAMPERS ACCURACY"  THEN
    cr ." PHASERS LOCKED ON TARGET"

    BEGIN
	cr ." ENERGY AVAILABLE = " E ? ." UNITS"
	cr ." NUMBER OF UNITS TO FIRE "  #in X !
	e @ X @ - 0 >=
    UNTIL
	
    X @ 0> IF
	X @ negate e +! 
	d{ 7 } f@ f0< IF  X @ s>f ran0 f* fround>s X ! THEN   
	X @ k3 @ / h1 !  \ distribute phaser energy among klingons present

        4 1 DO 
	    k{{ I 3 }} @ 0> IF
		h1 @ s>f  I ShipKlingonDistance f/ \ attenuate hit based on distance
		( ran0 2e f+ f*) ftrunc>s h !
		h @ k{{ I 3 }} @ 3 * 20 / <= IF    
		    cr ." SENSORS SHOW NO DAMAGE TO ENEMY AT "
		    k{{ I 1 }} ? ." ," k{{ I 2 }} ? 
		ELSE
		    h @ negate k{{ I 3 }} +!  
		    cr h ? ." UNIT HIT ON KLINGON AT SECTOR "
		    k{{ I 1 }} ? ." ," k{{ I 2 }} ?
		    k{{ I 3 }} @ 0 <= IF 
			cr ." *** KLINGON DESTROYED ***" 
			-1 k3 +! 
			-1 k9 +!
			k{{ I 1 }} @  k{{ I 2 }} @  EMPTY$  PlaceAt
			0 k{{ I 3 }} ! 
			g{{ q1 @ q2 @ }} @ 100 - g{{ q1 @ q2 @ }} ! 
			g{{ q1 @ q2 @ }} @  z{{ q1 @ q2 @ }} ! 
			k9 @ 0 <= IF  END_WON_GAME EndOfGame EXIT  THEN
		    ELSE
			cr ."   (SENSORS SHOW " k{{ I 3 }} ? ." UNITS REMAINING)"
		    THEN
		THEN
	    THEN
	LOOP
	KlingonsShoot
    THEN
;


\ Photon Torpedo code
fvariable x1
fvariable y1
variable x3
variable y3
: FirePhotonTorpedo ( -- )
    
    p @ 0 <= IF  cr ." ALL PHOTON TORPEDOES EXPENDED" EXIT  THEN
    d{ 5 } f@ f0< IF 	cr ." PHOTON TUBES NOT OPERATIONAL" EXIT  THEN

    cr ." PHOTON TORPEDO COURSE (1-9)" f#in c1 f!
    c1 f@ 9e f= IF 1e c1 f! THEN
    c1 f@ ftrunc>s 1 9 within invert IF
	cr ." ENSIGN CHEKOV REPORTS, 'INCORRECT COURSE DATA, SIR!'" 
	EXIT
    THEN

    -2 e +!
    -1 p +!
    
    c1 f@ Dir>Angle deg>rad fsincos x1 f! fnegate y1 f!
    s1 @ s>f  y f!  s2 @ s>f  x f!
    cr ." TORPEDO TRACK:"

    BEGIN
	x1 f@ x f@ f+ x f!
	y1 f@ y f@ f+ y f!  
	x f@ fround>s x3 !
	y f@ fround>s y3 !
	x3 @ 1 9 within  y3 @ 1 9 within and IF
	    cr ."             " y3 ? ." , " x3 ?
	ELSE
	    cr ." TORPEDO MISSED" 
	    KlingonsShoot 
	    EXIT 
	THEN
	y3 @ x3 @ IsEmpty? 0=
    UNTIL

    y3 @ x3 @  STAR$  IsAt? IF
	cr ." STAR AT " y3 ? ." ," x3 ? ." ABSORBED TORPEDO ENERGY." 
        KlingonsShoot 
        EXIT
    THEN

    y3 @ x3 @  STARBASE$  IsAt? IF
	cr ." *** STARBASE DESTROYED ***"
	y3 @ s1 @ - abs 2 < x3 @ s2 @ - abs 2 < and d0 @ and
	IF  END_SHIP_DESTROYED EndOfGame EXIT  THEN
	-1 b3 +! 
	-1 b9 +!
	b9 @ 0 <= IF
	    cr ." THAT DOES IT CAPTAIN!! YOU ARE HEREBY RELIEVED OF"
	    cr ." COMMAND AND SENTENCED TO 99 STARDATES AT HARD LABOR" 
	    cr ." ON CYGNUS 12!!"
	    END_NO_WIN EndOfGame EXIT
	THEN
	
	cr ." STARFLEET COMMAND REVIEWING YOUR RECORD TO CONSIDER" 
	cr ." COURT MARTIAL!" 
	
	false d0 !
    THEN
	
    y3 @ x3 @  KLINGON$  IsAt? IF
	cr ." *** KLINGON DESTROYED ***" 
        -1 k3 +!
        -1 k9 +!
	k9 @ 0 <= IF  END_WON_GAME EndOfGame EXIT THEN

        4 1 DO
	    k{{ I 1 }} @ k{{ I 2 }} @ y3 @ x3 @ d= IF
		0 k{{ I 3 }} !
	    THEN
	LOOP
    THEN

    y3 @ x3 @ EMPTY$ PlaceAt
    k3 @ 100 * b3 @ 10 * + s3 @ + g{{ q1 @ q2 @ }} !
    g{{ q1 @ q2 @ }} @  z{{ q1 @ q2 @ }} ! 

    k3 @ IF  KlingonsShoot  THEN
;


: ShieldControl  ( -- )
    d0 @ IF  cr ." STARBASE SHIELDS PROTECT THE ENTERPRISE" EXIT THEN
    d{ 7 } f@ f0< IF
	cr ." SHIELD CONTROL INOPERABLE" 
    ELSE
	cr ." ENERGY AVAILABLE = " e @ s @ + .
	cr ." NUMBER OF UNITS TO SHIELDS " #in X !
	X @ 0<  X @ s @ = or  IF
            cr ." <SHIELDS UNCHANGED>" 
	ELSE
	    X @ e @ s @ + > IF
		cr ." SHIELD CONTROL REPORTS, 'THIS IS NOT THE FEDERATION "
		." TREASURY.'"
		cr ." <SHIELDS UNCHANGED>" 
	    ELSE
		s @ X @ - e +! 
		X @ s !
		cr ." DEFLECTOR CONTROL ROOM REPORT:"
		cr ."  'SHIELDS NOW AT " S ? ." UNITS PER YOUR COMMAND.'" 
            THEN
	THEN
    THEN
;


\ Damage Control
fvariable d3
: DamageControl  ( -- )
    d{ 6 } f@ f0< IF
	cr ." DAMAGE CONTROL REPORT NOT AVAILABLE"
    ELSE
        cr ." DEVICE           STATE OF REPAIR" cr
        cr
        9 1 DO
          I DeviceName type 
	  5 spaces 9 emit d{ I } f@ f.
	  CR
	LOOP
    THEN
    
    d0 @ IF 
	0e d3 f!
	9 1 DO
	    I 1 d{ I } f@ f0< IF
		d3 f@ 0.1e f+ d3 f!
	    THEN
	LOOP
	    
	d3 f@ f0= IF EXIT THEN
	    
	d3 f@ d4 f@ f+ d3 F!
	d3 f@ 1e f>= IF 0.9e d3 f! THEN
	cr ." TECHNICIANS STANDING BY TO EFFECT REPAIRS TO YOUR SHIP"
	cr ." ESTIMATED TIME TO REPAIR: " 
	d3 f@ 100e f* ftrunc>s s>d <# # # [char] . hold # #> type
	." STARDATES" 
	cr ." WILL YOU AUTHORIZE THE REPAIR ORDER (Y/N) "
	key 95 and [char] Y = IF  
	    9 1 DO 
		d{ I } f@ f0< IF 0e d{ I } f! THEN 
	    LOOP
	    t f@ d3 f@ f+ 0.1e f+ t f!
	THEN
    THEN
;


: LibraryComputer  ( -- )
    
    d{ 8 } f@ f0< IF  cr ." COMPUTER DISABLED" EXIT  THEN

    BEGIN
	cr ." COMPUTER ACTIVE AND AWAITING COMMAND (0 TO 5, OR -1) "
	#in
	dup 0< IF drop cr EXIT THEN  

	CASE
	    
\ Cumulative Galactic Record
	    0 OF
		true h8 !
		cr ." COMPUTER RECORD OF GALAXY" 5 spaces
		." ( YOU ARE AT QUADRANT " q1 ? ." ," q2 ? ." )"
		cr PrintGalaxy
	    ENDOF

\ Status report
	    1 OF
		cr ."    STATUS REPORT:"
		k9 @ 1 > IF s" S" ELSE s" " THEN 
		cr ." KLINGON" type ."  LEFT: " k9 ?
		cr ." MISSION MUST BE COMPLETED IN "
		t0 @ t9 @ + s>f t f@ f- fround>s . ." STARDATES"

		b9 @ 1 < IF
		    cr ." YOUR STUPIDITY HAS LEFT YOU ON YOUR OWN IN" 
		    cr ."  THE GALAXY -- YOU HAVE NO STARBASES LEFT!"
		ELSE
		    b9 @ 1 > IF s" S" ELSE s" " THEN
		    cr ." THE FEDERATION IS MAINTAINING " b9 ? ." STARBASE" 
		    type ."  IN THE GALAXY"
		THEN
		DamageControl
	    ENDOF

\ Torpedo, base nav, D/D calculator
	    2 OF  
		k3 @ 0 <= IF  NoEnemyShips EXIT  THEN

		k3 @ 1 > IF s" S" ELSE s" " THEN
		cr ." FROM ENTERPRISE TO KLINGON BATTLE CRUISER" type
		4 1 DO
		    k{{ I 3 }} @ 0> IF
			s1 @  s2 @  k{{ I 1 }} @  k{{ I 2 }} @ 
			DirectionCalc
		    THEN
		LOOP
	    ENDOF

\ Starbase Nav Data
	    3 OF
		 b3 @ IF
		     cr ." FROM ENTERPRISE TO STARBASE:" CR
		     s1 @ s2 @ b4 @ b5 @ DirectionCalc
		 ELSE
		     NoStarbases
		 THEN
	      ENDOF

\ Direction/Distance Calculator
	      4 OF
		  cr ." DIRECTION/DISTANCE CALCULATOR:"
		  cr ." YOU ARE AT QUADRANT " q1 ? ." ," q2 ?
		  ."   SECTOR " s1 ? ." ," s2 ?
		  cr ." PLEASE ENTER INITIAL COORDINATES (S1, S2)"
		  cr ."   S1: " #in  ."   S2: " #in 
		  cr ." PLEASE ENTER FINAL COORDINATES   (S1, S2)"
		  cr ."   S1: " #in  ."   S2: " #in
		  DirectionCalc
	      ENDOF

\ Galaxy region name map
	      5 OF
		  cr ."                         THE GALAXY"
		  false h8 ! PrintGalaxy
	      ENDOF
	      
\ Invalid command
	      cr
	      cr ." FUNCTIONS AVAILABLE FROM LIBRARY COMPUTER:"
	      cr ."     0  =  CUMULATIVE GALACTIC RECORD" 
	      cr ."     1  =  STATUS REPORT" 
	      cr ."     2  =  PHOTON TORPEDO DATA" 
	      cr ."     3  =  STARBASE NAV DATA" 
	      cr ."     4  =  DIRECTION/DISTANCE CALCULATOR" 
	      cr ."     5  =  GALAXY 'REGION NAME' MAP" 
	      cr
	  ENDCASE
      AGAIN
;


    
\ Klingons move/fire on moving starship . . .
fvariable d6
: KlingonsMove ( -- )
    k3 @ 1+ 1 ?DO
	k{{ I 3 }} @ IF 
            k{{ I 1 }} @  k{{ I 2 }} @  EMPTY$ PlaceAt
	    EmptyLocation 2dup KLINGON$ PlaceAt
	    k{{ I 2 }} !  k{{ I 1 }} ! 
	THEN
    LOOP
;

: RepairDamage ( -- )
    0 d1 ! 
    w1 f@ d6 f!
    w1 f@ 1e f>= IF 1e d6 f! THEN

    9 1 DO
        d{ I } f@ f0< IF 
            d6 f@ d{ I } f@ f+ d{ I } f!
            d{ I } f@ -0.1e f> d{ I } f@ f0< and IF
		-0.1e d{ I } f!
            ELSE
		d{ I } f@ 0e f>= IF
		    d1 @ 1 <> IF 1 d1 ! THEN 
		    cr ." DAMAGE CONTROL REPORT:  "
		    9 emit  I r1 !  I DeviceName type ."  REPAIR COMPLETED."
		THEN
	    THEN
	THEN
    LOOP
    
    20 % chance IF
	1 fnr() r1 !
	cr ." DAMAGE CONTROL REPORT:  "
	r1 @ DeviceName type
	
	60 % chance IF
	    ran0 5e f* 1e f+ fnegate   
             ."  DAMAGED" 
	ELSE
            ran0 3e f* 1e f+  
            ."  STATE OF REPAIR IMPROVED" 
	THEN
	d{ r1 @ } f@ f+ d{ r1 @ } f!
    THEN
;


: ManeuverEnergy ( -- | reroute shields to complete maneuver if needed)
    n @ 10 + negate e +!
    e @ 0< IF
	cr ." SHIELD CONTROL SUPPLIES ENERGY TO COMPLETE THE MANEUVER."
        e @ s +! 
        0 e !
        s @ 0 max s ! 
    THEN    
;

\ Adjust quadrant and sector coordinates if we are on boundary between quadrants.
: AdjustAtBoundary ( -- )
    s1 @ 0= IF  -1 q1 +!  8 s1 !  THEN
    s2 @ 0= IF 	-1 q2 +!  8 s2 !  THEN
;


: OutsideGalaxy? ( -- flag | are we outside the galaxy?)
    q1 @ 1 9 within invert dup IF q1 @ 1 max 8 min dup q1 ! s1 ! THEN
    q2 @ 1 9 within invert dup IF q2 @ 1 max 8 min dup q2 ! s2 ! THEN    
    or
;


variable q4
variable q5
: MoveShip ( fdirection -- | number of sectors to move is in "n")

    Dir>Angle deg>rad fsincos x1 f! fnegate y1 f!
    s1 @ s>f  y f!  s2 @ s>f  x f!
   
    s1 @ s2 @ EMPTY$ PlaceAt
    
    q1 @ q4 !  q2 @ q5 !
    
    n @ 0 ?DO
	x1 f@  x f@ f+  x f!  
	y1 f@  y f@ f+  y f!
	y f@ fround>s s1 !
	x f@ fround>s s2 !
	s1 @ 1 9 within  s2 @ 1 9 within and IF
	    s1 @ s2 @ IsEmpty? invert IF  \ anything blocking our path?
		y f@ y1 f@ f- fround>s s1 !
		x f@ x1 f@ f- fround>s s2 !
		cr ." WARP ENGINES SHUT DOWN AT "
		." SECTOR " s1 ? ." ," s2 ? ." DUE TO BAD NAVIGATION"
		I s>f t f@ f+ t f!
		LEAVE
	    THEN
	ELSE
	    \ We may be in a new quadrant; compute new quadrant and sector coords.
	    q1 @ 8 * s>f y1 f@ n @ s>f f* f+ y f@ f+ y f!
	    q2 @ 8 * s>f x1 f@ n @ s>f f* f+ x f@ f+ x f! 
	    y f@ 8e f/ ftrunc>s q1 !
	    x f@ 8e f/ ftrunc>s q2 !
	    y f@ q1 @ 8 * s>f f- ftrunc>s s1 !
	    x f@ q2 @ 8 * s>f f- ftrunc>s s2 !

	    AdjustAtBoundary

	    w1 f@ 1e fmin t f@ f+ t f!
 
	    OutsideGalaxy? IF
		cr ." LT. UHURA REPORTS MESSAGE FROM STARFLEET COMMAND:"
		cr ."   'PERMISSION TO ATTEMPT CROSSING OF GALACTIC PERIMETER"
		cr ."   IS HEREBY *DENIED*. SHUT DOWN ENGINES.'"
		cr ." CHIEF ENGINEER SCOTT REPORTS, 'WARP ENGINES SHUT DOWN"
		cr ."  AT SECTOR " s1 ? ." ," s2 ? ." OF QUADRANT " q1 ? ." ," q2 ?
	    THEN
	    q1 @ q2 @ q4 @ q5 @ d= invert IF  EnterNewQuadrant  THEN
	    LEAVE
	THEN
    LOOP
 
    s1 @ s2 @ ENTERPRISE$ PlaceAt
    ManeuverEnergy 

;
    

: CourseControl  ( -- )
    cr ." COURSE (1-9) " f#in c1 f!
    c1 f@ 9e f= IF 1e c1 f! THEN
    c1 f@ ftrunc>s 1 9 within IF
	s" 8" X$ $copy
        d{ 1 } f@ f0< IF  s" 0.2" X$ $copy THEN
    ELSE
	cr ."   LT. SULU REPORTS, 'INCORRECT COURSE DATA, SIR!'"
        EXIT
    THEN
    
    cr ." WARP FACTOR (0-" X$ type ." ): "
    f#in w1 f!
    w1 f@ f0= IF EXIT THEN
    
    d{ 1 } f@ f0< w1 f@ 0.2e f> and IF 
	cr ." WARP ENGINES ARE DAMAGED. MAXIMUM SPEED = WARP 0.2"
        EXIT
    THEN
    
    w1 f@ 0e f> w1 f@ 8e f<= and IF
        w1 f@ 8e f* fround>s n !  \ number of sectors to travel
        e @ n @ - 0< IF 
	    cr ." ENGINEERING REPORTS, 'INSUFFICIENT ENERGY AVAILABLE"
	    cr ."                      FOR MANEUVERING AT WARP " w1 f@ f. ." !'"
	    s @ n @ e @ - >= d{ 7 } f@ 0e f> and IF
		cr ." DEFLECTOR CONTROL ROOM ACKNOWLEDGES" s ? ." UNITS OF ENERGY"
		cr ."   PRESENTLY DEPLOYED TO SHIELDS."
	    THEN
	    EXIT
	THEN

	d0 @ n @ 0> and IF   \ undock if we are docked and about to move!
	    cr ."   LT. SULU REPORTS, 'UNDOCKING FROM STARBASE, SIR!'"
	    false d0 !
	THEN
	
	KlingonsMove
	KlingonsShoot
	RepairDamage
	c1 f@ MoveShip
	ShortRangeScan
	
	t f@ t0 @ t9 @ + s>f f> IF  END_NO_WIN EndOfGame EXIT THEN
    ELSE
	w1 f@ 0e f<> IF
	    cr ."   CHIEF ENGINEER SCOTT REPORTS, 'THE ENGINES WON'T TAKE "
	    ." WARP " w1 f@ f. ." '!"
	THEN
    THEN
;


: CheckEnergy ( -- ) 
    s @ e @ + 10 <=               \ Total energy <= 10 ?
    e @ 10 <=  d{ 7 } f@ f0< and  \ Energy <= 10 and shields damaged?
    or
    IF END_SHIP_STRANDED EndOfGame THEN
;


: CommandInput  ( -- )
    BEGIN
	COMMANDS$
	cr ." COMMAND " $input $ucase 3 $left
	search IF
	    drop COMMANDS$ drop - 3 / 1+
	    CASE
		 1  OF  CourseControl        ENDOF
		 2  OF  ShortRangeScan       ENDOF
		 3  OF  LongRangeSensors     ENDOF
		 4  OF  FirePhasers          ENDOF
		 5  OF  FirePhotonTorpedo    ENDOF
		 6  OF  ShieldControl        ENDOF
		 7  OF  DamageControl        ENDOF
		 8  OF  LibraryComputer      ENDOF
		 9  OF  END_NO_WIN EndOfGame ENDOF
		10  OF  help                 ENDOF
	    ENDCASE
	ELSE
	    2drop
	    CR ." ENTER ONE OF THE FOLLOWING:"
	    CR ."  NAV   (TO SET COURSE)"
	    CR ."  SRS   (FOR SHORT RANGE SENSOR SCAN)"
	    CR ."  LRS   (FOR LONG RANGE SENSOR SCAN)"
	    CR ."  PHA   (TO FIRE PHASERS)"
	    CR ."  TOR   (TO FIRE PHOTON TORPEDOES)"
	    CR ."  SHE   (TO RAISE OR LOWER SHIELDS)"
	    CR ."  DAM   (FOR DAMAGE CONTROL REPORTS)"
	    CR ."  COM   (TO CALL ON LIBRARY COMPUTER)"
	    CR ."  XXX   (TO RESIGN YOUR COMMAND)"
	    CR ."  HEL   (FOR HELP ON COMMANDS)"
	    CR
	THEN
	GameEnded? 0= IF  CheckEnergy  THEN
	GameEnded?
     UNTIL
;

: NewGame ( -- )
    BEGIN
	Initialize
	EnterNewQuadrant
	ShortRangeScan
	CommandInput
	PlayAgain? false =
    UNTIL
;


cr cr
cr .(                           ------*------, )
cr .(          ,-------------   `---  ------'  )
cr .(           `-------- --'      / /         )
cr .(                  --\\-------/ /--,       )
cr .(                  '--------------'        )
cr .(                                          )
cr .(     The USS Enterprise --- NCC - 1701    )
cr .(                                          )
cr .( Type:                                    )
cr .(       'NewGame' to begin a game          )
cr .(       'help'    for instructions         )
cr



help_buf doc(
	
1. When you see COMMAND? printed, enter one of the legal commands
   (NAV, SRS, LRS, PHA, TOR, SHE, DAM, COM, XXX, or HEL).

2. If you should type in an illegal command, you'll get a short list of
   the legal commands printed out.

3. Some commands require you to enter data (for example, the 'NAV' command
   comes back with 'COURSE (1-9) ?'.) If you type in illegal data (like
   negative numbers), that command will be aborted.

  The galaxy is divided into an 8 X 8 quadrant grid, and each quadrant
is further divided into an 8 x 8 sector grid.

  You will be assigned a starting point somewhere in the galaxy to begin
a tour of duty as commander of the starship Enterprise; your mission:
to seek out and destroy the fleet of Klingon warships which are menacing
the United Federation of Planets.

  You have the following commands available to you as Captain of the Starship
Enterprise:



\NAV\ Command = Warp Engine Control --

  Course is in a circular numerical vector            4  3  2
  arrangement as shown. Integer and real               . . .
  values may be used. (Thus course 1.5 is               ...
  half-way between 1 and 2.                         5 ---*--- 1
                                                        ...
  Values may approach 9.0, which itself is             . . .
  equivalent to 1.0.                                  6  7  8

  One warp factor is the size of one quadrant.        COURSE
  Therefore, to get from quadrant 6,5 to 5,5
  you would use course 3, warp factor 1.

\SRS\ Command = Short Range Sensor Scan

  Shows you a scan of your present quadrant.
	  
  Symbology on your sensor screen is as follows:
    <*> = Your starship's position
    +K+ = Klingon battlecruiser
    >!< = Federation starbase (Refuel/Repair/Re-Arm here!)
     *  = Star
  A condensed 'Status Report' will also be presented.
\LRS\ Command = Long Range Sensor Scan

  Shows conditions in space for one quadrant on each side of the Enterprise
  (which is in the middle of the scan). The scan is coded in the form \###\
  where the units digit is the number of stars, the tens digit is the number
  of starbases, and the hundreds digit is the number of Klingons.

  Example - 207 = 2 Klingons, No Starbases, & 7 stars.

\PHA\ Command = Phaser Control.

  Allows you to destroy the Klingon Battle Cruisers by zapping them with
  suitably large units of energy to deplete their shield power. (Remember,
  Klingons have phasers, too!)

\TOR\ Command = Photon Torpedo Control

  Torpedo course is the same  as used in warp engine control. If you hit
  the Klingon vessel, he is destroyed and cannot fire back at you. If you
  miss, you are subject to the phaser fire of all other Klingons in the
  quadrant.

  The Library-Computer (\COM\ command) has an option to compute torpedo
  trajectory for you (option 2).
\SHE\ Command = Shield Control

  Defines the number of energy units to be assigned to the shields. Energy
  is taken from total ship's energy. Note that the status display total
  energy includes shield energy.

\DAM\ Command = Damage Control report
      
  Gives the state of repair of all devices. Where a negative 'State of Repair'
  shows that the device is temporarily damaged.

\COM\ Command = Library-Computer

  The Library-Computer contains six options:  

  Option 0 = Cumulative Galactic Record
    This option shows computer memory of the results of all previous
    short and long range sensor scans.

  Option 1 = Status Report
    This option shows the number of Klingons, stardates, and starbases
    remaining in the game.

	
  Option 2 = Photon Torpedo Data	
    Gives directions and distance from Enterprise to all Klingons
    in your quadrant.
	
  Option 3 = Starbase Nav Data
    This option gives direction and distance to any starbase in your
    quadrant.
	
  Option 4 = Direction/Distance Calculator
    This option allows you to enter coordinates for direction/distance
    calculations.
	
  Option 5 = Galactic /Region Name/ Map
    This option prints the names of the sixteen major galactic regions
    referred to in the game.
	
  Option < 0 = Exit the library computer.
)doc
to HELP_SIZE
	
	
