-- ==
-- input {4}
-- output {
--   [[0i32, 0i32, 0i32, 0i32],
--    [0i32, 1i32, 2i32, 3i32],
--    [0i32, 2i32, 4i32, 6i32],
--    [0i32, 3i32, 6i32, 9i32]]
-- }

def multable (n : i32) : [n][n]i32 =
  map (\i ->
    map (\j -> i * j) (iota n))
      (iota n)

def main (n:i32) : [n][n]i32 = multable n