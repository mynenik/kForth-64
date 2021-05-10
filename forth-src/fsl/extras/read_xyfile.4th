\ read_xyfile.4th
\
\ Utility for reading a two-column ascii file into FSL-type arrays
\
\ Requires the non-standard word PARSE_ARGS, which parses a line of
\ text into a sequence of floating point numbers:
\
\     PARSE_ARGS ( a u -- r1 r2 ... rn  n )
\
\  or, for systems with a separate floating stack,
\
\     PARSE_ARGS ( a u -- n ) ( F: -- r1 r2 ... rn )
\
\  PARSE_ARGS should return zero for n if the line is empty or
\  contains only whitespace characters.
\
\ Notes:
\
\  1. The input file must be a text file, having two columns of
\     numbers, with the columns separated by a comma, space(s), or a tab.
\
\  2. The file may contain comments which are indicated by a '#' in
\     the first column of a line.
\
\  3. Empty lines and white space lines are ignored.
\
\  4. Return error codes for read_xyfile:
\
\       0 -- no error
\       1 -- unable to open input file
\       2 -- input file does not conform to specs.
\
\ Copyright (c) 2007 K. Myneni, 2007-11-21
\
\ This file may be used for any purpose, as long as the copyright notice
\ above is preserved.
\
\ Revisions:
\   2015-02-07  km; fixed reading lines with trailing spaces;
\                   drop left over zero on stack.
\
[undefined] parse_args [IF] include strings.4th [THEN]
[undefined] open-file  [IF] include files.4th   [THEN]

0 value fid
0 value idx
create dline 256 allot

: read_xyfile ( 'x 'y a u -- np ierr )
    R/O open-file ABORT" Unable to open file!"
    to fid
    0 to idx
    2>R
    BEGIN
	dline 255 fid read-line 0= and
    WHILE
	    dline c@ [char] # = IF dline swap cr type  \ ignore comment line
	    ELSE
		dline swap -trailing parse_args
		CASE
		    0 OF   ENDOF  \ blank line; ignore it
		    2 OF   2R@ nip idx } F!  2R@ drop idx } F!  1 idx + to idx  ENDOF
		    fid close-file drop ." Unrecognized junk in file" ABORT
		ENDCASE
	    THEN
    REPEAT
    drop
    fid close-file drop
    2R> 2drop
    idx 0 
;

