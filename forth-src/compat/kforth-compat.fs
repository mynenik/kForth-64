\ kforth-compat.fs
\
\ kForth compatibility defns. for gforth
\
\ Revised: 2022-02-08

[defined] utime [if]
    utime 2constant start_time
[else]
    [undefined] ticks [if]
        0 constant ticks \ just a useless dummy
    [then]
    ticks constant start_time
[then]

[undefined] pi [if]
    3.14159265358979e fconstant pi
[then]

base @
DECIMAL
: deg>rad ( F: r1 -- r2 ) PI f* 180.0e0 f/ ;
: rad>deg ( F: r1 -- r2 ) 180.0e0 f* PI f/ ;
: fround>s ( F: r -- ) ( -- s ) fround f>s ;
: ftrunc>s ( F: r -- ) ( -- s ) ftrunc f>s ;
: allot?  ( u -- a ) here swap allot ;
: 2+  2 + ;
: 2-  2 - ;
[defined] utime [if]
    : ms@ ( -- u )  utime start_time d- 1000 um/mod nip ;
    : us2@ ( -- ud ) utime start_time d- ;
[else]
    : ms@ ( -- u ) ticks start_time - ;
    : us2@ ( -- ud ) ms@ 1000 um* ;
[then]
: usleep ( u -- ) 1000 / 1 max ms ;
: nondeferred ( -- ) ;
[defined] synonym [if]
    synonym a@ @
    synonym ptr value
[else]
    : a@ @ ;
    : ptr value ;
[then]
base !

[undefined] ud. [if]
    : ud. 0 ud.r  space ;
[then]

