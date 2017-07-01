-- ==
-- input { } output { [true,true] }

let max (a:i32) (b:i32) : i32 = if a > b then a else b
let min (a:i32) (b:i32) : i32 = if a < b then a else b

-- Return the first index i into xs for which xs[i] == e
let find_idx_first [n] (e:i32) (xs:[n]i32) : i32 =
  let es = map (\x i -> if x==e then i else n) xs (iota n)
  let res = reduce min n es
  in if res == n then -1 else res

-- Return the last index i into xs for which xs[i] == e
let find_idx_last [n] (e:i32) (xs:[n]i32) : i32 =
  let es = map (\x i -> if x==e then i else -1) xs (iota n)
  in reduce max (-1) es

let main () : []bool =
  let xs = [34,453,23,5,67,445,23,-23,65,34,-232,56565,3,1,67567,3,545,67,343,23]
  in [find_idx_last 67 xs == 17,
      find_idx_first 67 xs == 4]
