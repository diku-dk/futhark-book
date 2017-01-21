-- Utilities
fun max (x:i32) (y:i32) : i32 = if x > y then x else y

-- Finding points on a line
type point = (i32,i32)
type line = (point,point)
type points = []point

fun compare (v1:i32) (v2:i32) : i32 =
  if v2 > v1 then 1 else if v1 > v2 then -1 else 0

fun slo ((x1,y1):point) ((x2,y2):point) : f32 =
  if x2==x1 then if y2>y1 then f32(1) else f32(-1)
                 else f32(y2-y1) / abs(f32(x2-x1))

fun linepoints ((x1,y1):point, (x2,y2):point) : points =
  let len = 1 + max (abs(x2-x1)) (abs(y2-y1))
  let xmax = abs(x2-x1) > abs(y2-y1)
  let (dir,slop) =
    if xmax then (compare x1 x2, slo (x1,y1) (x2,y2))
    else (compare y1 y2, slo (y1,x1) (y2,x2))
  in map (fn i => if xmax then (x1+i*dir, y1+i32(slop*f32(i)))
                  else (x1+i32(slop*f32(i)), y1+i*dir)) (iota len)

-- Draw lines on a 70 by 30 grid
fun main () : [][]i32 =
  let height:i32 = 30
  let width:i32 = 70
  let grid : *[][]i32 = replicate height (replicate width 0)
  let lines = [((58,20),(2,3)),((27,3),(2,28)),((5,20),(20,20)),
               ((4,10),(6,25)),((26,25),(26,2))]
  in drawlines grid lines

-- Write to grid
fun update (grid:*[h][w]i32)(xs:[n]i32)(ys:[n]i32):*[h][w]i32 =
  let is = map (fn x y => w*y+x) xs ys
  let flatgrid = reshape (h*w) grid
  let ones = map (fn _ => 1) is
  in reshape (h,w) (write is ones flatgrid)

-- Sequential algorithm for drawing multiple lines
fun drawlines (grid: *[h][w]i32) (lines:[n]line) : [h][w]i32 =
  loop (grid) = for i < n do -- find points for line i
    let (xs,ys) = unzip (linepoints (lines[i]))
    in update grid xs ys
  in grid
