# 印刷済みの部品の台帳

印刷した部品と、その版・データの場所を記録する。刷り直す部品は、ここにある版と組めることを `tools/compat_check.py` で確かめてから印刷する。

| 部品 | 印刷した版 | データ（コミット・ファイル） | 今後 |
|---|---|---|---|
| AG03 台 左（パーツA） | 初版 | `b4d3d18` `ag03_stand_half_a.stl` | 刷り直さない（これを基準にする） |
| AG03 台 右（パーツB） | 初版 | `b4d3d18` `ag03_stand_half_b.stl` | 刷り直す予定 → 版2 |
| 引き出し | 初版 | `9fa7f93` `ag03_stand_drawer.stl` | — |
| 増設台 P1・P2・P3 | 初版 | `9fa7f93` `ag03_stand_ext_p1〜p3.stl` | 刷り直さない |
| 増設台 P4（M5Stack） | 初版 | `9fa7f93` `ag03_stand_ext_p4.stl` | 刷り直す予定 → 版2（上側に隠し収納。フタ `ag03_stand_ext_lid.stl` を新しく印刷） |
| 連結キー・ケーブルカバー | 初版 | `9fa7f93` `ag03_stand_ext_keys.stl` `ag03_stand_ext_cover.stl` | — |
| 波紋パネル 左右 | 初版 | `9fa7f93` `ag03_stand_panel_a.stl` `ag03_stand_panel_b.stl` | — |

- 部品に版の刻印は入れない（印刷の乱れの原因になるため）。刷り直した部品は、古い部品と分けて保管する
- AG03 台の初版パーツA の床には、旧・抜け止めの小さな山（高さ約 0.9mm）がある。今の引き出しには溝がないので削って平らにしておく

## 刷り直し・新しいモジュールを印刷するときの手順

1. `ag03_stand.scad` を直す
2. `python3 tools/compat_check.py` で、印刷済みの部品と重ならない（＝そのまま組める）ことを確かめる
3. STL を書き出して印刷する
4. この表に行を足し（版・コミット）、`tools/compat_check.py` の `PRINTED` にも追加する
