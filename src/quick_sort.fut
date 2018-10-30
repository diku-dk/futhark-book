-- | Data-parallel implementation of quicksort.

import "segmented"
import "/futlib/math"

let segmented_replicate [n] (reps:[n]i32) (vs:[n]i32) : []i32 =
  let idxs = replicated_iota reps
  in map (\i -> unsafe vs[i]) idxs

let info 't ((<=): t -> t -> bool) (x:t) (y:t) : i32 =
  if x <= y then if y <= x then 0 else -1
  else 1

let tripit x = if x < 0 then (1,0,0)
               else if x > 0 then (0,0,1) else (0,1,0)

let tripadd (a1:i32,e1:i32,b1:i32) (a2,e2,b2) =
  (a1+a2,e1+e2,b1+b2)

type sgm = {start:i32,sz:i32}  -- segment

let step [n] 't ((<=): t -> t -> bool) (xs:*[n]t) (sgms:[]sgm) : (*[n]t,[]sgm) =
  -- find a pivot for each segment
  let pivots : []t = map (\sgm -> unsafe xs[sgm.start + sgm.sz/2]) sgms
  let sgms_szs : []i32 = map (\sgm -> sgm.sz) sgms
  let idxs : []i32 = replicated_iota sgms_szs

  -- find the indexes into values in segments; after a value equal to
  -- a pivot has moved, it will no longer be part of a segment (it
  -- need not be moved again).
  let is =
    let is1 = segmented_replicate sgms_szs (map (\x -> x.start) sgms)
    let fs = map2 (!=) is1 (rotate (i32.negate 1) is1)
    let is2 = segmented_iota fs
    in map2 (+) is1 is2

  -- for each such value, how does it compare to the pivot associated
  -- with the segment?
  let infos : []i32 = map2 (\idx i -> unsafe info (<=) xs[i] pivots[idx]) idxs is
  let orders : [](i32,i32,i32) = map tripit infos

  -- compute segment descriptor
  let flags =
    let flags : []bool = map2 (!=) idxs (rotate (i32.negate 1) idxs)
    in [true] ++ flags[1:]

  -- compute partition sizes for each segment
  let pszs : [](i32,i32,i32) = segmented_reduce tripadd (0,0,0) flags orders

  -- compute the new segments
  let sgms' =
    map2 (\(sgm:sgm) (a,e,b) -> [{start=sgm.start,sz=a},
                                 {start=sgm.start+a+e,sz=b}]) sgms pszs
    |> flatten
    |> filter (\sgm -> sgm.sz > 1)

  -- compute the new positions of the values in the present segments
  let newpos : []i32 =
    let where : [](i32,i32,i32) = segmented_scan tripadd (0,0,0) flags orders
    in map3 (\i (a,e,b) info ->
             let (x,y,_) = unsafe pszs[i]
             let s = unsafe sgms[i].start
             in if info < 0 then s+a-1
                else if info > 0 then s+b-1+x+y
                else s+e-1+x) idxs where infos

  let vs = map (\i -> unsafe xs[i]) is
  let xs' = scatter xs newpos vs
  in (xs',sgms')

-- | Quicksort. Given a comparison function (<=) and an array of
-- elements, `qsort (<=) xs` returns an array with the elements in
-- `xs` sorted according to `<=`. The algorithm has best case work
-- complexity *O(n)* (when all elements are identical), worst case
-- work complexity *O(n^2)*, and an average case work complexity of
-- *O(n log n)*. It has best depth complexity *O(1)*, worst depth
-- complexity *O(n)* and average depth complexity *O(log n)*.

let qsort [n] 't ((<=): t -> t -> bool) (xs:[n]t) : [n]t =
  if n < 2 then xs
  else (loop (xs,mms) = (copy xs,[{start=0,sz=n}]) while length mms > 0 do
          step (<=) xs mms).1

-- | Like `qsort`@term, but sort based on key function.
let qsort_by_key [n] 't 'k (key: t -> k) ((<=): k -> k -> bool) (xs: [n]t): [n]t =
  zip (map key xs) (iota n)
  |> qsort (\(x, _) (y, _) -> x <= y)
  |> map (\(_, i) -> unsafe xs[i])

let main [n] (xs : [n]i32) : [n]i32 =
  qsort (i32.<=) xs
