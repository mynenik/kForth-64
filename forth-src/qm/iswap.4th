\ iswap.4th
\
\ iSWAP 2-qubit gate in an n-qubit circuit
\
\ K. Myneni, 2019-11-13
\
\ Requires: qcsim.4th
\

variable sw_i
variable sw_j

: U_isw ( i j n -- q )
   >r sw_j ! sw_i !
   one one one one    \ -- g1 g2 g3 g4
   r> 0 ?DO
     I sw_i @ = I sw_j @ = or IF
       2>r P1 swap %x% swap P0 swap %x% swap 2r>
       I sw_i @ = IF
         P01 swap %x% swap P10 swap %x% swap
       ELSE
         P10 swap %x% swap P01 swap %x% swap
       THEN
     ELSE
       >r >r >r
       I1 swap %x%
       I1 r>   %x%
       I1 r>   %x%
       I1 r>   %x%
     THEN
   LOOP
   >r >r z=i r> z*q z=i r> z*q 
   q+ q+ q+ ;

