def fib (n: i64): [n]i64 =
  -- Create "empty" array.
  let arr = iota(n)
  -- Fill array with Fibonacci numbers.
  in loop (arr) for i < n-2 do
       let arr[i+2] = arr[i] + arr[i+1]
       in arr
