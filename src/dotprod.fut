fun main (x: []int) (y: []int): int =
  reduce (+) 0 (map (*) x y)