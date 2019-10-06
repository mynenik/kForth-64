( lz77.4th

  LZ77 Data Compression

      LZSS -- A Data Compression Program
      1989-04-06 Standard C by Haruhiko Okumura
      1994-12-09 Standard Forth by Wil Baden
      2001-O9-15 Minor changes and reformatting by Wil Baden 
      2002-04-19 Minor changes for kForth by Krishna Myneni	   

      Use, distribute, and modify this program freely.  [Haruhiko Okumura]


==== Intro by Wil Baden  1994-12-09 ===================================

Programmers are lousy lovers.  They always try to get the job done
faster than before.  And when they do, they brag that they have
better performance.  Programmers are the only men who boast how
small theirs is.

Since 1984 there has been amazing progress in data compression.

In the early 90's I got SALIENT SOFTWARE's AutoDoubler for the
Macintosh. My 80 megabyte hard drive had 2 meg available when I
installed the program. Since it was a Tuesday, I went out for lasagna,
and when I got back an hour later I had 19 meg available.

My 80 meg hard drive soon held 108 megs worth of data with
room for 25 to 50 more megabytes.

Not only that, but many programs loaded faster and read data
faster. When a file takes only half as much disk space, the data can
be read twice as fast.

How they do it is a trade secret, and Salient has applied for a
patent on their technology. There are also many variations possible
concerning details.

However, I have a good idea about where to begin looking.

Modern methods of data compression all go back to J. ZIV and A.
LEMPEL. In 1977 they published a paper in an engineering journal on
a new approach to data compresson.

  J. ZIV and A. LEMPEL, "A Universal Algorithm for Sequential Data
  Compression," IEEE Transactions on Information Theory, 23:3, 337-343.

In 1978 they published a paper about a related and more
elaborate method. In 1984 Unisys employee TERRY WELCH described
and had patented a version of the 1978 method suitable for
programming. This is called LZW for Lempel, Ziv, and Welch.

LZW is the basis of ARC and PKARC on the PC, compress in Unix, and
the original StuffIt on the Mac.

Around 1988 after losing a law suit PHIL KATZ [PKARC] came out with a 
better program, PKZIP. This is derived from the 1977 Ziv-Lempel paper. 
It turns out that the simpler method has better performance and is 
smaller. With additional processing, phenomonal results have been 
obtained. 

All popular archivers - arj, lha, zip, zoo, stac, auto-doubler,
current stuffit - are variations on the LZ77 theme.

The idea of LZ77 is very simple. It is explained in the FAQ
[frequently asked question] list for compression technology:

          The LZ77 family of compressors

  LZ77-based schemes keep track of the last n bytes of data seen, and
  when a phrase is encountered that has already been seen, they output a
  pair of values corresponding to the position of the phrase in the
  previously-seen buffer of data, and the length of the phrase.

  In effect the compressor moves a fixed-size "window" over the data
  generally referred to as a "sliding window" [or "ring buffer"], with
  the position part of the [position, length] pair referring to the
  position of the phrase within the window.

  The most commonly used algorithms are derived from the LZSS scheme
  described by JAMES STORER and THOMAS SZYMANSKI in 1982. In this the
  compressor maintains a window of size N bytes and a "lookahead buffer"
  the contents of which it tries to find a match for in the window:
)

\      while( lookAheadBuffer not empty )
\          {
\          get pointer ( position, match ) to the longest match in the window
\              for the lookahead buffer;
\
\          if( length > MINIMUM_MATCH_LENGTH )
\              {
\              output a ( position, length ) pair;
\              shift the window length characters along;
\              }
\          else
\              {
\              output the first character in the lookahead buffer;
\              shift the window 1 character along;
\              }
\          }

(
  Decompression is simple and fast: Whenever a [ position, length ] pair
  is encountered, go to that position in the window and copy length
  bytes to the output.

  Sliding-window-based schemes can be simplified by numbering the input
  text characters mod N, in effect creating a circular buffer. The
  sliding window approach automatically creates the LRU effect which must
  be done explicitly in LZ78 schemes.

  Variants of this method apply additional compression to the output of
  the LZSS compressor, which include a simple variable-length code [LZB],
  dynamic Huffman coding [LZH], and Shannon-Fano coding [ZIP 1.x], all
  of which result in a certain degree of improvement over the basic
  scheme, especially when the data are rather random and the LZSS
  compressor has little effect.

A copy of this FAQ is available by ftp from rtfm.mit.edu in
/pub/usenet/news.answers as compression-faq/part[1-3]. The profane
pseudocode given for LZ77 compression can be Forthed as:
)

\    BEGIN
\        look-ahead-buffer-used 0= not
\    WHILE
\        get-pointer(position,match)-to-longest-match
\        length minimum-match-length > IF
\            output-a-(position,match)-pair
\            shift-the-window-length-characters-along
\        ELSE
\            output-first-character-in-lookahead-buffer
\            shift-the-window-1-character-along
\        THEN
\    REPEAT

(
The bottleneck is the finding the longest match quickly. A naïve brute
force method is hardly acceptable. "It's hardly acceptable" is a
gentilism for "it sucks". Hashing, or binary search trees, or a
combination, is recommended.

 * Waterworth patented [4,701,745] the algorithm now known as LZRW1,
   because Ross Williams reinvented it later and posted it on
   comp.compression on April 22, 1991. The same algorithm has later
   been patented by Gibson & Graybill. The patent office failed to
   recognize that the same algorithm was patented twice, even though
   the wording used in the two patents is very similar.

   The Waterworth patent is now owned by Stac Inc, which won a lawsuit
   against Microsoft, concerning the compression feature of MSDOS 6.0.
   Damages awarded were $120 million.

 * Fiala and Greene obtained in 1990 a patent [4,906,991] on all
   implementations of LZ77 using a tree data structure.

 * Notenboom [from Microsoft] 4,955,066 uses three levels of
   compression, starting with run length encoding.

 * The Gibson & Graybill patent 5,049,881 covers the LZRW1 algorithm
   previously patented by Waterworth and reinvented by Ross Williams.
   Claims 4 and 12 are very general and could be interpreted as
   applying to any LZ algorithm using hashing, including all variants
   of LZ78:

 * Phil Katz, author of pkzip, also has a patent on LZ77 [5,051,745]
   but the claims only apply to sorted hash tables, and when the hash
   table is substantially smaller than the window size.

 * IBM patented [5,001,478] the idea of combining a history buffer,
   the LZ77 technique, and a lexicon [as in LZ78].

 * Stac Inc patented [5,016,009 and 5,126,739] yet another variation
   of LZ77 with hashing. The '009 patent was used in the lawsuit
   against Microsoft [see above]. Stac also has patents on LZ77 with
   parallel lookup in hardware [4,841,092 and 5,003,307].

 * Chambers 5,155,484 is yet another variation of LZ77 with hashing.
   The hash function is just the juxtaposition of two input bytes.
   This is the "invention" being patented. The hash table is named
   "direct lookup table". [Chambers is the author of AutoDoubler and
   DiskDoubler.]

A simple implementation of LZSS using binary search trees giving
very good but not best performance was put into the public domain
in 1988 by HARUHIKO OKUMURA. This implementation has inspired the
high performance programs now in use.

Given here is a Standard Forth version of that program. It shows
its genealogy by the unusually long Forth definitions. I believe that
politically correct factoring would not help understanding and would
degrade performance. This program is 8 to 10 times faster than the
brute force implementation I gave at the 1992 FORML Conference. It
can serve as material for studying data compression in Forth, as the
original program did in C and Pascal.

As an example, here is the beginning of _Green Eggs and Ham_,
copyright 1960, DR. SEUSS.

    That Sam-I-am!
    That Sam-I-am!
    I do not like that Sam-I-am!

    Do you like green eggs and ham?

    I do not like them, Sam-I-am.
    I do not like green eggs and ham.

Compressed with LZSS this becomes:

    |That Sam|-I-am!
    []|I do not| like t[]|
    Do you[]|green eg|gs and h|am?
    []em,|[].[][].

"|" represents a format byte. "[]" represents a two-byte position
and length.
)
\  End of Intro by Wil Baden 

\ Requirements for kForth: ans-words.4th  strings.4th  files.4th

\ =================================================================
\        General Utilities
\ =================================================================

    : checked ABORT" File Access Error. " ;      ( ior -- )
    \ : Checked FILE-CHECK ;

    CREATE Single-Char-I/O-Buffer    3 CHARS ALLOT

    : Read-Char                    ( file -- char )
        Single-Char-I/O-Buffer 1 ROT READ-FILE Checked IF
            Single-Char-I/O-Buffer C@
        ELSE
            -1
        THEN ;

    : Write-String   WRITE-FILE Checked ;

    : Closed CLOSE-FILE Checked ;

    : 'th   ( n "addr" -- addr+4n )
    	S" CELLS " EVALUATE
        BL WORD COUNT EVALUATE
        S" + " EVALUATE
        ; IMMEDIATE

    : BUFFER:   CREATE  ALLOT ;

\ =================================================================
\       Data
\ =================================================================

\      [Comments by Haruhiko Okumura]


4096  CONSTANT    N     \  Size of Ring Buffer
18    CONSTANT    F     \  Upper Limit for match-length
2     CONSTANT    THRESHOLD  \  Encode string into position & length
                        \  when match-length is greater.
N     CONSTANT    NIL   \  Index for Binary Search Tree Root

VARIABLE    Textsize    \  Text Size Counter
VARIABLE    Codesize    \  Code Size Counter

\  These are set by Insert-Node procedure.

VARIABLE    Match-Position
VARIABLE    Match-Length

N  F 1-  +  2 +  BUFFER: Text-Buf   \  Ring buffer of size N, with extra
                            \  F-1 bytes to facilitate string comparison.

\  Left & Right Children and Parents -- Binary Search Trees

N 1+    CELLS BUFFER: LSon
N 257 + CELLS BUFFER: RSon
N 1+    CELLS BUFFER: DAD

\  Input & Output Files

VARIABLE In-File
VARIABLE Out-File

\  For i = 0 to N - 1, RSon[i] and LSon[i] will be the right and
\  left children of node i.  These nodes need not be initialized.
\  Also, DAD[i] is the parent of node i.  These are initialized to
\  NIL = N, which stands for "not used".
\  For i = 0 to 255, RSon[N + i + 1] is the root of the tree
\  for strings that begin with character i.  These are initialized
\  to NIL.  Note there are 256 trees.

      : N-MOD   4095 AND ;   \  Modulo N

\ =================================================================
\        Initialize trees
\ =================================================================

\  Initialize trees.

: Init-Tree                                \ ( -- )
      N 257 +  N 1+  DO  NIL  I 'th RSon !  LOOP
      N  0  DO  NIL  I 'th DAD !  LOOP
      0 Textsize !  0 Codesize ! ;

\ =================================================================
\        Insert-Node
\ =================================================================


\  Insert string of length F, Text-Buf[r..r+F-1], into one of the
\  trees of Text-Buf[r]'th tree and return the longest-match position
\  and length via the global variables Match-Position and
\  Match-Length.  If Match-Length = F, then remove the old node in
\  favor of the new one, because the old one will be deleted sooner.
\  Note r plays double role, as tree node and position in buffer.

: Insert-Node                              ( r -- )
      NIL over 'th LSon !    NIL over 'th RSon !    0 Match-Length !
      dup Text-Buf + C@  N +  1+                ( r p)
      1                                         ( r p cmp)
      BEGIN                                     ( r p cmp)
            0< NOT IF                           ( r p)
                  dup 'th RSon @ NIL = NOT IF
                        'th RSon @
                  ELSE
                        2dup 'th RSon !
                        SWAP 'th DAD !          ( )
                  EXIT THEN
            ELSE                                ( r p)
                  dup 'th LSon @ NIL = NOT IF
                        'th LSon @
                  ELSE
                        2dup 'th LSon !
                        SWAP 'th DAD !          ( )
                  EXIT THEN
            THEN                                ( r p)
            0 F dup 1 DO                        ( r p . .)
                  3 PICK I + Text-Buf + C@      ( r p . .  c)
                  3 PICK I + Text-Buf + C@ -    ( r p . . cmp)
                  ?dup IF  NIP NIP  I  LEAVE  THEN  ( r p . .)
            LOOP                                ( r p cmp i)
            dup Match-Length @ > IF
                  2 PICK Match-Position !
                  dup Match-Length !
                  F < NOT
            ELSE
                  DROP FALSE
            THEN                                ( r p cmp flag)
      UNTIL                                     ( r p cmp)
      DROP                                      ( r p)
      2dup 'th DAD @ SWAP 'th DAD !
      2dup 'th LSon @ SWAP 'th LSon !
      2dup 'th RSon @ SWAP 'th RSon !
      2dup 'th LSon @ 'th DAD !
      2dup 'th RSon @ 'th DAD !
      dup 'th DAD @ 'th RSon @ over = IF
            TUCK 'th DAD @ 'th RSon !
      ELSE
            TUCK 'th DAD @ 'th LSon !
      THEN                                      ( p)
      'th DAD NIL SWAP !    \  Remove p         ( )
      ;

\ =================================================================
\        Delete-Node
\ =================================================================

\  Delete node p from tree.

: Delete-Node                              ( p -- )
      dup 'th DAD @ NIL = IF  DROP  EXIT THEN   \  Not in tree.
      dup 'th RSon @ NIL = IF
            dup 'th LSon @
      ELSE
      dup 'th LSon @ NIL = IF
            dup 'th RSon @
      ELSE
            dup 'th LSon @                      ( p q)
            dup 'th RSon @ NIL = NOT IF
                  BEGIN
                        'th RSon @
                        dup 'th RSon @ NIL =
                  UNTIL
                  dup 'th LSon @ over 'th DAD @ 'th RSon !
                  dup 'th DAD @ over 'th LSon @ 'th DAD !
                  over 'th LSon @ over 'th LSon !
                  over 'th LSon @ 'th DAD over SWAP !
            THEN
            over 'th RSon @ over 'th RSon !
            over 'th RSon @ 'th DAD over SWAP !
      THEN THEN                                ( p q)
      over 'th DAD @ over 'th DAD !
      over dup 'th DAD @ 'th RSon @ = IF
            over 'th DAD @ 'th RSon !
      ELSE
            over 'th DAD @ 'th LSon !
      THEN                                      ( p)
      'th DAD NIL SWAP ! ;                      ( )

\ =================================================================
\        Statistics
\ =================================================================

: Statistics                              ( -- )
      ." In : "   Textsize ?   CR
      ." Out: "   Codesize ?   CR
      Textsize @ IF
            ." Saved: " Textsize @  Codesize @ -  100 Textsize @ */
                  2 .R ." %" CR
      THEN
      ;

\ =================================================================
\        Encode
\ =================================================================

      17 2 + BUFFER:  Code-Buf

      VARIABLE    Len
      VARIABLE    Last-Match-Length
      VARIABLE    Code-Buf-Ptr

      VARIABLE    Mask

: Encode                                  ( -- )
      Init-Tree    \  Initialize trees.

      \  Code-Buf[1..16] holds eight units of code, and Code-Buf[0]
      \  works as eight flags, "1" representing that the unit is an
      \  unencoded letter in 1 byte, "0" a position-and-length pair
      \  in 2 bytes.  Thus, eight units require at most 16 bytes
      \  of code.

      0 Code-Buf C!
      1 Mask C!   1 Code-Buf-Ptr !
      0  N F -                                  ( s r)

      \  Clear the buffer with a character that will appear often.
      Text-Buf  N F -  BL  FILL

      \  Read F bytes into the last F bytes of the buffer.
      dup Text-Buf + F In-File @ READ-FILE Checked   ( s r count)
      dup Len !  dup Textsize !
      0= IF  2DROP  EXIT THEN                   ( s r)

      \  Insert the F strings, each of which begins with one or more
      \  "space" characters.  Note the order in which these strings
      \  are inserted.  This way, degenerate trees will be less
      \  likely to occur.

      F  1+ 1 DO  dup I - Insert-Node  LOOP

      \  Finally, insert the whole string just read.  The global
      \  variables Match-Length and Match-Position are set.
      dup ( r) Insert-Node

      BEGIN                                     ( s r)
            \  Match-Length may be spuriously long at end of text.
            Match-Length @ Len @ > IF  Len @ Match-Length !  THEN

            Match-Length @ THRESHOLD > NOT IF
                  \  Not long enough match.  Send one byte.
                  1 Match-Length !
                  \  "send one byte" flag
                  Mask C@ Code-Buf C@ OR Code-Buf C!
                  \  Send uncoded.
                  dup Text-Buf + C@ Code-Buf-Ptr @ Code-Buf + C!
                  1 Code-Buf-Ptr +!
            ELSE
                  \  Send position and length pair.
                  \  Note Match-Length > THRESHOLD.
                  Match-Position @  Code-Buf-Ptr @ Code-Buf + C!
                  1 Code-Buf-Ptr +!
                  Match-Position @  8 RSHIFT  4 LSHIFT ( . . j)
                        Match-Length @  THRESHOLD -  1-  OR
                        Code-Buf-Ptr @  Code-Buf + C!  ( . .)
                  1 Code-Buf-Ptr +!
            THEN
            \  Shift mask left one bit. )        ( . .)
            Mask C@  2*  Mask C!  Mask C@ 0= IF
                  \  Send at most 8 units of code together.
                  Code-Buf  Code-Buf-Ptr @    ( . . a k)
                        Out-File @ Write-String ( . .)
                  Code-Buf-Ptr @  Codesize  +!
                  0 Code-Buf C!    1 Code-Buf-Ptr !    1 Mask C!
            THEN                                ( s r)
            Match-Length @ Last-Match-Length !
            Last-Match-Length @ dup 0 DO        ( s r n)
                  In-File @ Read-Char           ( s r n c)
                  dup 0< IF  2DROP I LEAVE  THEN
                  \  Delete old strings and read new bytes.
                  3 PICK ( s) Delete-Node
                  dup 4 PICK ( c s) Text-Buf + C!
                  \  If the position is near end of buffer, extend
                  \  the buffer to make string comparison easier.
                  3 PICK ( s) F 1- < IF         ( s r n c)
                        dup 4 PICK ( c s) N + Text-Buf + C!
                  THEN
                  DROP                          ( s r n)
                  \  Since this is a ring buffer, increment the
                  \  position modulo N.
                  >R >R                         ( s)
                        1+  N-MOD
                  R>                            ( s r)
                        1+  N-MOD
                  R>                            ( s r n)
                  \  Register the string in Text-Buf[r..r+F-1].
                  over Insert-Node
            LOOP                                ( s r i)
            dup Textsize +!

            \  After the end of text, no need to read, but
            \  buffer might not be empty.
            Last-Match-Length @ SWAP ( s r l i) ?DO  ( s r)
                  over Delete-Node
                  >R  ( s) 1+  N-MOD  R>
                  ( r) 1+  N-MOD
                  -1 Len +!  Len @ IF
                        dup Insert-Node
                  THEN
            LOOP

            Len @ 0> NOT
      UNTIL  2DROP                              ( )

      \  Send remaining code.
      Code-Buf-Ptr @ 1 > IF
            Code-Buf  Code-Buf-Ptr @  Out-File @ Write-String
            Code-Buf-Ptr @ Codesize +!
      THEN

      Statistics ;

\ =================================================================
\        Decode
\ =================================================================

\  Just the reverse of Encode.

: Decode                                  ( -- )
      \  [Warning: Does not close In-File or Out-File.]
      Text-Buf  N F -  BL FILL
      0  N F -                                  ( flags r)
      BEGIN
            >R                                  ( flags)
                  1 RSHIFT dup 256 AND 0= IF DROP     ( )
                        In-File @ Read-Char       ( c)
                        dup 0< IF  R> 2DROP  EXIT THEN
                        [ HEX ] 0FF00 [ DECIMAL ] OR ( flags)
                        \  Uses higher byte to count eight.
                  THEN
            R>                                  ( flags r)
            over 1 AND IF
                  In-File @ Read-Char           ( . r c)
                  dup 0< IF  DROP 2DROP  EXIT THEN
                  over Text-Buf + C!            ( . r)
                  dup Text-Buf + 1 Out-File @ Write-String
                  1+  N-MOD
            ELSE
                  In-File @ Read-Char           ( . r i)
                  dup 0< IF  DROP 2DROP  EXIT THEN
                  In-File @ Read-Char           ( . . i j)
                  dup 0< IF  2DROP 2DROP  EXIT THEN
                  dup >R  4 RSHIFT  8 LSHIFT OR  R>
                  15 AND  THRESHOLD +  1+
                  0 ?DO                                  ( . r i)
                        dup I +  N-MOD  Text-Buf +       ( . r i addr)
                        dup 1 Out-File @ Write-String
                        C@  2 PICK ( c r) Text-Buf + C!  ( . r i)
                        >R  ( r) 1+  N-MOD  R>
                  LOOP                          ( . r i)
                  DROP                          ( flags r)
            THEN
      AGAIN ;

\  End of LZ77
