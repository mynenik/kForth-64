\ libgmp.4th
\
\ Load bindings for the GNU Mulitprecision Library
\
1 CELLS 8 = [IF]
  s" libs/gmp/libgmp_x86_64.4th" included
[ELSE]
  s" libs/gmp/libgmp_x86.4th" included
[THEN]

