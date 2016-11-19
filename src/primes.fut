
-- primes

fun max (x:i32) (y:i32) : i32 = if x > y then x else y

fun primes (n:i32) : []i32 =
  if n <= 3 then [2,3]
  else let sqrtn = i32(sqrt32(f32(n)))
       let first = primes sqrtn
       let is = map (+sqrtn) (iota(n-sqrtn))
       let fs = map (fn i =>
                       let xs = map (fn p => if i%p == 0 then 1 else 0) first
		       in reduce (+) 0 xs) is
       let new = filter (fn i => 0 == unsafe fs[i-sqrtn]) is
  in concat first new

fun main (n:i32) : i32 =
  reduce max 0 (primes n)
