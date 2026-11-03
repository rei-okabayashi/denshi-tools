"""側面パネル用「波紋」模様の生成スクリプト

大小の同心円（波紋）を散らし、そのすき間を、円をよけて流れる波線で埋める。
出力: ../ripple_pattern.scad（module ripple_pattern2d() を定義。ag03_stand.scad から use する）

  python3 gen_ripple.py [--seed N]

必要: numpy, shapely, contourpy
寸法は ag03_stand.scad の既定値（tilt=40, H0=55, S=150 ...）に合わせてある。
"""
import argparse, math, random, os
import numpy as np
import contourpy
from shapely.geometry import Polygon, Point, LineString, MultiPolygon
from shapely.ops import unary_union

# ---- ag03_stand.scad と同じ寸法 ----
tilt, H0, S = 40, 55, 150
t_top, lip_t, lip_h, guide_h = 10, 5, 17.0, 17
pnl_gap, pnl_border = 0.2, 7
c, s_ = math.cos(math.radians(tilt)), math.sin(math.radians(tilt))
def P(s, h): return (s*c - h*s_, H0 + s*s_ + h*c)
xr, xL = P(S, -t_top)[0], P(-lip_t, lip_h)[0]
sil = Polygon([(xL, 0), (xr, 0), P(S, -t_top), P(S, 0), P(0, 0), P(0, lip_h), P(-lip_t, lip_h)])
guide = Polygon([P(-lip_t, -t_top), P(S, -t_top), P(S, guide_h), P(-lip_t, guide_h)])
area = unary_union([sil, guide]).buffer(-(pnl_gap + pnl_border), join_style=2)

# ---- 模様のパラメータ ----
W_LINE = 1.3      # 溝の幅 [mm]
PITCH = 3.0       # 線の間隔 [mm]
GAP = 2.2         # 円と円・円と波線のすき間 [mm]

def place_circles(seed):
    rnd = random.Random(seed)
    radii = [27, 23, 20, 17, 15, 14, 12, 11, 10, 9, 8, 8, 7, 7, 6, 6]
    minx, miny, maxx, maxy = area.bounds
    circles = []
    for R in radii:
        for _ in range(4000):
            x, y = rnd.uniform(minx - R*0.4, maxx + R*0.4), rnd.uniform(miny - R*0.4, maxy + R*0.4)
            if not area.contains(Point(x, y)):          # 中心は模様の範囲内（円は縁で切れてよい）
                continue
            if all(math.hypot(x - a, y - b) >= R + r + GAP + PITCH for a, b, r in circles):
                circles.append((x, y, R)); break
    return circles

def rings(circles):
    shapes = []
    for x, y, R in circles:
        r = R
        while r > 2.2:
            shapes.append(Point(x, y).buffer(r + W_LINE/2, 64).difference(Point(x, y).buffer(r - W_LINE/2, 64)))
            r -= PITCH
        shapes.append(Point(x, y).buffer(max(1.0, r*0.6), 32))   # 中心の点
    return unary_union(shapes)

def flow_lines(circles, seed):
    rnd = random.Random(seed + 1)
    minx, miny, maxx, maxy = area.bounds
    xs = np.arange(minx - 5, maxx + 5, 0.25); ys = np.arange(miny - 5, maxy + 5, 0.25)
    X, Y = np.meshgrid(xs, ys)
    # 流れ関数：ゆるい波＋円の位置に「湧き出し」を置いて線が円をよけて曲がる
    psi = Y.copy()
    psi += 2.2*np.sin(2*np.pi*X/58 + 0.7) + 1.4*np.sin(2*np.pi*(X + 0.6*Y)/31 + 2.1)
    for x, y, R in circles:
        Re = R + GAP
        r2 = (X - x)**2 + (Y - y)**2
        psi -= 0.5*Re*Re*(Y - y)/np.maximum(r2, Re*Re*0.25)
    gen = contourpy.contour_generator(xs, ys, psi)
    lines = []
    for lv in np.arange(psi.min(), psi.max(), PITCH):
        for seg in gen.lines(lv):
            if len(seg) >= 2:
                lines.append(LineString(seg).simplify(0.05))
    band = unary_union([ln.buffer(W_LINE/2, 8) for ln in lines])
    holes = unary_union([Point(x, y).buffer(R + GAP + W_LINE/2, 64) for x, y, R in circles])
    return band.difference(holes)

def to_scad(geom, path):
    polys = list(geom.geoms) if isinstance(geom, MultiPolygon) else [geom]
    with open(path, "w") as f:
        f.write("// 自動生成: tools/gen_ripple.py（手で編集しない）\nmodule ripple_pattern2d() {\n")
        for pg in polys:
            if pg.is_empty: continue
            rings_ = [pg.exterior] + list(pg.interiors)
            pts, paths, n = [], [], 0
            for rg in rings_:
                cs = list(rg.coords)[:-1]
                pts += cs; paths.append(list(range(n, n + len(cs)))); n += len(cs)
            f.write("  polygon(points=[%s], paths=%s);\n" % (",".join("[%.2f,%.2f]" % p for p in pts), paths))
        f.write("}\n")
    return len(polys)

if __name__ == "__main__":
    ap = argparse.ArgumentParser(); ap.add_argument("--seed", type=int, default=7); a = ap.parse_args()
    circles = place_circles(a.seed)
    pattern = unary_union([rings(circles), flow_lines(circles, a.seed)]).intersection(area.buffer(1)).simplify(0.03)
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ripple_pattern.scad")
    n = to_scad(pattern, out)
    print("circles:", len(circles), "polygons:", n, "->", os.path.normpath(out))
