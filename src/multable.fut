-- ==
-- input {4i64}
-- output {
--   [[0i64, 0i64, 0i64, 0i64],
--    [0i64, 1i64, 2i64, 3i64],
--    [0i64, 2i64, 4i64, 6i64],
--    [0i64, 3i64, 6i64, 9i64]]
-- }

def multable (n : i64) : [n][n]i64 =
  map (\i ->
    map (\j -> i * j) (iota n))
      (iota n)

def main (n:i64) : [n][n]i64 = multable n
