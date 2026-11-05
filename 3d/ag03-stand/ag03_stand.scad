// ============================================================
//  YAMAHA AG03（初代）用 40° チルトスタンド（AG03MK2 にも切替可）
//  ・ネジ／接着剤 不要（左右2分割を圧入ダボで差し込むだけ）
//  ・サポート不要（どちらのパーツも外側の側板を下にして寝かせて印刷）
//
//  使い方（OpenSCAD）:
//    part = "assembly"  … 組み立てプレビュー（AG03の外形をゴースト表示）
//    part = "half_a"    … 左パーツ（ダボ＝オス）   ← STL書き出し用
//    part = "half_b"    … 右パーツ（ダボ穴＝メス） ← STL書き出し用
//    part = "drawer"    … 引き出し                 ← STL書き出し用
//    part = "fit_test"  … 圧入の効き具合を試す小片（本番前に推奨）
//  コマンドライン例:
//    openscad -D 'part="half_a"' -o ag03_stand_half_a.stl ag03_stand.scad
// ============================================================

part = "assembly";

use <ripple_pattern.scad>   // 側面パネルの「波紋」模様（tools/gen_ripple.py で生成）

/* ---------- 本体寸法（メーカー公称値。手持ちの実機をノギスで測って上書き推奨） ---------- */
model   = "AG03";                            // "AG03"(初代) or "AG03MK2"
dev_w   = model == "AG03" ? 128.8 : 126;     // 幅 [mm]（初代はノギス実測 128.8。公称 129）
dev_d   = model == "AG03" ? 202 : 201;       // 奥行 [mm]
// 側面形状：手前が低く奥が高い坂形（初代はノギス実測）。MK2 は未計測のため公称の箱形
dev_h_front = model == "AG03" ? 28.0 : 63;   // 手前の高さ [mm]
dev_h_rear  = model == "AG03" ? 54.3 : 63;   // 奥の高さ [mm]
//   → 初代の天板は底面に対して atan((54.3-28.0)/202) ≈ 7.4° 手前に傾いている
//     （底面を tilt=40° にすると操作面は約47.4°）

/* ---------- 角度・姿勢 ---------- */
tilt    = 40;    // 本体底面の傾き [°]
H0      = 55;    // 本体手前下端の机からの高さ [mm]
                 //   この下（手前の横桁の下）を引き出しが通る。前面プラグの逃げも兼ねる
S       = 150;   // 傾斜面で支える長さ [mm]（重心≒奥行の中央より十分後ろまで）

/* ---------- 構造 ---------- */
clr     = 0.6;   // 本体側面と側板の片側すき間 [mm]
g       = 4;     // 側板（ガイド壁）の厚み [mm]
guide_h = 17;    // ガイド壁の高さ（本体底面から）[mm]  ※AG03は曲面仕上げで、この高さが一番幅のある部分
frame_w = 14;    // 側面フレーム（＝手前ストッパー）の横幅（側板の内側へ）[mm]
                 //   （手前ストッパー自体は前板 front_wall2d で全幅につながる）
m       = 7;     // フレーム部材の太さ [mm]
t_top   = 10;    // 傾斜面（本体を受ける部材）の厚み [mm]
t_base  = 10;    // 底の部材の厚み [mm]
lip_t   = 5;     // 手前ストッパーの厚み [mm]
lip_h   = 17.0;  // 手前ストッパー（前板）の高さ（本体底面から）[mm]  ※側板と同じ。AG03の一番幅のある高さ

/* ---------- 角の丸み ---------- */
R_out   = 3;     // 外形の角R [mm]（外に向かって凸の角だけ丸める）
R_hole  = 9;     // 肉抜き穴の角R [mm]

/* ---------- 圧入ダボ ---------- */
peg_d   = 6;     // ダボ直径 [mm]（5→6で根元の層間せん断に強く）
peg_len = 6;     // ダボ長さ [mm]
fit_tol = 0.10;  // 穴の半径方向クリアランス [mm]（テスト片で①0.10がぴったり、②0.15・③0.20は緩かった）

$fn = 48;

// ============================================================
//  2D 側面プロファイル（x: 手前→奥, y: 上）
//  P(s,h): 傾斜面に沿って s、傾斜面の法線方向に h だけ進んだ点
//          s=0,h=0 が本体の手前下端
// ============================================================
function P(s, h) = [s*cos(tilt) - h*sin(tilt), H0 + s*sin(tilt) + h*cos(tilt)];

module band(s0, s1, h0, h1) polygon([P(s0,h0), P(s1,h0), P(s1,h1), P(s0,h1)]);
module below_top() band(-500, 500, -500, -t_top);           // 傾斜部材より下（穴を開けてよい範囲）

xf = P(-lip_t, -m)[0];      // 前側の横桁の前面 x
xr = P(S, -t_top)[0];       // 後脚の背面 x（机に触れる後端）
xL = P(-lip_t, lip_h)[0];   // ストッパー先端 x（＝前脚のつま先）
Zc = g + dev_w/2 + clr;     // 左右パーツの合わせ面（中心）

// 外形（反時計回り）: 前脚つま先 → 平らな底 → 垂直な背面 → 傾斜面(本体が乗る) → ストッパー → 垂直な前面
function silhouette() = [
    [xL, 0], [xr, 0], P(S, -t_top), P(S, 0), P(0, 0), P(0, lip_h), P(-lip_t, lip_h)
];

module sil_sharp() polygon(silhouette());
module sil2d() offset(r = R_out) offset(delta = -R_out) sil_sharp();   // 外側の角をすべて丸める

// 肉抜き：外形を m だけ内側へ。傾斜部材・底部材は厚く残し、斜材で2室に仕切って大きなRで丸める
module holes2d()
    offset(r = R_hole) offset(delta = -R_hole)
    difference() {
        intersection() {
            offset(delta = -m) sil_sharp();
            below_top();
            translate([-500, t_base]) square(1000);
        }
        hull() {                                    // 斜材（後ろ下 → 傾斜の中ほど）
            translate([xr - 18, t_base]) circle(d = 8);
            translate(P(S*0.45, -t_top)) circle(d = 8);
        }
        translate([xL - 1, ceil_top - m]) square([xr - xL + 2, m]);   // 天井の高さの横材
    }

// 引き出しの天井板：引き出しを閉めたとき上から中が見えないようにふさぐ（前脚の前面〜背面まで全長）
t_ceil   = 3;                               // 天井板の厚み [mm]
ceil_top = P(-lip_t, -t_top)[1];            // 天井板の上面：手前の横桁の一番低い所にそろえる
ceil_bot = ceil_top - t_ceil;
// 前端は前面の斜面（front_slope2d）が受け持つので、斜面の内側から始めて段差を出さない
module ceiling2d() intersection() { sil2d(); translate([P(10, -t_top)[0] - 2, ceil_bot]) square([xr, t_ceil]); }

module frame2d() difference() { sil2d(); holes2d(); }

// 側板（Z=0〜g）：傾斜面に沿った一定高さの帯。角だけ丸める
module guide2d() offset(r = R_out) offset(delta = -R_out) band(-lip_t, S, -t_top, guide_h);

// 中央へ渡す横桁（左右パーツの合わせ面まで伸びる）— 断面はフレームの形をそのまま引き継ぐ
module front_rung2d() rnd() intersection() { frame2d(); band(-lip_t, 18, -t_top, 0); }
module mid_rung2d()   rnd() intersection() { frame2d(); band(S*0.45 - 8, S*0.45 + 8, -t_top, 0); }
module rear_rung2d()  rnd() intersection() { frame2d(); band(S - 30, S + 1, -t_top, 0); }
module rear_base2d()  rnd() intersection() { frame2d(); translate([xr - 18, -1]) square([19, t_base + 1]); }
module bars2d() { front_rung2d(); mid_rung2d(); rear_rung2d(); rear_base2d(); }   // 手前下は引き出しの通り道なので横桁なし
module plates2d() { bars2d(); ceiling2d(); front_slope2d(); front_wall2d(); floor2d(); back2d(); }

// 前板：左右の手前ストッパーを全幅でつなぐ（AG03 初代は前面のこの範囲に端子がない）
// 天井板の上から前脚の前面と面一に立ち上げ、ストッパーの上端まで。AG03 の前面を高さ lip_h で受ける
module front_wall2d() intersection() {
    sil2d();
    band(-500, 0, -500, 500);                                  // AG03 の前面より手前だけ
    translate([xL - 1, ceil_bot]) square([200, 200]);          // 天井板より上だけ（下は引き出しの口）
}

// 床板と背板：机に接する底面と、AG03 の後ろに隠れる背面をふさぐ（横の肉抜き穴はそのまま）
t_floor = 3;     // 床板の厚み [mm]（引き出しはこの上を滑る）
t_back  = 3;     // 背板の厚み [mm]
module floor2d() intersection() { sil2d(); translate([xL - 1, -1]) square([xr - xL + 2, t_floor + 1]); }
module back2d()  intersection() { sil2d(); translate([xr - t_back, -1]) square([t_back + 1, 500]); }

// 床板の継ぎ目は相欠き（重ね継ぎ）：A の床板の下半分が舌として B 側へ lap_len 伸び、B の床板の下半分に入る
// → 左右の床板が上下にずれず、前の下側も開きにくい。印刷向きでは薄い壁が上に伸びるだけなのでサポート不要
lap_len = 8;                                    // 重ねる長さ [mm]
lap_t   = t_floor/2;                            // 舌の厚み [mm]
lap_x0  = xL + 3;                               // 前後の範囲（後ろ下の横桁は避ける）
lap_x1  = xr - 18 - 3;
module lap_tongue2d() translate([lap_x0, 0]) square([lap_x1 - lap_x0, lap_t]);
// 抜け止めの山：前（差し込む側）はゆるい斜面、奥（引き出す側）は急な斜面
module detent_bump2d() let(x0 = xL + det_bx) polygon([
    [x0 - 3.5, t_floor - 0.01], [x0, t_floor + det_bh], [x0 + 0.6, t_floor + det_bh], [x0 + 1.2, t_floor - 0.01]]);
module lap_recess2d() translate([lap_x0 - 0.3, -1]) square([lap_x1 - lap_x0 + 0.6, lap_t + 0.1 + 1]);

// 前面の斜面：天井板の前端から AG03 の手前下端まで一直線につなぎ、前から見て段差・すき間のない面にする
// （本体の底面の延長より下なので、前面端子のプラグには当たらない）
module front_slope2d() offset(r = R_out) offset(delta = -R_out) polygon([
    [xL, ceil_bot], [xL, ceil_top], P(0, 0), P(10, 0), P(10, -t_top), [P(10, -t_top)[0], ceil_bot]
]);
module rnd() offset(r = 2.5) offset(delta = -2.5) children();       // 横桁の角も丸める

// ダボ位置 [x, y, 直径]
pegs = [
    [xL + 4.5, ceil_bot + 5.5, peg_d],     // 前板の下部（前の下側の開き止め）
    [-1.8,     ceil_bot + 5.5, peg_d],     // 〃
    concat(P(5,        -5), [peg_d]),      // 手前の横桁
    concat(P(13,       -5), [peg_d]),
    concat(P(S*0.45,   -5), [peg_d]),      // 中の横桁
    concat(P(S - 25,   -5), [peg_d]),      // 奥の横桁
    concat(P(S - 12,   -5), [peg_d]),
    [xr - 9,  5, peg_d],                   // 後ろ下の横桁
];

// ============================================================
//  3D
// ============================================================
module half(male = true) {
    difference() {
        union() {
            linear_extrude(g + frame_w) frame2d();                     // 側面フレーム（ストッパー・前脚込み）
            linear_extrude(g) guide2d();                               // 側板（横ズレ防止）
            linear_extrude(Zc) plates2d();                             // 横桁＋引き出しの天井板
            if (male) for (p = pegs) translate([p[0], p[1], Zc - 0.01]) peg(p[2]);
            if (male) translate([0, 0, Zc - 0.01]) linear_extrude(lap_len) lap_tongue2d();
            if (male) translate([0, 0, Zc - 8 - det_bw/2]) linear_extrude(det_bw) detent_bump2d();   // 抜け止めの山（A 側の床板）
        }
        if (!male) for (p = pegs)
            translate([p[0], p[1], Zc - peg_len - 0.6]) peg_hole(p[2]);
        if (!male) translate([0, 0, Zc - lap_len - 0.3]) linear_extrude(lap_len + 1) lap_recess2d();
    }
}

module peg(d) {
    c = 0.6;  // 先端の面取り（差し込みやすく）
    cylinder(d = d, h = peg_len - c);
    translate([0, 0, peg_len - c]) cylinder(d1 = d, d2 = d - 2*c, h = c);
}

module peg_hole(d) {
    dh = d + 2*fit_tol;
    cylinder(d = dh, h = peg_len + 0.6 + 0.01);
    translate([0, 0, peg_len + 0.6 - 0.4]) cylinder(d1 = dh, d2 = dh + 1.2, h = 0.42); // 入口の面取り
}

// 組み立て状態（実際に机に置いた向きで表示）
module assembly() rotate([90, 0, 0]) assembly_raw();

// 部品座標系のまま（Z=0 が片側の外面、Z=2*Zc が反対側の外面）
module assembly_raw() {
    color("SteelBlue") half(true);
    color("LightSteelBlue") translate([0, 0, 2*Zc]) mirror([0, 0, 1]) half(false);
    // AG03 ゴースト
    %translate([0, 0, g + clr]) multmatrix([
        [cos(tilt), -sin(tilt), 0, 0],
        [sin(tilt),  cos(tilt), 0, H0],
        [0, 0, 1, 0], [0, 0, 0, 1]])
        linear_extrude(dev_w) polygon([[0, 0], [dev_d, 0], [dev_d, dev_h_rear], [0, dev_h_front]]);
    // 引き出し（drawer_open だけ手前に引き出した状態で表示）
    color("Goldenrod") translate([dr_x0 - drawer_open, dr_y0, dr_z0])
        multmatrix([[1, 0, 0, 0], [0, 0, 1, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) drawer();
}

// ============================================================
//  引き出し（左右フレームの内面にガイドされて床板の上を滑る。レール・ネジ不要）
// ============================================================
drawer_open = 0;    // プレビュー用：引き出した量 [mm]
dr_clr_side = 0.5;  // 左右のすき間 [mm]
dr_clr_top  = 0.8;  // 天井板の下とのすき間 [mm]
dr_wall     = 1.6;  // 壁の厚み [mm]
dr_floor    = 2.4;  // 底の厚み [mm]（抜け止めの溝を入れるので厚め）
dr_r        = 3;    // 外形の角R [mm]
dr_front    = 2.4;  // 前板の厚み [mm]（つまみを支えるので少し厚め）
pull_p      = 8;    // 取っ手（前板上端の全幅のひさし）の出っ張り [mm]
pull_t      = 4;    // 取っ手の先端の厚み [mm]（下面は45°の斜面でサポート不要・指が掛かる）
dr_chamfer  = 0.4;  // 底の外周の面取り [mm]（1層目の広がり＝象の足でこすれないように）
// 抜け止め（外から見えない）：引き出しの底の溝に、台の床板の小さな山が入る。
// 溝の途中にある「歯」が山に当たって止まる。強めに引けば歯が山を乗り越えて外せる（ソフトストップ）
det_v       = Zc - 8 - (g + frame_w + dr_clr_side);   // 溝の位置（引き出しの左端から）：左右の継ぎ目を避けて A 側
det_gw      = 8;    // 溝の幅 [mm]
det_gd      = 1.2;  // 溝の深さ [mm]
det_tooth   = 3;    // 歯の長さ [mm]
det_u       = 97;   // 歯の位置（前面から）[mm]
det_bx      = 12;   // 台の山の位置（前脚の前面から奥へ）[mm]
det_bh      = 0.9;  // 山の高さ [mm]
det_bw      = 5;    // 山の幅 [mm]

dr_x0 = xL;                                       // 前面：閉めたとき前脚の前面と面一
dr_x1 = xr - 18 - 1.5;                            // 背面：後ろの横桁の手前（ここで止まる）
dr_z0 = g + frame_w + dr_clr_side;                // 左右：フレームの内面の間
dr_z1 = 2*Zc - (g + frame_w) - dr_clr_side;
dr_L  = dr_x1 - dr_x0;                            // 奥行（外寸）
dr_W  = dr_z1 - dr_z0;                            // 幅（外寸）
dr_y0 = t_floor;                                  // 底：床板の上に乗る
dr_H  = ceil_bot - dr_clr_top - dr_y0;            // 高さ（外寸）：床板の上〜天井板の下

// 印刷向き（底が下、開口が上）。u: 奥行（0 が前面）、v: 幅、w: 高さ
module drawer() {
    difference() {
        union() {
            chamfer_box(dr_L, dr_W, dr_H, dr_r, dr_chamfer);
            front_pull();
        }
        translate([dr_front, dr_wall, dr_floor])
            rbox(dr_L - dr_front - dr_wall, dr_W - 2*dr_wall, dr_H, max(0.5, dr_r - dr_wall));
        // 抜け止めの溝（奥側は開放、前端は前板の裏で止める。途中に歯を残す）。溝の天井は幅8mmのブリッジなのでサポート不要
        for (seg = [[5, det_u], [det_u + det_tooth, dr_L + 1]])   // 前端は閉じて前面に切り欠きを見せない
            translate([seg[0], det_v - det_gw/2, -1]) cube([seg[1] - seg[0], det_gw, det_gd + 1]);
    }
}

// 取っ手：前板の上端を全幅で手前へ張り出した「ひさし」。上面は引き出しの縁と面一、下面は45°。
// 平面形は引き出しの外形をそのまま前へ延ばした形（左右は側面と面一、前の角だけ丸める）
module front_pull() intersection() {
    translate([0, dr_W + 1, 0]) rotate([90, 0, 0]) linear_extrude(dr_W + 2)
        offset(r = 1.5) offset(delta = -1.5)
        polygon([[dr_front, dr_H - pull_t - pull_p - 2], [0, dr_H - pull_t - pull_p], [-pull_p, dr_H - pull_t],
                 [-pull_p, dr_H], [dr_front, dr_H]]);
    linear_extrude(dr_H) intersection() {
        offset(r = dr_r) offset(delta = -dr_r) translate([-pull_p, 0]) square([dr_L + pull_p, dr_W]);
        translate([-pull_p - 1, -1]) square([pull_p + 1 + dr_front, dr_W + 2]);
    }
}
// 底の外周だけ45°で面取りした角丸の箱
module chamfer_box(l, w, h, r, c) hull() {
    translate([0, 0, c]) rbox(l, w, h - c, r);
    linear_extrude(c + 0.01) offset(delta = -c) offset(r = r) offset(delta = -r) square([l, w]);
}

module rbox(l, w, h, r) linear_extrude(h) offset(r = r) offset(delta = -r) square([l, w]);

// ============================================================
//  側面の化粧パネル（台の外側の面＝印刷時のプレート面をおおう）
//  ・裏の「リム」が台の肉抜き穴（下段の長穴・上段の三角2つ）に差し込まれて摩擦で留まる。ネジ・接着剤なし、台は刷り直し不要
//  ・黒 1 色で印刷する前提。表面をプレートに付けて印刷し、彫った溝の陰影とツヤの差で模様を見せる
//    （color_layer の高さでフィラメントを替えれば 2 色にもできる）
// ============================================================
face_col = "#2A2A2A"; accent_col = "#2A2A2A";   // プレビューの色（表の色／模様の色）。黒 1 色
panel_style = "ripple";  // "ripple"（波紋）/ "eq" / "wave" / "grille" / "lines" / "relic" / "rune" / "stone" / "plain"
pnl_t       = 2.4;   // パネルの厚み [mm]
pnl_gap     = 0.2;   // 台の外形より内側に下げる量 [mm]（縁がはみ出さないように）
pnl_chamfer = 0.6;   // 表側の縁の面取り [mm]
pnl_border  = 7;     // 模様を入れない縁の幅 [mm]
deboss      = 1.0;   // 模様の彫りの深さ [mm]（1 色なので陰影が出るよう深め）
color_layer = 0.4;   // （2 色にする場合）ここでフィラメントを替える [mm]
plug_len    = 6;     // 差し込みリムの長さ [mm]
plug_wall   = 1.6;   // リムの壁厚 [mm]
plug_tol    = 0.1;   // リムと穴のすき間 [mm]（ダボのテスト結果と同じ値）

module side_outline2d() offset(delta = -pnl_gap) union() { sil2d(); guide2d(); }
module pattern_area2d() offset(delta = -pnl_border) side_outline2d();
function y_top(x) = H0 + x*tan(tilt) + guide_h/cos(tilt);      // 外形の上辺（傾斜面＋側板）

// --- 模様 ---
eq_f = [0.34, 0.52, 0.66, 0.8, 0.92, 0.7, 0.86, 0.97, 0.78, 0.62, 0.9, 0.74, 0.56, 0.82, 0.6, 0.46, 0.64, 0.42, 0.5, 0.36];
module eq2d() {                       // イコライザー：底から立ち上がる角丸のバー。高さは台の傾斜に沿って伸びる
    pitch = 6.4; w = 3.6; yb = pnl_border + 4;
    n = floor((xr - 10 - (xL + 12))/pitch) + 1;
    for (i = [0:n-1]) let(x = xL + 12 + i*pitch, avail = y_top(x) - pnl_border - 5 - yb, h = max(w, avail*eq_f[i % len(eq_f)]))
        hull() { translate([x, yb + w/2]) circle(d = w, $fn = 24); translate([x, yb + h - w/2]) circle(d = w, $fn = 24); }
}
wv_g = [0.42, 0.7, 0.55, 0.92, 0.66, 1.0, 0.78, 0.5, 0.88, 0.62, 0.97, 0.72, 0.84, 0.46, 0.76, 0.58, 0.9, 0.68, 0.52, 0.8, 0.6, 0.38, 0.7, 0.48, 0.64, 0.44, 0.56, 0.34];
module wave2d() {                     // 波形：傾斜と平行な中心線から上下に伸びる録音波形
    s0 = 0; s1 = 108; pitch = 4.4; w = 2.6; hc = -44; A = 30;
    n = floor((s1 - s0)/pitch) + 1;
    for (i = [0:n-1]) let(s = s0 + i*pitch, t = i/(n-1), env = pow(sin(180*t), 0.6), a = max(w/2, A*env*wv_g[i % len(wv_g)]))
        hull() { translate(P(s, hc - a)) circle(d = w, $fn = 20); translate(P(s, hc + a)) circle(d = w, $fn = 20); }
}
module grille2d() {                   // スピーカーグリル：六方格子の丸穴。前は小さく奥ほど大きいグラデーション
    pitch = 6.6;
    for (j = [0:30], i = [0:26]) let(x = xL - 4 + i*pitch + (j % 2)*pitch/2, y = 2 + j*pitch*0.866,
                                     t = max(0, min(1, (x - xL)/(xr - xL))), d = 1.8 + 3.4*t)
        translate([x, y]) circle(d = d, $fn = 16);
}
module lines2d() {                    // 40°ライン：傾斜面と平行な溝。下へ行くほど間隔が広がる
    for (k = [0:16]) let(h = -(4 + 1.8*k + 0.22*k*k)) hull() {
        translate(P(-60, h)) circle(d = 1.4, $fn = 12); translate(P(S + 60, h)) circle(d = 1.4, $fn = 12); }
}
// --- 古代遺跡ファンタジー風（オリジナル模様。特定作品のロゴ・紋章は使わない） ---
module stroke(pts, w) for (i = [0:len(pts)-2]) hull() { translate(pts[i]) circle(d = w, $fn = 16); translate(pts[i+1]) circle(d = w, $fn = 16); }
module ring(c, r, w) translate(c) difference() { circle(r = r + w/2, $fn = 96); circle(r = r - w/2, $fn = 96); }
function onr(c, r, a) = [c[0] + r*cos(a), c[1] + r*sin(a)];

module relic_circuit2d() {            // 古代テック回路：直角と45°で折れる光の配線が、中央の円環ノードに集まる
    C = [74, 68]; w = 1.8;
    ring(C, 24, 2.2); ring(C, 17, 1.2); translate(C) circle(d = 7, $fn = 32);
    for (a = [0:30:330]) stroke([onr(C, 19.5, a), onr(C, 21.5, a)], 1.0);            // 円環の目盛り
    stroke([[-20, 18], [22, 18], [35, 31], [50, 31], onr(C, 24, 214)], w);
    stroke([[-20, 42], [8, 42], [24, 58], onr(C, 24, 180)], w);
    stroke([[74, -10], onr(C, 24, 270)], w);
    stroke([onr(C, 24, 0), [104, 68], [118, 82], [140, 82]], w);
    stroke([onr(C, 24, 62), [88, 106], [100, 118], [100, 138]], w);
    stroke([[40, -10], [40, 6], [52, 18]], w);
    stroke([[112, -10], [112, 30], [98, 44]], w);
    stroke([onr(C, 24, 120), [56, 104], [44, 104], [32, 92]], w);
    for (n = [[52, 18], [98, 44], [32, 92], [100, 138], [22, 18]]) ring(n, 3.2, 1.4);  // 端子
    stroke([onr(C, 24, 100), [62, 100], [50, 100]], w); ring([50, 100], 3.2, 1.4);
    stroke([[8, 42], [8, 62], [16, 70]], w); ring([16, 70], 3.2, 1.4);
    for (n = [[8, 42], [104, 68], [88, 106], [40, 6]]) translate(n) circle(d = 3.4, $fn = 20);
}

module rune_circle2d() {              // ルーンの円環：二重の円の間にオリジナルの古代文字を 16 個並べた紋章
    C = [56, 56]; R = 42;
    ring(C, R, 2.2); ring(C, R - 9, 1.2); ring(C, 20, 1.6);
    for (k = [0:15]) let(a = 90 - k*22.5) translate(onr(C, R - 4.5, a)) rotate(a - 90) glyph(k);
    for (a = [0:45:315]) stroke([onr(C, 21, a), onr(C, R - 10, a)], 1.0);
    translate(C) for (r = [0, 45]) rotate(r) difference() {                        // 中心：八方の星（重ねた正方形）
        square(17, center = true); square(17 - 3.2, center = true); }
    translate(C) circle(d = 4.5, $fn = 24);
    // 奥の縁に沿った「文字の柱」：2 本の線の間に記号を縦に並べる
    stroke([[99, 22], [99, 138]], 1.2); stroke([[109, 22], [109, 146]], 1.2);
    for (k = [0:11]) translate([104, 30 + k*9.6]) glyph(k + 3);
    for (q = [[104, 14], [2, 14]]) translate(q) rotate(45) difference() { square(7, center = true); square(3.6, center = true); }
}
module glyph(k) {                     // 古代文字風の記号（縦画＋4種の付属）。幅 1mm の線
    w = 1.0; m = k % 4;
    stroke([[0, -2.2], [0, 2.2]], w);
    if (m == 0) stroke([[-1.6, 2.2], [1.6, 2.2]], w);
    if (m == 1) translate([1.7, 0]) circle(d = 1.3, $fn = 12);
    if (m == 2) stroke([[-1.7, -0.6], [0, 1.0], [1.7, -0.6]], w);
    if (m == 3) { stroke([[-1.5, -2.2], [1.5, -2.2]], w); stroke([[-1.5, 0.4], [-0.2, 0.4]], w); }
}

// 角ばった渦：外側の角から右→上→左→下と、2辺ごとに step ずつ短くしながら内側へ巻き込む
module square_spiral(c, step, turns, w) let(a = step*turns, p0 = c + [-a, -a])
    stroke(concat([p0], spiral_pts(p0, step, 2*a, 0, 4*turns - 1)), w);
function spiral_pts(p, step, L2a, i, n) =
    i >= n ? [] :
    let(L = i == 0 ? L2a : L2a - step*floor((i - 1)/2),
        q = p + [[1, 0], [0, 1], [-1, 0], [0, -1]][i % 4]*L)
    concat([q], spiral_pts(q, step, L2a, i + 1, n));
module stone_spiral2d() {             // 石板の渦紋：外枠の彫り線＋角ばった渦＋雷文の帯
    difference() { pattern_area2d(); offset(delta = -2) pattern_area2d(); }          // 内側の枠線
    square_spiral([46, 74], 5.4, 5, 2.0);
    translate([96, 112]) mirror([1, 0]) square_spiral([0, 0], 5.4, 3, 2.0);       // 逆巻きの渦で対に
    for (i = [0:7]) translate([-6 + i*16, 10]) {                                  // 雷文（メアンダー）の帯
        stroke([[0, 0], [16, 0]], 1.8);
        stroke([[13, 0], [13, 13], [3, 13], [3, 4], [9, 4], [9, 9]], 1.8);
    }
    stroke([[-20, 31], [140, 31]], 1.8);
}

module pattern2d() intersection() {
    pattern_area2d();
    if      (panel_style == "eq")     eq2d();
    else if (panel_style == "wave")   wave2d();
    else if (panel_style == "grille") grille2d();
    else if (panel_style == "lines")  lines2d();
    else if (panel_style == "relic")  relic_circuit2d();
    else if (panel_style == "rune")   rune_circle2d();
    else if (panel_style == "stone")  stone_spiral2d();
    else if (panel_style == "ripple") ripple_pattern2d();
}

// 台の外面（Z=0）に付けた状態の座標：表面が Z=-pnl_t、リムが +Z 側へ穴に入る
module panel_local() difference() {
    union() {
        translate([0, 0, -pnl_t + pnl_chamfer]) linear_extrude(pnl_t - pnl_chamfer) side_outline2d();
        for (k = [0:2]) translate([0, 0, -pnl_t + k*pnl_chamfer/3])            // 表側の縁の45°面取り（3段で近似）
            linear_extrude(pnl_chamfer/3 + 0.01) offset(delta = -(pnl_chamfer - k*pnl_chamfer/3)) side_outline2d();
        linear_extrude(plug_len - 1) plug_rim2d(plug_tol);                    // 差し込みリム
        translate([0, 0, plug_len - 1 - 0.01]) linear_extrude(1) plug_rim2d(plug_tol + 0.4);   // 先端は細くして入れやすく
    }
    translate([0, 0, -pnl_t - 1]) linear_extrude(deboss + 1) pattern2d();
}
module plug_rim2d(tol) difference() { offset(delta = -tol) holes2d(); offset(delta = -tol - plug_wall) holes2d(); }

// 2 色表示用（表面から color_layer までを表の色、それより奥を模様の色で）
module panel_colored(c_face = "DimGray", c_accent = "Orange") {
    color(c_face)   intersection() { panel_local(); translate([-500, -500, -pnl_t - 1]) cube([1000, 1000, 1 + color_layer]); }
    color(c_accent) intersection() { panel_local(); translate([-500, -500, -pnl_t + color_layer]) cube([1000, 1000, 100]); }
}

// 手前ストッパー・側板が本体の手前の高さを超えないこと（超えると天板やつまみに当たる）
assert(lip_h   < dev_h_front, "lip_h が本体の手前の高さ以上です");
assert(guide_h < dev_h_front, "guide_h が本体の手前の高さ以上です");

// 圧入テスト：オス1個 ＋ クリアランス違いの穴3個
module fit_test() {
    linear_extrude(6) square([16, 16]);
    translate([8, 8, 6 - 0.01]) peg(peg_d);
    translate([22, 0, 0]) difference() {
        cube([48, 16, peg_len + 2]);
        for (i = [0:2]) translate([8 + i*16, 8, 2]) {
            dh = peg_d + 2*(0.10 + i*0.05);
            cylinder(d = dh, h = peg_len + 1);
        }
        for (i = [0:2]) translate([8 + i*16 - 2, 1, peg_len + 2 - 0.6])  // 目印の溝 本数=1,2,3 → 0.10/0.15/0.20
            for (k = [0:i]) translate([k*1.6, 0, 0]) cube([0.8, 2.5, 1]);
    }
}

// ============================================================
//  増設台（Kindle Paperwhite 第10世代 横置き ＋ M5Stack Basic）
//  ・AG03 台と同じ側面形状・同じ前の線（共通規格）。並びは左から AG03｜Kindle｜通り道｜M5Stack
//  ・機器の前面は前板の上端（傾斜面から lip_h）にそろえる：Kindle は座面を持ち上げ、M5Stack はそのまま
//  ・Kindle と M5Stack の間にケーブルの通り道（L字プラグ前提）。ケーブルは溝から台の中へ落とし、背面・底面の後ろの開口から出す
//  ・下段は引き出しを後から付けられる空間（天井板・床板・仕切り・奥の止め・抜け止めの山）。今は引き出しなし
//  ・AG03 台とは「連結キー」（側面の穴に両側から差し込むリング）でつなぐ。右端には波紋パネル（panel_b）を付けられる
//  ・幅が 255mm あるので 4 分割（左｜Kindle｜通り道｜M5Stack）して印刷し、ダボでつなぐ。どれも下の面から立ち上がる形でサポート不要
// ============================================================
kin_w = 167; kin_h = 116; kin_t = 8.18;          // Kindle Paperwhite 第10世代（横置き：幅×高さ×厚み）
m5_w = 54.1; m5_h = 54.1; m5_t = 17.6;            // M5Stack Basic（実測）
dev_clr = 0.6;                                     // 機器と壁のすき間 [mm]
chan_w  = 24;                                      // ケーブルの通り道の幅 [mm]（L字プラグ前提）
kin_riser = lip_h - kin_t;                         // Kindle の座面の持ち上げ量（画面を前板の上端にそろえる）
back_open_top = 95;                                // 背面の開口の上端（机から）[mm]

// 幅方向の位置（増設台の左面＝AG03 台の右面が 0、右へ +）
ez_k0  = g + dev_clr;                ez_k1 = ez_k0 + kin_w;
ez_c0  = ez_k1 + dev_clr;            ez_c1 = ez_c0 + chan_w;
ez_m0  = ez_c1 + dev_clr;            ez_m1 = ez_m0 + m5_w;
ez_end = ez_m1 + dev_clr + g;
ez_cut1 = 86;                                       // 印刷の分割位置：P1｜P2 = ez_cut1、P2｜P3 = ez_c0（通り道の左端）、P3｜P4 = ez_c1（右端）
rear_open_x = dr_x1 + 3;                            // ここより後ろは床・天井なし（ケーブルの縦の通り道）

module ext_floor2d()   intersection() { sil2d(); translate([xL - 1, -1]) square([rear_open_x - xL + 1, t_floor + 1]); }
module ext_ceiling2d() intersection() { sil2d(); translate([P(10, -t_top)[0] - 2, ceil_bot]) square([rear_open_x - P(10, -t_top)[0] + 2, t_ceil]); }
module ext_rib2d()     translate([dr_x1 + 0.3, t_floor - 0.01]) square([rear_open_x - dr_x1 - 0.3, ceil_bot - t_floor + 0.02]);   // 引き出し空間の奥の壁（床と天井をつなぎ、引き出しの奥の止めも兼ねる）
module ext_back2d()    intersection() { back2d(); translate([-500, back_open_top]) square(1000); }
module ext_common2d() { front_wall2d(); front_slope2d(); front_rung2d(); rear_rung2d(); ext_floor2d(); ext_ceiling2d(); ext_rib2d(); ext_back2d(); }
module kin_support2d() {               // Kindle の座面（厚み 3mm の床）と、それを支える横桁（座面の高さまで持ち上げ）
    band(0, S, kin_riser - 3, kin_riser);
    for (r = [[-lip_t, 18], [S*0.45 - 8, S*0.45 + 8], [S - 30, S]]) band(r[0], r[1], -t_top, kin_riser);
}
module m5_support2d() {                // M5Stack の座面（傾斜面そのもの）
    band(0, S, -3, 0);
    band(S*0.45 - 8, S*0.45 + 8, -t_top, 0);
}
module chan_block2d() band(-lip_t, 6, -t_top, lip_h);   // 通り道の手前の角：Kindle の右下・M5Stack の左下の角を受ける
module chan_rblock2d() band(118, S, -t_top, lip_h);     // 通り道の奥の受け台（カバーの奥側を受ける）

// ケーブルカバー：通り道の上にかぶせて L字プラグとケーブルを隠す。手前・奥の受け台の溝に差し込むだけ（摩擦で留まる）
cov_t   = 1.6;                 // カバーの厚み [mm]
cov_s0  = 3;  cov_s1 = 121;    // カバーの範囲（傾斜に沿って）
cov_clr = 0.3;                 // 通り道の壁（機器）とのすき間 [mm]
cov_h0  = lip_h;               // カバーの下面の高さ（受け台の上面）。L字アダプタ（厚み約 7mm）の上に余裕を残す
plug_w  = 16; plug_s = 2.0; plug_dp = 2.4;              // 差し込み部（幅・奥行・深さ）
cov_W   = chan_w - 2*cov_clr;
module cover_local() {          // u: 傾斜に沿って、v: 幅、w: 厚み方向（上面 w=0）
    translate([0, 0, -cov_t]) linear_extrude(cov_t) offset(r = 2) offset(delta = -2) translate([cov_s0, 0]) square([cov_s1 - cov_s0, cov_W]);
    for (u = [(cov_s0 + 6)/2 + 0.0, 119.5]) translate([u - plug_s/2, (cov_W - plug_w)/2, -cov_t - plug_dp]) cube([plug_s, plug_w, plug_dp + 0.01]);
}
module cover_placed() multmatrix([[cos(tilt), 0, -sin(tilt), -sin(tilt)*(cov_h0 + cov_t)],
                                  [sin(tilt), 0,  cos(tilt), H0 + cos(tilt)*(cov_h0 + cov_t)],
                                  [0, -1, 0, ez_c1 - cov_clr], [0, 0, 0, 1]]) cover_local();
module cover_recess() for (u = [(cov_s0 + 6)/2, 119.5])                  // 受け台の溝（差し込み部より 0.2mm ずつ大きい）
    translate([0, 0, ez_c0 + cov_clr + (cov_W - plug_w)/2 - 0.2]) linear_extrude(plug_w + 0.4)
        band(u - plug_s/2 - 0.2, u + plug_s/2 + 0.2, cov_h0 - plug_dp - 0.2, cov_h0 + 0.01);
// 通り道の奥の柱：通り道のパーツの手前側と奥の横桁をつなぐ（通り道の左端に幅 4mm だけ。残り 20mm はケーブルが通れる）
module chan_post2d() intersection() { sil2d(); translate([rear_open_x - 3, ceil_bot]) square([3, 135 - ceil_bot]); }
module ext_div2d() intersection() { sil2d(); translate([xL - 1, 0]) square([rear_open_x - xL + 1, ceil_top]); }  // 引き出しの仕切り
kz_bump = (g + frame_w + ez_c0)/2 + 8;              // 抜け止めの山（引き出しを付けたとき用）
mz_bump = (ez_c0 + 3 + ez_end - g - frame_w)/2 - 4;   // （M5Stack 側は継ぎ目を避けて中央寄り）

module ext_solid() difference() { ext_solid_body(); cover_recess(); }
module ext_solid_body() {
    linear_extrude(g + frame_w) frame2d();  linear_extrude(g) guide2d();                         // 左の枠（穴は共通規格）
    translate([0, 0, ez_end]) mirror([0, 0, 1]) { linear_extrude(g + frame_w) frame2d(); linear_extrude(g) guide2d(); }   // 右の枠
    linear_extrude(ez_end) ext_common2d();
    translate([0, 0, g])     linear_extrude(ez_c0 - g)          kin_support2d();
    translate([0, 0, ez_c0]) linear_extrude(chan_w)             { chan_block2d(); chan_rblock2d(); }
    translate([0, 0, ez_c1]) linear_extrude(ez_end - g - ez_c1) m5_support2d();
    translate([0, 0, ez_c0]) linear_extrude(3)                  ext_div2d();
    translate([0, 0, ez_c0]) linear_extrude(4)                  chan_post2d();
    for (z = [kz_bump, mz_bump]) translate([0, 0, z - det_bw/2]) linear_extrude(det_bw) detent_bump2d();
}

// 分割面のダボ（両側に材料がある位置）
pegs_c1 = [[xL + 4.5, ceil_bot + 5.5, peg_d], [-1.8, ceil_bot + 5.5, peg_d],
           concat(P(5, -5), [peg_d]), concat(P(13, -5), [peg_d]), concat(P(S*0.45, -5), [peg_d]),
           concat(P(S - 25, -5), [peg_d]), concat(P(S - 12, -5), [peg_d])];
pegs_c2 = [[xL + 4.5, ceil_bot + 5.5, peg_d], [-1.8, ceil_bot + 5.5, peg_d],
           concat(P(9, -5), [peg_d]), concat(P(S - 25, -5), [peg_d]), concat(P(S - 12, -5), [peg_d])];
pegs_c3 = pegs_c2;
module slab(z0, z1) translate([-500, -500, z0 + 0.002]) cube([1000, 1000, z1 - z0 - 0.004]);   // 切り口ちょうどで始まる部品が厚み 0 の面を作らないよう、わずかに内側で切る
module pegs_at(list, z)  for (p = list) translate([p[0], p[1], z - 0.01]) peg(p[2]);
module holes_at(list, z) for (p = list) translate([p[0], p[1], z - 0.01]) peg_hole_up(p[2]);
module peg_hole_up(d) let(dh = d + 2*fit_tol) {     // 下の面から上向きの穴（入口の面取りつき）
    cylinder(d = dh, h = peg_len + 0.6);
    cylinder(d1 = dh + 1.2, d2 = dh, h = 0.6);
}
module ext_p1() { intersection() { ext_solid(); slab(0, ez_cut1); } pegs_at(pegs_c1, ez_cut1); }
module ext_p2() { difference() { intersection() { ext_solid(); slab(ez_cut1, ez_c0); } holes_at(pegs_c1, ez_cut1); } pegs_at(pegs_c2, ez_c0); }
module ext_p3() difference() { intersection() { ext_solid(); slab(ez_c0, ez_c1); } holes_at(pegs_c2, ez_c0);
    for (p = pegs_c3) translate([p[0], p[1], ez_c1 - peg_len - 0.6]) peg_hole(p[2]); }        // 上の面にも穴（P4 のダボが入る）
module ext_p4() { intersection() { ext_solid(); slab(ez_c1, ez_end); }                       // 右の枠を下にして印刷するので、ダボは左向き
    for (p = pegs_c3) translate([p[0], p[1], ez_c1 + 0.01]) mirror([0, 0, 1]) peg(p[2]); }

// 連結キー：AG03 台の側面の穴と増設台の左の枠の穴に、両側から 6mm ずつ差し込むリング（3 個を 1 回で印刷）
module ext_keys() {
    c = 0.6;
    linear_extrude(2*plug_len - 2*c) plug_rim2d(plug_tol);
    translate([0, 0, -c]) linear_extrude(c + 0.01) plug_rim2d(plug_tol + 0.4);
    translate([0, 0, 2*plug_len - 2*c - 0.01]) linear_extrude(c) plug_rim2d(plug_tol + 0.4);
}

// 全体の組み立て表示（AG03 台の右に増設台。両端に波紋パネル、Kindle・M5Stack・AG03 をゴースト表示）
module full_view() rotate([90, 0, 0]) {
    color("#2A2A2A") { half(true); translate([0, 0, 2*Zc]) mirror([0, 0, 1]) half(false); }
    panel_colored(face_col, accent_col);
    translate([0, 0, 2*Zc]) {
        color("#2E2E2E") ext_solid();
        translate([0, 0, ez_end]) mirror([0, 0, 1]) panel_colored(face_col, accent_col);
        dev_on(ez_k0, kin_h, kin_t, kin_w, kin_riser, "#E8E6DF");
        dev_on(ez_m0, m5_h, m5_t, m5_w, 0, "#3A6FD0");
        color("#262626") cover_placed();
    }
    %translate([0, 0, g + clr]) multmatrix([[cos(tilt), -sin(tilt), 0, 0], [sin(tilt), cos(tilt), 0, H0], [0, 0, 1, 0], [0, 0, 0, 1]])
        linear_extrude(dev_w) polygon([[0, 0], [dev_d, 0], [dev_d, dev_h_rear], [0, dev_h_front]]);
}
module dev_on(z0, L, T, W, h0, col) color(col, 0.9) translate([0, 0, z0])
    multmatrix([[cos(tilt), -sin(tilt), 0, 0], [sin(tilt), cos(tilt), 0, H0], [0, 0, 1, 0], [0, 0, 0, 1]]) translate([0, h0, 0]) cube([L, T, W]);

if      (part == "half_a")   half(true);
else if (part == "half_b")   mirror([1, 0, 0]) half(false);   // 裏返して外面を下にした向き
else if (part == "drawer")   drawer();
else if (part == "panel_a")  translate([0, 0, pnl_t]) panel_local();                     // 左パネル（表面を下にして印刷）
else if (part == "panel_b")  mirror([1, 0, 0]) translate([0, 0, pnl_t]) panel_local();  // 右パネル
else if (part == "panel_view") rotate([90, 0, 0]) { color("Gainsboro") half(true); panel_colored(face_col, accent_col);
    color("Goldenrod") translate([dr_x0, dr_y0, dr_z0]) multmatrix([[1, 0, 0, 0], [0, 0, 1, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) drawer();
    %translate([0, 0, g + clr]) multmatrix([[cos(tilt), -sin(tilt), 0, 0], [sin(tilt), cos(tilt), 0, H0], [0, 0, 1, 0], [0, 0, 0, 1]])
        linear_extrude(dev_w) polygon([[0, 0], [dev_d, 0], [dev_d, dev_h_rear], [0, dev_h_front]]); }
else if (part == "ext_p1")   ext_p1();                                     // 増設台 1/4（左の枠を下にして印刷）
else if (part == "ext_p2")   translate([0, 0, -ez_cut1]) ext_p2();          // 増設台 2/4（Kindle）
else if (part == "ext_p3")   translate([0, 0, -ez_c0]) ext_p3();            // 増設台 3/4（ケーブルの通り道）
else if (part == "ext_p4")   rotate([180, 0, 0]) translate([0, 0, -ez_end]) ext_p4();   // 増設台 4/4（M5Stack。右の外面を下にして印刷）
else if (part == "ext_keys") translate([0, 0, 0.6]) ext_keys();             // 連結キー 3 個
else if (part == "ext_cover") rotate([180, 0, 0]) cover_local();          // ケーブルカバー（上面を下にして印刷）
else if (part == "full_view") full_view();
else if (part == "fit_test") fit_test();
else                         assembly();
