\ ieee-comparisons-test.4th
\
\ Comparison of IEEE 754 special values
\ Floating point exceptions should be masked.
\
include ans-words.4th
include ttester.4th
include ieee-754.4th

TESTING F=
\ F= sanity tests
t{ -1e  -1e  F= -> true  }t
t{ -1e   1e  F= -> false }t
t{  1e  -1e  F= -> false }t
t{  1e   1e  F= -> true  }t

\ F= NAN tests
t{ +NAN +NAN F= -> false }t 
t{ +NAN -NAN F= -> false }t
t{ +NAN +INF F= -> false }t
t{ -NAN +INF F= -> false }t
t{ +NAN -INF F= -> false }t
t{ -NAN -INF F= -> false }t
t{ +NAN  0e  F= -> false }t
t{ -NAN  0e  F= -> false }t
t{ +NAN -0e  F= -> false }t
t{ -NAN -0e  F= -> false }t

\ F= +/-0 and +/-INF tests
t{ -0e  -0e  F= -> true  }t
t{ -0e   0e  F= -> true  }t
t{  0e  -0e  F= -> true  }t
t{  0e   0e  F= -> true  }t
t{ -INF -0e  F= -> false }t
t{ -INF  0e  F= -> false }t
t{ +INF -0e  F= -> false }t
t{ +INF  0e  F= -> false }t
t{ +INF -INF F= -> false }t
t{ +INF +INF F= -> true  }t
t{ -INF -INF F= -> true  }t
t{ -INF +INF F= -> false }t


TESTING F<>
\ F<> sanity tests
t{ -1e  -1e  F<> -> false }t
t{ -1e   1e  F<> -> true  }t
t{  1e  -1e  F<> -> true  }t
t{  1e   1e  F<> -> false }t

\ F<> NAN tests
t{ +NAN +NAN F<> -> true }t
t{ +NAN -NAN F<> -> true }t
t{ +NAN +INF F<> -> true }t
t{ -NAN +INF F<> -> true }t
t{ +NAN -INF F<> -> true }t
t{ -NAN -INF F<> -> true }t
t{ +NAN  0e  F<> -> true }t
t{ -NAN  0e  F<> -> true }t
t{ +NAN -0e  F<> -> true }t
t{ -NAN -0e  F<> -> true }t

\ F<> +/-0 and +/-INF tests
t{ -0e  -0e  F<> -> false }t
t{ -0e   0e  F<> -> false }t
t{  0e  -0e  F<> -> false }t
t{  0e   0e  F<> -> false }t
t{ -INF -0e  F<> -> true  }t
t{ -INF  0e  F<> -> true  }t
t{ +INF -0e  F<> -> true  }t
t{ +INF  0e  F<> -> true  }t
t{ +INF -INF F<> -> true  }t
t{ +INF +INF F<> -> false }t
t{ -INF -INF F<> -> false }t
t{ -INF +INF F<> -> true  }t


TESTING F<
\ F< sanity tests
t{ -1e  -1e  F< -> false }t
t{ -1e   1e  F< -> true  }t
t{  1e  -1e  F< -> false }t
t{  1e   1e  F< -> false }t

\ F< NAN tests
t{ +NAN +NAN F< -> false }t
t{ +NAN -NAN F< -> false }t
t{ +NAN +INF F< -> false }t
t{ -NAN +INF F< -> false }t
t{ +NAN -INF F< -> false }t
t{ -NAN -INF F< -> false }t
t{ +NAN  0e  F< -> false }t
t{ -NAN  0e  F< -> false }t
t{ +NAN -0e  F< -> false }t
t{ -NAN -0e  F< -> false }t

\ F< +/-0 and +/-INF tests
t{ -0e  -0e  F< -> false }t
t{ -0e   0e  F< -> false }t
t{  0e  -0e  F< -> false }t
t{  0e   0e  F< -> false }t
t{ -INF -0e  F< -> true  }t
t{ -INF  0e  F< -> true  }t
t{ +INF -0e  F< -> false }t
t{ +INF  0e  F< -> false }t
t{ +INF -INF F< -> false }t
t{ +INF +INF F< -> false }t
t{ -INF -INF F< -> false }t
t{ -INF +INF F< -> true  }t


TESTING F>
\ F> sanity tests
t{ -1e  -1e  F> -> false }t
t{ -1e   1e  F> -> false }t
t{  1e  -1e  F> -> true  }t
t{  1e   1e  F> -> false }t

\ F> NAN tests
t{ +NAN +NAN F> -> false }t
t{ +NAN -NAN F> -> false }t
t{ +NAN +INF F> -> false }t
t{ -NAN +INF F> -> false }t
t{ +NAN -INF F> -> false }t
t{ -NAN -INF F> -> false }t
t{ +NAN  0e  F> -> false }t
t{ -NAN  0e  F> -> false }t
t{ +NAN -0e  F> -> false }t
t{ -NAN -0e  F> -> false }t

\ F> +/-0 and +/-INF tests
t{ -0e  -0e  F> -> false }t
t{ -0e   0e  F> -> false }t
t{  0e  -0e  F> -> false }t
t{  0e   0e  F> -> false }t
t{ -INF -0e  F> -> false }t
t{ -INF  0e  F> -> false }t
t{ +INF -0e  F> -> true  }t
t{ +INF  0e  F> -> true  }t
t{ +INF -INF F> -> true  }t
t{ +INF +INF F> -> false }t
t{ -INF -INF F> -> false }t
t{ -INF +INF F> -> false }t


TESTING F<=
\ F<= sanity tests
t{ -1e  -1e  F<= -> true }t
t{ -1e   1e  F<= -> true }t
t{  1e  -1e  F<= -> false }t
t{  1e   1e  F<= -> true }t

\ F<= NAN tests
t{ +NAN +NAN F<= -> false }t
t{ +NAN -NAN F<= -> false }t
t{ +NAN +INF F<= -> false }t
t{ -NAN +INF F<= -> false }t
t{ +NAN -INF F<= -> false }t
t{ -NAN -INF F<= -> false }t
t{ +NAN  0e  F<= -> false }t
t{ -NAN  0e  F<= -> false }t
t{ +NAN -0e  F<= -> false }t
t{ -NAN -0e  F<= -> false }t

\ F<= +/-0 and +/-INF tests
t{ -0e  -0e  F<= -> true }t
t{ -0e   0e  F<= -> true }t
t{  0e  -0e  F<= -> true }t
t{  0e   0e  F<= -> true }t
t{ -INF -0e  F<= -> true }t
t{ -INF  0e  F<= -> true }t
t{ +INF -0e  F<= -> false }t
t{ +INF  0e  F<= -> false }t
t{ +INF -INF F<= -> false }t
t{ +INF +INF F<= -> true }t
t{ -INF -INF F<= -> true }t
t{ -INF +INF F<= -> true }t


TESTING F>=
\ F>= sanity tests
t{ -1e  -1e  F>= -> true }t
t{ -1e   1e  F>= -> false }t
t{  1e  -1e  F>= -> true }t
t{  1e   1e  F>= -> true }t

\ F>= NAN tests
t{ +NAN +NAN F>= -> false }t
t{ +NAN -NAN F>= -> false }t
t{ +NAN +INF F>= -> false }t
t{ -NAN +INF F>= -> false }t
t{ +NAN -INF F>= -> false }t
t{ -NAN -INF F>= -> false }t
t{ +NAN  0e  F>= -> false }t
t{ -NAN  0e  F>= -> false }t
t{ +NAN -0e  F>= -> false }t
t{ -NAN -0e  F>= -> false }t

\ F>= +/-0 and +/-INF tests
t{ -0e  -0e  F>= -> true }t
t{ -0e   0e  F>= -> true }t
t{  0e  -0e  F>= -> true }t
t{  0e   0e  F>= -> true }t
t{ -INF -0e  F>= -> false }t
t{ -INF  0e  F>= -> false }t
t{ +INF -0e  F>= -> true }t
t{ +INF  0e  F>= -> true }t
t{ +INF -INF F>= -> true }t
t{ +INF +INF F>= -> true }t
t{ -INF -INF F>= -> true }t
t{ -INF +INF F>= -> false }t


TESTING F0=
\ F0= NAN tests
t{ +NAN F0= -> false }t
t{ -NAN F0= -> false }t

TESTING F0<
\ F0< NAN tests
t{ +NAN F0< -> false }t
t{ -NAN F0< -> false }t

TESTING F0>
\ F0> NAN tests
t{ +NAN F0> -> false }t
t{ -NAN F0> -> false }t


