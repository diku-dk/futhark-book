-- Segmented scan with integer addition
fun sgm_scan_add (vals:[n]i32) (flags:[n]bool) : [n]i32 =
  let pairs = scan ( fn (v1,f1) (v2,f2) =>
                       let f = f1 || f2
                       let v = if f2 then v2 else v1+v2
                       in (v,f) ) (0,False) (zip vals flags)
  let (res,_) = unzip pairs
  in res

-- Longest streak of increasing numbers. Solution to Problem 2 of
-- 2015 International APL Problem Solving Competition - Phase I
-- Converted into Futhark code.
--
-- streak [1, 2, 3, 4, 5, 6, 7, 8, 9] == 8
-- streak [1] == 0
-- streak [9, 8, 7, 6, 5, 4] == 0
-- streak [1, 5, 3, 4, 2, 6, 7, 8] == 3

fun main() : []bool =
  [sgm_streak ([1, 2, 3, 4, 5, 6, 7, 8, 9]) == 8,
   sgm_streak ([1]) == 0,
   sgm_streak ([9, 8, 7, 6, 5, 4]) == 0,
   sgm_streak ([1, 5, 3, 4, 2, 6, 7, 8]) == 3]

fun max (a:i32) (b:i32) : i32 = if a > b then a else b

-- xs   : [1, 5, 3, 4, 2, 6, 7, 8]
-- ys   : [5, 3, 4, 2, 6, 7, 8, 1]
-- is   : [1, 0, 1, 0, 1, 1, 1]
-- ss   : [1, 1, 2, 2, 3, 4, 5]
-- ss1  : [0, 1, 0, 2, 0, 0, 0]
-- ss2  : [0, 1, 1, 2, 2, 2, 2]
-- ss3  : [1, 0, 1, 0, 1, 2, 3]
-- res  : 3

-- Longest streak of increasing numbers
fun sgm_streak (xs: [n]i32) : i32  =
  let ys = rotate 1 xs
  let is = (zipWith (fn x y => if x < y then 1 else 0) xs ys)[0:n-1]
  let isn = map (==0) is
  let ss3 = sgm_scan_add is isn
  let res = reduce max 0 ss3
  in res