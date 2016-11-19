fun main (n:int) : [n][n]i32 = multable n

fun multable (n : int) : [n][n]i32 =
  map (fn i =>
    map (fn j => i * j) (iota n))
      (iota n)
