fun indices_of_nonzero(xs: [n]int): []int =
  let xs_and_is = zip xs (iota n)
  let xs_and_is' = filter (fn (x,_) => x != 0) xs_and_is
  let (_, is') = unzip xs_and_is'
  in is'
