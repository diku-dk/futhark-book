fun main (x: []int) (y: []int): int =
  reduce (+) 0 (zipWith (*) x y)