import "lib/github.com/diku-dk/sobol/sobol-dir-50"
import "lib/github.com/diku-dk/sobol/sobol"

module sobol = Sobol sobol_dir { def D: i32 = 2 }

def sqr (x:f64) = x * x

def in_circle (p:[sobol.D]f64) : bool =
  sqr p[0] + sqr p[1] < 1.0f64

def pi_arr [n] (arr: [n][sobol.D]f64) : f64 =
  let bs = map (i32.bool <-< in_circle) arr
  let sum = reduce (+) 0 bs
  in 4f64 * r64 sum / f64.i32 n

def main (n:i32) : f64 =
  sobol.sobol n |> pi_arr

entry pi_sobol (n:i32) : f64 =
  sobol.sobol n |> pi_arr


entry pi_uniform (n:i32) : f64 =
  let n = f32.i32 n |> f32.sqrt |> i32.f32
  let d = f64.(1f64 / i32 n)
  let points = map (\ x -> f64.(d*i32 x + d/2f64)) (iota n)
  let arr = map (\x -> map (\y -> [x,y] :> [sobol.D]f64) points) points
  in flatten arr |> pi_arr

-- let diff (x:f64) : f64 =
--   f64.((x - pi) / pi)

-- entry compare (n:i32) : []f64 =
--  let args = scan (*) 1 (replicate n 2)
--  let pi_sobols = map (diff <-< pi_sobol) args
--  let pi_uniforms = map (diff <-< pi_uniform) args
--  in map2 (/) pi_sobols pi_uniforms
