let main [n] [m] (xs: [n]i32) (ys: [m]i32): []i32 =
  map (\i -> if i < n then xs[i] else ys[i-n])
      (iota (n+m))
