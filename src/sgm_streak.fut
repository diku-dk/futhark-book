-- Segmented scan with integer addition
let segmented_scan_add [n] (flags:[n]bool) (vals:[n]i32) : [n]i32 =
  let pairs = scan ( \(v1,_) (v2,f2) ->
                       let v = if f2 then v2 else v1+v2
                       in (v,false) ) (0,false) (zip vals flags)
  let (res,_) = unzip pairs
  in res


-- ==
-- entry: segmented_scan_add_tester
-- input { [false,false,true,true,false,false, false,true,false,false]
--         [2,3,63,2,4,7,3,4,6,3] }
-- output { [2i32, 5i32, 63i32, 2i32, 6i32, 13i32, 16i32, 4i32, 10i32, 13i32] }
entry segmented_scan_add_tester [n] (flags:[n]bool) (vals:[n]i32) : [n]i32 =
  segmented_scan_add flags vals

let max (a:i32) (b:i32) : i32 = if a > b then a else b

-- xs   : [1, 5, 3, 4, 2, 6, 7, 8]
-- ys   : [5, 3, 4, 2, 6, 7, 8, 1]
-- is   : [1, 0, 1, 0, 1, 1, 1]
-- fs   : [0, 1, 0, 1, 0, 0, 0]
-- ss   : [1, 0, 1, 0, 1, 2, 3]
-- res  : 3

-- Longest streak of increasing numbers
let segmented_streak [n] (xs: [n]i32) : i32  =
  let ys = rotate 1 xs
  let is = (map2 (\x y -> if x < y then 1 else 0) xs ys)[0:n-1]
  let fs = map (==0) is
  let ss = segmented_scan_add fs is
  let res = reduce max 0 ss
  in res

-- Longest streak of increasing numbers. Solution to Problem 2 of
-- 2015 International APL Problem Solving Competition - Phase I
-- Converted into Futhark code.
--
-- streak [1, 2, 3, 4, 5, 6, 7, 8, 9] == 8
-- streak [1] == 0
-- streak [9, 8, 7, 6, 5, 4] == 0
-- streak [1, 5, 3, 4, 2, 6, 7, 8] == 3

-- ==
-- entry: segmented_streak_tester
-- input { [1, 2, 3, 4, 5, 6, 7, 8, 9] } output { 8 }
-- input { [1] } output { 0 }
-- input { [9, 8, 7, 6, 5, 4] } output { 0 }
-- input { [1, 5, 3, 4, 2, 6, 7, 8] } output { 3 }
entry segmented_streak_tester [n] (xs: [n]i32) : i32 =
  segmented_streak xs
