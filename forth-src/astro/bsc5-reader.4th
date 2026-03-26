\ bsc5-reader.4th
\
\ Read the records from the Yale Bright Star Catalog v. 5
\ binary file into Forth structures.
\
\ K. Myneni, Creative Consulting for Research & Education
\ krishna.myneni@ccreweb.org, http://ccreweb.org
\
\ This module is released as public domain -- please
\ cite the original if you use it in your own works.
\
\ Requires:
\   ans-words.4th, strings.4th, files.4th  ( kForth only )
\   struct-200x.4th
\   struct-200x-ext.4th
\   modules.4th
\   bsc5-structs.4th
\
\ Revisions:
\   2014-10-02  km  created.
\   2014-10-03  km  revised to make public get-nstars.
\   2026-03-26  km  updated for Forth 200x structures; 32/64 bit
\
\ Notes:
\
\  1. Please see reference [1] for information about the
\     Yale Bright Star Catalog.
\
\  2. A binary file in Intel byte order is available, 
\     sorted by the catalog number [2]. The binary file
\     header format is described in [3], and the record
\     format in [4].
\
\  3. The module allows multiple catalogs, for example files
\     with different sortings of fields such as by magnitude
\     or by right ascension, to exist in memory simultaneously.
\     Each such catalog in memory is referenced with a unique
\     handle.
\
\ References:
\
\  1. http://tdc-www.harvard.edu/catalogs/bsc5.html
\  2. http://tdc-www.harvard.edu/catalogs/BSC5
\  3. http://tdc-www.harvard.edu/catalogs/bsc5.header.html
\  4. http://tdc-www.harvard.edu/catalogs/bsc5.entry.html
\

Module: bsc5-reader

Also bsc5-structs

Begin-Module

create cat_hdr    HDR_SIZE allot
variable cat_fid
variable nrec_read

: open-catalog-file ( afilename u -- ior ) R/O open-file swap cat_fid ! ;
: close-catalog-file ( -- ior ) cat_fid @ close-file ;

: allocate-cat-mem ( -- handle ior )
    REC_SIZE cat_hdr h_starN SL@ abs * HDR_SIZE + allocate
;
: free-cat-mem ( handle -- ior ) free ;

\ Read the currently opened catalog file header into
\ the transient header memory.
: read-header ( -- ior )  cat_hdr HDR_SIZE cat_fid @  read-file nip ;
: copy-header ( handle -- ) cat_hdr swap HDR_SIZE move ;

Public:
 
: get-nstars ( handle -- u ) h_starN SL@ abs ;  \ ABS required for harvard files

Private:

: read-records ( handle -- ior )
    0 nrec_read !
    \ Ensure bytes per record in header matches record size
    dup h_nbent SL@ REC_SIZE <> IF drop -1 EXIT THEN
    dup get-nstars REC_SIZE * >r 
    HDR_SIZE + r> cat_fid @ read-file nip
;

Public:

\ Open a binary catalog file, read its header, allocate
\ memory for the catalog, and return the handle to 
\ the catalog and the number of records read.
\
\ ior < 0 to indicate error opening/reading the catalog file:
\   -1  unable to open catalog file.
\   -2  unable to read catalog header.
\   -3  unable to allocate memory for catalog.
\   -4  unable to read catalog records.
\   -5 
: open-catalog ( afilename u -- handle ior )
    open-catalog-file IF 0 -1 EXIT THEN 
    read-header       IF close-catalog-file drop 0 -2 EXIT THEN
    allocate-cat-mem  IF close-catalog-file drop -3 EXIT THEN
    dup copy-header
    dup read-records  IF close-catalog-file drop -4 EXIT THEN
    close-catalog-file IF -5 EXIT THEN
    0
;

\ Free the memory associated with the catalog.
: close-catalog ( handle -- ior ) free-cat-mem ;


End-Module

