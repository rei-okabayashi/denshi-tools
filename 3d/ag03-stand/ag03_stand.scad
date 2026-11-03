// ============================================================
//  YAMAHA AG03（初代）用 40° チルトスタンド（AG03MK2 にも切替可）
//  ・ネジ／接着剤 不要（左右2分割を圧入ダボで差し込むだけ）
//  ・サポート不要（どちらのパーツも外側の側板を下にして寝かせて印刷）
//
//  使い方（OpenSCAD）:
//    part = "assembly"  … 組み立てプレビュー（AG03の外形をゴースト表示）
//    part = "half_a"    … 左パーツ（ダボ＝オス）   ← STL書き出し用
//    part = "half_b"    … 右パーツ（ダボ穴＝メス） ← STL書き出し用
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
H0      = 35;    // 本体手前下端の机からの高さ [mm]
                 //   前面のヘッドセット端子(3.5mm)のプラグが机に当たらないための逃げ
S       = 150;   // 傾斜面で支える長さ [mm]（重心≒奥行の中央より十分後ろまで）

/* ---------- 構造 ---------- */
clr     = 0.6;   // 本体側面と側板の片側すき間 [mm]
g       = 4;     // 側板（ガイド壁）の厚み [mm]
guide_h = 14;    // ガイド壁の高さ（本体底面から）[mm]
rail_w  = 18;    // 側面レール（トラス）の幅（側板の内側へ）[mm]
m       = 8;     // トラス部材の太さ [mm]
lip_t   = 5;     // 手前ストッパーの厚み [mm]
lip_h   = 27.0;  // 手前ストッパーの高さ（本体底面から）[mm]  ※本体の手前の高さ28.0より低く。左右の角だけなので中央の前面端子にはかからない
lip_w   = 14;    // 手前ストッパーの横幅（左右の角だけ。中央は端子用に空ける）[mm]
corner_r = 3;    // 肉抜き穴の角R [mm]

/* ---------- 圧入ダボ ---------- */
peg_len = 6;     // ダボ長さ [mm]
fit_tol = 0.15;  // 穴の半径方向クリアランス [mm]（きつい→0.2 / ゆるい→0.1）

$fn = 48;

// ============================================================
//  2D 側面プロファイル（x: 手前→奥, y: 上）
//  P(s,h): 傾斜面に沿って s、傾斜面の法線方向に h だけ進んだ点
//          s=0,h=0 が本体の手前下端
// ============================================================
function P(s, h) = [s*cos(tilt) - h*sin(tilt), H0 + s*sin(tilt) + h*cos(tilt)];

module band(s0, s1, h0, h1) polygon([P(s0,h0), P(s1,h0), P(s1,h1), P(s0,h1)]);

xf = P(-lip_t, -m)[0];   // 前脚の前面 x
xr = P(S, -m)[0];        // 後脚の背面 x
Zc = g + dev_w/2 + clr;  // 左右パーツの合わせ面（中心）

module outer2d() hull() {
    translate([xf, 0]) square([xr - xf, 0.01]);
    band(-lip_t, S, -m, 0);
}

// 肉抜き：外形を m だけ内側にオフセットし、斜材で2室に仕切る
module holes2d()
    offset(r = corner_r) offset(delta = -corner_r)
    difference() {
        offset(delta = -m) outer2d();
        hull() {                                   // 斜材（後ろ下→傾斜の中ほど）
            translate([xr - m, m]) circle(d = m);
            translate(P(S*0.45, -m)) circle(d = m);
        }
    }

module rail2d() difference() { outer2d(); holes2d(); }

// 手前ストッパー＋前脚：ストッパー先端から机まで垂直に落とした面で埋める（前倒れ防止）
// 左右の角（幅 lip_w）だけに設けるので、前面中央の端子・プラグの通り道はふさがない
xL = P(-lip_t, lip_h)[0];  // ストッパー先端の x（＝前脚の前面）
module front_foot2d() hull() {
    band(-lip_t, 0, -m, lip_h);
    translate([xL, 0]) square([xf - xL, 0.01]);
}

// 中央へ渡す横桁（左右パーツの合わせ面まで伸びる）
module front_bar2d() intersection() { outer2d(); translate([xf - 1, -1]) square([15, 200]); }
module rear_rung2d() intersection() { outer2d(); band(S - 22, S + 1, -12, 0); }
module mid_rung2d()  intersection() { outer2d(); band(S*0.45 - 8, S*0.45 + 8, -10, 0); }
module rear_base2d() intersection() { outer2d(); translate([xr - 16, -1]) square([17, 13]); }

// ダボ位置 [x, y, 直径]
pegs = [
    [xf + 7.5, 9,  6],
    [xf + 7.5, 22, 6],
    concat(P(S - 11, -6),     [6]),
    concat(P(S*0.45, -5),     [5]),
    [xr - 8,   6,  6],
];

// ============================================================
//  3D
// ============================================================
module half(male = true) {
    difference() {
        union() {
            linear_extrude(g + rail_w) rail2d();                       // 側面トラス
            linear_extrude(g) band(-lip_t, S, -m, guide_h);            // 側板（横ズレ防止）
            linear_extrude(g + lip_w) front_foot2d();                  // 手前ストッパー＋前脚（前倒れ防止）
            linear_extrude(Zc) {                                       // 横桁
                front_bar2d(); rear_rung2d(); mid_rung2d(); rear_base2d();
            }
            if (male) for (p = pegs) translate([p[0], p[1], Zc - 0.01]) peg(p[2]);
        }
        if (!male) for (p = pegs)
            translate([p[0], p[1], Zc - peg_len - 0.6]) peg_hole(p[2]);
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
}

// 手前ストッパー・側板が本体の手前の高さを超えないこと（超えると天板やつまみに当たる）
assert(lip_h   < dev_h_front, "lip_h が本体の手前の高さ以上です");
assert(guide_h < dev_h_front, "guide_h が本体の手前の高さ以上です");

// 圧入テスト：オス1個 ＋ クリアランス違いの穴3個
module fit_test() {
    linear_extrude(6) square([16, 16]);
    translate([8, 8, 6 - 0.01]) peg(6);
    translate([22, 0, 0]) difference() {
        cube([48, 16, peg_len + 2]);
        for (i = [0:2]) translate([8 + i*16, 8, 2]) {
            dh = 6 + 2*(0.10 + i*0.05);
            cylinder(d = dh, h = peg_len + 1);
        }
        for (i = [0:2]) translate([8 + i*16 - 2, 1, peg_len + 2 - 0.6])  // 目印の溝 本数=1,2,3 → 0.10/0.15/0.20
            for (k = [0:i]) translate([k*1.6, 0, 0]) cube([0.8, 2.5, 1]);
    }
}

if      (part == "half_a")   half(true);
else if (part == "half_b")   mirror([1, 0, 0]) half(false);   // 裏返して外面を下にした向き
else if (part == "fit_test") fit_test();
else                         assembly();
