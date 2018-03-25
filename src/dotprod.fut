-- ==
-- input { [1,2,3] [4,5,6] }
-- output { 32 }

let main (x: []i32) (y: []i32): i32 =
  reduce (+) 0 (map2 (*) x y)