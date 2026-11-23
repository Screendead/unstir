// Copyright © 2026 Jack Lusher. All rights reserved.
// The Plumb Line: the Descent at its sparest. One fine line hangs from a float at the surface and ends in a small
// weight that is always where the player is; it pays out as they dive and reels in as they rise. Levels are beads on
// the line, the next one largest; levels not yet reached wait in the water below the weight. Packs hang on short side
// lines. The ground is one shader pass (water by depth, a breath of light from the surface, a few motes); the line,
// type and glass are 2D on top. Nothing stirs, and every clock stops while a level is on the screen.

const { ramp, ease, settle, mix } = World;
const RM = World.rm, AX = World.ax;
const PM = AX ? 236 : 132;            // points between two levels
const TOP = 340;                      // world y of level 0; the surface is world y 0
const FOCUS = 470;                    // screen y the weight rides at
const levelY = (n) => TOP + n * PM;
const NAMES = ['Drop', 'Drip', 'Trickle', 'Ripple', 'Bubble', 'Fizz', 'Sprinkle', 'Mist', 'Spray', 'Splash', 'Puddle',
  'Froth', 'Suds', 'Lather', 'Steam', 'Gurgle', 'Rinse', 'Drizzle', 'Shower', 'Downpour', 'Overflow', 'Bathwater',
  'Spin', 'Whirl', 'Spiral', 'Last drop', 'Drain'];
const two = (n) => String(n).padStart(2, '0');

const INK = '#eef1f6';
const ink = (a) => `rgba(238, 241, 246, ${a})`;
const F = {
  name: (s, w = 300) => `${w} ${s}px UPro`,
  word: (s) => `italic 300 ${s}px NY`,
  data: (s) => `400 ${s}px UMono`,
  ui: (s, w = 400) => `${w} ${s}px UPro`,
};
const P = (role) => World.pt(role);

const PACKS = [
  { id: 'lens', name: 'Lens', m: 6.5 },
  { id: 'escapement', name: 'Escapement', m: 11.5 },
  { id: 'prism', name: 'Prism', m: 16.5 },
  { id: 'triptych', name: 'Triptych I', m: 21.5 },
];
const PACK_X = AX ? 330 : 68, PACK_D = 58, PACK_DROP = 80;

// ---------------------------------------------------------------- the timeline (the Descent's, shot for shot)
// 0     the whole column at rest                         menu-today
// 2.6   a tap by the weight; the view sinks to 14
// 5.2   the line at 14 Lather                            menu
// 7.0   a finger draws the water down: the line reels in to 01
// 8.9   tapping Drop: the weight opens into its tank
// 10.4  play at rest, every clock stopped                play
// 12.6  later: the line pays out to 27
// 14.6  the result arrives                               result
// 18.4  "↑ levels": back to the line at 16
// 20.2  tapping Prism on its side line opens its card
// 22.6  pack at rest                                     pack
// 24.6  "↑ menu", the line reels in to the float, tap it
// 27.0  settings at rest                                 settings
const DUR = 29600;
const SHOTS = AX ? { menu: 6400, play: 11800, result: 17600, prism: 40000 }
  : { 'menu-today': 1800, menu: 6400, play: 11800, result: 17600, pack: 23800, settings: 28600, prism: 40000 };

const CAM = {
  overview: 0,
  menu14: levelY(14) - FOCUS,
  menu1: levelY(1) - FOCUS,
  result: levelY(27) - FOCUS,
  menu16: levelY(16) - FOCUS,
  surface: -330,
};

function span(t, a, b, c, d) {
  if (RM) { const m1 = (a + b) / 2, m2 = (c + d) / 2; return ramp(t, m1 - 120, m1 + 120) * (1 - ramp(t, m2 - 120, m2 + 120)); }
  return ease(ramp(t, a, b)) * (1 - ease(ramp(t, c, d)));
}
function move(t, a, b, from, to, curve = ease) {
  if (RM) return t < (a + b) / 2 ? from : to;
  return mix(from, to, curve(ramp(t, a, b)));
}
function camera(t) {
  if (t >= 36000) return CAM.menu1;
  if (t < 3000) return CAM.overview;
  let y = move(t, 3000, 5200, CAM.overview, CAM.menu14);
  if (t >= 7000) y = move(t, 7000, 8700, CAM.menu14, CAM.menu1, settle);
  if (t >= 12600) y = move(t, 12800, 14600, CAM.menu1, CAM.result);
  if (t >= 18400) y = move(t, 18600, 20200, CAM.result, CAM.menu16, settle);
  if (t >= 24600) y = move(t, 24900, 26400, CAM.menu16, CAM.surface);
  return y;
}
const ov = (t) => t >= 36000 ? 0 : (RM ? (t < 3000 ? 1 : 0) : 1 - ease(ramp(t, 2950, 3500)));
const packMix = (t) => t >= 36000 ? 0 : span(t, 20600, 21600, 24700, 25400);
const nextLevel = (t) => t < 13000 ? 14 : 28;

// The world's own clock: it stops while a level or its result is on the screen, so the ground is a still frame there.
const FROZEN = [[10300, 12700], [15000, 18500]];
function clock(t) {
  if (RM || t >= 36000) return 0;
  let c = t;
  for (const [a, b] of FROZEN) c -= Math.max(0, Math.min(t, b) - a);
  return c;
}

// ---------------------------------------------------------------- the water
const shader = `
uniform float camY, ov, pk, tm, PM, TOP, pr;
float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float nz(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3. - 2. * f);
  return mix(mix(h1(i), h1(i + vec2(1, 0)), f.x), mix(h1(i + vec2(0, 1)), h1(i + vec2(1, 1)), f.x), f.y); }
float ovM(float y) { // the whole column on one screen: surface at 196, four tiers, then the deep
  if (y < 370.) return mix(-TOP / PM, 0., (y - 196.) / 174.);
  if (y < 530.) return (y - 370.) / 160. * 27.;
  if (y < 675.) return 27. + (y - 530.) / 145. * 27.;
  if (y < 790.) return 54. + (y - 675.) / 115. * 27.;
  if (y < 880.) return 81. + (y - 790.) / 90. * 27.;
  return 108. + (y - 880.) / 76. * 20.;
}
vec3 water(float m) { // plughole sea-glass, whirlpool heather, vortex ink blue, maelstrom ember, then the dark
  vec3 c = mix(vec3(.105, .30, .32), vec3(.030, .135, .160), smoothstep(-3., 10., m));
  c = mix(c, vec3(.105, .060, .165), smoothstep(23., 32., m));
  c = mix(c, vec3(.022, .042, .145), smoothstep(50., 59., m));
  c = mix(c, vec3(.120, .028, .040), smoothstep(77., 86., m));
  c = mix(c, vec3(.010, .006, .010), smoothstep(102., 124., m));
  return c;
}
void main() {
  vec2 p = uv * res;
  float mD = (camY + p.y - TOP) / PM;
  float m = mix(mD, ovM(p.y), ov);
  float sY = mix(-camY, 196., ov) + 2.6 * sin(p.x * .019 + tm * .0008) + 1.3 * sin(p.x * .047 - tm * .0011 + 1.3);
  vec3 col;
  if (p.y < sY) { // the air: a pale haze lying on the water, dark above
    float g = exp(-(sY - p.y) / 120.);
    col = vec3(.012, .018, .028) + vec3(.10, .21, .23) * g * .55;
  } else {
    col = water(m);
    float d = p.y - sY;
    float s = nz(vec2((p.x + d * .22) * .011 + tm * .00003, 1.7));
    col += vec3(.55, .85, .86) * smoothstep(.35, .9, s) * exp(-d / 420.) * .05;
    col += vec3(.32, .62, .64) * exp(-d / 70.) * .16;
  }
  col += vec3(.80, .96, 1.) * exp(-abs(p.y - sY) / 1.1) * .34;
  // a few motes sinking slowly, one layer
  vec2 q = vec2(p.x, p.y + mix(camY * .5, 0., ov) - tm * .004) / 92.;
  vec2 id = floor(q), f = fract(q) - .5;
  vec2 jo = vec2(h1(id), h1(id + 7.1)) - .5;
  float r = length((f - jo * .7) * 92.);
  col += vec3(.7, .92, .92) * smoothstep(1.1, 0., r) * step(.5, h1(id + 3.3)) * .14 * step(sY, p.y) * (1. - smoothstep(70., 125., m));
  // a pack's card and its levels: the same water, stilled and drained of colour
  vec3 still = vec3(.020, .025, .034) + vec3(.035, .042, .055) * (1. - uv.y);
  col = mix(col, still, max(pk * .9, pr * .9));
  vec2 e = uv - .5;
  col *= 1. - dot(e * vec2(1.05, .45), e * vec2(1.05, .45)) * .5;
  col += (h1(p + 3.) - .5) * .006;
  o = vec4(col, 1);
}`;

// ---------------------------------------------------------------- 2D helpers
let ctx;
let rects = [];
const AUDITED = new Set(Object.values(SHOTS));
function text(s, x, y, font, colour, align = 'left', spacing = 0) {
  ctx.font = font; ctx.fillStyle = colour; ctx.textAlign = align; ctx.textBaseline = 'alphabetic';
  ctx.letterSpacing = spacing + 'px';
  ctx.fillText(s, x, y);
  const m = ctx.measureText(s);
  ctx.letterSpacing = '0px';
  if (AX && ctx.globalAlpha > 0.05) {
    const x0 = align === 'left' ? x : align === 'right' ? x - m.width : x - m.width / 2;
    rects.push([x0, y - m.actualBoundingBoxAscent, x0 + m.width, y + m.actualBoundingBoxDescent, s]);
  }
  return m.width;
}
function audit(shot) {
  ctx.font = F.name(P('display'), 250);
  const wide = NAMES.filter(n => ctx.measureText(n).width + 16 + P('body') * 1.25 > 420);
  if (wide.length) console.error('ax title row too wide: ' + wide.join(', ')); // accessibility type: nothing off the screen, under the status bar or on another word
  const bad = [];
  rects.forEach((a, i) => {
    if (a[0] < 6 || a[2] > 434 || a[1] < 56 || a[3] > 950) bad.push(`"${a[4]}" off screen (${a.slice(0, 4).map(Math.round)})`);
    for (let j = i + 1; j < rects.length; j++) {
      const b = rects[j];
      if (a[0] < b[2] && b[0] < a[2] && a[1] < b[3] && b[1] < a[3]) bad.push(`"${a[4]}" over "${b[4]}"`);
    }
  });
  if (bad.length) console.error(`ax t=${shot}: ` + bad.join('; '));
}
function wrap(str, font, max) {
  ctx.font = font;
  const out = []; let line = '';
  for (const w of str.split(' ')) {
    const tryLine = line ? line + ' ' + w : w;
    if (ctx.measureText(tryLine).width > max && line) { out.push(line); line = w; } else line = tryLine;
  }
  if (line) out.push(line);
  return out;
}
function glow(x, y, r, a, rgb = '205, 245, 245') {
  const g = ctx.createRadialGradient(x, y, 0, x, y, r);
  g.addColorStop(0, `rgba(${rgb}, ${a})`);
  g.addColorStop(1, `rgba(${rgb}, 0)`);
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
}
function bead(x, y, r, a = 1) {
  ctx.fillStyle = ink(a);
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
}
function ring(x, y, r, a = 1, w = 1) {
  ctx.strokeStyle = ink(a); ctx.lineWidth = w;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke();
}
function marks(x, y, n, r = 3.2, gap = 9, a = 1) {
  for (let k = 0; k < 3; k++) {
    if (k < n) bead(x + k * gap, y, r, 0.9 * a); else ring(x + k * gap, y, r - 0.5, 0.6 * a);
  }
}
// The weight: a small plumb bob, its top at (x, y).
function bob(x, y, a = 1, s = 1) {
  glow(x, y + 9 * s, 30 * s, 0.22 * a);
  ctx.fillStyle = ink(0.96 * a);
  ctx.beginPath();
  ctx.moveTo(x - 4.4 * s, y + 5 * s);
  ctx.quadraticCurveTo(x - 4.4 * s, y + 0.5 * s, x, y + 0.5 * s);
  ctx.quadraticCurveTo(x + 4.4 * s, y + 0.5 * s, x + 4.4 * s, y + 5 * s);
  ctx.quadraticCurveTo(x + 3.4 * s, y + 12 * s, x, y + 19 * s);
  ctx.quadraticCurveTo(x - 3.4 * s, y + 12 * s, x - 4.4 * s, y + 5 * s);
  ctx.fill();
}
// A float: a slender quill standing in the surface. up 1 stands tall, 0 has sunk to its tip.
function float(x, y, up = 1, a = 1, s = 1) {
  const h = (3.2 + 7.8 * up) * s, cy = y + (4 - 6 * up) * s;
  if (up > 0.5) glow(x, cy - h * 0.7, 22 * s, 0.16 * a * up);
  ctx.strokeStyle = ink(0.7 * up * a); ctx.lineWidth = 0.8;
  ctx.beginPath(); ctx.moveTo(x, cy - h); ctx.lineTo(x, cy - h - 8 * s * up); ctx.stroke();
  if (up > 0.5) {
    ctx.fillStyle = ink(0.92 * a);
    ctx.beginPath(); ctx.ellipse(x, cy, 2.3 * s, h, 0, 0, Math.PI * 2); ctx.fill();
  } else { // sunk: only its crown shows, unlit
    ctx.strokeStyle = ink(0.62 * a); ctx.lineWidth = 1;
    ctx.beginPath(); ctx.ellipse(x, cy, 2.3 * s, h, 0, 0, Math.PI * 2); ctx.stroke();
  }
}
// A glass crop, untouched, at the alpha of whatever it is drawn within.
function disc(name, x, y, d, k = 1) { World.disc(ctx, name, x, y, d, ctx.globalAlpha * k); }
function finger(x, y, a, press = 0) {
  if (a <= 0) return;
  glow(x, y, 46, 0.12 * a, '255, 255, 255');
  ctx.fillStyle = `rgba(255, 255, 255, ${(0.16 + press * 0.1) * a})`;
  ctx.beginPath(); ctx.arc(x, y, 21 - press * 3, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = `rgba(255, 255, 255, ${0.4 * a})`; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.arc(x, y, 21 - press * 3, 0, Math.PI * 2); ctx.stroke();
}
const under = (y) => AX ? ramp(y, 70, 130) : ramp(y, 58, 104);
const wavy = (x, c) => 2.6 * Math.sin(x * 0.019 + c * 0.0008) + 1.3 * Math.sin(x * 0.047 - c * 0.0011 + 1.3);

// The line's path in the dive: a long slow lean that never runs plumb-straight, plus a sway that grows with depth.
const LINE = AX ? { x: 78, a: 7, b: 3 } : { x: 204, a: 24, b: 9 };
function LX(wy, c) {
  const sway = RM ? 0 : Math.min(4.5, 1.2 + wy * 0.0007) * Math.sin(c * 0.0008 - wy * 0.0027);
  return LINE.x + LINE.a * Math.sin(wy * 0.0021 + 0.9) + LINE.b * Math.sin(wy * 0.0052 + 2.1) + sway * Math.min(1, wy / 300);
}
// The line across the overview, where the whole column is one screen.
function OX(y, c) {
  const d = Math.max(0, y - 196);
  return 204 + 22 * Math.sin(y * 0.0058 + 0.2) + 6 * Math.sin(y * 0.0141 + 1) + (RM ? 0 : 2.2 * Math.sin(c * 0.0008 - y * 0.006)) * Math.min(1, d / 200);
}
const GHOST = 0.15;   // the line below the weight: not yet paid out, there only as a trace
function strand(fx, y0, y1, a, w = 0.9) { // a stroke along x = fx(y), faded in under the status bar
  if (y1 <= y0 || a <= 0) return;
  const g = ctx.createLinearGradient(0, 56, 0, 112);
  g.addColorStop(0, ink(0)); g.addColorStop(1, ink(a));
  ctx.strokeStyle = g; ctx.lineWidth = w; ctx.lineCap = 'round';
  ctx.beginPath();
  for (let y = y0; y < y1; y += 6) { if (y === y0) ctx.moveTo(fx(y), y); else ctx.lineTo(fx(y), y); }
  ctx.lineTo(fx(y1), y1);
  ctx.stroke();
}
function sag(x0, y0, x1, y1, drop, a) { // a side line: slack between two points
  ctx.strokeStyle = ink(a); ctx.lineWidth = 0.8; ctx.lineCap = 'round';
  ctx.beginPath(); ctx.moveTo(x0, y0);
  ctx.quadraticCurveTo((x0 + x1) / 2, Math.max(y0, y1) + drop, x1, y1);
  ctx.stroke();
}

// ---------------------------------------------------------------- scenes
// The whole column on one screen.
function overview(t, a) {
  if (a <= 0) return;
  const c = clock(t);
  ctx.save(); ctx.globalAlpha = a;
  text('UNSTIR', 32, 128, `200 ${P('display')}px UPro`, INK, 'left', 11);
  const X = (y) => OX(y, c);
  const sY = 196 + wavy(X(196), c);
  // the bands' knots: 27 to a tier
  const tiers = [
    { name: 'plughole', y0: 370, y1: 530, note: '13 of 27 at par', done: 13, nameA: 0.95 },
    { name: 'whirlpool', y0: 530, y1: 675, note: 'opens with every plughole level solved', done: 0, nameA: 0.6 },
    { name: 'vortex', y0: 675, y1: 790, note: 'opens with every whirlpool level solved', done: 0, nameA: 0.6 },
    { name: 'maelstrom', y0: 790, y1: 880, note: 'opens with every vortex level solved', done: 0, nameA: 0.6 },
  ];
  const knotY = (tr, k) => tr.y0 + 14 + (tr.y1 - tr.y0 - 22) * k / 26;
  const tipY = knotY(tiers[0], 13);
  strand(X, tipY, 904, GHOST);
  strand(X, sY + 4, tipY, 0.62);
  float(X(196), sY, 1, 1, 1.15);
  text('settings', X(196) + 22, sY - 14, F.ui(P('detail')), ink(0.7));
  tiers.forEach((tr) => {
    for (let k = 0; k < 27; k++) {
      const y = knotY(tr, k), x = X(y);
      if (k < tr.done) bead(x, y, 1.5, 0.92); else if (!(tr.done && k === tr.done)) bead(x, y, 1, tr.done ? 0.42 : 0.26);
    }
    const ny = tr.y0 + 44, nx = X(ny - 8) + 30;
    text(tr.name, nx, ny, F.word(P('title')), ink(tr.nameA));
    wrap(tr.note, F.ui(P('detail')), 426 - nx).forEach((ln, i) =>
      text(ln, nx + 1, ny + 23 + i * 18, F.ui(P('detail')), ink(tr.done ? 0.7 : 0.5)));
  });
  bead(X(tipY), tipY, 3.4, 1);
  bob(X(tipY), tipY + 3, 1, 0.8);
  // today, the first bead under the float
  const ty = 258, tx = X(ty);
  glow(tx, ty, 34, 0.2, '255, 240, 210');
  bead(tx, ty, 5, 1);
  text('today', tx + 30, ty + 8, F.word(P('title')), INK);
  text('daily · Mon 23 Nov', tx + 30, ty + 33, F.ui(P('body')), ink(0.88));
  const w = text('4 days running', tx + 30, ty + 55, F.data(P('detail')), ink(0.66));
  marks(tx + 30 + w + 14, ty + 51, 2);
  ring(X(338), 338, 2.6, 0.7);
  text('archive', X(338) + 30, 344, F.ui(P('body')), ink(0.74));
  text('comes with any pack', X(338) + 30, 363, F.ui(P('detail')), ink(0.5));
  // packs on their side lines
  const hung = [[404, 0], [550, 1], [692, 2], [792, 3]];
  hung.forEach(([y, i]) => {
    const pk = PACKS[i];
    const px = 62 + (i % 2) * 14, py = y + 34 + (RM ? 0 : 1.5 * Math.sin(c * 0.0009 + i * 2));
    sag(X(y), y, px, py - 15, 5, i ? 0.24 : 0.42);
    disc('cover-' + pk.id, px, py, 30);
    text(pk.name, px, py + 31, F.ui(P('detail')), ink(0.66), 'center');
  });
  text('packs · paid add-ons', 32, 908, F.ui(P('detail')), ink(0.6));
  text('first 3 levels of each free', 32, 926, F.ui(P('detail')), ink(0.46));
  // endless, where the column runs out of light
  const ey = 908;
  ring(X(ey), ey, 3.2, 0.6);
  text('endless', X(ey) + 30, ey + 6, F.word(P('title')), ink(0.82));
  text('best 9 tanks', X(ey) + 31, ey + 28, F.data(P('detail')), ink(0.6));
  ctx.restore();
}

// The dive: the line, its beads and the weight at its tip. rows 0 hides the levels (settings keeps only the line).
function dive(t, cam, a, rows = 1) {
  if (a <= 0) return;
  const c = clock(t);
  const next = nextLevel(t);
  const tipW = Math.min(cam + FOCUS, levelY(Math.min(next, 27)));
  const focus = (tipW - TOP) / PM;
  const X = (sy) => LX(sy + cam, c);
  ctx.save(); ctx.globalAlpha = a;
  const sY = -cam + wavy(X(-cam), c);
  strand(X, Math.max(tipW - cam + 20, 40), Math.min(980, levelY(29) - cam), GHOST * rows);
  strand(X, Math.max(sY + 4, 40), tipW - cam + 20, 0.6);
  if (sY > -40) float(X(-cam), sY, 1, under(sY + 30), 1.15);
  bob(X(tipW - cam + 20), tipW - cam + 20, under(tipW - cam));
  const lab = (s, m, note) => {
    const y = levelY(m) - cam;
    if (y < 40 || y > 1000) return;
    ctx.save(); ctx.globalAlpha = a * rows * under(y - P('title'));
    text(s, X(y) + (AX ? 30 : 34), y, F.word(P('title')), ink(0.62));
    if (note) wrap(note, F.ui(P('detail')), 440 - X(y) - 52).forEach((ln, i) =>
      text(ln, X(y) + (AX ? 31 : 35), y + P('detail') * 1.75 + i * P('detail') * 1.35, F.ui(P('detail')), ink(0.5)));
    ctx.restore();
  };
  lab('plughole', 0.25);
  lab('whirlpool', 27.85, next > 27 ? '' : 'opens with every plughole level solved');
  const gapN = AX ? 20 : 22, gapT = AX ? 24 : 28;
  for (let n = 1; n <= 27; n++) {
    const y = levelY(n) - cam;
    if (y < 20 || y > 1010) continue;
    const u = under(y - (AX ? 60 : 20)) * rows * (1 - ramp(y, AX ? 850 : 900, AX ? 900 : 956));
    if (u <= 0) continue;
    const x = X(y);
    const far = 1 - 0.42 * ramp(Math.abs(n - focus), 0.6, 3.6);   // the water takes what is far from the weight
    ctx.save(); ctx.globalAlpha = a * u;
    const b = P('body');
    if (n === next) {
      const ti = P('title') * 1.2;
      glow(x, y, 46, 0.2);
      bead(x, y, 6.2, 1);
      text(two(n), x - gapN, y + b * 0.35, F.data(b), ink(0.78), 'right');
      text(NAMES[n - 1], x + gapT, y + ti * 0.35, F.name(ti, 250), INK);
      text('4 rods · par 4', x + gapT + 1, y + ti * 0.35 + P('label') * 1.6, F.data(P('label')), ink(0.7));
    } else if (n < next) {
      bead(x, y, 2.8, 0.95 * far);
      text(two(n), x - gapN, y + b * 0.35, F.data(b), ink(0.5 * far), 'right');
      const w = text(NAMES[n - 1], x + gapT, y + b * 0.35, F.ui(b, 350), ink(0.88 * far));
      marks(x + gapT + w + (AX ? 20 : 14), y, 2, AX ? 5 : 3, AX ? 15 : 9.5, far);
    } else {
      ring(x, y, 2.6, 0.5 * far);
      text(two(n), x - gapN, y + b * 0.35, F.data(b), ink(0.34 * far), 'right');
      text(NAMES[n - 1], x + gapT, y + b * 0.35, F.ui(b, 350), ink(0.5 * far));
    }
    ctx.restore();
  }
  PACKS.forEach((pk, i) => {
    const ky = levelY(pk.m) - cam;
    if (ky < -140 || ky > 1020) return;
    const hung = levelY(pk.m) < tipW + 20;
    const drift = RM ? 0 : Math.sin(c * 0.0007 + i * 1.7);
    const px = PACK_X + 2.5 * drift, py = ky + PACK_DROP + 1.5 * drift;
    const u = under(py - 30) * rows;
    ctx.save(); ctx.globalAlpha = a * u;
    sag(X(ky), ky, px + (AX ? -8 : 8), py - PACK_D / 2 - 1, 7, hung ? 0.45 : 0.24);
    bead(X(ky), ky, 1.5, hung ? 0.8 : 0.4);
    disc('cover-' + pk.id, px, py, PACK_D, hung ? 1 : 0.86);
    text(pk.name, px, py + PACK_D / 2 + P('detail') * 1.3, F.ui(P('detail')), ink(hung ? 0.72 : 0.6), 'center');
    ctx.restore();
  });
  ctx.restore();
}

// A level: its tank hangs where the weight was, on the same line. The line stops at the rim.
const TANK_PLAY = AX ? { x: 220, y: 296, d: 240 } : { x: 220, y: 474, d: 403 };
const TANK_RESULT = AX ? { x: 220, y: 246, d: 170 } : { x: 220, y: 396, d: 364 };
const hangX = (T) => (y) => { const u = Math.max(0, T.y - T.d / 2 - y); return T.x + 0.035 * u + 0.00042 * u * u; };
function hang(T, a) { strand(hangX(T), 40, T.y - T.d / 2 - 1, 0.6 * a); }
function titleRow(T, y, num, name, a, white = false) {
  ctx.save(); ctx.globalAlpha = a;
  const up = (P('display') - P('body')) * 0.16, col = white ? '#ffffff' : ink(0.72);
  if (AX) { // the longest names don't fit beside the line at these sizes: one centred row under the glass
    ctx.font = F.data(P('body')); const nw = ctx.measureText(num).width;
    ctx.font = F.name(P('display'), 250); const x = 220 - (nw + 16 + ctx.measureText(name).width) / 2;
    text(num, x, y - up, F.data(P('body')), col);
    text(name, x + nw + 16, y, F.name(P('display'), 250), INK);
  } else {
    const x = hangX(T)(y - P('display') * 0.3);
    text(num, x - 20, y - up, F.data(P('body')), col, 'right');
    text(name, x + 22, y, F.name(P('display'), 250), INK);
  }
  ctx.restore();
}
function playChrome(a, o) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const T = o.tank;
  text(o.back, 28, AX ? 112 : 96, F.ui(P('body')), ink(0.8));
  if (!AX) text(o.count, 412, 96, F.data(P('label')), ink(0.7), 'right');
  titleRow(T, AX ? T.y + T.d / 2 + 66 : T.y - T.d / 2 - 62, o.num, o.title, a, o.prism);
  let y = T.y + T.d / 2 + (AX ? 176 : 50);
  if (AX) text(o.count, 220, y - 60, F.data(P('label')), ink(0.7), 'center');
  const lines = AX ? wrap(o.note.join(' '), F.word(P('body')), 392) : o.note;
  for (const line of lines) { text(line, 220, y, F.word(P('body')), ink(0.8), 'center'); y += AX ? 47 : 26; }
  const cy = AX ? 912 : 890;
  text(o.undo, 30, cy, F.ui(P('body')), ink(0.5));
  text('reset', 410, cy, F.ui(P('body')), ink(0.86), 'right');
  ctx.restore();
}
function tank(name, T, a, s = 1) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  glow(T.x, T.y, T.d * s * 0.6, 0.1);
  disc(name, T.x, T.y, T.d * s);
  ctx.restore();
}

function resultScene(t, a, t0) {
  if (a <= 0) return;
  const T = TANK_RESULT;
  hang(T, a);
  ctx.save(); ctx.globalAlpha = a;
  text('↑ levels', 28, AX ? 112 : 96, F.ui(P('body')), ink(0.8));
  ctx.restore();
  titleRow(T, AX ? T.y + T.d / 2 + 62 : T.y - T.d / 2 - 56, '27', 'Drain', a);
  const arr = (k) => a * (RM ? 1 : ease(ramp(t, t0 + 300 + k * 260, t0 + 1000 + k * 260)));
  const sink = (k) => RM ? 0 : (1 - settle(ramp(t, t0 + 300 + k * 260, t0 + 1500 + k * 260))) * -14;  // each settles down into place
  let y = T.y + T.d / 2 + (AX ? 102 : 40);
  ctx.save(); ctx.globalAlpha = arr(0);
  const r = AX ? 8 : 5.6, g = AX ? 34 : 25;
  [0, 1, 2].forEach((k) => { const x = 220 + (k - 1) * g; if (k < 2) { glow(x, y + sink(0), 18, 0.2); bead(x, y + sink(0), r, 0.96); } else ring(x, y + sink(0), r - 0.6, 0.7, 1.1); });
  ctx.restore();
  y += AX ? 70 : 62;
  ctx.save(); ctx.globalAlpha = arr(1);
  text('unstirred.', 220, y + sink(1), F.word(P('display')), INK, 'center');
  ctx.restore();
  ctx.save(); ctx.globalAlpha = arr(2);
  const rows = [['at par · new best, was +6', F.ui(P('body')), 0.92, P('body')], ['moves 9 · par 9', F.data(P('label')), 0.66, P('label')],
    ['clean needs no undo or reset', F.ui(P('detail')), 0.56, P('detail')]];
  y += AX ? 14 : 12;
  for (const [s, font, al, size] of rows) {
    for (const ln of wrap(s, font, 396)) { y += size * (AX ? 1.2 : 1.55); text(ln, 220, y + sink(2), font, ink(al), 'center'); }
    y += AX ? 6 : 2;
  }
  ctx.restore();
  ctx.save(); ctx.globalAlpha = arr(3);
  const by = AX ? 918 : 890;
  text('again', 30, by, F.ui(P('body')), ink(0.78));
  text('up a notch', 410, by - (AX ? 60 : 30), F.word(P('label')), ink(0.62), 'right');
  text('whirlpool ›', 410, by, F.name(P('title')), INK, 'right');
  ctx.restore();
}

// A pack's card: its cover hangs on its side line, its words below in still water.
const PACK_T = { x: 220, y: 286, d: 262 };
function packLine(T, a) {
  ctx.strokeStyle = ink(0.5 * a); ctx.lineWidth = 0.9; ctx.lineCap = 'round';
  ctx.beginPath(); ctx.moveTo(452, 62);
  ctx.quadraticCurveTo(T.x + 118, T.y - T.d / 2 - 22, T.x + 14, T.y - T.d / 2 - 0.5);
  ctx.stroke();
}
function packScene(t, a, t0) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const arr = (k) => RM ? 1 : ease(ramp(t, t0 + 500 + k * 130, t0 + 1200 + k * 130));
  const sink = (k) => RM ? 0 : (1 - settle(ramp(t, t0 + 500 + k * 130, t0 + 1500 + k * 130))) * -12;
  text('↑ menu', 28, 96, F.ui(P('body')), ink(0.8));
  const line = (k, s, y, font, colour) => { ctx.save(); ctx.globalAlpha = a * arr(k); text(s, 220, y + sink(k), font, colour, 'center'); ctx.restore(); };
  line(0, 'Prism', 486, F.name(P('display') * 1.18, 200), '#ffffff');
  line(1, 'each rod stirs only some colours', 520, F.word(P('body')), ink(0.86));
  line(2, 'after plughole · reading by colour', 572, F.ui(P('label')), ink(0.8));
  line(2, '30 specimens in five trays', 596, F.ui(P('label')), ink(0.8));
  line(2, 'levels 1–3 free, no purchase', 620, F.ui(P('label')), ink(0.8));
  line(3, 'letters for colour-blind play, in settings', 648, F.ui(P('detail')), ink(0.56));
  ctx.save(); ctx.globalAlpha = a * arr(4);
  const by = 716 + sink(4);
  glow(78, by - 6, 26, 0.24); bead(78, by - 6, 5.6, 1);
  text('buy $2.99', 96, by, F.ui(P('body'), 600), '#ffffff');
  text('try 3 free ›', 366, by, F.ui(P('body')), ink(0.86), 'right');
  text('or all three in Triptych I · $5.99 · save $2.98 ›', 220, by + 36, F.ui(P('detail')), ink(0.6), 'center');
  ctx.restore();
  // its 30 specimens, six to a tray, each tray settled a little lower than the last; the three free ones lit
  ctx.save(); ctx.globalAlpha = a * arr(5);
  for (let tray = 0; tray < 5; tray++) for (let k = 0; k < 6; k++) {
    const i = tray * 6 + k;
    const x = 60 + tray * 72 + k * 9, y = 822 + 5 * Math.sin((k + 0.5) / 6 * Math.PI) + sink(5);
    if (i < 3) { glow(x, y, 9, 0.3); bead(x, y, 2.4, 1); } else bead(x, y, 1.6, 0.36);
  }
  text('restore purchases', 220, 908, F.ui(P('detail')), ink(0.6), 'center');
  ctx.restore();
  ctx.restore();
}

// Settings: the surface, where the float is. A switch is a small float of its own: standing is on, sunk is off.
function settingsScene(t, a, t0, cam) {
  if (a <= 0) return;
  const c = clock(t);
  ctx.save(); ctx.globalAlpha = a;
  const sY = -cam;
  const arr = (k) => RM ? 1 : ease(ramp(t, t0 + k * 140, t0 + 700 + k * 140));
  ctx.save(); ctx.globalAlpha = a * arr(0);
  text('settings', 32, 176, F.word(P('display')), INK);
  ctx.restore();
  const floats = [['music', true, 58, 52], ['sounds', true, 132, 98], ['haptics', true, 304, 52], ['colour letters', false, 370, 98]];
  floats.forEach(([name, on, x, dy], k) => {
    const up = (on ? 1 : 0) * (RM ? 1 : settle(ramp(t, t0 + 200 + k * 150, t0 + 1300 + k * 150)));
    const y = sY + wavy(x, c);
    ctx.save(); ctx.globalAlpha = a * arr(k + 1);
    float(x, y, up, 1, 0.9);
    text(name, x, sY + dy, F.ui(P('body')), ink(on ? 0.95 : 0.72), 'center');
    text(on ? 'on' : 'off', x, sY + dy + 21, F.data(P('detail')), ink(0.6), 'center');
    ctx.restore();
  });
  ctx.save(); ctx.globalAlpha = a * arr(5);
  const lx = LX(140 + 20, c);
  text('↓ levels', lx + 20, sY + 172, F.ui(P('body')), ink(0.8));
  text('restore purchases', 44, sY + 286, F.ui(P('body')), ink(0.86));
  text('report a problem ↗', 396, sY + 356, F.ui(P('body')), ink(0.86), 'right');
  text('privacy policy ↗', 76, sY + 426, F.ui(P('body')), ink(0.86));
  text('Unstir 1.0 (1)', 396, sY + 520, F.data(P('detail')), ink(0.5), 'right');
  ctx.restore();
  ctx.restore();
}

// ---------------------------------------------------------------- the film's fingertip
const PRISM_AT = { x: PACK_X, y: levelY(16.5) - CAM.menu16 + PACK_DROP };
const TOUCHES = [
  [2100, 2700, 3000, 236, 452, 236, 452],     // the weight, on the overview
  [6700, 7000, 8500, 300, 360, 300, 860],     // draw the water down: rise
  [8400, 8800, 9100, LX(levelY(1), 0) + 30, FOCUS, LX(levelY(1), 0) + 30, FOCUS], // Drop
  [18000, 18350, 18600, 58, 92, 58, 92],      // ↑ levels
  [19900, 20300, 20600, PRISM_AT.x, PRISM_AT.y, PRISM_AT.x, PRISM_AT.y],
  [24200, 24500, 24800, 58, 92, 58, 92],      // ↑ menu
  [26300, 26600, 26900, LX(0, 0), 326, LX(0, 0), 326], // the float
];
function touches(t) {
  if (RM) return;
  for (const [a, p, l, x0, y0, x1, y1] of TOUCHES) {
    if (t < a - 300 || t > l + 400) continue;
    const show = ease(ramp(t, a - 300, a)) * (1 - ease(ramp(t, l, l + 400)));
    const k = ease(ramp(t, p, l));
    const press = x0 === x1 && y0 === y1 ? Math.sin(Math.PI * ramp(t, p - 120, p + 260)) : 0.4 * ramp(t, a, p);
    finger(mix(x0, x1, k), mix(y0, y1, k), show, Math.max(0, press));
  }
}

let status$;
function statusBar() {
  if (!status$) {
    const im = World.images.status;
    status$ = document.createElement('canvas');
    status$.width = im.width; status$.height = im.height;
    const c = status$.getContext('2d');
    c.drawImage(im, 0, 0);
    const d = c.getImageData(0, 0, im.width, im.height);
    for (let i = 0; i < d.data.length; i += 4) {
      const a = Math.max(d.data[i], d.data[i + 1], d.data[i + 2]);
      if (a > 0) for (let k = 0; k < 3; k++) d.data[i + k] = Math.min(255, d.data[i + k] * 255 / a);
      d.data[i + 3] = a;
    }
    c.putImageData(d, 0, 0);
  }
  ctx.drawImage(status$, 0, 0, 440, 54);
}

// ---------------------------------------------------------------- the frame
function draw(c, t) {
  ctx = c; rects = [];
  const cam = camera(t);
  if (t >= 36000) { prismLevel(); if (AX && AUDITED.has(t)) audit(t); return; }
  overview(t, ov(t));
  const sA = span(t, 26500, 27000, 99999, 99999);
  const menuA = t < 3000 ? 0 : span(t, 3250, 4100, 8800, 9500) + 0.8 * span(t, 12700, 13200, 14300, 14800)
    + span(t, 18700, 19400, 20500, 21200) + span(t, 24700, 25300, 99999, 99999);
  dive(t, cam, Math.min(1, menuA), 1 - sA);
  // play: the weight opens into Drop's tank, still on the line
  const openK = RM ? (t >= 9550 ? 1 : 0) : settle(ramp(t, 8900, 10200));
  const playA = t >= 8900 && t < 13600 ? (RM ? span(t, 9200, 9900, 12700, 13300) : ease(ramp(t, 8900, 9300)) * (1 - ease(ramp(t, 12700, 13300)))) : 0;
  if (playA > 0) {
    const src = { x: LX(levelY(1), 0), y: FOCUS + 28 };
    const T = { x: mix(src.x, TANK_PLAY.x, openK), y: mix(src.y, TANK_PLAY.y, openK), d: TANK_PLAY.d * mix(0.04, 1, openK) };
    const chromeA = playA * (RM ? 1 : ease(ramp(t, 9700, 10500)));
    hang(TANK_PLAY, chromeA);
    tank('play01', T, playA);
    playChrome(chromeA, { tank: TANK_PLAY, back: '↑ levels', num: '01', title: 'Drop', count: 'moves 0 / par 1',
      note: ['Turn a rod to look. Let go where', 'you started and nothing happens.'], undo: 'undo · 10' });
  }
  const resA = span(t, 14500, 15000, 18700, 19300);
  if (resA > 0) {
    tank('drain-solved', TANK_RESULT, resA * (RM ? 1 : ease(ramp(t, 14500, 15100))));
    resultScene(t, resA, 14600);
  }
  // Prism's card: its cover swings in from where it hung
  const pA = packMix(t);
  if (pA > 0) {
    const k = RM ? 1 : settle(ramp(t, 20600, 21900));
    const T = { x: mix(PRISM_AT.x, PACK_T.x, k), y: mix(PRISM_AT.y, PACK_T.y, k), d: mix(PACK_D, PACK_T.d, k) };
    ctx.save(); ctx.globalAlpha = pA;
    packLine(T, RM ? 1 : ease(ramp(t, 21200, 22000)));
    disc('prism-clip', T.x, T.y, T.d);
    ctx.restore();
    packScene(t, pA, 21000);
  }
  settingsScene(t, sA, 26600, cam);
  touches(t);
  statusBar();
  if (AX && AUDITED.has(t)) audit(t);
}

// Prism 01 in play: still, colourless water; its number white, never one channel's colour.
function prismLevel() {
  hang(TANK_PLAY, 1);
  tank('prism01', TANK_PLAY, 1);
  playChrome(1, { tank: TANK_PLAY, back: '↑ Prism', num: '01', title: 'Frond', count: 'moves 0 / par 3', prism: true,
    note: ['Each rod stirs only its knob’s colours.'], undo: 'undo · 10' });
  statusBar();
}

window.DRAWS_AX = true;
World.load(['play01', 'drain-solved', 'prism01', 'prism-clip', 'cover-lens', 'cover-escapement', 'cover-prism',
  'cover-triptych', 'status']).then(() => World.start({
  fonts: ['300 28px UPro', 'italic 300 28px NY', '400 13px UMono', '600 17px UPro', '200 40px UPro', '250 34px UPro', '350 17px UPro'],
  shader,
  uniforms: (t) => ({ camY: camera(t), ov: ov(t), pk: packMix(t), tm: clock(t), PM, TOP, pr: t >= 36000 ? 1 : 0 }),
  draw,
  duration: DUR,
  shots: SHOTS,
}));
