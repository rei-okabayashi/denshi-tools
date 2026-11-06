"""刷り直す部品・新しいモジュールが、印刷済みの部品とそのまま組めるかを確かめる

印刷済みの部品は git の履歴から取り出す（printed.md の表と同じ版）。
今の ag03_stand.scad から部品を組み立てた位置で書き出し、印刷済みの部品と重なる体積を調べる。
ダボが穴に入らない・形がぶつかる、などがあれば重なりが出る（すき間は fit_tol などの設計値どおり）。

使い方: 3d/ag03-stand で  python3 tools/compat_check.py
必要: git, openscad, python の trimesh と manifold3d（pip install trimesh manifold3d）
"""
import io, math, os, subprocess, sys, tempfile
import trimesh

HERE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
REPO_PATH = "3d/ag03-stand"
ROT_X90 = trimesh.transformations.rotation_matrix(math.pi/2, [1, 0, 0])   # OpenSCAD の rotate([90, 0, 0])

# 印刷済みの部品: 名前 -> (コミット, ファイル, 組み立て位置へ動かす変換)
PRINTED = {
    "AG03 左（パーツA 初版）": ("b4d3d18", "ag03_stand_half_a.stl", ROT_X90),   # 印刷用 STL ＝ 組み立て前の座標
    "増設台 P3（初版）":        ("9fa7f93", "viewer/stl/a_ext_p3.stl", None),   # ビューア用 STL ＝ 組み立てた位置
    "増設台 P4（初版）":        ("9fa7f93", "viewer/stl/a_ext_p4.stl", None),
    "連結キー（初版）":          ("9fa7f93", "viewer/stl/a_ext_keys.stl", None),
    "ケーブルカバー（初版）":    ("9fa7f93", "viewer/stl/a_ext_cover.stl", None),
    "引き出し（初版）":          ("9fa7f93", "viewer/stl/a_ag_drawer.stl", None),
}
# 確かめる部品: 名前 -> (ag03_stand.scad の書き出し [part と -D の組], 組み合わせを確かめる印刷済みの部品)
CHECKS = {
    "AG03 右（パーツB）":    ([{"part": "va_ag_b"}], ["AG03 左（パーツA 初版）", "連結キー（初版）", "引き出し（初版）"]),
    "増設台 P4（M5Stack）":  ([{"part": "va_ext_p4"}], ["増設台 P3（初版）", "ケーブルカバー（初版）"]),
    "拡張モジュール（mod_bays）": ([{"part": "va_mod_p", "mod_piece": k} for k in range(1, 9)], ["増設台 P4（初版）"]),
}

def git_stl(rev, path):
    r = subprocess.run(["git", "show", "%s:%s/%s" % (rev, REPO_PATH, path)], cwd=HERE, capture_output=True)
    if r.returncode:
        raise SystemExit("取り出せません: %s:%s  %s" % (rev, path, r.stderr.decode(errors="replace").strip()))
    return trimesh.load(io.BytesIO(r.stdout), file_type="stl")

def scad_stl(tmp, defs):
    out = os.path.join(tmp, "new.stl")
    if os.path.exists(out): os.remove(out)
    args = ["openscad", "-q", "-o", out]
    for k, v in defs.items():
        args += ["-D", '%s="%s"' % (k, v) if isinstance(v, str) else "%s=%s" % (k, v)]
    r = subprocess.run(args + ["ag03_stand.scad"], cwd=HERE, capture_output=True, text=True)
    if r.returncode or not os.path.exists(out) or os.path.getsize(out) < 200:
        return None                                            # 例: モジュールの部品番号が部品数を超えた
    return trimesh.load(out)

def main():
    tmp = tempfile.mkdtemp(prefix="compat_")
    refs = {}
    for name, (rev, path, tf) in PRINTED.items():
        m = git_stl(rev, path)
        if tf is not None: m.apply_transform(tf)
        refs[name] = m
    bad = 0
    for name, (exports, partners) in CHECKS.items():
        parts = [m for m in (scad_stl(tmp, d) for d in exports) if m is not None]
        if not parts:
            print("書き出せません:", name); bad += 1; continue
        for pn in partners:
            vol = sum(abs(trimesh.boolean.intersection([p, refs[pn]], engine="manifold").volume) for p in parts)
            ok = vol < 0.5
            bad += not ok
            print("%s  %s × %s  重なり %.2f mm3" % ("OK " if ok else "NG ", name, pn, vol))
    print("すべて組めます" if not bad else "組めない組み合わせがあります")
    return 1 if bad else 0

if __name__ == "__main__":
    sys.exit(main())
