-- Utilities

import "/futlib/math"

-- Finding points on a line
type point = (i32,i32)
type line = (point,point)
type points = []point

let compare (v1:i32) (v2:i32) : i32 =
  if v2 > v1 then 1 else if v1 > v2 then -1 else 0

-- Compute a slope
let sl ((x1,y1):point) ((x2,y2):point) : f32 =
  if x2==x1 then if y2>y1 then 1f32 else -1f32
		 else r32(y2-y1) / f32.abs(r32(x2-x1))

let linepoints ((x1,y1):point, (x2,y2):point) : points =
  let dx = i32.abs(x1-x2)
  let dy = i32.abs(y1-y2)
  let len = i32.max dx dy
  let xmax = dx > dy
  let dir = if xmax then compare x1 x2
	    else compare y1 y2
  let slop =
    if xmax then sl (x1,y1) (x2,y2)
    else sl (y1,x1) (y2,x2)
  in map (\i ->
            if xmax then (x1+i*dir,
			  y1+t32(slop*r32(i)))
	    else (x1+t32(slop*r32(i)),
		  y1+i*dir))
         (iota len)

-- Sequential algorithm for drawing multiple lines
let points [n] (lines:[n]line) : [][2]i32 =
  let points : [][]i32 = []
  in loop (points) for i < n do -- find points for line i
     let ps = map (\(x,y) -> [x,y]) (linepoints (lines[i]))
     in concat points ps

let main () : [][2]i32 =
  let lines = [((58,20),(2,3)),((27,3),(2,28)),((5,20),(20,20)),((4,10),(6,25)),((26,25),(26,2))]
  in points lines
