\ struct-200x-ext.4th
\
\ Extension words for creating single byte aligned structures.
\
\ It is often required to create a structure with contiguous
\ boundaries for its fields. The normal field defining
\ words found in struct-200x.4th automatically adjusts alignment
\ and do not guarantee that successive elements are contiguous
\ in memory. Therefore, defining a structure for a precisely
\ specified format poses a problem. This problem is addressed
\ by providing a set of field creation words which always ensure
\ that successive elements are contiguous in memory.
\
\ Revisions:
\
\   2003-11-03  created by Krishna Myneni (for struct.4th)
\   2010-06-22  km  added int64:
\   2019-08-12  km  added int128: and qfloat:
\   2021-09-13  km  ported to Forth 200x structures
\   2021-09-18  km  renamed unaligned fields so that both
\                   Forth 200x-like structures can coexist
\                   with STRUCT-like structures.
\ Requires:
\
\	ans-words.4th
\	struct-200x.4th
\

\ Aligned fields ( see Forth=2012 standard, A.10.6.2.0763 )

0 [IF]
: BFIELD: CFIELD: ;
: WFIELD: ;
: LFIELD: ;
: XFIELD: ;
: QFIELD: ;
[THEN]


\ Unaligned fields

: +BFIELD    1 +FIELD ;		\ 8-bit  field
: +WFIELD    2 +FIELD ;		\ 16-bit field
: +LFIELD    4 +FIELD ;		\ 32-bit field
: +XFIELD    8 +FIELD ;         \ 64-bit field
: +int128   16 +FIELD ;         \ 128-bit integer
: +SFFIELD   4 +FIELD ;		\ 32-bit (single precision) float
: +DFFIELD   8 +FIELD ;		\ 64-bit (double precision) float
: +QFFIELD  16 +FIELD ;         \ 128-bit (quad precision)  float
: +FFIELD    1 FLOATS +FIELD ;	\ current floating point size

