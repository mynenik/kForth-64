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
\
\ Requires:
\
\	ans-words.4th
\	struct-200x.4th
\

\ Aligned fields

0 [IF]
: BFIELD: CFIELD: ;
: WFIELD: ;
: LFIELD: ;
: XFIELD: ;
: QFIELD: ;
[THEN]


\ Unaligned fields
: byte:    1 +FIELD ;		\ 8-bit  field
: int16:   2 +FIELD ;		\ 16-bit integer
: int32:   4 +FIELD ;		\ 32-bit integer
: int64:   8 +FIELD ;           \ 64-bit integer
: int128: 16 +FIELD ;           \ 128-bit integer
: sfloat:  4 +FIELD ;		\ 32-bit (single precision) float
: dfloat:  8 +FIELD ;		\ 64-bit (double precision) float
: qfloat: 16 +FIELD ;           \ 128-bit (quad precision)  float
: float:    dfloat: ;		\ 64-bit float
: buf: ( n -- ) +FIELD ;	\ byte buffer

