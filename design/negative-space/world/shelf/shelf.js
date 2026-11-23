// Copyright © 2026 Jack Lusher. All rights reserved.
// The Shelf: the Descent as an illustrated place. The water is a cutaway beside an underwater slope that falls away in
// curving terraces; each level is a pebble resting on its own ledge, packs are lit hollows in the slope, and past the
// last ledge the shelf breaks into open deep water. The ground is one shader pass (water by depth, two hazy far ridges,
// the terraced shelf, a near silhouette, sinking motes); pebbles, type and glass are 2D on top. Depth comes from
// layers moving at different speeds. Nothing stirs: the UI sinks, rises, drifts and settles, and while a level plays
// the ground holds still.

const { ramp, ease, settle, mix } = World;
const RM = World.rm, AX = World.ax;
const PM = AX ? 196 : 110;            // points between two levels' ledges
const TOP = 420;                      // world y of ledge 0; the surface is world y 0
const PEB = AX ? 8 : 4.5;              // a ledge's top lies this far under its pebble's centre
const levelY = (n) => TOP + n * PM;
const NAMES = ['Drop', 'Drip', 'Trickle', 'Ripple', 'Bubble', 'Fizz', 'Sprinkle', 'Mist', 'Spray', 'Splash', 'Puddle',
  'Froth', 'Suds', 'Lather', 'Steam', 'Gurgle', 'Rinse', 'Drizzle', 'Shower', 'Downpour', 'Overflow', 'Bathwater',
  'Spin', 'Whirl', 'Spiral', 'Last drop', 'Drain'];
const RODS = [3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5];
const PARS = [1, 1, 2, 2, 3, 3, 4, 4, 5, 4, 5, 6, 7, 4, 5, 3, 7, 8, 6, 7, 5, 6, 7, 8, 8, 9, 9];
const DOTS = [3, 3, 3, 3, 2, 3, 3, 2, 3, 2, 2, 2, 2, 3, 2, 3, 2, 2, 3, 2, 2, 3, 2, 2, 3, 2, 2];

const INK = '#edeff7';
const ink = (a) => `rgba(237, 239, 247, ${a})`;
const F = {
  name: (s) => `300 ${s}px UPro`,
  word: (s) => `italic 300 ${s}px NY`,
  data: (s) => `400 ${s}px UMono`,
  ui: (s, w = 400) => `${w} ${s}px UPro`,
};

// Packs are hollows in the slope, each lit from inside by its own cover.
const PACKS = [
  { id: 'first-stir', name: 'First Stir', m: 2.5, glow: '255, 196, 140', fresh: false },
  { id: 'lens', name: 'Lens', m: 6.5, glow: '255, 90, 214', fresh: true },
  { id: 'escapement', name: 'Escapement', m: 11.5, glow: '255, 150, 110', fresh: true },
  { id: 'prism', name: 'Prism', m: 16.5, glow: '214, 228, 255', fresh: true },
  { id: 'triptych', name: 'Triptych I', m: 21.5, glow: '255, 206, 130', fresh: false },
];

// ---------------------------------------------------------------- the shelf's shape, the same in the shader
// Ledge k's lip reaches out to tipX(k); under it the rock cuts back by the overhang and leans out again to the next.
const G = AX ? { tb: 62, ta: 5, la: 3, ovs: 0.7 } : { tb: 170, ta: 14, la: 8, ovs: 1 };
const tipX = (k) => G.tb + G.ta * Math.sin(k * 0.85 + 0.6) + 0.5 * G.ta * Math.sin(k * 0.31 + 2.0) + G.la * Math.sin(k * 2.4 + 1.0);
const pebX = (k) => tipX(k) - (AX ? 17 : 23);
// The overview's shelf: fifteen long ledges 40 pt apart, three to a tier, then the break.
const O = { y0: 262, pitch: 40 };
const wallO = (u) => 40 + 8 * Math.sin(u * 0.9 + 1.0);
const tipO = (k) => wallO(k) + 108 + 9 * Math.sin(k * 1.7 + 0.4);
const bowO = (k, x) => 3.4 * Math.sin(x * 0.021 + k * 1.3) + 0.03 * (x - 60);   // a ledge's top is never straight
const topO = (k, x = 100) => O.y0 + O.pitch * k + bowO(k, x);
const bankH = (x) => 26 * Math.exp(-((x / 80) ** 2)) - 6;   // the shelf's dry top, above the water line
const seatY = (x) => 902 + 8 * Math.sin(x * 0.0085 + 1.2) - 3 * Math.sin(x * 0.021 + 0.4);
const g1 = (v) => v.toFixed(2);

// ---------------------------------------------------------------- the timeline
// Long moves ease out; short ones settle with a small overshoot, as a body finds its depth.
// 0     the whole shelf at rest (overview)          menu-today
// 2.6   a finger taps plughole; the view sinks to 14
// 5.2   the slope at 14 at rest                       menu
// 7.0   a finger draws the water down: rise to 01
// 8.9   tapping Drop's pebble opens its tank
// 10.4  play at rest, the ground held still           play
// 12.6  later, deeper: sink to 27
// 14.6  the result arrives                            result
// 18.4  "↑ levels": rise to 15
// 20.2  tapping Prism's hollow opens it
// 22.6  pack at rest                                  pack
// 24.6  "↑ menu", rise to the surface, tap the stone on the bank
// 27.0  settings at rest                              settings
const DUR = 29600;
const SHOTS = AX ? { menu: 6400, play: 11800 }
  : { 'menu-today': 1800, menu: 6400, play: 11800, result: 17600, pack: 23800, settings: 28600, prism: 40000 };

const CAM = {
  overview: 0,
  menu14: levelY(14) - 470,
  menu1: levelY(1) - 470,
  play: levelY(1) - 474,
  result: levelY(27) - 467,
  menu15: levelY(15.6) - 470,
  surface: -180,
};

function span(t, a, b, c, d) { // fades in over a..b, out over c..d; under Reduce Motion both are short fades
  if (RM) { const m1 = (a + b) / 2, m2 = (c + d) / 2; return ramp(t, m1 - 120, m1 + 120) * (1 - ramp(t, m2 - 120, m2 + 120)); }
  return ease(ramp(t, a, b)) * (1 - ease(ramp(t, c, d)));
}
function move(t, a, b, from, to, curve = ease) {
  if (RM) return t < (a + b) / 2 ? from : to;
  return mix(from, to, curve(ramp(t, a, b)));
}
function camera(t) {
  if (t >= 36000) return CAM.play;
  if (t < 3000) return CAM.overview;
  let y = move(t, 3000, 5200, CAM.overview, CAM.menu14);
  if (t >= 7000) y = move(t, 7000, 8700, CAM.menu14, CAM.menu1, settle);
  if (t >= 8700) y = move(t, 8900, 10200, CAM.menu1, CAM.play);
  if (t >= 12600) y = move(t, 12800, 14600, CAM.play, CAM.result);
  if (t >= 18400) y = move(t, 18600, 20200, CAM.result, CAM.menu15, settle);
  if (t >= 24600) y = move(t, 24900, 26400, CAM.menu15, CAM.surface);
  return y;
}
const ov = (t) => t >= 36000 ? 0 : (RM ? (t < 3000 ? 1 : 0) : 1 - ease(ramp(t, 2950, 3500)));
const packMix = (t) => t >= 36000 ? 0 : span(t, 20600, 21600, 24700, 25400);
const prismMix = (t) => t >= 36000 ? 1 : 0;
// A level takes the screen: the shelf draws aside and one terrace rises under the tank.
const levelMix = (t) => t >= 36000 ? 1 : Math.min(1, span(t, 8900, 10000, 12700, 13300) + span(t, 14300, 15000, 18600, 19300));
// The ground's own clock: it stops while a level plays.
const clock = (t) => RM ? 0 : t >= 36000 ? 9800 : t < 9800 ? t : t < 12700 ? 9800 : t - 2900;
const NEXT = (t) => t >= 12000 && t < 36000 ? 28 : 14;

// ---------------------------------------------------------------- the ground
const shader = `
uniform float camY, ov, pk, pr, tm, lv, glint, near;
uniform vec2 pkC;
const float PM = ${g1(PM)}, TOP = ${g1(TOP)}, PEB = ${g1(PEB)};
float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float nz(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3. - 2. * f);
  return mix(mix(h1(i), h1(i + vec2(1, 0)), f.x), mix(h1(i + vec2(0, 1)), h1(i + vec2(1, 1)), f.x), f.y); }
float ss(float x) { return smoothstep(-.7, .7, x); }
float g2(float x) { return exp(-x * x); }
float tierD(float k) { return clamp(floor((k - 1.) / 27.), 0., 3.); }
float tierO(float k) { return clamp(floor((k - 3.) / 3.), 0., 3.); }
float tipD(float k) { return ${g1(G.tb)} + ${g1(G.ta)} * sin(k * .85 + .6) + ${g1(G.ta * 0.5)} * sin(k * .31 + 2.) + ${g1(G.la)} * sin(k * 2.4 + 1.); }
// a tier's ledges: the lip's thickness, its overhang, how blunt its nose is, ripples down its face
vec4 shapeD(float t) { return (t < .5 ? vec4(56., 42., 1.7, 0.) : t < 1.5 ? vec4(64., 46., 1.9, 3.) : t < 2.5 ? vec4(28., 60., 1.2, 0.) : vec4(80., 40., 2.4, 0.)) * vec4(1., ${g1(G.ovs)}, 1., 1.); }
float prevEnd(float k) { return min(tipD(k - 1.), tipD(k)) - .85 * shapeD(tierD(k - 1.)).y; }
float edgeD(float k, float f) { // the rock's edge f points under ledge k's top
  vec4 sp = shapeD(tierD(k));
  float tip = tipD(k);
  float e = tip - sp.y * smoothstep(0., 1., pow(clamp(f / sp.x, 0., 1.), sp.z));
  float s = clamp((f - sp.x) / (PM - sp.x), 0., 1.);
  float b = sin(3.1416 * s);
  e = mix(e, prevEnd(k + 1.), s * s * (3. - 2. * s)) + 4. * b * b + (sp.w + 1.) * sin(f * .19 + k) * b * b;
  return e - (tip - prevEnd(k)) * pow(max(1. - f / 10., 0.), 3.);
}
float wallO(float u) { return 40. + 8. * sin(u * .9 + 1.) - 110. * max(u - 14.6, 0.); }
float lenO(float k) { return 108. + 9. * sin(k * 1.7 + .4); }
float ovM(float y) { // the overview's depth: the surface at 180, four tiers of 120 pt from 362, then the deep
  if (y < 362.) return mix(-3.8, 0., (y - 180.) / 182.);
  if (y < 842.) return (y - 362.) / 120. * 27.;
  return 108. + (y - 842.) / 114. * 20.;
}
vec3 water(float m) {
  vec3 c = mix(vec3(.075, .30, .31), vec3(.018, .125, .165), smoothstep(-3.8, 11., m));
  c = mix(c, vec3(.105, .03, .155), smoothstep(24., 31., m));
  c = mix(c, vec3(.02, .04, .15), smoothstep(51., 58., m));
  c = mix(c, vec3(.10, .016, .024), smoothstep(78., 85., m));
  c = mix(c, vec3(.008, .006, .014), smoothstep(107., 128., m));
  return c;
}
// Each tier's rock: sandstone, mauve scallops, slate plates, basalt pillows.
vec3 rockC(float t) { return t < .5 ? vec3(.50, .36, .27) : t < 1.5 ? vec3(.30, .165, .32) : t < 2.5 ? vec3(.12, .185, .36) : vec3(.23, .075, .07); }
vec3 litC(float t) { return t < .5 ? vec3(1., .82, .55) : t < 1.5 ? vec3(1., .62, .86) : t < 2.5 ? vec3(.55, .76, 1.) : vec3(1., .46, .26); }
// the overview's ledges: thickness as a share of the pitch, the underside's curve, the tip's droop, scallops
vec4 shapeO(float t) { return t < .5 ? vec4(.9, 1.7, 4., 0.) : t < 1.5 ? vec4(.94, 1.4, 5., 2.2) : t < 2.5 ? vec4(.7, 2.6, 2.5, 0.) : vec4(.98, 1.1, 6., 0.); }

// rock by how lit it is: shadows take the water's colour, lit faces the tier's own
vec3 sand(vec3 R, vec3 Lc, vec3 wc, float tone, float cl) {
  return mix(mix(R * .5, wc * 2.4, .42), R * 1.36 + Lc * .05, smoothstep(.4, 1.3, tone)) + Lc * cl;
}
vec3 scene(vec2 p, float o) {
  float cam = o > .5 ? 0. : camY;
  float wy = p.y + cam;
  float m = o > .5 ? ovM(p.y) : (wy - TOP) / PM;
  float sY0 = o > .5 ? 180. : -cam;
  float sY = sY0 + 3.2 * sin(p.x * .024 + tm * .0011) + 1.8 * sin(p.x * .063 - tm * .0016 + 1.3);
  float d = p.y - sY;
  vec3 wc = water(m);
  vec3 col;
  if (d < 0.) { // the air: dusk, warm along the water
    float g = exp(d / 62.);
    col = mix(vec3(.03, .028, .05), vec3(.60, .37, .21), g * .8);
    col += vec3(.5, .3, .12) * exp(-length((p - vec2(60., sY0)) * vec2(.006, .02))) * .22;
  } else {
    col = wc;
    float sx = p.x + d * .32 + tm * .004;
    float s = nz(vec2(sx * .016, 1.7)) * nz(vec2(sx * .041 + 9., tm * .00012));
    s = smoothstep(.12, .55, s) * exp(-max(m + 3.8, 0.) / 8.);
    col += vec3(.85, .78, .55) * s * .10;
    col += vec3(.55, .50, .30) * exp(-d / 46.) * .16;
    col += vec3(.45, .30, .10) * exp(-length((p - vec2(40., sY0)) * vec2(.004, .0046))) * .16;
    col += vec3(1., .9, .72) * exp(-abs(d) / 1.3) * .5;
  }
  float under = step(0., d);
  // two far ridges, hazed to the water's own colour, each moving slower than the shelf
  for (int j = 0; j < 2; j++) {
    float fj = float(j);
    float yy = o > .5 ? p.y * 1.5 + 300. * fj : p.y + cam * (.3 + .28 * fj);
    float e = 318. + 72. * fj + (38. - 12. * fj) * sin(yy * (.0057 + .0031 * fj) + 1.7 * fj + .4)
      + 13. * sin(yy * .0173 + 4. * fj) + 4.5 * sin(yy * .061 + fj);
    float inR = smoothstep(-1.2 - 1.5 * (1. - fj), 1.2 + 1.5 * (1. - fj), p.x - e);
    vec3 rc = fj < .5 ? wc * 1.2 + vec3(.004, .012, .014) : wc * .6;
    rc += wc * .35 * exp(-max(p.x - e, 0.) / 9.) * (.5 + .5 * sin(yy * .061 + fj + 1.6));
    col = mix(col, rc, inR * under * smoothstep(0., 40., d));
  }
  // the shelf
  float x = p.x + 280. * lv * (1. - o);
  float sun = exp(-max(m + 3.8, 0.) / 26.) * .75 + .25;
  float swell = 84. * g2((p.y - sY0) / 66.);
  float below = ss(p.y - (sY0 - (26. * g2(x / 80.) - 6.)));
  float mask, tier, tone, cl;
  if (o > .5) {
    float u = (p.y - 262.) / 40.;
    float k = floor(u), f = (u - k) * 40.;
    f -= 3.4 * sin(x * .021 + k * 1.3) + .03 * (x - 60.);
    tier = tierO(k);
    vec4 sp = shapeO(tier);
    float L = lenO(k), tip = wallO(k) + L;
    float has = step(0., k) * step(k, 14.);
    float xr = tip - x;
    float top = sp.z * pow(1. - smoothstep(0., 26., xr), 2.);
    float bot = top + sp.x * 40. * pow(clamp(xr / L, 0., 1.), sp.y) + sp.w * sin(xr * .17) * smoothstep(0., 18., xr);
    float inL = has * ss(f - top) * ss(bot - f) * ss(xr);
    float B = max(wallO(u), swell);
    float v = clamp((f - top) / max(bot - top, 1.), 0., 1.);
    float dap = .7 + .6 * nz(vec2(x * .06 + tm * .0003, k * 3.1 + tm * .0002));
    float lt = mix(1.3, .46, pow(v, .7)) * (.82 + .3 * sun);
    float wt = (.6 + .22 * exp(-max(B - x, 0.) / 9.)) * (.8 + .3 * sun);
    wt *= 1. - .4 * has * exp(-max(f - bot, 0.) / 7.) * step(0., xr) * step(bot, f);
    tone = mix(wt, lt, inL);
    cl = (exp(-max(f - top, 0.) / 2.4) * .6 + exp(-max(f - top, 0.) / 9.) * .16) * dap * sun * inL;
    mask = max(inL, ss(B - x));
  } else {
    float u = (wy - TOP - PEB) / PM;
    float k = floor(u), f = (u - k) * PM;
    tier = tierD(k);
    vec4 sp = shapeD(tier);
    float e0 = edgeD(k, f), sl = (edgeD(k, f + .6) - e0) / .6;
    e0 = max(e0, swell);
    float din = e0 - x;
    mask = smoothstep(-.7, .7, din / sqrt(1. + sl * sl));
    float T = sp.x, tip = tipD(k), pe = prevEnd(k);
    float tf = f < T * 1.15 ? mix(1.32, .56, smoothstep(0., T * 1.15, f)) : mix(.56, .82, smoothstep(T, PM - 10., f));
    float w = smoothstep(pe - 2., pe + 26., x) * (1. - smoothstep(T * .9, T * 1.6, f));
    tone = mix(.76, tf, w);
    tone *= 1. - .38 * exp(-max(din, 0.) / 14.) * smoothstep(T * .45, T, f) * (1. - smoothstep(T, T + 36., f));
    tone *= .82 + .3 * sun;
    // sandstone: soft bands that bow with the slope, a little grain, darker towards the heart of the rock
    tone *= 1. + .05 * sin((u + x * x * .00002) * 9.4) + .035 * sin((u - x * .004) * 23.);
    tone *= .96 + .08 * nz(vec2(x * .11, wy * .11));
    tone *= mix(.72, 1., smoothstep(-20., 120., x));
    float fTop = 10. * (1. - pow(clamp((tip - x) / max(tip - pe, 1.), 0., 1.), 1. / 3.));
    cl = (exp(-max(f - fTop, 0.) / 2.6) * .62 + exp(-max(f - fTop, 0.) / 13.) * .2) * smoothstep(pe - 1., pe + 9., x) * step(f, T);
    float dap = .7 + .6 * nz(vec2(x * .06 + tm * .0003, k * 3.1 + tm * .0002));
    cl *= dap * sun;
  }
  vec3 rc = sand(rockC(tier), litC(tier), wc, tone, cl);
  rc = mix(rc, wc * 1.25, .2) * mix(1., .8, smoothstep(-3.8, 30., m));
  rc = mix(rc, vec3(.50, .36, .24) * (.75 + .5 * exp(min(d, 0.) / 9.)), 1. - under); // the dry bank, lit
  col = mix(col, rc, mask * below);
  if (o < .5) {
    // a near silhouette, out of focus, moving faster than the shelf
    float yy = p.y + cam * 1.55;
    float e = 446. - 40. * pow(max(sin(yy * .0047 + .9), 0.), 3.) - 5. * sin(yy * .019);
    col = mix(col, wc * .34, smoothstep(-9., 9., p.x - e) * .92 * near * under);
    // one terrace under the tank
    float ys = 956. + 70. - 124. * lv + 8. * sin(p.x * .0085 + 1.2) - 3. * sin(p.x * .021 + .4);
    float dd = p.y - ys;
    float st = mix(1.3, .5, smoothstep(0., 64., dd)) * (.82 + .3 * sun) * (.96 + .08 * nz(p * .11));
    st *= 1. + .05 * sin((dd + p.x * p.x * .0004) * .12);
    vec3 sc = sand(rockC(0.), litC(0.), wc, st, (exp(-max(dd, 0.) / 2.6) * .5 + exp(-max(dd, 0.) / 14.) * .16) * (.5 + .5 * sun + .5 * glint));
    sc = mix(sc, wc * 1.25, .2) * mix(1., .8, smoothstep(-3.8, 30., m));
    col = mix(col, sc, ss(dd) * step(.001, lv));
    // a solved tank catches the light
    col += vec3(1., .86, .6) * glint * g2((p.x - 250. + (p.y - 450.) * .3) / 170.) * exp(-p.y / 900.) * .085;
  }
  // sinking motes, three layers
  for (int j = 0; j < 3; j++) {
    float fk = float(j);
    float par = .35 + fk * .3;
    float cell = 46. + fk * 22.;
    vec2 q = vec2(p.x + fk * 37. - tm * .0012, p.y + cam * par - tm * (.004 + fk * .003)) / cell;
    vec2 id = floor(q), fr = fract(q) - .5;
    vec2 jo = vec2(h1(id), h1(id + 7.1)) - .5;
    float r = length((fr - jo * .7) * cell);
    float b = smoothstep(.7 + fk * .5, 0., r) * step(.55, h1(id + 3.3));
    col += vec3(.95, .9, .75) * b * (.08 + fk * .06) * under * (1. - smoothstep(60., 125., m));
  }
  return col;
}
// Inside a hollow: still water between two jambs of pale stone, a floor, one ledge, the cover's light split in three.
vec3 cave(vec2 p) {
  vec3 c = vec3(.02, .024, .036) + vec3(.03, .035, .05) * (1. - uv.y);
  vec2 v = p - pkC;
  float ang = atan(v.x, v.y);
  float fall = smoothstep(0., 40., v.y) * exp(-length(v) / 520.);
  vec3 rays = vec3(1., .16, .16) * g2((ang + .19) / .085) + vec3(.16, 1., .3) * g2(ang / .085) + vec3(.2, .4, 1.) * g2((ang - .19) / .085);
  c += rays * fall * .17;
  float low = smoothstep(640., 956., p.y);
  float jl = 20. + 12. * sin(p.y * .011 + 1.) + 5. * sin(p.y * .029) + 26. * low;
  float jr = 440. - (22. + 12. * sin(p.y * .0093 + 3.) + 5. * sin(p.y * .031 + 1.)) - 26. * low;
  float fl = 842. + 8. * sin(p.x * .012 + .5);
  float xr = 118. - p.x, f = p.y - 722. - 2.5 * sin(p.x * .05 + 1.);
  float top = 4. * pow(1. - smoothstep(0., 26., xr), 2.);
  float bot = top + 30. * pow(clamp(xr / 96., 0., 1.), 1.5);
  float inL = ss(f - top) * ss(bot - f) * ss(xr);
  float lit = .55 + .9 * exp(-length(v) / 380.);
  vec3 R = vec3(.105, .108, .125);
  vec3 rc = R * .8 * lit;
  rc = mix(rc, R * .6 * lit, max(ss(jl * .5 - p.x), ss(p.x - (440. - (440. - jr) * .5))));
  rc += R * exp(-max(min(jl - p.x, p.x - jr) , 0.) / 10.) * .25 * step(p.y, fl);
  vec3 fc = R * mix(1.25, .55, clamp((p.y - fl) / 70., 0., 1.)) + vec3(.8, .84, .9) * (exp(-max(p.y - fl, 0.) / 2.6) * .22 + exp(-max(p.y - fl, 0.) / 14.) * .07);
  rc = mix(rc, fc, ss(p.y - fl));
  vec3 lc = R * mix(1.5, .7, clamp((f - top) / max(bot - top, 1.), 0., 1.)) + vec3(.8, .84, .9) * exp(-max(f - top, 0.) / 2.4) * .3;
  rc = mix(rc, lc, inL);
  return mix(c, rc, max(max(ss(jl - p.x), ss(p.x - jr)), max(ss(p.y - fl), inL)));
}
void main() {
  vec2 p = uv * res;
  vec3 col = ov < 1. ? scene(p, 0.) : vec3(0);
  if (ov > 0.) col = mix(col, scene(p, 1.), ov);
  if (pk > 0.) col = mix(col, cave(p), pk);
  // the Prism level: clear water, white light
  float gr = dot(col, vec3(.3, .5, .2));
  col = mix(col, gr * vec3(.92, .98, 1.12), pr * .9);
  vec2 e = uv - .5;
  col *= 1. - dot(e * vec2(1.1, .5), e * vec2(1.1, .5)) * .5;
  o = vec4(col, 1);
}`;

// ---------------------------------------------------------------- 2D helpers
let ctx;
function text(s, x, y, font, colour, align = 'left', spacing = 0) {
  ctx.font = font; ctx.fillStyle = colour; ctx.textAlign = align; ctx.textBaseline = 'alphabetic';
  ctx.letterSpacing = spacing + 'px';
  ctx.fillText(s, x, y);
  const w = ctx.measureText(s).width;
  ctx.letterSpacing = '0px';
  return w;
}
function fade(a, fn) { if (a <= 0) return; ctx.save(); ctx.globalAlpha *= a; fn(); ctx.restore(); }
function glow(x, y, r, rgb, a) {
  const g = ctx.createRadialGradient(x, y, 0, x, y, r);
  g.addColorStop(0, `rgba(${rgb}, ${a})`);
  g.addColorStop(1, `rgba(${rgb}, 0)`);
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
}
const STONE = {
  lit: ['255, 251, 238', '232, 218, 192', '150, 132, 112'],
  next: ['255, 255, 250', '250, 240, 214', '196, 170, 130'],
  dull: ['104, 122, 130', '66, 84, 94', '34, 46, 56'],
  pale: ['236, 240, 246', '196, 204, 216', '112, 120, 136'],
};
// A smooth stone resting at (x, y): its lit side is up and to the left, where the sun is.
function pebble(x, y, rx, ry, rot, kind) {
  const c = STONE[kind];
  if (kind === 'lit') glow(x, y - 1, rx * 2.9, '255, 232, 180', 0.3);
  if (kind === 'pale') glow(x, y - 1, rx * 2.9, '226, 236, 255', 0.3);
  ctx.fillStyle = 'rgba(0, 0, 0, 0.3)';
  ctx.beginPath(); ctx.ellipse(x + 1, y + ry * 0.92, rx * 1.02, ry * 0.3, 0, 0, Math.PI * 2); ctx.fill();
  ctx.save(); ctx.translate(x, y); ctx.rotate(rot);
  const g = ctx.createRadialGradient(-rx * 0.34, -ry * 0.5, 0, -rx * 0.1, -ry * 0.1, rx * 1.45);
  g.addColorStop(0, `rgb(${c[0]})`); g.addColorStop(0.45, `rgb(${c[1]})`); g.addColorStop(1, `rgb(${c[2]})`);
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.ellipse(0, 0, rx, ry, 0, 0, Math.PI * 2); ctx.fill();
  if (kind !== 'dull') {
    ctx.fillStyle = 'rgba(255, 255, 255, 0.75)';
    ctx.beginPath(); ctx.ellipse(-rx * 0.3, -ry * 0.48, rx * 0.26, ry * 0.15, -0.2, 0, Math.PI * 2); ctx.fill();
  }
  ctx.restore();
}
const lean = (n) => 0.22 * Math.sin(n * 1.7 + 0.5);
function hollowDot(x, y, r, a = 1) {
  ctx.strokeStyle = ink(0.62 * a); ctx.lineWidth = 1.2;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke();
}
// Result marks: three dots, the earned ones filled.
function marks(x, y, n, r = 3.2, gap = 9) {
  for (let k = 0; k < 3; k++) {
    const bx = x + k * gap;
    if (k < n) { ctx.fillStyle = ink(0.92); ctx.beginPath(); ctx.arc(bx, y, r, 0, Math.PI * 2); ctx.fill(); }
    else hollowDot(bx, y, r - 0.6);
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
const two = (n) => String(n).padStart(2, '0');
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
// The whole shelf on one screen: the bank and the daily in the shallows, a tier to each stretch of slope, the break.
function overview(t, a) {
  fade(a, () => {
    text('UNSTIR', 32, 128, `250 ${World.pt('display')}px UPro`, INK, 'left', 9);
    // the stone on the bank: settings
    pebble(40, 180 - bankH(40) - 5, 8, 5.6, -0.1, 'lit');
    text('settings', 58, 166, F.ui(World.pt('detail')), ink(0.86));
    const tx = 180;
    // today, on the first ledge under the surface
    const sunny = RM ? 1 : 0.88 + 0.12 * Math.sin(t * 0.0016);
    glow(tipO(0) - 17, topO(0, tipO(0) - 17) - 6, 44, '255, 232, 180', 0.26 * sunny);
    pebble(tipO(0) - 17, topO(0, tipO(0) - 17) - 6.5, 10, 7, 0.08, 'next');
    text('today', tx, 250, F.word(World.pt('title')), INK);
    text('Daily · Mon 23 Nov', tx, 275, F.ui(World.pt('body')), ink(0.92));
    const w = text('4 days running', tx, 296, F.data(World.pt('detail')), ink(0.74));
    marks(tx + w + 14, 292, 2);
    // the archive, a ledge deeper, not yet lit
    pebble(tipO(2) - 16, topO(2, tipO(2) - 16) - 4.5, 7, 4.8, -0.12, 'dull');
    text('Archive', tx, O.y0 + 82, F.ui(World.pt('body')), ink(0.72));
    text('30 past dailies · comes with any pack', tx, O.y0 + 100, F.ui(World.pt('detail')), ink(0.64));
    const tiers = [
      { name: 'plughole', note: '27/27 at par', lit: 27, open: 27, a: 0.96 },
      { name: 'whirlpool', note: '0/27 at par', lit: 0, open: 1, a: 0.96 },
      { name: 'vortex', note: 'opens with every whirlpool level solved', lit: 0, open: 0, a: 0.74 },
      { name: 'maelstrom', note: 'opens with every vortex level solved', lit: 0, open: 0, a: 0.74 },
    ];
    tiers.forEach((tr, i) => {
      const y = O.y0 + 40 * (3 + 3 * i) + 22;
      text(tr.name, tx, y, F.word(World.pt('title')), ink(tr.a));
      text(tr.note, tx + 1, y + 21, F.ui(World.pt('detail')), ink(0.68));
      // its 27 levels, nine to a ledge, counted out from the wall
      for (let n = 0; n < 27; n++) {
        const k = 3 + 3 * i + Math.floor(n / 9), j = 8 - n % 9;
        const x = tipO(k) - 15 - 11.4 * j, y2 = topO(k, x) - 2.6;
        if (n < tr.lit) pebble(x, y2, 3.9, 2.9, lean(n + i), 'lit');
        else if (n < tr.open) { glow(x, y2, 16, '255, 236, 200', 0.4); pebble(x, y2 - 0.6, 4.6, 3.4, 0, 'next'); }
        else fade(0.8, () => pebble(x, y2 + 0.4, 3.3, 2.3, lean(n), 'dull'));
      }
    });
    // endless: past the break, open water
    text('endless', 250, 902, F.word(World.pt('title')), ink(0.92), 'center');
    text('best 9', 250, 924, F.data(World.pt('detail')), ink(0.7), 'center');
  });
}

// The slope itself: a pebble on each ledge with its number and name beside it, packs as hollows in the wall.
function dive(t, cam, a, next) {
  fade(a, () => {
    const sY = -cam;
    if (sY > -40) fade(under(sY - bankH(40) - 5), () => {
      pebble(40, sY - bankH(40) - 5, 8, 5.6, -0.1, 'lit');
      text('settings', 58, sY - 14, F.ui(World.pt('detail')), ink(0.86));
    });
    const lx = AX ? 96 : 214;
    const pY = levelY(-1.25) - cam, wY = levelY(27.75) - cam;
    if (pY > -40 && pY < 1000) fade(under(pY - 20), () => {
      text('plughole', lx, pY, F.word(World.pt('title')), ink(0.9));
      text(`${Math.min(27, next - 1)}/27 at par`, lx + 1, pY + World.pt('detail') * 1.6, F.data(World.pt('detail')), ink(0.68));
      if (!AX) text('packs · first 3 levels of each free', lx + 1, pY + World.pt('detail') * 3.2, F.ui(World.pt('detail')), ink(0.68));
    });
    if (wY > -40 && wY < 1000) fade(under(wY - 20), () => {
      text('whirlpool', lx, wY, F.word(World.pt('title')), ink(0.9));
      text(next > 27 ? '0/27 at par' : 'opens with every plughole level solved', lx + 1, wY + World.pt('detail') * 1.6,
        F.ui(World.pt('detail')), ink(0.68));
    });
    for (let n = 1; n <= 27; n++) {
      const y = levelY(n) - cam;
      if (y < 20 || y > 1010) continue;
      const x = pebX(n), nx = tipX(n) + (AX ? 14 : 18);
      const facts = `${RODS[n - 1]} rods · par ${PARS[n - 1]}`;
      const b = World.pt('body'), d = World.pt('detail');
      fade(under(y), () => {
        if (n === next) {
          const p = RM ? 1 : 0.86 + 0.14 * Math.sin(t * 0.0021);
          glow(x, y, AX ? 96 : 74, '255, 236, 190', 0.22 * p);
          pebble(x, y - (AX ? 3 : 2.5), AX ? 15 : 12.5, AX ? 11 : 9, 0.06, 'next');
          const ti = World.pt('title') * 1.15, by = y + ti * 0.27;
          const w = text(two(n), nx, by, F.data(b), ink(0.8));
          text(NAMES[n - 1], nx + w + (AX ? 14 : 10), by, F.name(ti), INK);
          text(facts, nx + 1, by + World.pt('label') * 1.5, F.data(World.pt('label')), ink(0.84));
          return;
        }
        const done = n < next;
        if (done) pebble(x, y - 0.5, AX ? 11 : 8.4, AX ? 8 : 6, lean(n), 'lit');
        else fade(0.9, () => pebble(x, y + 1.5, AX ? 9 : 6.8, AX ? 6 : 4.4, lean(n), 'dull'));
        const by = y + b * 0.12;
        const w = text(two(n), nx, by, F.data(World.pt('label')), ink(done ? 0.62 : 0.5));
        const nw = text(NAMES[n - 1], nx + w + (AX ? 14 : 9), by, F.ui(b, 350), ink(done ? 0.92 : 0.66));
        if (done) marks(nx + w + (AX ? 14 : 9) + nw + (AX ? 18 : 13), by - b * 0.3, DOTS[n - 1], AX ? 5 : 3.2, AX ? 14 : 9);
        text(facts, nx + 1, by + d * 1.5, F.data(d), ink(done ? 0.62 : 0.5));
      });
    }
    if (!AX) PACKS.forEach((pk) => {
      const y = levelY(pk.m) - cam;
      if (y < -60 || y > 1040) return;
      const x = hollowX(pk);
      fade(under(y), () => hollow(pk, x, y, 58));
    });
  });
}
const hollowX = (pk) => 56 + 5 * Math.sin(pk.m);
// An opening in the slope: dark inside, the pack's own cover lit within, its light spilling on the rock.
function hollow(pk, x, y, d) {
  glow(x, y, d * 1.25, pk.glow, 0.26);
  ctx.fillStyle = 'rgba(3, 6, 10, 0.92)';
  ctx.beginPath(); ctx.ellipse(x, y, d / 2 + 5, d / 2 + 5, 0, 0, Math.PI * 2); ctx.fill();
  World.disc(ctx, 'cover-' + pk.id, x, y, d);
  // the rock's own thickness around the mouth: shade at the top, light caught on the lower lip
  const g = ctx.createRadialGradient(x, y, d / 2, x, y, d / 2 + 6);
  g.addColorStop(0, 'rgba(3, 6, 10, 0)'); g.addColorStop(1, 'rgba(3, 6, 10, 0.85)');
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.arc(x, y, d / 2 + 6, 0, Math.PI * 2); ctx.arc(x, y, d / 2, 0, Math.PI * 2, true); ctx.fill();
  const l = ctx.createLinearGradient(0, y + d * 0.2, 0, y + d / 2 + 6);
  l.addColorStop(0, `rgba(${pk.glow}, 0)`); l.addColorStop(1, `rgba(${pk.glow}, 0.55)`);
  ctx.strokeStyle = l; ctx.lineWidth = 1.6;
  ctx.beginPath(); ctx.arc(x, y, d / 2 + 5.4, 0.12 * Math.PI, 0.88 * Math.PI); ctx.stroke();
  text(pk.name, x, y + d / 2 + 23, F.ui(World.pt('detail')), ink(0.86), 'center');
  if (pk.fresh) text('new', x, y + d / 2 + 39, F.data(World.pt('detail')), ink(0.72), 'center');
}

function playChrome(a, o) {
  fade(a, () => {
    const T = o.tank;
    text('↑ levels', 28, AX ? 104 : 96, F.ui(World.pt('body')), ink(0.86));
    if (o.count) text(o.count, AX ? 28 : 412, AX ? 150 : 96, F.data(World.pt('label')), ink(0.76), AX ? 'left' : 'right');
    const titleY = T.y - T.d / 2 - (AX ? 24 : 54);
    if (o.over) text(o.over, 220, titleY - (AX ? 56 : 38), F.data(World.pt('detail')), ink(0.74), 'center');
    // number then name, as the menu writes them; Prism's number stays white
    ctx.font = F.data(World.pt('body')); const nw = ctx.measureText(o.num).width;
    ctx.font = F.name(World.pt('display')); const tw = ctx.measureText(o.title).width;
    const gap = AX ? 16 : 11, x0 = 220 - (nw + gap + tw) / 2;
    if (o.prism) glow(x0 + nw / 2, titleY - World.pt('body') * 0.34, 24, '255, 255, 255', 0.16);
    text(o.num, x0, titleY, F.data(World.pt('body')), o.prism ? '#ffffff' : ink(0.76));
    text(o.title, x0 + nw + gap, titleY, F.name(World.pt('display')), INK);
  });
}
function tank(name, T, a, s = 1) {
  fade(a, () => {
    glow(T.x, T.y, T.d * s * 0.62, '255, 240, 210', 0.1);
    World.disc(ctx, name, T.x, T.y, T.d * s);
  });
}
// The hint under the glass, and undo and reset as two stones on the terrace.
function noteAndControls(a, o) {
  fade(a, () => {
    const T = o.tank;
    let y = T.y + T.d / 2 + (AX ? 56 : 42);
    const lines = AX ? wrap(o.note.join(' '), F.word(World.pt('body')), 392) : o.note;
    for (const line of lines) { text(line, 220, y, F.word(World.pt('body')), ink(0.84), 'center'); y += AX ? 47 : 25; }
    const r = AX ? 13 : 10, b = World.pt('body');
    const uy = seatY(52) - r * 0.7, ry = seatY(388) - r * 0.7;
    fade(o.undone ? 1 : 0.75, () => pebble(52, uy, r, r * 0.72, -0.08, o.undone ? 'lit' : 'dull'));
    text(o.undo, 52 + r + 12, uy + b * 0.2, F.ui(b), ink(o.undone ? 0.9 : 0.66));
    pebble(388, ry, r, r * 0.72, 0.1, o.prism ? 'pale' : 'lit');
    text('reset', 388 - r - 12, ry + b * 0.2, F.ui(b), ink(0.9), 'right');
  });
}
const TANK_PLAY = AX ? { x: 220, y: 392, d: 236 } : { x: 220, y: 474, d: 403 };
const TANK_RESULT = { x: 220, y: 440, d: 372 };

function resultScene(t, a, t0) {
  fade(a, () => {
    const T = TANK_RESULT;
    // light settling: bright motes sink past the glass and come to rest
    if (!RM) for (let k = 0; k < 9; k++) {
      const st = t0 + 200 + k * 210;
      const life = ramp(t, st, st + 3400);
      if (life <= 0 || life >= 1) continue;
      const side = k % 2 ? 1 : -1;
      const x = 220 + side * (T.d * 0.5 + 6 + (k * 37 % 30)) + 5 * Math.sin(k * 2.1);
      const y = 150 + ease(life) * (700 + (k * 53 % 60));
      glow(x, y, 7, '255, 238, 196', 0.42 * Math.sin(Math.PI * Math.min(1, life * 1.15)));
    }
    text('↑ levels', 28, 96, F.ui(World.pt('body')), ink(0.86));
    const tw = (() => { ctx.font = F.data(World.pt('label')); const a1 = ctx.measureText('27').width; ctx.font = F.ui(World.pt('body')); return [a1, ctx.measureText('Drain').width]; })();
    const x0 = 220 - (tw[0] + 9 + tw[1]) / 2;
    text('27', x0, 140, F.data(World.pt('label')), ink(0.66));
    text('Drain', x0 + tw[0] + 9, 140, F.ui(World.pt('body')), ink(0.92));
    const rise = RM ? 1 : settle(ramp(t, t0 + 300, t0 + 1500));
    fade(RM ? ramp(t, t0, t0 + 200) : ease(ramp(t, t0 + 300, t0 + 900)), () =>
      text('unstirred.', 220, 208 - (1 - rise) * 26, F.word(World.pt('display')), INK, 'center'));
    fade(RM ? 1 : ease(ramp(t, t0 + 900, t0 + 1500)), () => {
      const my = T.y + T.d / 2 + 34 - (RM ? 0 : (1 - settle(ramp(t, t0 + 900, t0 + 1700))) * 14);
      [196, 220, 244].forEach((x, k) => {
        if (k < 2) { glow(x, my, 18, '255, 238, 200', 0.28); ctx.fillStyle = ink(0.96); ctx.beginPath(); ctx.arc(x, my, 6, 0, 7); ctx.fill(); }
        else hollowDot(x, my, 5.4);
      });
      text('at par', 220, my + 36, F.ui(World.pt('body'), 500), 'rgba(255, 222, 160, 0.98)', 'center');
      text('moves 9 · par 9', 220, my + 60, F.data(World.pt('label')), ink(0.86), 'center');
      text('new best · was +6', 220, my + 83, F.data(World.pt('label')), ink(0.8), 'center');
      text('clean needs no undo or reset', 220, my + 105, F.ui(World.pt('detail')), ink(0.68), 'center');
    });
    fade(RM ? 1 : ease(ramp(t, t0 + 1400, t0 + 2100)), () => {
      const b = World.pt('body');
      const ay = seatY(50) - 7;
      pebble(50, ay, 10, 7.2, -0.08, 'lit');
      text('again', 72, ay + b * 0.2, F.ui(b), ink(0.9));
      const ny = seatY(404) - 9;
      glow(404, ny, 40, '255, 170, 220', 0.3);
      pebble(404, ny, 12.5, 9, 0.1, 'next');
      text('up a notch', 380, ny - 22, F.word(World.pt('label')), ink(0.76), 'right');
      text('whirlpool ›', 380, ny + 8, F.name(World.pt('title')), INK, 'right');
    });
  });
}

function packScene(t, a, t0) {
  fade(a, () => {
    const arr = (k) => RM ? 1 : ease(ramp(t, t0 + 500 + k * 130, t0 + 1200 + k * 130));
    const lift = (k) => RM ? 0 : (1 - settle(ramp(t, t0 + 500 + k * 130, t0 + 1500 + k * 130))) * 12;
    const line = (k, s, y, font, colour) => fade(arr(k), () => text(s, 220, y + lift(k), font, colour, 'center'));
    text('↑ menu', 28, 96, F.ui(World.pt('body')), ink(0.86));
    fade(arr(0), () => glow(220, 500, 90, '255, 255, 255', 0.06));
    line(0, 'pack · paid add-on', 470, F.data(World.pt('detail')), ink(0.64));
    line(0, 'Prism', 516, `200 ${World.pt('display') * 1.3}px UPro`, '#ffffff');
    line(1, 'each rod stirs only some colours', 548, F.word(World.pt('body')), ink(0.9));
    line(2, 'after plughole · reading by colour', 586, F.ui(World.pt('label')), ink(0.86));
    line(2, 'levels 1–3 free, no purchase', 608, F.ui(World.pt('label')), ink(0.86));
    line(2, '30 specimens in five trays', 630, F.ui(World.pt('label')), ink(0.86));
    line(3, 'letters for colour-blind play, in settings', 656, F.ui(World.pt('detail')), ink(0.68));
    fade(arr(4), () => {
      glow(94, 712, 40, '236, 242, 255', 0.2);
      pebble(94, 712, 11.5, 8.2, -0.06, 'pale');
      text('buy $2.99', 132, 722, F.ui(World.pt('body'), 600), '#ffffff');
      text('try 3 free ›', 388, 722, F.ui(World.pt('body')), ink(0.9), 'right');
      text('or all three in Triptych I · $5.99 · save $2.98 ›', 236, 776, F.ui(World.pt('detail')), ink(0.7), 'center');
    });
    // its 30 specimens, six to a tray, resting on the floor; the three free ones are lit
    fade(arr(5), () => {
      for (let tray = 0; tray < 5; tray++) for (let k = 0; k < 6; k++) {
        const i = tray * 6 + k;
        const x = 66 + tray * 66 + k * 9.4;
        const y = 842 + 8 * Math.sin(x * 0.012 + 0.5);
        if (i < 3) pebble(x, y - 3.2, 4.2, 3.2, lean(i), 'pale');
        else fade(0.9, () => pebble(x, y - 2, 3.4, 2.5, lean(i), 'dull'));
      }
      text('0/30 at par', 220, 880, F.data(World.pt('detail')), ink(0.66), 'center');
      text('restore purchases', 220, 918, F.ui(World.pt('detail')), ink(0.74), 'center');
    });
  });
}

// Settings: at the water line. Each switch is a stone on one of the first ledges under the surface, lit when on.
function settingsScene(t, a, t0, cam) {
  fade(a, () => {
    const arr = (k) => RM ? 1 : ease(ramp(t, t0 + k * 120, t0 + 700 + k * 120));
    fade(arr(0), () => text('settings', 32, 132, F.word(World.pt('display')), INK));
    const rows = [
      ['music', true, 'the beds under the menu and the levels'],
      ['sounds', true, 'every effect and button'],
      ['haptics', true, 'the tank’s knocks and taps'],
      ['colour letters', false, 'R, G and B on Prism’s knobs'],
    ];
    const b = World.pt('body'), d = World.pt('detail');
    rows.forEach(([name, on, sub], i) => {
      const k = i - 3, x = pebX(k), nx = tipX(k) + 18;
      const sink = RM ? 0 : (1 - settle(ramp(t, t0 + 200 + i * 140, t0 + 1300 + i * 140))) * -26;
      fade(arr(i + 1), () => {
        const y = levelY(k) - cam;
        if (on) pebble(x, y - 1 + sink, 9.5, 6.8, lean(i + 3), 'lit');
        else fade(0.9, () => pebble(x, y + 2, 8, 5, lean(i), 'dull'));
        const w = text(name, nx, y + 2, F.ui(b), ink(on ? 0.96 : 0.82));
        text(on ? 'on' : 'off', nx + w + 12, y + 2, F.data(d), ink(on ? 0.8 : 0.6));
        text(sub, nx, y + 2 + d * 1.5, F.ui(d), ink(0.64));
      });
    });
    fade(arr(5), () => {
      const x1 = tipX(1) + 14, x2 = tipX(1) + 24, x3 = tipX(2) + 20;
      text('restore purchases', x1, 668, F.ui(b), ink(0.92));
      text('packs bought on this Apple ID', x1, 688, F.ui(d), ink(0.64));
      text('report a problem ↗', x2, 732, F.ui(b), ink(0.92));
      text('with the log: touches, moves,', x2, 752, F.ui(d), ink(0.64));
      text('purchases and errors', x2, 769, F.ui(d), ink(0.64));
      text('privacy policy ↗', x3, 811, F.ui(b), ink(0.92));
      text('what the game keeps, and why', x3, 831, F.ui(d), ink(0.64));
      text('Unstir 1.0 (1)', x3, 874, F.data(d), ink(0.62));
      text('↓ back into the water', 220, 922, F.ui(d), ink(0.72), 'center');
    });
  });
}

// ---------------------------------------------------------------- the film's fingertip
const prism = PACKS[3];
const TOUCHES = [
  // [appear, press, lift, x0, y0, x1, y1]
  [2100, 2700, 3000, 236, 410, 236, 410],     // tap plughole's stretch of slope
  [6700, 7000, 8500, 300, 360, 300, 860],     // draw the water down: rise
  [8400, 8800, 9100, pebX(1), levelY(1) - CAM.menu1, pebX(1), levelY(1) - CAM.menu1],  // Drop's pebble
  [18000, 18350, 18600, 58, 92, 58, 92],      // ↑ levels
  [19900, 20300, 20600, hollowX(prism), levelY(prism.m) - CAM.menu15, hollowX(prism), levelY(prism.m) - CAM.menu15],
  [24200, 24500, 24800, 58, 92, 58, 92],      // ↑ menu
  [26300, 26600, 26900, 40, -CAM.surface - bankH(40) - 5, 40, -CAM.surface - bankH(40) - 5],  // the stone on the bank
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
const PLAY = { tank: TANK_PLAY, title: 'Drop', num: '01', count: 'moves 0 / par 1',
  note: ['Turn a rod to look. Let go where', 'you started and nothing happens.'], undo: 'undo · 10' };
const PRISM = { tank: TANK_PLAY, title: 'Frond', num: '01', over: 'Prism', count: 'moves 0 / par 3', prism: true,
  note: ['Each rod stirs only its knob’s colours.'], undo: 'undo · 10' };

function draw(c, t) {
  ctx = c;
  if (t >= 36000) { // Prism 01 in play, off the film: clear water and white light, its number white
    tank('prism01', TANK_PLAY, 1);
    playChrome(1, PRISM);
    noteAndControls(1, PRISM);
    return statusBar();
  }
  const cam = camera(t);
  overview(t, RM ? ov(t) : 1 - ease(ramp(t, 2950, 3250)));
  // the pebbles stay in view while the camera sinks between screens, so a dive passes the levels it crosses
  const menuA = t < 3000 ? 0 : span(t, 3200, 3800, 8800, 9500) + span(t, 12900, 13400, 14200, 14700)
    + span(t, 18900, 19700, 20600, 21300) + span(t, 24900, 25500, 26700, 27200);
  ctx.save();
  ctx.translate(-280 * levelMix(t), 0);
  dive(t, cam, Math.min(1, menuA), NEXT(t));
  ctx.restore();
  // play: Drop's pebble opens into its tank
  const openK = RM ? (t >= 9550 ? 1 : 0) : settle(ramp(t, 8900, 10200));
  const playA = t >= 8900 && t < 13600 ? (RM ? span(t, 9200, 9900, 12700, 13300) : ease(ramp(t, 8900, 9300)) * (1 - ease(ramp(t, 12700, 13300)))) : 0;
  if (playA > 0) {
    const src = { x: pebX(1), y: levelY(1) - CAM.menu1 };
    tank('play01', { x: mix(src.x, TANK_PLAY.x, openK), y: mix(src.y, TANK_PLAY.y, openK), d: TANK_PLAY.d }, playA, mix(0.04, 1, openK));
    const chromeA = playA * (RM ? 1 : ease(ramp(t, 9700, 10500)));
    playChrome(chromeA, PLAY);
    noteAndControls(chromeA, PLAY);
  }
  const resA = span(t, 14500, 15000, 18600, 19100);
  if (resA > 0) {
    tank('drain-solved', TANK_RESULT, resA * (RM ? 1 : ease(ramp(t, 14500, 15100))));
    resultScene(t, resA, 14600);
  }
  // Prism: its cover rises out of the hollow to the middle
  const pA = packMix(t);
  if (pA > 0) {
    const k = RM ? 1 : settle(ramp(t, 20600, 21900));
    const src = { x: hollowX(prism), y: levelY(prism.m) - CAM.menu15 };
    fade(pA, () => World.disc(ctx, 'prism-clip', mix(src.x, 220, k), mix(src.y, 290, k), mix(58, 290, k)));
    packScene(t, pA, 21000);
  }
  settingsScene(t, span(t, 26800, 27300, 99999, 99999), 26800, cam);
  touches(t);
  statusBar();
}

window.DRAWS_AX = true;
// A page that builds on this one (eggs/) sets SHELF_HOLD and starts the world itself.
if (!window.SHELF_HOLD) World.load(['play01', 'drain-solved', 'prism01', 'prism-clip', 'cover-first-stir', 'cover-lens', 'cover-escapement',
  'cover-prism', 'cover-triptych', 'status']).then(() => World.start({
  fonts: ['300 28px UPro', 'italic 300 28px NY', '400 13px UMono', '600 17px UPro', '200 40px UPro', '250 34px UPro',
    '350 17px UPro', '500 17px UPro'],
  shader,
  uniforms: (t) => ({
    camY: camera(t), ov: ov(t), pk: packMix(t), pr: prismMix(t), tm: clock(t), lv: levelMix(t),
    glint: t >= 36000 ? 0 : span(t, 14600, 15800, 18600, 19100), near: AX ? 0 : 1, pkC: [220, 290],
  }),
  draw,
  duration: DUR,
  shots: SHOTS,
}));
