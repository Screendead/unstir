// Copyright © 2026 Jack Lusher. All rights reserved.
// The Rings in the outrun scene of Jack's reference board: a sky running purple to magenta to orange with stars, a
// sun cut by bands setting on a horizon, a ridge against it and a neon grid floor running to a vanishing point.
// Two looks share this file (window.LOOK, set by rings-sun and rings-gate):
//   a  the sun is the stage: it sets inside the ring, wireframe mountains either side, the tier's words dark on it
//   b  the ring is a gate standing on the grid road: the sun is the daily, setting behind a skyline and two palms
// The grid's straight lines and the sun's bands are Jack's references, which override "no hard straight lines" here.
//
// Built as it would ship: every picture is drawn once into a layer (build), and a frame is only those layers
// placed, scaled as a whole and faded (put). At rest nothing moves. On a tier change the stars shift and the grid
// runs towards the viewer: in the app that is one baked flat tile of grid under a fixed perspective transform,
// translated along itself by the compositor. This page has no perspective transform, so floor() stands in for it by
// drawing the tile's projection for the phase asked, kept while the phase holds.

const { ramp, ease, mix } = World;
const AX = World.ax;
const A = window.LOOK === 'a';
const S = World.scale;

const CX = 220, CY = AX ? 428 : 462;   // the ring's centre
const R = 190;                         // bead centres; 27 beads sit 44.2 pt apart along it
const BEAD = 27, NEXTBEAD = 37;
const ORBIT_DAILY = 300, ORBIT_PACKS = 304;
const TANK = { x: 220, y: 484, d: 409 };
const H0 = A ? CY + (AX ? 150 : 100) : 262;   // the horizon; under accessibility type look a's sun clears it, for its words
const DARK = '#1b0440', DARKRGB = '27, 4, 64';

const F = {
  name: (s, w = 300) => `${w} ${s}px UPro`,
  word: (s) => `italic 300 ${s}px NY`,
  data: (s, w = 400) => `${w} ${s}px UMono`,
};
const pt = (size, role) => size * (AX ? World.axScale[role] : 1);
const ink = (a) => `rgba(243, 240, 236, ${a})`;
const GOLD = '255, 232, 72';
const CYAN = '40, 236, 255', PINK = '255, 52, 200';
const SUN = ['#fff27a', '#ffb347', '#ff3d9a'];

const WHIRLPOOL = ['Spring', 'Headwaters', 'Creek', 'Brook', 'Stream', 'Shallows', 'Stepping stone', 'Riverbend',
  'Millpond', 'Dam', 'Floodgate', 'Water wheel', 'Rapids', 'Cascade', 'Waterfall', 'Plunge pool', 'Ravine', 'Canyon',
  'Meander', 'Sandbank', 'Wetland', 'Eddy', 'Tributary', 'Watershed', 'Floodplain', 'Salt marsh', 'Estuary'];

// The rings, shallowest first. solved: levels 1...solved are solved; over: those solved but not at par.
const RINGS = [
  { id: 'today', word: 'today', rgb: '255, 226, 70', n: 30, solved: 30, over: [1, 2, 3, 5, 6, 8, 9, 11, 12, 13, 15, 17, 19, 20, 21, 22, 23, 25, 26, 27, 28, 29, 30], missed: [4, 10, 14, 18, 22, 27] },
  { id: 'plughole', word: 'plughole', rgb: '40, 240, 220', n: 27, solved: 27, over: [8, 19, 23] },
  { id: 'whirlpool', word: 'whirlpool', rgb: '198, 96, 255', n: 27, solved: 14, over: [5, 9, 12], next: 15 },
  { id: 'vortex', word: 'vortex', rgb: '64, 132, 255', n: 27, solved: 0, over: [], locked: 'whirlpool' },
  { id: 'maelstrom', word: 'maelstrom', rgb: '255, 56, 96', n: 27, solved: 0, over: [], locked: 'vortex' },
  { id: 'endless', word: 'endless', rgb: '255, 60, 200', n: 0 },
];
const HOME = 2, PICK = 9;
const beadAngle = (k, n) => -Math.PI / 2 + (k - 0.5) * 2 * Math.PI / n;   // the seam between last and first is at the top
const beadAt = (k, n = 27) => ({ x: CX + R * Math.cos(beadAngle(k, n)), y: CY + R * Math.sin(beadAngle(k, n)) });

// ---------------------------------------------------------------- layers, each drawn once
const L = {};
function layer(name, w, h, draw, scale = S) {
  const c = document.createElement('canvas');
  c.width = Math.ceil(w * scale); c.height = Math.ceil(h * scale);
  const g = c.getContext('2d');
  g.scale(scale, scale);
  draw(g, w, h);
  L[name] = { c, w, h };
}
function say(g, str, x, y, font, fill, { align = 'center', track = 0 } = {}) {
  g.font = font; g.fillStyle = fill; g.textAlign = align; g.textBaseline = 'middle';
  g.letterSpacing = track + 'px';
  g.fillText(str, x + (align === 'center' ? track / 2 : 0), y);
  g.letterSpacing = '0px';
}
// Two runs set as one centred line, each in its own face.
function pair(g, a, fa, ca, b, fb, cb, x, y, gap) {
  g.font = fa; const wa = g.measureText(a).width;
  g.font = fb; const wb = g.measureText(b).width;
  const x0 = x - (wa + gap + wb) / 2;
  say(g, a, x0, y, fa, ca, { align: 'left' });
  say(g, b, x0 + wa + gap, y, fb, cb, { align: 'left' });
}

function tube(g, x, y, r, rgb, width, glow) {   // a neon ring
  g.save();
  g.shadowColor = `rgba(${rgb}, 0.95)`; g.shadowBlur = glow * S;
  g.strokeStyle = `rgba(${rgb}, 1)`; g.lineWidth = width;
  g.beginPath(); g.arc(x, y, r, 0, 7); g.stroke();
  g.restore();
}
function bead(g, x, y, d, rgb, state, label) {
  const r = d / 2;
  g.save();
  if (state === 'dull') {
    g.fillStyle = 'rgba(12, 3, 36, 0.72)'; g.beginPath(); g.arc(x, y, r, 0, 7); g.fill();
    g.strokeStyle = `rgba(${rgb}, 0.6)`; g.lineWidth = 1; g.beginPath(); g.arc(x, y, r - 0.5, 0, 7); g.stroke();
  } else if (state === 'solved') {   // solved over par: a lit tube round dark glass
    g.fillStyle = 'rgba(10, 4, 26, 0.92)'; g.beginPath(); g.arc(x, y, r, 0, 7); g.fill();
    tube(g, x, y, r - 1, rgb, 2, 7);
  } else {
    const hot = state === 'next';
    g.shadowColor = `rgba(${rgb}, 0.95)`; g.shadowBlur = (hot ? 28 : 10) * S;
    const f = g.createRadialGradient(x - r * 0.3, y - r * 0.38, 0, x, y, r);
    f.addColorStop(0, '#fff'); f.addColorStop(hot ? 0.6 : 0.45, `rgba(${rgb}, 1)`); f.addColorStop(1, `rgba(${rgb}, 0.86)`);
    g.fillStyle = f; g.beginPath(); g.arc(x, y, r, 0, 7); g.fill();
    if (hot) g.fill();
    g.shadowBlur = 0;
    if (hot) {   // the next level: its rim split into cyan and magenta
      g.lineWidth = 1.6;
      g.strokeStyle = `rgba(${CYAN}, 0.9)`; g.beginPath(); g.arc(x - 1.4, y, r + 4, 0, 7); g.stroke();
      g.strokeStyle = `rgba(${PINK}, 0.9)`; g.beginPath(); g.arc(x + 1.4, y, r + 4, 0, 7); g.stroke();
      g.strokeStyle = '#fff'; g.lineWidth = 1.2; g.beginPath(); g.arc(x, y, r + 4, 0, 7); g.stroke();
    } else tube(g, x, y, r + 2.6, GOLD, 1.6, 4);
  }
  g.restore();
  if (label) say(g, label, x, y + 0.5, F.data(state === 'next' ? 15 : 11, state === 'dull' ? 400 : 600),
    state === 'dull' ? ink(0.62) : state === 'solved' ? `rgba(${rgb}, 1)` : 'rgba(14, 6, 30, 0.92)');
}
// A sun, yellow over orange over hot pink (or the stops given), its lower part cut by bands of the sky behind it,
// and nothing drawn below `set`, the horizon it sets on.
function sun(g, x, y, d, { stops = SUN, set = d, bands = [[0.16, 0.09], [0.42, 0.13], [0.72, 0.17]], glow = 18 } = {}) {
  const r = d / 2;
  g.save();
  g.beginPath(); g.rect(x - d * 2, y - d * 2, d * 4, d * 2 + set); g.clip();
  g.shadowColor = 'rgba(255, 90, 150, 0.9)'; g.shadowBlur = glow * S;
  const f = g.createLinearGradient(0, y - r, 0, y + Math.min(r, set));
  stops.forEach((c, i) => f.addColorStop(i / (stops.length - 1), c));
  g.fillStyle = f; g.beginPath(); g.arc(x, y, r, 0, 7); g.fill();
  g.shadowBlur = 0; g.beginPath(); g.arc(x, y, r + 0.5, 0, 7); g.clip(); g.globalCompositeOperation = 'destination-out';
  for (const [a, h] of bands) g.fillRect(x - r - 2, y + a * r, d + 4, h * r);
  g.restore();
}
function star(g, x, y, r) {   // look a's daily, now the sun is the stage: the evening star
  g.save();
  g.shadowColor = `rgba(${CYAN}, 0.95)`; g.shadowBlur = 12 * S; g.fillStyle = '#fff';
  g.beginPath();
  for (let k = 0; k < 8; k++) { const q = k % 2 ? r * 0.2 : (k % 4 ? r * 0.72 : r), a = k * Math.PI / 4 - Math.PI / 2; g.lineTo(x + q * Math.cos(a), y + q * Math.sin(a)); }
  g.closePath(); g.fill(); g.fill();
  g.restore();
}
// Neon type: a white core running to the tube's colour, its glow, and a cyan and a magenta fringe.
function neon(g, str, x, y, font, rgb, size) {
  say(g, str, x - 1.3, y, font, `rgba(${CYAN}, 0.7)`);
  say(g, str, x + 1.3, y, font, `rgba(${PINK}, 0.7)`);
  g.save();
  g.shadowColor = `rgba(${rgb}, 0.95)`; g.shadowBlur = 12 * S;
  const f = g.createLinearGradient(0, y - size * 0.4, 0, y + size * 0.45);
  f.addColorStop(0, '#fff'); f.addColorStop(0.5, '#fff'); f.addColorStop(1, `rgba(${rgb}, 1)`);
  say(g, str, x, y, font, f);
  g.restore();
}

const RS = 2 * (R + 34);   // a ring layer's side
function stateOf(ring, k) {
  if (ring.next === k) return 'next';
  if (ring.missed && ring.missed.includes(k)) return 'dull';
  if (k > ring.solved) return 'dull';
  return ring.over.includes(k) ? 'solved' : 'par';
}
function ringLayer(ring, near) {
  layer(`${ring.id}-${near ? 'near' : 'far'}`, RS, RS, (g) => {
    const c = RS / 2, dim = ring.locked ? 0.72 : 1;
    g.globalAlpha = dim;
    if (!ring.n) {   // endless: one unbroken band
      g.shadowColor = `rgba(${ring.rgb}, 0.8)`; g.shadowBlur = (near ? 16 : 5) * S;
      g.strokeStyle = `rgba(${ring.rgb}, 0.95)`; g.lineWidth = near ? 5 : 3.5;
      g.beginPath(); g.arc(c, c, R, 0, 7); g.stroke();
      g.shadowBlur = 0;
      g.strokeStyle = 'rgba(255,255,255,0.75)'; g.lineWidth = 1.2;
      if (near) { g.beginPath(); g.arc(c, c, R, 0, 7); g.stroke(); }
      return;
    }
    g.strokeStyle = `rgba(${ring.rgb}, ${near ? 0.3 : 0.3})`; g.lineWidth = near ? 1 : 1.6;
    g.beginPath(); g.arc(c, c, R, 0, 7); g.stroke();
    for (let k = 1; k <= ring.n; k++) {
      const a = beadAngle(k, ring.n), x = c + R * Math.cos(a), y = c + R * Math.sin(a), st = stateOf(ring, k);
      if (near) bead(g, x, y, st === 'next' ? NEXTBEAD : ring.n > 27 ? 24 : BEAD, ring.rgb, st, ring.n > 27 ? '' : String(k).padStart(2, '0'));
      else {   // seen from far: a mote, no numeral (a scaled layer would shrink it)
        g.fillStyle = st === 'dull' ? `rgba(${ring.rgb}, 0.45)` : `rgba(${ring.rgb}, 1)`;
        g.beginPath(); g.arc(x, y, st === 'next' ? 9 : 5.5, 0, 7); g.fill();
      }
    }
  });
}

// The stage: what the middle of a ring says. 300 pt square, centred on the ring.
const ST = 344;
function stage(name, draw) { layer(name, ST, ST, (g) => { g.translate(ST / 2, ST / 2); draw(g); }); }
function playMark(g, y, rgb) {
  g.shadowColor = `rgba(${rgb}, 0.9)`; g.shadowBlur = 8 * S;
  g.fillStyle = `rgba(${rgb}, 1)`; g.strokeStyle = g.fillStyle; g.lineJoin = 'round'; g.lineWidth = 3;
  g.beginPath(); g.moveTo(-5, y - 7); g.lineTo(7, y); g.lineTo(-5, y + 7); g.closePath(); g.fill(); g.stroke();
  g.shadowBlur = 0;
}
// The rings a swipe away, named between the two depth rings: the one above at the top, the one below at the foot.
function ways(g, i) {
  if (AX) return;
  g.textBaseline = 'middle'; g.font = F.data(11, 500); g.letterSpacing = '1px';
  const up = RINGS[i - 1], down = RINGS[i + 1];
  const r = A ? 163 : 132;
  g.shadowColor = 'rgba(6, 0, 24, 0.95)'; g.shadowBlur = 4 * S;
  if (up) { g.fillStyle = `rgba(${up.rgb}, 1)`; World.arcText(g, `↑ ${up.word}`, 0, 0, r, -Math.PI / 2); }
  if (down) { g.fillStyle = `rgba(${down.rgb}, 0.95)`; World.arcText(g, `↓ ${down.word}`, 0, 0, r, Math.PI / 2, { inward: false }); }
  g.letterSpacing = '0px'; g.shadowBlur = 0;
}
function title(g, ring, y, size) {   // dark on look a's sun, neon elsewhere
  if (A) say(g, ring.word, 0, y, `italic 500 ${size}px NY`, DARK); else neon(g, ring.word, 0, y, F.word(size), ring.rgb, size);
}
function stages() {
  const w = RINGS[2], tint = (ring, a) => `rgba(${ring.rgb}, ${a})`;
  const hi = A ? DARK : ink(1), lo = A ? 'rgba(40, 6, 80, 0.86)' : ink(0.58), up = A ? -14 : 0, fat = A ? 500 : 400;
  const level = (g, ring, k, name, sub, cue) => {
    const num = A ? DARK : tint(ring, 1);
    if (AX) {
      title(g, ring, -78, pt(28, 'title'));
      say(g, sub, 0, -38, F.data(pt(13, 'detail'), fat), A ? lo : ink(0.62));
      say(g, String(k).padStart(2, '0'), 0, 8, F.data(pt(20, 'title'), 500), num);
      say(g, name, 0, 60, F.name(pt(28, 'title'), A ? 400 : 300), hi);
      return;
    }
    title(g, ring, -62 + up, 38);
    ways(g, RINGS.indexOf(ring));
    say(g, sub, 0, -29 + up, F.data(13, fat), lo, { track: 0.4 });
    pair(g, String(k).padStart(2, '0'), F.data(20, 600), num, name, F.name(30, A ? 400 : 300), hi, 0, 22 + up, 10);
    if (cue) say(g, cue, 0, 62 + 2 * up, F.data(13, fat), A ? lo : ink(0.5), { track: 0.4 }); else playMark(g, 64 + 2 * up, A ? DARKRGB : ring.rgb);
  };
  stage('whirlpool-stage', (g) => level(g, w, 15, 'Waterfall', AX ? '14/27 · 11 par' : '14/27 · 11 at par'));
  stage('whirlpool-pick', (g) => level(g, w, PICK, WHIRLPOOL[PICK - 1], 'solved in 6 · par 5', 'tap again to play'));
  stage('plughole-stage', (g) => level(g, RINGS[1], 1, 'Drop', '27/27 · 24 at par'));
  for (const ring of [RINGS[3], RINGS[4]]) stage(`${ring.id}-stage`, (g) => {
    say(g, ring.word, 0, -34, F.word(38), ink(0.2));   // an unlit tube
    g.font = F.word(38); g.strokeStyle = tint(ring, 0.9); g.lineWidth = 0.9; g.textAlign = 'center'; g.strokeText(ring.word, 0, -34);
    ways(g, RINGS.indexOf(ring));
    say(g, 'opens with every', 0, 8, F.name(16, 400), ink(0.7));
    say(g, `${ring.locked} level solved`, 0, 31, F.name(16, 400), ink(0.7));
  });
  stage('today-stage', (g) => {
    title(g, RINGS[0], -62 + up, 38);
    ways(g, 0);
    say(g, '30 past dailies · 3 at par', 0, -29 + up, F.data(13, fat), lo, { track: 0.4 });
    say(g, 'Fri 27 Nov', 0, 22 + up, F.name(30, A ? 400 : 300), hi);
    playMark(g, 64 + 2 * up, A ? DARKRGB : RINGS[0].rgb);
  });
  stage('endless-stage', (g) => {
    title(g, RINGS[5], -62 + up, 38);
    ways(g, 5);
    say(g, 'tank 6 · brim 3 · best 9', 0, -29 + up, F.data(13, fat), lo, { track: 0.4 });
    say(g, 'continue', 0, 22 + up, F.name(30, A ? 400 : 300), hi);
    say(g, 'new run', 0, 62 + 2 * up, F.name(17, 500), A ? lo : ink(0.7));
  });
}

function chrome() {
  // The wordmark, and settings on the axis at the foot: six motes round a seventh.
  layer('wordmark', 300, 60, (g) => {   // chrome: sky over the horizon over sunset
    const f = g.createLinearGradient(0, 19, 0, 41);
    f.addColorStop(0, '#ffffff'); f.addColorStop(0.44, '#62d4ff'); f.addColorStop(0.5, '#2a1a90');
    f.addColorStop(0.56, '#ff4fd0'); f.addColorStop(1, '#ffd65a');
    g.shadowColor = `rgba(${PINK}, 0.8)`; g.shadowBlur = 9 * S;
    say(g, 'UNSTIR', 150, 30, F.name(23, 700), f, { track: 11 });
  });
  layer('settings', 44, 44, (g) => {
    g.fillStyle = ink(0.5);
    for (let k = 0; k < 6; k++) { g.beginPath(); g.arc(22 + 7.5 * Math.cos(k * Math.PI / 3), 22 + 7.5 * Math.sin(k * Math.PI / 3), 1.7, 0, 7); g.fill(); }
    g.beginPath(); g.arc(22, 22, 2.2, 0, 7); g.fill();
  });

  // Today's daily: one bright bead on the orbit above the ring, its words along the orbit either side.
  const rgb = RINGS[0].rgb;
  layer('daily', 440, 260, (g) => {
    if (AX) {
      if (A) star(g, 220, 40, 15); else sun(g, 220, 40, 32);
      say(g, 'Daily · Fri 27 Nov', 220, 88, F.name(pt(17, 'headline')), ink(1));
      say(g, '4 days running', 220, 128, F.data(pt(13, 'detail')), ink(0.62));
      return;
    }
    const cy = 40 + ORBIT_DAILY;
    if (A) star(g, 220, 40, 15); else sun(g, 220, 40, 32);
    g.textBaseline = 'middle';
    g.font = F.name(16, 400); g.fillStyle = ink(0.96); g.letterSpacing = '0.3px';
    const w1 = g.measureText('Daily · Fri 27 Nov').width;
    World.arcText(g, 'Daily · Fri 27 Nov', 220, cy, ORBIT_DAILY, -Math.PI / 2 - (30 + w1 / 2) / ORBIT_DAILY);
    g.fillStyle = ink(0.58);
    const w2 = g.measureText('4 days running').width;
    World.arcText(g, '4 days running', 220, cy, ORBIT_DAILY, -Math.PI / 2 + (30 + w2 / 2) / ORBIT_DAILY);
    g.letterSpacing = '0px';
  });

  // The packs: three covers on the orbit below the ring.
  const packs = [
    { id: 'lens', name: 'Lens', state: 'owned ✓', ax: 'Lens ✓', a: Math.PI / 2 + 0.41 },
    { id: 'escapement', name: 'Escapement', state: '1/3 free', ax: 'Escapement 1/3', a: Math.PI / 2 },
    { id: 'prism', name: 'Prism', state: '2/3 free', ax: 'Prism 2/3', a: Math.PI / 2 - 0.41 },
  ];
  const top = CY + ORBIT_PACKS - 110, d = AX ? 78 : 84;
  layer('packs', 440, AX ? 330 : 260, (g) => {
    for (const p of packs) {
      const orbit = AX ? ORBIT_PACKS - 16 : ORBIT_PACKS;
      const x = CX + orbit * Math.cos(p.a), y = CY + orbit * Math.sin(p.a) - top;
      g.save();
      g.shadowColor = `rgba(${A ? CYAN : PINK}, 0.6)`; g.shadowBlur = 12 * S;
      g.fillStyle = '#000'; g.beginPath(); g.arc(x, y, d / 2 - 1, 0, 7); g.fill();
      g.restore();
      g.drawImage(World.images['rings-' + p.id], x - d / 2, y - d / 2, d, d);
      g.shadowColor = 'rgba(6, 0, 24, 1)'; g.shadowBlur = 5 * S;
      if (AX) say(g, p.ax, x, p.id === 'escapement' ? y + d / 2 + 58 : y + d / 2 + 40, F.name(pt(15, 'label'), 400), ink(0.96));
      else {
        say(g, p.name, x, y + d / 2 + 20, F.name(16, 400), ink(0.96));
        say(g, p.state, x, y + d / 2 + 39, F.data(12), p.id === 'lens' ? `rgba(${GOLD}, 1)` : ink(0.8));
      }
    }
    g.shadowColor = 'rgba(6, 0, 24, 1)'; g.shadowBlur = 5 * S;
    if (AX) {
      say(g, 'packs · first 3 levels', 220, 238, F.data(pt(12, 'detail')), ink(0.8));
      say(g, 'of each free', 220, 268, F.data(pt(12, 'detail')), ink(0.55));
    } else say(g, 'packs · first 3 levels of each free', 220, 228, F.data(12), ink(0.8), { track: 0.4 });
  });
  L.packs.top = top;
}

// A seeded draw, so the stars and the skyline are the same every load.
let seed = 7;
const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
function scene() {
  layer('sky', 440, H0, (g) => {
    const f = g.createLinearGradient(0, 0, 0, H0);
    const stops = A ? [[0, '#070222'], [0.42, '#1c0648'], [0.72, '#4a0f72'], [0.9, '#a3267f'], [1, '#ff7a4a']]
      : [[0, '#0a0328'], [0.4, '#3a0a6a'], [0.7, '#a01f8a'], [0.9, '#ff4f8a'], [1, '#ffa24a']];
    for (const [k, c] of stops) f.addColorStop(k, c);
    g.fillStyle = f; g.fillRect(0, 0, 440, H0);
  });
  layer('stars', 440, H0, (g) => {
    for (let k = 0; k < (A ? 110 : 60); k++) {
      const x = rnd() * 440, y = rnd() * rnd() * H0 * 0.8, r = 0.4 + rnd() * 0.8;
      g.fillStyle = `rgba(255, 255, 255, ${0.35 + 0.6 * rnd()})`; g.beginPath(); g.arc(x, y, r, 0, 7); g.fill();
    }
  });
  layer('ridge', 440, 160, (g) => {
    for (const side of [1, -1]) {
      g.save();
      if (side < 0) { g.translate(440, 0); g.scale(-1, 1); }
      if (A) {   // wireframe mountains, low towards the middle so the sun sets between them
        const pts = [[0, 50], [24, 76], [48, 40], [76, 64], [102, 28], [126, 42], [148, 14], [170, 22], [198, 0]];
        g.beginPath(); g.moveTo(0, 160);
        if (AX) for (const q of pts) q[1] *= 0.4;
        for (const [x, h] of pts) g.lineTo(x, 160 - h);
        g.closePath(); g.fillStyle = '#10033a'; g.fill();
        g.shadowColor = `rgba(${CYAN}, 0.9)`; g.shadowBlur = 4 * S; g.strokeStyle = `rgba(${CYAN}, 0.95)`; g.lineWidth = 1.1; g.lineJoin = 'round';
        g.beginPath(); pts.forEach(([x, h], k) => k ? g.lineTo(x, 160 - h) : g.moveTo(x, 160 - h)); g.stroke();
        g.globalAlpha = 0.55; g.lineWidth = 0.8;
        for (const k of [1, 3, 5, 7]) for (const dx of [-17, -4, 11]) { g.beginPath(); g.moveTo(pts[k][0], 160 - pts[k][1]); g.lineTo(pts[k][0] + dx * (1 + pts[k][1] / 60), 160); g.stroke(); }
      } else {   // a skyline, and a palm at the edge
        g.fillStyle = '#0d0228';
        for (let x = 0; x < 128;) {
          const w = 8 + rnd() * 11, h = 14 + rnd() * 52 * (0.4 + 0.6 * Math.sin(x / 128 * Math.PI));
          g.fillRect(x, 160 - h, w + 0.5, h);
          g.fillStyle = 'rgba(255, 214, 110, 0.85)';
          for (let n = 0; n < 4; n++) if (rnd() < 0.6) g.fillRect(x + 2 + Math.floor(rnd() * (w - 4)), 160 - h + 4 + Math.floor(rnd() * Math.max(1, h - 10)), 1.2, 1.6);
          g.fillStyle = '#0d0228';
          x += w;
        }
        g.fillStyle = '#07011c'; g.strokeStyle = '#07011c'; g.lineWidth = 3.4; g.lineCap = 'round';
        g.beginPath(); g.moveTo(26, 160); g.quadraticCurveTo(40, 92, 33, 34); g.stroke();
        for (const [a, len] of [[-2.9, 34], [-2.3, 40], [-1.75, 36], [-1.2, 38], [-0.6, 40], [0.05, 34], [3.4, 26]]) {
          const ex = 33 + len * Math.cos(a), ey = 34 + len * Math.sin(a) + 12, mx = 33 + len * 0.5 * Math.cos(a), my = 34 + len * 0.5 * Math.sin(a);
          g.beginPath(); g.moveTo(33, 34); g.quadraticCurveTo(mx, my - 12, ex, ey); g.quadraticCurveTo(mx, my - 1, 33, 34); g.fill();
        }
      }
      g.restore();
    }
  });
  if (A) for (const ring of RINGS) layer(`${ring.id}-sun`, 400, 400, (g) => {   // the stage: each ring's sun, setting
    const bands = AX ? [] : [[0.34, 0.025], [0.44, 0.04], [0.55, 0.055]];
    if (ring.locked) {   // a tier not yet open: the sun is down, a dark disc with its rim lit
      sun(g, 200, 200, 300, { stops: ['#2a1060', '#3c1272', '#5a1a7a'], set: H0 - CY, bands, glow: 0 });
      g.save(); g.beginPath(); g.rect(0, 0, 400, 200 + H0 - CY); g.clip(); tube(g, 200, 200, 149, ring.rgb, 1.4, 6); g.restore();
    } else sun(g, 200, 200, 300, { stops: ring.id === 'plughole' ? ['#f6ffa0', '#7af0c0', '#22c4e0'] : ring.id === 'endless' ? ['#ffd0f0', '#ff6ad0', '#a04cff'] : SUN, set: H0 - CY, bands, glow: 26 });
  });
  else {
    // The gate's dark: the road beyond the ring, so the stage's words sit on night.
    layer('portal', 2 * R + 40, 2 * R + 40, (g) => {
      const c = R + 20, f = g.createRadialGradient(c, c, 0, c, c, R + 12);
      f.addColorStop(0, 'rgba(8, 2, 30, 0.9)'); f.addColorStop(0.86, 'rgba(8, 2, 30, 0.86)'); f.addColorStop(1, 'rgba(8, 2, 30, 0)');
      g.fillStyle = f; g.fillRect(0, 0, 2 * c, 2 * c);
    });
    // The daily is the sun itself, its day and streak dark on it.
    layer('daysun', 300, 300, (g) => {
      sun(g, 150, 150, 192, { set: H0 - 236, bands: [[0.04, 0.03], [0.12, 0.04], [0.2, 0.05]], glow: 24 });
      say(g, 'Daily · Fri 27 Nov', 150, 108, F.name(16, 600), DARK);
      say(g, '4 days running', 150, 131, F.data(12, 600), 'rgba(40, 6, 80, 0.9)');
    });
  }
}
// The grid floor at a phase of its run towards the viewer (see the note at the top).
const GRID = A ? PINK : CYAN;
let floorKey = -1;
function floor(phase) {
  const key = Math.round((phase - Math.floor(phase)) * 400) % 400;
  if (key === floorKey) return 'floor';
  floorKey = key;
  layer('floor', 440, 956 - H0, (g, w, h) => {
    const f = g.createLinearGradient(0, 0, 0, h);
    f.addColorStop(0, '#220648'); f.addColorStop(0.25, '#12033a'); f.addColorStop(1, '#06011c');
    g.fillStyle = f; g.fillRect(0, 0, w, h);
    g.shadowColor = `rgba(${GRID}, 0.9)`; g.shadowBlur = 3 * S; g.strokeStyle = `rgba(${GRID}, 0.7)`; g.lineWidth = 1;
    g.beginPath();
    for (let i = -30; i <= 30; i++) { g.moveTo(220 + i * 1.6, 0); g.lineTo(220 + i * (A ? 62 : 74) * h / 394, h); }
    g.stroke();
    for (let k = 1; k < 70; k++) {
      const y = h * 1.5 / (k - key / 400);
      if (y > h + 2 || y < 0) continue;
      g.globalAlpha = 0.08 + 0.92 * ramp(y, 4, 120);
      g.beginPath(); g.moveTo(0, y); g.lineTo(w, y); g.stroke();
    }
    g.globalAlpha = 1; g.shadowBlur = 0;
    const haze = g.createLinearGradient(0, 0, 0, 46);
    haze.addColorStop(0, A ? 'rgba(255, 110, 150, 0.85)' : 'rgba(255, 150, 120, 0.85)'); haze.addColorStop(1, 'rgba(255, 80, 170, 0)');
    g.fillStyle = haze; g.fillRect(0, 0, w, 46);
    g.shadowColor = '#fff'; g.shadowBlur = 5 * S; g.fillStyle = 'rgba(255, 236, 240, 0.95)'; g.fillRect(0, 0, w, 1.4);
  });
  return 'floor';
}
function lights() {
  scene();
  // Each ring's light: a soft band where its beads sit, drawn small and stretched (it has no detail to lose).
  for (const ring of RINGS) layer(`${ring.id}-glow`, 760, 760, (g) => {
    const f = g.createRadialGradient(380, 380, 0, 380, 380, 380);
    const a = ring.locked ? 0.6 : 1;
    f.addColorStop(0, `rgba(${ring.rgb}, ${0.04 * a})`);
    f.addColorStop(0.34, `rgba(${ring.rgb}, ${0.11 * a})`);
    f.addColorStop(0.5, `rgba(${ring.rgb}, ${0.24 * a})`);
    f.addColorStop(0.68, `rgba(${ring.rgb}, ${0.08 * a})`);
    f.addColorStop(1, `rgba(${ring.rgb}, 0)`);
    g.fillStyle = f; g.fillRect(0, 0, 760, 760);
  }, 0.5);
  layer('halo', 80, 80, (g) => {   // round a picked bead
    g.shadowColor = 'rgba(255,255,255,0.9)'; g.shadowBlur = 8 * S;
    g.strokeStyle = 'rgba(255,255,255,0.95)'; g.lineWidth = 1.6;
    g.beginPath(); g.arc(40, 40, BEAD / 2 + 6.5, 0, 7); g.stroke();
  });
  layer('touch', 64, 64, (g) => {
    const f = g.createRadialGradient(32, 32, 0, 32, 32, 30);
    f.addColorStop(0, 'rgba(255,255,255,0.5)'); f.addColorStop(0.7, 'rgba(255,255,255,0.28)'); f.addColorStop(1, 'rgba(255,255,255,0)');
    g.fillStyle = f; g.fillRect(0, 0, 64, 64);
  });
  layer('tank', TANK.d, TANK.d, (g) => g.drawImage(World.images['rings-tank'], 0, 0, TANK.d, TANK.d));
  layer('hud', 440, 80, (g) => {
    pair(g, '15', F.data(17, 500), `rgba(${RINGS[2].rgb}, 1)`, 'Waterfall', F.name(24), ink(1), 220, 24, 10);
    say(g, 'moves 0 / par 8', 220, 56, F.data(13), ink(0.55), { track: 0.4 });
  });
}

function build() {
  for (const ring of RINGS) { ringLayer(ring, true); ringLayer(ring, false); }
  stages(); chrome(); lights();
}

// ---------------------------------------------------------------- a frame: layers placed, scaled and faded
let ctx;
function put(name, x, y, scale = 1, alpha = 1) {
  if (alpha <= 0.003) return;
  const l = L[name];
  ctx.globalAlpha = Math.min(1, alpha);
  ctx.drawImage(l.c, x - l.w * scale / 2, y - l.h * scale / 2, l.w * scale, l.h * scale);
  ctx.globalAlpha = 1;
}

// ---------------------------------------------------------------- the timeline
// 0      launch at rest                                   launch
// 1.5    a swipe up: whirlpool passes, vortex comes forward
// 2.5    vortex at rest, locked                           locked
// 3.8    a swipe down: back to whirlpool
// 5.8    a tap on bead 09 names it in the middle          bead
// 7.6    a tap on the next bead: its tank grows from it
// 9.2    the tank at rest
// Past the film: today's ring and endless, as stills.
const DUR = 11000;
const SHOTS = AX ? { launch: 600 } : { launch: 600, locked: 3200, bead: 6900, today: 20000, endless: 21000 };

const glide = (x) => x * x * (3 - 2 * x);
function place(t) {   // which ring is forward, as a ring index that may sit between two
  if (t >= 21000) return 5;
  if (t >= 20000) return 0;
  return HOME + glide(ramp(t, 1650, 2500)) - glide(ramp(t, 3850, 4750));
}
const picked = (t) => t >= 20000 ? 0 : ease(ramp(t, 5850, 6150)) * (1 - ease(ramp(t, 7650, 7850)));
const open = (t) => t >= 20000 ? 0 : ease(ramp(t, 7700, 9000));
function touch(t) {
  const press = (a, b) => ease(ramp(t, a, a + 120)) * (1 - ease(ramp(t, b, b + 180)));
  if (t < 3000) return { x: 318, y: mix(650, 430, glide(ramp(t, 1620, 2200))), a: press(1500, 2200) };
  if (t < 5400) return { x: 318, y: mix(430, 650, glide(ramp(t, 3800, 4400))), a: press(3680, 4400) };
  if (t < 7200) return { ...beadAt(PICK), a: press(5700, 5880) };
  return { ...beadAt(15), a: press(7500, 7680) };
}

function draw(g, t) {
  ctx = g;
  const p = place(t), o = open(t), menu = 1 - ease(ramp(o, 0, 0.7)), dive = 1 + 0.5 * o;
  put('sky', 220, H0 / 2, 1, menu);
  put('stars', 220, H0 / 2 - (p - HOME) * 10, 1, menu);
  if (A) RINGS.forEach((ring, i) => put(`${ring.id}-sun`, CX, CY, 1, Math.max(0, 1 - Math.abs(i - p)) * menu));
  else if (!AX) put('daysun', 220, 236, 1, menu);
  put('ridge', 220, H0 - 80, 1, menu);
  put(floor(p * 2), 220, (956 + H0) / 2, 1, menu);
  if (!A) put('portal', CX, CY, dive, menu);
  RINGS.forEach((ring, i) => {
    const d = i - p;                                   // depth: 0 forward, + deeper, - passed
    const s = (d >= 0 ? Math.pow(0.78, d) : Math.pow(1.5, -d)) * dive;
    const near = d >= 0 ? 1 - ramp(d, 0.05, 0.7) : 1 + d * 1.25;
    const far = AX || A ? 0 : ramp(d, 0.3, 1) * (d <= 1 ? 0.6 : d <= 2 ? mix(0.6, 0.26, d - 1) : mix(0.26, 0, d - 2));
    if (!A) put(`${ring.id}-glow`, CX, CY, s, Math.max(0, 1 - Math.abs(d)) * menu);
    put(`${ring.id}-far`, CX, CY, s, far * menu);
    put(`${ring.id}-near`, CX, CY, s, near * menu);
    const words = Math.max(0, 1 - 2.2 * Math.abs(d)) * menu;
    if (ring.id === 'whirlpool') {
      put('whirlpool-stage', CX, CY, s, words * (1 - picked(t)));
      put('whirlpool-pick', CX, CY, s, words * picked(t));
    } else put(`${ring.id}-stage`, CX, CY, s, words);
  });
  const b = beadAt(PICK);
  put('halo', b.x, b.y, 1, picked(t) * menu);
  put('wordmark', 220, AX ? 72 : 86, 1, menu);
  if (A || AX) put('daily', 220, CY - ORBIT_DAILY - 40 + 130 - (AX ? 20 : 0), 1, menu);
  put('packs', 220, L.packs.top + L.packs.h / 2, 1, menu);
  put('settings', 220, AX ? 921 : 912, 1, menu);

  const from = beadAt(15), k = glide(ramp(o, 0, 1));
  put('tank', mix(from.x, TANK.x, k), mix(from.y, TANK.y, k), mix(NEXTBEAD / TANK.d, 1, k), ramp(o, 0, 0.12));
  put('hud', 220, 150, 1, ease(ramp(t, 9000, 9600)) * (t < 20000 ? 1 : 0));
  const f = touch(t);
  put('touch', f.x, f.y, 1, t < 20000 ? f.a : 0);
}

World.load(['rings-tank', 'rings-lens', 'rings-escapement', 'rings-prism']).then(() => {
  const fonts = ['italic 500 38px NY', '700 23px UPro', '600 16px UPro', '600 12px UMono', '500 13px UMono', '300 30px UPro', '400 16px UPro', 'italic 300 36px NY', '400 13px UMono', '500 20px UMono', '600 11px UMono'];
  Promise.all(fonts.map(f => document.fonts.load(f))).then(() => {
    build();
    window.DRAWS_AX = true;
    World.start({
      shader: `void main() { o = vec4(0.016, 0.014, 0.027, 1.); }`,
      draw, duration: DUR, shots: SHOTS, fonts,
    });
  });
});
