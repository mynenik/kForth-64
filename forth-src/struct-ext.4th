\ struct-ext.4th
\
\ Extension words for creating single byte aligned structures.
\
\ It is often required to create a structure with contiguous
\ boundaries for its fields. The normal field defining
\ word found in struct.4th automatically adjusts alignment and
\ does not guarantee that successive elements are contiguous
\ in memory. Therefore, defining a structure for a precisely
\ specified format poses a problem. This problem is addressed
\ by providing a set of field creation words which always ensure
\ that successive elements are contiguous in memory.
\
\ Revisions:
\
\   2003-11-03  created by Krishna Myneni
\   2010-06-22  km  added int64:
\   2019-08-12  km  added int128: and qfloat:
\
\ Requires:
\
\	ans-words.4th
\	struct.4th
\

: byte:   1  1 field ;			\ 8-bit  value
: int16:  1  2 field ;			\ 16-bit integer
: int32:  1  4 field ;			\ 32-bit integer
: int64:  1  8 field ;                  \ 64-bit integer
: int128: 1 16 field ;                  \ 128-bit integer
: int:    int32: ;			\ 32-bit integer 
: sfloat: 1  4 field ;			\ 32-bit (single precision) float
: dfloat: 1  8 field ;			\ 64-bit (double precision) float
: qfloat: 1 16 field ;                  \ 128-bit (quad precision)  float
: float:  dfloat: ;			\ 64-bit float
: buf: ( n -- ) 1 swap field ;		\ byte buffer



