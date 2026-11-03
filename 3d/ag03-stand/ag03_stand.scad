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
guide_h = 14;    // ガイド壁の高さ（本体底面から）[mm]。手前はストッパーの高さから滑らかに下がる
frame_w = 14;    // 側面フレーム（＝手前ストッパー）の横幅（側板の内側へ）[mm]
                 //   左右の角だけなので前面中央の端子・プラグの通り道はふさがない
m       = 7;     // フレーム部材の太さ [mm]
t_top   = 10;    // 傾斜面（本体を受ける部材）の厚み [mm]
t_base  = 10;    // 底の部材の厚み [mm]
lip_t   = 5;     // 手前ストッパーの厚み [mm]
lip_h   = 27.0;  // 手前ストッパーの高さ（本体底面から）[mm]  ※本体の手前の高さ28.0より低く

/* ---------- 曲線デザイン（接地面・本体との接触面以外） ---------- */
R_out   = 2.4;   // 外形の角R [mm]
R_hole  = 9;     // 肉抜き穴の角R [mm]
bow_f   = 8;     // 前脚の前面のえぐり量 [mm]
bow_r   = 15;    // 後脚の背面のえぐり量 [mm]
arch_h  = 5;     // 底面中央のアーチ高さ [mm]（前後の脚だけが机に触れる）
N       = 32;    // 曲線の分割数

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
function lerp(a, b, t) = a + (b - a)*t;

module band(s0, s1, h0, h1) polygon([P(s0,h0), P(s1,h0), P(s1,h1), P(s0,h1)]);
module below_top() band(-500, 500, -500, -t_top);           // 傾斜部材より下（穴を開けてよい範囲）

xf = P(-lip_t, -m)[0];      // 前側の横桁の前面 x
xr = P(S, -t_top)[0];       // 後脚の背面 x（机に触れる後端）
xL = P(-lip_t, lip_h)[0];   // ストッパー先端 x（＝前脚のつま先）
Zc = g + dev_w/2 + clr;     // 左右パーツの合わせ面（中心）

xa = xf + 26;               // 前脚の接地面の後端 → ここからアーチ
xb = xr - 20;               // 後脚の接地面の前端

// 外形（反時計回り）: 前脚つま先 → 底(前の接地面・アーチ・後ろの接地面) → 後脚の背面(えぐり)
//                    → 傾斜面(本体が乗る直線) → ストッパー → 前脚の前面(えぐり)
function silhouette() = concat(
    [[xL, 0]],
    [for (i = [0:N]) let(t = i/N) [lerp(xa, xb, t), arch_h*pow(sin(180*t), 2)]],
    [[xr, 0]],
    [for (i = [1:N-1]) let(t = i/N) [lerp(xr, P(S,0)[0], t) - bow_r*sin(180*t), lerp(0, P(S,0)[1], t)]],
    [P(S, 0), P(0, 0), P(0, lip_h), P(-lip_t, lip_h)],
    [for (i = [1:N-1]) let(t = 1 - i/N) [xL + bow_f*sin(180*t), lerp(0, P(-lip_t, lip_h)[1], t)]]
);

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
    }

module frame2d() difference() { sil2d(); holes2d(); }

// 側板（Z=0〜g）：手前はストッパーの高さから guide_h まで滑らかに下がり、後端は丸く終わる
function guide_top(s) =
    s <= 0        ? lip_h :
    s <= 55       ? guide_h + (lip_h - guide_h)*(1 + cos(180*s/55))/2 :
    s <= S - 34   ? guide_h :
                    guide_h*sqrt(max(0, 1 - pow((s - (S - 34))/30, 2)));
module guide2d() offset(r = 2) offset(delta = -2) polygon(concat(
    [for (i = [0:120]) let(s = lerp(-lip_t, S - 4, i/120)) P(s, guide_top(s))],
    [P(S - 4, -2), P(-lip_t, -2)]
));

// 中央へ渡す横桁（左右パーツの合わせ面まで伸びる）— 断面はフレームの形をそのまま引き継ぐ
module front_base2d() rnd() intersection() { frame2d(); translate([xf - 1, -1]) square([26, t_base + 1]); }
module front_rung2d() rnd() intersection() { frame2d(); band(-lip_t, 18, -t_top, 0); }
module mid_rung2d()   rnd() intersection() { frame2d(); band(S*0.45 - 8, S*0.45 + 8, -t_top, 0); }
module rear_rung2d()  rnd() intersection() { frame2d(); band(S - 30, S + 1, -t_top, 0); }
module rear_base2d()  rnd() intersection() { frame2d(); translate([xr - 18, -1]) square([19, t_base + 1]); }
module bars2d() { front_base2d(); front_rung2d(); mid_rung2d(); rear_rung2d(); rear_base2d(); }
module rnd() offset(r = 2.5) offset(delta = -2.5) children();       // 横桁の角も丸める

// 横桁の付け根のフィレット（フレーム上面から立ち上がる部分を R_fil で滑らかに）
// 下にフレームがある範囲だけに作るので、印刷時にオーバーハングにならない
R_fil = 6;
module bar_fillets() {
    n = 8;
    for (i = [0:n-1]) let(z0 = R_fil*i/n, zm = R_fil*(i + 0.5)/n,
                          w = R_fil - sqrt(R_fil*R_fil - pow(R_fil - zm, 2)))
        translate([0, 0, g + frame_w + z0]) linear_extrude(R_fil/n + 0.01)
            intersection() { frame2d(); offset(r = w) bars2d(); }
}

// ダボ位置 [x, y, 直径]
pegs = [
    [xf + 12, 5, 5],
    concat(P(7,        -5), [5]),
    concat(P(S*0.45,   -5), [5]),
    concat(P(S - 20,   -5), [5]),
    [xr - 9,  5, 5],
];

// ============================================================
//  3D
// ============================================================
module half(male = true) {
    difference() {
        union() {
            linear_extrude(g + frame_w) frame2d();                     // 側面フレーム（ストッパー・前脚込み）
            linear_extrude(g) guide2d();                               // 側板（横ズレ防止）
            linear_extrude(Zc) bars2d();                               // 横桁
            bar_fillets();
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
