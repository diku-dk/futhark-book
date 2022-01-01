-- ==
-- input {} output { 1212i32 17i32 }

-- Find the largest integer and its index in an array
def MININT : i32 = -10000000

def mx (m1:i32,i1:i32) (m2:i32,i2:i32) : (i32,i32) =
  if m1 > m2 then (m1,i1) else (m2,i2)

def maxidx [n] (xs: [n]i32) : (i32,i32) =
  reduce mx (MININT,-1) (zip xs (iota n))

def main : (i32,i32) =  -- (1212,17)
  maxidx ([34,23,45,56,34,456,4,34,4,454,23,2,12,123,56,767,23,1212,12,23,232,2,67,4])
