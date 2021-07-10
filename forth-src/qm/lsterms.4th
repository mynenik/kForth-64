\ lsterms.4th
\
\ Given an atomic electron configuration, determine the allowed LS terms and levels.
\
\ Copyright (c) 2006 Krishna Myneni
\ Provided under the GNU General Public License
\
\ The notation for an LS term is  (2S+1)L
\ The notation for a level is     (2S+1)LJ
\
\ Electron configurations are specified in the form of a list, using
\ the standard notation for orbital angular momentum: s (l=0), p (l=1),
\ d (l=2), etc. Non-equivalent electrons having the same angular momentum
\ are specified as different list elements, e.g.
\
\     '( p p )
\
\ indicates the two p-electrons are in different shells, and are therefore
\ non-equivalent.
\
\ ** This program does not handle equivalent electrons yet **
\
\ Examples:
\
\  1. Compute and print the allowed LS terms for a configuration
\     consisting of an "s" and a "p" electron, for example the
\     configuration of an excited helium (He) atom:
\
\        '( s p ) terms print
\
\     Output: ( 1P 3P )
\
\  2. Compute and print allowed levels for previous configuration.
\
\        '( s p ) levels print
\
\     Output: ( ( 1P1 ) ( 3P0 3P1 3P2 ) )
\
\     Each sublist of levels arises from the corresponding term from
\     the list of terms.
\
\  3. For a configuration of a p electron and a d electron, find the
\     levels. See ref. [1], Fig 4-4 and Fig 4-5 (energy levels of doubly
\     ionized titanium, Ti III, with 3d4p electron configuration).
\
\        '( d p ) levels print
\
\     Output: 
\       ( ( 1P1 ) ( 3P0 3P1 3P2 ) ( 1D2 ) ( 3D1 3D2 3D3 ) ( 1F3 ) 
\         ( 3F2 3F3 3F4 ) )
\
\ References:
\
\  1. R. D. Cowan, The Theory of Atomic Structure and Spectra, Univ.
\     of California Press, (Berkeley, 1981).
\
\  2. Eisberg and Resnick, Quantum Physics of Atoms, Molecules, Solids,
\     Nuclei and Particles.
\
\ Revisions:
\   2010-07-19  km  fixed problem with Lmin, causing it to be sensitive
\                   to ordering of configuration.
\   2010-07-25  km  simplified the words LSJ-LEVELS, TERMS and LEVELS;
\                   pictured level lists now have a 1-1 correspondence
\                   with terms list.
include ans-words
include strings
include lists

'( s p d f g h i k l m n o q r t u v w x y ) ptr l-notation
'( S P D F G H I K L M N O Q R T U V W X Y ) ptr L-labels

: s>$ ( n -- c-addr u )
    dup >r abs 0 <# #s r> 0< IF [char] - hold THEN #> ;
 
: s>atom ( n -- ^atom | return a list atom for a number)
    s>$ $>hndl ;

: atom>l ( ^atom -- l | convert label to angular momentum quantum number)
    l-notation position ;

: term ( 'LSterm | 'LSJlevel -- ^val | return a pictured output list atom for LS term)
    dup
    second first s>$
    rot first  first L-labels nth >$ strcat
    $>atom$ ;

\ Return a pictured output list atom for a list containing a single LSJ level
: level ( 'LSJlevel -- ^val )
    dup term >$
    rot last   first first 1- dup 2 mod dup >r 0= IF 2/ THEN
    s>$ strcat r> IF s" /2" strcat THEN
    $>atom$ ;

\ Return a list of pictured levels for an input list containing 
\ a list of LSJ levels
: level-list ( 'LSJlist -- 'levels )
    ['] level mapcar ;
 
: >qnumbers ( 'l -- q1 q2 ... | extract a list of quantum numbers to numbers on the stack)
    BEGIN  dup nil? 0=  WHILE  dup first first swap rest  REPEAT drop ;

: >qnlist ( q1 q2 ... qn  n -- 'l | make a list of n numbers)
    nil swap 0 ?DO swap s>atom swap cons LOOP ;

: min_qns>term ( M_L  M_S -- ^val | return an atom indicating the term )
    abs 1+ swap abs swap 2 >qnlist term ;
 
nil ptr temp_list
: min_qns>list ( min_M_L  min_M_S -- 'l )
    nil to temp_list swap  \  -- min_M_S  min_M_L 
    dup abs 2* 1+ 0 DO
	over abs 1+ 0 DO
	    2dup J + swap I 2* + 2 >qnlist temp_list cons to temp_list
	LOOP
    LOOP
    2drop temp_list reverse ;


\ Convert orbital angular momentum label of an electron to a list of its allowed
\   angular momentum quantum numbers, including spin: { ( m_l  m_s ) }. The
\   spin quantum number, m_s, is scaled by 2; i.e. m_s = +/- 1. 
: atom>mlms ( ^atom -- 'mlms )
    atom>l negate -1 min_qns>list ;

\ Given a list of allowed quantum numbers for n electrons
\
\   ( m_l1  m_s1  m_l2  m_s2 ... m_ln  m_sn )
\
\ return a list of the total m_l and total m_s quantum numbers:
\
\   ( M_L  M_S )
\
: >qtot ( 'qlist -- 'qtot )
    0 0 rot
    BEGIN dup nil? 0= WHILE
	    dup first first >r rest
	    dup first first >r rest
	    -rot
	    r> + swap r> + swap
	    rot
    REPEAT
    drop 2 >qnlist ;

\ Given a list of sets of quantum numbers for n electrons:
\
\   { ( m_l1  m_s1  m_l2  m_s2 ... m_ln  m_sn ) }
\
\   return a list of total quantum numbers { ( M_L  M_S ) }
: qtotal ( 'l -- 'MLMS )
    nil swap
    BEGIN  dup nil? 0=  WHILE
	    dup >r first >qtot swap cons
	    r> rest
    REPEAT
    drop ;

\ Return minimum of value M_L1 and M_L2 from single list ( M_L2 M_S2 )
: min_ML1 ( m_l  'mlms -- m_l') first first min ;
: min_ML ( 'MLMS -- M_L )
    0 swap ['] min_ML1 reduce ;

: min_MS ( 'MLMS  M_L -- M_L  M_S | for a given M_L, return the smallest M_S )
    0 rot
    BEGIN  dup nil? 0=  WHILE
	    dup >r first
	    dup >r first first >r over r>
	    = IF  r> second first min  ELSE r> drop THEN
	    r> rest
    REPEAT
    drop ;

\ Return the pair of values which exist in a list { ( M_L  M_S ) } with
\   the smallest M_L, and for this M_L, the smallest M_S.
: min_MLMS ( 'MLMS -- M_L  M_S ) dup min_ML min_MS ;

\ Remove one occurence of list1, which is a pair ( M_L  M_S ), in list2.
\ The winnowed list is list3.
: remove_MLMS ( 'list1 'list2 -- 'list3 )
    nil -rot
    BEGIN  dup nil? 0=  WHILE  \ -- 'list3  'list1  'list2
	    2dup first dup >r list-equal
	    IF  >r drop reverse r> rest  append r> drop EXIT
	    ELSE rot r> swap cons -rot rest THEN
    REPEAT
    2drop ;

\ Given a list of allowed total quantum numbers { ( M_L  M_S ) },
\   return a list of allowed terms.

: qs>terms ( 'MLMS -- 'terms )
    nil swap
    BEGIN  dup nil? 0=  WHILE  \ -- 'terms 'MLMS
	    dup >r
	    min_MLMS
	    2dup 2>r min_qns>term swap cons 2r>
	    min_qns>list r>	    
	    BEGIN  over nil? 0=  WHILE  \ -- 'terms 'list 'MLMS
		    over first swap  remove_MLMS
		    swap rest swap
	    REPEAT
	    nip	    
    REPEAT
    drop ;

: add-L ( n1 ^val -- n2 )  atom>l + ;
: sub-L ( n1 ^val -- n2 )  atom>l - abs ;

: Lmax ( 'conf -- Lmax | return max value of L for given electron config)
    0 swap ['] add-L reduce ;

: Lmin ( 'conf -- Lmin | return min value of L for given electron config)
    0 swap ['] sub-L reduce abs ;

: Smax ( 'conf -- Smax | return max multiplicity for given electron config)
    length 1+ ;

: Smin ( 'conf -- Smin | return min multiplicity for given electron config)
    length 2 mod 1+ ;

: L-list ( 'conf -- 'L | return list of coupled angular momenta for config)
    dup Lmax 1+ swap Lmin 2dup < IF swap THEN
    nil -rot DO I s>atom swap cons LOOP ;

: S-list ( 'conf -- 'S | return list of multiplicities for config)
    dup Smax 1+ swap Smin
    nil -rot DO I s>atom swap cons 2 +LOOP ;

nil ptr lstemp

\ Return a list of allowed terms { ( L 2S+1 ) } for a given list of
\ allowed L values and a list of allowed multiplicities 2S+1.

: lsterm1 ( 'Lterm ^Sval -- 'Lterm ) over cons lstemp cons to lstemp ;
: lsterm2 ( S' ^Lval -- S' ) nil cons over ['] lsterm1 reduce drop ;

: LS-terms ( 'L 'S -- 'LSterms )
    nil to lstemp
    swap ['] lsterm2 reduce drop
    lstemp ['] reverse mapcar
;

\ Return a list of allowed levels { ( L 2S+1 2J+1 ) } for a given LS term 
: LSJ ( 'LSterm -- 'LSJlevels )
    dup first first 2*
    over second first
    2dup - 1+ abs 1+ >r + 1+ r>
    nil -rot DO over I s>atom nil cons append nil cons append 2 +LOOP nip ; 
    

\ Return a list of all allowed levels, given a list of LS terms
: LSJ-levels ( 'LSterms -- 'LSJlevels )
    ['] LSJ mapcar ;

: config>lsterms ( 'config -- 'LSterms )
    dup L-list swap S-list LS-terms ;

\ return a list of the pictured ^{2S+1}L terms for given config  
: terms ( 'config -- 'lsterms )
    config>lsterms ['] term mapcar ;

\ Return list of the pictured ^{2S+1}L_J levels for given electron config     
: levels ( 'config -- 'levels )
    config>lsterms LSJ-levels ['] level-list mapcar ;
   

