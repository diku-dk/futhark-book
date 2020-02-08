-- ==
-- input {} output @ lines_flat.ok

-- [sgm_scan_add xs fs] returns the sum-scan of the argument xs but
-- reset at points i where xs[i] is true.

let sgm_scan_add [n] (vals:[n]i32) (flags:[n]bool) : [n]i32 =
  let pairs = scan (\(v1,f1) (v2,f2) ->
                       let f = f1 || f2
                       let v = if f2 then v2 else v1+v2
                       in (v,f) ) (0,false) (zip vals flags)
  let (res,_) = unzip pairs
  in res

let repl_idx [n] (reps:[n]i32) : []i32 =
  let s1 = scan (+) 0 reps
  let s2 = map (\i -> if i==0 then 0 else unsafe s1[i-1]) (iota n)
  let tmp = scatter (replicate (unsafe s1[n-1]) 0) s2 (iota n)
  let flags = map (>0) tmp
  in sgm_scan_add tmp flags

-- Drawing lines
type point = (i32,i32)
type line = (point,point)
type points [n] = [n]point

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

-- Utility functions
let xmax ((x1,y1):point) ((x2,y2):point) : bool =
  abs(x1-x2) > abs(y1-y2)

let swap ((x,y):point) : point = (y,x)

let sgm_iota [n] (flags:[n]bool) : [n]i32 =
  let iotas = sgm_scan_add (replicate n 1) flags
  in map (\x->x-1) iotas

-- Parallel flattened algorithm for drawing multiple lines
let drawlines [h][w][n] (grid:*[h][w]i32)
                        (lines:[n]line) :[h][w]i32 =
  let lens = map (\ ((x1,y1),(x2,y2)) ->
                   1 + max (abs(x2-x1)) (abs(y2-y1))) lines
  let idxs = repl_idx lens
  let lns = map (\ i -> unsafe lines[i]) idxs
  let dirs = map (\ (p1,p2) ->
                   if xmax p1 p2 then compare (p1.0) (p2.0)
                   else compare (p1.0) (p2.1)) lns
  let sls = map (\ (p1,p2) ->
                  if xmax p1 p2 then slope p1 p2
                  else slope (swap p1) (swap p2)) lns
  let is = sgm_iota (map2 (!=) idxs (rotate 1 idxs))
  let xs = map4 (\ (p1,p2) dirx sl i ->
                 if xmax p1 p2 then p1.0+dirx*i
                 else p1.0+t32(sl*r32(i))) lns dirs sls is
  let ys = map4 (\ (p1,p2) dirx sl i ->
                 if xmax p1 p2 then p1.1+t32(sl*r32(i))
                 else p1.1+i*dirx) lns dirs sls is
  in update grid xs ys

let main : [][]i32 =
  let height:i32 = 30
  let width:i32 = 70
  let grid : *[][]i32 = replicate height (replicate width 0)
  let lines = [((58,20),(2,3)),((27,3),(2,28)),((5,20),(20,20)),
               ((4,10),(6,25)),((26,25),(26,2)),((58,20),(52,3))]
  in drawlines grid lines
