let multable (n : i32) : [n][n]i32 =
  map (\i ->
    map (\j -> i * j) (iota n))
      (iota n)

let main (n:i32) : [n][n]i32 = multable n