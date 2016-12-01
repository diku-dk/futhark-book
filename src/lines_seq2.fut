-- Utilities
fun max (x:i32) (y:i32) : i32 = if x > y then x else y

fun main () : [][2]i32 =
  let lines = [((58,20),(2,3)),((27,3),(2,28)),((5,20),(20,20)),((4,10),(6,25)),((26,25),(26,2))]
  in points lines

-- Finding points on a line
type point = (i32,i32)
type line = (point,point)
type points = []point

fun compare (v1:i32) (v2:i32) : i32 =
  if v2 > v1 then 1 else if v1 > v2 then -1 else 0

-- Compute a slope
fun sl ((x1,y1):point) ((x2,y2):point) : f32 =
  if x2==x1 then if y2>y1 then f32(1) else f32(-1)
		 else f32(y2-y1) / abs(f32(x2-x1))

fun linepoints ((x1,y1):point, (x2,y2):point) : points =
  let dx = abs(x1-x2)
  let dy = abs(y1-y2)
  let len = max dx dy
  let xmax = dx > dy
  let dir = if xmax then compare x1 x2
	    else compare y1 y2
  let slop =
    if xmax then sl (x1,y1) (x2,y2)
    else sl (y1,x1) (y2,x2)
  in map (fn i =>
            if xmax then (x1+i*dir,
			  y1+i32(slop*f32(i)))
	    else (x1+i32(slop*f32(i)),
		  y1+i*dir))
         (iota len)

-- Sequential algorithm for drawing multiple lines
fun points (lines:[n]line) : [][2]i32 =
  let points : [][]i32 = empty([2]i32)
  loop (points) = for i < n do -- find points for line i
     let ps = map (fn (x,y) => [x,y]) (linepoints (lines[i]))
     in concat points ps
  in points
