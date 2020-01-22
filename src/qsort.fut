-- Data-parallel implementation of quicksort.

import "segmented"

let segmented_replicate [n] (reps:[n]i32) (vs:[n]i32) : []i32 =
  let idxs = replicated_iota reps
  in map (\i -> unsafe vs[i]) idxs

let info 't ((<=): t -> t -> bool) (x:t) (y:t) : i32 =
  if x <= y then
     if y <= x then 0 else -1
  else 1

let tripit x =
  if x < 0 then (1,0,0)
  else if x > 0 then (0,0,1) else (0,1,0)

let tripadd (a1:i32,e1:i32,b1:i32) (a2,e2,b2) =
  (a1+a2,e1+e2,b1+b2)

type sgm = {start:i32,sz:i32}  -- segment

let step [n] 't ((<=): t -> t -> bool) (xs:*[n]t) (sgms:[]sgm) : (*[n]t,[]sgm) =
  --let _ = trace {NEW_STEP=()}
  let pivots : []t = map (\sgm -> xs[sgm.start + sgm.sz/2]) sgms
  let sgms_szs : []i32 = map (\sgm -> sgm.sz) sgms
  let idxs : []i32 = replicated_iota sgms_szs

  let is =
    let is1 = segmented_replicate sgms_szs (map (\x -> x.start) sgms)
    let fs = map2 (!=) is1 (rotate (i32.negate 1) is1)
    let is2 = segmented_iota fs
    in map2 (+) is1 is2

  let infos : []i32 = map2 (\idx i -> info (<=) xs[i] pivots[idx]) idxs is
  let orders : [](i32,i32,i32) = map tripit infos
  let flags : []bool = map2 (!=) idxs (rotate (i32.negate 1) idxs)
  let flags = [true] ++ flags[1:]
  let bszs : [](i32,i32,i32) = segmented_reduce tripadd (0,0,0) flags orders

  let sgms' =
    map2 (\(sgm:sgm) (a,e,b) -> [{start=sgm.start,sz=a},
                                 {start=sgm.start+a+e,sz=b}]) sgms bszs
    |> flatten
    |> filter (\sgm -> sgm.sz > 1)

  let newpos : []i32 =
    let where : [](i32,i32,i32) = segmented_scan tripadd (0,0,0) flags orders
    in map3 (\i (a,e,b) info ->
             let (x,y,_) = bszs[i]
             let s = sgms[i].start
             in if info < 0 then s+a-1
                else if info > 0 then s+b-1+x+y
                else s+e-1+x) idxs where infos

  let vs = map (\i -> xs[i]) is
  let xs' = scatter xs newpos vs
  in (xs',sgms')

let qsort [n] 't ((<=): t -> t -> bool) (xs:*[n]t) : [n]t =
  if n < 2 then xs
  else (loop (xs,mms) = (xs,[{start=0,sz=n}]) while length mms > 0 do
          step (<=) xs mms).0

let main [n] (xs:*[n]i32) = qsort (i32.<=) xs

entry first [n] (xs:*[n]i32) =
  let rec2arr ({start,sz}:sgm) = [start,sz]
  let (_,sgms) = step (i32.<=) xs [{start=0,sz=n}]
  in map rec2arr sgms
