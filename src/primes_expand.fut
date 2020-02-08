-- ==
-- input { 100 } output { 25 }

import "segmented"

-- Flattened version of Erastothenes' sieve using expansion
let primes (n:i32) =
  (.0) <|
  loop (acc:[]i32,c) = ([],2) while c < n+1 do
    let c2 = if c < i32.f32(f32.sqrt(f32.i32(n+1))) then c*c
             else n+1
    let sz (p:i32) = (c2 - p) / p
    let get p i = (2+i)*p
    let m = c2 - c
    let sieves = map (\p -> p-c) (expand sz get acc)
    let vs = replicate m 1
    let vs = scatter vs sieves (map (const 0) sieves)
    let new = filter (>0) <| map2 (*) vs ((c..<c2) :> [m]i32)
    in (acc ++ new, c2)

-- Return the number of primes less than n
let main (n:i32) : i32 = length <| primes n
