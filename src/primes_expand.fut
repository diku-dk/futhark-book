-- ==
-- input { 100i64 } output { 25i64 }

import "segmented"

-- Flattened version of Erastothenes' sieve using expansion
def primes (n:i64) =
  let (res, _) =
    loop (acc:[]i64,c) = ([],2) while c < n+1 do
    let c2 = if c < i64.f32(f32.sqrt(f32.i64(n+1))) then c*c
             else n+1
    let sz (p:i64) = (c2 - p) / p
    let get p i = (2+i)*p
    let m = c2 - c
    let sieves = map (\p -> p-c) (expand sz get acc)
    let vs = replicate m 1
    let vs = scatter vs sieves (map (const 0) sieves)
    let new = filter (>0) <| map2 (*) vs ((c..<c2) :> [m]i64)
    in (acc ++ new, c2)
  in res

-- Return the number of primes less than n
def main (n:i64) : i64 = length (primes n)
