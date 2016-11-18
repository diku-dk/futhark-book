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
  in drawlines_par grid lines

-- Sequential algorithm for drawing multiple lines
fun linepoints (p1:point) (p2:point) : points =
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
  loop (grid) = for i < n do
    let (p1,p2) = lines[i]
    let ps = linepoints p1 p2
    in loop (grid) = for j < (shape ps)[0] do
         let x = (ps[j]).0
         let y = (ps[j]).1
         let grid[y,x] = 1
         in grid
       in grid
  in grid

-- Parallel flattened algorithm for drawing multiple lines
fun drawlines_par (grid:*[h][w]i32) (lines:[n]line) :[h][w]i32 =
  let lens = map (fn line =>
                   let ((x1,y1),(x2,y2)) = line
		   in max (abs(x1-x2)) (abs(y1-y2))) lines
  let idxs = replIdx lens
  let iotan = iota n
  let nums = map (fn i => iotan[i]) idxs
  let nn = reduce (+) 0 lens                -- total number of points
  let flags = map (fn i => i != 0 && nums[i] != nums[i-1]) (iota nn)
  let (ps1,ps2) = unzip lines
  let (xs1,ys1) = unzip ps1
  let (xs2,ys2) = unzip ps2
  let xs1 = map (fn i => xs1[i]) idxs
  let ys1 = map (fn i => ys1[i]) idxs
  let xs2 = map (fn i => xs2[i]) idxs
  let ys2 = map (fn i => ys2[i]) idxs
  let dirxs = zipWith (fn x1 x2 =>
                        if x2 > x1 then 1
		        else if x1 > x2 then -1
		        else 0) xs1 xs2
  let slops = zipWith (fn x1 y1 x2 y2 =>
                        if x2 == x1 then
   	   	        if y2 > y1 then f32(1) else f32(-1)
		        else f32(y2-y1) / abs(f32(x2-x1))) xs1 ys1 xs2 ys2
  let iotas = sgmIota flags
  let xs = zipWith (fn x1 dirx i =>
                     x1+dirx*i) xs1 dirxs iotas
  let ys = zipWith (fn y1 slop i =>
                     y1+i32(slop*f32(i))) ys1 slops iotas
  let is = zipWith (fn x y => w*y+x) xs ys
  let flatgrid = reshape (h*w) grid
  in reshape (h,w) (write is (replicate nn 1) flatgrid)
