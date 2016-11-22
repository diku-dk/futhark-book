-- A least significant digit radix sort to test out `write`.
-- ==
--
-- input {
--   [83, 1, 4, 99, 33, 0, 6, 5]
-- }
-- output {
--   [0, 1, 4, 5, 6, 33, 83, 99]
-- }
--
-- input @ data/radix_sort_100.in
-- output @ data/radix_sort_100.out

fun main(arg:[]u32): []u32 = rsort arg
--  let arg = map u32 ([83, 1, 4, 99, 33, 0, 6, 5])
--  in rsort arg

-- Radix sort algorithm, ascending
fun rsort(xs: [n]u32): [n]u32 =
  loop (xs) = for i < 32 do rsort_step(xs,i)
  in xs

-- The rsort_step contraction function takes care of moving
-- all elements with bit_n set to the end of the array (and
-- otherwise preserve the order of elements)
fun rsort_step(xs: [n]u32, bit_n: i32): [n]u32 =
  let bits1 = map (fn x => i32((x >> u32(bit_n)) & 1u32)) xs
  let bits0 = map (fn b => 1 - b) bits1
  let idxs0 = zipWith (*) bits0 (scan (+) 0 bits0)
  let idxs1 = scan (+) 0 bits1
  let offs  = reduce (+) 0 bits0
  let idxs1 = zipWith (*) bits1 (map (+offs) idxs1)
  let idxs  = zipWith (+) idxs0 idxs1
  let idxs  = map (fn p => p - 1) idxs
  in write idxs xs (copy xs)
