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
dr_floor    = 1.6;  // 底の厚み [mm]
dr_r        = 3;    // 外形の角R [mm]
dr_front    = 2.4;  // 前板の厚み [mm]（つまみを支えるので少し厚め）
knob_w      = 40;   // つまみの幅 [mm]
knob_p      = 9;    // つまみの出っ張り [mm]
knob_t      = 5;    // つまみ先端の縦の厚み [mm]（下側は45°の斜面でサポート不要）
knob_top    = 4;    // 前板の上端からつまみ上面までの距離 [mm]
dr_chamfer  = 0.4;  // 底の外周の面取り [mm]（1層目の広がり＝象の足でこすれないように）
// 抜け止め：左右の側壁を縦に切った「ツメ」。外向きの突起が側面フレームの下段の穴に入り、
// 引き出すと穴の前の縁に当たって止まる。外すときは横の穴からツメを内側へ押す
stop_u      = 89;   // 突起の前面の位置（前面からの距離）[mm]：閉めた状態で穴の中に来る位置
tab_len     = 9;    // ツメの幅 [mm]
tab_slit    = 0.8;  // ツメの両脇の切り込み幅 [mm]
tab_base    = 8;    // ツメの付け根の高さ（引き出しの底から）[mm]
bump_p      = 1.5;  // 突起の出っ張り [mm]（すき間0.5を引いて約1mm掛かる）
bump_w0     = 17;   // 突起の下端の高さ（引き出しの底から）[mm]：穴の縁がまっすぐな範囲に入れる
bump_w1     = 24;   // 突起の上端の高さ [mm]

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
        chamfer_box(dr_L, dr_W, dr_H, dr_r, dr_chamfer);
        translate([dr_front, dr_wall, dr_floor])
            rbox(dr_L - dr_front - dr_wall, dr_W - 2*dr_wall, dr_H, max(0.5, dr_r - dr_wall));
        for (side = [0, 1]) side_mirror(side)                       // ツメの両脇の切り込み（上は開放）
            for (u = [stop_u - tab_slit, stop_u + tab_len])
                translate([u, -1, tab_base]) cube([tab_slit, dr_wall + 2, dr_H]);
    }
    knob();
    for (side = [0, 1]) side_mirror(side) stop_bump();
}
module side_mirror(side) if (side == 0) children(); else translate([0, dr_W, 0]) mirror([0, 1, 0]) children();

// 突起：前面は垂直（止まる面）、後ろ側は斜面（差し込むとき押し込まれる）、下面は45°（サポート不要）
module stop_bump() intersection() {
    translate([0, 0, bump_w0]) linear_extrude(bump_w1 - bump_w0)
        polygon([[stop_u + 0.5, 0.01], [stop_u + 0.5, -bump_p], [stop_u + 3, -bump_p], [stop_u + tab_len - 0.5, 0.01]]);
    translate([0, 0.01, 0]) rotate([90, 0, 90]) linear_extrude(dr_L)
        polygon([[0.01, bump_w0], [-bump_p, bump_w0 + bump_p], [-bump_p, bump_w1], [0.01, bump_w1]]);
}
// 底の外周だけ45°で面取りした角丸の箱
module chamfer_box(l, w, h, r, c) hull() {
    translate([0, 0, c]) rbox(l, w, h - c, r);
    linear_extrude(c + 0.01) offset(delta = -c) offset(r = r) offset(delta = -r) square([l, w]);
}

// 前板中央のつまみ：上面は水平、下面は45°の斜面（印刷時にサポート不要）。外側の角は丸める
module knob() {
    w1 = dr_H - knob_top;               // つまみ上面の高さ
    w0 = w1 - knob_t - knob_p;          // 斜面が前板に付く高さ
    intersection() {
        translate([0, dr_W/2 + knob_w/2, 0]) rotate([90, 0, 0]) linear_extrude(knob_w)
            offset(r = 1.5) offset(delta = -1.5)
            polygon([[0.01, w0], [-knob_p, w0 + knob_p], [-knob_p, w1], [0.01, w1]]);
        linear_extrude(dr_H) offset(r = 4) offset(delta = -4)
            translate([-knob_p, dr_W/2 - knob_w/2]) square([knob_p + 6, knob_w]);
    }
}
module rbox(l, w, h, r) linear_extrude(h) offset(r = r) offset(delta = -r) square([l, w]);

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

if      (part == "half_a")   half(true);
else if (part == "half_b")   mirror([1, 0, 0]) half(false);   // 裏返して外面を下にした向き
else if (part == "drawer")   drawer();
else if (part == "fit_test") fit_test();
else                         assembly();
