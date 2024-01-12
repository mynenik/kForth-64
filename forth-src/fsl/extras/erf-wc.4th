\ erf
\
\   This module evaluates  erf(x),  erfc(x),  and  exp(x*x)*erfc(x)
\   for a real argument  x.
\
\ Provides:
\
\     ERF
\     ERFC
\     ERFCX
\
\ Intrinsic functions required are:
\
\     FABS  FLOOR  FEXP
\
\
\  Author: W. J. Cody
\          Mathematics and Computer Science Division
\          Argonne National Laboratory
\          Argonne, IL 60439
\
\  Ported to Forth-94 by Krishna Myneni, krishna.myneni@ccreweb.org
\
\  Revisions:
\    1990-03-19  ?   last modification to original Fortran source
\    2009-06-28  km; modified constant XBIG for double precision
\                    calculations.
\    2009-07-13  km; modified CALERF for proper argument order to
\                    integrated fp/data stack Forth systems.
\    2023-12-05  km; replaced FDUP F* with FSQUARE
\
\  Notes from original program:
\
\  1. Original Program at http://www.netlib.org/specfun/
\
\  2. The word  CALERF  is intended for internal use only,
\     all computations within the module being concentrated in this
\     word.  
\
\  3. The main computation evaluates near-minimax approximations
\     from "Rational Chebyshev approximations for the error function"
\     by W. J. Cody, Math. Comp., 1969, PP. 631-638.  This
\     transportable program uses rational functions that theoretically
\     approximate  erf(x)  and  erfc(x)  to at least 18 significant
\     decimal digits.  The accuracy achieved depends on the arithmetic
\     system, the compiler, the intrinsic functions, and proper
\     selection of the machine-dependent constants.
\
\  4. Explanation of machine-dependent constants
\
\   XMIN   = the smallest positive floating-point number.
\   XINF   = the largest positive finite floating-point number.
\   XNEG   = the largest negative argument acceptable to ERFCX;
\            the negative of the solution to the equation
\            2*exp(x*x) = XINF.
\   XSMALL = argument below which erf(x) may be represented by
\            2*x/sqrt(pi)  and above which  x*x  will not underflow.
\            A conservative value is the largest machine number X
\            such that   1.0 + X = 1.0   to machine precision.
\   XBIG   = largest argument acceptable to ERFC;  solution to
\            the equation:  W(x) * (1-0.5/x**2) = XMIN,  where
\            W(x) = exp(-x*x)/[x*sqrt(pi)].
\   XHUGE  = argument above which  1.0 - 1/(2*x*x) = 1.0  to
\            machine precision.  A conservative value is
\            1/[2*sqrt(XSMALL)]
\   XMAX   = largest acceptable argument to ERFCX; the minimum
\            of XINF and 1/[sqrt(pi)*XMIN].
\
\   Approximate values for some important machines are:
\
\                          XMIN       XINF        XNEG     XSMALL
\
\  CDC 7600      (S.P.)  3.13E-294   1.26E+322   -27.220  7.11E-15
\  CRAY-1        (S.P.)  4.58E-2467  5.45E+2465  -75.345  7.11E-15
\  IEEE (IBM/XT,
\    SUN, etc.)  (S.P.)  1.18E-38    3.40E+38     -9.382  5.96E-8
\  IEEE (IBM/XT,
\    SUN, etc.)  (D.P.)  2.23D-308   1.79D+308   -26.628  1.11D-16
\  IBM 195       (D.P.)  5.40D-79    7.23E+75    -13.190  1.39D-17
\  UNIVAC 1108   (D.P.)  2.78D-309   8.98D+307   -26.615  1.73D-18
\  VAX D-Format  (D.P.)  2.94D-39    1.70D+38     -9.345  1.39D-17
\  VAX G-Format  (D.P.)  5.56D-309   8.98D+307   -26.615  1.11D-16
\
\
\                          XBIG       XHUGE       XMAX
\
\  CDC 7600      (S.P.)  25.922      8.39E+6     1.80X+293
\  CRAY-1        (S.P.)  75.326      8.39E+6     5.45E+2465
\  IEEE (IBM/XT,
\    SUN, etc.)  (S.P.)   9.194      2.90E+3     4.79E+37
\  IEEE (IBM/XT,
\    SUN, etc.)  (D.P.)  26.543      6.71D+7     2.53D+307
\  IBM 195       (D.P.)  13.306      1.90D+8     7.23E+75
\  UNIVAC 1108   (D.P.)  26.582      5.37D+8     8.98D+307
\  VAX D-Format  (D.P.)   9.269      1.90D+8     1.70D+38
\  VAX G-Format  (D.P.)  26.569      6.71D+7     8.98D+307
\
\
\  5. Error returns
\
\     The program returns  ERFC = 0      for  ARG >= XBIG
\
\                          ERFCX = XINF  for  ARG <  XNEG
\      and
\                          ERFCX = 0     for  ARG >= XMAX
\
\

\ ------------------------------------------------------------------

BASE @
DECIMAL

[UNDEFINED] FTRUNC [IF]
: FTRUNC   ( r1 -- r2 )
      FDUP F0= 0=  IF 
	FDUP F0<  IF 
	  FNEGATE FLOOR FNEGATE
        ELSE    
          FLOOR
        THEN
      THEN    ;
[THEN]

VARIABLE JINT

FVARIABLE DEL
FVARIABLE RESULT
FVARIABLE X
FVARIABLE XDEN
FVARIABLE XNUM
FVARIABLE Y
FVARIABLE YSQ

\ ------------------------------------------------------------------
\  Mathematical constants
\ ------------------------------------------------------------------
4.0E0                     FCONSTANT  FOUR
1.0E0                     FCONSTANT  ONE
0.5E0                     FCONSTANT  HALF
2.0E0                     FCONSTANT  TWO
0.0E0                     FCONSTANT  ZERO
5.6418958354775628695E-1  FCONSTANT  SQRPI
0.46875E0                 FCONSTANT  THRESH
16.0E0                    FCONSTANT  SIXTEEN

\ ------------------------------------------------------------------
\  Machine-dependent constants
\ ------------------------------------------------------------------
1 FLOATS 4 = [IF]           \ Single precision
3.40E38   FCONSTANT  XINF
-9.382E0  FCONSTANT  XNEG
5.96E-8   FCONSTANT  XSMALL
9.194E0   FCONSTANT  XBIG
2.90E3    FCONSTANT  XHUGE
4.79E37   FCONSTANT  XMAX
[ELSE]                      \ Double precision
1.79E308  FCONSTANT  XINF
-26.628E0 FCONSTANT  XNEG
1.11E-16  FCONSTANT  XSMALL
27.5E0 ( 26.543E0)   FCONSTANT  XBIG
6.71E7    FCONSTANT  XHUGE
2.53E307  FCONSTANT  XMAX
[THEN]

\ ------------------------------------------------------------------
\  Coefficients for approximation to  erf  in first interval
\ ------------------------------------------------------------------
5 FLOAT ARRAY A{
3.16112374387056560E00
1.13864154151050156E02
3.77485237685302021E02
3.20937758913846947E03
1.85777706184603153E-1
5 A{ }fput

4 FLOAT ARRAY B{
2.36012909523441209E01
2.44024637934444173E02
1.28261652607737228E03
2.84423683343917062E03
4 B{ }fput

\ ------------------------------------------------------------------
\  Coefficients for approximation to  erfc  in second interval
\ ------------------------------------------------------------------
9 FLOAT ARRAY C{
5.64188496988670089E-1
8.88314979438837594E0
6.61191906371416295E01
2.98635138197400131E02
8.81952221241769090E02
1.71204761263407058E03
2.05107837782607147E03
1.23033935479799725E03
2.15311535474403846E-8
9 C{ }fput

8 FLOAT ARRAY D{
1.57449261107098347E01
1.17693950891312499E02
5.37181101862009858E02
1.62138957456669019E03
3.29079923573345963E03
4.36261909014324716E03
3.43936767414372164E03
1.23033935480374942E03
8 D{ }fput

\ ------------------------------------------------------------------
\  Coefficients for approximation to  erfc  in third interval
\ ------------------------------------------------------------------
6 FLOAT ARRAY P{
3.05326634961232344E-1
3.60344899949804439E-1
1.25781726111229246E-1
1.60837851487422766E-2
6.58749161529837803E-4
1.63153871373020978E-2
6 P{ }fput

5 FLOAT ARRAY Q{
2.56852019228982242E00
1.87295284992346047E00
5.27905102951428412E-1
6.05183413124413191E-2
2.33520497626869185E-3
5 Q{ }fput

\ ------------------------------------------------------------------
\  Fix up for negative argument, erf, etc.
\ ------------------------------------------------------------------
: NEG-ARG-FIXUP ( -- )
      JINT @ 0= IF
            HALF RESULT F@ F- HALF F+  RESULT F!
            X F@ F0< IF  RESULT F@ FNEGATE RESULT F! THEN
      ELSE 
	   JINT @ 1 =  IF
             X F@ F0< IF  TWO RESULT F@ F- RESULT F!  THEN
           ELSE
             X F@ F0< IF
               X F@ XNEG  F<  IF
                     XINF RESULT F!
               ELSE
                     X F@ SIXTEEN F* FTRUNC SIXTEEN F/  YSQ F!
                     X F@ YSQ F@ F-  X F@ YSQ F@ F+  F*  DEL F!
                     YSQ F@ FSQUARE FEXP  DEL F@ FEXP  F*  Y F!
                     Y F@ FDUP F+ RESULT F@ F-  RESULT F!
               THEN
             THEN
	   THEN
      THEN
;


: CALERF ( F: ARG -- RESULT ) ( JINT -- )
      JINT !
      X F!
      X F@ FABS Y F!
      Y F@ THRESH  F<=  IF
\ ------------------------------------------------------------------
\  Evaluate  erf  for  |X| <= 0.46875
\ ------------------------------------------------------------------
        ZERO  YSQ F!
        Y F@ XSMALL F>  IF  Y F@ FSQUARE  YSQ F!  THEN
        A{ 4 } F@ YSQ F@ F*  XNUM F!
        YSQ F@  XDEN F!
        3 0 DO 
          XNUM F@ A{ I } F@ F+  YSQ F@ F*  XNUM F!
          XDEN F@ B{ I } F@ F+  YSQ F@ F*  XDEN F!
   	LOOP
        XNUM F@ A{ 3 } F@ F+  XDEN F@ B{ 3 } F@ F+  F/  X F@ F*  RESULT F!
        JINT @ IF  ONE RESULT F@ F-  RESULT F!  THEN
        JINT @ 2 = IF  YSQ F@ FEXP RESULT F@ F*  RESULT F! THEN
\ ------------------------------------------------------------------
\  Evaluate  erfc  for 0.46875 <= |X| <= 4.0
\ ------------------------------------------------------------------
      ELSE 
	Y F@ FOUR F<=  IF
          C{ 8 } F@ Y F@ F*  XNUM F!
          Y F@  XDEN F!
          7 0 DO 
            XNUM F@ C{ I } F@ F+  Y F@ F*  XNUM F!
            XDEN F@ D{ I } F@ F+  Y F@ F*  XDEN F!
          LOOP
          XNUM F@ C{ 7 } F@ F+  XDEN F@ D{ 7 } F@ F+  F/  RESULT F!
          JINT @ 2 <> IF
            Y F@ SIXTEEN F* FTRUNC SIXTEEN F/  YSQ F!
            Y F@ YSQ F@ F- Y F@ YSQ F@ F+  F*  DEL F!
            YSQ F@ FSQUARE FNEGATE FEXP  DEL F@ FNEGATE FEXP F* 
            RESULT F@ F*  RESULT F!
          THEN
\ ------------------------------------------------------------------
\  Evaluate  erfc  for |X| > 4.0
\ ------------------------------------------------------------------
        ELSE
          ZERO  RESULT F!
          Y F@  XBIG F>= IF
            JINT @ 2 <>  Y F@ XMAX F>=  OR IF  
	      NEG-ARG-FIXUP  RESULT F@ EXIT
	    THEN
            Y F@ XHUGE F>=  IF
              SQRPI Y F@ F/  RESULT F!
              NEG-ARG-FIXUP  RESULT F@ EXIT
            THEN
          THEN
          ONE Y F@ FSQUARE F/  YSQ F!
          P{ 5 } F@ YSQ F@ F*  XNUM F!
          YSQ F@  XDEN F!
          4 0 DO 
            XNUM F@ P{ I } F@ F+  YSQ F@ F*  XNUM F!
            XDEN F@ Q{ I } F@ F+  YSQ F@ F*  XDEN F!
          LOOP
          YSQ F@  XNUM F@ P{ 4 } F@ F+  F*  XDEN F@ Q{ 4 } F@ F+  F/ RESULT F!
          SQRPI RESULT F@ F-  Y F@ F/  RESULT F!
          JINT @ 2 <>  IF
            Y F@  SIXTEEN F* FTRUNC SIXTEEN F/  YSQ F!
            Y F@ YSQ F@ F-  Y F@ YSQ F@ F+  F*  DEL F!
            YSQ F@ FSQUARE FNEGATE FEXP  
	    DEL F@ FNEGATE FEXP F* RESULT F@ F*  RESULT F!
          THEN
        THEN
	NEG-ARG-FIXUP
      THEN
      RESULT F@ 
;


\ --------------------------------------------------------------------
\
\ This subprogram computes approximate values for erf(x).
\   (see comments heading CALERF).
\
\   Author/date: W. J. Cody, January 8, 1985
\
\ --------------------------------------------------------------------
: ERF ( F: X -- result ) 
	FDUP FABS THRESH F<= IF
	  0 CALERF 
	ELSE
	  1 CALERF
	  ONE FSWAP F-
	THEN	
;

\ --------------------------------------------------------------------
\
\ This subprogram computes approximate values for erfc(x).
\   (see comments heading CALERF).
\
\   Author/date: W. J. Cody, January 8, 1985
\
\ --------------------------------------------------------------------
: ERFC ( F: X -- result )
	1 CALERF 
;

\ ------------------------------------------------------------------
\
\ This subprogram computes approximate values for exp(x*x) * erfc(x).
\   (see comments heading CALERF).
\
\   Author/date: W. J. Cody, March 30, 1987
\
\ ------------------------------------------------------------------
: ERFCX ( F: X -- result )  2 CALERF  ;

BASE !

TEST-CODE? [IF]
[undefined] T{ [IF] include ttester  [THEN]

1e-15 rel-near F!
set-near
\ Reference values generated from extended precision calculations
\   by APH using the MPFR library. 

CR
TESTING ERF

t{  0e    erf  ->   0e  		                          r}t
t{  0.1e  erf  ->   1.124629160182848922032750717439683832217e-1  r}t
t{  0.2e  erf  ->   2.227025892104784541401390068001438163883e-1  r}t
t{  0.3e  erf  ->   3.286267594591274276389140478667565511699e-1  r}t
t{  0.4e  erf  ->   4.283923550466684551036038453201724441219e-1  r}t
t{  0.5e  erf  ->   5.204998778130465376827466538919645287365e-1  r}t
t{  1.0e  erf  ->   8.427007929497148693412206350826092592961e-1  r}t
t{  1.5e  erf  ->   9.661051464753107270669762616459478586814e-1  r}t
t{  2.0e  erf  ->   9.953222650189527341620692563672529286109e-1  r}t
t{  2.5e  erf  ->   9.995930479825550410604357842600250872797e-1  r}t
t{  3.0e  erf  ->   9.999779095030014145586272238704176796202e-1  r}t
t{  3.5e  erf  ->   9.999992569016276585872544763162439043643e-1  r}t 
t{  4.0e  erf  ->   9.999999845827420997199811478403265131160e-1  r}t

t{ -0.1e  erf  ->   0.1e  erf  fnegate  r}t
t{ -1.0e  erf  ->   1.0e  erf  fnegate  r}t


TESTING ERFC

t{  4.00e  erfc  ->  1.541725790028001885215967348688404857215e-8    r}t
t{  4.50e  erfc  ->  1.966160441542887476279160367664332660578e-10   r}t
t{  5.00e  erfc  ->  1.537459794428034850188343485383378890118e-12   r}t
t{  5.50e  erfc  ->  7.357847917974398063068362398570090208223e-15   r}t
t{  6.00e  erfc  ->  2.151973671249891311659335039918738463048e-17   r}t
t{  6.50e  erfc  ->  3.842148327120647469875804543768776621449e-20   r}t
t{  7.00e  erfc  ->  4.183825607779414398614010223899932250030e-23   r}t
t{  7.50e  erfc  ->  2.776649386030569100663966209322412586740e-26   r}t
t{  8.00e  erfc  ->  1.122429717298292707996788844317027909343e-29   r}t
t{  8.50e  erfc  ->  2.762324071333771446134502930057782220140e-33   r}t
t{  9.00e  erfc  ->  4.137031746513810238053903467362524595710e-37   r}t
t{  9.50e  erfc  ->  3.769214485654879941677087321047321969621e-41   r}t
t{ 1.00e1  erfc  ->  2.088487583762544757000786294957788611561e-45   r}t
t{ 1.05e1  erfc  ->  7.035928090177522686735314989983875191751e-50   r}t
t{ 1.10e1  erfc  ->  1.440866137943694680339809702856082753964e-54   r}t
t{ 1.15e1  erfc  ->  1.793309643576782058109116063975786076405e-59   r}t
t{ 1.20e1  erfc  ->  1.356261169205904212780306156590417572667e-64   r}t
t{ 1.25e1  erfc  ->  6.231942781979911006139549129089687366380e-70   r}t
t{ 1.30e1  erfc  ->  1.739557315466724521804198548243026985089e-75   r}t
t{ 1.35e1  erfc  ->  2.949433113257988264759187435938438926110e-81   r}t
t{ 1.40e1  erfc  ->  3.037229847750311665115172806783328447912e-87   r}t
t{ 1.45e1  erfc  ->  1.899395941979503049574200023929227908760e-93   r}t
t{ 1.50e1  erfc  ->  7.212994172451206666565066558692927109934e-100  r}t
t{ 1.55e1  erfc  ->  1.663201640048872334149102741177324070423e-106  r}t
t{ 1.60e1  erfc  ->  2.328485751571530693364872854573442597534e-113  r}t
t{ 1.65e1  erfc  ->  1.979130575553267972057334325050809148358e-120  r}t
t{ 1.70e1  erfc  ->  1.021228015094260881145599235077652994402e-127  r}t
t{ 1.75e1  erfc  ->  3.198863812343480988193469195296936871692e-135  r}t
t{ 1.80e1  erfc  ->  6.082369231816399307668466715702274949588e-143  r}t
t{ 1.85e1  erfc  ->  7.019961574985679324600020297239088904740e-151  r}t
t{ 1.90e1  erfc  ->  4.917722839256475446413297625239608170931e-159  r}t
t{ 1.95e1  erfc  ->  2.090954147922729460496243175316188288743e-167  r}t
t{ 2.00e1  erfc  ->  5.395865611607900928934999167905345604088e-176  r}t
t{ 2.05e1  erfc  ->  8.450842369572458394324668950605102484119e-185  r}t
t{ 2.10e1  erfc  ->  8.032453871022455669021356947138268888968e-194  r}t
t{ 2.15e1  erfc  ->  4.633336539658445649129685587506432913376e-203  r}t
t{ 2.20e1  erfc  ->  1.621905860933472513052034647026123265178e-212  r}t
t{ 2.25e1  erfc  ->  3.445348860464601762032717331402956086707e-222  r}t
t{ 2.30e1  erfc  ->  4.441265948088057244074884428946738565069e-232  r}t
t{ 2.35e1  erfc  ->  3.474059495649971502741911545224997354591e-242  r}t
t{ 2.40e1  erfc  ->  1.648982583151933514218512437543746903943e-252  r}t
t{ 2.45e1  erfc  ->  4.749361264067378997552878283177710144873e-263  r}t
t{ 2.50e1  erfc  ->  8.300172571196522752044012769513722768714e-274  r}t
t{ 2.55e1  erfc  ->  8.801662690727950571267149831749167485576e-285  r}t
t{ 2.60e1  erfc  ->  5.663192408856142846475727896926092580329e-296  r}t
t{ 2.65e1  erfc  ->  2.210907664263734275929239022915826039075e-307  r}t
t{ 2.70e1  erfc  ->  5.237048923789255685016067682849547090934e-319  r}t
t{ 2.75e1  erfc  ->  7.526685450446576390019421308136851786684e-331  r}t
t{ 2.80e1  erfc  ->  6.563215840328784152380910481606274774134e-343  r}t
t{ 2.85e1  erfc  ->  3.472324842773765004803444205414833803922e-355  r}t
t{ 2.90e1  erfc  ->  1.114576716822273502962178302814958361364e-367  r}t
t{ 2.95e1  erfc  ->  2.170606033898513863258927438981864795715e-380  r}t
t{ 3.00e1  erfc  ->  2.564656203756111600033397277501447146549e-393  r}t

[THEN]
