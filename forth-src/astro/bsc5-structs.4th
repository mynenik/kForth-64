\ bsc5-structs.4th
\
\ Data structures for the Yale Bright Star Catalog v 5 files.
\ 
\ K. Myneni, Creative Consulting for Research & Education
\ krishna.myneni@ccreweb.org
\
\ This module is released as public domain -- please
\ cite the original if you use it in your own works.
\
\ Requires:
\   ans-words.4th, strings.4th, files.4th  ( kForth only )
\   struct-200x.4th
\   struct-200x-ext.4th
\   modules.4th
\
\ Revisions:
\   2014-10-03  km  created.
\   2026-03-26  km  revised for Forth 200x structures
\ Notes:
\
\  1. Please see reference [1] for information about the
\     Yale Bright Star Catalog.
\
\  2. The BSC5 catalog binary file may be found in [2],
\     the file header format is described in [3], and
\     the record format in [4].
\
\
\ References:
\
\  1. http://tdc-www.harvard.edu/catalogs/bsc5.html
\  2. http://tdc-www.harvard.edu/catalogs/BSC5
\  3. http://tdc-www.harvard.edu/catalogs/bsc5.header.html
\  4. http://tdc-www.harvard.edu/catalogs/bsc5.entry.html
\

Module: bsc5-structs

Begin-Module

Public:

BEGIN-STRUCTURE header%
  +LFIELD h_star0  \ Subtract from star number to get sequence number
  +LFIELD h_star1  \ First star number in file
  +LFIELD h_starN  \ Number of stars in file
  +LFIELD h_stnum  \ 0 if no star i.d. numbers are present
                   \ 1 if star i.d. numbers are in catalog file
                   \ 2 if star i.d. numbers are  in file
  +LFIELD h_mprop  \ 1 if proper motion is included
  	           \ 0 if no proper motion is included
  +LFIELD h_nmag   \ Number of magnitudes present (-1=J2000 instead of B1950)
  +LFIELD h_nbent  \ Number of bytes per star entry
END-STRUCTURE

BEGIN-STRUCTURE record%
  +SFFIELD r_xno   \ Catalog number of star
  +DFFIELD r_sra0  \ B1950 Right Ascension (radians) 
  +DFFIELD r_sdec0 \ B1950 Declination (radians)
  2 +FIELD r_spec  \ Spectral type (2 characters)
   +WFIELD r_mag   \ V Magnitude * 100
  +SFFIELD r_xrpm  \ R.A. proper motion (radians per year)
  +SFFIELD r_xdpm  \ Dec. proper motion (radians per year)
END-STRUCTURE

header% constant HDR_SIZE
record% constant REC_SIZE

End-Module

