\ Low and High Accuracy Calculations of the Error Function and
\   Complementary Error Function for real values.

\ Forth Scientific Library Algorithm #62

\ Environmental dependences:
\
\ 1. requires FLOATING and FLOATING EXT wordsets
\ 2. supports unified or separate floating point stack
\ 
\ Provides:
\
\  ERF1
\  ERFC1
\  ERF
\  ERFC
\
\ compiled by Krishna Myneni from postings on comp.lang.forth by 
\ Andrew P. Haley, Charles G. Montgomery, and Marcel A. Hendrix 
\ Thread Root Message ID: <gPTPl.42433$v8.19515@bignews3.bellsouth.net>
\
\ Disclaimer:
\
\ THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
\ IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
\ WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
\ DISCLAIMED. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY DIRECT,
\ INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
\ (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
\ SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
\ HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
\ STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
\ IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
\ POSSIBILITY OF SUCH DAMAGE.
\
\ Notes:
\
\   1. The faster, lower accuracy methods are provided by ERF1 and ERF1C.
\      The slower, higher accuracy methods are provided by ERF and ERFC. 
\      Errors for the provided words are given below, measured on a double 
\      precision IEEE floating point system:
\
\      ERF1 : 
\         -6 <= x <= 10.0, maximum relative error < 6e-4
\ 
\      ERFC1:
\         -6 <= x <= 1.0,    max. rel. error < 2e-5
\                            max. abs. error < 3e-5
\
\          1.0 <= x <= 10.0, max. rel. error < 2e-1
\                            max. abs. error < 3e-5
\
\      ERF:
\         -6 <= x <= 10.0,   max. rel. error < 4e-16
\
\      ERFC:
\         -6 <= x <= 10.0,   max. rel. error < 4e-15 
\
\   2. The test code checks for an upper bound on relative nearness, 
\      not relative error.
\
\ References:
\
\ [1] M. Abramowitz and I. A. Stegun, Handbook of Mathematical Functions
\     with Formulas, Graphs, and Mathematical Tables, Dover, New York,
\     1964; 7.1.25
\ 
\ [2] C. W. Clenshaw, Chebyshev Series for Mathematical Functions,
\     Mathematical Tables, vol. 5, National. Physical Laboratory, H.M.S.O.,
\     London, 1962 
\
\ [3] http://en.wikipedia.org/wiki/Clenshaw_algorithm
\
\ Revisions:
\   2009-07-23  km  use APH's revised segmentation for calculation of
\                   ERF and ERFC, to avoid numerical loss of precision
\                   in calculations across entire domain; revised
\                   maximum relative error for ERF1 based on tests.
\   2009-08-09  km  revised comments to conform to FSL requirements.
\                   Version 1.0.
\   2011-01-12  km  uncommented definition of ERFC1; revised comments 
\                   to give errors for ERF1, ERFC1, ERF, ERFC; ver 1.02
\   2011-01-13  km  minor mods for use with kForth
\   2011-09-16  km  use Neal Bridges' anonymous module interface.
\   2012-02-19  km  use KM/DNW's modules library 
CR .( ERF               V1.03     19 February  2012 )

BEGIN-MODULE

BASE @
DECIMAL

Public:

\ Low accuracy method based on rational approximation [1].
\ Charles G. Montgomery 20 May 2009 placed in public domain

: fff ( f: x y z -- x x*[y+z] ) \ factor for Horner polynomial
  F+ FOVER F*  ;

\ The auxiliary func1 may be what you really need for some things.
: func1 ( f: x -- r )  \ exp(x*x)*erfc(x) for non-negative x
  0.47047e F* 1.0e F+ 1.0e FSWAP F/
  0.0E 0.7478556e fff -0.0958798e fff 0.3480242E fff
  FSWAP FDROP  ;

\ Error function for positive real arguments 
: erfc1_pos ( f: x -- erfc[x] ) \ for non-negative x only; abs error <= 2.5e-5
    FDUP func1 FSWAP FDUP F* FNEGATE FEXP F* ; ( erfc[x] )
 
: erfc1 ( f: x -- erfc[x] ) \ for all x, using erfc(-x) = 2 - erfc(x)
    FDUP F0<  >R FABS erfc1_pos  R> IF  2e FSWAP F-  THEN ;
 
: erf1_pos ( f: x -- erf[x] ) \ for non-negative x only; rel error <= 1e-4
    erfc1_pos FNEGATE 1.0e F+  ;  \ erf(x) = 1 - erfc(x)

: erf1 ( f: x -- erf[x] ) \ for all x, using erf(-x) = -erf(x)
    FDUP F0<  >R FABS erf1_pos   R> IF  FNEGATE  THEN ;


\ High-accuracy method based on Chebyshev polynomials. 
\ by Andrew P. Haley, and placed in public domain.
\
\ Clenshaw [2] gives Chebyshev coefficients for
\ 
\    erf(x) = x/4 * sum(k=0..N) { a[2k] * T[2k](x/4) }  -4 <= x <= 4
\ 
\ and
\ 
\    erfc(x) = exp(-x2)/(x*sqrt pi) * sum(k=0..N) { a[2k] * T[2k](4/x) }
\                                                 x >= 4
\ 
\ where erfc(x) = 1 - erf(x)
\ 
\
\ To obtain a less precise but faster approximation to these
\ functions the Chebyshev series may be truncated.
\
\ We use Clenshaw's coefficients for erfc x >= 4, but use specially
\ generated approximations in the ranges -2 <= x <= 2 for erf and for
\ erfc in the range 2 <= x <= 4.



\ Evaluate a series in Chebyshev polynomials of the first kind.
\
\ Clenshaw's recurrence is [3]:
\
\    b[r] = 2x*b[r+1] - b[r+2] + a[r]
\
\    f[x] = 1/2 (b[0] - b[2])
\
\ a0 is address of the zeroth coefficient, an the last.  The zeroth
\ coefficient in the table should be divided by two.
\
\ You can replace the use of allocate in this word with a
\ floating-point local if your system supports them.

Private:

fvariable 2x
0 ptr a0
0 ptr aN

Public:

: chebev ( x a0 aN -- y)   \  ( a0 aN -- ) ( F: x - y)
    to aN  to a0
    2.0e0 f* 2x f!
    0.0e fdup
    a0 1 floats +  aN do
	( b[r+2] b[r+1] )
	fdup  2x f@ f*
	frot f-
	i f@ f+
    -1 floats +loop
    2x f@ 2.0e0 f/ f*  fswap f-  a0 f@ f+
;


\ The last few coefficients for erf are removed because they don't
\ contribute much useful accuracy.  If you're using IEEE double
\ precision, which has at best 16.25 decimal digits, you can remove
\ the last few coefficients without significant loss of accuracy.

24 FLOAT ARRAY erf_coeffs{
     +2.96622112816960724611e+00 2.0e f/ 
     -6.02142146773189901654e-01 
     +1.37989661379663136323e-01 
     -2.78325425294443761376e-02 
     +4.84159904486692746016e-03 
     -7.31727937169617309608e-04 
     +9.72419688646380992648e-05 
     -1.14985131160713699893e-05 
     +1.22264871568695297335e-06 
     -1.17982030625916872056e-07 
     +1.04140181841372967700e-08 
     -8.46595175993108677117e-10 
     +6.37622701329835012648e-11 
     -4.47231003766536866963e-12 
     +2.93465969598216991847e-13 
     -1.80880039707634947850e-14 
     +1.05096274309418376464e-15 
     -5.77485224456989086893e-17 
\    +3.00957037511526508273e-18 
\    -1.49145785641888477345e-19 
\    +7.04512761980799395177e-21 
18 erf_coeffs{ }fput
erf_coeffs{  0 }  ptr  erf_coeffs
erf_coeffs{ 17 }  ptr  /erf_coeff

\    erfc(x) = exp(-x2)/(x*sqrt pi) * sum(k=0..N) { a[2k] * T[2k](4/x) }
\                                                 x >= 4
\ 
\    From Clenshaw

18 FLOAT ARRAY erfc_coeffs{
    +1.97070527225754492387e0 2.0e f/ 
    -0.01433974027177497552e0 
    +0.00029736169220261895e0 
    -0.00000980351604336237e0 
    +0.00000043313342034728e0 
    -0.00000002362150026241e0 
    +0.00000000151549676581e0 
    -0.00000000011084939856e0 
    +0.00000000000904259014e0 
    -0.00000000000080947054e0 
    +0.00000000000007853856e0 
    -0.00000000000000817918e0 
    +0.00000000000000090715e0 
    -0.00000000000000010646e0 
    +0.00000000000000001315e0 
    -0.00000000000000000170e0 
\   +0.00000000000000000023e0 
\   -0.00000000000000000003e0 
16 erfc_coeffs{ }fput
erfc_coeffs{  0 }  ptr  erfc_coeffs
erfc_coeffs{ 15 }  ptr  /erfc_coeff

\ erfc(x) = exp(-x2)/(x*sqrt pi) * sum(k=0..N) { a[k] * T[k](x-3) }
\                                 2 <= x <= 4
\
\ Coefficients specially generated for this program.

24 FLOAT ARRAY erfc_coeffs2{
     +1.89055402018135235557e+00 2.0e f/ 
     +3.17049565101290913120e-02 
     -6.73843163544725938991e-03 
     +1.23559784757597021029e-03 
     -2.06258409386934785687e-04 
     +3.21465835918538975707e-05 
     -4.74521240392225710897e-06 
     +6.69458188091390037841e-07 
     -9.08366988906448634126e-08 
     +1.19085967623897923140e-08 
     -1.51371242892998039880e-09 
     +1.87074264411699517115e-10 
     -2.25295145776339602484e-11 
     +2.64893125290031939759e-12 
     -3.04550625183817820911e-13 
     +3.42854718946481738893e-14 
     -3.78388196540724875713e-15 
     +4.09821531703203301077e-16 
     -4.35997253185852896000e-17 
     +4.55999402005552146398e-18 
\    -4.69202690718497228320e-19 
\    +4.75298359746767356516e-20 
\    -4.74296215874657703189e-21 
20 erfc_coeffs2{ }fput
erfc_coeffs2{  0 }  ptr  erfc_coeffs2
erfc_coeffs2{ 19 }  ptr  /erfc_coeff2

1.0e0 fasin 2.0e0 f* fsqrt fconstant sqrt(pi)

\ The real axis is split into three intervals:
\
\   domain 1:  x < -2
\   domain 2:  -2 <= x < 2
\   domain 3:  x >= 2
\
\ erf(x) and erfc(x) are computed in the three domains, using
\ the high-precision words for erfc(x) in domain 3, and erf(x)
\ in domain 2, and the relations between erfc(x), erf(x), and
\ erfc(-x) and erf(-x).


\ erf(x), domain 2: -2 <= x < 2
: erf_d2 ( F: x -- y)
   2.0e0 f/  fdup
   fdup f* 2.0e0 f* 1.0e0 f-  
   erf_coeffs /erf_coeff chebev

   f* ;


\ erfc(x), domain 3: x >= 2

: erfc_d3 ( F: x -- y)

    fdup
    fdup f* fnegate fexp  fover sqrt(pi) f* f/  fswap 

    fdup 4.0e f> if
      4.0e0 fswap f/
      fdup f* 2.0e0 f* 1.0e0 f-
      erfc_coeffs /erfc_coeff chebev
    else
      3.0e f-
      erfc_coeffs2 /erfc_coeff2 chebev
    then
    
    f* ;

: erf_d1 ( F: x -- y)
    \ Compute erfc in domain 3; Use erf(-x) = -erf(x) = erfc(x) - 1
    fabs erfc_d3 1e f-
;

: erf_d3 ( F: x -- y)
   \ Compute erfc in domain 3; Use erf(x) = 1 - erfc(x)
   erfc_d3 1e fswap f-
;

: erfc_d2 ( F: x -- y)
   \ Compute erf in domain 2; Use erfc(x) = 1 - erf(x)
   erf_d2 1e fswap f-
;

: erfc_d1 ( F: x -- y)
   \ Compute erfc in domain 3; Use erfc(-x) = 2 - erfc(x)
   fabs erfc_d3 2e fswap f-
;

: erf ( F: x -- y)
   fdup -2e f< IF  erf_d1
   ELSE fdup 2e f< IF erf_d2  ELSE  erf_d3  THEN
   THEN
;

: erfc ( F: x -- y)
   fdup -2e f< IF  erfc_d1
   ELSE fdup 2e f< IF erfc_d2  ELSE  erfc_d3  THEN
   THEN
;


BASE !
END-MODULE

TEST-CODE? [IF]
[undefined] T{ [IF] s" ttester.4th" included  [THEN]
BASE @
DECIMAL

1e-4 rel-near F!
set-near

CR
TESTING ERF1
t{  0e    erf1  ->   0e  	    r}t
t{  0.1e  erf1  ->   1.12462916e-1  r}t
t{  0.2e  erf1  ->   2.22702589e-1  r}t
t{  0.3e  erf1  ->   3.28626759e-1  r}t
t{  0.4e  erf1  ->   4.28392355e-1  r}t
t{  0.5e  erf1  ->   5.20499878e-1  r}t
t{  1.0e  erf1  ->   8.42700793e-1  r}t
t{  1.5e  erf1  ->   9.66105146e-1  r}t
t{  2.0e  erf1  ->   9.95322265e-1  r}t
t{  2.5e  erf1  ->   9.99593048e-1  r}t
t{  3.0e  erf1  ->   9.99977910e-1  r}t
t{  3.5e  erf1  ->   9.99999257e-1  r}t 
t{  4.0e  erf1  ->   9.99999984e-1  r}t

t{ -0.1e  erf  ->   0.1e  erf  fnegate  r}t
t{ -1.0e  erf  ->   1.0e  erf  fnegate  r}t

1e-15 rel-near F!
set-near
\ Reference values generated from extended precision calculations
\   by APH using the MPFR library. 

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

BASE !
[THEN]

