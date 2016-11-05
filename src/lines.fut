
type point = (i32,i32)
type line = (point,point)
type points = []point

fun max (x:i32) (y:i32) : i32 = if x > y then x else y

fun main () : [][]i32 =
  let lines = [((58,20),(2,3)),((27,3),(2,28)),((5,20),(20,20)),((6,10),(6,25)),((26,25),(26,2))]
  in draw lines

fun linepoints (p1:point) (p2:point) : points =
    let (x1,y1) = p1
    let (x2,y2) = p2
    let len = max (abs(x1-x2)) (abs(y1-y2))
    let dirx = if x2 > x1 then 1 else if x1 > x2 then -1 else 0
    let slop = if x2==x1 then
                  if y2 > y1 then f32(1) else f32(-1)
	       else f32(y2-y1) / abs(f32(x2-x1))
    in map (fn (i:i32):point =>
              let x = x1+i*dirx
	      let y = y1+i32(slop*f32(i))
	      in (x,y))
       (iota(len))

-- draw all lines
fun draw (lines:[]line) : [][]i32 =
  let grid : *[][]i32 = replicate 30 (replicate 70 0)
  in loop (grid) = for i < (shape lines)[0] do
       let (p1,p2) = lines[i]
       let ps :[]point = linepoints p1 p2
       in loop (grid) = for j < (shape ps)[0] do
            let x = (ps[j]).0
            let y = (ps[j]).1
            let grid[y,x] = 1
	    in grid
          in grid
     in grid