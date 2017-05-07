import "futlib/math"

-- Find the first n primes
let primes (n:i32) : []i32 =
  if n == 2 then empty(i32)
  else let sqrtn = i32(f32.sqrt(f32(n)))+1
       let first = primes sqrtn
       let is = map (+sqrtn) (iota(n-sqrtn))
       let fs = map (\i ->
                     let xs = map (\p -> if i%p==0 then 1
                                         else 0) first
                     in reduce (+) 0 xs) is
       -- apply the sieve
       let new = filter (\i -> 0 == unsafe fs[i-sqrtn]) is
  in concat first new

-- Return the number of primes less than n
let main (n:i32) : i32 =
  let ps = primes n in (shape ps)[0]
