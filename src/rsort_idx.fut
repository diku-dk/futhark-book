-- A least significant digit radix sort to test out `write`.
-- ==
--
-- input {
--
-- }
-- output {
--   [true,true]
--
-- }

module Array = import "/futlib/array"

-- Store elements for which bitn is not set first
let rs_step_asc [n] ((xs:[n]u32,is:[n]i32),bitn:i32) : ([n]u32,[n]i32) =
  let bits1 = map (\x -> i32((x >> u32(bitn)) & 1u32)) xs
  let bits0 = map (1-) bits1
  let idxs0 = map (*) bits0 (scan (+) 0 bits0)
  let idxs1 = scan (+) 0 bits1
  let offs  = reduce (+) 0 bits0    -- store idxs1 last
  let idxs1 = map (*) bits1 (map (+offs) idxs1)
  let idxs  = map (-1) (map (+) idxs0 idxs1)
  in (scatter (Array.copy xs) idxs xs,
      scatter (Array.copy is) idxs is)

-- Radix sort - ascending
let rsort_asc [n] (xs: [n]u32) : ([n]u32,[n]i32) =
  let is = iota n
  in loop (p : ([n]u32,[n]i32) = (xs,is)) for i < 32 do
    rs_step_asc(p,i)


-- Store elements for which bitn is set first
let rs_step_desc [n] ((xs:[n]u32,is:[n]i32),bitn:i32) : ([n]u32,[n]i32) =
  let bits1 = map (\x -> i32((x >> u32(bitn)) & 1u32)) xs
  let bits0 = map (1-) bits1
  let idxs1 = map (*) bits1 (scan (+) 0 bits1)
  let idxs0 = scan (+) 0 bits0
  let offs  = reduce (+) 0 bits1    -- store idxs0 last
  let idxs0 = map (*) bits0 (map (+offs) idxs0)
  let idxs  = map (-1) (map (+) idxs1 idxs0)
  in (scatter (Array.copy xs) idxs xs,
      scatter (Array.copy is) idxs is)

-- Radix sort - descending
let rsort_desc [n] (xs: [n]u32) : ([n]u32,[n]i32) =
  loop (p : ([n]u32,[n]i32) = (xs,iota n)) for i < 32 do
    rs_step_desc(p,i)


let grade_up [n] (xs: [n]u32) : [n]i32 =
  let (_,is) = rsort_asc xs in is

let grade_down [n] (xs: [n]u32) : [n]i32 =
  let (_,is) = rsort_desc xs in is

let eq_vec [n] (v1: [n]i32) (v2: [n]i32) : bool =
  reduce (&&) true (map (==) v1 v2)

let main() : []bool =
  let xs = map (\i -> u32(i)) ([83,1,4,99,33,0,6,5])
  in [eq_vec (grade_up xs) ([5,1,2,7,6,4,0,3]),
      eq_vec (grade_down xs) ([3,0,4,6,7,2,1,5])]
