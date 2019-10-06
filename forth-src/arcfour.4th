\ arcfour.4th
\ ARCFOUR - Alleged RC4
(
                               Neil Bawd 1997-05-25 2000-07-16

In 1987 Ron Rivest developed the RC4 cipher-system for RSA 
Data Security, Inc. It used a well-guarded proprietary trade 
secret. The system was popular and is used in several hundred 
commercial cryptography products, including Lotus Notes, 
Apple Computer's AOCE, and Oracle Secure SQL. It is part of 
the Cellular Digital Packet Data Specification, and is used 
by Internet Explorer, Netscape, and Adobe Acrobat. 

Seven years later, source code alleged to be equivalent to
RC4 was published anonymously on the Cypherpunks mailing
list.  Users with legal copies of RC4 confirmed compatibility.

The code is extremely simple and can be written by most
programmers from the description.

  We have an array of 256 bytes, all different.

  Every time the array is used it changes - by swapping
  two bytes.

  The swaps are controlled by counters _i_ and _j_, each
  initially 0.

  To get a new _i_, add 1.

  To get a new _j_, add the array byte at the new _i_.

  Exchange the array bytes at _i_ and _j_.

  The code is the array byte at the sum of the array bytes
  at _i_ and _j_.

  This is XORed with a byte of the plaintext to encrypt, or
  the ciphertext to decrypt.

  The array is initialized by first setting it to 0 through
  255. Then step through it using _i_ and _j_, getting the new
  _j_ by adding to it the array byte at _i_ and a key byte, and
  swapping the array bytes at _i_ and _j_.  Finally, _i_ and _j_
  are set to 0.

  All additions are modulo 256.

The cipher key to be used when initializing can be up to 256
bytes, i.e., 2048 bits.  It works best when it's shorter so
the randomizing done at initialization can thoroughly shuffle
the array.  At most 64 bytes are recommended for the key.

The name "RC4" is trademarked by RSA Data Security, Inc. So
anyone who writes his own code has to call it something else.
In 1997 I called it ARCIPHER. ARCFOUR has been since
widely accepted as the name of the alleged RC4.

It is popular because it is small, fast, and believed to be
secure.

It's a rare example of Cheap, Fast, and Good.

For further information, see http://ciphersaber.gurus.com

The following Standard Forth version uses Core words only.
The number of fetches and stores in `ARCFOUR` has been
minimized.  There is no need to optimize `ARCFOUR-INIT`.

)

\  Implementation dependency on 1 CHARS is 1.

\  All arithmetic modulo 256.
\  i = i + 1
\  j = j + S[i]
\  temp = S[i]; S[i] = S[j]; S[j] = temp
\  temp = S[S[i]+S[j]]
\  return char xor temp

\ Insignificant mods to Neil Bawd's code were made for 
\ use under kForth -- Krishna Myneni, 2002-04-26
\ Requires ans-words.4th

VARIABLE &I   VARIABLE &J
CREATE &S  256 CHARS ALLOT

\  @ and ! may be replaced by C@ and C!.

: ARCFOUR  ( c -- x )
    \  All arithmetic modulo 256.
    \  i = i + 1
    &I @  1+  DUP &I !  255 AND   ( . i)

    \  j = j + S[i]
    &S +  DUP C@          ( . &S[i] S[i])
    DUP &J @ +  255 AND   ( . &S[i] S[i] j)
    DUP &J !

    \  temp = S[i]; S[i] = S[j]; S[j] = temp
    &S +  DUP C@          ( . &S[i] S[i] &S[j] S[j])
    >R  OVER SWAP C!      ( . &S[i] S[i])( R: S[j])
    R@ ROT C!             ( . S[i])

    \  temp = S[i]; S[i] = S[j]; S[j] = temp
    R> +                  ( . S[i]+S[j])( R: )
    255 AND &S + C@       ( c x)

    \  return char xor temp
    XOR ( x) ;

: ARCFOUR-INIT              ( key len -- )
    \  Set array to 0 through 255.
    256 0 DO  I DUP &S + C!  LOOP

    0 &J !
    256 0 DO                        ( key len)
        \  Get new j by adding array byte at i and a key byte.
        2DUP I SWAP MOD + C@  I &S + C@ +
            &J @ +  255 AND  &J !
        \  Swap array bytes at i and j.
        I &S + C@  &J @ &S +  &J @ &S + C@  I &S +  C! C!
    LOOP  2DROP                     ( )

    \  Set i and j to 0.
    0 &I !  0 &J ! ;


(
To compete with the many appearances of RC4, a Forth
version should be a CODE definition for speed.  In this CODE
definition, there is no stack movement. It is more than 4.5
times as fast as the colon version above.

    CREATE Arcfour-State  2 CELLS 256 CHARS + ALLOT
    
    : MACRO                  \ "name <char> ccc<char>" -- 
        :   CHAR PARSE POSTPONE SLITERAL  POSTPONE EVALUATE
        POSTPONE ; IMMEDIATE
        ;
    
    MACRO &I " Arcfour-State "
    MACRO &J " Arcfour-State CELL+ "
    MACRO &S " Arcfour-State 2 CELLS + " 
    
    CODE ARCFOUR  \ char -- code 
        \  RX    i
        \  RY    j
        \  R30   S[i] finally S[S[i]+S[j]]
        \  R31   S[j]
        \  R29   &i, then &S, then char, then code
    
        \  Save local registers.
        R31 -4 RRSP STWU,
        R30 -4 RRSP STWU,
        R29 -4 RRSP STWU,
    
        \  RTOS = Arcfour-State
        RTOS  -4 RDSP  STWU,       \ . .
        ['] Arcfour-State info-find-token @infoDataOffset
            R29 LiteralToRegister,
            R29 RDBP ADD,
    
        \  To get a new i, add 1.
        RX 0 R29 LWZ,        \  rx = i
        RX RX 1 ADDI,        \  rx = rx + 1
        RX 0 R29 STW,        \  i = rx
        RX RX 255 ANDI.,     \  rx = rx mod 256
    
        \  To get a new j, add the array byte at the new i.
        R29 R29 8 ADDI,      \  rtos = &S
        R30 R29 RX LBZX,     \  r30 = S[i]
        RY  -4 R29 LWZ,      \  ry = j
        RY  RY R30 ADD,      \  ry = ry + S[i]
        RY  RY 255 ANDI.,    \  ry = ry mod 256
        RY  -4 R29 STW,      \  j = ry
    
        \  Swap the array bytes at i and j.
        R31  R29 RY LBZX,
        R30  R29 RY STBX,
        R31  R29 RX STBX,
    
        \  The code is the array byte at the sum of the
        \  array bytes at i and j.
        R30 R31 ADD,
        R30 R30 255 ANDI.,
        R30 R29 R30 LBZX,
    
        \  XOR with plaintext or ciphertext byte.
        RTOS R30 XOR,
    
        \  Restore local registers.
        R29 0 RRSP LWZ,
        R30 4 RRSP LWZ,
        R31 8 RRSP LWZ,
        RRSP 12 ADDI,
    
        NEXT, END-CODE
    
    \ Definition of ARCFOUR-INIT copied from above.
)


\ This is one of many tests to validate the code.  It 
\ works with any correct version of `ARCFOUR`.

include ttester

CREATE KEY: 64 ALLOT

\ !KEY  km 2002-04-26

: !KEY ( c1 c2 ... cn n -- store the specified key of length n )
	DUP KEY: C! KEY: + KEY: 1+ SWAP ?DO I C! -1 +LOOP ;

base @  
HEX  
61 8A 63 0D2 0FB  5 !KEY

KEY: COUNT ARCFOUR-INIT
TESTING ARCFOUR
t{  0DC  ARCFOUR  ->  F1  }t
t{  0EE  ARCFOUR  ->  38  }t
t{  04C  ARCFOUR  ->  29  }t
t{  0F9  ARCFOUR  ->  C9  }t
t{  02C  ARCFOUR  ->  DE  }t

\ CR .( Should be: F1 38 29 C9 DE -- Fox 1; 3 8; 2 9; Charlie 9; Dog Easy. ) 
base !

\  End of ARCFOUR
