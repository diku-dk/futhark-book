default (f32)

-- Our state is a floating-point value to keep track of time.
type state = f32

-- Initially, degree=1.
entry initial_state(): state = 0.0

entry advance (s: state, _setting: int): state = s + 0.01

entry render(width: int, height: int, time: state, degree: int): [width][height]u32 =
  let scale = 30.0
  in map (fn (y: i32): [height]u32  =>
            map (fn (x: i32): u32  =>
                   quasicrystal(scale, degree, time,
                                normalize_index(x, width),
                                normalize_index(y, height)))
                (iota height))
         (iota width)

val pi: f32 = 3.14159265358979323846264338327950288419716939937510

fun odd(n: i32): bool = (n & 1) == 1

fun quasicrystal(scale: f32, degree: i32, time: f32, x: f32, y: f32): u32 =
  let phi = 1.0 + (time ** 1.5) * 0.005
  let (x', y') = point(scale, x, y)
  in intColour(rampColour(waves(degree, phi, x', y')))

fun waves(degree: i32, phi: f32, x: f32, y: f32): f32 =
  let th = pi / phi
  in wrap(waver(th, x, y, degree))

fun waver(th: f32, x: f32, y: f32, n: i32): f32 =
  reduce (+) (0.0) (map (fn i  => wave(f32(i) * th, x, y)) (iota n))

fun wrap(n: f32): f32 =
  let n' = n - f32(i32(n))
  let odd_in_int = i32(n) & 1
  let even_in_int = 1 - odd_in_int
  in f32(odd_in_int) * (1.0 - n') + f32(even_in_int) * n'

fun wave(th: f32, x: f32, y: f32): f32 =
  let cth = cos32(th)
  let sth = sin32(th)
  in (cos32(cth * x + sth * y) + 1.0) / 2.0

fun point(scale: f32, x: f32, y: f32): (f32, f32) =
  (x * scale, y * scale)

fun rampColour(v: f32): (f32, f32, f32) =
  (1.0, 0.4 + (v * 0.6), v) -- rgb

fun intColour((r,g,b): (f32, f32, f32)): u32 =
  u32(intPixel(r)) << 16u32 | u32(intPixel(g)) << 8u32 | u32(intPixel(b))

fun intPixel(t: f32): u8 =
  u8(255.0 * t)

fun normalize_index(i: i32, field_size: i32): f32 =
  f32(i) / f32(field_size)
