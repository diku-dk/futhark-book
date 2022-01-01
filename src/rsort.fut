-- A least significant digit radix sort to test out `scatter`.
-- ==
--
-- input {
--   [83u32, 1u32, 4u32, 99u32, 33u32, 0u32, 6u32, 5u32]
-- }
-- output {
--   [0u32, 1u32, 4u32, 5u32, 6u32, 33u32, 83u32, 99u32]
-- }
--
-- input { [1u32] } output { [1u32] }
-- input { empty([0]u32) } output { empty([0]u32) }
--



-- The rsort_step contraction function takes care of moving
-- all elements with bitn set to the end of the array (and
-- otherwise preserve the order of elements)
def rsort_step [n] (xs: [n]u32, bitn: i32): [n]u32 =
  let bits1 = map (\x -> (i32.u32 (x >> u32.i32 bitn)) & 1) xs
  let bits0 = map (1-) bits1
  let idxs0 = map2 (*) bits0 (scan (+) 0 bits0)
  let idxs1 = scan (+) 0 bits1
  let offs  = reduce (+) 0 bits0
  let idxs1 = map2 (*) bits1 (map (+offs) idxs1)
  let idxs  = map2 (+) idxs0 idxs1
  let idxs  = map (\x->x-1) idxs
  in scatter (copy xs) idxs xs

-- Radix sort algorithm, ascending
def rsort [n] (xs: [n]u32): [n]u32 =
  loop (xs) for i < 32 do rsort_step(xs,i)


--  let arg = map u32 ([83, 1, 4, 99, 33, 0, 6, 5])
--  in rsort arg
def main(arg:[]u32): []u32 = rsort arg
