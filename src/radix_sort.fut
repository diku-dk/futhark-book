-- A least significant digit radix sort to test out `write`.
-- ==
--
-- input {
--
-- }
-- output {
--   [0u32, 1u32, 4u32, 5u32, 6u32, 33u32, 83u32, 99u32]
-- }
--
--
--



-- A least significant digit radix sort to test out `write`.
def radix_sort_step [n] (xs: [n]u32, digit_n: i32): [n]u32 =
  let bits       = map (\(x: u32): i32 ->
                          (i32.u32 x >> digit_n)
                          & 1) xs
  let bits_inv   = map (\(b: i32): i32 -> 1 - b) bits
  let ps0        = scan (+) 0 (bits_inv)
  let ps0_clean  = map2 (*) bits_inv ps0
  let ps1        = scan (+) 0 bits
  let ps0_offset = reduce (+) 0 (bits_inv)
  let ps1_clean  = map (+ps0_offset) ps1
  let ps1_clean' = map2 (*) bits ps1_clean
  let ps         = map2 (+) ps0_clean ps1_clean'
  let ps_actual  = map (\(p: i32): i32 -> p - 1) ps
  in scatter (copy xs) ps_actual xs

def radix_sort [n] (xs: [n]u32): [n]u32 =
  loop (xs) for i < 32 do
    radix_sort_step(xs, i)

def main: []u32 =
  let arg = map u32.i32 ([83, 1, 4, 99, 33, 0, 6, 5])
  in radix_sort(arg)
