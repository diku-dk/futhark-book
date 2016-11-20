-- Given N, compute the sum of squares of the first N integers.
-- ==
-- input {       1000 } output {   332833500 }
-- input {    1000000 } output {   584144992 }
-- input { 1000000000 } output { -2087553280 }

fun main (n: int): int =
  reduce (+) 0 (map (**2) (iota n))
