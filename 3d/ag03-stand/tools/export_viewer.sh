#!/usr/bin/env bash
# ビューア（viewer/index.html）用の STL を書き出す。
#   組み立て位置の部品 → viewer/stl/a_*.stl、印刷用 STL → viewer/stl/p_*.stl（どちらもバイナリ形式）
# 使い方: 3d/ag03-stand で  bash tools/export_viewer.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p viewer/stl
for p in ag_a ag_b ag_drawer panel_l panel_r ext_p1 ext_p2 ext_p3 ext_p4 ext_cover ext_keys dev_ag03 dev_kindle dev_m5; do
  openscad -q -D "part=\"va_$p\"" -o "viewer/stl/a_$p.stl" ag03_stand.scad
done
for f in ag03_stand_*.stl; do cp "$f" "viewer/stl/p_${f#ag03_stand_}"; done
python3 tools/stl_to_binary.py viewer/stl/*.stl
