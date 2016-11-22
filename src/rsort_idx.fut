-- A least significant digit radix sort to test out `write`.
-- ==
--
-- nobench input {
--   [83, 1, 4, 99, 33, 0, 6, 5]
-- }
-- output {
--   [0, 1, 4, 5, 6, 33, 83, 99],
--   [5, 1, 2, 7, 6,  4,  0,  3]
-- }
--
-- nobench input @ data/radix_sort_100.in
-- output @ data/radix_sort_100.out

fun eq_vec (v1: [n]i32) (v2: [n]i32) : bool =
  reduce (&&) true (zipWith (==) v1 v2)

fun main() : []bool =
  let xs = map (fn i => u32(i)) ([83,1,4,99,33,0,6,5])
  in [eq_vec (grade_up xs) ([5,1,2,7,6,4,0,3]),
      eq_vec (grade_down xs) ([3,0,4,6,7,2,1,5])]

-- Radix sort - ascending
fun rsort_asc(xs: [n]u32) : ([n]u32,[n]i32) =
  let is = iota n
  loop (p : ([n]u32,[n]i32) = (xs,is)) = for i < 32 do
    rs_step_asc(p,i)
  in p

-- Store elements for which bitn is not set first
fun rs_step_asc((xs:[n]u32,is:[n]i32),bitn:i32) : ([n]u32,[n]i32) =
  let bits1 = map (fn x => i32((x >> u32(bitn)) & 1u32)) xs
  let bits0 = map (1-) bits1
  let idxs0 = zipWith (*) bits0 (scan (+) 0 bits0)
  let idxs1 = scan (+) 0 bits1
  let offs  = reduce (+) 0 bits0    -- store idxs1 last
  let idxs1 = zipWith (*) bits1 (map (+offs) idxs1)
  let idxs  = map (-1) (zipWith (+) idxs0 idxs1)
  in (write idxs xs (copy xs),
      write idxs is (copy is))

-- Radix sort - descending
fun rsort_desc(xs: [n]u32) : ([n]u32,[n]i32) =
  loop (p : ([n]u32,[n]i32) = (xs,iota n)) = for i < 32 do
    rs_step_desc(p,i)
  in p

-- Store elements for which bitn is set first
fun rs_step_desc((xs:[n]u32,is:[n]i32),bitn:i32) : ([n]u32,[n]i32) =
  let bits1 = map (fn x => i32((x >> u32(bitn)) & 1u32)) xs
  let bits0 = map (1-) bits1
  let idxs1 = zipWith (*) bits1 (scan (+) 0 bits1)
  let idxs0 = scan (+) 0 bits0
  let offs  = reduce (+) 0 bits1    -- store idxs0 last
  let idxs0 = zipWith (*) bits0 (map (+offs) idxs0)
  let idxs  = map (-1) (zipWith (+) idxs1 idxs0)
  in (write idxs xs (copy xs),
      write idxs is (copy is))

fun grade_up (xs: [n]u32) : [n]i32 =
  let (_,is) = rsort_asc xs in is

fun grade_down (xs: [n]u32) : [n]i32 =
  let (_,is) = rsort_desc xs in is
