-- ==
-- input {} output @ lines_seq.ok

-- Finding points on a line
type point = (i32,i32)
type line = (point,point)
type points = []point

let compare (v1:i32) (v2:i32) : i32 =
  if v2 > v1 then 1 else if v1 > v2 then -1 else 0

let slope ((x1,y1):point) ((x2,y2):point) : f32 =
  if x2==x1 then if y2>y1 then 1f32 else -1f32
                 else r32(y2-y1) / f32.abs(r32(x2-x1))

let linepoints ((x1,y1):point, (x2,y2):point) : points =
  let len = 1 + i32.max (i32.abs(x2-x1)) (i32.abs(y2-y1))
  let xmax = i32.abs(x2-x1) > i32.abs(y2-y1)
  let (dir,sl) =
    if xmax then (compare x1 x2, slope (x1,y1) (x2,y2))
    else (compare y1 y2, slope (y1,x1) (y2,x2))
  in map (\i -> if xmax
                then (x1+i*dir,
                      y1+i32.f32(f32.round(sl*r32(i))))
                else (x1+i32.f32(f32.round(sl*r32(i))),
                      y1+i*dir)) (iota len)

-- Write to grid
let update [h] [w] [n] (grid: [h][w]i32)(xs:[n]i32)(ys:[n]i32): [h][w]i32 =
  let is = map2 (\x y -> w*y+x) xs ys
  let flatgrid = flatten grid
  let ones = map (\ _ -> 1) is
  in unflatten h w (scatter (copy flatgrid) is ones)

-- Sequential algorithm for drawing multiple lines
let drawlines [h] [w] [n] (grid: *[h][w]i32) (lines:[n]line) : [h][w]i32 =
  loop (grid) for i < n do -- find points for line i
    let (xs,ys) = unzip (linepoints (lines[i]))
    in update grid xs ys

-- Draw lines on a 70 by 30 grid
let main : [][]i32 =
  let height:i32 = 30
  let width:i32 = 70
  let grid : *[][]i32 = replicate height (replicate width 0)
  let lines = [((58,20),(2,3)),((27,3),(2,28)),((5,20),(20,20)),
               ((4,10),(6,25)),((26,25),(26,2)),((58,20),(52,3))]
  in drawlines grid lines
