let main [n] [m] (xs: [n]int) (ys: [m]int): []int =
  map (\i -> if i < n then xs[i] else ys[i-n])
      (iota (n+m))
