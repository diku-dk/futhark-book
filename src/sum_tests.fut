import "sum"

-- ==
-- entry: test_sum_add_i32
-- input { [1, 2, 3, 4] }
-- output { 10 }

module sum_add_i32 = sum { type t = i32
                           def add = (i32.+)
                           def zero = 0i32
                         }

entry test_sum_add_i32 = sum_add_i32.sum

-- ==
-- entry: test_sum_prod_f32
-- input { [1f32, 2f32, 3f32, 4f32] }
-- output { 24f32 }

module sum_prod_f32 = sum { type t = f32
                            def add = (f32.*)
                            def zero = 1f32
                          }

entry test_sum_prod_f32 = sum_prod_f32.sum
