\ zwofz.4th
\
\ Provides:
\   ZWOFZ
\
\ File dependencies:
\   fsl-util.x    auxiliary FSL utilities file
\   complex.x     FSL #60 complex arithmetic module
\   ttester-xf.x/ttester.x  test harness (needed only for automated tests)
\
\ Environmental dependencies:
\   - This version should work with both integrated and separate fp stacks.
\   - Forth-94 floating point and floating point extension words.
\
\ Description:
\
\      Algorithm 680, Collected Algorithms from ACM.
\      This work published in Transactions on Mathematical Software,
\      vol. 16, no. 1, pp. 47.
\
\  Given a complex number z, the word zwofz computes the value of the 
\  complex Faddeeva-function,
\
\ 	w(z) = exp(-z**2)*erfc(-i*z)
\
\  where erfc is the complex complementary error function and i
\  means sqrt(-1).
\
\  The accuracy of the algorithm for z in the 1st and 2nd quadrant
\  is 14 significant digits; in the 3rd and 4th it is 13 significant
\  digits outside a circular region with radius 0.126 around a zero
\  of the function.
\
\  The code contains a few compiler-dependent parameters :
\     RMAXREAL = the maximum value of RMAXREAL equals the root of
\                RMAX = the largest number which can still be 
\                implemented on the computer in double precision
\                floating-point arithmetic
\     RMAXEXP  = ln(RMAX) - ln(2)
\     RMAXGONI = the largest possible argument of a double precision
\                goniometric function (FCOS, FSIN, ...)
\  The reason why these parameters are needed as they are defined will
\  be explained in the code by means of comments
\
\  The routine is not underflow-protected but any variable can be
\  put to 0 upon underflow;
\
\  Reference - GPM Poppe, CMJ Wijers; More Efficient Computation of
\  the Complex Error-Function, ACM Trans. Math. Software.
\
\  Ported to Forth-94 by Krishna Myneni, krishna.myneni@ccreweb.org
\  31 July 2009
\
\  Revisions:
\    2009-08-04  km  revised comments, include link to comprehensive
\                    table of reference values. 
\    2010-12-11  km  extensive revision using the FSL complex library,
\                    FSL #60, making use of factored words, and use of
\                    Forth coding style; revised automated tests to use 
\                    ttester-xf.
\    2010-12-15  km  modified to support both separate and integrated 
\                    data/fp stack systems. Replaced use of F>S with 
\                    FTRUNC>S. Added conditional code to select between
\                    ttester-xf and ttester loading and setup.
\    2011-09-16  km  use Neal Bridges' anonymous modules.
\    2012-02-19  km  use KM/DNW's modules library.
\
\  Additional Notes:
\
\    1. The overflow checks in the original code are not compiled
\       by default, since the checks assume a fixed machine precision 
\       (double precision). The checks may be enabled by changing the 
\       constant OVFLOW_PROTECT to true.

BEGIN-MODULE

BASE @
DECIMAL

Public:

[UNDEFINED] fsquare  [IF] : fsquare postpone fdup postpone f* ; immediate [THEN]
[UNDEFINED] ftrunc>s [IF] : ftrunc>s  f>d d>s ;     [THEN]
[UNDEFINED] fround>s [IF] : fround>s  fround ftrunc>s ;  [THEN]

Private:
false constant OVFLOW_PROTECT

1.12837916709551257388E0 fconstant FACTOR     \ 2/sqrt(pi)
0.5E154                  fconstant RMAXREAL
708.503061461606E0       fconstant RMAXEXP
3.53711887601422E15      fconstant RMAXGONI

0 value N2
Public:

\ Evaluate N terms of power series approximation to
\   the Faddeeva function; za = |x| + i*|y|
: zfadd_pow_series ( za N -- zw ) 
	>r  zdup z^2            \ F: za zq
        r@ 2* 1+ to N2
        1.0e N2 s>f f/  0.0e0     \ F: za zq zsum
        1 r> DO                   \ loop N -> 1
	  zover z* I s>f  z/f
	  N2 -2 + dup to N2 s>f 1/f x+ 
        -1 +LOOP                  \ F: za zq zsum
        znip
        z* FACTOR z*f 1e fswap f- fswap  \ F: zw
;

Private:

variable kapn
fvariable h1
fvariable h2
fvariable qlambda
zvariable r
zvariable s

0 value bflag
Public:
\ Continued fraction evaluation of the Faddeeva function; 
\ nu is number of terms; za = |x| + i*|y|
: zfadd_cfracs ( za nu -- zw ) 
        0.0e  0.0e  zdup r  z!  s  z!
	
        h1 f@ fdup 2e f* h2 f!  0.0e f> dup to bflag
        IF  h2 f@  kapn @ s>f f**  qlambda f!  THEN

        0 swap DO  \ loop nu -> 0
          zdup h1 f@ y+ 
	  r z@ I 1+ s>f z*f  i* z+  fswap ( conjg i*)
          zdup |z|^2  0.5e fswap f/ z*f r z!

          bflag   I kapn @ <=   and IF
	    s z@ qlambda f@  x+  r z@ z*  s z!
            qlambda f@ h2 f@ f/  qlambda f!
          THEN
        -1 +LOOP

        h1 f@ f0=  IF  r  ELSE  s  THEN z@ FACTOR z*f  \ F: -- za zuv
        zswap f0=  IF  fsquare fnegate fexp fswap frot THEN
        fdrop
;

Private:

fvariable qrho
zvariable zi
zvariable za
zvariable zp
zvariable z2

Public:

: zwofz ( z  -- zw flag )  \ Faddeeva function            
      zdup zi z! 
      fabs fswap fabs fswap 
      zdup za z!

[ OVFLOW_PROTECT ] [IF]               \ Protect against |za|^2 overflow
      zdup RMAXREAL f> >R  RMAXREAL f> R> or IF  
        zdrop 0e 0e true exit
      THEN
[THEN]

      zdup z^2 

[ OVFLOW_PROTECT ] [IF]      \  Protect exp(-z**2) against overflow
          zdup fabs RMAXGONI f> >R  fabs RMAXEXP f> R> or IF
		zdrop zdrop 0e 0e true EXIT
	  THEN
[THEN]

      znegate zexp z2 z!
      4.4e f/ fswap 6.3e f/ fswap 
      zdup zp z!
      |z|^2 fdup qrho f!
      0.085264e0 f<  IF

\  QRHO <  0.085264E0 
\  Evaluate w(za) using a power-series (Abramowitz/Stegun, eq. 7.1.8, p.297)

        1e zp z@ imag 0.85e f* f- qrho f@ fsqrt f* 72e f* 6e f+ fround>s >r \ R: N
	za z@ r> zfadd_pow_series
	z2 z@ z*
      ELSE

        qrho f@ 1.0e f> IF

\  QRHO > 1.O 
\  Evaluate w(za) using the Laplace continued fraction

          0.0e0 h1 f!  0 kapn !
	  qrho f@ fsqrt 26e f* 77e f+ 1442e fswap f/ 3e f+ ftrunc>s >r \ R: nu
        ELSE

\  0.085264 < QRHO  < 1.0
\  Evaluate w(za) by a truncated Taylor expansion, where the Laplace 
\  continued fraction is used to calculate the derivatives of w(z)
\  kapn is the minimum number of terms in the Taylor expansion needed
\  to obtain the required accuracy
\  nu is the minimum number of terms of the continued fraction needed
\  to calculate the derivatives with the required accuracy
\
          1e zp z@ imag f-  1e qrho f@ f- fsqrt f*
          fdup 1.88e f*  h1 f!
          fdup 34e f* 7e f+  fround>s  kapn !
          26e f* 16e f+  fround>s >r  \ R: nu
        THEN

	za z@ r> zfadd_cfracs

      THEN   \ F: w(za) 

\  Transform w(za) to correct quadrant, to give w(zi)

      zi z@ 0.0e f<  IF         \ w(-z) = 2*exp(-z^2) - w(z)
        0.0e f> >r
	z2 z@ 2e z*f zswap z- r>
      ELSE
        f0<
      THEN

      IF conjg THEN  0 
;

BASE !
END-MODULE

TEST-CODE? [IF]

\ Set the flag below to 1 to use ttester-xf, 0 for ttester
0 constant USE_TTESTER-XF

[UNDEFINED] T{  [IF] 
USE_TTESTER-XF [IF] include ttester-xf [ELSE] include ttester  [THEN]
[THEN]

BASE @
DECIMAL

\ Reference values are taken from the Matpack special functions implementation
\ test routines in funtest.cpp, by Berndt M. Gammel. See http://www.matpack.de
\ For a more extensive table of values, reproduced from the same source, see
\ ftp://ccreweb.org/software/fsl/extras/zwofz-reference-values.txt

USE_TTESTER-XF [IF]  \  setup for ttester-xf 
\  If ref = 0, test absolute error; otherwise, test relative error
: ft-rel0=  ( F: meas ref -- ) ( -- flag )
  fdup f0= IF  ft-abs=  ELSE  ft-rel= THEN ;

: set-ft-mode-rel0  ( -- )  ['] ft-rel0= ft-test=-xt ! ;

set-ft-mode-rel0
1e-37  FT-ABS-ERROR F!
2e-15  FT-REL-ERROR F!

: ?}t  }t ;
[ELSE]  \  setup for ttester

1e-256 abs-near f!
2e-15  rel-near f!   
set-near

: ?}t  rrx}t ;
[THEN]

CR
TESTING ZWOFZ
t{ -2.0e  -2.0e zwofz ->  -0.43895282712924287596643907240606330819e     -2.10989621033098140920150385396220394331e  0 ?}t
t{ -2.0e  -1.5e zwofz ->   0.183289715319317036760070295301264235039e    -0.073260876796080792095198822633956123101e 0 ?}t
t{ -2.0e  -1.0e zwofz ->  -0.205325580646587513283825721521229530107e    -0.146855485030167393064213599903333042823e 0 ?}t
t{ -2.0e  -0.5e zwofz ->  -0.122932494822762374121292046660171680827e    -0.327555136333312587627222896684373565679e 0 ?}t
t{ -2.0e   0.0e zwofz ->   0.01831563888873418029371802127324124221191e  -0.340026217066066201280467897123400351211e 0 ?}t
t{ -2.0e   0.5e zwofz ->   0.103358823741366658953062349638804853052e    -0.28478588475009374558328290919841313745e  0 ?}t
t{ -2.0e   1.0e zwofz ->   0.140239581366277943695959506114271778326e    -0.222213440179899102605794500435104617163e 0 ?}t
t{ -2.0e   1.5e zwofz ->   0.150415438871039747617373178237581832522e    -0.170371142762476985627101574087970440296e 0 ?}t
t{ -2.0e   2.0e zwofz ->   0.14795275951201582422875630874367394297e     -0.13117971708421785358525665747162659908e  0 ?}t
t{ -1.5e  -2.0e zwofz ->  10.8674622395776211714967887828609726103e       3.0965521142997534229680658477024236488e   0 ?}t
t{ -1.5e  -1.5e zwofz ->  -0.6227067163884116411051423068613715348e       1.79071165397990662077818231386062897937e  0 ?}t
t{ -1.5e  -1.0e zwofz ->  -0.779111784231756692689265888094467986093e    -0.314034095888643736260374989580622706139e 0 ?}t
t{ -1.5e  -0.5e zwofz ->  -0.17748955379745403236318048141809805694e     -0.607712851425209724486050937542131846141e 0 ?}t
t{ -1.5e   0.0e zwofz ->   0.1053992245618643367832176892406980972685e   -0.483227330140769057926902291608470059127e 0 ?}t
t{ -1.5e   0.5e zwofz ->   0.196636032243581962363885730243649142606e    -0.337720318346887945905938190305428231255e 0 ?}t
t{ -1.5e   1.0e zwofz ->   0.211836585968510564256586582644861058736e    -0.233170977404442439968522175642150729022e 0 ?}t
t{ -1.5e   1.5e zwofz ->   0.20111511752685222914417865727371074878e     -0.16434858135028749000008771513663057636e  0 ?}t
t{ -1.5e   2.0e zwofz ->   0.1833347623811499753436522984018014989e      -0.1192982330062729387898603992894135238e   0 ?}t
t{ -1.0e  -2.0e zwofz -> -26.476058778199206857477508766171844855e       30.3085711167433072583594590086268067272e   0 ?}t
t{ -1.0e  -1.5e zwofz ->  -7.1679546161700898468604498767704492936e      -1.1203567295729395305616084222371854431e   0 ?}t
t{ -1.0e  -1.0e zwofz ->  -1.13703787835119736645227530007111933967e     -2.02681379185419501807947707907820529935e  0 ?}t
t{ -1.0e  -0.5e zwofz ->   0.155541142454331075901205660255323721008e    -1.137837215781686377738087088101075469584e 0 ?}t
t{ -1.0e   0.0e zwofz ->   0.3678794411714423215955237701614608674458e   -0.607157705841393729115038235800744921161e 0 ?}t
t{ -1.0e   0.5e zwofz ->   0.354900332867577883922445599634927294884e    -0.342871719131100716552337823750091427533e 0 ?}t
t{ -1.0e   1.0e zwofz ->   0.30474420525691259245713884106959496013e     -0.20821893820283162728743734725471561394e  0 ?}t
t{ -1.0e   1.5e zwofz ->   0.2571279392712283631817635118927714589e      -0.13524227699550782708878403838222364602e  0 ?}t
t{ -1.0e   2.0e zwofz ->   0.21849261527489069682239847542358814e        -0.0929978093926018660475030380586688847e   0 ?}t
t{ -0.5e  -2.0e zwofz -> -35.6353035120018890541413069531983298143e     -77.3801423753454349424382190735070680621e   0 ?}t
t{ -0.5e  -1.5e zwofz ->   0.74200718289486356609832707083402721227e    -14.81894370296502187613346222409723237502e  0 ?}t
t{ -0.5e  -1.0e zwofz ->   1.89640595954530034020825849466326552226e     -3.68999058851944924662944055512211701373e  0 ?}t
t{ -0.5e  -0.5e zwofz ->   1.222008415868570518464334253164948182978e    -1.189339308592864409254253941565702334794e 0 ?}t
t{ -0.5e   0.0e zwofz ->   0.7788007830714048682451702669783206472968e   -0.478925172901043472544937540717089342226e 0 ?}t
t{ -0.5e   0.5e zwofz ->   0.533156707912174913768228912042711121005e    -0.23048823138445840870767807113455955863e  0 ?}t
t{ -0.5e   1.0e zwofz ->   0.39123402145213608337190110677048354169e     -0.12720241088464801019460968171034158452e  0 ?}t
t{ -0.5e   1.5e zwofz ->   0.30335511991319153439202737939137821881e     -0.07785087412615059529718940382149537324e  0 ?}t
t{ -0.5e   2.0e zwofz ->   0.2452759902263585078573396831219042248e      -0.0515214783436358491099961278415586527e   0 ?}t
t{  0.0e  -2.0e zwofz -> 108.9409043899779724123554338248132140423e       0.0e                                       0 ?}t
t{  0.0e  -1.5e zwofz ->  18.65388625626273393874641550130021127851e      0.0e                                       0 ?}t
t{  0.0e  -1.0e zwofz ->   5.00898008076228346630982459821480981469e      0.0e                                       0 ?}t
t{  0.0e  -0.5e zwofz ->   1.95236048918255709327604771344113097989e      0.0e                                       0 ?}t
t{  0.0e   0.0e zwofz ->   1.0e                                           0.0e                                       0 ?}t
t{  0.0e   0.5e zwofz ->   0.615690344192925874870793422683741936782e     0.0e                                       0 ?}t
t{  0.0e   1.0e zwofz ->   0.42758357615580700441075034449051518082e      0.0e                                       0 ?}t
t{  0.0e   1.5e zwofz ->   0.32158541645431750235432258772326556903e      0.0e                                       0 ?}t
t{  0.0e   2.0e zwofz ->   0.2553956763105057438650885809085427633e       0.0e                                       0 ?}t
t{  0.5e  -2.0e zwofz -> -35.6353035120018890541413069531983298143e      77.3801423753454349424382190735070680621e   0 ?}t
t{  0.5e  -1.5e zwofz ->   0.74200718289486356609832707083402721227e     14.81894370296502187613346222409723237502e  0 ?}t
t{  0.5e  -1.0e zwofz ->   1.89640595954530034020825849466326552226e      3.68999058851944924662944055512211701373e  0 ?}t
t{  0.5e  -0.5e zwofz ->   1.222008415868570518464334253164948182978e     1.189339308592864409254253941565702334794e 0 ?}t
t{  0.5e   0.0e zwofz ->   0.7788007830714048682451702669783206472968e    0.478925172901043472544937540717089342226e 0 ?}t
t{  0.5e   0.5e zwofz ->   0.533156707912174913768228912042711121005e     0.23048823138445840870767807113455955863e  0 ?}t
t{  0.5e   1.0e zwofz ->   0.39123402145213608337190110677048354169e      0.12720241088464801019460968171034158452e  0 ?}t
t{  0.5e   1.5e zwofz ->   0.30335511991319153439202737939137821881e      0.07785087412615059529718940382149537324e  0 ?}t
t{  0.5e   2.0e zwofz ->   0.2452759902263585078573396831219042248e       0.0515214783436358491099961278415586527e   0 ?}t
t{  1.0e  -2.0e zwofz -> -26.476058778199206857477508766171844855e      -30.3085711167433072583594590086268067272e   0 ?}t
t{  1.0e  -1.5e zwofz ->  -7.1679546161700898468604498767704492936e       1.1203567295729395305616084222371854431e   0 ?}t
t{  1.0e  -1.0e zwofz ->  -1.13703787835119736645227530007111933967e      2.02681379185419501807947707907820529935e  0 ?}t
t{  1.0e  -0.5e zwofz ->   0.155541142454331075901205660255323721008e     1.137837215781686377738087088101075469584e 0 ?}t
t{  1.0e   0.0e zwofz ->   0.3678794411714423215955237701614608674458e    0.607157705841393729115038235800744921161e 0 ?}t
t{  1.0e   0.5e zwofz ->   0.354900332867577883922445599634927294884e     0.342871719131100716552337823750091427533e 0 ?}t
t{  1.0e   1.0e zwofz ->   0.30474420525691259245713884106959496013e      0.20821893820283162728743734725471561394e  0 ?}t
t{  1.0e   1.5e zwofz ->   0.2571279392712283631817635118927714589e       0.13524227699550782708878403838222364602e  0 ?}t
t{  1.0e   2.0e zwofz ->   0.21849261527489069682239847542358814e         0.0929978093926018660475030380586688847e   0 ?}t
t{  1.5e  -2.0e zwofz ->  10.8674622395776211714967887828609726103e      -3.0965521142997534229680658477024236488e   0 ?}t
t{  1.5e  -1.5e zwofz ->  -0.6227067163884116411051423068613715348e      -1.79071165397990662077818231386062897937e  0 ?}t
t{  1.5e  -1.0e zwofz ->  -0.779111784231756692689265888094467986093e     0.314034095888643736260374989580622706139e 0 ?}t
t{  1.5e  -0.5e zwofz ->  -0.17748955379745403236318048141809805694e      0.607712851425209724486050937542131846141e 0 ?}t
t{  1.5e   0.0e zwofz ->   0.1053992245618643367832176892406980972685e    0.483227330140769057926902291608470059127e 0 ?}t
t{  1.5e   0.5e zwofz ->   0.196636032243581962363885730243649142606e     0.337720318346887945905938190305428231255e 0 ?}t
t{  1.5e   1.0e zwofz ->   0.211836585968510564256586582644861058736e     0.233170977404442439968522175642150729022e 0 ?}t
t{  1.5e   1.5e zwofz ->   0.20111511752685222914417865727371074878e      0.16434858135028749000008771513663057636e  0 ?}t
t{  1.5e   2.0e zwofz ->   0.1833347623811499753436522984018014989e       0.1192982330062729387898603992894135238e   0 ?}t
t{  2.0e  -2.0e zwofz ->  -0.43895282712924287596643907240606330819e      2.10989621033098140920150385396220394331e  0 ?}t
t{  2.0e  -1.5e zwofz ->   0.183289715319317036760070295301264235039e     0.073260876796080792095198822633956123101e 0 ?}t
t{  2.0e  -1.0e zwofz ->  -0.205325580646587513283825721521229530107e     0.146855485030167393064213599903333042823e 0 ?}t
t{  2.0e  -0.5e zwofz ->  -0.122932494822762374121292046660171680827e     0.327555136333312587627222896684373565679e 0 ?}t
t{  2.0e   0.0e zwofz ->   0.01831563888873418029371802127324124221191e   0.340026217066066201280467897123400351211e 0 ?}t
t{  2.0e   0.5e zwofz ->   0.103358823741366658953062349638804853052e     0.28478588475009374558328290919841313745e  0 ?}t
t{  2.0e   1.0e zwofz ->   0.140239581366277943695959506114271778326e     0.222213440179899102605794500435104617163e 0 ?}t
t{  2.0e   1.5e zwofz ->   0.150415438871039747617373178237581832522e     0.170371142762476985627101574087970440296e 0 ?}t
t{  2.0e   2.0e zwofz ->   0.14795275951201582422875630874367394297e      0.13117971708421785358525665747162659908e  0 ?}t

BASE !
[THEN]

