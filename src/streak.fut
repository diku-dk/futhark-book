-- Longest streak of increasing numbers. Solution to Problem 2 of
-- 2015 International APL Problem Solving Competition - Phase I
-- Converted into Futhark code.
--
-- ==
-- input { [1, 2, 3, 4, 5, 6, 7, 8, 9] } output { 8 }
-- input { [1] } output { 0 }
-- input { [9, 8, 7, 6, 5, 4] } output { 0 }
-- input { [1, 5, 3, 4, 2, 6, 7, 8] } output { 3 }

let max (a:i32) (b:i32) : i32 = if a > b then a else b

-- xs   : [1, 5, 3, 4, 2, 6, 7, 8]
-- ys   : [5, 3, 4, 2, 6, 7, 8, 1]
-- is   : [1, 0, 1, 0, 1, 1, 1]
-- ss   : [1, 1, 2, 2, 3, 4, 5]
-- ss1  : [0, 1, 0, 2, 0, 0, 0]
-- ss2  : [0, 1, 1, 2, 2, 2, 2]
-- ss3  : [1, 0, 1, 0, 1, 2, 3]
-- res  : 3

-- Longest streak of increasing numbers
let streak [n] (xs: [n]i32) : i32  =
  -- find increments
  let ys = rotate 1 xs
  let is = (map (\x y -> if x < y then 1 else 0) xs ys)[0:n-1]
  -- scan increments
  let ss = scan (+) 0 is
  -- nullify where there is no increment
  let ss1 = map (\s i -> s*(1-i)) ss is
  let ss2 = scan max 0 ss1
  -- subtract from increment scan
  let ss3 = map (-) ss ss2
  let res = reduce max 0 ss3
  in res

let main [n] (xs: [n]i32) : i32 = streak xs