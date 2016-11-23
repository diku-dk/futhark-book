-- Find the first n primes
fun primes (n:i32) : []i32 =
  if n == 2 then empty(i32)
  else let sqrtn = i32(sqrt32(f32(n)))+1
       let first = primes sqrtn
       let is = map (+sqrtn) (iota(n-sqrtn))
       let fs = map (fn i =>
                       let xs = map (fn p => if i%p==0 then 1
                                             else 0) first
                       in reduce (+) 0 xs) is
       -- apply the sieve
       let new = filter (fn i => 0 == unsafe fs[i-sqrtn]) is
  in concat first new

-- Return the number of primes less than n
fun main (n:i32) : i32 =
  let ps = primes n in (shape ps)[0]
