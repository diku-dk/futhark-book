-- Given N, compute the sum of squares of the first N integers.
-- ==
-- compiled input {       1000i64 } output {           332833500i64 }
-- compiled input {    1000000i64 } output {  333332833333500000i64 }
-- compiled input { 1000000000i64 } output { 3338615082255021824i64 }

def main (n: i64): i64 =
  reduce (+) 0 (map (**2) (iota n))
