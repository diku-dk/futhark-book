-- ==
-- input {} output { true }

-- Find the smallest power of two greater than n
def nextpow2 (n:i32) : i32 =
  loop a=2 while a < n do 2*a

-- Pad a vector to make its size a power of two
def padpow2 [n] (ne: i32) (v:[n]i32) : []i32 =
  concat v (replicate (nextpow2 n - n) ne)

-- Reduce by contraction
def red (xs : []i32) : i32 =
  let xs = loop xs=padpow2 0 xs while length xs > 1 do
    let n = length xs / 2
    in map2 (+) (take n xs) (take n (drop n xs))
  in xs[0]

def main : bool =
  let vals = [58,20,3,3,2,28,5,20,10,25,26,2,23,56,895,23,43]  -- 18 values
  let res = red vals
  let real = reduce (+) 0 vals
  in res == real
