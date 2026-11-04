"""側面パネル用「波紋」模様の生成スクリプト

参考画像を分析して決めた描画ルール（下の層から順に描き、上の層が下の層を隠す）:
  1. 波線（一番下の層）  … 全面に水平の線を一定間隔で引く。どの線も同じ形のゆるい波（＝間隔は常に一定）。
                           円をよけて曲がることはなく、上に描かれた円に隠されるだけ。
  2. 大きな同心円        … 波線の上に重ねる。円の内側（＋すき間1本分）の下の線は消える。
  3. 中・小の同心円      … 大きな円の「縁」にかぶさる位置に置き、下の円の輪を途中で断ち切る。
  共通: 円の輪も波線も同じ太さ・同じ間隔。円の中心は小さな点。
        上の円の一番外側の輪と下の線の間には、ふつうの線間と同じ幅のすき間を空ける。
        大きな円はパネルの縁で切れてよい。

出力: ../ripple_pattern.scad（module ripple_pattern2d()。ag03_stand.scad から use する）
  python3 gen_ripple.py [--seed N] [--preview out.png]
必要: numpy, shapely（寸法は ag03_stand.scad の既定値に合わせてある）
"""
import argparse, math, random, os
import numpy as np
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
outline = unary_union([sil, guide]).buffer(-pnl_gap, join_style=2)
area = outline.buffer(-pnl_border, join_style=2)

# ---- 線のルール ----
PITCH = 3.0            # 線の間隔（波線も輪も共通）[mm]
W = 1.4                # 線（溝）の太さ [mm]
GAP = PITCH - W        # 線と線のすき間 [mm]
WAVE = [(0.75, 19.0, 0.0), (0.25, 7.3, 1.3)]   # 波線の形（振幅, 波長, 位相）— 全部の線で共通

# 円の大きさ：輪の本数（半径 = 本数 × PITCH）
LARGE = [11, 10, 10, 9, 9]
MEDIUM = [6, 6, 5, 5]
SMALL = [4, 3, 3, 3, 3]

def wave_y(x): return sum(a*math.sin(2*math.pi*x/l + p) for a, l, p in WAVE)

def background():
    minx, miny, maxx, maxy = outline.bounds
    xs = np.arange(minx - 2, maxx + 2, 0.4)
    lines = []
    y0 = miny - 2
    while y0 < maxy + 2:
        lines.append(LineString([(x, y0 + wave_y(x)) for x in xs]).buffer(W/2, 8))
        y0 += PITCH
    return unary_union(lines)

def rings(cx, cy, n):
    shapes = [Point(cx, cy).buffer(W*0.75, 24)]                       # 中心の点
    for k in range(1, n + 1):
        r = k*PITCH
        shapes.append(Point(cx, cy).buffer(r + W/2, 96).difference(Point(cx, cy).buffer(r - W/2, 96)))
    return unary_union(shapes)

def mask(cx, cy, n):                    # この円が下の層を隠す範囲：外側の輪＋すき間 1 本分
    return Point(cx, cy).buffer(n*PITCH + W/2 + GAP, 96)

def place(seed):
    """大→中→小の順に、参考画像の配置ルールで円の位置を決める（ベストキャンディデート法で均等に散らす）"""
    rnd = random.Random(seed)
    minx, miny, maxx, maxy = area.bounds
    placed = []                          # (x, y, n, layer)

    def candidates(k=600, out=0.0):
        for _ in range(k):
            x, y = rnd.uniform(minx - out, maxx + out), rnd.uniform(miny - out, maxy + out)
            if area.buffer(out).contains(Point(x, y)):
                yield x, y

    # 2. 大きな円：互いにあまり重ならず、パネル全体に散らばる。縁から少しはみ出してよい
    for n in LARGE:
        R = n*PITCH; best = None
        for x, y in candidates(out=R*0.35):
            ds = [math.hypot(x - a, y - b) - (R + m*PITCH) for a, b, m, _ in placed]
            if ds and min(ds) < -0.12*R: continue                   # 大どうしの重なりは少しだけ
            score = min(ds) if ds else 0
            score += 0.5*min(0, area.boundary.distance(Point(x, y)) - 0.4*R)   # 縁に寄りすぎない
            if best is None or score > best[0]: best = (score, x, y)
        if best: placed.append((best[1], best[2], n, 1))

    # 3. 中・小の円：大きい円（小は中も）の縁にかぶさる位置。下の円の中心の点は隠さない
    def ride(n, layer, under_layers):
        r = n*PITCH; best = None
        unders = [p for p in placed if p[3] in under_layers]
        for x, y in candidates(k=1500, out=r*0.3):
            on_rim = [abs(math.hypot(x - a, y - b) - m*PITCH) for a, b, m, _ in unders]
            if not on_rim or min(on_rim) > 0.45*r + PITCH: continue      # どこかの円の縁の上にいる
            if any(math.hypot(x - a, y - b) < r + 3*PITCH for a, b, m, _ in placed):   # 下の円の中心を隠さない
                continue
            same = [math.hypot(x - a, y - b) - (r + m*PITCH) for a, b, m, l in placed if l >= layer]
            if same and min(same) < -0.2*r: continue                       # 同じ層どうしは重なりすぎない
            spread = min([math.hypot(x - a, y - b) for a, b, m, l in placed if l >= layer] or [999])
            score = min(spread, 60) - 3*min(on_rim)
            if best is None or score > best[0]: best = (score, x, y)
        if best: placed.append((best[1], best[2], n, layer))

    for n in MEDIUM: ride(n, 2, (1,))
    for n in SMALL:  ride(n, 3, (1, 2))
    return placed

def build(seed):
    placed = place(seed)
    geom = background()
    for x, y, n, layer in sorted(placed, key=lambda p: p[3]):        # 下の層から順に描き、上の円で隠す
        geom = geom.difference(mask(x, y, n)).union(rings(x, y, n))
    return geom.intersection(area.buffer(0.01)).simplify(0.02), placed

def to_scad(geom, path):
    polys = list(geom.geoms) if isinstance(geom, MultiPolygon) else [geom]
    with open(path, "w") as f:
        f.write("// 自動生成: tools/gen_ripple.py（手で編集しない）\nmodule ripple_pattern2d() {\n")
        for pg in polys:
            if pg.is_empty or pg.area < 0.3: continue
            pts, paths, n = [], [], 0
            for rg in [pg.exterior] + list(pg.interiors):
                cs = list(rg.coords)[:-1]
                pts += cs; paths.append(list(range(n, n + len(cs)))); n += len(cs)
            f.write("  polygon(points=[%s], paths=%s);\n" % (",".join("[%.2f,%.2f]" % p for p in pts), paths))
        f.write("}\n")
    return len(polys)

def preview(geom, path, scale=5, face=(60, 58, 54), accent=(214, 178, 96)):
    from PIL import Image, ImageDraw
    minx, miny, maxx, maxy = outline.bounds
    Wd, Hd = int((maxx - minx + 10)*scale), int((maxy - miny + 10)*scale)
    T = lambda p: ((p[0] - minx + 5)*scale, Hd - (p[1] - miny + 5)*scale)
    im = Image.new("RGB", (Wd, Hd), (250, 250, 250)); d = ImageDraw.Draw(im)
    d.polygon([T(p) for p in outline.exterior.coords], fill=accent)     # 表の面（溝でない所）
    mask_im = Image.new("L", (Wd, Hd), 0)
    for pg in (geom.geoms if hasattr(geom, "geoms") else [geom]):
        m = Image.new("L", (Wd, Hd), 0); dm = ImageDraw.Draw(m)
        dm.polygon([T(p) for p in pg.exterior.coords], fill=255)
        for it in pg.interiors: dm.polygon([T(p) for p in it.coords], fill=0)
        mask_im.paste(255, (0, 0), m)
    im.paste(face, (0, 0), mask_im)                                       # 溝（線）
    im.save(path)

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=2)
    ap.add_argument("--preview")
    ap.add_argument("--no-scad", action="store_true")
    a = ap.parse_args()
    geom, placed = build(a.seed)
    print("circles:", [(l, n) for *_, n, l in placed])
    if a.preview: preview(geom, a.preview)
    if not a.no_scad:
        out = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ripple_pattern.scad"))
        print("polygons:", to_scad(geom, out), "->", out)
