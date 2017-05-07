-- ==
-- input { [1,2,3] [4,5,6] }
-- output { 32 }

let main (x: []int) (y: []int): int =
  reduce (+) 0 (map (*) x y)