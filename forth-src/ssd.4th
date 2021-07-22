\ ssd.4th
\ 
\ SEE facility and Single-Step Debugger for kForth
\ (Preliminary, for kForth-32 v2.x and kForth-64 v0.2.x)
\
\  K. Myneni, 2021-07-19
\
\ Requires: ans-words.4th
\ Revisions:
\   2021-07-19  km  first release; SEE works;
\                   single step debug is limited.
\   2021-07-21  km  code cleanup and one fix to OP.

[UNDEFINED] BEGIN-STRUCTURE [IF] include struct-200x [THEN]
[UNDEFINED] BEGIN-MODULE [IF] include modules [THEN]
[UNDEFINED] DUMP [IF] include dump [THEN]
[UNDEFINED] CELL- [IF] : cell- 1 cells - ; [THEN]
 
MODULE: ssd

BEGIN-MODULE

DECIMAL

1 CELLS 4 = constant 32-bit?
[DEFINED] FDEPTH constant fp-stack?

Public:

BEGIN-STRUCTURE TInfo%  \ byte code token info
  FIELD:  T->NameCount  \ name string count
  FIELD:  T->Name       \ name string address
  FIELD:  T->OpCount    \ trailing operand count in cells
END-STRUCTURE

BEGIN-STRUCTURE ExtTInfo%  \ extended token info
  drop TInfo%              \ structure inherits TInfo% fields
  FIELD:  ET->NCaddr       \ native code address
END-STRUCTURE

256 constant MAX_TOKENS
256 constant MAX_EXT_TOKENS

Create TI TInfo%     MAX_TOKENS     * ALLOT
Create ETI ExtTInfo% MAX_EXT_TOKENS * ALLOT

\ index token structure for given opcode 
: op[] ( op -- addr )
    dup MAX_TOKENS < IF
      TInfo% * TI
    ELSE
      MAX_TOKENS - ExtTInfo% * ETI
    THEN + ;


: ti! ( c-addr u noperands op | c-addr u nop addr-nc op -- )
    dup MAX_TOKENS >= >r
    op[]
    r> IF tuck ET->NCaddr ! THEN
    tuck T->OpCount !  
    tuck T->NameCount !
         T->Name ! ;

: opname@ ( op -- caddr u )
    op[] dup 
    T->NameCount @ swap 
    T->Name a@ swap
;

: operand-count@ ( op -- u )
    op[] T->OpCount @ ;
 

\ XT>ITC and XT>NC are kForth-specific!

: xt>ITC ( xt -- aITC ) a@ ;
: xt>NC  ( xt -- addr ) a@ 1+ a@ ; \ for use with extended byte codes
: nt>ITC ( nt -- aITC | 0 ) name>interpret dup IF xt>ITC THEN ;
: nc' ( "name" -- addr-nc ) ' xt>nc ;

variable searchITC
variable searchName
variable searchCount

: find-ITC ( nt -- flag )
    dup name>interpret xt>ITC searchITC a@ =
    IF  name>string searchCount ! searchName ! false
    ELSE  drop true
    THEN ;

: ITC>string ( aITC -- caddr u )
    searchITC ! 0 searchName ! 0 searchCount !
    get-order 0 DO
      searchCount @ 0= IF
        ['] find-ITC swap traverse-wordlist
      ELSE drop
      THEN
    LOOP
    searchName a@ searchCount @ ;

: NC>string ( addr-nc -- caddr u )
    MAX_EXT_TOKENS MAX_TOKENS + MAX_TOKENS DO
      dup I op[] ET->NCaddr a@ = IF
        drop I opname@
        UNLOOP EXIT
      THEN
    LOOP
    0 ;


: next-ITC-count ( aITC -- aITC u )
    dup c@ operand-count@ cells 1+ ;


Private:
  0  constant  OP_FALSE
  1  constant  OP_TRUE
  2  constant  OP_CELLS
  3  constant  OP_CELL+
  4  constant  OP_DFLOATS
  5  constant  OP_DFLOAT+
  6  constant  OP_CASE
  7  constant  OP_ENDCASE
  8  constant  OP_OF
  9  constant  OP_ENDOF
 10  constant  OP_OPEN
 11  constant  OP_LSEEK
 12  constant  OP_CLOSE
 13  constant  OP_READ
 14  constant  OP_WRITE
 15  constant  OP_IOCTL
 16  constant  OP_USLEEP
 17  constant  OP_MS
 18  constant  OP_MS@
 19  constant  OP_SYSCALL
 20  constant  OP_FILL
 21  constant  OP_CMOVE
 22  constant  OP_CMOVE>
 23  constant  OP_.(
 24  constant  OP_<#
 25  constant  OP_EXECUTE-BC
 26  constant  OP_FSYNC
 27  constant  OP_#>
 28  constant  OP_#S
 29  constant  OP_S"
 30  constant  OP_CR
 31  constant  OP_BL
 32  constant  OP_SPACES
 33  constant  OP_!
 34  constant  OP_C"
 35  constant  OP_#
 36  constant  OP_SIGN
 37  constant  OP_MOD
 38  constant  OP_AND
 39  constant  OP_'
 40  constant  OP_(
 41  constant  OP_HOLD
 42  constant  OP_*
 43  constant  OP_+

 45  constant  OP_-
 46  constant  OP_.
 47  constant  OP_/
 48  constant  OP_DABS
 49  constant  OP_DNEGATE
 50  constant  OP_UM*
 51  constant  OP_UM/MOD
 52  constant  OP_M*
 53  constant  OP_M+
 54  constant  OP_M/
 55  constant  OP_M*/
 56  constant  OP_FM/MOD
 57  constant  OP_SM/REM
 58  constant  OP_:
 59  constant  OP_;
 60  constant  OP_<
 61  constant  OP_=
 62  constant  OP_>
 63  constant  OP_?
 64  constant  OP_@
 65  constant  OP_ADDR
 66  constant  OP_BASE
 67  constant  OP_CALL
 68  constant  OP_DEFINITION
 69  constant  OP_ERASE
 70  constant  OP_FVAL
 71  constant  OP_CALLADDR
 72  constant  OP_>BODY
 73  constant  OP_IVAL
 74  constant  OP_EVALUATE
 75  constant  OP_KEY
 76  constant  OP_LSHIFT
 77  constant  OP_/MOD
 78  constant  OP_PTR
 79  constant  OP_.R
 80  constant  OP_D.
 81  constant  OP_KEY?
 82  constant  OP_RSHIFT
 83  constant  OP_.S
 84  constant  OP_ACCEPT
 85  constant  OP_CHAR
 86  constant  OP_[CHAR]
 87  constant  OP_WORD
 88  constant  OP_*/
 89  constant  OP_*/MOD
 90  constant  OP_U.R
 91  constant  OP_[
 92  constant  OP_\
 93  constant  OP_]
 94  constant  OP_XOR
 95  constant  OP_LITERAL
 96  constant  OP_ALLOT?
 97  constant  OP_ALLOT
 98  constant  OP_BINARY
 99  constant  OP_COUNT
100  constant  OP_DECIMAL
101  constant  OP_EMIT
102  constant  OP_F.
103  constant  OP_COLD
104  constant  OP_HEX
105  constant  OP_I
106  constant  OP_J
107  constant  OP_[']
108  constant  OP_FVARIABLE
109  constant  OP_2!
110  constant  OP_FIND
111  constant  OP_CONSTANT
112  constant  OP_IMMEDIATE
113  constant  OP_FCONSTANT
114  constant  OP_CREATE
115  constant  OP_."
116  constant  OP_TYPE
117  constant  OP_U.
118  constant  OP_VARIABLE
119  constant  OP_WORDS
120  constant  OP_DOES>
121  constant  OP_2VAL
122  constant  OP_2@
123  constant  OP_SEARCH
124  constant  OP_OR
125  constant  OP_COMPARE
126  constant  OP_NOT
127  constant  OP_MOVE
128  constant  OP_FSIN
129  constant  OP_FCOS
130  constant  OP_FTAN
131  constant  OP_FASIN
132  constant  OP_FACOS
133  constant  OP_FATAN
134  constant  OP_FEXP
135  constant  OP_FLN
136  constant  OP_FLOG
137  constant  OP_FATAN2
138  constant  OP_FTRUNC
139  constant  OP_FTRUNC>S
140  constant  OP_FMIN
141  constant  OP_FMAX
142  constant  OP_FLOOR
143  constant  OP_FROUND
144  constant  OP_D<
145  constant  OP_D0=
146  constant  OP_D=
147  constant  OP_2>R
148  constant  OP_2R>
149  constant  OP_2R@
150  constant  OP_S>D
151  constant  OP_S>F
152  constant  OP_D>F
153  constant  OP_FROUND>S
154  constant  OP_F>D
155  constant  OP_DEG>RAD
156  constant  OP_RAD>DEG
157  constant  OP_D+
158  constant  OP_D-
159  constant  OP_DU<
160  constant  OP_1+
161  constant  OP_1-
162  constant  OP_ABS
163  constant  OP_NEGATE
164  constant  OP_MIN
165  constant  OP_MAX
166  constant  OP_2*
167  constant  OP_2/
168  constant  OP_2+
169  constant  OP_2-
170  constant  OP_C@
171  constant  OP_C!
172  constant  OP_SW@
173  constant  OP_W!
174  constant  OP_DF@
175  constant  OP_DF!
176  constant  OP_SF@
177  constant  OP_SF!
178  constant  OP_SP@
179  constant  OP_+!
180  constant  OP_F+
181  constant  OP_F-
182  constant  OP_F*
183  constant  OP_F/
184  constant  OP_FABS
185  constant  OP_FNEGATE
186  constant  OP_F**
187  constant  OP_FSQRT
188  constant  OP_SP!
189  constant  OP_RP!
190  constant  OP_F=
191  constant  OP_F<>
192  constant  OP_F<
193  constant  OP_F>
194  constant  OP_F<=
195  constant  OP_F>=
196  constant  OP_F0=
197  constant  OP_F0<
198  constant  OP_F0>
199  constant  OP_F~
200  constant  OP_DROP
201  constant  OP_DUP
202  constant  OP_SWAP
203  constant  OP_OVER
204  constant  OP_ROT
205  constant  OP_-ROT
206  constant  OP_NIP
207  constant  OP_TUCK
208  constant  OP_PICK
209  constant  OP_ROLL
210  constant  OP_2DROP
211  constant  OP_2DUP
212  constant  OP_2SWAP
213  constant  OP_2OVER
214  constant  OP_2ROT
215  constant  OP_DEPTH
216  constant  OP_?DUP
217  constant  OP_IF
218  constant  OP_ELSE
219  constant  OP_THEN
220  constant  OP_>R
221  constant  OP_R>
222  constant  OP_IP>R
223  constant  OP_R@
224  constant  OP_RP@
225  constant  OP_A@
226  constant  OP_DO
227  constant  OP_LEAVE
228  constant  OP_?DO
229  constant  OP_ABORT"
230  constant  OP_JZ
231  constant  OP_JNZ
232  constant  OP_JMP
233  constant  OP_RTLOOP
234  constant  OP_RT+LOOP
235  constant  OP_RTUNLOOP
236  constant  OP_EXECUTE
237  constant  OP_RECURSE
238  constant  OP_RET
239  constant  OP_ABORT
240  constant  OP_QUIT
241  constant  OP_>=
242  constant  OP_<=
243  constant  OP_<>
244  constant  OP_0=
245  constant  OP_0<>
246  constant  OP_0<
247  constant  OP_0>
248  constant  OP_U<
249  constant  OP_U>
250  constant  OP_BEGIN
251  constant  OP_WHILE
252  constant  OP_REPEAT
253  constant  OP_UNTIL
254  constant  OP_AGAIN
255  constant  OP_BYE
256  constant  OP_UTM/
257  constant  OP_UTS/MOD
258  constant  OP_STS/REM
259  constant  OP_UDM*
260  constant  OP_INCLUDED
261  constant  OP_INCLUDE
262  constant  OP_SOURCE
263  constant  OP_REFILL
264  constant  OP_STATE
265  constant  OP_ALLOCATE
266  constant  OP_FREE
267  constant  OP_RESIZE

269  constant  OP_DS*
270  constant  OP_COMPILE,
271  constant  OP_COMPILE-NAME
272  constant  OP_POSTPONE
273  constant  OP_NONDEFERRED
274  constant  OP_FORGET
275  constant  OP_FORTH-SIGNAL
276  constant  OP_RAISE
277  constant  OP_SET-ITIMER
278  constant  OP_GET-ITIMER
279  constant  OP_US2@
280  constant  OP_>FLOAT
281  constant  OP_FSINCOS
282  constant  OP_FACOSH
283  constant  OP_FASINH
284  constant  OP_FATANH
285  constant  OP_FCOSH
286  constant  OP_FSINH
287  constant  OP_FTANH
288  constant  OP_FALOG
289  constant  OP_D0<
290  constant  OP_DMAX
291  constant  OP_DMIN
292  constant  OP_D2*
293  constant  OP_D2/
294  constant  OP_UD.
295  constant  OP_WITHIN
296  constant  OP_2LITERAL
297  constant  OP_>NUMBER
298  constant  OP_NUMBER?
299  constant  OP_SLITERAL
300  constant  OP_FLITERAL
301  constant  OP_2VARIABLE
302  constant  OP_2CONSTANT

304  constant  OP_>FILE
305  constant  OP_CONSOLE

309  constant  OP_:NONAME
310  constant  OP_SPACE
311  constant  OP_BLANK
312  constant  OP_/STRING
313  constant  OP_-TRAILING
314  constant  OP_PARSE
315  constant  OP_PARSE-NAME

320  constant  OP_DLOPEN
321  constant  OP_DLERROR
322  constant  OP_DLSYM
323  constant  OP_DLCLOSE
324  constant  OP_US
325  constant  OP_ALIAS
326  constant  OP_SYSTEM
327  constant  OP_CHDIR
328  constant  OP_TIME&DATE

330  constant  OP_WORDLIST
331  constant  OP_FORTH-WORDLIST
332  constant  OP_GET-CURRENT
333  constant  OP_SET-CURRENT
334  constant  OP_GET-ORDER
335  constant  OP_SET-ORDER
336  constant  OP_SEARCH-WORDLIST
337  constant  OP_DEFINITIONS
338  constant  OP_VOCABULARY

340  constant  OP_ONLY
341  constant  OP_ALSO
342  constant  OP_ORDER
343  constant  OP_PREVIOUS
344  constant  OP_FORTH
345  constant  OP_ASSEMBLER
346  constant  OP_TRAVERSE-WORDLIST
347  constant  OP_NAME>STRING
348  constant  OP_NAME>INTERPRET
349  constant  OP_NAME>COMPILE
350  constant  OP_DEFINED
351  constant  OP_UNDEFINED

360  constant  OP_PRECISION
361  constant  OP_SET-PRECISION

363  constant  OP_FS.

365  constant  OP_FPICK
366  constant  OP_FEXPM1
367  constant  OP_FLNP1
368  constant  OP_UD.R
369  constant  OP_D.R
370  constant  OP_F2DROP
371  constant  OP_F2DUP

381  constant  OP_FDEPTH
382  constant  OP_FP@
383  constant  OP_FP!
384  constant  OP_F.S
385  constant  OP_FDUP
386  constant  OP_FDROP
387  constant  OP_FSWAP
388  constant  OP_FROT
389  constant  OP_FOVER

400  constant  OP_.NOT.
401  constant  OP_.AND.
402  constant  OP_.OR.
403  constant  OP_.XOR.
404  constant  OP_BOOLEAN?
405  constant  OP_UW@
406  constant  OP_UL@
407  constant  OP_SL@
408  constant  OP_L!

420  constant  OP_SFLOATS
421  constant  OP_SFLOAT+
422  constant  OP_FLOATS
423  constant  OP_FLOAT+

Public:

create SingleITCBuf 3 cells allot

\ Fetch opcode+operands for next primitive word from byte code
\ sequence aITC and place in SingleITC Buf for single word
\ execution. Return pointer to beginning of next opcode in the 
\ sequence
: ITC-packet@ ( aITC -- aITC' ) 
    next-ITC-count 
    2dup SingleITCBuf swap move 
    SingleITCBuf over + OP_RET swap c! 
    + ;

: addr. ( a -- ) [char] $ emit .address ;
: ptr.  ( a -- ) [char] * addr. ;
: #num. ( n -- ) [char] # emit base @ swap decimal . base ! ;
: $num. ( n -- ) [char] $ emit base @ swap hex . base ! ;
 
: op. ( aITC' op -- )  
     dup
     CASE
       OP_IVAL OF drop cell- @ #num. ENDOF
       OP_2VAL OF drop cell- cell- 
           dup @ #num. cell+ @ #num. ENDOF
       OP_FVAL OF drop 1 floats 1 cells /
           1 MAX cells - f@ fs. ENDOF
       OP_ADDR OF drop cell- a@ addr. ENDOF
       OP_PTR  OF drop cell- a@ ptr.  ENDOF
       OP_CALLADDR OF
           swap cell- a@ swap
           over NC>String
           ?dup IF type 2drop
           ELSE drop opname@ type space addr.
           THEN ENDOF 
       OP_DEFINITION OF
           swap cell- a@ swap
           over ITC>String
           ?dup IF type 2drop 
           ELSE drop opname@ type space addr. 
           THEN ENDOF
       OP_JZ  OF opname@ type space cell- @ $num. ENDOF
       OP_JMP OF opname@ type space cell- @ $num. ENDOF  
       opname@ type drop
     ENDCASE ;

: operands. ( aITC' op -- )
    operand-count@ tuck cells -
    swap 0 ?DO dup @ space addr. cell+ LOOP
    drop ;

: see ( "name" -- )
    ' xt>itc
    BEGIN
      dup .address 
      ITC-packet@ >r
      r@ SingleITCBuf c@ swap 
      over 3 spaces op. cr
      r> swap OP_RET =
    UNTIL drop ;

: step ( i*x aITC -- j*x aITC' )
    ITC-packet@ dup >r
    SingleITCBuf c@ op. cr
    SingleITCBuf execute-bc r>
;

\ Byte code primitives in kForth 2.x
S" FALSE"   0  OP_FALSE   ti!
S" TRUE"    0  OP_TRUE    ti!
S" CELLS"   0  OP_CELLS   ti!
S" CELL+"   0  OP_CELL+   ti!
S" DFLOATS" 0  OP_DFLOATS ti!
S" DFLOAT+" 0  OP_DFLOAT+ ti!
S" CASE"    0  OP_CASE    ti!
S" ENDCASE" 0  OP_ENDCASE ti!
S" OF"      0  OP_OF      ti!
S" ENDOF"   0  OP_ENDOF   ti!
S" OPEN"    0  OP_OPEN    ti!
S" LSEEK"   0  OP_LSEEK   ti!
S" CLOSE"   0  OP_CLOSE   ti!
S" READ"    0  OP_READ    ti!
S" WRITE"   0  OP_WRITE   ti!
S" IOCTL"   0  OP_IOCTL   ti!
S" USLEEP"  0  OP_USLEEP  ti!
S" MS"      0  OP_MS      ti!
S" MS@"     0  OP_MS@     ti!
S" SYSCALL" 0  OP_SYSCALL ti!
S" FILL"    0  OP_FILL    ti!
S" CMOVE"   0  OP_CMOVE   ti!
S" CMOVE>"  0  OP_CMOVE>  ti!
S" .("      0  OP_.(      ti!
S" <#"      0  OP_<#      ti!
S" EXECUTE-BC" 0  OP_EXECUTE-BC  ti!
S" FSYNC"   0  OP_FSYNC   ti!
S" #>"      0  OP_#>      ti!
S" #S"      0  OP_#S      ti!
S" S."      0  OP_S"      ti!
S" CR"      0  OP_CR      ti!
S" BL"      0  OP_BL      ti!
S" SPACES"  0  OP_SPACES  ti!
S" !"       0  OP_!       ti!
S" C."      0  OP_C"      ti!
S" #"       0  OP_#       ti!
S" SIGN"    0  OP_SIGN    ti!
S" MOD"     0  OP_MOD     ti!
S" AND"     0  OP_AND     ti!
S" '"       0  OP_'       ti!
S" ("       0  OP_(       ti!
S" HOLD"    0  OP_HOLD    ti!
S" *"       0  OP_*       ti!
S" +"       0  OP_+       ti!
S" -"       0  OP_-       ti!
S" ."       0  OP_.       ti!
S" /"       0  OP_/       ti!
S" DABS"    0  OP_DABS    ti!
S" DNEGATE" 0  OP_DNEGATE ti!
S" UM*"     0  OP_UM*     ti!
S" UM/MOD"  0  OP_UM/MOD  ti!
S" M*"      0  OP_M*      ti!
S" M+"      0  OP_M+      ti!
S" M/"      0  OP_M/      ti!
S" M*/"     0  OP_M*/     ti!
S" FM/MOD"  0  OP_FM/MOD  ti!
S" SM/REM"  0  OP_SM/REM  ti!
S" :"       0  OP_:       ti!
S" ;"       0  OP_;       ti!
S" <"       0  OP_<       ti!
S" ="       0  OP_=       ti!
S" >"       0  OP_>       ti!
S" ?"       0  OP_?       ti!  
S" @"       0  OP_@       ti!
S" ADDR"    1  OP_ADDR    ti!
S" BASE"    0  OP_BASE    ti!
S" CALL"    0  OP_CALL    ti!
S" DEFINITION" 1 OP_DEFINITION ti!
S" ERASE"   0  OP_ERASE   ti!

32-bit? [IF]  
S" FVAL"    2  OP_FVAL    ti!
[ELSE]
S" FVAL"    1  OP_FVAL    ti!
[THEN]

S" CALLADDR" 1 OP_CALLADDR ti!
S" >BODY"   0  OP_>BODY   ti!
S" IVAL"    1  OP_IVAL    ti!
S" EVALUATE" 0 OP_EVALUATE ti!
S" KEY"     0  OP_KEY     ti!
S" LSHIFT"  0  OP_LSHIFT  ti!
S" /MOD"    0  OP_/MOD    ti!
S" PTR"     1  OP_PTR     ti!
S" .R"      0  OP_.R      ti!
S" D."      0  OP_D.      ti!
S" KEY?"    0  OP_KEY?    ti!
S" RSHIFT"  0  OP_RSHIFT  ti!
S" .S"      0  OP_.S      ti!
S" ACCEPT"  0  OP_ACCEPT  ti!
S" CHAR"    0  OP_CHAR    ti!
S" [CHAR]"  0  OP_[CHAR]  ti!
S" WORD"    0  OP_WORD    ti!
S" */"      0  OP_*/      ti!
S" */MOD"   0  OP_*/MOD   ti!
S" U.R"     0  OP_U.R     ti!
S" ["       0  OP_[       ti!
S" \"       0  OP_\       ti!
S" ]"       0  OP_]       ti!
S" XOR"     0  OP_XOR     ti!
S" LITERAL" 0  OP_LITERAL ti!
S" ALLOT?"  0  OP_ALLOT?  ti!
S" ALLOT"   0  OP_ALLOT   ti!
S" BINARY"  0  OP_BINARY  ti!
S" COUNT"   0  OP_COUNT   ti!  
S" DECIMAL" 0  OP_DECIMAL ti!
S" EMIT"    0  OP_EMIT    ti!
S" F."      0  OP_F.      ti!
S" COLD"    0  OP_COLD    ti!
S" HEX"     0  OP_HEX     ti!
S" I"       0  OP_I       ti!
S" J"       0  OP_J       ti!
S" [']"     0  OP_[']     ti!
S" FVARIABLE" 0 OP_FVARIABLE ti!
S" 2!"      0  OP_2!      ti!
S" FIND"    0  OP_FIND    ti!
S" CONSTANT"  0 OP_FIND ti!
S" IMMEDIATE" 0 OP_IMMEDIATE ti!
S" FCONSTANT" 0 OP_FCONSTANT ti!
S" CREATE"    0 OP_CREATE ti!
S" .."      0  OP_."     ti!
S" TYPE"    0  OP_TYPE   ti!
S" U."      0  OP_U.     ti!
S" VARIABLE" 0 OP_VARIABLE ti!
S" WORDS"   0  OP_WORDS  ti!
S" DOES>"   0  OP_DOES>  ti!
S" 2VAL"    2  OP_2VAL   ti!
S" 2@"      0  OP_2@     ti!
S" SEARCH"  0 OP_SEARCH ti!
S" OR"      0  OP_OR     ti!
S" COMPARE" 0 OP_COMPARE ti!
S" NOT"     0  OP_NOT    ti!
S" MOVE"    0  OP_MOVE   ti!
S" FSIN"    0  OP_FSIN   ti!
S" FCOS"    0  OP_FCOS   ti!
S" FTAN"    0  OP_FTAN   ti!
S" FASIN"   0  OP_FASIN  ti!
S" FACOS"   0  OP_FACOS  ti!
S" FATAN"   0  OP_FATAN  ti!
S" FEXP"    0  OP_FEXP   ti!
S" FLN"     0  OP_FLN    ti!
S" FLOG"    0  OP_FLOG   ti!
S" FATAN2"  0  OP_FATAN2 ti!
S" FTRUNC"  0  OP_FTRUNC ti!
S" FTRUNC>S" 0 OP_FTRUNC>S ti!
S" FMIN"    0  OP_FMIN   ti!
S" FMAX"    0  OP_FMAX   ti!
S" FLOOR"   0  OP_FLOOR  ti!
S" FROUND"  0  OP_FROUND ti!
S" D<"      0  OP_D<     ti!
S" D0="     0  OP_D0=    ti!
S" D="      0  OP_D=     ti!
S" 2>R"     0  OP_2>R    ti!
S" 2R>"     0  OP_2R>    ti!
S" 2R@"     0  OP_2R@    ti!
S" S>D"     0  OP_S>D    ti!
S" S>F"     0  OP_S>F    ti!
S" D>F"     0  OP_D>F    ti!
S" FROUND>S" 0 OP_FROUND>S  ti!
S" F>D"     0  OP_F>D    ti!
S" DEG>RAD" 0  OP_DEG>RAD  ti!
S" RAD>DEG" 0  OP_RAD>DEG  ti!
S" D+"      0  OP_D+     ti!
S" D-"      0  OP_D-     ti!
S" DU<"     0  OP_DU<    ti!
S" 1+"      0  OP_1+     ti!
S" 1-"      0  OP_1-     ti!
S" ABS"     0  OP_ABS    ti!
S" NEGATE"  0  OP_NEGATE ti!
S" MIN"     0  OP_MIN    ti!
S" MAX"     0  OP_MAX    ti!
S" 2*"      0  OP_2*     ti!
S" 2/"      0  OP_2/     ti!  
S" 2+"      0  OP_2+     ti!
S" 2-"      0  OP_2-     ti!
S" C@"      0  OP_C@     ti!
S" C!"      0  OP_C!     ti!
S" SW@"     0  OP_SW@    ti!
S" W!"      0  OP_W!     ti!
S" DF@"     0  OP_DF@    ti!
S" DF!"     0  OP_DF!    ti!
S" SF@"     0  OP_SF@    ti!
S" SF!"     0  OP_SF!    ti!
S" SP@"     0  OP_SP@    ti!
S" +!"      0  OP_+!     ti!
S" F+"      0  OP_F+     ti!
S" F-"      0  OP_F-     ti!
S" F*"      0  OP_F*     ti!
S" F/"      0  OP_F/     ti!
S" FABS"    0  OP_FABS   ti!
S" FNEGATE" 0  OP_FNEGATE ti!
S" F**"     0  OP_F**    ti!
S" FSQRT"   0  OP_FSQRT  ti!
S" SP!"     0  OP_SP!    ti!
S" RP!"     0  OP_RP!    ti!
S" F="      0  OP_F=     ti!
S" F<>"     0  OP_F<>    ti!
S" F<"      0  OP_F<     ti!
S" F>"      0  OP_F>     ti!
S" F<="     0  OP_F<=    ti!
S" F>="     0  OP_F>=    ti!
S" F0="     0  OP_F0=    ti!
S" F0<"     0  OP_F0<    ti!
S" F0>"     0  OP_F0>    ti!

S" DROP"    0  OP_DROP   ti!
S" DUP"     0  OP_DUP    ti!
S" SWAP"    0  OP_SWAP   ti!
S" OVER"    0  OP_OVER   ti!
S" ROT"     0  OP_ROT    ti!
S" -ROT"    0  OP_-ROT   ti!
S" NIP"     0  OP_NIP    ti!
S" TUCK"    0  OP_TUCK   ti!
S" PICK"    0  OP_PICK   ti!
S" ROLL"    0  OP_ROLL   ti!
S" 2DROP"   0  OP_2DROP  ti!
S" 2DUP"    0  OP_2DUP   ti!
S" 2SWAP"   0  OP_2SWAP  ti!
S" 2OVER"   0  OP_2OVER  ti!
S" 2ROT"    0  OP_2ROT   ti!
S" DEPTH"   0  OP_DEPTH  ti!
S" ?DUP"    0  OP_?DUP   ti!
S" IF"      0  OP_IF     ti!
S" ELSE"    0  OP_ELSE   ti!
S" THEN"    0  OP_THEN   ti!
S" >R"      0  OP_>R     ti!
S" R>"      0  OP_R>     ti!
S" IP>R"    0  OP_IP>R   ti!
S" R@"      0  OP_R@     ti!
S" RP@"     0  OP_RP@    ti!
S" A@"      0  OP_A@     ti!
S" DO"      0  OP_DO     ti!
S" LEAVE"   0  OP_LEAVE  ti!
S" ?DO"     0  OP_?DO    ti!
S" ABORT."  0  OP_ABORT" ti!
S" JZ"      1  OP_JZ     ti!
S" JNZ"     1  OP_JNZ    ti!
S" JMP"     1  OP_JMP    ti!
S" LOOP"    0  OP_RTLOOP ti!
S" +LOOP"   0  OP_RT+LOOP ti!
S" UNLOOP"  0  OP_RTUNLOOP ti!
S" EXECUTE" 0  OP_EXECUTE  ti!
S" RECURSE" 0  OP_RECURSE  ti!
S" RET"     0  OP_RET      ti!
S" ABORT"   0  OP_ABORT    ti!
S" QUIT"    0  OP_QUIT     ti!
S" >="      0  OP_>=       ti!
S" <="      0  OP_<=       ti!
S" <>"      0  OP_<>       ti!
S" 0="      0  OP_0=       ti!
S" 0<>"     0  OP_0<>      ti!
S" 0<"      0  OP_0<       ti!
S" 0>"      0  OP_0>       ti!
S" U<"      0  OP_U<       ti!
S" U>"      0  OP_U>       ti!
S" BEGIN"   0  OP_BEGIN    ti!
S" WHILE"   0  OP_WHILE    ti!
S" REPEAT"  0  OP_REPEAT   ti!
S" UNTIL"   0  OP_UNTIL    ti!
S" AGAIN"   0  OP_AGAIN    ti!
S" BYE"     0  OP_BYE      ti!

\ Extended byte-code primitives in kForth 2.x

S" UTM/"    0  nc' UTM/      OP_UTM/     ti!
S" UTS/MOD" 0  nc' UTS/MOD   OP_UTS/MOD  ti!
S" STS/REM" 0  nc' STS/REM   OP_STS/REM  ti!
S" UDM*"    0  nc' UDM*      OP_UDM*     ti!
S" INCLUDED" 0 nc' INCLUDED  OP_INCLUDED ti!
S" INCLUDE" 0  nc' INCLUDE   OP_INCLUDE  ti!
S" SOURCE"  0  nc' SOURCE    OP_SOURCE   ti!
S" REFILL"  0  nc' REFILL    OP_REFILL   ti!
S" STATE"   0  nc' STATE     OP_STATE    ti!
S" ALLOCATE" 0 nc' ALLOCATE  OP_ALLOCATE ti!
S" FREE"    0  nc' FREE      OP_FREE     ti!
S" RESIZE"  0  nc' RESIZE    OP_RESIZE   ti!
S" DS*"     0  nc' DS*       OP_DS*      ti!
S" COMPILE," 0 nc' COMPILE,  OP_COMPILE, ti!
S" COMPILE-NAME" 0 nc' COMPILE-NAME OP_COMPILE-NAME ti!
S" POSTPONE" 0 nc' POSTPONE  OP_POSTPONE ti!
S" NONDEFERRED" 0 nc' NONDEFERRED OP_NONDEFERRED ti!
S" FORGET"   0 nc' FORGET    OP_FORGET   ti!
S" FORTH-SIGNAL" 0 nc' FORTH-SIGNAL OP_FORTH-SIGNAL ti!
S" RAISE"    0 nc' RAISE     OP_RAISE    ti!
S" SET-ITIMER" 0 nc' SET-ITIMER OP_SET-ITIMER ti!
S" GET-ITIMER" 0 nc' GET-ITIMER OP_GET-ITIMER ti!
S" US2@"     0 nc' US2@      OP_US2@     ti!
S" >FLOAT"   0 nc' >FLOAT    OP_>FLOAT   ti!
S" FSINCOS"  0 nc' FSINCOS   OP_FSINCOS  ti!
S" FACOSH"   0 nc' FACOSH    OP_FACOSH   ti!
S" FASINH"   0 nc' FASINH    OP_FASINH   ti!
S" FATANH"   0 nc' FATANH    OP_FATANH   ti!
S" FCOSH"    0 nc' FCOSH     OP_FCOSH    ti!
S" FSINH"    0 nc' FSINH     OP_FSINH    ti!
S" FTANH"    0 nc' FTANH     OP_FTANH    ti!
S" FALOG"    0 nc' FALOG     OP_FALOG    ti!
S" D0<"      0 nc' D0<       OP_D0<      ti!
S" DMAX"     0 nc' DMAX      OP_DMAX     ti!
S" DMIN"     0 nc' DMIN      OP_DMIN     ti!
S" D2*"      0 nc' D2*       OP_D2*      ti!
S" D2/"      0 nc' D2/       OP_D2/      ti!
S" UD."      0 nc' UD.       OP_UD.      ti!
S" WITHIN"   0 nc' WITHIN    OP_WITHIN   ti!
S" 2LITERAL" 0 nc' 2LITERAL  OP_2LITERAL ti!
S" >NUMBER"  0 nc' >NUMBER   OP_>NUMBER  ti!
S" NUMBER?"  0 nc' NUMBER?   OP_NUMBER?  ti!
S" SLITERAL" 0 nc' SLITERAL  OP_SLITERAL ti!
S" FLITERAL" 0 nc' FLITERAL  OP_FLITERAL ti!
S" 2VARIABLE" 0 nc' 2VARIABLE OP_2VARIABLE ti!
S" 2CONSTANT" 0 nc' 2CONSTANT OP_2CONSTANT ti!
S" >FILE"    0 nc' >FILE     OP_>FILE     ti!
S" CONSOLE"  0 nc' CONSOLE   OP_CONSOLE   ti!
S" :NONAME"  0 nc' :NONAME   OP_:NONAME   ti!
S" SPACE"    0 nc' SPACE     OP_SPACE     ti!
S" BLANK"    0 nc' BLANK     OP_BLANK     ti!
S" /STRING"  0 nc' /STRING   OP_/STRING   ti!
S" -TRAILING" 0 nc' -TRAILING  OP_-TRAILING  ti!
S" PARSE"    0 nc' PARSE     OP_PARSE     ti!
S" PARSE-NAME" 0 nc' PARSE-NAME OP_PARSE-NAME ti!
S" DLOPEN"   0 nc' DLOPEN    OP_DLOPEN    ti!
S" DLERROR"  0 nc' DLERROR   OP_DLERROR   ti!
S" DLSYM"    0 nc' DLSYM     OP_DLSYM     ti!
S" DLCLOSE"  0 nc' DLCLOSE   OP_DLCLOSE   ti!
S" US"       0 nc' US        OP_US        ti!
S" ALIAS"    0 nc' ALIAS     OP_ALIAS     ti!
S" SYSTEM"   0 nc' SYSTEM    OP_SYSTEM    ti!
S" CHDIR"    0 nc' CHDIR     OP_CHDIR     ti!
S" TIME&DATE" 0 nc' TIME&DATE OP_TIME&DATE ti!
S" WORDLIST" 0 nc' WORDLIST  OP_WORDLIST  ti!
S" FORTH-WORDLIST" 0 nc' FORTH-WORDLIST OP_FORTH-WORDLIST ti!
S" GET-CURRENT" 0 nc' GET-CURRENT OP_GET-CURRENT ti!
S" SET-CURRENT" 0 nc' SET-CURRENT OP_SET-CURRENT ti!
S" GET-ORDER"   0 nc' GET-ORDER   OP_GET-ORDER   ti!
S" SET-ORDER"   0 nc' SET-ORDER   OP_SET-ORDER   ti!
S" ONLY"        0 nc' ONLY        OP_ONLY        ti!
S" ALSO"        0 nc' ALSO        OP_ALSO        ti!
S" ORDER"       0 nc' ORDER       OP_ORDER       ti!
S" PREVIOUS"    0 nc' PREVIOUS    OP_PREVIOUS    ti!
S" FORTH"       0 nc' FORTH       OP_FORTH       ti!
S" ASSEMBLER"   0 nc' ASSEMBLER   OP_ASSEMBLER   ti!
S" TRAVERSE-WORDLIST" 0 nc' TRAVERSE-WORDLIST OP_TRAVERSE-WORDLIST ti!
S" NAME>STRING" 0 nc' NAME>STRING OP_NAME>STRING ti!
S" NAME>INTERPRET" 0 nc' NAME>INTERPRET OP_NAME>INTERPRET ti!
S" NAME>COMPILE"   0 nc' NAME>COMPILE   OP_NAME>COMPILE   ti!
S" PRECISION"      0 nc' PRECISION      OP_PRECISION  ti!
S" SET-PRECISION"  0 nc' SET-PRECISION  OP_SET-PRECISION  ti!
S" FS."            0 nc' FS.            OP_FS.            ti!
S" FEXPM1"         0 nc' FEXPM1         OP_FEXPM1         ti!
S" FLNP1"          0 nc' FLNP1          OP_FLNP1          ti!
S" UD.R"           0 nc' UD.R           OP_UD.R           ti!
S" D.R"            0 nc' D.R            OP_D.R            ti!
S" F2DROP"         0 nc' F2DROP         OP_F2DROP         ti!
S" F2DUP"          0 nc' F2DUP          OP_F2DUP          ti!

fp-stack? [IF]
S" FDEPTH"         0 nc' FDEPTH         OP_FDEPTH         ti!
S" FP@"            0 nc' FP@            OP_FP@            ti!
S" FP!"            0 nc' FP!            OP_FP!            ti!
S" F.S"            0 nc' F.S            OP_F.S            ti!
[THEN]

S" FDUP"           0 nc' FDUP           OP_FDUP           ti!
S" FSWAP"          0 nc' FSWAP          OP_FSWAP          ti!
S" FROT"           0 nc' FROT           OP_FROT           ti!
S" FOVER"          0 nc' FOVER          OP_FOVER          ti!
S" .NOT."          0 nc' .NOT.          OP_.NOT.          ti!
S" .AND."          0 nc' .AND.          OP_.AND.          ti!
S" .OR."           0 nc' .OR.           OP_.OR.           ti!
S" .XOR."          0 nc' .XOR.          OP_.XOR.          ti!
S" BOOLEAN?"       0 nc' BOOLEAN?       OP_BOOLEAN?       ti!
S" UW@"            0 nc' UW@            OP_UW@            ti!
S" UL@"            0 nc' UL@            OP_UL@            ti!
S" SL@"            0 nc' SL@            OP_SL@            ti!
S" L!"             0 nc' L!             OP_L!             ti!
S" SFLOATS"        0 nc' SFLOATS        OP_SFLOATS        ti!
S" SFLOAT+"        0 nc' SFLOAT+        OP_SFLOAT+        ti!
S" FLOATS"         0 nc' FLOATS         OP_FLOATS         ti!
S" FLOAT+"         0 nc' FLOAT+         OP_FLOAT+         ti!
END-MODULE

Also ssd

