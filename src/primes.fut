-- ==
-- input { 100 } output { 25 }

-- Find the first n primes
-- let primes (n:i32) : []i32 =
--   if n == 2 then empty(i32)
--   else let sqrtn = i32(f32.sqrt(f32(n)))+1
--        let first = primes sqrtn
--        let is = map (+sqrtn) (iota(n-sqrtn))
--        let fs = map (\i ->
--                      let xs = map (\p -> if i%p==0 then 1
--                                          else 0) first
--                      in reduce (+) 0 xs) is
--        -- apply the sieve
--        let new = filter (\i -> 0 == unsafe fs[i-sqrtn]) is
--   in concat first new

-- Find the first n primes
def primes (n:i32) : []i32 =
  let (acc, _) = loop (acc,c) = ([],2) while c < n+1 do
	let c2 = i32.min (c * c) (n+1)
	let is = map (+c) (map i32.i64 (iota (i64.i32 (c2-c))))
	let fs = map (\i ->
		      let xs = map (\p -> if i%p==0 then 1
					  else 0) acc
		      in reduce (+) 0 xs) is
	-- apply the sieve
	let new = filter (\i -> 0 == fs[i-c]) is
	in (concat acc new, c2)
  in acc

-- Return the number of primes less than n
def main (n:i32) =
  let ps = primes n in length ps
