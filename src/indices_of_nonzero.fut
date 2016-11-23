-- ==
-- input { [0,5,2,0,1] }
-- output { [1,2,4] }

fun main(xs: [n]int): []int = indices_of_nonzero xs

fun indices_of_nonzero(xs: [n]int): []int =
  let xs_and_is = zip xs (iota n)
  let xs_and_is' = filter (fn (x,_) => x != 0) xs_and_is
  let (_, is') = unzip xs_and_is'
  in is'
