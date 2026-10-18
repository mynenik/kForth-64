\ fdotn-test.4th
\ 18 Oct 2026
\
\ Test F.N ( F: r -- ) ( n -- ) 
\ Fixed point output and n is the number of decimal places.
\
\ K. Myneni and Peter <peter@noreply.tin.it>

include ans-words
include strings

CR .( FDOTN-TEST        V1.2      18 Oct     2026 )
[UNDEFINED] T{ [IF] s" ttester" included [THEN]
\ The included below will change to strings.4th
\ (F.N) and F.N will be integrated into strings.4th
\ [UNDEFINED] (F.N) [IF] s" fdotn.4th" included [THEN]
include fdotn.4th

variable fdotn-errors  0 fdotn-errors !
:noname ( c-addr u -- | Keep cumulative error count )
  1 fdotn-errors +! error1 ; error-xt !

CR
TESTING (F.N)
: strupr ( caddr u -- caddr u)
    2dup 0 ?DO dup c@ ucase over c! 1+ LOOP drop ;    
: comp ( caddr1 u caddr2 u -- n )
    ( strupr) 2swap -trailing bl skip ( strupr) compare ;

t{ (  1 ) 0.0051e0  0 (f.n) s" 0." comp -> 0 }t
t{ (  2 ) 0.0051e0  1 (f.n) s" 0.0" comp -> 0 }t
t{ (  3 ) 0.0051e0  2 (f.n) s" 0.01" comp -> 0 }t
t{ (  4 ) 0.0051e0  3 (f.n) s" 0.005" comp -> 0 }t
t{ (  5 ) 0.0051e0  4 (f.n) s" 0.0051" comp -> 0 }t
t{ (  6 ) 0.0051e0  5 (f.n) s" 0.00510" comp -> 0 }t
t{ (  7 ) 0.0051e0 17 (f.n) s" 0.00510000000000000" comp -> 0 }t
t{ (  8 ) 2.0e-15  17 (f.n) s" 0.00000000000000200" comp -> 0 }t
t{ (  9 ) 0.1e0     0 (f.n) s" 0." comp -> 0 }t
t{ ( 10 ) 0.2e0     0 (f.n) s" 0." comp -> 0 }t
t{ ( 11 ) 0.5e0     0 (f.n) s" 0." comp -> 0 }t
t{ ( 12 ) 0.51e0    0 (f.n) s" 1." comp -> 0 }t
t{ ( 13 ) 0.500000000000000001e0  0 (f.n) s" 0." comp -> 0 }t
t{ ( 14 ) 0.50000000000000001e0   0 (f.n) s" 0." comp -> 0 }t
t{ ( 15 ) 0.5000000000000001e0    0 (f.n) s" 1." comp -> 0 }t
t{ ( 16 ) 0.6e0     0 (f.n) s" 1." comp -> 0 }t
t{ ( 17 ) 0.9e0     0 (f.n) s" 1." comp -> 0 }t 
t{ ( 18 ) 1.0e0     0 (f.n) s" 1." comp -> 0 }t 
t{ ( 19 ) 1.4e0     0 (f.n) s" 1." comp -> 0 }t 
t{ ( 20 ) 1.4999999e0 0 (f.n) s" 1." comp -> 0 }t
t{ ( 21 ) 1.5e0     0 (f.n) s" 2." comp -> 0 }t
t{ ( 22 ) 2.5e0     0 (f.n) s" 2." comp -> 0 }t
t{ ( 23 ) 3.5e0     0 (f.n) s" 4." comp -> 0 }t
t{ ( 24 ) -1100.2e0 0 (f.n) s" -1100." comp -> 0 }t
t{ ( 25 ) -1100.5e0 0 (f.n) s" -1100." comp -> 0 }t
t{ ( 26 ) -1101.5e0 0 (f.n) s" -1102." comp -> 0 }t
t{ ( 27 ) -1102.5e0 0 (f.n) s" -1102." comp -> 0 }t
t{ ( 28 ) 2.01682663070034556e16  0 (f.n) s" 20168266307003456."
   comp -> 0 }t
t{ ( 29 ) 2.01682663070034556e16 20 (f.n)
   s" 20168266307003456.00000000000000000000" comp -> 0 }t
t{ ( 30 ) 0.5e0    25 (f.n) s" 0.5000000000000000000000000"
   comp -> 0 }t
t{ ( 31 ) 0.625e0  25 (f.n) s" 0.6250000000000000000000000"
   comp -> 0 }t
t{ ( 32 ) -0.6e0    4 (f.n) s" -0.6000" comp -> 0 }t
t{ ( 33 ) -0.6e0   16 (f.n) s" -0.6000000000000000" comp -> 0 }t
t{ ( 34 ) -0.6e0   17 (f.n) s" -0.59999999999999998"
   comp -> 0 }t
t{ ( 35 ) -0.6e0   23 (f.n) s" -0.59999999999999997779554"
   comp -> 0 }t
t{ ( 36 ) -0.6e0   25 (f.n) s" -0.5999999999999999777955395"
   comp -> 0 }t
t{ ( 37 ) 9.1e0     3 (f.n) s" 9.100" comp -> 0 }t
t{ ( 38 ) 9.51e0    1 (f.n) s" 9.5" comp -> 0 }t
t{ ( 39 ) 9.55e0    1 (f.n) s" 9.6" comp -> 0 }t
t{ ( 40 ) -9.66e0   1 (f.n) s" -9.7" comp -> 0 }t
t{ ( 41 ) 99.995e0  2 (f.n) s" 100.00" comp -> 0 }t
t{ ( 42 ) 99.625e0  2 (f.n) s" 99.62"  comp -> 0 }t
t{ ( 43 ) 96.62500000000001e 2 (f.n) s" 96.63" comp -> 0 }t
t{ ( 44 ) 1.247777e3       0 (f.n) s" 1248." comp -> 0 }t
t{ ( 45 ) 1.247777e3       1 (f.n) s" 1247.8" comp -> 0 }t
t{ ( 46 ) 1.247777e3       2 (f.n) s" 1247.78" comp -> 0 }t
t{ ( 47 ) 1.247777e3       3 (f.n) s" 1247.777" comp -> 0 }t
t{ ( 48 ) -5.0999913335e0  4 (f.n) s" -5.1000"  comp -> 0 }t
t{ ( 49 ) -5.0999913335e0  5 (f.n) s" -5.09999" comp -> 0 }t
t{ ( 50 ) -5.0999913335e0  6 (f.n) s" -5.099991" comp -> 0 }t
t{ ( 51 ) -5.0999913335e0  7 (f.n) s" -5.0999913" comp -> 0 }t
t{ ( 52 ) -5.0999913335e0  8 (f.n) s" -5.09999133" comp -> 0 }t
t{ ( 53 ) -5.0999913335e0  9 (f.n) s" -5.099991334" comp -> 0 }t
t{ ( 54 ) 9.599999999e8    0 (f.n) s" 960000000." comp -> 0 }t
t{ ( 55 ) 0.0e             0 (f.n) s" 0." comp -> 0 }t
t{ ( 56 ) -0.0e            0 (f.n) s" -0." comp -> 0 }t

\ Addtional tests by <peter@noreply.tin.it>:
\ from message on comp.lang.forth 8 October 2026
t{ (  1)  0.9e  0 (f.n) s" 1." comp -> 0 }t
t{ (  2)  0.3e  0 (f.n) s" 0." comp -> 0 }t
t{ (  3) -0.9e  0 (f.n) s" -1." comp -> 0 }t
t{ (  4) -0.3e  0 (f.n) s" -0." comp -> 0 }t

t{ (  5) 0.123e   0 (f.n) s" 0." comp -> 0 }t
t{ (  6) 0.123e-1 1 (f.n) s" 0.0" comp -> 0 }t
t{ (  7) 0.123e-2 2 (f.n) s" 0.00" comp -> 0 }t
t{ (  8) 0.123e-3 3 (f.n) s" 0.000" comp -> 0 }t

t{ (  9) 0.823e   0 (f.n) s" 1." comp -> 0 }t
t{ ( 10) 0.823e-1 1 (f.n) s" 0.1" comp -> 0 }t
t{ ( 11) 0.823e-2 2 (f.n) s" 0.01" comp -> 0 }t
t{ ( 12) 0.823e-3 3 (f.n) s" 0.001" comp -> 0 }t

t{ ( 13)  0.1368e    3 (f.n) s" 0.137" comp -> 0 }t
t{ ( 14) -0.1368e-1  3 (f.n) s" -0.014" comp -> 0 }t
t{ ( 15)  0.1368e-2  3 (f.n) s" 0.001" comp -> 0 }t
t{ ( 16) -0.1368e-3  3 (f.n) s" -0.000" comp -> 0 }t
t{ ( 17)  0.1368e-4  3 (f.n) s" 0.000" comp -> 0 }t

t{ ( 18) -0.8368e    3 (f.n) s" -0.837" comp -> 0 }t
t{ ( 19) -0.8368e-1  3 (f.n) s" -0.084" comp -> 0 }t
t{ ( 20) -0.8368e-2  3 (f.n) s" -0.008" comp -> 0 }t
t{ ( 21) -0.8368e-3  3 (f.n) s" -0.001" comp -> 0 }t
t{ ( 22) -0.8368e-4  3 (f.n) s" -0.000" comp -> 0 }t

t{ ( 23) 126.8567e   3 (f.n) s" 126.857" comp -> 0 }t
t{ ( 24) 126.8567e   2 (f.n) s" 126.86" comp -> 0 }t
t{ ( 25) 126.8567e   1 (f.n) s" 126.9" comp -> 0 }t
t{ ( 26) 126.8567e   0 (f.n) s" 127." comp -> 0 }t
t{ ( 27) 126.8567e  -1 (f.n) s" 130" comp -> 0 }t
t{ ( 28) 126.8567e  -2 (f.n) s" 100" comp -> 0 }t
t{ ( 29) 126.8567e  -3 (f.n) s" 100" comp -> 0 }t

t{ ( 30) 99.995e  3 (f.n) s" 99.995" comp -> 0 }t
t{ ( 31) 99.995e  2 (f.n) s" 100.00" comp -> 0 }t
t{ ( 32) 99.995e  1 (f.n) s" 100.0" comp -> 0 }t

t{ ( 33) 0.999955555e 0 (f.n) s" 1." comp -> 0 }t
t{ ( 34) 0.999955555e 1 (f.n) s" 1.0" comp -> 0 }t
t{ ( 35) 0.999955555e 2 (f.n) s" 1.00" comp -> 0 }t
t{ ( 36) 0.999955555e 3 (f.n) s" 1.000" comp -> 0 }t
t{ ( 37) 0.999955555e 4 (f.n) s" 1.0000" comp -> 0 }t
t{ ( 38) 0.999955555e 5 (f.n) s" 0.99996" comp -> 0 }t

t{ ( 39) 5.2345678e-1  10 (f.n) s" 0.5234567800" comp -> 0 }t
t{ ( 40) 5.2345678e-2  10 (f.n) s" 0.0523456780" comp -> 0 }t
t{ ( 41) 5.2345678e-3  10 (f.n) s" 0.0052345678" comp -> 0 }t
t{ ( 42) 5.2345678e-4  10 (f.n) s" 0.0005234568" comp -> 0 }t
t{ ( 43) 5.2345678e-5  10 (f.n) s" 0.0000523457" comp -> 0 }t
t{ ( 44) 5.2345678e-6  10 (f.n) s" 0.0000052346" comp -> 0 }t
t{ ( 45) 5.2345678e-7  10 (f.n) s" 0.0000005235" comp -> 0 }t
t{ ( 46) 5.2345678e-8  10 (f.n) s" 0.0000000523" comp -> 0 }t
t{ ( 47) 5.2345678e-9  10 (f.n) s" 0.0000000052" comp -> 0 }t
t{ ( 48) 5.2345678e-10 10 (f.n) s" 0.0000000005" comp -> 0 }t
t{ ( 49) 5.2345678e-11 10 (f.n) s" 0.0000000001" comp -> 0 }t
t{ ( 50) 5.2345678e-12 10 (f.n) s" 0.0000000000" comp -> 0 }t

t{ ( 50) -1e 0e f/ 5 (f.n) s" -inf" comp -> 0 }t
t{ ( 51)  0e 0e f/ 5 (f.n) s" nan" comp -> 0 }t

CR .( Error Count: ) fdotn-errors ? CR

