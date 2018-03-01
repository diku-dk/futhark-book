Ideas for exercises.

Define the following functions:

-- Summation.
val sum [n]: (xs: [n]i32) -> i32

-- Taking product.
val product [n]: (xs: [n]i32) -> i32

-- Computing average - remember to not use i32 for intermediate
-- calculations!
val average [n]: (xs: [n]i32) -> i32

-- Dot product.
val dotprod [n]: (xs: [n]i32) -> (ys: [n]i32) -> i32

-- Multiply matrix with row vector.
val matvecmul_row [n][m]: (xss: [n][m]i32) -> (ys: [m]i32) -> [n]t

-- Multiply matrix with column vector.
let matvecmul_col [n][m]: (xss: [n][m]i32) -> (ys: [n]i32) -> [n][n]t

-- Multiply two matices.  Hint: You will need to use the 'transpose'
-- function.
let matmul [n][p][m]: (xss: [n][p]i32) -> (yss: [p][m]i32) -> [n][m]i32

Define some of the array utility functions:

https://futhark-lang.org/docs/futlib/array.html
