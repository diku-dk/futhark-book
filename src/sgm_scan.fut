fun main () : []i32 =
  let data = [2,3,63,2,4,7,3,4,6,3]
  let flags = [False,False,True,True,False,False,
               False,True,False,False]
  in sgm_scan_add data flags

-- Segmented scan with integer addition
fun sgm_scan_add (vals:[n]i32) (flags:[n]bool) : [n]i32 =
  let pairs = scan ( fn ((v1,f1):(i32,bool))
                        ((v2,f2):(i32,bool)) : (i32,bool) =>
                       let f = f1 || f2
                       let v = if f2 then v2 else v1+v2
                       in (v,f) ) (0,False) (zip vals flags)
  let (res,_) = unzip pairs
  in res
