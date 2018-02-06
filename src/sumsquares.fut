-- Given N, compute the sum of squares of the first N integers.
-- ==
-- compiled input {       1000 } output {   332833500 }
-- compiled input {    1000000 } output {   584144992 }
-- compiled input { 1000000000 } output { -2087553280 }

let main (n: i32): i32 =
  reduce (+) 0 (map (**2) (iota n))
