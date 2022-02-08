\ kforth-compat.fs
\
\ kForth compatibility defns. for gforth
\
\ Revised: 2022-02-05

utime 2constant start_time

base @
DECIMAL
: deg>rad ( F: r1 -- r2 ) PI f* 180.0e0 f/ ;
: rad>deg ( F: r1 -- r2 ) 180.0e0 f* PI f/ ;
: fround>s ( F: r -- ) ( -- s ) fround f>s ;
: ftrunc>s ( F: r -- ) ( -- s ) ftrunc f>s ;
: allot?  ( u -- a ) here swap allot ;
: 2+  2 + ;
: 2-  2 - ;
: ms@ ( -- u )  utime start_time d- 1000 um/mod nip ;
: us2@ ( -- ud ) utime start_time d- ;
: usleep ( u -- ) 1000 / 1 max ms ;
: nondeferred ( -- ) ;
synonym a@ @
synonym ptr value
base !

