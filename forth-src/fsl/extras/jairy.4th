\ jairy.4th
\
\ Compute the Airy function and the derivative of the Airy function.
\
\ The original Fortran subroutine JAIRY source is taken from
\ the collected algorithms of the ACM. See algorithm 511 at
\ http://www.netlib.org/toms/
\
\ Below are the original comments from the source. Some of these
\ comments are not relevant to this implementation, for example, 
\ this Forth version is standalone, and does not require external
\ routines such as JBESS to compute parameters.
\
\
\      SUBROUTINE JAIRY(X, RX, C, AI, DAI)                JAI   10
\
\     CDC 6600 ROUTINE
\     1-2-74
\
\                  JAIRY COMPUTES THE AIRY FUNCTION AI(X)
\                   AND ITS DERIVATIVE DAI(X) FOR JBESS
\
\                                   INPUT
\
\         X - ARGUMENT, COMPUTED BY JBESS, X.LE.(ELIM2*1.5)**(2./3.)
\        RX - RX=SQRT(ABS(X)), COMPUTED BY JBESS
\         C - C=2.*(ABS(X)**1.5)/3., COMPUTED BY JBESS
\
\                                  OUTPUT
\
\        AI - VALUE OF FUNCTION AI(X)
\       DAI - VALUE OF THE DERIVATIVE DAI(X)
\
\                                WRITTEN BY
\
\                               D. E. AMOS
\                               S. L. DANIEL
\                               M. K. WESTON
\
\ ---------------------------------------------------------------
\ Ported to Forth-94 by Krishna Myneni, http://ccreweb.org
\
\ Forth version requires:
\
\   modules.4th
\   fsl-util.4th
\   ttester.4th  (to run test code only)
\
\ Revisions:
\   2013-04-14 km  first version, 1.0
   
Begin-Module

Private:

14 constant N1
23 constant N2
19 constant N3
15 constant N4

12 constant M1
21 constant M2
17 constant M3
13 constant M4


1.30899693899575E+00  fconstant FPI12
5.03154716196777E+00  fconstant CON2
3.80004589867293E-01  fconstant CON3
8.33333333333333E-01  fconstant CON4
8.66025403784439E-01  fconstant CON5


14 FLOAT ARRAY ak1{
 2.20423090987793E-01
-1.25290242787700E-01
 1.03881163359194E-02
 8.22844152006343E-04
-2.34614345891226E-04
 1.63824280172116E-05
 3.06902589573189E-07
-1.29621999359332E-07
 8.22908158823668E-09
 1.53963968623298E-11
-3.39165465615682E-11
 2.03253257423626E-12
-1.10679546097884E-14
-5.16169497785080E-15
14 ak1{ }fput


23 float array ak2{
 2.74366150869598E-01
 5.39790969736903E-03
-1.57339220621190E-03
 4.27427528248750E-04
-1.12124917399925E-04
 2.88763171318904E-05
-7.36804225370554E-06
 1.87290209741024E-06
-4.75892793962291E-07
 1.21130416955909E-07
-3.09245374270614E-08
 7.92454705282654E-09
-2.03902447167914E-09
 5.26863056595742E-10
-1.36704767639569E-10
 3.56141039013708E-11
-9.31388296548430E-12
 2.44464450473635E-12
-6.43840261990955E-13
 1.70106030559349E-13
-4.50760104503281E-14
 1.19774799164811E-14
-3.19077040865066E-15
23 ak2{ }fput


14 float array ak3{
 2.80271447340791E-01
-1.78127042844379E-03
 4.03422579628999E-05
-1.63249965269003E-06
 9.21181482476768E-08
-6.52294330229155E-09
 5.47138404576546E-10
-5.24408251800260E-11
 5.60477904117209E-12
-6.56375244639313E-13
 8.31285761966247E-14
-1.12705134691063E-14
 1.62267976598129E-15
-2.46480324312426E-16
14 ak3{ }fput


19 float array ajp{
 7.78952966437581E-02
-1.84356363456801E-01
 3.01412605216174E-02
 3.05342724277608E-02
-4.95424702513079E-03
-1.72749552563952E-03
 2.43137637839190E-04
 5.04564777517082E-05
-6.16316582695208E-06
-9.03986745510768E-07
 9.70243778355884E-08
 1.09639453305205E-08
-1.04716330588766E-09
-9.60359441344646E-11
 8.25358789454134E-12
 6.36123439018768E-13
-4.96629614116015E-14
-3.29810288929615E-15
 2.35798252031104E-16
19 ajp{ }fput


19 float array ajn{
 3.80497887617242E-02
-2.45319541845546E-01
 1.65820623702696E-01
 7.49330045818789E-02
-2.63476288106641E-02
-5.92535597304981E-03
 1.44744409589804E-03
 2.18311831322215E-04
-4.10662077680304E-05
-4.66874994171766E-06
 7.15218807277160E-07
 6.52964770854633E-08
-8.44284027565946E-09
-6.44186158976978E-10
 7.20802286505285E-11
 4.72465431717846E-12
-4.66022632547045E-13
-2.67762710389189E-14
 2.36161316570019E-15
19 ajn{ }fput


15 float array a{
 4.90275424742791E-01
 1.57647277946204E-03
-9.66195963140306E-05
 1.35916080268815E-07
 2.98157342654859E-07
-1.86824767559979E-08
-1.03685737667141E-09
 3.28660818434328E-10
-2.57091410632780E-11
-2.32357655300677E-12
 9.57523279048255E-13
-1.20340828049719E-13
-2.90907716770715E-15
 4.55656454580149E-15
-9.99003874810259E-16
15 a{ }fput


15 float array b{
 2.78593552803079E-01
-3.52915691882584E-03
-2.31149677384994E-05
 4.71317842263560E-06
-1.12415907931333E-07
-2.00100301184339E-08
 2.60948075302193E-09
-3.55098136101216E-11
-3.50849978423875E-11
 5.83007187954202E-12
-2.04644828753326E-13
-1.10529179476742E-13
 2.87724778038775E-14
-2.88205111009939E-15
-3.32656311696166E-16
15 b{ }fput


14 constant  N1D
24 constant  N2D
19 constant  N3D
15 constant  N4D

12 constant  M1D
22 constant  M2D
17 constant  M3D
13 constant  M4D


14 float array dak1{
 2.04567842307887E-01
-6.61322739905664E-02
-8.49845800989287E-03
 3.12183491556289E-03
-2.70016489829432E-04
-6.35636298679387E-06
 3.02397712409509E-06
-2.18311195330088E-07
-5.36194289332826E-10
 1.13098035622310E-09
-7.43023834629073E-11
 4.28804170826891E-13
 2.23810925754539E-13
-1.39140135641182E-14
14 dak1{ }fput


24 float array dak2{
 2.93332343883230E-01
-8.06196784743112E-03
 2.42540172333140E-03
-6.82297548850235E-04
 1.85786427751181E-04
-4.97457447684059E-05
 1.32090681239497E-05
-3.49528240444943E-06
 9.24362451078835E-07
-2.44732671521867E-07
 6.49307837648910E-08
-1.72717621501538E-08
 4.60725763604656E-09
-1.23249055291550E-09
 3.30620409488102E-10
-8.89252099772401E-11
 2.39773319878298E-11
-6.48013921153450E-12
 1.75510132023731E-12
-4.76303829833637E-13
 1.29498241100810E-13
-3.52679622210430E-14
 9.62005151585923E-15
-2.62786914342292E-15
24 dak2{ }fput


14 float array dak3{
 2.84675828811349E-01
 2.53073072619080E-03
-4.83481130337976E-05
 1.84907283946343E-06
-1.01418491178576E-07
 7.05925634457153E-09
-5.85325291400382E-10
 5.56357688831339E-11
-5.90889094779500E-12
 6.88574353784436E-13
-8.68588256452194E-14
 1.17374762617213E-14
-1.68523146510923E-15
 2.55374773097056E-16
14 dak3{ }fput


19 float array dajp{
 6.53219131311457E-02
-1.20262933688823E-01
 9.78010236263823E-03
 1.67948429230505E-02
-1.97146140182132E-03
-8.45560295098867E-04
 9.42889620701976E-05
 2.25827860945475E-05
-2.29067870915987E-06
-3.76343991136919E-07
 3.45663933559565E-08
 4.29611332003007E-09
-3.58673691214989E-10
-3.57245881361895E-11
 2.72696091066336E-12
 2.26120653095771E-13
-1.58763205238303E-14
-1.12604374485125E-15
 7.31327529515367E-17
19 dajp{ }fput


19 float array dajn{
 1.08594539632967E-02
 8.53313194857091E-02
-3.15277068113058E-01
-8.78420725294257E-02
 5.53251906976048E-02
 9.41674060503241E-03
-3.32187026018996E-03
-4.11157343156826E-04
 1.01297326891346E-04
 9.87633682208396E-06
-1.87312969812393E-06
-1.50798500131468E-07
 2.32687669525394E-08
 1.59599917419225E-09
-2.07665922668385E-10
-1.24103350500302E-11
 1.39631765331043E-12
 7.39400971155740E-14
-7.32887475627500E-15
19 dajn{ }fput


15 float array da{
 4.91627321104601E-01
 3.11164930427489E-03
 8.23140762854081E-05
-4.61769776172142E-06
-6.13158880534626E-08
 2.87295804656520E-08
-1.81959715372117E-09
-1.44752826642035E-10
 4.53724043420422E-11
-3.99655065847223E-12
-3.24089119830323E-13
 1.62098952568741E-13
-2.40765247974057E-14
 1.69384811284491E-16
 8.17900786477396E-16
15 da{ }fput


15 float array db{
-2.77571356944231E-01
 4.44212833419920E-03
-8.42328522190089E-05
-2.58040318418710E-06
 3.42389720217621E-07
-6.24286894709776E-09
-2.36377836844577E-09
 3.16991042656673E-10
-4.40995691658191E-12
-5.18674221093575E-12
 9.64874015137022E-13
-4.90190576608710E-14
-1.77253430678112E-14
 5.55950610442662E-15
-7.11793337579530E-16
15 db{ }fput


fvariable ai
fvariable c
fvariable cv
fvariable ccv
fvariable csv
fvariable dai
fvariable e1
fvariable e2
fvariable ec
fvariable f1
fvariable f2
fvariable rx
fvariable rtrx
fvariable scv
fvariable t
fvariable tt
fvariable temp1
fvariable temp2
fvariable x

variable jj

\ Airy function for x > 0, c > 5
: jairy-pos-cgt5 ( -- )
\   60 CONTINUE

      10e c f@ f/ 1e f- t f!             \ T = 10./C - 1.
      t f@ fdup f+ tt f!                 \ TT = T + T
      N1 1- jj !                         \ J = N1
      ak3{ jj @ } f@ f1 f!               \ F1 = AK3(J)
      0e f2 f!                           \ F2 = 0.

      M1 0 DO                            \ DO 70 I=1,M1
        -1 jj +!                         \ J = J - 1
        f1 f@ temp1 f!                   \ TEMP1 = F1
        tt f@ f1 f@ f* f2 f@ f- ak3{ jj @ } f@ f+ f1 f!  \ F1 = TT*F1 - F2 + AK3(J)
        temp1 f@ f2 f!                   \ F2 = TEMP1
      LOOP                               \ 70 CONTINUE

      rx f@ fsqrt rtrx f!                \ RTRX = SQRT(RX)
      c f@ fnegate fexp ec f!            \ EC = EXP(-C)
      t f@ f1 f@ f* f2 f@ f- ak3{ 0 } f@ f+ ec f@ f* rtrx f@ f/ ai f! \ AI = EC*(T*F1-F2+AK3(1))/RTRX
      N1D 1- jj !                        \ J = N1D
      dak3{ jj @ } f@ f1 f!              \ F1 = DAK3(J)
      0e f2 f!                           \ F2 = 0.

      M1D 0 DO                           \ DO 80 I=1,M1D
        -1 jj +!                         \ J = J - 1
        f1 f@ temp1 f!                   \ TEMP1 = F1
        tt f@ f1 f@ f* f2 f@ f- dak3{ jj @ } f@ f+ f1 f!    \ F1 = TT*F1 - F2 + DAK3(J)
        temp1 f@ f2 f!                   \ F2 = TEMP1
      LOOP                               \ 80 CONTINUE

      t f@ f1 f@ f* f2 f@ f- dak3{ 0 } f@ f+ ec f@ f* rtrx f@ f* fnegate dai f! \ DAI = -RTRX*EC*(T*F1-F2+DAK3(1))
                                         \ RETURN
;

\ Airy function for x < 0, c > 5
: jairy-neg-cgt5 ( -- )
\  120 CONTINUE

      10e c f@ f/ 1e f- t f!             \ T = 10./C - 1.
      t f@ fdup f+ tt f!                 \ TT = T + T
      N4 1- jj !                         \ J = N4
      a{ jj @ } f@ f1 f!                 \ F1 = A(J)
      b{ jj @ } f@ e1 f!                 \ E1 = B(J)
      0e f2 f!                           \ F2 = 0.
      0e e2 f!                           \ E2 = 0.

      M4 0 DO                            \ DO 130 I=1,M4
        -1 jj +!                         \ J = J - 1
        f1 f@ temp1 f!                   \ TEMP1 = F1
        e1 f@ temp2 f!                   \ TEMP2 = E1
        tt f@ f1 f@ f* f2 f@ f- a{ jj @ } f@ f+ f1 f!  \ F1 = TT*F1 - F2 + A(J)
        tt f@ e1 f@ f* e2 f@ f- b{ jj @ } f@ f+ e1 f!  \ E1 = TT*E1 - E2 + B(J)
        temp1 f@ f2 f!                   \ F2 = TEMP1
        temp2 f@ e2 f!                   \ E2 = TEMP2
      LOOP                               \ 130 CONTINUE

      t f@ f1 f@ f* f2 f@ f- a{ 0 } f@ f+ temp1 f! \ TEMP1 = T*F1 - F2 + A(1)
      t f@ e1 f@ f* e2 f@ f- b{ 0 } f@ f+ temp2 f! \ TEMP2 = T*E1 - E2 + B(1)
      rx f@ fsqrt rtrx f!                \ RTRX = SQRT(RX)
      c f@ FPI12 f- cv f!                \ CV = C - FPI12
      cv f@ fsincos ccv f! scv f!        \ CCV = COS(CV) ; SCV = SIN(CV)
      temp1 f@ ccv f@ f* temp2 f@ scv f@ f* f- rtrx f@ f/ ai f! \ AI = (TEMP1*CCV-TEMP2*SCV)/RTRX
      N4D 1- jj !                        \ J = N4D
      da{ jj @ } f@ f1 f!                \ F1 = DA(J)
      db{ jj @ } f@ e1 f!                \ E1 = DB(J)
      0e f2 f!                           \ F2 = 0.
      0e e2 f!                           \ E2 = 0.

      M4D 0 DO                           \ DO 140 I=1,M4D
        -1 jj +!                         \ J = J - 1
        f1 f@ temp1 f!                   \ TEMP1 = F1
        e1 f@ temp2 f!                   \ TEMP2 = E1
        tt f@ f1 f@ f* f2 f@ f- da{ jj @ } f@ f+ f1 f!  \ F1 = TT*F1 - F2 + DA(J)
        tt f@ e1 f@ f* e2 f@ f- db{ jj @ } f@ f+ e1 f!  \ E1 = TT*E1 - E2 + DB(J)
        temp1 f@ f2 f!                   \ F2 = TEMP1
        temp2 f@ e2 f!                   \ E2 = TEMP2
      LOOP                               \ 140 CONTINUE

      t f@ f1 f@ f* f2 f@ f- da{ 0 } f@ f+ temp1 f!  \ TEMP1 = T*F1 - F2 + DA(1)
      t f@ e1 f@ f* e2 f@ f- db{ 0 } f@ f+ temp2 f!  \ TEMP2 = T*E1 - E2 + DB(1)
      ccv f@ CON5 f* scv f@ 0.5e f* f+ e1 f!         \ E1 = CCV*CON5 + .5*SCV
      scv f@ CON5 f* ccv f@ 0.5e f* f- e2 f!         \ E2 = SCV*CON5 - .5*CCV
      temp1 f@ e1 f@ f* temp2 f@ e2 f@ f* f- rtrx f@ f* dai f! \ DAI = (TEMP1*E1-TEMP2*E2)*RTRX
                                        \ RETURN
;


\ Airy function for negative real argument
: jairy-neg ( -- )
\    90 CONTINUE

      c f@ 5e f> IF jairy-neg-cgt5 EXIT THEN \ IF (C.GT.5.) GO TO 120

      c f@ 0.4e f* 1e f- t f!            \ T = .4*C - 1.
      t f@ fdup f+ tt f!                 \ TT = T + T
      N3 1- jj !                         \ J = N3
      ajp{ jj @ } f@ f1 f!               \ F1 = AJP(J)
      ajn{ jj @ } f@ e1 f!               \ E1 = AJN(J)
      0e f2 f!                           \ F2 = 0.
      0e e2 f!                           \ E2 = 0.

      M3 0 DO                            \ DO 100 I=1,M3
        -1 jj +!                         \ J = J - 1
        f1 f@ temp1 f!                   \ TEMP1 = F1
        e1 f@ temp2 f!                   \ TEMP2 = E1
        tt f@ f1 f@ f* f2 f@ f- ajp{ jj @ } f@ f+ f1 f!  \ F1 = TT*F1 - F2 + AJP(J)
        tt f@ e1 f@ f* e2 f@ f- ajn{ jj @ } f@ f+ e1 f!  \ E1 = TT*E1 - E2 + AJN(J)
        temp1 f@ f2 f!                   \ F2 = TEMP1
        temp2 f@ e2 f!                   \ E2 = TEMP2
      LOOP                               \ 100 CONTINUE

      t f@ e1 f@ f* e2 f@ f- ajn{ 0 } f@ f+
      t f@ f1 f@ f* f2 f@ f- ajp{ 0 } f@ f+ x f@ f* f- ai f! \ AI = (T*E1-E2+AJN(1)) - X*(T*F1-F2+AJP(1))
      N3D 1- jj !                        \ J = N3D
      dajp{ jj @ } f@ f1 f!              \ F1 = DAJP(J)
      dajn{ jj @ } f@ e1 f!              \ E1 = DAJN(J)
      0e f2 f!                           \ F2 = 0.
      0e e2 f!                           \ E2 = 0.

      M3D 0 DO                           \ DO 110 I=1,M3D
        -1 jj +!                         \ J = J - 1
        f1 f@ temp1 f!                   \ TEMP1 = F1
        e1 f@ temp2 f!                   \ TEMP2 = E1
        tt f@ f1 f@ f* f2 f@ f- dajp{ jj @ } f@ f+ f1 f!  \ F1 = TT*F1 - F2 + DAJP(J)
        tt f@ e1 f@ f* e2 f@ f- dajn{ jj @ } f@ f+ e1 f!  \ E1 = TT*E1 - E2 + DAJN(J)
        temp1 f@ f2 f!                   \ F2 = TEMP1
        temp2 f@ e2 f!                   \ E2 = TEMP2
      LOOP                               \ 110 CONTINUE

      t f@ f1 f@ f* f2 f@ f- dajp{ 0 } f@ f+ x f@ fdup f* f* 
      t f@ e1 f@ f* e2 f@ f- dajn{ 0 } f@ f+ f+ dai f! \ DAI = X*X*(T*F1-F2+DAJP(1)) + (T*E1-E2+DAJN(1))
                                         \ RETURN
;

\ Airy Function for x > 1.2 and c <= 5
: jairy-xgt1.2-cle5 ( -- )
\   30 CONTINUE

      x f@ fdup f+ CON2 f- CON3 f* t f!  \ T = (X+X-CON2)*CON3
      t f@ fdup f+ tt f!                 \ TT = T + T
      N2 1- jj !                         \ J = N2
      ak2{ jj @ } f@ f1 f!               \ F1 = AK2(J)
      0e f2 f!                           \ F2 = 0.

      M2 0 DO                            \ DO 40 I=1,M2
        -1 jj +!                         \ J = J - 1
        f1 f@ temp1 f!                   \ TEMP1 = F1
        tt f@ f1 f@ f* f2 f@ f- ak2{ jj @ } f@ f+ f1 f!  \ F1 = TT*F1 - F2 + AK2(J)
        temp1 f@ f2 f!                   \ F2 = TEMP1
      LOOP                               \ 40 CONTINUE

      rx f@ fsqrt rtrx f!                \ RTRX = SQRT(RX)
      c f@ fnegate fexp ec f!            \ EC = EXP(-C)
      t f@ f1 f@ f* f2 f@ f- ak2{ 0 } f@ f+ ec f@ f* rtrx f@ f/ ai f!  \ AI = EC*(T*F1-F2+AK2(1))/RTRX
      N2D 1- jj !                        \ J = N2D
      dak2{ jj @ } f@ f1 f!              \ F1 = DAK2(J)
      0e f2 f!                           \ F2 = 0.

      M2D 0 DO                           \ DO 50 I=1,M2D
        -1 jj +!                         \ J = J - 1
        f1 f@ temp1 f!                   \ TEMP1 = F1
        tt f@ f1 f@ f* f2 f@ f- dak2{ jj @ } f@ f+ f1 f!  \ F1 = TT*F1 - F2 + DAK2(J)
        temp1 f@ f2 f!                   \ F2 = TEMP1
      LOOP                               \ 50 CONTINUE

      t f@ f1 f@ f* f2 f@ f- dak2{ 0 } f@ f+ ec f@ fnegate f* rtrx f@ f* dai f! \ DAI = -EC*(T*F1-F2+DAK2(1))*RTRX

;

\ Airy function for 0 <= x <= 1.2 and c <= 5
: jairy-xle1.2-cle5 ( -- )
      x f@ fdup f+ 1.2e f- CON4 f* t f!  \ T = (X+X-1.2)*CON4
      t f@ fdup f+ tt f!                 \ TT = T + T
      N1 1- jj !                         \ J = N1
      ak1{ jj @ } f@ f1 f!               \ F1 = AK1(J)
      0e f2 f!                           \ F2 = 0.

      M1 0 DO                            \ DO 10 I=1,M1
        -1 jj +!                         \ J = J - 1
        f1 f@ temp1 f!                   \ TEMP1 = F1
        tt f@ f1 f@ f* f2 f@ f- ak1{ jj @ } f@ f+ f1 f!   \ F1 = TT*F1 - F2 + AK1(J)
        temp1 f@ f2 f!                   \ F2 = TEMP1
      LOOP                               \ 10 CONTINUE

      t f@ f1 f@ f* f2 f@ f- ak1{ 0 } f@ f+ ai f!  \ AI = T*F1 - F2 + AK1(1)
      N1D 1- jj !                        \ J = N1D
      dak1{ jj @ } f@ f1 f!              \ F1 = DAK1(J)
      0e f2 f!                           \ F2 = 0.

      M1D 0 DO                           \ DO 20 I=1,M1D
        -1 jj +!                         \ J = J - 1
        f1 f@ temp1 f!                   \ TEMP1 = F1
        tt f@ f1 f@ f* f2 f@ f- dak1{ jj @ } f@ f+ f1 f! \ F1 = TT*F1 - F2 + DAK1(J)
        temp1 f@ f2 f!                   \ F2 = TEMP1
      LOOP                               \ 20 CONTINUE

      t f@ f1 f@ f* f2 f@ f- dak1{ 0 } f@ f+ fnegate dai f! \ DAI = -(T*F1-F2+DAK1(1))

;

Public:

: jairy ( F: x -- ai[x] dai[x] )
    fdup x f!
    fdup fabs fsqrt rx f!               \ RX=SQRT(ABS(X))
    fdup fabs 1.5e f** 2e f* 3e f/ c f! \ C=2.*(ABS(X)**1.5)/3.

    f0< IF
      jairy-neg                    \ IF (X.LT.0.) GO TO 90
    ELSE
      c f@ 5e f> IF 
        jairy-pos-cgt5             \ IF (C.GT.5.) GO TO 60
      ELSE
        x f@ 1.2e f> IF            \ IF (X.GT.1.2) GO TO 30
          jairy-xgt1.2-cle5
        ELSE
          jairy-xle1.2-cle5
        THEN
      THEN
    THEN
    ai f@ dai f@
;

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

1e-15  FT-ABS-ERROR F!
4e-14  FT-REL-ERROR F!
set-ft-mode-rel0
: ?}t  }t ;
[ELSE]              \  setup for ttester

1e-15  abs-near f!
1e-15  rel-near f!   
set-near
: ?}t  rr}t ;
[THEN]
\ Uncomment next line to see message when testing, or only errors are shown.
true VERBOSE !

\ Reference values computed using Maxima's airy_ai() and airy_dai().
cr 
TESTING JAIRY
\ Positive arguments
t{  0e                   jairy  ->  3.550280538878172e-1  -2.588194037928063e-1  ?}t
t{  9.5367431640625e-06  jairy  ->  3.550255855936374e-1  -2.588194037766616e-1  ?}t
t{  9.765625e-4          jairy  ->  3.547753006188888e-1  -2.588192345825862e-1  ?}t
t{  9.9609375e-2         jairy  ->  3.293035740232009e-1  -2.571432582453169e-1  ?}t
t{  0.5e                 jairy  ->  2.316936064808335e-1  -2.249105326646834e-1  ?}t
t{  1.0e                 jairy  ->  1.352924163128814e-1  -1.591474412967926e-1  ?}t
t{  2.0e                 jairy  ->  3.492413042327437e-2  -5.309038443365368e-2  ?}t
t{  3.0e                 jairy  ->  6.591139357460717e-3  -1.191297670595132e-2  ?}t
t{  4.0e                 jairy  ->  9.515638512048020e-4  -1.958640950204181e-3  ?}t
t{  5.0e                 jairy  ->  1.0834442813607432e-4 -2.474138908684627e-4  ?}t
t{  6.0e                 jairy  ->  9.947694360252899e-6  -2.476520039703499e-5  ?}t
t{  7.0e                 jairy  ->  7.492128863997157e-7  -2.008150894738791e-6  ?}t
t{  8.0e                 jairy  ->  4.692207616099224e-8  -1.3414392979067874e-7 ?}t
t{  9.0e                 jairy  ->  2.4711684308724902e-9 -7.480641389658949e-9  ?}t
t{ 10.0e                 jairy  ->  1.104753255289865e-10 -3.520633676738927e-10 ?}t

\ Negative arguments
t{  -9.5367431640625e-06 jairy  ->  3.55030522181997e-1   -2.588194037766621e-1  ?}t
t{  -9.765625e-4         jairy  ->  3.552808071567064e-1  -2.588192344218905e-1  ?}t
t{  -9.9609375e-2        jairy  ->  3.807482909558885e-1  -2.569729582129294e-1  ?}t
t{  -0.5e                jairy  ->  4.757280916105396e-1  -2.04081670339547e-1   ?}t
t{  -1.0e                jairy  ->  5.355608832923521e-1  -1.016056711664498e-2  ?}t
t{  -2.0e                jairy  ->  2.274074282016854e-1   6.182590207416906e-1  ?}t
t{  -3.0e                jairy  -> -3.788142936776581e-1   3.145837692165983e-1  ?}t
t{  -4.0e                jairy  -> -7.026553294928967e-2  -7.906285753685816e-1  ?}t
t{  -5.0e                jairy  ->  3.507610090241142e-1   3.271928185544409e-1  ?}t
t{ -10.0e                jairy  ->  4.024123848644296e-2   9.962650441327906e-1  ?}t


BASE !
[THEN]

End-Module

