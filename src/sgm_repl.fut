-- ==
-- input {} output { [5i32, 5i32, 6i32, 8i32, 8i32, 8i32] }

-- Segmented scan with integer addition
let sgm_scan_add [n] (vals:[n]i32) (flags:[n]bool) : [n]i32 =
  let pairs = scan ( \(v1,f1) (v2,f2) ->
                       let f = f1 || f2
                       let v = if f2 then v2 else v1+v2
                       in (v,f) ) (0,false) (zip vals flags)
  let (res,_) = unzip pairs
  in res

let repl_idx [n] (reps:[n]i32) : []i32 =
  let s1 = scan (+) 0 reps
  let s2 = map (\i -> if i==0 then 0 else s1[i-1]) (iota n)
  let tmp = scatter (replicate (s1[n-1]) 0) s2 (iota n)
  let flags = map (>0) tmp
  in sgm_scan_add tmp flags

let sgm_repl [n] (reps:[n]i32) (vs:[n]i32) : []i32 =
  let idxs = repl_idx reps
  in map (\i -> vs[i]) idxs

let main : []i32 =
  sgm_repl ([2,1,0,3,0]) ([5,6,9,8,4])  -- [5,5,6,8,8,8]
