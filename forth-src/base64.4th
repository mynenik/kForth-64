( ANEW --BASE64-- )                             \  Wil Baden 1997-11-17

\  *******************************************************************
\  *                                                                 *
\  *                           BASE64                                *
\  *                                                                 *
\  *  http://www.oac.uci.edu/indiv/ehood/MIME/1521/rfc1521ToC.html   *
\  *                                                                 *
\  *          5.2.  Base64 Content-Transfer-Encoding                 *
\  *                                                                 *
\  *  The Base64 Content-Transfer-Encoding is designed to represent  *
\  *  arbitrary sequences of octets in a form that need not be       *
\  *  humanly readable.  The encoding and decoding algorithms are    *
\  *  simple, but the encoded data are consistently only about 33    *
\  *  percent larger than the unencoded data.  This encoding is      *
\  *  virtually identical to the one used in Privacy Enhanced Mail   *
\  *  (PEM) applications, as defined in RFC 1421. The base64         *
\  *  encoding is adapted from RFC 1421, with one change: base64     *
\  *  eliminates the "*" mechanism for embedded clear text.          *
\  *                                                                 *
\  *  A 65-character subset of US-ASCII is used, enabling 6 bits to  *
\  *  be represented per printable character. (The extra 65th        *
\  *  character, "=", is used to signify a special processing        *
\  *  function.)                                                     *
\  *                                                                 *
\  *  NOTE: This subset has the important property that it is        *
\  *  represented identically in all versions of ISO 646, including  *
\  *  US ASCII, and all characters in the subset are also            *
\  *  represented identically in all versions of EBCDIC.  Other      *
\  *  popular encodings, such as the encoding used by the uuencode   *
\  *  utility and the base85 encoding specified as part of Level 2   *
\  *  PostScript, do not share these properties, and thus do not     *
\  *  fulfill the portability requirements a binary transport        *
\  *  encoding for mail must meet.                                   *
\  *                                                                 *
\  *  The encoding process represents 24-bit groups of input bits    *
\  *  as output strings of 4 encoded characters. Proceeding from     *
\  *  left to right, a 24-bit input group is formed by               *
\  *  concatenating 3 8-bit input groups. These 24 bits are then     *
\  *  treated as 4 concatenated 6-bit groups, each of which is       *
\  *  translated into a single digit in the base64 alphabet. When    *
\  *  encoding a bit stream via the base64 encoding, the bit stream  *
\  *  must be presumed to be ordered with the most-significant-bit   *
\  *  first.                                                         *
\  *                                                                 *
\  *  That is, the first bit in the stream will be the high-order    *
\  *  bit in the first byte, and the eighth bit will be the          *
\  *  low-order bit in the first byte, and so on.                    *
\  *                                                                 *
\  *  Each 6-bit group is used as an index into an array of 64       *
\  *  printable characters. The character referenced by the index    *
\  *  is placed in the output string. These characters, identified   *
\  *  in Table 1, below, are selected so as to be universally        *
\  *  representable, and the set excludes characters with            *
\  *  particular significance to SMTP (e.g., ".", CR, LF) and to     *
\  *  the encapsulation boundaries defined in this document (e.g.,   *
\  *  "-").                                                          *
\  *                                                                 *
\  *        Table 1: The Base64 Alphabet                             *
\  *                                                                 *
\  *  Value Encoding  Value Encoding  Value Encoding  Value Encoding *
\  *      0 A            17 R            34 i            51 z        *
\  *      1 B            18 S            35 j            52 0        *
\  *      2 C            19 T            36 k            53 1        *
\  *      3 D            20 U            37 l            54 2        *
\  *      4 E            21 V            38 m            55 3        *
\  *      5 F            22 W            39 n            56 4        *
\  *      6 G            23 X            40 o            57 5        *
\  *      7 H            24 Y            41 p            58 6        *
\  *      8 I            25 Z            42 q            59 7        *
\  *      9 J            26 a            43 r            60 8        *
\  *     10 K            27 b            44 s            61 9        *
\  *     11 L            28 c            45 t            62 +        *
\  *     12 M            29 d            46 u            63 /        *
\  *     13 N            30 e            47 v                        *
\  *     14 O            31 f            48 w         (pad) =        *
\  *     15 P            32 g            49 x                        *
\  *     16 Q            33 h            50 y                        *
\  *                                                                 *
\  *  The output stream (encoded bytes) must be represented in       *
\  *  lines of no more than 76 characters each.  All line breaks or  *
\  *  other characters not found in Table 1 must be ignored by       *
\  *  decoding software.  In base64 data, characters other than      *
\  *  those in Table 1, line breaks, and other white space probably  *
\  *  indicate a transmission error, about which a warning message   *
\  *  or even a message rejection might be appropriate under some    *
\  *  circumstances.                                                 *
\  *                                                                 *
\  *  Special processing is performed if fewer than 24 bits are      *
\  *  available at the end of the data being encoded.  A full        *
\  *  encoding quantum is always completed at the end of a body.     *
\  *  When fewer than 24 input bits are available in an input        *
\  *  group, zero bits are added (on the right) to form an integral  *
\  *  number of 6-bit groups.  Padding at the end of the data is     *
\  *  performed using the '=' character.  Since all base64 input is  *
\  *  an integral number of octets, only the following cases can     *
\  *  arise: (1) the final quantum of encoding input is an integral  *
\  *  multiple of 24 bits; here, the final unit of encoded output    *
\  *  will be an integral multiple of 4 characters with no "="       *
\  *  padding, (2) the final quantum of encoding input is exactly 8  *
\  *  bits; here, the final unit of encoded output will be two       *
\  *  characters followed by two "=" padding characters, or (3) the  *
\  *  final quantum of encoding input is exactly 16 bits; here, the  *
\  *  final unit of encoded output will be three characters          *
\  *  followed by one "=" padding character.                         *
\  *                                                                 *
\  *  Because it is used only for padding at the end of the data,    *
\  *  the occurrence of any '=' characters may be taken as evidence  *
\  *  that the end of the data has been reached (without truncation  *
\  *  in transit).  No such assurance is possible, however, when     *
\  *  the number of octets transmitted was a multiple of three.      *
\  *                                                                 *
\  *  Any characters outside of the base64 alphabet are to be        *
\  *  ignored in base64-encoded data.  The same applies to any       *
\  *  illegal sequence of characters in the base64 encoding, such    *
\  *  as "====="                                                     *
\  *                                                                 *
\  *  Care must be taken to use the proper octets for line breaks    *
\  *  if base64 encoding is applied directly to text material that   *
\  *  has not been converted to canonical form. In particular, text  *
\  *  line breaks must be converted into CRLF sequences prior to     *
\  *  base64 encoding. The important thing to note is that this may  *
\  *  be done directly by the encoder rather than in a prior         *
\  *  canonicalization step in some implementations.                 *
\  *                                                                 *
\  *  NOTE: There is no need to worry about quoting apparent         *
\  *  encapsulation boundaries within base64-encoded parts of        *
\  *  multipart entities because no hyphen characters are used in    *
\  *  the base64 encoding.                                           *
\  *                                                                 *
\  *******************************************************************

\ Revised for kForth -- K. Myneni, 9/13/2003
\
\ Entire files may be encoded or decoded with single line
\ commands:
\
\	S" filename"  BASE64ENCODE	--> creates encoded file with
\					    name filename+.b64
\
\	S" filename"  BASE64DECODE	--> creates decoded file with
\					    name filename+.un
\
\ The following files are required under kForth:
\
\	ans-words.4th
\	strings.4th
\	files.4th
\

: C+!  ( n addr -- )  DUP >R  C@ +  R> C! ;
: Append-Char ( char ^str -- ) 1 OVER +! COUNT 1- + C! ;

VARIABLE b64-infile
VARIABLE b64-outfile

: b64-open-infile ( str len -- )
    R/O  OPEN-FILE  ABORT" UNABLE TO OPEN INPUT FILE"
    b64-infile ! ;

: b64-open-outfile ( str len -- )
    W/O  O_TRUNC or CREATE-FILE  ABORT" UNABLE TO CREATE OUTPUT FILE"
    b64-outfile ! ;


\  *******************************************************************
\  *                                                                 *
\  *          BASE64ENCODE                                           *
\  *                                                                 *
\  *  Needs your definitions for:                                    *
\  *                                                                 *
\  *  GET-UNENCODED-FILE  ( -- str len more )                        *
\  *  PUT-ENCODED-LINE    ( str len -- )                             *
\  *                                                                 *
\  *******************************************************************

57 CONSTANT #Bytes-at-a-Time

    CREATE Clipboard-Buffer  256 ALLOT

\ Working definitions of Get-Unencoded-File and Put-Encoded-Line
\   are supplied for this version of the code -- km 9/13/03

    : Get-Unencoded-File  ( . . -- . . str len more )
        \ 2dup dup #Bytes-at-a-Time MIN /STRING /SPLIT
        \    Clipboard-Buffer PLACE
        \ Clipboard-Buffer COUNT dup ;

        Clipboard-Buffer #Bytes-at-a-Time b64-infile @ READ-FILE
	DROP Clipboard-Buffer SWAP DUP ;
 

    : Put-Encoded-Line  ( str len -- )
        \ TYPE CR ;
	b64-outfile @ WRITE-LINE DROP ;

\  File-Span           ( -- addr )
\     Variable for the length of the binary line.

\  Bin-to-Ascii        ( n -- )
\     Write 6-bit binary as 7-bit Ascii.

\  3Bin-to-4Ascii      ( str len -- )
\     Encode a binary line as 7-bit Ascii.

VARIABLE File-Span

CREATE Base64-Alphabet  65 ALLOT
S" ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
    Base64-Alphabet SWAP MOVE

CREATE Inverse-Base64-Alphabet  256 ALLOT

\    MARKER INITIALIZATION

    : SALT
        Inverse-Base64-Alphabet 256 65 FILL
        65 0 DO
            I Base64-Alphabet I + C@ Inverse-Base64-Alphabet + C!
        LOOP ; SALT

    ( END ) ( INITIALIZATION ) FORGET SALT

: Bin-to-Ascii      ( n -- )
    63 AND  Base64-Alphabet +  C@
    PAD Append-Char ;

: 3Bin-to-4Ascii    ( str len -- )
    \  Pad input with two nul bytes.
    2dup + >R  0 R@ C!  0 R> 1+ C!
    \  Pick up 3 bytes at a time.
    0 ?DO                         ( str)
        COUNT 16 LSHIFT >R        ( str+1)( R: x)
        COUNT  8 LSHIFT R> OR >R  ( str+2)( R: xx)
        COUNT R> OR               ( str+3 xxx)( R: )
        dup 18 RSHIFT Bin-to-Ascii
        dup 12 RSHIFT Bin-to-Ascii
        dup  6 RSHIFT Bin-to-Ascii
        Bin-to-Ascii                 ( str+3)
    3 +LOOP  DROP ;

\  Encode-a-Line       ( str len -- )
\     Encode a given line.
\  Encode-the-File     ( -- )
\     Encode the file.

    : Write-Ascii-Line  ( -- )
        File-Span @ 3 MOD
	CASE 
        1 OF  -2 PAD C+!
            [char] = PAD Append-Char
            [char] = PAD Append-Char
            ENDOF
        2 OF  -1 PAD C+!
            [char] = PAD Append-Char
            ENDOF
        ENDCASE
        PAD COUNT Put-Encoded-Line ;

: Encode-a-Line     ( str len -- )
    \  Initialize output buffer.
    0 PAD C!
    \  Save length of input for later.
    dup File-Span !
    \  Encode the record.
    3Bin-to-4Ascii ( )
    Write-Ascii-Line ;

: Encode-the-File   ( -- )
    BEGIN  Get-Unencoded-File
    WHILE  ( str len) Encode-a-Line  REPEAT
    2DROP  ( ) ;

\  *************************  BASE64ENCODE  **************************

\ parameters for BASE64ENCODE "str len" are the input filename
\ output file name is automatically set to: input filename + ".b64"

: BASE64ENCODE    ( str len -- )	   
    CR
    \ CLIPBOARD ( str len)
    2DUP  b64-open-infile
    s" .b64" strcat b64-open-outfile
    Encode-the-File
    b64-infile  @ CLOSE-FILE DROP
    b64-outfile @ CLOSE-FILE DROP
    \ 2DROP
    ;


\  *******************************************************************
\  *                                                                 *
\  *         BASE64DECODE                                            *
\  *                                                                 *
\  *  Needs your definitions for:                                    *
\  *                                                                 *
\  *  GET-ENCODED-LINE  ( -- str len flag )                          *
\  *  PUT-DECODED-FILE  ( str len -- )                               *
\  *                                                                 *
\  *******************************************************************

\ Working definitions of Get-Encoded-Line and Put-Decoded-File
\   are supplied for this version of the code -- km 9/13/03

    : Get-Encoded-Line ( . . -- str len flag )
        \ dup >R  Split-Next-Line  R> ;
	Clipboard-Buffer 80 b64-infile @ READ-LINE 
	DROP Clipboard-Buffer -ROT ;

    : Put-Decoded-File  ( str len -- )
        \ 0 ?DO  COUNT
        \    OUTFILE @ -1 = IF
        \        dup 10 = IF  DROP 13  THEN
        \    THEN
        \    EMIT
        \ LOOP DROP ;
	b64-outfile @  WRITE-FILE  DROP ;

\  Ascii-to-Bin        ( ascii -- )
\     Convert 7-bit encoded Ascii to 6-bit binary.

\  4Ascii-to-3Bin      ( str -- str' )
\     Repack 7-bit Ascii to 6-bit binary pieces.

\  Decode-a-Line       ( str len -- flag )
\     Convert encoded line to binary.

\  Decode-the-File     ( -- )
\     Convert encoded file to binary.

: Ascii-to-Bin      ( ascii -- )
    Inverse-Base64-Alphabet + C@ ;

: 4Ascii-to-3Bin    ( str -- str' )
    COUNT Ascii-to-Bin 18 LSHIFT >R        ( str+1)( R: b)
    COUNT Ascii-to-Bin 12 LSHIFT R> OR >R  ( str+2)( R: bb)
    COUNT Ascii-to-Bin  6 LSHIFT R> OR >R  ( str+3)( R: bbb)
    COUNT Ascii-to-Bin R> OR               ( str+4 bbb)( R: )
    dup 16 RSHIFT  PAD Append-Char
    dup  8 RSHIFT  PAD Append-Char
    PAD Append-Char                        ( str+4)
    ;

    : Save-Ascii-Line-Length  ( str len -- )
        2dup 1- + C@ [char] = = IF  1-  THEN
        2dup 1- + C@ [char] = = IF  1-  THEN
        File-Span !  DROP ;

: Decode-a-Line     ( str len -- flag )
    \  Discard empty line.
    dup 0=                  IF  NIP   EXIT THEN
    \  Save length for later.
    2dup Save-Ascii-Line-Length
    \  Reset PAD.
    0 PAD C!
    \  Decode the line.
    0 ?DO ( str) 4Ascii-to-3Bin  3 +LOOP
    DROP 0 ( flag)
    PAD 1+ File-Span @ 3 4 */ Put-Decoded-File ;

: Decode-the-File   ( -- )
    BEGIN                                         ( )
        Get-Encoded-Line 0= IF  2DROP  EXIT THEN  ( str len)
        ( CLIP)  Decode-a-Line                    ( end)
    UNTIL ;

\  *************************  BASE64DECODE  **************************

\ parameters for BASE64DECODE "str len" are the input filename
\ output file name is automatically set to: input filename + ".un"

: BASE64DECODE      ( str len -- )
    CR  
    2DUP  b64-open-infile
    s" .un" strcat b64-open-outfile
    \ CLIPBOARD  ( str len) 
    Decode-the-File  
    b64-infile  @ CLOSE-FILE DROP
    b64-outfile @ CLOSE-FILE DROP
    \ 2DROP 
    ;

\ \   //   \\   //   \\   //   \\   //   \\   //   \\   //   \\   //   \\
