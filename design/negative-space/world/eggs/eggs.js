// Copyright © 2026 Jack Lusher. All rights reserved.
// Easter eggs for the Shelf, each a short film on the Shelf's own overview (?egg=above, below, skim, cairn, tilt,
// still), and one still that is not an egg: the overview with the four pack hollows in plughole's rock (?egg=packs;
// ?egg=none is the overview as approved). The page loads ../shelf/shelf.js held (SHELF_HOLD) and draws with its
// shader and 2D helpers; the shader gains a few terms by patching its source, each zero when its uniform is.
// The mono line at the foot of a film and the phone glyph are the film's notes, as the fingertip is; none is UI.

(() => {
const EGG = new URLSearchParams(location.search).get('egg') || 'none';
const TAU = Math.PI * 2;
const g2 = (x) => Math.exp(-x * x);

// ---------------------------------------------------------------- the ground's added terms
function patch(src, from, to) {
  if (!src.includes(from)) throw new Error('the Shelf shader no longer has: ' + from);
  return src.replace(from, to);
}
let sh = shader;
sh = patch(sh, 'float tierD(float k) {', `
uniform float eShift, eTilt, eCalm, eNight, eDeep;
uniform vec2 eMoon;
uniform vec4 eRipX, eRipA, eRipX2, eRipA2;
// points of light on a jittered grid; the deep's are the sky's, mirrored about the screen
float eStars(vec2 q, float soft, float pulse) {
  float s = 0.;
  for (int j = 0; j < 2; j++) {
    float fj = float(j), c = 27. + 19. * fj;
    vec2 g = q / c + fj * 13.7;
    vec2 id = floor(g), f = fract(g) - .5;
    vec2 jo = vec2(h1(id + 1.3), h1(id + 5.9)) - .5;
    float r = length((f - jo * .8) * c);
    float mag = .22 + .78 * pow(h1(id + 2.2), 3.);
    float tw = 1. - pulse * (.5 + .5 * sin(tm * .0016 * (.5 + h1(id)) + 6.28 * h1(id + 4.)));
    s += (smoothstep(1., 0., r / (.62 + .8 * mag)) + soft * exp(-r / (1.6 + 2.4 * mag)) * .5) * mag * tw * step(.3, h1(id + 9.1));
  }
  return s;
}
void eSky(inout vec3 col, vec2 p, float sY0) {
  float h = sY0 - p.y;
  float up = smoothstep(50., 210., h) * eNight;
  col += vec3(.86, .9, 1.) * eStars(p, 0., .3) * up;
  col += vec3(.05, .054, .085) * smoothstep(.3, .9, nz(vec2(p.x * .005 + p.y * .004, (p.y - p.x * .7) * .011))) * up;
  vec2 mv = (p - vec2(322., sY0 - 282.)) / 15.;
  float r = length(mv);
  float lim = sqrt(max(1. - mv.y * mv.y, 0.));
  float lit = smoothstep(-.07, .07, mv.x * eMoon.y - eMoon.x * lim);
  vec3 face = vec3(1., .965, .87) * (.8 + .2 * nz(mv * 2.1 + 3.)) * (1. - .16 * r * r);
  col = mix(col, mix(vec3(.05, .052, .075), face, lit), smoothstep(1., .92, r) * eNight);
  col += vec3(.62, .64, .78) * exp(-max(r - 1., 0.) * .5) * .10 * eNight;
}
vec3 eWater(vec2 p, float d) { // the moon on the water: a bright stretch of the surface, broken glints under it
  float a = exp(-abs(d) / 1.6) * g2((p.x - 322.) / 44.) * .45;
  a += g2((p.x - 322.) / (13. + d * .22)) * exp(-d / 60.) * (.8 + .2 * sin(p.x * .4 + tm * .003)) * .1;
  return vec3(1., .96, .86) * a * eNight;
}
float eRip1(float x, float x0, float a, float amp) { // a skip's ring, seen from the side: two bumps running apart
  if (a <= 0.) return 0.;
  float f = abs(x - x0) - 30. * a;
  return amp * exp(-a * 1.1) * cos(f * .3) * exp(-f * f / (40. + 320. * a));
}
float eRip(float x) {
  float s = 0.;
  for (int i = 0; i < 4; i++) {
    s += eRip1(x, eRipX[i], eRipA[i], 4.8 * pow(.88, float(i)));
    s += eRip1(x, eRipX2[i], eRipA2[i], 4.8 * pow(.88, float(i + 4)));
  }
  return s;
}
float tierD(float k) {`);
sh = patch(sh, 'float m = o > .5 ? ovM(p.y) :', 'float m = o > .5 ? ovM(p.y - (p.x - 220.) * eTilt) :');
sh = patch(sh, 'float sY = sY0 + 3.2 * sin(p.x * .024 + tm * .0011) + 1.8 * sin(p.x * .063 - tm * .0016 + 1.3);',
  `float sY = sY0 + (1. - eCalm) * (3.2 * sin(p.x * .024 + tm * .0011) + 1.8 * sin(p.x * .063 - tm * .0016 + 1.3))
    + (p.x - 220.) * eTilt;`);
// a ring moves the water line, not the light above and below it
sh = patch(sh, 'float d = p.y - sY;', 'float d = p.y - sY; d -= eRip(p.x) * exp(-abs(d) / 9.);');
sh = patch(sh, 'col += vec3(.5, .3, .12) * exp(-length((p - vec2(60., sY0)) * vec2(.006, .02))) * .22;',
  `col += vec3(.5, .3, .12) * exp(-length((p - vec2(60., sY0)) * vec2(.006, .02))) * .22;
    eSky(col, p, sY0);`);
sh = patch(sh, 'float sx = p.x + d * .32 + tm * .004;', 'float sx = p.x + d * (.32 - eTilt * 4.) + tm * .004;');
// still water: light reaches further down, and the far ridges come out of the haze
sh = patch(sh, 's = smoothstep(.12, .55, s) * exp(-max(m + 3.8, 0.) / 8.);',
  's = smoothstep(.12, .55, s) * exp(-max(m + 3.8, 0.) / (8. + 44. * eCalm)) * (1. + 1.2 * eCalm);');
sh = patch(sh, 'col += vec3(1., .9, .72) * exp(-abs(d) / 1.3) * .5;',
  `col += vec3(1., .9, .72) * exp(-abs(d) / 1.3) * (.5 + .3 * eCalm);
    col += eWater(p, d);`);
sh = patch(sh, 'rc += wc * .35 * exp(-max(p.x - e, 0.) / 9.) * (.5 + .5 * sin(yy * .061 + fj + 1.6));',
  `rc += wc * .35 * exp(-max(p.x - e, 0.) / 9.) * (.5 + .5 * sin(yy * .061 + fj + 1.6));
    rc += wc * eCalm * (.5 - .2 * fj) * exp(-max(p.x - e, 0.) / (26. + 30. * fj));`);
sh = patch(sh, 'float sun = exp(-max(m + 3.8, 0.) / 26.) * .75 + .25;',
  'float sun = exp(-max(m + 3.8, 0.) / (26. + 90. * eCalm)) * .75 + .25;');
sh = patch(sh, `  return col;
}
// Inside a hollow`, `  // under the last water: cold lights, where the sky's stars would be
  float dz = p.y - 956.;
  col += (vec3(.34, .95, .86) * eStars(vec2(p.x, -dz), 1., .75) + vec3(.0, .016, .026) * smoothstep(0., 300., dz))
    * smoothstep(-30., 110., dz) * eDeep;
  return col;
}
// Inside a hollow`);
sh = patch(sh, 'vec2 p = uv * res;\n  vec3 col = ov < 1.', 'vec2 p = uv * res; p.y -= eShift;\n  vec3 col = ov < 1.');

// ---------------------------------------------------------------- the film's notes
function note(s) { text(s, 220, 941, F.data(11), ink(0.56), 'center', 0.4); }
function touch(x, y, a, press) { finger(x, y, a, press); }
const surf = (x, tm) => 180 + 3.2 * Math.sin(x * 0.024 + tm * 0.0011) + 1.8 * Math.sin(x * 0.063 - tm * 0.0016 + 1.3);
// The moon as it stands on the mock-up's date, the evening of Mon 23 Nov 2026 (mean phase from the new moon of
// 6 Jan 2000): k is the terminator's place across the disc, 1 new and -1 full, and the lit limb is on the right
// while it waxes, as the northern half of the world sees it.
const SYNODIC = 29.530588853;
const moonAge = ((Date.UTC(2026, 10, 23, 21) - Date.UTC(2000, 0, 6, 18, 14)) / 864e5) % SYNODIC;
const MOON = [Math.cos(TAU * moonAge / SYNODIC), moonAge < SYNODIC / 2 ? 1 : -1];

// ---------------------------------------------------------------- the eggs
// Each: dur, shot (the still's time), state(t) -> what the ground and the 2D layer take, over(t, st) drawn with
// the overview (it moves with an overscroll), top(t, st) drawn on the screen.
const EGGS = {};

EGGS.none = { dur: 3000, shot: 1800, name: 'overview-before', state: (t) => ({ tm: t }) };

// Not an egg: the four packs seen from the first screen. Each hollow is cut in the root of the plughole ledge its
// place on the slope falls on (Lens by level 6, Escapement by 11, Prism by 16, Triptych I by 21; nine levels to a
// ledge), lit by its own cover, and the tier's lines name them.
const SPOTS = { lens: [3, 23, 22], escapement: [4, 22, 22], prism: [4, 58, 20], triptych: [5, 24, 22] };
EGGS.packs = {
  dur: 3000, shot: 1800, name: 'overview-packs', state: (t) => ({ tm: t }),
  over() {
    const sold = PACKS.filter(pk => SPOTS[pk.id]);
    for (const pk of sold) {
      const [k, x, d] = SPOTS[pk.id];
      const y = topO(k, x) + (k === 4 && x > 40 ? 15.5 : 18);
      ctx.save();
      ctx.translate(x, y); ctx.scale(d / 58, d / 58);
      hollow({ ...pk, name: '', fresh: false }, 0, 0, 58);
      ctx.restore();
    }
    const d = World.pt('detail');
    text('packs · first 3 levels of each free', 181, 446, F.ui(d), ink(0.68));
    sold.forEach((pk, i) => { // two to a line, each by a bead of its hollow's light
      const x = 181 + 96 * (i % 2), y = 466 + 19 * Math.floor(i / 2);
      glow(x + 4, y - 4.5, 9, pk.glow, 0.5);
      ctx.fillStyle = `rgb(${pk.glow})`;
      ctx.beginPath(); ctx.arc(x + 4, y - 4.5, 2.6, 0, TAU); ctx.fill();
      text(pk.name, x + 13, y, F.ui(d), ink(0.88));
    });
  },
};

// Pull down past the surface: the view lifts out of the water into the night that was always above it.
EGGS.above = {
  dur: 9000, shot: 4800, caption: 'pull down past the surface',
  state(t) {
    const shift = 255 * ease(ramp(t, 800, 2400)) * (1 - settle(ramp(t, 6200, 7700)));
    return { tm: t, shift, night: ease(ramp(shift, 24, 215)) };
  },
  top(t) {
    const a = ease(ramp(t, 500, 800)) * (1 - ease(ramp(t, 6200, 6500)));
    touch(250, mix(300, 640, ease(ramp(t, 800, 2400))), a, 0.4 * ramp(t, 500, 800));
  },
};

// Pull up past endless: under the last water, cold lights come out one by one, the sky's own stars upside down.
EGGS.below = {
  dur: 9500, shot: 5600, caption: 'pull up past endless, and hold',
  state(t) {
    const shift = -300 * ease(ramp(t, 800, 2300)) * (1 - settle(ramp(t, 6900, 8400)));
    return { tm: t, shift, deep: ease(ramp(t, 1700, 5200)) * ramp(-shift, 40, 260) };
  },
  top(t) {
    const a = ease(ramp(t, 500, 800)) * (1 - ease(ramp(t, 6900, 7200)));
    touch(300, mix(730, 396, ease(ramp(t, 800, 2300))), a, 0.4 * ramp(t, 500, 800));
  },
};

// Flick along the water line: a flat stone off the bank skips, each touch a ring, and goes under.
const SKIP = { t0: 1000, at: [360, 800, 1180, 1500, 1770, 1990, 2170], x: [170, 228, 277, 318, 352, 379, 399],
  h: [0, 15, 11, 8, 5.6, 3.6, 2.2] };
EGGS.skim = {
  dur: 7600, shot: 2020, caption: 'flick along the water line',
  state(t) {
    const age = SKIP.at.map(a => (t - SKIP.t0 - a) / 1000);
    return { tm: t, ripX: SKIP.x.slice(0, 4), ripA: age.slice(0, 4), ripX2: [...SKIP.x.slice(4), 0], ripA2: [...age.slice(4), 0] };
  },
  over(t) {
    const u = t - SKIP.t0, n = SKIP.at.length;
    if (u < 0) return;
    const wet = (i) => surf(SKIP.x[i], t) - 1.2;
    let x, y, rot = -0.16, a = 1;
    if (u < SKIP.at[0]) { // off the fingertip, low and flat
      const k = u / SKIP.at[0];
      x = mix(124, SKIP.x[0], k); y = mix(166, wet(0), k * k);
    } else if (u < SKIP.at[n - 1]) {
      let i = 1; while (u >= SKIP.at[i]) i++;
      const k = (u - SKIP.at[i - 1]) / (SKIP.at[i] - SKIP.at[i - 1]);
      x = mix(SKIP.x[i - 1], SKIP.x[i], k);
      y = mix(wet(i - 1), wet(i), k) - SKIP.h[i] * 4 * k * (1 - k);
      rot = -0.16 + 0.1 * k;
    } else { // spent: it goes under and sinks, rocking as a flat stone does
      const s = (u - SKIP.at[n - 1]) / 1000, k = ramp(s, 0, 3.6);
      x = SKIP.x[n - 1] + 5 + 5 * Math.sin(s * 3.1) * (0.3 + k);
      y = wet(n - 1) + 2 + 132 * (1 - Math.pow(1 - k, 1.6));
      rot = 0.3 * Math.sin(s * 3.1 + 1.2);
      a = 1 - ease(ramp(s, 1.2, 3.4));
    }
    // a bead or two of water thrown up by each touch
    SKIP.at.forEach((at, i) => {
      const s = (u - at) / 380;
      if (s <= 0 || s >= 1) return;
      for (let j = 0; j < 3; j++) {
        const vx = (j - 0.6) * 9 + 5, up = (11 - i) * (0.7 + 0.25 * j);
        ctx.fillStyle = `rgba(255, 244, 220, ${0.8 * (1 - s)})`;
        ctx.beginPath(); ctx.arc(SKIP.x[i] + vx * s, wet(i) - up * 4 * s * (1 - s) - 1, 1.1 - 0.5 * s, 0, TAU); ctx.fill();
      }
    });
    fade(a, () => pebble(x, y, 6.4, 2.5, rot, 'next'));
    // how many times it touched, where it went under
    fade(span(t, SKIP.t0 + 2500, SKIP.t0 + 3000, SKIP.t0 + 5000, SKIP.t0 + 5800), () =>
      text(String(n), SKIP.x[n - 1] + 5, 164, F.data(World.pt('detail')), ink(0.8), 'center'));
  },
  top(t) {
    const a = ease(ramp(t, 400, 650)) * (1 - ease(ramp(t, 1000, 1250)));
    const k = Math.pow(ramp(t, 760, 1000), 2);
    touch(mix(62, 150, k), mix(171, 169, k), a, 0.4 * ramp(t, 400, 700));
  },
};

// A day's daily solved adds a flat stone to a cairn on the ledge under today's; a tap makes it rock.
const CAIRN = { x: tipO(1) - 30, rx: [10.5, 8.8, 7.3, 6, 5, 4.2, 3.5], off: [0, 1.3, -0.9, 0.8, -0.5, 0.6, -0.3],
  lean: [0.02, -0.05, 0.04, -0.06, 0.05, -0.03, 0.04] };
EGGS.cairn = {
  dur: 8200, shot: 4300, caption: 'today’s daily solved: a stone for each day running',
  state: (t) => ({ tm: t }),
  over(t) {
    const base = topO(1, CAIRN.x);
    const land = 3300, tap = 5400;
    const knock = (t0, amp, i) => { // a damped rock about where the stone rests, more the higher it sits
      const s = (t - t0) / 1000;
      return s <= 0 ? 0 : amp * (0.35 + 0.3 * i) * Math.exp(-s * 2.6) * Math.sin(s * 13 + i * 0.7);
    };
    let y = base;
    for (let i = 0; i < 4; i++) {
      const rx = CAIRN.rx[i], ry = rx * 0.37;
      const cy = y - ry * 0.9;
      y -= ry * 1.72;
      const sway = knock(land, 0.05, i) + knock(tap, 0.09, i);
      if (i < 3) { fade(0.94, () => pebble(CAIRN.x + CAIRN.off[i] + sway * 9, cy, rx, ry, CAIRN.lean[i] + sway, 'next')); continue; }
      // the fourth comes down through the water from the surface and finds its seat
      const k = ramp(t, 900, land), s = 1 - Math.pow(1 - k, 1.7);
      const fx = CAIRN.x + CAIRN.off[i] + 26 * (1 - s) + 7 * Math.sin(k * 10) * (1 - s);
      const fy = mix(186, cy, s);
      const rot = CAIRN.lean[i] + 0.32 * Math.sin(k * 10 + 1.1) * (1 - s);
      fade(ease(ramp(t, 900, 1300)) * 0.94, () => pebble(fx + sway * 9, fy, rx, ry, rot + sway, 'next'));
      // fine sand lifts where it lands
      const p = ramp(t, land - 60, land + 1300);
      if (p > 0 && p < 1) for (let j = 0; j < 5; j++) {
        const side = j % 2 ? 1 : -1;
        glow(CAIRN.x + side * (6 + 9 * ease(p) + j * 2.4), cy + 2 - (5 + j * 2.2) * ease(p), 2.4, '255, 232, 190', 0.34 * Math.sin(Math.PI * p));
      }
    }
  },
  top(t) {
    const y = topO(1, CAIRN.x) - 12;
    const a = ease(ramp(t, 4900, 5200)) * (1 - ease(ramp(t, 5650, 6000)));
    touch(CAIRN.x, y, a, Math.max(0, Math.sin(Math.PI * ramp(t, 5280, 5660))));
  },
};

// Tilt the phone: the rock is the phone's, the water is not. The surface and every depth's colour stay level.
const DEG = Math.PI / 180;
EGGS.tilt = {
  dur: 9400, shot: 3300, caption: 'tilt the phone',
  state(t) {
    const phone = 5 * (ease(ramp(t, 1000, 2200)) - 2 * ease(ramp(t, 3900, 5700)) + ease(ramp(t, 7100, 8100)));
    const water = 5 * (settle(ramp(t, 1080, 3100)) - 2 * settle(ramp(t, 3980, 6600)) + settle(ramp(t, 7180, 9200)));
    return { tm: t, tilt: -Math.tan(water * DEG), phone };
  },
  top(t, st) { // the phone as held, its tilt drawn three times over so it reads at this size
    ctx.save();
    ctx.translate(394, 884);
    ctx.strokeStyle = ink(0.34); ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(-22, 0); ctx.lineTo(22, 0); ctx.stroke();
    ctx.rotate(st.phone * 3 * DEG);
    ctx.strokeStyle = ink(0.78); ctx.lineWidth = 1.3;
    ctx.beginPath(); ctx.roundRect(-9, -18, 18, 36, 4.5); ctx.stroke();
    ctx.restore();
  },
};

// Leave it alone: with no touch for twenty seconds the water stops moving and clears, down to the last rock.
function drifted(t, calm) { // the ground's clock, slowing to a stop as the water calms
  let tm = 0;
  for (let u = 0; u < t; u += 20) tm += 20 * (1 - calm(u));
  return tm;
}
EGGS.still = {
  dur: 9600, shot: 6900,
  calm: (t) => ease(ramp(t, 1200, 5600)) * (1 - ease(ramp(t, 7650, 8500))),
  state(t) { return { tm: drifted(t, this.calm), calm: this.calm(t) }; },
  top(t) {
    const s = t < 7650 ? Math.floor(20 * ramp(t, 1200, 5600) + Math.max(0, t - 5600) / 1000) : 0;
    note(`no touch for 0:${two(s)}`);
    touch(292, 520, ease(ramp(t, 7300, 7600)) * (1 - ease(ramp(t, 7950, 8300))), Math.max(0, Math.sin(Math.PI * ramp(t, 7560, 7940))));
  },
};

// ---------------------------------------------------------------- the frame
const egg = EGGS[EGG];
if (!egg) throw new Error('no such egg: ' + EGG);
const base = { camY: 0, ov: 1, pk: 0, pr: 0, lv: 0, glint: 0, near: 1, pkC: [220, 290] };
const zero = [0, 0, 0, 0];
World.load(['cover-first-stir', 'cover-lens', 'cover-escapement', 'cover-prism', 'cover-triptych', 'status']).then(() => World.start({
  fonts: ['300 28px UPro', 'italic 300 28px NY', '400 13px UMono', '250 34px UPro'],
  shader: sh,
  uniforms(t) {
    const st = egg.state(t);
    return { ...base, tm: st.tm, eShift: st.shift || 0, eTilt: st.tilt || 0, eCalm: st.calm || 0, eNight: st.night || 0,
      eDeep: st.deep || 0, eMoon: MOON, eRipX: st.ripX || zero, eRipA: st.ripA || zero, eRipX2: st.ripX2 || zero, eRipA2: st.ripA2 || zero };
  },
  draw(c, t) {
    ctx = c;
    const st = egg.state(t);
    ctx.save();
    ctx.translate(0, st.shift || 0);
    overview(st.tm, 1);
    if (egg.over) egg.over(t, st);
    ctx.restore();
    if (egg.top) egg.top(t, st);
    if (egg.caption) note(egg.caption);
    statusBar();
  },
  duration: egg.dur,
  shots: { [egg.name || EGG]: egg.shot },
}));
})();
