fun main (xs: [n]int) (ys: [m]int): []int =
  map (fn i => if i < n then xs[i] else ys[i-n])
      (iota (n+m))
