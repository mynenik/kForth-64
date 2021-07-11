\ zerf.4th
\
\ Error function and Complementary Error Function of 
\ a complex number.
\
\ Provides:
\
\   ZERF
\   ZERFC
\
\ Krishna Myneni
\
\ Requires:
\   fsl-util.4th
\   complex.4th
\   zwofz.4th
\
\ Revisions:
\   2010-12-08 km  created.
\   2011-09-16 km  use Neal Bridges' anonymous modules.
\   2012-02-19 km  use KM/DNW's modules library.

BEGIN-MODULE

BASE @
DECIMAL

Private:
zvariable eterm

Public:

: zerfc ( z1 -- z2 )
    zdup z^2 znegate zexp eterm z! 
    i* zwofz drop eterm z@ z* ;
 
: zerf ( z1 -- z2 )
    1e 0e zswap zerfc z- ;

BASE !
END-MODULE
