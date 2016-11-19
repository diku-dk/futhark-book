-- Utilities

-- [sgmScanSum_i32 xs fs] returns the sum-scan of the argument xs but
-- reset at points i where xs[i] is true.

fun sgmScanSum_i32 (vals:[n]i32) (flags:[n]bool) : [n]i32 =
  let pairs = scan ( fn (v1,f1) (v2,f2) =>
                       let f = f1 || f2
                       let v = if f2 then v2 else v1+v2
                       in (v,f) ) (0,False) (zip vals flags)
  let (res,_) = unzip pairs
  in res

fun replIdx (reps:[n]i32) : []i32 =
  let tmp = scan (+) 0 reps
  let sers = zipWith (fn i t => if i == 0 then 0 else t) (iota n) tmp
  let m = tmp[n-1]
  let tmp2 = write sers (iota(n)) (replicate m 0)
  let flags = map (>0) tmp2
  let res = sgmScanSum_i32 tmp2 flags
  in res

fun sgmIota (flags:[n]bool) : [n]i32 =
  let iotas = sgmScanSum_i32 (replicate n 1) flags
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

-- Parallel flattened algorithm for drawing multiple lines
fun drawlines_par (grid:*[h][w]i32) (lines:[n]line) :[h][w]i32 =
  let lens = map (fn line =>
                   let ((x1,y1),(x2,y2)) = line
		   in max (abs(x1-x2)) (abs(y1-y2))) lines
  let idxs = replIdx lens
  let iotan = iota n
  let nums = map (fn i => iotan[i]) idxs
  let nums2 = rotate 1 nums
  let flags = zipWith (!=) nums nums2
  let lines1 = map (fn i => unsafe lines[i]) idxs
  let dirxs = map (fn ((x1,_),(x2,_)) =>
                     if x2 > x1 then 1
                     else if x1 > x2 then -1
	             else 0) lines1
  let slops = map (fn ((x1,y1),(x2,y2)) =>
                     if x2 == x1 then
   	    	       if y2 > y1 then f32(1) else f32(-1)
		     else f32(y2-y1) / abs(f32(x2-x1))) lines1
  let iotas = sgmIota flags
  let xs = zipWith (fn ((x1,_),_) dirx i =>
                     x1+dirx*i) lines1 dirxs iotas
  let ys = zipWith (fn ((_,y1),_) slop i =>
                     y1+i32(slop*f32(i))) lines1 slops iotas
  let is = zipWith (fn x y => w*y+x) xs ys
  let flatgrid = reshape (h*w) grid
  let ones = map (fn _ => 1) is
  in reshape (h,w) (write is ones flatgrid)
