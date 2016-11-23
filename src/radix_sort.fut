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

fun main(): []u32 =
  let arg = map u32 ([83, 1, 4, 99, 33, 0, 6, 5])
  in radix_sort(arg)

-- A least significant digit radix sort to test out `write`.
fun radix_sort(xs: [n]u32): [n]u32 =
  loop (xs) = for i < 32 do
    radix_sort_step(xs, i)
  in xs

fun radix_sort_step(xs: [n]u32, digit_n: i32): [n]u32 =
  let bits       = map (fn (x: u32): i32 =>
                          i32((x >> u32(digit_n))
                              & 1u32)) xs
  let bits_inv   = map (fn (b: i32): i32 => 1 - b) bits
  let ps0        = scan (+) 0 (bits_inv)
  let ps0_clean  = map (*) bits_inv ps0
  let ps1        = scan (+) 0 bits
  let ps0_offset = reduce (+) 0 (bits_inv)
  let ps1_clean  = map (+ps0_offset) ps1
  let ps1_clean' = map (*) bits ps1_clean
  let ps         = map (+) ps0_clean ps1_clean'
  let ps_actual  = map (fn (p: i32): i32  => p - 1) ps
  in write ps_actual xs (copy xs)
