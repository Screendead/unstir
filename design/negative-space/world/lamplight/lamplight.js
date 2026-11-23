// Copyright © 2026 Jack Lusher. All rights reserved.
// Lamplight: the Descent in the dark. The game is one column of water seen from the side, nearly black; the player
// carries a lamp, a soft pool of warm light at the next level to play, and every level solved stays lit behind it as
// a small living glow in its tier's own light. The ground is one shader pass (dark water by depth, one radial lamp,
// dusk at the surface, motes in three parallax layers that only show where light reaches); glows, type and glass are
// 2D on top. Nothing stirs: the UI sinks, rises, drifts, breathes and kindles. While a tank is open the ground holds
// one frame.

const { ramp, ease, settle, mix } = World;
const RM = World.rm, AX = World.ax;
const PM = AX ? 196 : 110;            // points between two levels in the dive
const TOP = 420;                      // world y of level 0; the surface (world y 0) sits 3.8 levels above level 1
const levelY = (m) => TOP + m * PM;
const NAMES = ['Drop', 'Drip', 'Trickle', 'Ripple', 'Bubble', 'Fizz', 'Sprinkle', 'Mist', 'Spray', 'Splash', 'Puddle',
  'Froth', 'Suds', 'Lather', 'Steam', 'Gurgle', 'Rinse', 'Drizzle', 'Shower', 'Downpour', 'Overflow', 'Bathwater',
  'Spin', 'Whirl', 'Spiral', 'Last drop', 'Drain'];
const NEXT = 14;
const laneX = (n) => (AX ? 58 : 118) + (AX ? 16 : 46) * Math.sin(n * 0.85 + 0.6);

const INK = '#f1f0ee';
const ink = (a) => `rgba(241, 240, 238, ${a})`;
const WARM = '255, 214, 150';
const F = {
  name: (s) => `300 ${s}px UPro`,
  word: (s) => `italic 300 ${s}px NY`,
  data: (s) => `400 ${s}px UMono`,
  ui: (s, w = 400) => `${w} ${s}px UPro`,
};

// Each tier's own light: its colour and how it lives. b is brightness, dy a vertical drift in points.
const TIER = {
  plughole: { rgb: '110, 255, 220', live: (t, k) => ({ b: 0.8 + 0.2 * Math.sin(t * 0.0014 + k * 1.7), dy: 0 }) },                 // breathes
  whirlpool: { rgb: '205, 150, 255', live: (t, k) => ({ b: 0.9, dy: 3.2 * Math.sin(t * 0.0008 + k * 1.3) }) },                    // drifts
  vortex: { rgb: '140, 195, 255', live: (t, k) => ({ b: 0.5 + 0.5 * Math.pow(Math.max(0, Math.sin(t * 0.0028 + k * 2.4)), 6), dy: 0 }) }, // glints
  maelstrom: { rgb: '255, 150, 95', live: (t, k) => ({ b: 0.72 + 0.18 * Math.sin(t * 0.0009 + k) + 0.1 * Math.sin(t * 0.0041 + k * 3.1), dy: 0 }) }, // smoulders
};
const live = (tier, t, k) => RM ? { b: 1, dy: 0 } : TIER[tier].live(t, k);

// Packs are distant glows at the lane's far side, each at its own depth.
const PACKS = [
  { id: 'lens', name: 'Lens', m: 6.6, x: 388, glow: '255, 90, 214' },
  { id: 'escapement', name: 'Escapement', m: 11.4, x: 376, glow: '255, 140, 100' },
  { id: 'prism', name: 'Prism', m: 16.5, x: 386, glow: '225, 232, 255' },
  { id: 'triptych', name: 'Triptych I', m: 21.6, x: 378, glow: '255, 205, 130' },
];

// ---------------------------------------------------------------- the timeline
// 0     the whole column at rest (overview)            menu-today
// 2.6   a finger taps plughole; the view sinks to level 14, where the lamp is
// 5.2   the dive at 14 at rest                          menu
// 7.0   a finger draws the water down: rise along the trail to level 1
// 8.9   tapping Drop opens its tank; the ground holds still
// 10.4  play at rest                                    play
// 12.6  later: the lamp sinks to 27, each level it passes kindling behind it
// 14.6  the result arrives and Drain kindles            result
// 18.4  "↑ levels": rise to 15, the whole trail lit
// 20.2  tapping Prism's glow opens its card
// 22.6  pack at rest                                    pack
// 24.6  "↑ menu", rise to the surface, tap the buoy
// 27.0  settings at rest                                settings
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

function span(t, a, b, c, d) { // fades in over a..b, out over c..d
  if (RM) { const mid1 = (a + b) / 2, mid2 = (c + d) / 2; return ramp(t, mid1 - 120, mid1 + 120) * (1 - ramp(t, mid2 - 120, mid2 + 120)); }
  return ease(ramp(t, a, b)) * (1 - ease(ramp(t, c, d)));
}
function move(t, a, b, from, to, curve = ease) {
  if (RM) return t < (a + b) / 2 ? from : to;
  return mix(from, to, curve(ramp(t, a, b)));
}

function camera(t) {
  if (t >= 36000) return CAM.play; // the Prism level, off the film
  if (t < 3000) return CAM.overview;
  let y = move(t, 3000, 5200, CAM.overview, CAM.menu14);
  if (t >= 7000) y = move(t, 7000, 8700, CAM.menu14, CAM.menu1, (x) => settle(x));
  if (t >= 8700) y = move(t, 8900, 10200, CAM.menu1, CAM.play);
  if (t >= 12600) y = move(t, 12800, 14600, CAM.play, CAM.result);
  if (t >= 18400) y = move(t, 18600, 20200, CAM.result, CAM.menu15, (x) => settle(x));
  if (t >= 24600) y = move(t, 24900, 26400, CAM.menu15, CAM.surface);
  return y;
}
const ov = (t) => t >= 36000 ? 0 : (RM ? (t < 3000 ? 1 : 0) : 1 - ease(ramp(t, 2950, 3500)));
const packMix = (t) => t >= 36000 ? 0 : span(t, 20600, 21600, 24700, 25400);
const prismMix = (t) => t >= 36000 ? 1 : 0;
const settingsMix = (t) => t >= 36000 ? 0 : span(t, 26500, 27000, 99999, 99999);
// Where the lamp is in the column: the next level to play. It travels down with the later dive.
const front = (t) => t < 12800 ? NEXT : t < 15200 ? move(t, 12800, 14600, NEXT, 27) : 28;
// How lit a level is, 0..1: it kindles as the lamp passes, and Drain when its result lands.
const lit = (n, t) => n === 27 ? (RM ? (t >= 15000 ? 1 : 0) : ease(ramp(t, 15000, 16200))) : ramp(front(t) - n, 0, 0.7);
// The ground's clock: held while a tank is open, as the app freezes the pass during play.
const groundTime = (t) => RM ? 0 : t >= 36000 ? 9500 : t < 9500 ? t : t < 12700 ? 9500 : t < 14700 ? 9500 + (t - 12700) : t < 18600 ? 11500 : 11500 + (t - 18600);

const TANK_PLAY = AX ? { x: 220, y: 410, d: 236 } : { x: 220, y: 474, d: 403 };
const TANK_RESULT = { x: 220, y: 446, d: 384 };
const OV_LAMP = { x: 348 + 54 * Math.sin(0.5 * Math.PI * 1.6 + 0.4), y: 450 };

// The lamp on screen: centre, radius, strength, and how warm (1 the lamp's own amber, 0 a neutral light so the
// tank's colours read true).
let LAMP = { x: 0, y: 0, r: 300, a: 1, warm: 1 };
function lamp(t, cam) {
  if (t >= 36000) return { x: TANK_PLAY.x, y: TANK_PLAY.y, r: 380, a: 0.75, warm: 0 };
  const f = front(t);
  let L = { x: laneX(f), y: levelY(f) - cam, r: AX ? 430 : 300, a: 1, warm: 1 };
  const to = (k, T) => { for (const key of Object.keys(T)) L[key] = mix(L[key], T[key], k); };
  to(ov(t), { x: OV_LAMP.x, y: OV_LAMP.y, r: 150 });
  const playK = t >= 8900 && t < 13300 ? (RM ? span(t, 9200, 9900, 12700, 13300) : ease(ramp(t, 8900, 10000)) * (1 - ease(ramp(t, 12700, 13300)))) : 0;
  to(playK, { x: TANK_PLAY.x, y: TANK_PLAY.y, r: 380, a: 0.75, warm: 0 });
  to(span(t, 14500, 15000, 18700, 19300), { x: TANK_RESULT.x, y: TANK_RESULT.y, r: 380, a: 0.8, warm: 0 });
  L.a *= (1 - packMix(t)) * (1 - settingsMix(t));
  return L;
}
const lampAt = (x, y) => LAMP.a * Math.exp(-2.2 * ((x - LAMP.x) ** 2 + (y - LAMP.y) ** 2) / (LAMP.r * LAMP.r));

// ---------------------------------------------------------------- the water
const shader = `
uniform float camY, ov, pk, tm, PM, pr, lampR, lampA, warm;
uniform vec2 pkC, lampC;
float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ovM(float y) { // the whole column on one screen: surface 196, then the four tiers, then the deep
  if (y < 370.) return mix(-3.8, 0., (y - 196.) / 174.);
  if (y < 530.) return (y - 370.) / 160. * 27.;
  if (y < 675.) return 27. + (y - 530.) / 145. * 27.;
  if (y < 790.) return 54. + (y - 675.) / 115. * 27.;
  if (y < 880.) return 81. + (y - 790.) / 90. * 27.;
  return 108. + (y - 880.) / 76. * 20.;
}
vec3 water(float m) { // each tier's water as light shows it
  vec3 c = mix(vec3(.06, .22, .25), vec3(.02, .15, .17), smoothstep(-3.8, 9., m));
  c = mix(c, vec3(.13, .04, .19), smoothstep(24., 31., m));
  c = mix(c, vec3(.025, .055, .2), smoothstep(51., 58., m));
  c = mix(c, vec3(.16, .03, .03), smoothstep(78., 85., m));
  c = mix(c, vec3(.03, .015, .012), smoothstep(102., 122., m));
  return c;
}
vec3 glowOf(float m) { // each tier's living light
  vec3 c = vec3(.43, 1., .86);
  c = mix(c, vec3(.8, .59, 1.), smoothstep(24., 31., m));
  c = mix(c, vec3(.55, .76, 1.), smoothstep(51., 58., m));
  c = mix(c, vec3(1., .59, .37), smoothstep(78., 85., m));
  return c;
}
void main() {
  vec2 p = uv * res;
  float mD = (camY + p.y - 420.) / PM;
  float m = mix(mD, ovM(p.y), ov);
  float sY = mix(-camY, 196., ov) + 3.5 * sin(p.x * .024 + tm * .0011) + 2. * sin(p.x * .063 - tm * .0016 + 1.3);
  vec3 dusk = vec3(.72, .43, .2);
  vec3 col, w = water(m);
  float below = step(sY, p.y);
  if (p.y < sY) { // the last of the daylight, low on the horizon
    float h = sY - p.y;
    col = vec3(.014, .018, .04) + dusk * exp(-h / 52.) * .5 + vec3(.2, .16, .25) * exp(-h / 170.) * .3;
  } else {
    float d = p.y - sY;
    col = w * mix(.16, .34, ov) + vec3(.003, .005, .009);
    col += (w * 1.1 + dusk * .16) * exp(-d / 120.);
    col += vec3(1., .72, .46) * exp(-d / 1.4) * .5;
  }
  // a pack's waters: still and neutral, lit by its glass's light split into three
  vec3 still = vec3(.012, .014, .022) + vec3(.02, .024, .034) * (1. - uv.y);
  vec2 v = p - pkC;
  float ang = atan(v.x, v.y);
  float fall = smoothstep(0., 40., v.y) * exp(-length(v) / 520.);
  vec3 rays = vec3(1., .16, .16) * exp(-pow((ang + .19) / .085, 2.));
  rays += vec3(.16, 1., .3) * exp(-pow(ang / .085, 2.));
  rays += vec3(.2, .4, 1.) * exp(-pow((ang - .19) / .085, 2.));
  still += rays * fall * .16;
  col = mix(col, still, pk);
  col = mix(col, vec3(.012, .015, .024), pr);
  // the lamp: one soft pool that shows the water its own colour, warm at its heart
  vec2 ld = p - lampC;
  float lf = exp(-2.2 * dot(ld, ld) / (lampR * lampR)) * lampA * mix(1., below, .8);
  vec3 shown = mix(w, vec3(.085, .1, .125), max(pr, (1. - warm) * .55));
  vec3 lampCol = mix(vec3(.5, .56, .62), vec3(1., .7, .4), warm);
  col += shown * lf * 1.25 + lampCol * lf * lf * lf * .22;
  // motes in three parallax layers: dust in the lamp's light, and a few that glow on their own in the tier's light
  vec3 own = glowOf(m);
  for (int k = 0; k < 3; k++) {
    float fk = float(k);
    float par = .35 + fk * .3;
    float cell = 46. + fk * 22.;
    vec2 q = vec2(p.x + fk * 37., p.y + mix(camY * par, 0., ov) + tm * (.006 + fk * .004)) / cell;
    vec2 id = floor(q), f = fract(q) - .5;
    vec2 jo = vec2(h1(id), h1(id + 7.1)) - .5;
    float r = length((f - jo * .7) * cell);
    float b = smoothstep(.8 + fk * .5, 0., r) * step(.55, h1(id + 3.3));
    float self = step(.86, h1(id + 5.7)) * (.6 + .4 * sin(tm * .0012 + h1(id) * 40.));
    col += (mix(vec3(.75, .8, .85), vec3(1., .82, .6), warm) * lf * .5 + own * self * .32) * b * below * (1. - pk) * (1. - pr);
  }
  vec2 e = uv - .5;
  col *= 1. - dot(e * vec2(1.1, .5), e * vec2(1.1, .5)) * .5;
  col += (h1(p + 3.1) - .5) / 170.; // dither: near-black gradients band without it
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
function glow(x, y, r, rgb, a) { // light adds to what is under it
  if (a <= 0 || r <= 0) return;
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  const g = ctx.createRadialGradient(x, y, 0, x, y, r);
  g.addColorStop(0, `rgba(${rgb}, ${a})`);
  g.addColorStop(0.4, `rgba(${rgb}, ${a * 0.32})`);
  g.addColorStop(1, `rgba(${rgb}, 0)`);
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
  ctx.restore();
}
function dot(x, y, r, colour) { ctx.fillStyle = colour; ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill(); }
// A solved level's light: a small core in a soft halo of its tier's colour.
function lum(x, y, rgb, b, size = 1) {
  glow(x, y, 46 * size, rgb, 0.16 * b);
  glow(x, y, 15 * size, rgb, 0.6 * b);
  dot(x, y, 2.9 * size, `rgba(246, 255, 250, ${0.55 + 0.45 * b})`);
}
// The lamp itself.
function lampOrb(x, y, r, b = 1) {
  glow(x, y, r * 9, WARM, 0.2 * b);
  glow(x, y, r * 3.4, WARM, 0.55 * b);
  dot(x, y, r, '#fff6e2');
}
function hollow(x, y, r, a = 1) {
  ctx.strokeStyle = ink(0.62 * a); ctx.lineWidth = 1.2;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke();
}
// Result marks: dots, filled earned, hollow not.
function marks(x, y, n, r = 3.2, gap = 9, a = 1) {
  for (let k = 0; k < 3; k++) {
    if (k < n) dot(x + k * gap, y, r, ink(0.9 * a)); else hollow(x + k * gap, y, r - 0.5, a);
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
// Nothing of the water's chrome draws under the status bar.
const under = (y) => AX ? ramp(y, 120, 190) : ramp(y, 58, 104);
function bob(t, k, amp = 2.2) { return RM ? 0 : amp * Math.sin(t * 0.0012 + k * 1.9); }
function wavy(x, t) { return 3.5 * Math.sin(x * 0.024 + t * 0.0011) + 2 * Math.sin(x * 0.063 - t * 0.0016 + 1.3); }
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

// ---------------------------------------------------------------- scenes
// The whole column on one screen: dusk over the surface, today in the last daylight, each tier a band of dark
// water with its levels as motes, the solved ones alight, the lamp where the player is.
function overview(t, a) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const g = groundTime(t);
  text('UNSTIR', 32, 128, `250 ${World.pt('display')}px UPro`, INK, 'left', 9);
  // the buoy: settings
  const by = 196 + wavy(388, g) + bob(t, 0, 1.2);
  glow(388, by - 2, 26, WARM, 0.4); dot(388, by - 2, 4.6, '#fff6e2');
  text('settings', 368, by - 16, F.ui(World.pt('detail')), ink(0.82), 'right');
  // today, in the last of the daylight
  const sun = RM ? 1 : 0.85 + 0.15 * Math.sin(t * 0.0016);
  glow(58, 264, 70, '255, 196, 130', 0.3 * sun);
  dot(58, 264, 6.5, '#fff3dc');
  text('today', 86, 258, F.word(World.pt('title')), INK);
  text('daily · Mon 23 Nov', 86, 284, F.ui(World.pt('body')), ink(0.92));
  const w = text('4 days running', 86, 306, F.data(World.pt('detail')), ink(0.76));
  marks(86 + w + 14, 301, 2);
  dot(262, 334, 2.6, ink(0.6));
  text('archive', 276, 339, F.ui(World.pt('body')), ink(0.8));
  text('comes with any pack', 276, 359, F.ui(World.pt('detail')), ink(0.66));
  const tiers = [
    { name: 'plughole', y0: 370, y1: 530, note: '13 of 27 at par', lit: 13, nameA: 0.95 },
    { name: 'whirlpool', y0: 530, y1: 675, note: 'opens with every plughole level solved', lit: 0, nameA: 0.74 },
    { name: 'vortex', y0: 675, y1: 790, note: 'opens with every whirlpool level solved', lit: 0, nameA: 0.74 },
    { name: 'maelstrom', y0: 790, y1: 880, note: 'opens with every vortex level solved', lit: 0, nameA: 0.74 },
  ];
  tiers.forEach((tr, i) => {
    const ny = tr.y0 + 36;
    text(tr.name, 32, ny, F.word(World.pt('title')), ink(tr.nameA));
    text(tr.note, 33, ny + 22, F.ui(World.pt('detail')), ink(0.7));
    for (let k = 0; k < 27; k++) {
      const f = k / 26;
      const L = live(tr.name, t, k + i * 30);
      const x = 348 + 54 * Math.sin(f * Math.PI * 1.6 + 0.4 + i * 0.7);
      const y = tr.y0 + 20 + (tr.y1 - tr.y0 - 40) * f + L.dy * 0.5;
      if (k < tr.lit) lum(x, y, TIER[tr.name].rgb, L.b, 0.62);
      else if (i === 0 && k === tr.lit) lampOrb(x, y, 3.6);
      else {
        const near = i === 0 ? lampAt(x, y) : 0;
        dot(x, y, 1.5, `rgba(${TIER[tr.name].rgb}, ${0.2 + 0.26 * L.b + 0.3 * near})`);
      }
    }
  });
  // endless: a far light at the bottom of everything
  glow(220, 908, 86, '255, 170, 110', RM ? 0.16 : 0.13 + 0.04 * Math.sin(t * 0.0007));
  text('endless', 220, 912, F.word(World.pt('title')), ink(0.9), 'center');
  text('best 9', 220, 934, F.data(World.pt('detail')), ink(0.7), 'center');
  ctx.restore();
}

// The dive: levels at their depths on a meandering lane. Solved ones glow; the lamp sits at the next; the levels
// just past it show in its light, and those beyond are motes in the dark.
function dive(t, cam, a) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const f = front(t);
  const pY = levelY(-1.6) - cam, wY = levelY(27.8) - cam;
  if (pY > -40 && pY < 1000) text('plughole', 32, pY, F.word(World.pt('title')), ink(0.8 * under(pY)));
  if (wY > -40 && wY < 1000) {
    text('whirlpool', 32, wY, F.word(World.pt('title')), ink(0.8 * under(wY)));
    if (f < 28) text('opens with every plughole level solved', 33, wY + 22, F.ui(World.pt('detail')), ink(0.66 * under(wY)));
  }
  const body = World.pt('body'), pad = (n) => String(n).padStart(2, '0');
  for (let n = 1; n <= 27; n++) {
    const L = live('plughole', t, n);
    const y = levelY(n) - cam + bob(t, n, 1.4);
    if (y < 20 || y > 990) continue;
    const u = under(y);
    if (u <= 0) continue;
    const x = laneX(n), nx = x + (AX ? 26 : 24);
    const near = lampAt(x, y), on = lit(n, t);
    ctx.save(); ctx.globalAlpha = a * u;
    if (n === NEXT && f === NEXT) {
      lampOrb(x, y, 6.5, RM ? 1 : 0.9 + 0.1 * Math.sin(t * 0.0019));
      const ti = World.pt('title') * 1.15;
      const base = y + ti * 0.36;
      const w = text(pad(n), nx, base, F.data(body), ink(0.8));
      text(NAMES[n - 1], nx + w + (AX ? 14 : 9), base, F.name(ti), INK);
      text('4 rods · par 4', nx, base + World.pt('label') * 1.5, F.data(World.pt('label')), ink(0.8));
    } else if (on > 0) {
      lum(x, y, TIER.plughole.rgb, L.b * on);
      const ta = (0.66 + 0.26 * near) * mix(0.9, 1, on);
      const base = y + body * 0.35;
      const w = text(pad(n), nx, base, F.data(body), ink(ta * 0.85));
      const w2 = text(NAMES[n - 1], nx + w + (AX ? 12 : 8), base, F.ui(body, 350), ink(ta));
      ctx.globalAlpha = a * u * on;
      marks(nx + w + w2 + (AX ? 30 : 21), base - body * 0.32, 2, AX ? 5 : 3.2, AX ? 14 : 9, ta + 0.1);
    } else {
      const vis = ramp(near, 0.1, 0.15); // a name is readable or absent, never half-lit
      dot(x, y, 1.6 + 1.2 * vis, ink(0.22 + 0.4 * vis));
      if (vis > 0) {
        const base = y + body * 0.35;
        const w = text(pad(n), nx, base, F.data(body), ink(0.6 * vis));
        text(NAMES[n - 1], nx + w + (AX ? 12 : 8), base, F.ui(body, 350), ink(0.68 * vis));
      }
    }
    ctx.restore();
  }
  // packs: far glows, each its own cover, breathing slowly
  if (!AX) PACKS.forEach((pk, i) => {
    const y = levelY(pk.m) - cam + bob(t, i + 40, 4);
    if (y < -80 || y > 1040) return;
    const u = under(y);
    const b = RM ? 1 : 0.82 + 0.18 * Math.sin(t * 0.0009 + i * 2.1);
    ctx.save(); ctx.globalAlpha = a * u;
    glow(pk.x, y, 96, pk.glow, 0.17 * b);
    glow(pk.x, y, 44, pk.glow, 0.3 * b);
    World.disc(ctx, 'cover-' + pk.id, pk.x, y, 54, a * u);
    text(pk.name, pk.x, y + 50, F.ui(World.pt('detail')), ink(0.76), 'center');
    ctx.restore();
  });
  ctx.restore();
}

// A level's tank in a pool of plain light, the water around it dark and still.
function playChrome(t, a, o) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const T = o.tank;
  text('↑ levels', 28, AX ? 104 : 96, F.ui(World.pt('body')), ink(0.84));
  if (o.count) text(o.count, AX ? 28 : 412, AX ? 150 : 96, F.data(World.pt('label')), ink(0.76), AX ? 'left' : 'right');
  const titleY = T.y - T.d / 2 - (AX ? 24 : 54);
  text(o.where, 220, titleY - (AX ? 60 : 36), F.data(World.pt('detail')), o.prism ? '#ffffff' : ink(0.72), 'center');
  text(o.title, 220, titleY, F.name(World.pt('display')), o.prism ? '#ffffff' : INK, 'center');
  ctx.restore();
}
function tank(name, T, a, s = 1, rgb = '200, 215, 230', k = 0.1) {
  if (a <= 0) return;
  const d = T.d * s;
  ctx.save(); ctx.globalAlpha = a;
  glow(T.x, T.y, d * 0.7, rgb, k);
  World.disc(ctx, name, T.x, T.y, d, a);
  ctx.restore();
}
function noteAndControls(t, a, o) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const T = o.tank;
  let y = T.y + T.d / 2 + (AX ? 56 : 42);
  const lines = AX ? wrap(o.note.join(' '), F.word(World.pt('body')), 392) : o.note;
  for (const line of lines) { text(line, 220, y, F.word(World.pt('body')), ink(0.84), 'center'); y += AX ? 47 : 25; }
  const cy = AX ? 890 : 878, b = World.pt('body');
  glow(40, cy, 30, WARM, 0.3); dot(40, cy, 4, '#fff6e2');
  text(o.undo, 58, cy + b * 0.35, F.ui(b), ink(0.88));
  glow(400, cy, 30, WARM, 0.3); dot(400, cy, 4, '#fff6e2');
  text('reset', 382, cy + b * 0.35, F.ui(b), ink(0.88), 'right');
  ctx.restore();
}

function resultScene(t, a, t0) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const T = TANK_RESULT, rgb = TIER.plughole.rgb;
  // sparks of the tier's light drift up from the solved tank to join the trail
  if (!RM) for (let k = 0; k < 16; k++) {
    const st = t0 + 500 + k * 130;
    const life = ramp(t, st, st + 3200);
    if (life <= 0 || life >= 1) continue;
    const x = T.x + Math.sin(k * 12.9898) * T.d * 0.42 + 5 * Math.sin(life * 5 + k);
    const y = T.y - T.d * 0.42 - life * 260;
    const b = Math.sin(Math.PI * life);
    glow(x, y, 10, rgb, 0.5 * b); dot(x, y, 1.3, `rgba(240, 255, 250, ${0.8 * b})`);
  }
  text('↑ levels', 28, 96, F.ui(World.pt('body')), ink(0.84));
  text('27 Drain', 220, 140, F.data(World.pt('label')), ink(0.78), 'center');
  const rise = RM ? 1 : settle(ramp(t, t0 + 300, t0 + 1500));
  ctx.save(); ctx.globalAlpha = a * (RM ? ramp(t, t0, t0 + 200) : ease(ramp(t, t0 + 300, t0 + 900)));
  text('unstirred.', 220, 210 + (1 - rise) * 30, F.word(World.pt('display')), INK, 'center');
  ctx.restore();
  const mA = RM ? 1 : ease(ramp(t, t0 + 900, t0 + 1500));
  ctx.save(); ctx.globalAlpha = a * mA;
  const my = T.y + T.d / 2 + 46 + (RM ? 0 : (1 - settle(ramp(t, t0 + 900, t0 + 1700))) * 14);
  [196, 220, 244].forEach((x, k) => {
    if (k < 2) { glow(x, my, 20, rgb, 0.5); dot(x, my, 6, ink(0.96)); } else hollow(x, my, 5.5, 1);
  });
  text('at par · new best, was +6', 220, my + 40, F.ui(World.pt('body')), ink(0.92), 'center');
  text('clean needs no undo or reset', 220, my + 63, F.ui(World.pt('detail')), ink(0.68), 'center');
  ctx.restore();
  const nA = RM ? 1 : ease(ramp(t, t0 + 1400, t0 + 2100));
  ctx.save(); ctx.globalAlpha = a * nA;
  text('again', 30, 888, F.ui(World.pt('body')), ink(0.8));
  // the next tier's light, far below
  glow(372, 906, 130, TIER.whirlpool.rgb, 0.2);
  text('deeper', 410, 860, F.word(World.pt('label')), ink(0.76), 'right');
  text('whirlpool ›', 410, 888, `300 ${World.pt('title') * 0.82}px UPro`, INK, 'right');
  ctx.restore();
  ctx.restore();
}

function packScene(t, a, t0) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const arr = (k) => RM ? 1 : ease(ramp(t, t0 + 500 + k * 130, t0 + 1200 + k * 130));
  text('↑ menu', 28, 96, F.ui(World.pt('body')), ink(0.84));
  const lift = (k) => RM ? 0 : (1 - settle(ramp(t, t0 + 500 + k * 130, t0 + 1500 + k * 130))) * 14;
  const line = (k, s, y, font, colour) => { ctx.save(); ctx.globalAlpha = a * arr(k); text(s, 220, y + lift(k), font, colour, 'center'); ctx.restore(); };
  line(0, 'Prism', 512, `200 ${World.pt('display') * 1.3}px UPro`, '#ffffff');
  line(1, 'each rod stirs only some colours', 546, F.word(World.pt('body')), ink(0.9));
  line(2, '30 specimens in five trays', 592, F.ui(World.pt('label')), ink(0.86));
  line(2, 'levels 1–3 free, no purchase', 614, F.ui(World.pt('label')), ink(0.86));
  line(3, 'letters for colour-blind play, in settings', 640, F.ui(World.pt('detail')), ink(0.68));
  ctx.save(); ctx.globalAlpha = a * arr(4);
  const by = 700 + lift(4);
  lampOrb(84, by - 6, 5.5);
  text('buy $2.99', 102, by, F.ui(World.pt('body'), 600), '#ffffff');
  text('try 3 free ›', 356, by, F.ui(World.pt('body')), ink(0.88), 'right');
  text('or all three in Triptych I · $5.99 · save $2.98 ›', 220, by + 36, F.ui(World.pt('detail')), ink(0.7), 'center');
  ctx.restore();
  // its 30 specimens as five small shoals, the first three alight (free)
  ctx.save(); ctx.globalAlpha = a * arr(5);
  for (let tray = 0; tray < 5; tray++) {
    for (let k = 0; k < 6; k++) {
      const i = tray * 6 + k;
      const x = 66 + tray * 77 + k * 9;
      const y = 812 + 10 * Math.sin(k * 0.9 + tray) + bob(t, i + 90, 1.4);
      if (i < 3) lum(x, y, '235, 240, 255', RM ? 1 : 0.85 + 0.15 * Math.sin(t * 0.0015 + i), 0.6); else dot(x, y, 1.7, ink(0.34));
    }
  }
  text('the first three are free to play', 220, 852, F.ui(World.pt('detail')), ink(0.66), 'center');
  text('restore purchases', 220, 906, F.ui(World.pt('detail')), ink(0.7), 'center');
  ctx.restore();
  ctx.restore();
}

// Settings live at the surface, in the last of the daylight: each switch a lamp afloat on the waterline, lit or dark.
function settingsScene(t, a, t0, cam) {
  if (a <= 0) return;
  ctx.save(); ctx.globalAlpha = a;
  const sY = -cam, g = groundTime(t);
  const arr = (k) => RM ? 1 : ease(ramp(t, t0 + k * 140, t0 + 700 + k * 140));
  ctx.save(); ctx.globalAlpha = a * arr(0);
  text('settings', 32, 176, F.word(World.pt('display')), INK);
  ctx.restore();
  const buoys = [['music', true, 70], ['sounds', true, 170], ['haptics', true, 270], ['colour letters', false, 370]];
  buoys.forEach(([name, on, x], k) => {
    const rise = RM ? 0 : (1 - settle(ramp(t, t0 + 200 + k * 150, t0 + 1300 + k * 150))) * 40;
    const y = sY + wavy(x, g) + bob(t, k + 100, 1.6) + rise - 3;
    ctx.save(); ctx.globalAlpha = a * arr(k + 1);
    if (on) { glow(x, y, 64, WARM, 0.34); glow(x, y + 30, 40, WARM, 0.1); dot(x, y, 8, '#fff6e2'); }
    else { dot(x, y, 8, 'rgba(8, 14, 20, 0.92)'); hollow(x, y, 8, 0.9); }
    text(name, x, sY + 50, F.ui(World.pt('body')), ink(on ? 0.95 : 0.8), 'center');
    text(on ? 'on' : 'off', x, sY + 72, F.data(World.pt('detail')), ink(0.72), 'center');
    ctx.restore();
  });
  ctx.save(); ctx.globalAlpha = a * arr(5);
  text('restore purchases', 40, sY + 172, F.ui(World.pt('body')), ink(0.9));
  text('report a problem ↗', 150, sY + 240, F.ui(World.pt('body')), ink(0.9));
  text('privacy policy ↗', 70, sY + 308, F.ui(World.pt('body')), ink(0.9));
  text('Unstir 1.0 (1)', 220, sY + 396, F.data(World.pt('detail')), ink(0.66), 'center');
  // the way back: the trail's first light, far below
  lum(220, 868, TIER.plughole.rgb, RM ? 1 : 0.8 + 0.2 * Math.sin(t * 0.0014), 0.9);
  text('↓ back into the water', 220, 906, F.ui(World.pt('detail')), ink(0.72), 'center');
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
  [19900, 20300, 20600, 386, levelY(16.5) - CAM.menu15, 386, levelY(16.5) - CAM.menu15], // Prism's glow
  [24200, 24500, 24800, 58, 92, 58, 92],      // ↑ menu
  [26300, 26600, 26900, 388, -CAM.surface, 388, -CAM.surface], // the buoy
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
  LAMP = lamp(t, cam);
  if (t >= 36000) return prismLevel(t);
  overview(t, ov(t));
  // the levels stay in view while the camera sinks between screens, so a dive passes the lights it crosses
  const menuA = t < 3000 ? 0 : span(t, 2950, 3700, 8700, 9300) + span(t, 13150, 13500, 14200, 14650) + span(t, 18900, 19800, 20500, 21200) + 0.9 * span(t, 24800, 25200, 26300, 26700);
  dive(t, cam, Math.min(1, menuA));
  // play: Drop's light opens into its tank
  const openK = RM ? (t >= 9550 ? 1 : 0) : settle(ramp(t, 8900, 10200));
  const playA = t >= 8900 && t < 13600 ? (RM ? span(t, 9200, 9900, 12700, 13300) : ease(ramp(t, 8900, 9300)) * (1 - ease(ramp(t, 12700, 13300)))) : 0;
  if (playA > 0) {
    const src = { x: laneX(1), y: levelY(1) - CAM.menu1 };
    const T = { x: mix(src.x, TANK_PLAY.x, openK), y: mix(src.y, TANK_PLAY.y, openK), d: TANK_PLAY.d };
    tank('play01', T, playA, mix(0.04, 1, openK));
    const chromeA = playA * (RM ? 1 : ease(ramp(t, 9700, 10500)));
    const o = { tank: TANK_PLAY, title: 'Drop', where: 'plughole · 01', count: 'moves 0 / par 1',
      note: ['Turn a rod to look. Let go where', 'you started and nothing happens.'], undo: 'undo · 10' };
    playChrome(t, chromeA, o);
    noteAndControls(t, chromeA, o);
  }
  // the result at 27: the tank kindles in its tier's light
  const resA = span(t, 14500, 15000, 18700, 19300);
  if (resA > 0) {
    const kin = RM ? 1 : settle(ramp(t, 15000, 16600));
    tank('drain-solved', TANK_RESULT, resA * (RM ? 1 : ease(ramp(t, 14500, 15100))), 1, TIER.plughole.rgb, 0.1 + 0.3 * kin);
    resultScene(t, resA, 14600);
  }
  // Prism's card: its far glow comes near
  const pA = packMix(t);
  if (pA > 0) {
    const k = RM ? 1 : settle(ramp(t, 20600, 21900));
    const src = { x: 386, y: levelY(16.5) - CAM.menu15 };
    const T = { x: mix(src.x, 220, k), y: mix(src.y, 296, k), d: mix(54, 290, k) };
    ctx.save(); ctx.globalAlpha = pA;
    glow(T.x, T.y, T.d * 0.78, '225, 232, 255', 0.16);
    World.disc(ctx, 'prism-clip', T.x, T.y, T.d, pA);
    ctx.restore();
    packScene(t, pA, 21000);
  }
  settingsScene(t, settingsMix(t), 26600, cam);
  touches(t);
  statusBar();
}

// Prism 01 in play: still dark water and white light; its number white, never one channel's colour.
function prismLevel(t) {
  const o = { tank: TANK_PLAY, title: 'Frond', where: 'Prism · 01', count: 'moves 0 / par 3', prism: true,
    note: ['Each rod stirs only its', 'knob’s colours.'], undo: 'undo · 10' };
  tank('prism01', TANK_PLAY, 1, 1, '255, 255, 255', 0.1);
  playChrome(t, 1, o);
  noteAndControls(t, 1, o);
  statusBar();
}

window.DRAWS_AX = true;
World.load(['play01', 'drain-solved', 'prism01', 'prism-clip', 'cover-lens', 'cover-escapement', 'cover-prism',
  'cover-triptych', 'status']).then(() => World.start({
  fonts: ['300 28px UPro', 'italic 300 28px NY', '400 13px UMono', '600 17px UPro', '200 40px UPro', '250 34px UPro', '350 17px UPro'],
  shader,
  uniforms: (t) => {
    const cam = camera(t);
    const L = lamp(t, cam);
    return {
      camY: cam, ov: ov(t), pk: packMix(t), tm: groundTime(t), PM, pkC: [220, 296], pr: prismMix(t),
      lampC: [L.x, L.y], lampR: L.r, lampA: L.a, warm: L.warm,
    };
  },
  draw,
  duration: DUR,
  shots: SHOTS,
}));
