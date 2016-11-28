-- Utilities

-- [sgm_scan_add xs fs] returns the sum-scan of the argument xs but
-- reset at points i where xs[i] is true.

fun sgm_scan_add (vals:[n]i32) (flags:[n]bool) : [n]i32 =
  let pairs = scan ( fn (v1,f1) (v2,f2) =>
                       let f = f1 || f2
                       let v = if f2 then v2 else v1+v2
                       in (v,f) ) (0,False) (zip vals flags)
  let (res,_) = unzip pairs
  in res

fun repl_idx (reps:[n]i32) : []i32 =
  let s1 = scan (+) 0 reps
  let s2 = map (fn i => if i==0 then 0 else unsafe s1[i-1]) (iota n)
  let tmp = write s2 (iota n) (replicate (unsafe s1[n-1]) 0)
  let flags = map (>0) tmp
  in sgm_scan_add tmp flags

fun sgm_iota (flags:[n]bool) : [n]i32 =
  let iotas = sgm_scan_add (replicate n 1) flags
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
  in drawlines grid lines

-- Write to grid
fun upd_grid (grid:*[h][w]i32)(xs:[n]i32)(ys:[n]i32):[h][w]i32 =
  let is = map (fn x y => w*y+x) xs ys
  let flatgrid = reshape (h*w) grid
  let ones = map (fn _ => 1) is
  in reshape (h,w) (write is ones flatgrid)

-- Parallel flattened algorithm for drawing multiple lines
fun drawlines (grid:*[h][w]i32) (lines:[n]line) :[h][w]i32 =
  let lens = map (fn ((x1,y1),(x2,y2)) =>
                   max (abs(x1-x2)) (abs(y1-y2))) lines
  let idxs = repl_idx lens
  let iotan = iota n
  let nums = map (fn i => iotan[i]) idxs
  let flags = map (!=) nums (rotate 1 nums)
  let lines1 = map (fn i => unsafe lines[i]) idxs
  let dirxs = map (fn ((x1,_),(x2,_)) =>
                     if x2 > x1 then 1
                     else if x1 > x2 then -1
                     else 0) lines1
  let slops = map (fn ((x1,y1),(x2,y2)) =>
                     if x2 == x1 then
                       if y2 > y1 then f32(1) else f32(-1)
                     else f32(y2-y1) / abs(f32(x2-x1))) lines1
  let iotas = sgm_iota flags
  let xs = map (fn ((x1,_),_) dirx i =>
                  x1+dirx*i) lines1 dirxs iotas
  let ys = map (fn ((_,y1),_) slop i =>
                  y1+i32(slop*f32(i))) lines1 slops iotas
  in upd_grid grid xs ys