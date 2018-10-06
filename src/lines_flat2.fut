-- ==
-- input {} output @ lines_flat2.ok

import "/futlib/math"
import "segmented"

-- Drawing lines
type point = (i32,i32)
type line = (point,point)

-- Write to grid
let update [h][w][n] (grid:*[h][w]i32) (xs:[n]i32)
                     (ys:[n]i32) : [h][w]i32 =
  let is = map2 (\x y -> w*y+x) xs ys
  let flatgrid = flatten grid
  let ones = map (\_ -> 1) is
  in unflatten h w (scatter (copy flatgrid) is ones)

let max = i32.max
let abs = i32.abs

let compare (v1:i32) (v2:i32) : i32 =
  if v2 > v1 then 1 else if v1 > v2 then -1 else 0

let slo ((x1,y1):point) ((x2,y2):point) : f32 =
  if x2==x1 then if y2>y1 then r32(1) else r32(-1)
                 else r32(y2-y1) / r32(abs(x2-x1))

-- Parallel flattened algorithm for turning lines into
-- points, using expansion.

let points_in_line ((x1,y1),(x2,y2)) =
  i32.(1 + max (abs(x2-x1)) (abs(y2-y1)))

let get_point_in_line ((p1,p2):line) (i:i32) =
  if i32.abs(p1.1-p2.1) > i32.abs(p1.2-p2.2)
  then let dir = compare (p1.1) (p2.1)
       let sl = slo p1 p2
       in (p1.1+dir*i,
           p1.2+t32(sl*r32 i))
    else let dir = compare (p1.2) (p2.2)
         let sl = slo (p1.2,p1.1) (p2.2,p2.1)
         in (p1.1+t32(sl*r32 i),
             p1.2+i*dir)

let drawlines [h][w][n] (grid:*[h][w]i32)
                        (lines:[n]line) :[h][w]i32 =
  let (xs,ys) = expand points_in_line get_point_in_line lines
              |> unzip
  in update grid xs ys

let main : [][]i32 =
  let height:i32 = 30
  let width:i32 = 70
  let grid : *[][]i32 = replicate height (replicate width 0)
  let lines = [((58,20),(2,3)),((27,3),(2,28)),((5,20),(20,20)),
               ((4,10),(6,25)),((26,25),(26,2)),((58,20),(52,3))]
  in drawlines grid lines
