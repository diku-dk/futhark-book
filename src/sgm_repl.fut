-- ==
-- input {} output { [5i32, 5i32, 6i32, 8i32, 8i32, 8i32] }

-- Segmented scan with integer addition
def segmented_scan [n] 't (op: t -> t -> t) (ne: t)
                          (flags: [n]bool) (as: [n]t): [n]t =
  (unzip (scan (\(x_flag,x) (y_flag,y) ->
                (x_flag || y_flag,
                 if y_flag then y else x `op` y))
          (false, ne)
          (zip flags as))).1

def replicated_iota [n] (reps:[n]i32) : []i32 =
  let s1 = scan (+) 0 reps
  let s2 = map (\i -> if i==0 then 0 else s1[i-1]) (iota n)
  let tmp = scatter (replicate s1[n-1] 0) s2 (iota n)
  let flags = map (>0) tmp
  in segmented_scan (+) 0 flags tmp

def segmented_replicate [n] (reps:[n]i32) (vs:[n]i32) : []i32 =
  let idxs = replicated_iota reps
  in map (\i -> vs[i]) idxs

def main : []i32 =
  segmented_replicate ([2,1,0,3,0]) ([5,6,9,8,4])  -- [5,5,6,8,8,8]
