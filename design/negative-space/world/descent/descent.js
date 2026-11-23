// Copyright © 2026 Jack Lusher. All rights reserved.
// The Descent: the game seen as one column of water. The surface is at the top, each level hangs at its own depth
// in metres, and the tiers are the water getting deeper and darker. The ground is one shader pass (water by depth,
// light shafts from the surface, drifting motes in three parallax layers); lanterns, type and glass are 2D on top.
// Nothing here stirs: the UI moves by sinking, rising, drifting and settling.

const { ramp, ease, settle, mix } = World;
const RM = World.rm, AX = World.ax;
const PM = AX ? 196 : 110;            // points per metre in the dive: the gap between two levels
const TOP = 420;                      // world y of 0 m; the surface (world y 0) sits 3.8 m above level 1
const levelY = (m) => TOP + m * PM;
const NAMES = ['Drop', 'Drip', 'Trickle', 'Ripple', 'Bubble', 'Fizz', 'Sprinkle', 'Mist', 'Spray', 'Splash', 'Puddle',
  'Froth', 'Suds', 'Lather', 'Steam', 'Gurgle', 'Rinse', 'Drizzle', 'Shower', 'Downpour', 'Overflow', 'Bathwater',
  'Spin', 'Whirl', 'Spiral', 'Last drop', 'Drain'];
const NEXT = 14;
const laneX = (n) => (AX ? 58 : 118) + (AX ? 16 : 46) * Math.sin(n * 0.85 + 0.6);

const INK = '#edeff7';
const ink = (a) => `rgba(237, 239, 247, ${a})`;
const F = {
  name: (s) => `300 ${s}px UPro`,
  word: (s) => `italic 300 ${s}px NY`,
  data: (s) => `400 ${s}px UMono`,
  ui: (s, w = 400) => `${w} ${s}px UPro`,
};

// Packs drift as portholes at the lane's far side, each at its own depth.
const PACKS = [
  { id: 'lens', name: 'Lens', m: 6.6, x: 392, glow: '255, 43, 214' },
  { id: 'escapement', name: 'Escapement', m: 11.4, x: 380, glow: '255, 120, 90' },
  { id: 'prism', name: 'Prism', m: 16.5, x: 390, glow: '200, 220, 255' },
  { id: 'triptych', name: 'Triptych I', m: 21.6, x: 382, glow: '255, 200, 120' },
];

// ---------------------------------------------------------------- the timeline
// Long moves ease out; short ones settle with a small overshoot, as a body finds its depth.
// 0     the whole dive at rest (overview)          menu-today
// 2.6   a finger taps plughole; the view sinks to 14 m
// 5.2   the dive at 14 m at rest                     menu
// 7.0   a finger draws the water down: rise to 1 m
// 8.9   tapping Drop opens its tank
// 10.4  play at rest                                 play
// 12.6  later, deeper: sink to 27 m
// 14.6  the result arrives                           result
// 18.4  "↑ levels": rise to 15 m
// 20.2  tapping Prism's porthole opens its card
// 22.6  pack at rest                                 pack
// 24.6  "↑ menu", rise to the surface, tap the buoy
// 27.0  settings at rest                             settings
const DUR = 29600;
const SHOTS = AX ? { menu: 6400, play: 11800 } : { 'menu-today': 1800, menu: 6400, play: 11800, result: 17600, pack: 23800, settings: 28600, prism: 40000 };

const CAM = {
  overview: 0,
  menu14: levelY(14) - 470,
  menu1: levelY(1) - 470,
  play: levelY(1) - 474,
  result: levelY(27) - 467,
  menu15: levelY(15.6) - 470,
  surface: -330,
};

// Each element's presence 0..1 over the timeline. Under Reduce Motion, moves become cuts at their midpoint and
// arrivals become short fades.
function span(t, a, b, c, d) { // fades in over a..b, out over c..d
  if (RM) { const mid1 = (a + b) / 2, mid2 = (c + d) / 2; return ramp(t, mid1 - 120, mid1 + 120) * (1 - ramp(t, mid2 - 120, mid2 + 120)); }
  return ease(ramp(t, a, b)) * (1 - ease(ramp(t, c, d)));
}
function move(t, a, b, from, to, curve = ease) {
  if (RM) return t < (a + b) / 2 ? from : to;
  return mix(from, to, curve(ramp(t, a, b)));
}

function camera(t) {
  if (t < 3000) return CAM.overview;
  let y = move(t, 3000, 5200, CAM.overview, CAM.menu14);
  if (t >= 7000) y = move(t, 7000, 8700, CAM.menu14, CAM.menu1, (x) => settle(x));
  if (t >= 8700) y = move(t, 8900, 10200, CAM.menu1, CAM.play);
  if (t >= 12600) y = move(t, 12800, 14600, CAM.play, CAM.result);
  if (t >= 18400) y = move(t, 18600, 20200, CAM.result, CAM.menu15, (x) => settle(x));
  if (t >= 24600) y = move(t, 24900, 26400, CAM.menu15, CAM.surface);
  if (t >= 36000) y = t >= 39000 ? CAM.play : y; // the Prism level, off the film
  return y;
}
const ov = (t) => t >= 36000 ? 0 : (RM ? (t < 3000 ? 1 : 0) : 1 - ease(ramp(t, 2950, 3500)));
const packMix = (t) => t >= 36000 ? 0.62 : span(t, 20600, 21600, 24700, 25400);
const prismMix = (t) => t >= 36000 ? 1 : 0;

// ---------------------------------------------------------------- the water
const shader = `
uniform float camY, ov, pk, tm, PM, shaft, pr;
uniform vec2 pkC;
float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float nz(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3. - 2. * f);
  return mix(mix(h1(i), h1(i + vec2(1, 0)), f.x), mix(h1(i + vec2(0, 1)), h1(i + vec2(1, 1)), f.x), f.y); }
float ovM(float y) { // the whole dive compressed onto one screen: surface 196, then the four tiers, then the abyss
  if (y < 370.) return mix(-3.8, 0., (y - 196.) / 174.);
  if (y < 530.) return (y - 370.) / 160. * 27.;
  if (y < 675.) return 27. + (y - 530.) / 145. * 27.;
  if (y < 790.) return 54. + (y - 675.) / 115. * 27.;
  if (y < 880.) return 81. + (y - 790.) / 90. * 27.;
  return 108. + (y - 880.) / 76. * 20.;
}
vec3 water(float m) {
  vec3 c = mix(vec3(.055, .25, .29), vec3(.016, .12, .155), smoothstep(-3.8, 9., m));
  c = mix(c, vec3(.11, .025, .16), smoothstep(24., 31., m));
  c = mix(c, vec3(.018, .035, .15), smoothstep(51., 58., m));
  c = mix(c, vec3(.11, .012, .02), smoothstep(78., 85., m));
  c = mix(c, vec3(.008, .004, .006), smoothstep(102., 122., m));
  return c;
}
void main() {
  vec2 p = uv * res;
  float mD = (camY + p.y - 420.) / PM;
  float m = mix(mD, ovM(p.y), ov);
  float sY = mix(-camY, 196., ov) + 3.5 * sin(p.x * .024 + tm * .0011) + 2. * sin(p.x * .063 - tm * .0016 + 1.3);
  vec3 col;
  if (p.y < sY) {
    float g = exp(-(sY - p.y) / 70.);
    col = vec3(.008, .012, .026) + vec3(.06, .2, .22) * g * .5;
  } else {
    col = water(m);
    float d = p.y - sY;
    float sx = p.x + d * .3 + tm * .004;
    float s = nz(vec2(sx * .016, 1.7)) * nz(vec2(sx * .041 + 9., tm * .00012));
    s = smoothstep(.12, .55, s) * exp(-max(m + 3.8, 0.) / 8.) * shaft;
    col += vec3(.5, .85, .88) * s * .11;
    col += vec3(.25, .62, .66) * exp(-d / 44.) * .2;
    col += vec3(.7, .95, 1.) * exp(-abs(p.y - sY) / 1.3) * .55;
  }
  // drifting motes, three parallax layers rising slowly
  for (int k = 0; k < 3; k++) {
    float fk = float(k);
    float par = .35 + fk * .3;
    float cell = 46. + fk * 22.;
    vec2 q = vec2(p.x + fk * 37., p.y + mix(camY * par, 0., ov) + tm * (.006 + fk * .004)) / cell;
    vec2 id = floor(q), f = fract(q) - .5;
    vec2 jo = vec2(h1(id), h1(id + 7.1)) - .5;
    float r = length((f - jo * .7) * cell);
    float b = smoothstep(.7 + fk * .5, 0., r) * step(.55, h1(id + 3.3));
    col += vec3(.6, .9, .9) * b * (.10 + fk * .07) * step(sY, p.y) * (1. - smoothstep(60., 125., m));
  }
  // a pack's waters: neutral and still, lit by its porthole's light split into three
  vec3 still = vec3(.02, .024, .036) + vec3(.03, .035, .05) * (1. - uv.y);
  vec2 v = p - pkC;
  float ang = atan(v.x, v.y);
  float fall = smoothstep(0., 40., v.y) * exp(-length(v) / 520.);
  vec3 rays = vec3(0);
  rays += vec3(1., .16, .16) * exp(-pow((ang + .19) / .085, 2.));
  rays += vec3(.16, 1., .3) * exp(-pow((ang) / .085, 2.));
  rays += vec3(.2, .4, 1.) * exp(-pow((ang - .19) / .085, 2.));
  still += rays * fall * .2;
  col = mix(col, still, pk);
  // the Prism level: clear water, white light
  col = mix(col, vec3(.02, .026, .04) + vec3(.05, .06, .08) * exp(-p.y / 260.), pr * .85);
  // a soft edge to the whole column
  vec2 e = uv - .5;
  col *= 1. - dot(e * vec2(1.1, .5), e * vec2(1.1, .5)) * .55;
  o = vec4(col, 1);
}`;

// ---------------------------------------------------------------- 2D helpers
let ctx;
function text(s, x, y, font, colour, align = 'left', spacing = 0) {
  ctx.font = font; ctx.fillStyle = colour; ctx.textAlign = align; ctx.textBaseline = 'alphabetic';
  ctx.letterSpacing = spacing + 'px';
  ctx.fillText(s, x, y);
  ctx.letterSpacing = '0px';
  return ctx.measureText(s).width;
}
function glow(x, y, r, rgb, a) {
  const g = ctx.createRadialGradient(x, y, 0, x, y, r);
  g.addColorStop(0, `rgba(${rgb}, ${a})`);
  g.addColorStop(1, `rgba(${rgb}, 0)`);
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
}
function orb(x, y, r, a = 1) {
  glow(x, y, r * 4.2, '190, 250, 245', 0.32 * a);
  ctx.fillStyle = `rgba(250, 255, 246, ${a})`;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
}
function hollow(x, y, r, a = 1) {
  ctx.strokeStyle = ink(0.62 * a); ctx.lineWidth = 1.2;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke();
}
// Result marks as bubbles: filled earned, hollow not. Each sits a little higher than the last, as bubbles rise.
function marks(x, y, n, r = 3.2, gap = 9, a = 1) {
  for (let k = 0; k < 3; k++) {
    const bx = x + k * gap, by = y - k * 1.6;
    if (k < n) { ctx.fillStyle = ink(0.92 * a); ctx.beginPath(); ctx.arc(bx, by, r, 0, Math.PI * 2); ctx.fill(); }
    else hollow(bx, by, r, a);
  }
}
function finger(x, y, a, press = 0) {
  if (a <= 0) return;
  glow(x, y, 46, '255, 255, 255', 0.12 * a);
  ctx.fillStyle = `rgba(255, 255, 255, ${(0.16 + press * 0.1) * a})`;
  ctx.beginPath(); ctx.arc(x, y, 21 - press * 3, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = `rgba(255, 255, 255, ${0.4 * a})`; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.arc(x, y, 21 - press * 3, 0, Math.PI * 2); ctx.stroke();
  if (press > 0) {
    ctx.strokeStyle = `rgba(255, 255, 255, ${0.35 * a * (1 - press)})`;
    ctx.beginPath(); ctx.arc(x, y, 21 + press * 26, 0, Math.PI * 2); ctx.stroke();
  }
}
// The surface fade: nothing of the water's chrome draws under the status bar.
const under = (y) => AX ? ramp(y, 120, 190) : ramp(y, 58, 104);
function surfaceY(t, cam) { return -cam + 3.5 * Math.sin(220 * 0.024 + (RM ? 0 : t) * 0.0011); }
function bob(t, k, amp = 2.2) { return RM ? 0 : amp * Math.sin(t * 0.0012 + k * 1.9); }
function wavy(x, t) { return 3.5 * Math.sin(x * 0.024 + (RM ? 0 : t) * 0.0011) + 2 * Math.sin(x * 0.063 - (RM ? 0 : t) * 0.0016 + 1.3); }

// ---------------------------------------------------------------- scenes
// The whole dive on one screen: where the daily, the archive, endless and the tiers live.
function overview(t, a) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const W = 440;
  text('UNSTIR', 32, 128, `250 ${World.pt('display')}px UPro`, INK, 'left', 9);
  // the buoy: settings
  const by = 196 + wavy(388, t) + bob(t, 0, 1.2);
  orb(388, by - 2, 5.5, 0.9);
  text('settings', 368, by - 18, F.ui(World.pt('detail')), ink(0.7), 'right');
  // today, in the sunlit shallows
  const sun = 0.85 + (RM ? 0 : 0.15 * Math.sin(t * 0.0016));
  glow(58, 264, 54, '255, 236, 190', 0.24 * sun);
  orb(58, 264, 7, 1);
  text('today', 86, 258, F.word(World.pt('title')), INK);
  text('daily · Mon 23 Nov', 86, 284, F.ui(World.pt('body')), ink(0.9));
  const w = text('4 days running', 86, 306, F.data(World.pt('detail')), ink(0.72));
  marks(86 + w + 14, 302, 2);
  // the archive, a little deeper and dimmer
  hollow(258, 334, 5, 0.9);
  text('archive', 274, 339, F.ui(World.pt('body')), ink(0.78));
  text('comes with any pack', 274, 359, F.ui(World.pt('detail')), ink(0.62));
  // the four tiers, each its own water
  const tiers = [
    { name: 'plughole', y0: 370, y1: 530, note: '27 of 27 at par', lit: 27, open: 27, nameA: 0.95 },
    { name: 'whirlpool', y0: 530, y1: 675, note: 'Spring is next, at 28 m', lit: 0, open: 1, nameA: 0.95 },
    { name: 'vortex', y0: 675, y1: 790, note: 'opens after whirlpool', lit: 0, open: 0, nameA: 0.72 },
    { name: 'maelstrom', y0: 790, y1: 880, note: 'opens after vortex', lit: 0, open: 0, nameA: 0.72 },
  ];
  tiers.forEach((tr, i) => {
    const ny = tr.y0 + 36;
    text(tr.name, 32, ny, F.word(World.pt('title')), ink(tr.nameA));
    text(tr.note, 33, ny + 22, F.data(World.pt('detail')), ink(0.66));
    // 27 motes on a slow meander through the band, right of the words
    for (let k = 0; k < 27; k++) {
      const f = k / 26;
      // a gentle S down through the band, as the dive meanders
      const x = 318 + 78 * Math.sin(f * Math.PI * 1.6 + 0.4 + i * 0.7);
      const y = tr.y0 + 20 + (tr.y1 - tr.y0 - 40) * f + bob(t, k + i * 30, 1.2);
      if (k < tr.lit) { glow(x, y, 9, '190, 250, 245', 0.35); ctx.fillStyle = 'rgba(245, 255, 250, .95)'; ctx.beginPath(); ctx.arc(x, y, 1.9, 0, 7); ctx.fill(); }
      else if (k < tr.open) { orb(x, y, 3.2, 1); }
      else { ctx.fillStyle = ink(0.22); ctx.beginPath(); ctx.arc(x, y, 1.4, 0, 7); ctx.fill(); }
    }
  });
  // endless: the abyss
  glow(220, 916, 60, '255, 70, 60', 0.16);
  text('endless', 220, 912, F.word(World.pt('title')), ink(0.9), 'center');
  text('best 9', 220, 934, F.data(World.pt('detail')), ink(0.68), 'center');
  ctx.restore();
}

// The dive itself: lanterns at their depths on a meandering current, packs drifting at the far side.
function dive(t, cam, a) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const sY = surfaceY(t, cam);
  // the current: one faint curve through every lantern
  ctx.strokeStyle = 'rgba(190, 250, 245, 0.10)'; ctx.lineWidth = 1;
  ctx.beginPath();
  for (let m = 0.2; m <= 27.6; m += 0.1) {
    const x = laneX(m), y = levelY(m) - cam;
    if (m === 0.2) ctx.moveTo(x, y); else ctx.lineTo(x, y);
  }
  ctx.stroke();
  // the tier's name where its water begins
  const pY = levelY(-1.6) - cam, wY = levelY(27.8) - cam;
  if (pY > -40 && pY < 1000) text('plughole', 32, pY, F.word(World.pt('title')), ink(0.8 * under(pY)));
  if (wY > -40 && wY < 1000) {
    text('whirlpool', 32, wY, F.word(World.pt('title')), ink(0.8 * under(wY)));
    text('opens when plughole is at par', 33, wY + 22, F.data(World.pt('detail')), ink(0.62 * under(wY)));
  }
  for (let n = 1; n <= 27; n++) {
    const y = levelY(n) - cam + bob(t, n, 1.6);
    if (y < 20 || y > 990) continue;
    const u = under(y);
    if (u <= 0) continue;
    const x = laneX(n);
    const nx = x + (AX ? 26 : 24);
    ctx.save(); ctx.globalAlpha = a * u;
    if (n < NEXT) {
      orb(x, y, 4.6, 0.9);
      const b = World.pt('body');
      const w = text(NAMES[n - 1], nx, y + b * 0.35, F.ui(b, 350), ink(0.86));
      marks(nx + w + 13, y + 1, 2, AX ? 5 : 3.2, AX ? 14 : 9);
      text(`${n} m`, nx, y - b * 0.55 - 4, F.data(World.pt('detail')), ink(0.62));
    } else if (n === NEXT) {
      const p = RM ? 1 : 0.86 + 0.14 * Math.sin(t * 0.0021);
      glow(x, y, 70, '200, 255, 250', 0.2 * p);
      orb(x, y, 8, 1);
      const ti = World.pt('title') * 1.15;
      text(`${n} m`, nx + 2, y - ti * 0.6 - 4, F.data(World.pt('detail')), ink(0.74));
      text(NAMES[n - 1], nx, y + ti * 0.36, F.name(ti), INK);
      text('4 rods · par 4', nx + 2, y + ti * 0.36 + World.pt('label') * 1.45, F.data(World.pt('label')), ink(0.78));
    } else {
      hollow(x, y, 4.2, 0.85);
      text(NAMES[n - 1], nx, y + World.pt('body') * 0.35, F.ui(World.pt('body'), 350), ink(0.62));
    }
    ctx.restore();
  }
  // packs: their own covers as portholes, drifting
  if (!AX) PACKS.forEach((pk, i) => {
    const y = levelY(pk.m) - cam + bob(t, i + 40, 4);
    if (y < -60 || y > 1020) return;
    const u = under(y);
    const x = pk.x + (RM ? 0 : 3 * Math.sin(t * 0.0007 + i));
    ctx.save(); ctx.globalAlpha = a * u;
    glow(x, y, 62, pk.glow, 0.22);
    World.disc(ctx, 'cover-' + pk.id, x, y, 58);
    ctx.strokeStyle = 'rgba(220, 240, 255, 0.35)'; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.arc(x, y, 30.5, 0, Math.PI * 2); ctx.stroke();
    text(pk.name, x, y + 52, F.ui(World.pt('detail')), ink(0.72), 'center');
    ctx.fillStyle = INK; ctx.beginPath(); ctx.arc(x, y + 64, 2.2, 0, 7); ctx.fill();
    ctx.restore();
  });
  ctx.restore();
}

// A level's tank as a porthole at its depth.
function playChrome(t, a, o) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const T = o.tank;
  text('↑ levels', 28, AX ? 104 : 96, F.ui(World.pt('body')), ink(0.82));
  if (o.count) text(o.count, AX ? 28 : 412, AX ? 150 : 96, F.data(World.pt('label')), ink(0.72), AX ? 'left' : 'right');
  const titleY = T.y - T.d / 2 - (AX ? 24 : 54);
  text(o.depth, 220, titleY - (AX ? 46 : 36), F.data(World.pt('detail')), o.prism ? INK : ink(0.7), 'center');
  text(o.title, 220, titleY, F.name(World.pt('display')), INK, 'center');
  if (o.prism) glow(220, titleY - (AX ? 52 : 40), 26, '255, 255, 255', 0.16);
  ctx.restore();
}
function porthole(name, T, a, s = 1) {
  if (a <= 0) return;
  const d = T.d * s;
  ctx.save(); ctx.globalAlpha = a;
  glow(T.x, T.y, d * 0.62, '170, 240, 245', 0.16);
  World.disc(ctx, name, T.x, T.y, d);
  ctx.restore();
}
function noteAndControls(t, a, o) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const T = o.tank;
  let y = T.y + T.d / 2 + (AX ? 56 : 42);
  const lines = AX ? wrap(o.note.join(' '), F.word(World.pt('body')), 392) : o.note;
  for (const line of lines) { text(line, 220, y, F.word(World.pt('body')), ink(0.8), 'center'); y += AX ? 47 : 25; }
  const cy = AX ? 890 : 878;
  const b1 = bob(t, 70, 2.5), b2 = bob(t, 71, 2.5);
  glow(52, cy + b1, 34, '190, 250, 245', 0.12); hollow(52, cy + b1, 15, 1);
  ctx.fillStyle = ink(0.18); ctx.beginPath(); ctx.arc(52, cy + b1, 15, 0, 7); ctx.fill();
  text(o.undo, 76, cy + World.pt('body') * 0.35 + b1, F.ui(World.pt('body')), ink(0.86));
  glow(388, cy + b2, 34, '190, 250, 245', 0.12); hollow(388, cy + b2, 15, 1);
  ctx.fillStyle = ink(0.18); ctx.beginPath(); ctx.arc(388, cy + b2, 15, 0, 7); ctx.fill();
  text('reset', 364, cy + World.pt('body') * 0.35 + b2, F.ui(World.pt('body')), ink(0.86), 'right');
  ctx.restore();
}

const TANK_PLAY = AX ? { x: 220, y: 392, d: 236 } : { x: 220, y: 474, d: 403 };
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
const TANK_RESULT = { x: 220, y: 446, d: 384 };

function resultScene(t, a, t0) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const T = TANK_RESULT;
  // bubbles rising from the solved tank
  if (!RM) for (let k = 0; k < 26; k++) {
    const st = t0 + 150 + k * 70;
    const life = ramp(t, st, st + 2600);
    if (life <= 0 || life >= 1) continue;
    const x = T.x + (Math.sin(k * 12.9898) * 0.5) * T.d * 0.8 + 6 * Math.sin(life * 9 + k);
    const y = T.y - T.d * 0.35 - life * 330;
    const r = 1.4 + (k % 4) * 0.9;
    ctx.strokeStyle = `rgba(230, 255, 250, ${0.6 * (1 - life)})`; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.arc(x, y, r, 0, 7); ctx.stroke();
  }
  text('↑ levels', 28, 96, F.ui(World.pt('body')), ink(0.82));
  text('27 m · Drain', 220, 140, F.data(World.pt('label')), ink(0.74), 'center');
  const rise = RM ? 1 : settle(ramp(t, t0 + 300, t0 + 1500));
  ctx.save(); ctx.globalAlpha = a * (RM ? ramp(t, t0, t0 + 200) : ease(ramp(t, t0 + 300, t0 + 900)));
  text('unstirred.', 220, 210 + (1 - rise) * 40, F.word(World.pt('display')), INK, 'center');
  ctx.restore();
  // the marks: three bubbles, the third hollow
  const mA = RM ? 1 : ease(ramp(t, t0 + 900, t0 + 1500));
  ctx.save(); ctx.globalAlpha = a * mA;
  const my = T.y + T.d / 2 + 44 - (RM ? 0 : (1 - settle(ramp(t, t0 + 900, t0 + 1700))) * -16);
  [[196, 2], [220, 1.2], [244, 0]].forEach(([x, dy], k) => {
    if (k < 2) { glow(x, my - dy, 18, '200, 255, 250', 0.25); ctx.fillStyle = ink(0.95); ctx.beginPath(); ctx.arc(x, my - dy, 6, 0, 7); ctx.fill(); }
    else hollow(x, my - dy, 6, 1);
  });
  text('at par · new best, was +6', 220, my + 40, F.ui(World.pt('body')), ink(0.92), 'center');
  text('clean needs no undo or reset', 220, my + 63, F.ui(World.pt('detail')), ink(0.66), 'center');
  ctx.restore();
  const nA = RM ? 1 : ease(ramp(t, t0 + 1400, t0 + 2100));
  ctx.save(); ctx.globalAlpha = a * nA;
  text('again', 30, 888, F.ui(World.pt('body')), ink(0.78));
  text('deeper', 410, 860, F.word(World.pt('label')), ink(0.7), 'right');
  text('whirlpool ›', 410, 888, `300 ${World.pt('title') * 0.82}px UPro`, INK, 'right');
  ctx.restore();
  ctx.restore();
}

function packScene(t, a, t0) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const arr = (k) => RM ? 1 : ease(ramp(t, t0 + 500 + k * 130, t0 + 1200 + k * 130));
  text('↑ menu', 28, 96, F.ui(World.pt('body')), ink(0.82));
  const lift = (k) => RM ? 0 : (1 - settle(ramp(t, t0 + 500 + k * 130, t0 + 1500 + k * 130))) * 14;
  const line = (k, s, y, font, colour) => { ctx.save(); ctx.globalAlpha = a * arr(k); text(s, 220, y + lift(k), font, colour, 'center'); ctx.restore(); };
  ctx.save(); ctx.globalAlpha = a * arr(0);
  glow(220, 500, 90, '255, 255, 255', 0.07);
  ctx.restore();
  line(0, 'Prism', 512, `200 ${World.pt('display') * 1.3}px UPro`, '#ffffff');
  line(1, 'each rod stirs only some colours', 546, F.word(World.pt('body')), ink(0.88));
  line(2, '30 specimens in five trays', 592, F.ui(World.pt('label')), ink(0.86));
  line(2, 'levels 1–3 free, no purchase', 614, F.ui(World.pt('label')), ink(0.86));
  line(3, 'letters for colour-blind play, in settings', 640, F.ui(World.pt('detail')), ink(0.66));
  // buy: a bright orb; try: quieter
  ctx.save(); ctx.globalAlpha = a * arr(4);
  const by = 700 + lift(4);
  orb(84, by - 6, 7, 1);
  text('buy $2.99', 102, by, F.ui(World.pt('body'), 600), '#ffffff');
  text('try 3 free ›', 356, by, F.ui(World.pt('body')), ink(0.86), 'right');
  text('or all three in Triptych I · $5.99 · save $2.98 ›', 220, by + 36, F.ui(World.pt('detail')), ink(0.66), 'center');
  ctx.restore();
  // its 30 specimens as five small shoals of light, the first three lit (free)
  ctx.save(); ctx.globalAlpha = a * arr(5);
  for (let tray = 0; tray < 5; tray++) {
    for (let k = 0; k < 6; k++) {
      const i = tray * 6 + k;
      const x = 66 + tray * 77 + k * 9;
      const y = 812 + 10 * Math.sin(k * 0.9 + tray) + bob(t, i + 90, 1.4);
      if (i < 3) orb(x, y, 2.6, 1); else { ctx.fillStyle = ink(0.34); ctx.beginPath(); ctx.arc(x, y, 1.8, 0, 7); ctx.fill(); }
    }
  }
  text('the first three are free to play', 220, 852, F.ui(World.pt('detail')), ink(0.62), 'center');
  text('restore purchases', 220, 906, F.ui(World.pt('detail')), ink(0.66), 'center');
  ctx.restore();
  ctx.restore();
}

function settingsScene(t, a, t0, cam) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const sY = -cam;
  const arr = (k) => RM ? 1 : ease(ramp(t, t0 + k * 140, t0 + 700 + k * 140));
  ctx.save(); ctx.globalAlpha = a * arr(0);
  text('settings', 32, 176, F.word(World.pt('display')), INK);
  ctx.restore();
  const buoys = [['music', true, 70], ['sounds', true, 170], ['haptics', true, 270], ['colour letters', false, 370]];
  buoys.forEach(([name, on, x], k) => {
    const rise = RM ? 0 : (1 - settle(ramp(t, t0 + 200 + k * 150, t0 + 1300 + k * 150))) * 40;
    const y = sY + wavy(x, t) + bob(t, k + 100, 1.6) + rise - 2;
    ctx.save(); ctx.globalAlpha = a * arr(k + 1);
    if (on) { glow(x, y, 46, '255, 238, 200', 0.3); ctx.fillStyle = '#fffbea'; ctx.beginPath(); ctx.arc(x, y, 9, 0, 7); ctx.fill(); }
    else { ctx.fillStyle = 'rgba(10, 30, 36, 0.9)'; ctx.beginPath(); ctx.arc(x, y, 9, 0, 7); ctx.fill(); hollow(x, y, 9, 1); }
    text(name, x, sY + 46, F.ui(World.pt('body')), ink(on ? 0.95 : 0.8), 'center');
    text(on ? 'on' : 'off', x, sY + 68, F.data(World.pt('detail')), ink(0.66), 'center');
    ctx.restore();
  });
  ctx.save(); ctx.globalAlpha = a * arr(5);
  text('restore purchases', 40, sY + 168, F.ui(World.pt('body')), ink(0.88));
  text('report a problem ↗', 150, sY + 236, F.ui(World.pt('body')), ink(0.88));
  text('privacy policy ↗', 70, sY + 304, F.ui(World.pt('body')), ink(0.88));
  text('Unstir 1.0 (1)', 220, sY + 392, F.data(World.pt('detail')), ink(0.62), 'center');
  text('↓ back into the water', 220, 900, F.ui(World.pt('detail')), ink(0.66), 'center');
  ctx.restore();
  ctx.restore();
}

// ---------------------------------------------------------------- the film's fingertip
const TOUCHES = [
  // [appear, press, lift/leave, x0, y0, x1, y1]
  [2100, 2700, 3000, 300, 470, 300, 470],    // tap plughole's band
  [6700, 7000, 8500, 290, 360, 290, 860],     // draw the water down: rise
  [8400, 8800, 9100, laneX(1) + 4, levelY(1) - CAM.menu1, laneX(1) + 4, levelY(1) - CAM.menu1], // tap Drop
  [18000, 18350, 18600, 58, 92, 58, 92],      // ↑ levels
  [19900, 20300, 20600, 390, levelY(16.5) - CAM.menu15, 390, levelY(16.5) - CAM.menu15], // Prism's porthole
  [24200, 24500, 24800, 58, 92, 58, 92],      // ↑ menu
  [26300, 26600, 26900, 388, -CAM.surface + wavy(388, 26600), 388, -CAM.surface + wavy(388, 26600)], // the buoy
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

// The status bar's glyphs over the water itself: its black ground is dropped by taking the lighter of the two.
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
  ctx = c;
  const cam = camera(t);
  if (t >= 36000) return prismLevel(t);
  overview(t, ov(t));
  // the lanterns stay in view while the camera sinks between screens, so a dive passes the levels it crosses
  const menuA = t < 3000 ? 0 : span(t, 2950, 3700, 8700, 9300) + 0.7 * span(t, 13250, 13600, 14100, 14600) + span(t, 18900, 19800, 20500, 21200);
  dive(t, cam, Math.min(1, menuA));
  // play: Drop's lantern opens into its tank
  const openK = RM ? (t >= 9550 ? 1 : 0) : settle(ramp(t, 8900, 10200));
  const playA = t >= 8900 && t < 13600 ? (RM ? span(t, 9200, 9900, 12700, 13300) : ease(ramp(t, 8900, 9300)) * (1 - ease(ramp(t, 12700, 13300)))) : 0;
  if (playA > 0) {
    const src = { x: laneX(1), y: levelY(1) - CAM.menu1 };
    const T = { x: mix(src.x, TANK_PLAY.x, openK), y: mix(src.y, TANK_PLAY.y, openK), d: TANK_PLAY.d };
    porthole('play01', T, playA, mix(0.04, 1, openK));
    const chromeA = playA * (RM ? 1 : ease(ramp(t, 9700, 10500)));
    const o = { tank: TANK_PLAY, title: 'Drop', depth: '1 m', count: 'moves 0 / par 1',
      note: ['Turn a rod to look. Let go where', 'you started and nothing happens.'], undo: 'undo · 10' };
    playChrome(t, chromeA, o);
    noteAndControls(t, chromeA, o);
  }
  // result at 27 m
  const resA = span(t, 14500, 15000, 18700, 19300);
  if (resA > 0) {
    porthole('drain-solved', TANK_RESULT, resA * (RM ? 1 : ease(ramp(t, 14500, 15100))));
    resultScene(t, resA, 14600);
  }
  // Prism's card: its porthole rises from the drift to the middle
  const pA = packMix(t);
  if (pA > 0) {
    const k = RM ? 1 : settle(ramp(t, 20600, 21900));
    const src = { x: 390, y: levelY(16.5) - CAM.menu15 };
    const T = { x: mix(src.x, 220, k), y: mix(src.y, 296, k), d: mix(58, 290, k) };
    ctx.save(); ctx.globalAlpha = pA;
    World.disc(ctx, 'prism-clip', T.x, T.y, T.d);
    ctx.restore();
    packScene(t, pA, 21000);
  }
  // settings at the surface
  const sA = span(t, 26500, 27000, 99999, 99999);
  settingsScene(t, sA, 26600, cam);
  touches(t);
  statusBar();
}

// Prism 01 in play: clear water and white light; its number white, never one channel's colour.
function prismLevel(t) {
  const o = { tank: TANK_PLAY, title: 'Frond', depth: 'Prism · 01', count: 'moves 0 / par 3', prism: true,
    note: ['Each rod stirs only its', 'knob’s colours.'], undo: 'undo · 10' };
  porthole('prism01', TANK_PLAY, 1);
  playChrome(t, 1, o);
  noteAndControls(t, 1, o);
  statusBar();
}

window.DRAWS_AX = true;
World.load(['play01', 'drain-solved', 'prism01', 'prism-clip', 'cover-lens', 'cover-escapement', 'cover-prism',
  'cover-triptych', 'status']).then(() => World.start({
  fonts: ['300 28px UPro', 'italic 300 28px NY', '400 13px UMono', '600 17px UPro', '200 40px UPro', '250 34px UPro'],
  shader,
  uniforms: (t) => {
    const cam = camera(t);
    const pkx = 220, pky = 296;
    return {
      camY: t >= 36000 ? CAM.play : cam, ov: ov(t), pk: packMix(t), tm: RM ? 0 : t, PM, shaft: 1,
      pkC: [pkx, pky], pr: prismMix(t),
    };
  },
  draw,
  duration: DUR,
  shots: SHOTS,
}));
