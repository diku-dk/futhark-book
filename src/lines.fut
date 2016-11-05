
type point = (i32,i32)
type line = (point,point)
type points = []point

fun max (x:i32) (y:i32) : i32 = if x > y then x else y

fun main () : [][]i32 =
  let lines = [((2,3),(28,20)),((27,3),(2,28)),((5,20),(20,20)),((6,10),(6,25))]
  in draw lines

fun linepoints (p1:point) (p2:point) : points =
    let len:i32 = max (abs(p1.0 - p2.0)) (abs(p1.1-p2.1))
    in map (fn (i:i32):point =>
              let x1 = p1.0
	      let x2 = p2.0
	      let y1 = p1.1
	      let y2 = p2.1
	      let dirx = if x2 > x1 then 1 else if x1 > x2 then -1 else 0
              let slop:f32 = if x2==x1 then f32(1) else f32(y2-y1) / abs(f32(x2-x1))
              let x = p1.0+(i*dirx)
	      let y = p1.1+i32(slop*f32(i))
	      in (x,y))
       (iota(len))

-- draw all lines
fun draw (lines:[]line) : [][]i32 =
  let grid : *[][]i32 = replicate 30 (replicate 30 0)
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