\ libmpfr.4th
\
\ Load bindings for the GNU Multi-Precision Floating point library
\   with correct Rounding
\
1 CELLS 8 = [IF]
  s" libs/gmp/libmpfr_x86_64.4th" included
[ELSE]
  s" libs/gmp/libmpfr_x86.4th" included
[THEN]

