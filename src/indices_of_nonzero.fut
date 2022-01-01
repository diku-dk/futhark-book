-- ==
-- input { [0,5,2,0,1] }
-- output { [1,2,4] }

def indices_of_nonzero [n] (xs: [n]i32): []i32 =
  let xs_and_is = zip xs (iota n)
  let xs_and_is' = filter (\(x,_) -> x != 0) xs_and_is
  let (_, is') = unzip xs_and_is'
  in is'

def main [n] (xs: [n]i32): []i32 = indices_of_nonzero xs
