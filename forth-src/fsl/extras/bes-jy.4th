\ bes-jy.fs
\
\ This program computes zero and first order Bessel functions of the first
\   and second kind (J0, Y0, J1, Y1), for real arguments X, where 
\   0 < X <= XMAX for Y0, Y1, and |X| <= XMAX for J0, J1.
\ 
\ Provides:
\
\   BES-J0
\   BES-Y0
\   BES-J1
\   BES-Y1
\
\ Based on FORTRAN programs by W. Cody: j0y0.f and j1y1.f, from the 
\ SPECFUN package.
\
\ Requires:
\
\  fsl-util.fs  FSL utility file
\
\ Text from the original code (with edits and mods, as appropriate):
\
\   The main computation uses unpublished minimax rational
\   approximations for X .LE. 8.0, and an approximation from the 
\   book  Computer Approximations  by Hart, et. al., Wiley and Sons, 
\   New York, 1968, for arguments larger than 8.0   Part of this
\   transportable packet is patterned after the machine-dependent
\   FUNPACK program BESJ0(X), but cannot match that version for
\   efficiency or accuracy.  This version uses rational functions
\   that are theoretically accurate to at least 18 significant decimal
\   digits for X <= 8, and at least 18 decimal places for X > 8.  The
\   accuracy achieved depends on the arithmetic system, the compiler,
\   the intrinsic functions, and proper selection of the machine-
\   dependent constants.
\
\ *******************************************************************
\
\ Explanation of machine-dependent constants
\
\   XINF   = largest positive machine number
\   XMAX   = largest acceptable argument.  The functions AINT, SIN
\            and COS must perform properly for  ABS(X) .LE. XMAX.
\            We recommend that XMAX be a small integer multiple of
\            sqrt(1/eps), where eps is the smallest positive number
\            such that  1+eps > 1. 
\   XSMALL = positive argument such that  1.0-(X/2)**2 = 1.0
\            to machine precision for all  ABS(X) .LE. XSMALL.
\            We recommend that  XSMALL < sqrt(eps)/beta, where beta
\            is the floating-point radix (usually 2 or 16).
\
\     Approximate values for some important machines are
\
\                          eps      XMAX     XSMALL      XINF  
\
\  CDC 7600      (S.P.)  7.11E-15  1.34E+08  2.98E-08  1.26E+322
\  CRAY-1        (S.P.)  7.11E-15  1.34E+08  2.98E-08  5.45E+2465
\  IBM PC (8087) (S.P.)  5.96E-08  8.19E+03  1.22E-04  3.40E+38
\  IBM PC (8087) (D.P.)  1.11D-16  2.68D+08  3.72D-09  1.79D+308
\  IBM 195       (D.P.)  2.22D-16  6.87D+09  9.09D-13  7.23D+75
\  UNIVAC 1108   (D.P.)  1.73D-18  4.30D+09  2.33D-10  8.98D+307
\  VAX 11/780    (D.P.)  1.39D-17  1.07D+09  9.31D-10  1.70D+38
\
\ *******************************************************************
\
\ Error Returns
\
\  The program returns the value zero for  X .GT. XMAX, and returns
\    -XINF when Y0, Y1 are called with a negative or zero argument.
\
\
\ Intrinsic functions required are:
\
\     ABS, AINT, COS, LOG, SIN, SQRT
\
\
\  Latest modification: June 2, 1989
\
\  Author: W. J. Cody
\          Mathematics and Computer Science Division 
\          Argonne National Laboratory
\          Argonne, IL 60439
\
\ --------------------------------------------------------------------
\
\ Ported to Forth-94 by K. Myneni, Creative Consulting for
\   Research and Education, krishna.myneni@ccreweb.org.
\
\ Revisions:
\   2011-06-18  km  integrated j0y0.fs and j1y1.fs into this
\                   single file.
\   2011-07-02  km  revised the test reference values and added
\                   further symmetry checks.
\   2011-09-16  km  use Neal Bridges' anonymous modules.
\   2012-02-19  km  use KM/DNW's modules library.
\
\ Addtional Notes:
\
\ 0. Original F77 programs, on which this code is based, may be found 
\    at:  http://www.netlib.org/specfun/
\
\ 1. Higher order J_n and Y_n functions will be implemented using the
\    recurrence relations for these functions (not yet done).
\
\ 2. Arguments for the function tests are chosen such that they are
\    exactly representable in IEEE 754 format at double precision, e.g.
\    1e-3 is not exactly representable with a 53-bit mantissa, but
\    9.765625e-4 is exactly representable.
\
\ 3. Reference values for test code are computed with either the 
\    forth-gmpfr library interface to GNU MPFR, or with Wolfram Alpha.
\

BEGIN-MODULE

BASE @
DECIMAL

Public:

[undefined] fsquare [if] : fsquare postpone fdup postpone f* ; immediate [then]
[undefined] fnip    [if] : fnip fswap fdrop ; [then]

Private:

\ -------------------------------------------------------------------
\  Mathematical constants
\    CONS = ln(.5) + Euler's gamma
\ -------------------------------------------------------------------
 0.0E0   fconstant  ZERO
 0.5E0   fconstant  HALF
 1.0E0   fconstant  ONE
 3.0E0   fconstant  THREE
 4.0E0   fconstant  FOUR
 8.0E0   fconstant  EIGHT
 5.5E0   fconstant  FIVE5
64.0E0   fconstant  SIXTY4
0.125E0  fconstant  ONEOV8
0.375E0  fconstant  THROV8
1.716E-1 fconstant  P17
256.0E0  fconstant  TWO56
-1.1593151565841244881E-1   fconstant  CONS
 6.3661977236758134308E-1   fconstant  PI2
 6.2831853071795864769E0    fconstant  TWOPI
 6.28125E0                  fconstant  TWOPI1
 1.9353071795864769253E-3   fconstant  TWOPI2
 7.9788456080286535588E-1   fconstant  RTPI2
\ -------------------------------------------------------------------
\  Machine-dependent constants
\ -------------------------------------------------------------------
0 [IF]                      \ single precision
8.19E+03 fconstant  XMAX
1.22E-09 fconstant  XSMALL
1.7E+38  fconstant  XINF 
[ELSE]                      \ double precision
1.07E+09 fconstant  XMAX
9.31E-10 fconstant  XSMALL
1.7E+38  fconstant  XINF
[THEN]

\ -------------------------------------------------------------------
\  Coefficients for rational approximation to ln(x/a)
\ --------------------------------------------------------------------
 4 FLOAT ARRAY PLG{
    -2.4562334077563243311E+01
     2.3642701335621505212E+02
    -5.4989956895857911039E+02
     3.5687548468071500413E+02
4 PLG{ }fput

 4 FLOAT ARRAY QLG{
    -3.5553900764052419184E+01
     1.9400230218539473193E+02
    -3.3442903192607538956E+02
     1.7843774234035750207E+02
4 QLG{ }fput

\ -------------------------------------------------------------------
\  Zeroes of J0 and Y0 Bessel functions
\ -------------------------------------------------------------------
 2.4048255576957727686E+0   fconstant  XJ0
 5.5200781102863106496E+0   fconstant  XJ1
 8.9357696627916752158E-1   fconstant  XY0
 3.9576784193148578684E+0   fconstant  XY1
 7.0860510603017726976E+0   fconstant  XY2
 616.0E+0                   fconstant  XJ01
-1.4244423042272313784E-03  fconstant  XJ02
 1413.0E+0                  fconstant  XJ11
 5.4686028631064959660E-04  fconstant  XJ12
 228.0E+0                   fconstant  XY01
 2.9519662791675215849E-03  fconstant  XY02
 1013.0E+0                  fconstant  XY11
 6.4716931485786837568E-04  fconstant  XY12
 1814.0E+0                  fconstant  XY21
 1.1356030177269762362E-04  fconstant  XY22

\ -------------------------------------------------------------------
\  Coefficients for rational approximation of
\  J0(X) / (X**2 - XJ0**2),  XSMALL  <  |X|  <=  4.0
\ --------------------------------------------------------------------
 7 FLOAT ARRAY PJ0{
     6.6302997904833794242E+06
    -6.2140700423540120665E+08
     2.7282507878605942706E+10
    -4.1298668500990866786E+11
    -1.2117036164593528341E-01
     1.0344222815443188943E+02
    -3.6629814655107086448E+04
7 PJ0{ }fput

 5 FLOAT ARRAY QJ0{
     4.5612696224219938200E+05
     1.3985097372263433271E+08
     2.6328198300859648632E+10
     2.3883787996332290397E+12
     9.3614022392337710626E+02
5 QJ0{ }fput

\ -------------------------------------------------------------------
\  Coefficients for rational approximation of
\  J0(X) / (X**2 - XJ1**2),  4.0  <  |X|  <=  8.0
\ -------------------------------------------------------------------
 8 FLOAT ARRAY PJ1{
     4.4176707025325087628E+03
     1.1725046279757103576E+04
     1.0341910641583726701E+04
    -7.2879702464464618998E+03
    -1.2254078161378989535E+04
    -1.8319397969392084011E+03
     4.8591703355916499363E+01
     7.4321196680624245801E+02
8 PJ1{ }fput

 7 FLOAT ARRAY QJ1{
     3.3307310774649071172E+02
    -2.9458766545509337327E+03
     1.8680990008359188352E+04
    -8.4055062591169562211E+04
     2.4599102262586308984E+05
    -3.5783478026152301072E+05
    -2.5258076240801555057E+01
7 QJ1{ }fput

\ -------------------------------------------------------------------
\  Coefficients for rational approximation of
\    (Y0(X) - 2 LN(X/XY0) J0(X)) / (X**2 - XY0**2),
\        XSMALL  <  |X|  <=  3.0
\ --------------------------------------------------------------------
 6 FLOAT ARRAY PY0{
     1.0102532948020907590E+04
    -2.1287548474401797963E+06
     2.0422274357376619816E+08
    -8.3716255451260504098E+09
     1.0723538782003176831E+11
    -1.8402381979244993524E+01
6 PY0{ }fput

 5 FLOAT ARRAY QY0{
     6.6475986689240190091E+02
     2.3889393209447253406E+05
     5.5662956624278251596E+07
     8.1617187777290363573E+09
     5.8873865738997033405E+11
5 QY0{ }fput

\ -------------------------------------------------------------------
\  Coefficients for rational approximation of
\    (Y0(X) - 2 LN(X/XY1) J0(X)) / (X**2 - XY1**2),
\        3.0  <  |X|  <=  5.5
\ --------------------------------------------------------------------
 7 FLOAT ARRAY PY1{
    -1.4566865832663635920E+04
     4.6905288611678631510E+06
    -6.9590439394619619534E+08
     4.3600098638603061642E+10
    -5.5107435206722644429E+11
    -2.2213976967566192242E+13
     1.7427031242901594547E+01
7 PY1{ }fput

 6 FLOAT ARRAY QY1{
     8.3030857612070288823E+02
     4.0669982352539552018E+05
     1.3960202770986831075E+08
     3.4015103849971240096E+10
     5.4266824419412347550E+12
     4.3386146580707264428E+14
6 QY1{ }fput

\ -------------------------------------------------------------------
\  Coefficients for rational approximation of
\    (Y0(X) - 2 LN(X/XY2) J0(X)) / (X**2 - XY2**2),
\        5.5  <  |X|  <=  8.0
\ --------------------------------------------------------------------
 8 FLOAT ARRAY PY2{
     2.1363534169313901632E+04
    -1.0085539923498211426E+07
     2.1958827170518100757E+09
    -1.9363051266772083678E+11
    -1.2829912364088687306E+11
     6.7016641869173237784E+14
    -8.0728726905150210443E+15
    -1.7439661319197499338E+01
8 PY2{ }fput

 7 FLOAT ARRAY QY2{
     8.7903362168128450017E+02
     5.3924739209768057030E+05
     2.4727219475672302327E+08
     8.6926121104209825246E+10
     2.2598377924042897629E+13
     3.9272425569640309819E+15
     3.4563724628846457519E+17
7 QY2{ }fput

\ -------------------------------------------------------------------
\  Coefficients for Hart's approximation,  |X| > 8.0
\ -------------------------------------------------------------------
 6 FLOAT ARRAY P0{
     3.4806486443249270347E+03
     2.1170523380864944322E+04
     4.1345386639580765797E+04
     2.2779090197304684302E+04
     8.8961548424210455236E-01
     1.5376201909008354296E+02
6 P0{ }fput

 5 FLOAT ARRAY Q0{
     3.5028735138235608207E+03
     2.1215350561880115730E+04
     4.1370412495510416640E+04
     2.2779090197304684318E+04
     1.5711159858080893649E+02
5 Q0{ }fput

 6 FLOAT ARRAY P1{
    -2.2300261666214198472E+01
    -1.1183429920482737611E+02
    -1.8591953644342993800E+02
    -8.9226600200800094098E+01
    -8.8033303048680751817E-03
    -1.2441026745835638459E+00
6 P1{ }fput

 5 FLOAT ARRAY Q1{
     1.4887231232283756582E+03
     7.2642780169211018836E+03
     1.1951131543434613647E+04
     5.7105024128512061905E+03
     9.0593769594993125859E+01
5 Q1{ }fput

\ -------------------------------------------------------------------
\  Calculate J0 for appropriate interval, preserving
\     accuracy near the zero of J0
\ -------------------------------------------------------------------
fvariable XNUM
fvariable XDEN
fvariable ZSQ

: cal_J0 ( F: ax -- result )
      fdup  fsquare ZSQ f! 
      fdup  FOUR f<=  if
            PJ0{ 4 } f@ ZSQ f@ f*  PJ0{ 5 } f@ f+ ZSQ f@ f*   
            PJ0{ 6 } f@ f+        xnum f!
            ZSQ f@ QJ0{ 4 } f@ f+ xden f!

	    zsq f@
            4 0 do
               xnum f@ fover f* PJ0{ I } f@ f+  xnum f! 
               xden f@ fover f* QJ0{ I } f@ f+  xden f! 
            loop
	    fdrop   \ F: ax 
            fdup  XJ01 TWO56 f/ f- XJ02 f- fover XJ0 f+ f*     \ F: ax prod
      else
            ONE ZSQ f@ SIXTY4 f/ f-           \ F: ax WSQ    
            PJ1{ 6 } f@ fover f* PJ1{ 7 } f@ f+  xnum f!
            QJ1{ 6 } f@ fover f+  xden f!

            6 0 do
               xnum f@ fover f* PJ1{ I } f@ f+  xnum f!
               xden f@ fover f* QJ1{ I } f@ f+  xden f!
            loop
	    fdrop  \ F: ax
            fdup XJ1 f+ fover XJ11 TWO56 f/ f- XJ12 f- f*
      then

      xnum f@ f* xden f@ f/
      fnip
;

\ -------------------------------------------------------------------
\  Calculate  resJ0 = pi/2 ln(x/xn) J0(x), where xn is a zero of Y0
\ -------------------------------------------------------------------
fvariable UP
fvariable DOWN
fvariable WSQ
fvariable W
fvariable XY

: res_J0 ( F: ax J0 -- resj0 )
      PI2 f* fover
      fdup THREE f<=  if
        fdup XY01 TWO56 f/ f- XY02 f- 
        XY0
      else
        fdup FIVE5 f<=  if
          fdup XY11 TWO56 f/ f- XY12 f-
          XY1
        else
          fdup XY21 TWO56 f/ f- XY22 f-
          XY2
        then
      then    \ F: ax J0 ax up xy
      XY f!     UP f!
      XY f@ f+  DOWN f!

      UP f@ fabs   P17 DOWN f@ f*  f<  if
        UP f@ DOWN f@ f/  W    f!
        W f@ fsquare      WSQ  f!
        PLG{ 0 } f@       XNUM f!
        WSQ f@ QLG{ 0 } f@  f+  XDEN f!

        WSQ f@
        4 1 do
          XNUM f@ fover f* PLG{ I } f@ f+  XNUM f!
          XDEN F@ fover f* QLG{ I } f@ f+  XDEN f!
        loop
        fdrop

         W f@ XNUM f@ f* XDEN f@ f/
      else
        fover XY f@ f/ fln 
      then
      f*
      fnip
;


\ -------------------------------------------------------------------
\  Calculate Y0 for appropriate interval, preserving
\     accuracy near the zero of Y0
\ -------------------------------------------------------------------
: cal_Y0 ( F: ax J0 -- result)
      f2dup res_J0 fnip fswap  \ F: resj ax
      fdup THREE f<= if
        PY0{ 5 } f@ ZSQ f@ f* PY0{ 0 } f@ f+  xnum f!
        ZSQ f@ QY0{ 0 } f@ F+  xden f!

        ZSQ f@
        5 1 do
          xnum f@ fover f* PY0{ I } f@ f+  xnum F!
          xden f@ fover f* QY0{ I } f@ f+  xden F!
        loop
        fdrop
      else
        fdup FIVE5 f<= if
              PY1{ 6 } f@ ZSQ f@ f* PY1{ 0 } f@ f+  xnum f!
              ZSQ f@ QY1{ 0 } f@ f+  xden f!

              ZSQ f@
              6 1 do
                xnum f@ fover f* PY1{ I } f@ f+  xnum f!
                xden f@ fover f* QY1{ I } f@ f+  xden f!
              loop
              fdrop

        else
             PY2{ 7 } f@ ZSQ f@ f* PY2{ 0 } f@ f+  xnum f!
             ZSQ f@ QY2{ 0 } f@ f+  xden f!

	     ZSQ f@
             7 1 do
               xnum f@ fover f* PY2{ I } f@ f+  xnum f!
               xden f@ fover f* QY2{ I } f@ f+  xden f!
             loop
             fdrop
        then
      then
      fdrop

      UP f@ DOWN f@ f* XNUM f@ f* XDEN f@ f/  f+
;


\ -------------------------------------------------------------------
\  Calculate J0 or Y0 for |ARG|  >  8.0
\ -------------------------------------------------------------------
fvariable Z
fvariable R0
fvariable R1

: cal_JY0_8 ( ax jint -- result)
      >r
      EIGHT fover f/ fdup Z f! fsquare ZSQ f!
      fdup TWOPI f/ ftrunc ONEOV8 f+  W f!
      fdup W f@ TWOPI1 f* f- W f@ TWOPI2 f* f-  W f! 
      
      P0{ 4 } f@ ZSQ f@ f* P0{ 5 } f@ f+  XNUM f!
      ZSQ f@ Q0{ 4 } f@ f+  XDEN f!
      P1{ 4 } f@ ZSQ f@ f* P1{ 5 } f@ f+  UP f!
      ZSQ f@ Q1{ 4 } f@ f+  DOWN f!

      ZSQ f@
      4 0 do
         XNUM f@ fover f* P0{ I } f@ f+  XNUM f!
         XDEN f@ fover f* Q0{ I } f@ f+  XDEN f!
         UP   f@ fover f* P1{ I } f@ f+  UP   f!
         DOWN f@ fover f* Q1{ I } f@ f+  DOWN f!
      loop
      fdrop

      XNUM f@ XDEN f@ f/  R0 f!
      UP f@ DOWN f@ f/    R1 f!
      W f@ fsincos
      r> 0= IF
            R0 f@ f* fswap R1 f@ f* Z f@ f* f- 
      ELSE
            R1 f@ f* Z f@ f* FSWAP R0 f@ f* f+
      THEN
      PI2 frot f/ fsqrt f* 
;

\ --------------------------------------------------------------------

Public:

\ Compute approximate values for Bessel functions of the first kind of 
\ order zero for arguments  |X| <= XMAX

: bes-J0 ( F: x -- r )
     fabs
     fdup XSMALL f<= if  fdrop ONE   EXIT  then
     fdup XMAX   f>  if  fdrop ZERO  EXIT  then
     fdup EIGHT  f>  if  0 cal_JY0_8 EXIT  then
     cal_J0 ;


\ Compute approximate values for Bessel functions of the second kind of 
\ order zero for arguments 0 < X <= XMAX

: bes-Y0 ( F: x -- r )  
     fdup ZERO   f<= if  fdrop XINF fnegate EXIT  then
     fabs
     fdup XSMALL f<= if  FLN CONS f+ PI2 f* EXIT  then
     fdup XMAX   f>  if  fdrop ZERO         EXIT  then
     fdup EIGHT  f>  if  1 cal_JY0_8        EXIT  then
     fdup  cal_J0  cal_Y0  ;

\ --------------------------------------------------------------------

Private:

\ -------------------------------------------------------------------
\  Zeroes of J1 and Y1 Bessel functions
\ -------------------------------------------------------------------
 3.8317059702075123156E+0  fconstant  XJ0
 7.0155866698156187535E+0  fconstant  XJ1
 2.1971413260310170351E+0  fconstant  XY0
 5.4296810407941351328E+0  fconstant  XY1
 981.0E+0                  fconstant  XJ01
-3.2527979248768438556E-04 fconstant  XJ02
 1796.0E+0                 fconstant  XJ11
-3.8330184381246462950E-05 fconstant  XJ12
 562.0E+0                  fconstant  XY01
 1.8288260310170351490E-03 fconstant  XY02
 1390.0E+0                 fconstant  XY11
-6.4592058648672279948E-06 fconstant  XY12

\ -------------------------------------------------------------------
\  Coefficients for rational approximation of
\  J1(X) / (X * (X**2 - XJ0**2)),  XSMALL  <  |X|  <=  4.0
\ --------------------------------------------------------------------
7 FLOAT ARRAY PJ0{
 9.8062904098958257677E+05
-1.1548696764841276794E+08
 6.6781041261492395835E+09
-1.4258509801366645672E+11
-4.4615792982775076130E+03 
 1.0650724020080236441E+01
-1.0767857011487300348E-02
7 PJ0{ }fput

5 FLOAT ARRAY QJ0{
 5.9117614494174794095E+05
 2.0228375140097033958E+08
 4.2091902282580133541E+10 
 4.1868604460820175290E+12
 1.0742272239517380498E+03
5 QJ0{ }fput

\ -------------------------------------------------------------------
\  Coefficients for rational approximation of
\  J1(X) / (X * (X**2 - XJ1**2)),  4.0  <  |X|  <=  8.0
\ -------------------------------------------------------------------
8 FLOAT ARRAY PJ1{
 4.6179191852758252280E+00
-7.1329006872560947377E+03
 4.5039658105749078904E+06
-1.4437717718363239107E+09
 2.3569285397217157313E+11
-1.6324168293282543629E+13
 1.1357022719979468624E+14
 1.0051899717115285432E+15
8 PJ1{ }fput

7 FLOAT ARRAY QJ1{
 1.1267125065029138050E+06
 6.4872502899596389593E+08
 2.7622777286244082666E+11
 8.4899346165481429307E+13
 1.7128800897135812012E+16
 1.7253905888447681194E+18
 1.3886978985861357615E+03
7 QJ1{ }fput

\ -------------------------------------------------------------------
\  Coefficients for rational approximation of
\    (Y1(X) - 2 LN(X/XY0) J1(X)) / (X**2 - XY0**2),
\        XSMALL  <  |X|  <=  4.0
\ --------------------------------------------------------------------
7 FLOAT ARRAY PY0{
 2.2157953222280260820E+05
-5.9157479997408395984E+07
 7.2144548214502560419E+09
-3.7595974497819597599E+11
 5.4708611716525426053E+12
 4.0535726612579544093E+13
-3.1714424660046133456E+02
7 PY0{ }fput

6 FLOAT ARRAY QY0{
 8.2079908168393867438E+02
 3.8136470753052572164E+05
 1.2250435122182963220E+08
 2.7800352738690585613E+10
 4.1272286200406461981E+12
 3.0737873921079286084E+14
6 QY0{ }fput

\ --------------------------------------------------------------------
\  Coefficients for rational approximation of
\    (Y1(X) - 2 LN(X/XY1) J1(X)) / (X**2 - XY1**2),
\        4.0  <  |X|  <=  8.0
\ --------------------------------------------------------------------
9 FLOAT ARRAY PY1{
 1.9153806858264202986E+06
-1.1957961912070617006E+09
 3.7453673962438488783E+11
-5.9530713129741981618E+13
 4.0686275289804744814E+15
-2.3638408497043134724E+16
-5.6808094574724204577E+18
 1.1514276357909013326E+19
-1.2337180442012953128E+03
9 PY1{ }fput

8 FLOAT ARRAY QY1{
 1.2855164849321609336E+03
 1.0453748201934079734E+06
 6.3550318087088919566E+08
 3.0221766852960403645E+11
 1.1187010065856971027E+14
 3.0837179548112881950E+16
 5.6968198822857178911E+18
 5.3321844313316185697E+20
8 QY1{ }fput

\ -------------------------------------------------------------------
\  Coefficients for Hart's approximation,  |X| > 8.0
\ -------------------------------------------------------------------
6 FLOAT ARRAY P0{
-1.0982405543459346727E+05
-1.5235293511811373833E+06
-6.6033732483649391093E+06
-9.9422465050776411957E+06
-4.4357578167941278571E+06
-1.6116166443246101165E+03
6 P0{ }fput

6 FLOAT ARRAY Q0{
-1.0726385991103820119E+05
-1.5118095066341608816E+06
-6.5853394797230870728E+06
-9.9341243899345856590E+06
-4.4357578167941278568E+06
-1.4550094401904961825E+03
6 Q0{ }fput

6 FLOAT ARRAY P1{
 1.7063754290207680021E+03
 1.8494262873223866797E+04
 6.6178836581270835179E+04
 8.5145160675335701966E+04
 3.3220913409857223519E+04
 3.5265133846636032186E+01
6 P1{ }fput

6 FLOAT ARRAY Q1{
 3.7890229745772202641E+04
 4.0029443582266975117E+05
 1.4194606696037208929E+06
 1.8194580422439972989E+06
 7.0871281941028743574E+05
 8.6383677696049909675E+02
6 Q1{ }fput


\ -------------------------------------------------------------------
\  Calculate J1 for appropriate interval, preserving
\     accuracy near the zero of J1
\ -------------------------------------------------------------------
fvariable xnum
fvariable xden
fvariable zsq

: cal_J1 ( F: arg -- result)
      fdup  fabs              \ F: arg ax
      fdup  fsquare zsq f!
      fdup  FOUR f<=  IF
            PJ0{ 6 } f@ zsq f@ f* PJ0{ 5 } f@ f+  zsq f@ f* 
	    PJ0{ 4 } f@ f+  xnum f!
            zsq f@ QJ0{ 4 } f@ f+  xden f!

            zsq f@
            4 0 DO  
               xnum f@ fover f*  PJ0{ I } f@ f+  xnum f!
               xden f@ fover f*  QJ0{ I } f@ f+  xden f!
            LOOP
            fdrop  \ F: arg ax
            fdup XJ01 TWO56 f/ f- XJ02 f-  fswap XJ0 f+ f*   \ F: arg prod
         ELSE
            PJ1{ 0 } f@ xnum f!
            zsq f@ QJ1{ 6 } f@ f+  zsq f@ f* QJ1{ 0 } f@ f+  xden f!
            zsq f@
            6 1 DO
               xnum f@ fover f* PJ1{ I } f@ f+  xnum f!
               xden f@ fover f* QJ1{ I } f@ f+  xden f!
            LOOP
            fdrop   \ F: arg ax
	    fdup EIGHT f- fover EIGHT f+ f* xnum f@ f*  PJ1{ 6 } f@ f+ xnum f!
            fdup FOUR  f- fover FOUR  f+ f* xnum f@ f*  PJ1{ 7 } f@ f+ xnum f!
            fdup XJ11 TWO56 f/ f- XJ12 f-  fswap XJ1 f+ f*  \ F: arg prod
      THEN
      xnum f@ f* xden f@ f/
      f*
;

\ -------------------------------------------------------------------
\   Calculate resJ1 = pi/2 ln(x/xn) J1(x), where xn is a zero of Y1
\ -------------------------------------------------------------------
fvariable up
fvariable down
fvariable wsq
fvariable w
fvariable xy

: res_J1 ( F: ax J1 -- resj1 )
      PI2 f* fover
      fdup FOUR f<= IF
            fdup XY01 TWO56 f/ f- XY02 f-
            XY0
      ELSE
            fdup XY11 TWO56 f/ f- XY12 f-
            XY1
      THEN       \ F: ax J1*pi/2 ax up xy
      xy f!  up f!
      fdup xy f@ f+ down f!  \ F: ax J1*pi/2 ax

      up f@ fabs  P17 down f@ f*  f<  if
            up f@ down f@ f/  w f!
            w  f@ fsquare     wsq f!
            PLG{ 0 } f@       xnum f!
            wsq f@ QLG{ 0 } f@ f+  xden f!

            wsq f@
            4 1 DO
               xnum f@ fover f* PLG{ I } f@ f+  xnum f!
               xden f@ fover f* QLG{ I } f@ f+  xden f!
            LOOP
            f2drop  \ F: ax J1*pi/2
	    w f@ f* xnum f@ f* xden f@ f/ 
      ELSE
	    xy f@ f/ fln f*
      THEN
      fnip
;


\ -------------------------------------------------------------------
\  Calculate Y1 for appropriate interval, preserving
\     accuracy near the zero of Y1
\ -------------------------------------------------------------------
: cal_Y1 ( F: ax J1 -- result)
      f2dup res_J1 fnip fswap  \ F: resj ax
      fdup FOUR f<= IF
            PY0{ 6 } f@ zsq f@ f* PY0{ 0 } f@ f+  xnum f!
            zsq f@ QY0{ 0 } f@ f+  xden f!

            zsq f@
            6 1 DO 
               xnum f@ fover f* PY0{ I } f@ f+  xnum f!
               xden f@ fover f* QY0{ I } f@ f+  xden f!
            LOOP
            fdrop
      ELSE
            PY1{ 8 } f@ zsq f@ f* PY1{ 0 } f@ f+  xnum f!
            zsq f@ QY1{ 0 } f@ f+  xden f!

            zsq f@
            8 1 DO
               xnum f@ fover f* PY1{ I } f@ f+  xnum f!
               xden f@ fover f* QY1{ I } f@ f+  xden f!
            LOOP
            fdrop
      THEN
      up f@ down f@ f* fswap f/ xnum f@ f* xden f@ f/ f+
;

\ -------------------------------------------------------------------
\  Calculate J1 or Y1 for |ARG|  >  8.0
\ -------------------------------------------------------------------
fvariable z
fvariable r0
fvariable r1

: cal_JY1_8 ( arg jint -- result)  \ ( jint -- ) ( F: arg -- result )
      >r fdup fabs
      EIGHT fover f/  z f!
      fdup TWOPI f/ ftrunc THROV8 f+  w f!
      fdup w f@ TWOPI1 f* f- W f@ TWOPI2 f* f-  w f!
      z f@ fsquare zsq f!
      P0{ 5 } f@  xnum f!
      zsq f@ Q0{ 5 } f@ f+  xden f!
      P1{ 5 } f@  up f!
      zsq f@ Q1{ 5 } f@ f+  down f!

      zsq f@
      5 0 DO
         xnum f@ fover f* P0{ I } f@ f+  xnum f!
         xden f@ fover f* Q0{ I } f@ f+  xden f!
         up   f@ fover f* P1{ I } f@ f+  up   f!
         down f@ fover f* Q1{ I } f@ f+  down f!
      LOOP
      fdrop

      xnum f@ xden f@ f/  r0 f!
      up   f@ down f@ f/  r1 f!
      w f@ fsincos
      r@ 0= IF  \ F: arg ax sin(w) cos(w)
            r0 f@ f* fswap r1 f@ f* z f@ f* f-
      ELSE
            r1 f@ f* z f@ f* fswap r0 f@ f* f+
      THEN
      PI2 frot f/ fsqrt f* fswap \ F: r arg
      r> 0=  >r ZERO f< r> and  if  fnegate  then
;

\ --------------------------------------------------------------------

Public:

\ Compute approximate values for Bessel functions of the first kind of 
\ order one for arguments  |X| <= XMAX

: bes-J1 ( F: x -- result)
      fdup fabs  \ F: x |x|
      fdup XMAX  f>   if  f2drop ZERO        EXIT  then
      fdup EIGHT f>   if  fdrop 0 cal_JY1_8  EXIT  then
      fdup XSMALL f<= if  fdrop HALF f*      EXIT  then  
      fdrop cal_J1
;


\ Compute approximate values for Bessel functions of the second kind of 
\ order one for arguments 0 < X <= XMAX

: bes-Y1 ( F: x -- result)
      fdup fabs  \ F: x |x|
      fdup XMAX  f>   if  f2drop ZERO        EXIT  then
      fdup EIGHT f>   if  fdrop 1 cal_JY1_8  EXIT  then
      fdup XSMALL f<= if  PI2 fswap f/ fnegate fnip EXIT  then
      fswap cal_J1 cal_Y1
;


BASE !
END-MODULE

TEST-CODE? [IF] \ --------------------------------------------------------

\ Set the flag below to 1 to use ttester-xf, 0 for ttester
0 constant USE_TTESTER-XF

[UNDEFINED] T{  [IF] 
USE_TTESTER-XF [IF] s" ttester-xf.4th" [ELSE] s" ttester.4th"  [THEN]
included
[THEN]

BASE @
DECIMAL

USE_TTESTER-XF [IF]  \  setup for ttester-xf 

1e-17  FT-ABS-ERROR F!
1e-15  FT-REL-ERROR F!
set-ft-mode-rel0
: ?}t  }t ;
[ELSE]              \  setup for ttester

1e-17  abs-near f!
1e-15  rel-near f!   
set-near
: ?}t  r}t ;
[THEN]
\ Uncomment next line to see message when testing, or only errors are shown.
true VERBOSE !

cr 
TESTING bes-J0
t{  0e                   bes-J0  ->  1e                                           ?}t
t{  9.5367431640625e-06  bes-J0  ->  9.999999999772626324558060410228351074855e-1 ?}t
t{  9.765625e-4          bes-J0  ->  9.999997615814351092918387429216585220516e-1 ?}t
t{  9.9609375e-2         bes-J0  ->  9.975210309077554688485123283399960584208e-1 ?}t
t{  0.5e                 bes-J0  ->  9.384698072408129042284046735997126255689e-1 ?}t
t{  1.0e                 bes-J0  ->  7.651976865579665514497175261026632209093e-1 ?}t
t{  6.0e                 bes-J0  ->  1.506452572509969316623279489486898888492e-1 ?}t
t{ 10.0e                 bes-J0  -> -2.459357644513483351977608624853287538296e-1 ?}t

\ Check symmetry in the three distinct calculation regions
t{  -1.0e                bes-J0  ->  1.0e bes-J0 ?}t
t{  -6.0e                bes-J0  ->  6.0e bes-J0 ?}t
t{ -10.0e                bes-J0  -> 10.0e bes-J0 ?}t 

TESTING bes-Y0
t{  9.5367431640625e-06  bes-Y0  -> -7.433357103272405449088323013141542327764e0  ?}t
t{  9.765625e-4          bes-Y0  -> -4.486515076710973941241180629716879366110e0  ?}t
t{  9.9609375e-2         bes-Y0  -> -1.536766502510578857555155506190380232203e0  ?}t
t{  0.5e                 bes-Y0  -> -4.445187335067065571483984750683319103736e-1 ?}t
t{  1.0e                 bes-Y0  ->  8.825696421567695798292676602351516282782e-2 ?}t
t{ 10.0e                 bes-Y0  ->  5.567116728359939142445987741019004814513e-2 ?}t

TESTING bes-J1
t{  0e                   bes-J1  ->  0e ?}t
t{  9.5367431640625e-06  bes-J1  ->  4.768371581977039891375930210827028275865e-6 ?}t
t{  9.765625e-4          bes-J1  ->  4.882811917923413994971814547023652010972e-4 ?}t
t{  9.9609375e-2         bes-J1  ->  4.974294259629778646066291880417678867456e-2 ?}t
t{  0.5e                 bes-J1  ->  2.422684576748738863839545761415316408006e-1 ?}t
t{  1.0e                 bes-J1  ->  4.400505857449335159596822037189149131274e-1 ?}t
t{  6.0e                 bes-J1  -> -2.766838581275656081727748030461537587410e-1 ?}t
t{ 10.0e                 bes-J1  ->  4.347274616886143666974876802585928830627e-2 ?}t

\ Check symmetry in the three distinct calculation regions
t{  -1.0e                bes-J1  ->  1.0e bes-J1 fnegate ?}t
t{  -6.0e                bes-J1  ->  6.0e bes-J1 fnegate ?}t
t{ -10.0e                bes-J1  -> 10.0e bes-J1 fnegate ?}t

TESTING bes-Y1
t{ 9.5367431640625e-06  bes-Y1  -> -6.675442147997372602599872974994890140724e04 ?}t
t{ 9.765625e-4          bes-Y1  -> -6.519009930106311504739518761892958951438e02 ?}t
t{ 9.9609375e-2         bes-Y1  -> -6.483679333535285983038462105645461994814e0  ?}t
t{ 0.5e                 bes-Y1  -> -1.471472392670243069188584635323297453241e0  ?}t
t{ 1.0e                 bes-Y1  -> -7.812128213002887165471500000479648205499e-1 ?}t
t{ 10.0e                bes-Y1  -> 2.4901542420695388392328347466322280326042e-1 ?}t

BASE !
[THEN]


