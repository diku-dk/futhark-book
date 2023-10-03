-- Finding points on a line
type point = (i64,i64)
type line = (point,point)
type points [n] = [n]point

def compare (v1:i64) (v2:i64) : i64 =
  if v2 > v1 then 1 else if v1 > v2 then -1 else 0

def slope ((x1,y1):point) ((x2,y2):point) : f32 =
  if x2==x1 then if y2>y1 then 1f32 else -1f32
                 else f32.i64(y2-y1) / f32.abs(f32.i64(x2-x1))

def linepoints ((x1,y1):point, (x2,y2):point) : points [] =
  let len = 1 + i64.max (i64.abs(x2-x1)) (i64.abs(y2-y1))
  let xmax = i64.abs(x2-x1) > i64.abs(y2-y1)
  let (dir,sl) =
    if xmax then (compare x1 x2, slope (x1,y1) (x2,y2))
    else (compare y1 y2, slope (y1,x1) (y2,x2))
  in map (\i -> if xmax
                then (x1+i*dir,
                      y1+i64.f32(f32.round(sl*f32.i64(i))))
                else (x1+i64.f32(f32.round(sl*f32.i64(i))),
                      y1+i*dir)) (iota len)

-- Write to grid
def update [h] [w] [n] (grid: [h][w]i64)(xs:[n]i64)(ys:[n]i64): [h][w]i64 =
  let is = map2 (\x y -> w*y+x) xs ys
  let flatgrid = flatten grid
  let ones = map (\ _ -> 1) is
  in unflatten (scatter (copy flatgrid) is ones)

-- Sequential algorithm for drawing multiple lines
def drawlines [h] [w] [n] (grid: *[h][w]i64) (lines:[n]line) : [h][w]i64 =
  loop (grid) for i < n do -- find points for line i
    let (xs,ys) = unzip (linepoints (lines[i]))
    in update grid xs ys


-- Draw lines on a 70 by 30 grid
def main : [][2]i64 =
  let height:i64 = 30
  let width:i64 = 70
  let grid : *[][]i64 = replicate height (replicate width 0)
  let lines = [((58,20),(2,3)),((27,3),(2,28)),((5,20),(20,20)),
               ((4,10),(6,25)),((26,25),(26,2)),((58,20),(52,3))]
  let board = drawlines grid lines
  let board2 = map2 (\i row ->
                     map2 (\j b -> (i,j,b)) (iota width) row) (iota height) board
  let points = map (\ (i,j,_) -> [j,i]) (filter (\(_,_,b) -> b == 1) (flatten board2))
  in points
