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

let slope ((x1,y1):point) ((x2,y2):point) : f32 =
  if x2==x1 then if y2>y1 then r32(1) else r32(-1)
                 else r32(y2-y1) / r32(abs(x2-x1))

-- Parallel flattened algorithm for turning lines into
-- points, using expansion.

let points_in_line ((x1,y1),(x2,y2)) =
  i32.(1 + max (abs(x2-x1)) (abs(y2-y1)))

let get_point_in_line ((p1,p2):line) (i:i32) =
  if i32.abs(p1.0-p2.0) > i32.abs(p1.1-p2.1)
  then let dir = compare (p1.0) (p2.0)
       let sl = slope p1 p2
       in (p1.0+dir*i,
           p1.1+i32.f32(f32.round(sl*r32 i)))
    else let dir = compare (p1.1) (p2.1)
         let sl = slope (p1.1,p1.0) (p2.1,p2.0)
         in (p1.0+i32.f32(f32.round(sl*r32 i)),
             p1.1+i*dir)

let drawlines [h][w][n] (grid:*[h][w]i32)
                        (lines:[n]line) :[h][w]i32 =
  let (xs,ys) = expand points_in_line get_point_in_line lines
              |> unzip
  in update grid xs ys

type triangle = (point,point,point)

-- Parallel flattened algorithm for turning triangles into
-- lines, using expansion.

let bubble (a:point) (b:point) =
  if b.1 < a.1 then (b,a) else (a,b)

let normalize ((p,q,r): triangle) : triangle =
  let (p,q) = bubble p q
  let (q,r) = bubble q r
  let (p,q) = bubble p q
  in (p,q,r)

let lines_in_triangle ((p,_,r):triangle) : i32 =
  r.1 - p.1 + 1

let dxdy (a:point) (b:point) : f32 =
  let dx = b.0 - a.0
  let dy = b.1 - a.1
  in if dy == 0 then f32.i32 0
     else f32.i32 dx f32./ f32.i32 dy

let get_line_in_triangle ((p,q,r):triangle) (i:i32) =
  let y = p.1 + i
  in if i <= q.1 - p.1 then     -- upper half
       let sl1 = dxdy p q
       let sl2 = dxdy p r
       let x1 = p.0 + i32.f32(f32.round(sl1 * f32.i32 i))
       let x2 = p.0 + i32.f32(f32.round(sl2 * f32.i32 i))
       in ((x1,y),(x2,y))
     else                       -- lower half
       let sl1 = dxdy r p
       let sl2 = dxdy r q
       let dy = (r.1 - p.1) - i
       let x1 = r.0 - i32.f32(f32.round(sl1 * f32.i32 dy))
       let x2 = r.0 - i32.f32(f32.round(sl2 * f32.i32 dy))
       in ((x1,y),(x2,y))

let lines_of_triangles (xs:[]triangle) : []line =
  expand lines_in_triangle get_line_in_triangle
         (map normalize xs)

let draw (height:i32) (width:i32) : [][]i32 =
  let grid : *[][]i32 = replicate height (replicate width 0)
  let triangles = [((5,10),(2,28),(18,20)),
                   ((42,6),(58,10),(25,22)),
                   ((8,3),(15,15),(35,7))]
  let lines = lines_of_triangles triangles
  in drawlines grid lines

entry coords: [][2]i32 =
   let height = 30
   let width = 62
   let board = draw height width
   let board2 = map2 (\i row ->
                      map2 (\j b -> (i,j,b)) (iota width) row) (iota height) board
   let points = map (\ (i,j,_) -> [j,i]) (filter (\(_,_,b) -> b == 1) (flatten board2))
   in points

let main : [][]i32 = draw 30 62
