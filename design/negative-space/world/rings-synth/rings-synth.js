// Copyright © 2026 Jack Lusher. All rights reserved.
// The Rings, second pass, in the tank art's own finish: neon on dark, the Lens cover's magenta, cyan and yellow, a
// halftone of dots falling away down the well and a sunset low in the ground, all baked into one ground layer.
// The ring is wider (beads 44 pt apart) and the stage names the rings a swipe above and below.
// The menu as rings seen straight down a well. One ring fills the screen at a time, 27 beads for a tier's
// 27 levels, and its middle is the stage: the tier, its count and the level to play. Deeper rings wait inside it,
// smaller and dimmer; a vertical swipe brings the next one forward by scale and fade alone. Above the tiers is
// today's ring (the daily in its middle, the archive's 30 days its beads); below them endless, a ring with no beads.
//
// Built as it would ship: every picture is drawn once into a layer when the page loads (build), and a frame is only
// those layers placed, scaled as a whole and faded (put). Nothing is drawn per frame, nothing rotates, and nothing
// moves at rest. The ground shader is one constant colour.

const { ramp, ease, mix } = World;
const AX = World.ax;
const S = World.scale;

const CX = 220, CY = AX ? 428 : 462;   // the ring's centre
const R = 190;                         // bead centres; 27 beads sit 44.2 pt apart along it
const BEAD = 27, NEXTBEAD = 37;
const ORBIT_DAILY = 300, ORBIT_PACKS = 304;
const TANK = { x: 220, y: 484, d: 409 };

const F = {
  name: (s, w = 300) => `${w} ${s}px UPro`,
  word: (s) => `italic 300 ${s}px NY`,
  data: (s, w = 400) => `${w} ${s}px UMono`,
};
const pt = (size, role) => size * (AX ? World.axScale[role] : 1);
const ink = (a) => `rgba(243, 240, 236, ${a})`;
const GOLD = '255, 232, 72';
const CYAN = '40, 236, 255', PINK = '255, 52, 200';

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
    g.fillStyle = `rgba(${rgb}, 0.05)`; g.beginPath(); g.arc(x, y, r, 0, 7); g.fill();
    g.strokeStyle = `rgba(${rgb}, 0.42)`; g.lineWidth = 1; g.beginPath(); g.arc(x, y, r - 0.5, 0, 7); g.stroke();
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
    state === 'dull' ? ink(0.52) : state === 'solved' ? `rgba(${rgb}, 1)` : 'rgba(14, 6, 30, 0.92)');
}
// The daily: a small sun, yellow over hot pink, its lower half cut by three bands of the ground.
function sun(g, x, y, d) {
  const r = d / 2;
  g.save();
  g.shadowColor = 'rgba(255, 120, 90, 0.9)'; g.shadowBlur = 18 * S;
  const f = g.createLinearGradient(0, y - r, 0, y + r);
  f.addColorStop(0, 'rgb(255, 240, 96)'); f.addColorStop(0.5, 'rgb(255, 170, 70)'); f.addColorStop(1, 'rgb(255, 48, 170)');
  g.fillStyle = f; g.beginPath(); g.arc(x, y, r, 0, 7); g.fill();
  g.shadowBlur = 0; g.beginPath(); g.arc(x, y, r + 0.5, 0, 7); g.clip(); g.globalCompositeOperation = 'destination-out';
  for (const [a, h] of [[0.16, 0.09], [0.42, 0.13], [0.72, 0.17]]) g.fillRect(x - r - 2, y + a * r, d + 4, h * r);
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
const ST = 300;
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
  if (up) { g.fillStyle = `rgba(${up.rgb}, 0.85)`; World.arcText(g, `↑ ${up.word}`, 0, 0, 132, -Math.PI / 2); }
  if (down) { g.fillStyle = `rgba(${down.rgb}, 0.95)`; World.arcText(g, `↓ ${down.word}`, 0, 0, 132, Math.PI / 2, { inward: false }); }
  g.letterSpacing = '0px';
}
function stages() {
  const w = RINGS[2], tint = (ring, a) => `rgba(${ring.rgb}, ${a})`;
  const level = (g, ring, k, name, sub, cue) => {
    if (AX) {
      neon(g, ring.word, 0, -78, F.word(pt(28, 'title')), ring.rgb, pt(28, 'title'));
      say(g, sub, 0, -38, F.data(pt(13, 'detail')), ink(0.62));
      say(g, String(k).padStart(2, '0'), 0, 8, F.data(pt(20, 'title'), 500), tint(ring, 1));
      say(g, name, 0, 60, F.name(pt(28, 'title')), ink(1));
      return;
    }
    neon(g, ring.word, 0, -62, F.word(38), ring.rgb, 38);
    ways(g, RINGS.indexOf(ring));
    say(g, sub, 0, -29, F.data(13), ink(0.58), { track: 0.4 });
    pair(g, String(k).padStart(2, '0'), F.data(20, 500), tint(ring, 1), name, F.name(30), ink(1), 0, 22, 10);
    if (cue) say(g, cue, 0, 62, F.data(13), ink(0.5), { track: 0.4 }); else playMark(g, 64, ring.rgb);
  };
  stage('whirlpool-stage', (g) => level(g, w, 15, 'Waterfall', AX ? '14/27 · 11 par' : '14/27 · 11 at par'));
  stage('whirlpool-pick', (g) => level(g, w, PICK, WHIRLPOOL[PICK - 1], 'solved in 6 · par 5', 'tap again to play'));
  stage('plughole-stage', (g) => level(g, RINGS[1], 1, 'Drop', '27/27 · 24 at par'));
  for (const ring of [RINGS[3], RINGS[4]]) stage(`${ring.id}-stage`, (g) => {
    say(g, ring.word, 0, -34, F.word(38), ink(0.2));   // an unlit tube
    g.font = F.word(38); g.strokeStyle = tint(ring, 0.85); g.lineWidth = 0.9; g.textAlign = 'center'; g.strokeText(ring.word, 0, -34);
    ways(g, RINGS.indexOf(ring));
    say(g, 'opens with every', 0, 8, F.name(16, 400), ink(0.62));
    say(g, `${ring.locked} level solved`, 0, 31, F.name(16, 400), ink(0.62));
  });
  stage('today-stage', (g) => {
    neon(g, 'today', 0, -62, F.word(38), RINGS[0].rgb, 38);
    ways(g, 0);
    say(g, '30 past dailies · 3 at par', 0, -29, F.data(13), ink(0.58), { track: 0.4 });
    say(g, 'Fri 27 Nov', 0, 22, F.name(30), ink(1));
    playMark(g, 64, RINGS[0].rgb);
  });
  stage('endless-stage', (g) => {
    neon(g, 'endless', 0, -62, F.word(38), RINGS[5].rgb, 38);
    ways(g, 5);
    say(g, 'tank 6 · brim 3 · best 9', 0, -29, F.data(13), ink(0.58), { track: 0.4 });
    say(g, 'continue', 0, 22, F.name(30), ink(1));
    say(g, 'new run', 0, 72, F.name(17, 400), ink(0.7));
  });
}

function chrome() {
  // The wordmark, and settings on the axis at the foot: six motes round a seventh.
  layer('wordmark', 300, 60, (g) => {
    const f = g.createLinearGradient(62, 0, 238, 0);
    f.addColorStop(0, `rgb(${CYAN})`); f.addColorStop(0.5, `rgb(${PINK})`); f.addColorStop(1, 'rgb(255, 176, 64)');
    g.shadowColor = `rgba(${PINK}, 0.7)`; g.shadowBlur = 9 * S;
    say(g, 'UNSTIR', 150, 30, F.name(22, 500), f, { track: 11 });
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
      sun(g, 220, 40, 32);
      say(g, 'Daily · Fri 27 Nov', 220, 88, F.name(pt(17, 'headline')), ink(1));
      say(g, '4 days running', 220, 128, F.data(pt(13, 'detail')), ink(0.62));
      return;
    }
    const cy = 40 + ORBIT_DAILY;
    sun(g, 220, 40, 32);
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
      g.shadowColor = `rgba(${PINK}, 0.5)`; g.shadowBlur = 14 * S;
      g.fillStyle = '#000'; g.beginPath(); g.arc(x, y, d / 2 - 1, 0, 7); g.fill();
      g.restore();
      g.drawImage(World.images['rings-' + p.id], x - d / 2, y - d / 2, d, d);
      if (AX) say(g, p.ax, x, p.id === 'escapement' ? y + d / 2 + 58 : y + d / 2 + 40, F.name(pt(15, 'label'), 400), ink(0.96));
      else {
        say(g, p.name, x, y + d / 2 + 20, F.name(16, 400), ink(0.96));
        say(g, p.state, x, y + d / 2 + 39, F.data(12), p.id === 'lens' ? `rgba(${GOLD}, 0.95)` : ink(0.62));
      }
    }
    if (AX) {
      say(g, 'packs · first 3 levels', 220, 238, F.data(pt(12, 'detail')), ink(0.55));
      say(g, 'of each free', 220, 268, F.data(pt(12, 'detail')), ink(0.55));
    } else say(g, 'packs · first 3 levels of each free', 220, 228, F.data(12), ink(0.6), { track: 0.4 });
  });
  L.packs.top = top;
}

function lights() {
  // The ground, once: night running down to a sunset, and a halftone of dots that shrink towards the well's centre,
  // cyan above it and magenta below. No dot falls inside the ring.
  layer('ground', 440, 956, (g) => {
    const f = g.createLinearGradient(0, 0, 0, 956);
    f.addColorStop(0, '#04031a'); f.addColorStop(0.5, '#0a0424'); f.addColorStop(0.74, '#220a44');
    f.addColorStop(0.9, '#4a1060'); f.addColorStop(1, '#8a2c5c');
    g.fillStyle = f; g.fillRect(0, 0, 440, 956);
    let row = 0;
    for (let r = 232; r < 800; r *= 1.058, row++) for (let k = 0; k < 81; k++) {
      const a = (k + (row % 2) / 2) * 2 * Math.PI / 81, x = CX + r * Math.cos(a), y = CY + r * Math.sin(a);
      if (x < -8 || x > 448 || y < -8 || y > 964) continue;
      const low = ramp(y, CY - 240, CY + 240);
      g.fillStyle = `rgba(${Math.round(mix(40, 255, low))}, ${Math.round(mix(236, 52, low))}, ${Math.round(mix(255, 200, low))}, ${0.17 * ramp(r, 225, 320)})`;
      g.beginPath(); g.arc(x, y, r * 0.0062, 0, 7); g.fill();
    }
  });
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
  put('ground', 220, 478, 1, menu);
  RINGS.forEach((ring, i) => {
    const d = i - p;                                   // depth: 0 forward, + deeper, - passed
    const s = (d >= 0 ? Math.pow(0.78, d) : Math.pow(1.5, -d)) * dive;
    const near = d >= 0 ? 1 - ramp(d, 0.05, 0.7) : 1 + d * 1.25;
    const far = AX ? 0 : ramp(d, 0.3, 1) * (d <= 1 ? 0.6 : d <= 2 ? mix(0.6, 0.26, d - 1) : mix(0.26, 0, d - 2));
    put(`${ring.id}-glow`, CX, CY, s, Math.max(0, 1 - Math.abs(d)) * menu);
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
  put('daily', 220, CY - ORBIT_DAILY - 40 + 130 - (AX ? 20 : 0), 1, menu);
  put('packs', 220, L.packs.top + L.packs.h / 2, 1, menu);
  put('settings', 220, AX ? 921 : 912, 1, menu);

  const from = beadAt(15), k = glide(ramp(o, 0, 1));
  put('tank', mix(from.x, TANK.x, k), mix(from.y, TANK.y, k), mix(NEXTBEAD / TANK.d, 1, k), ramp(o, 0, 0.12));
  put('hud', 220, 150, 1, ease(ramp(t, 9000, 9600)) * (t < 20000 ? 1 : 0));
  const f = touch(t);
  put('touch', f.x, f.y, 1, t < 20000 ? f.a : 0);
}

World.load(['rings-tank', 'rings-lens', 'rings-escapement', 'rings-prism']).then(() => {
  const fonts = ['300 30px UPro', '400 16px UPro', 'italic 300 36px NY', '400 13px UMono', '500 20px UMono', '600 11px UMono'];
  Promise.all(fonts.map(f => document.fonts.load(f))).then(() => {
    build();
    window.DRAWS_AX = true;
    World.start({
      shader: `void main() { o = vec4(0.016, 0.014, 0.027, 1.); }`,
      draw, duration: DUR, shots: SHOTS, fonts,
    });
  });
});
