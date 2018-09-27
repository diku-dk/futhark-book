-- ==
-- input {} output { [2i32, 5i32, 63i32, 2i32, 6i32, 13i32, 16i32, 4i32, 10i32, 13i32] }

-- Segmented scan with integer addition
let sgm_scan_add [n] (vals:[n]i32) (flags:[n]bool) : [n]i32 =
  let pairs = scan ( \ (v1,f1) (v2,f2) ->
                       let f = f1 || f2
                       let v = if f2 then v2 else v1+v2
                       in (v,f) ) (0,false) (zip vals flags)
  let (res,_) = unzip pairs
  in res

-- Generic version of segmented scan
let sgm_scan 't [n] (g:t->t->t) (ne:t) (vals:[n]t) (flags:[n]bool) : [n]t =
  let pairs = scan ( \ (v1,f1) (v2,f2) ->
                       let f = f1 || f2
                       let v = if f2 then v2 else g v1 v2
                       in (v,f) ) (ne,false) (zip vals flags)
  let (res,_) = unzip pairs
  in res

let main : []i32 =
  let data = [2,3,63,2,4,7,3,4,6,3]
  let flags = [false,false,true,true,false,false,
               false,true,false,false]
  in sgm_scan_add data flags