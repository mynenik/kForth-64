\ interp-array.4th
\
\ Lineary interpolation for FSL arrays:
\
\ Assume x1{ and y1{ are arrays of type FLOAT, and contain (x,y) pairs.
\ Further assume ascending order for x1{ values.
\
\ Given a new set of abcissas x2{, which fall within the domain of x1{,
\   compute a new set of corresponding y2{ values by linear interpolation.
\
\ Requires:
\
\   ans-words.4th
\   fsl-util.4th
\

[undefined]  ptr  [IF] : ptr create 1 cells ?allot ! does> a@ ; [THEN]

0  ptr  x1{
0  ptr  y1{
0  ptr  x2{
0  ptr  y2{

0  VALUE  np1   \ number of points in arrays x1{ and y1{
0  VALUE  np2   \ number of points in arrays x2{ and y2{
0  VALUE  idx

FVARIABLE  xa
FVARIABLE  xb
FVARIABLE  ya
FVARIABLE  yb

: interp-array ( 'x1 'y1 np1 'x2 'y2 np2 -- | generate y2 array by linear interpolation )
    TO np2  TO y2{  TO x2{
    TO np1  TO y1{  TO x1{

    0 TO idx

    np2 0 ?DO

      x2{ I } F@

      np1 idx ?DO
        FDUP x1{ I } F@ F<  IF LEAVE THEN
	idx 1+ TO idx
      LOOP  

      FDROP
      
      idx np1 1- MIN TO idx

      idx 1- 0 MAX  x1{ SWAP } F@  xa  F!
      idx           x1{ SWAP } F@  xb  F!
      idx 1- 0 MAX  y1{ SWAP } F@  ya  F!
      idx           y1{ SWAP } F@  yb  F!
      
      xb F@ xa F@ F= IF     \ avoid divide by zero error 
        ya F@
      ELSE
        yb F@ ya F@ F-  x2{ I } F@ xa F@ F-  F*
	xb F@ xa F@ F-  F/  ya F@ F+
      THEN
      y2{ I } F!
    LOOP
;


