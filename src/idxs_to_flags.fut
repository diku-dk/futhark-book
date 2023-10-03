-- ==
-- input { [2i64,1i64,3i64] } output { [false,false,true,true,false,false] }
-- input { [2i64,0i64,3i64] } output { [false,false,true,false,false] }

-- Segmented scan with integer addition
def segmented_scan [n] 't (op: t -> t -> t) (ne: t)
                          (flags: [n]bool) (as: [n]t): [n]t =
  (unzip (scan (\(x_flag,x) (y_flag,y) ->
                (x_flag || y_flag,
                 if y_flag then y else x `op` y))
          (false, ne)
          (zip flags as))).1

def replicated_iota [n] (reps:[n]i64) : []i64 =
  let s1 = scan (+) 0 reps
  let s2 = map (\i -> if i==0 then 0 else s1[i-1]) (iota n)
  let tmp = scatter (replicate s1[n-1] 0) s2 (iota n)
  let flags = map (>0) tmp
  in segmented_scan (+) 0 flags tmp

def segmented_replicate [n] (reps:[n]i64) (vs:[n]i64) : []i64 =
  let idxs = replicated_iota reps
  in map (\i -> vs[i]) idxs

def idxs_to_flags [n] (is : [n]i64) : []bool =
  let vs = segmented_replicate is (iota n)
  let m = length vs
  in map2 (!=) (vs :> [m]i64) ([0] ++ vs[:m-1] :> [m]i64)

def main (xs: []i64): []bool =
  idxs_to_flags xs
