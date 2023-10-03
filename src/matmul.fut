-- Matrix multiplication.
-- ==
-- entry: matmul
-- input { [[1, 2]] [[3], [4]] }
-- output { [[11]] }
-- input { [[1, 2], [3, 4]] [[5, 6], [7, 8]] }
-- output { [[19, 22], [43, 50]] }
--
--
-- input { empty([0][0]i32) empty([0][0]i32) }
-- output { empty([0][0]i32) }
-- compiled input @ big_matrices.in
-- output @ big_matrices.out
-- compiled random input { [100][1000]i32 [1000][100]i32 }
-- auto output

entry matmul [n][m][p] (x: [n][m]i32) (y: [m][p]i32): [n][p]i32 =
  map (\xr -> map (\yc -> reduce (+) 0 (map2 (*) xr yc))
                  (transpose y))
      x
