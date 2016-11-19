-- Utilities
fun sgmScanSum (vals:[n]i32) (flags:[n]bool) : [n]i32 =
  let pairs = scan ( fn (v1,f1) (v2,f2) =>
                       let f = f1 || f2
                       let v = if f2 then v2 else v1+v2
                       in (v,f) ) (0,False) (zip vals flags)
  let (res,_) = unzip pairs
  in res

fun replIdx (reps:[n]i32) : []i32 =
  let tmp = scan (+) 0 reps
  let sers = map (fn i => if i == 0 then 0 else tmp[i-1]) (iota(n))
  let m = tmp[n-1]
  let tmp2 = write sers (iota(n)) (replicate m 0)
  let flags = map (>0) tmp2
  let res = sgmScanSum tmp2 flags
  in res

fun sgmIota (flags:[n]bool) : [n]i32 =
  let iotas = sgmScanSum (replicate n 1) flags
  in map (-1) iotas

fun max (x:i32) (y:i32) : i32 = if x > y then x else y

-- Drawing lines
type point = (i32,i32)
type line = (point,point)
type points = []point

fun main () : [][]i32 =
  let height:i32 = 30
  let width:i32 = 70
  let grid : *[][]i32 = replicate height (replicate width 0)
  let lines = [((58,20),(2,3)),((27,3),(2,28)),((5,20),(20,20)),((6,10),(6,25)),((26,25),(26,2))]
  in drawlines_seq grid lines

-- Sequential algorithm for drawing multiple lines
fun linepoints (p1:point, p2:point) : points =
    let (x1,y1) = p1
    let (x2,y2) = p2
    let len = max (abs(x1-x2)) (abs(y1-y2))
    let dirx = if x2 > x1 then 1 else if x1 > x2 then -1 else 0
    let slop = if x2==x1 then
                  if y2 > y1 then f32(1) else f32(-1)
	       else f32(y2-y1) / abs(f32(x2-x1))
    in map (fn i =>
              let x = x1+i*dirx
	      let y = y1+i32(slop*f32(i))
	      in (x,y))
       (iota(len))

fun drawlines_seq (grid: *[h][w]i32) (lines:[n]line) : [h][w]i32 =
  let flatgrid = reshape (h*w) grid
  loop (flatgrid) = for i < n do
    let ps = linepoints (lines[i])   -- find points for line i
    let is = map (fn (x,y) => y*w+x) ps
    let ones = map (fn _ => 1) is
    in (write is ones flatgrid)
  in reshape (h,w) flatgrid
