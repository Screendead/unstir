// Copyright © 2026 Jack Lusher. All rights reserved.
// The Night Sky: the menu is one sky scrolled downwards. The first screen holds the moon (today's daily, its past
// phases the archive), three planets (the packs' covers) and the evening star (the next level); below it each tier is
// a constellation of 27 stars that the player's solves join with threads, then the dark of endless.
//
// Built as the app would have to be: every piece of art is drawn once into a layer (build()), and a frame (seek)
// only places layers: translate, whole-layer scale and opacity. Nothing in seek() draws a path, a gradient or text,
// and nothing changes while the timeline rests.

const W = 440, H = 956;
const q = new URLSearchParams(location.search);
const S = Number(q.get('scale') || 3);
const AX = q.get('ax') === '1', RM = q.get('rm') === '1';
const GLASS = '../../../../build/negative-space/glass/';

const ramp = (t, a, b) => Math.min(1, Math.max(0, (t - a) / (b - a)));
const easeOut = (x) => 1 - Math.pow(1 - x, 3);
const easeInOut = (x) => x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
const mix = (a, b, x) => a + (b - a) * x;

const INK = '241, 240, 238';
const ink = (a) => `rgba(${INK}, ${a})`;
const F = {
  name: (s) => `300 ${s}px UPro`,
  ui: (s) => `400 ${s}px UPro`,
  place: (s) => `italic 300 ${s}px NY`,
  data: (s) => `400 ${s}px UMono`,
};
const k = AX ? 2.2 : 1; // accessibility type: every role grows, nothing else does

function rng(seed) { // mulberry32
  return () => { seed |= 0; seed = seed + 0x6D2B79F5 | 0; let t = Math.imul(seed ^ seed >>> 15, 1 | seed);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; };
}

// ---------------------------------------------------------------- the sky's plan (points, world y grows downwards)
const TIER_TOP = 1040, TIER_H = 1020;
const FIG_Y = 552;                                   // a figure's centre below its tier's top
const tierTop = (i) => TIER_TOP + i * TIER_H;
const tierScroll = (i) => tierTop(i) + 30;           // the scroll that frames tier i
const END_TOP = tierTop(4);
const TOTAL = END_TOP + H;

const TIERS = [
  { id: 'plughole', rgb: '255, 222, 170', solved: 27, notPar: [7, 16, 22], count: '27/27 · 24 at par' },
  { id: 'whirlpool', rgb: '216, 176, 255', solved: 14, notPar: [3, 6, 8, 11, 13], count: '14/27 · 9 at par',
    next: { n: 15, name: 'Waterfall' } },
  { id: 'vortex', rgb: '150, 194, 255', solved: 0, notPar: [], locked: 'opens with every whirlpool level solved' },
  { id: 'maelstrom', rgb: '255, 150, 118', solved: 0, notPar: [], locked: 'opens with every vortex level solved' },
];

// Points spaced `step` apart along a parametric curve p(u), u in 0..1.
function along(p, n, step) {
  const pts = [p(0)]; let last = p(0), acc = 0, prev = p(0);
  for (let i = 1; i <= 20000 && pts.length < n; i++) {
    const c = p(i / 20000);
    acc += Math.hypot(c[0] - prev[0], c[1] - prev[1]); prev = c;
    if (acc >= step) { pts.push(c); acc = 0; last = c; }
  }
  return pts;
}
// plughole: a drop. Twenty stars round its outline from the tip, then seven curling in to the drain at its heart.
function figureDrop() {
  const h = 215, w = 190;
  const outline = (u) => { const t = 0.045 + u * (2 * Math.PI - 0.09); return [w * Math.sin(t) * Math.pow(Math.sin(t / 2), 1.5), -h * Math.cos(t)]; };
  let len = 0, a = outline(0);
  for (let i = 1; i <= 2000; i++) { const b = outline(i / 2000); len += Math.hypot(b[0] - a[0], b[1] - a[1]); a = b; }
  const out = along(outline, 20, len / 20.02);
  return out.concat([[0, -70], [38, -30], [52, 22], [30, 68], [-16, 80], [-46, 44], [-22, 4]]);
}
// whirlpool: one arm winding in. It starts at the left and turns clockwise, so the 15th star hangs at the foot of
// the figure with open sky under it.
function figureSpiral() {
  const R = 154, pitch = 56;
  return along((u) => { const th = u * 16, r = R - pitch * th / (2 * Math.PI), a = th - 0.27; return [-r * Math.cos(a) + 13, -r * Math.sin(a) + 8]; }, 27, 46);
}
// vortex: a funnel seen from the side, its coils narrowing 7, 6, 5, 4, 3, 2.
function figureFunnel() {
  const pts = [];
  [7, 6, 5, 4, 3, 2].forEach((n, i) => {
    const hw = (n - 1) / 2 * 54, sway = 10 * Math.sin(i * 1.05 + 0.4);
    for (let j = 0; j < n; j++) {
      const x = (i % 2 ? 1 : -1) * (-hw + j * 54);
      pts.push([x + sway, -262 + i * 94 + 46 * (1 - (x / (hw + 27)) ** 2)]);
    }
  });
  return pts;
}
// maelstrom: an eye. Three broken rings, their gaps one channel, and the last star at the centre.
function figureEye() {
  const pts = [], gap = -1.05;
  [[14, 170], [8, 110], [4, 54]].forEach(([n, r], i) => {
    const step = 2 * Math.PI / (n + 0.7), dir = i % 2 ? -1 : 1;
    for (let j = 0; j < n; j++) {
      const th = gap + dir * (0.85 * step + j * step);
      pts.push([r * Math.cos(th), r * Math.sin(th)]);
    }
  });
  pts.push([0, 0]);
  return pts;
}
const FIGURES = [figureDrop(), figureSpiral(), figureFunnel(), figureEye()];

// ---------------------------------------------------------------- layers
function layer(w, h, draw, scale = S) {
  const c = document.createElement('canvas');
  c.width = Math.ceil(w * scale); c.height = Math.ceil(h * scale);
  const x = c.getContext('2d'); x.scale(scale, scale);
  draw(x);
  return { c, w, h };
}
function glow(x, cx, cy, r, rgb, a) {
  const g = x.createRadialGradient(cx, cy, 0, cx, cy, r);
  g.addColorStop(0, `rgba(${rgb}, ${a})`); g.addColorStop(0.35, `rgba(${rgb}, ${a * 0.38})`); g.addColorStop(1, `rgba(${rgb}, 0)`);
  x.fillStyle = g; x.beginPath(); x.arc(cx, cy, r, 0, 7); x.fill();
}
function flare(x, cx, cy, len, rgb, a) { // four tapered rays, soft at the tips
  for (let i = 0; i < 4; i++) {
    x.save(); x.translate(cx, cy); x.rotate(i * Math.PI / 2);
    const g = x.createLinearGradient(0, 0, len, 0);
    g.addColorStop(0, `rgba(${rgb}, ${a})`); g.addColorStop(1, `rgba(${rgb}, 0)`);
    x.fillStyle = g; x.beginPath(); x.moveTo(0, -1.1); x.quadraticCurveTo(len * 0.3, -0.5, len, 0); x.quadraticCurveTo(len * 0.3, 0.5, 0, 1.1); x.fill();
    x.restore();
  }
}
function star(x, cx, cy, kind, rgb) {
  if (kind === 'faint') {
    glow(x, cx, cy, 8, rgb, 0.22);
    x.fillStyle = ink(0.55); x.beginPath(); x.arc(cx, cy, 1.8, 0, 7); x.fill();
  } else if (kind === 'solved') {
    glow(x, cx, cy, 11, rgb, 0.55);
    x.fillStyle = '#fff'; x.beginPath(); x.arc(cx, cy, 2.3, 0, 7); x.fill();
  } else if (kind === 'par') {
    glow(x, cx, cy, 22, rgb, 0.7); flare(x, cx, cy, 13, '255, 255, 255', 0.8);
    x.fillStyle = '#fff'; x.beginPath(); x.arc(cx, cy, 3.3, 0, 7); x.fill();
  } else { // next
    glow(x, cx, cy, 54, rgb, 0.6); glow(x, cx, cy, 20, '255, 255, 255', 0.75); flare(x, cx, cy, 40, '255, 255, 255', 0.95);
    x.save(); x.translate(cx, cy); x.rotate(Math.PI / 4); flare(x, 0, 0, 15, '255, 255, 255', 0.6); x.restore();
    x.fillStyle = '#fff'; x.beginPath(); x.arc(cx, cy, 4.6, 0, 7); x.fill();
  }
}
// A thread through pts[i]..pts[i+1] as one span of a Catmull-Rom curve: it bends through the stars, never a ruled line.
function thread(x, pts, i, rgb, a) {
  const p0 = pts[Math.max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[Math.min(pts.length - 1, i + 2)];
  const c1 = [p1[0] + (p2[0] - p0[0]) / 5, p1[1] + (p2[1] - p0[1]) / 5], c2 = [p2[0] - (p3[0] - p1[0]) / 5, p2[1] - (p3[1] - p1[1]) / 5];
  const path = () => { x.beginPath(); x.moveTo(p1[0], p1[1]); x.bezierCurveTo(c1[0], c1[1], c2[0], c2[1], p2[0], p2[1]); };
  x.lineCap = 'round';
  x.strokeStyle = `rgba(${rgb}, ${a * 0.16})`; x.lineWidth = 4; path(); x.stroke();
  x.strokeStyle = `rgba(${rgb}, ${a * 0.62})`; x.lineWidth = 0.9; path(); x.stroke();
}
function numName(x, cx, y, n, name, size, align = 'center', a = 1) {
  x.font = F.data(size * 0.82); const wn = x.measureText(n).width;
  x.font = F.name(size); const wname = x.measureText(name).width;
  const gapW = size * 0.42, total = wn + gapW + wname;
  let left = align === 'center' ? cx - total / 2 : align === 'right' ? cx - total : cx;
  x.textAlign = 'left'; x.textBaseline = 'alphabetic';
  x.font = F.data(size * 0.82); x.fillStyle = ink(0.62 * a); x.fillText(n, left, y);
  x.font = F.name(size); x.fillStyle = ink(a); x.fillText(name, left + wn + gapW, y);
  return total;
}

const L = {}; // every layer, built once
const IM = {};
function loadImages(names) {
  return Promise.all(names.map((n) => new Promise((res) => {
    const im = new Image(); im.onload = () => { IM[n] = im; res(); }; im.onerror = () => res(); im.src = GLASS + n + '.png';
  })));
}

function starField(seed, count, rMin, rMax, bright) {
  return layer(W, H, (x) => {
    const r = rng(seed);
    for (let i = 0; i < count; i++) {
      const px = r() * W, py = r() * H, rad = rMin + (rMax - rMin) * Math.pow(r(), 2.2), a = 0.25 + 0.6 * r();
      const tint = ['255, 255, 255', '255, 236, 214', '214, 226, 255'][Math.floor(r() * 3)];
      for (const dy of [-H, 0, H]) { x.fillStyle = `rgba(${tint}, ${a})`; x.beginPath(); x.arc(px, py + dy, rad, 0, 7); x.fill(); }
    }
    for (const [px, py] of bright) { // a few stars the eye can follow from frame to frame
      glow(x, px, py, 9, '230, 236, 255', 0.5); flare(x, px, py, 7, '255, 255, 255', 0.6);
      x.fillStyle = '#fff'; x.beginPath(); x.arc(px, py, rMax, 0, 7); x.fill();
    }
  });
}

// The sky's colour by depth, one narrow strip stretched over the whole scroll.
function ground() {
  const stops = [
    [0, '#04071a'], [520, '#080d24'], [900, '#0d1a2c'],
    [tierTop(0) + 240, '#10272f'], [tierTop(0) + 760, '#3a2a20'], [tierTop(0) + 1010, '#231426'],
    [tierTop(1) + 300, '#22113f'], [tierTop(1) + 720, '#2b1450'], [tierTop(1) + 1020, '#0e0f33'],
    [tierTop(2) + 420, '#08194c'], [tierTop(2) + 800, '#0a2260'], [tierTop(2) + 1040, '#170a1c'],
    [tierTop(3) + 420, '#3d0f10'], [tierTop(3) + 760, '#4c1410'], [tierTop(3) + 1030, '#0c0304'],
    [END_TOP + 260, '#000000'], [TOTAL, '#000000'],
  ];
  return layer(4, TOTAL / 4, (x) => {
    const g = x.createLinearGradient(0, 0, 0, TOTAL / 4);
    for (const [y, c] of stops) g.addColorStop(y / TOTAL, c);
    x.fillStyle = g; x.fillRect(0, 0, 4, TOTAL / 4);
  }, 1);
}
function nebula(rgb) { // one soft cloud of colour, drawn small and scaled up
  return layer(128, 128, (x) => {
    const g = x.createRadialGradient(64, 64, 0, 64, 64, 64);
    g.addColorStop(0, `rgba(${rgb}, 1)`); g.addColorStop(0.5, `rgba(${rgb}, 0.36)`); g.addColorStop(1, `rgba(${rgb}, 0)`);
    x.fillStyle = g; x.fillRect(0, 0, 128, 128);
  }, 1);
}
// Clouds ride the middle layer (half speed). Each is placed by where it should sit when its tier is framed.
const CLOUD_SPEED = 0.8;
const cloudAt = (scroll, x, y, d, name, a) => ({ x, y: y + CLOUD_SPEED * scroll, d, name, a });
const CLOUDS = [
  cloudAt(0, 110, 250, 520, 'cool', 0.22), cloudAt(0, 340, 800, 460, 'violet', 0.2),
  cloudAt(tierScroll(0), 250, 730, 640, 'amber', 0.3), cloudAt(tierScroll(0), 130, 330, 520, 'teal', 0.24),
  cloudAt(tierScroll(1), 150, 470, 620, 'violet', 0.34), cloudAt(tierScroll(1), 330, 740, 480, 'magenta', 0.2),
  cloudAt(tierScroll(2), 280, 520, 660, 'blue', 0.34), cloudAt(tierScroll(2), 110, 300, 420, 'cyan', 0.14),
  cloudAt(tierScroll(3), 200, 560, 660, 'ember', 0.36), cloudAt(tierScroll(3), 340, 320, 400, 'amber', 0.14),
];

function moon(x, cx, cy, d) {
  glow(x, cx - d * 0.2, cy + d * 0.05, d * 1.25, '255, 240, 214', 0.2);
  const g = x.createRadialGradient(cx - d * 0.2, cy, d * 0.1, cx, cy, d / 2);
  g.addColorStop(0, '#1c2744'); g.addColorStop(1, '#0d142b');
  x.fillStyle = g; x.beginPath(); x.arc(cx, cy, d / 2 - 0.5, 0, 7); x.fill();
  const lit = layer(d + 4, d + 4, (m) => {
    const c = d / 2 + 2;
    const lg = m.createLinearGradient(0, 0, d, d); lg.addColorStop(0, '#fff8e8'); lg.addColorStop(1, '#f0d9ae');
    m.fillStyle = lg; m.beginPath(); m.arc(c, c, d / 2, 0, 7); m.fill();
    m.globalCompositeOperation = 'destination-out';
    m.filter = `blur(${d * 0.012}px)`;
    m.beginPath(); m.arc(c + d * 0.25, c - d * 0.07, d / 2 * 1.03, 0, 7); m.fill();
  });
  x.drawImage(lit.c, cx - d / 2 - 2, cy - d / 2 - 2, d + 4, d + 4);
}
function phase(x, cx, cy, d, kind, a) {
  x.save(); x.globalAlpha = a;
  x.fillStyle = '#141c36'; x.beginPath(); x.arc(cx, cy, d / 2, 0, 7); x.fill();
  x.fillStyle = '#f6e7c6';
  if (kind === 'full') { glow(x, cx, cy, d * 1.5, '255, 236, 200', 0.4); x.fillStyle = '#f6e7c6'; x.beginPath(); x.arc(cx, cy, d / 2, 0, 7); x.fill(); }
  else if (kind === 'half') { x.beginPath(); x.arc(cx, cy, d / 2, Math.PI / 2, -Math.PI / 2); x.ellipse(cx, cy, d * 0.14, d / 2, 0, -Math.PI / 2, Math.PI / 2); x.fill(); }
  else { x.strokeStyle = 'rgba(246, 231, 198, 0.55)'; x.lineWidth = 0.9; x.beginPath(); x.arc(cx, cy, d / 2 - 0.5, 0, 7); x.stroke(); }
  x.restore();
}
function planet(x, name, cx, cy, d, rgb) {
  glow(x, cx, cy, d * 0.95, rgb, 0.3);
  x.save(); x.beginPath(); x.arc(cx, cy, d / 2, 0, 7); x.clip();
  if (IM[name]) x.drawImage(IM[name], cx - d / 2 - d * 0.004, cy - d / 2 - d * 0.004, d * 1.008, d * 1.008);
  const g = x.createRadialGradient(cx - d * 0.1, cy - d * 0.12, d * 0.4, cx, cy, d * 0.56); // a little limb shade: a globe, the cover untouched
  g.addColorStop(0, 'rgba(0, 0, 0, 0)'); g.addColorStop(1, 'rgba(2, 4, 16, 0.3)');
  x.fillStyle = g; x.fillRect(cx - d / 2, cy - d / 2, d, d);
  x.restore();
}
function circleThrough(a, b, c) {
  const d = 2 * (a[0] * (b[1] - c[1]) + b[0] * (c[1] - a[1]) + c[0] * (a[1] - b[1]));
  const s = (p) => p[0] * p[0] + p[1] * p[1];
  const ux = (s(a) * (b[1] - c[1]) + s(b) * (c[1] - a[1]) + s(c) * (a[1] - b[1])) / d;
  const uy = (s(a) * (c[0] - b[0]) + s(b) * (a[0] - c[0]) + s(c) * (b[0] - a[0])) / d;
  return { x: ux, y: uy, r: Math.hypot(a[0] - ux, a[1] - uy) };
}
// Text set along a circle, centred on angle mid, reading left to right. up: 1 when the circle's centre lies above
// the text, -1 when below.
function curveText(x, text, c, r, mid, up) {
  const chars = [...text], widths = chars.map((ch) => x.measureText(ch).width);
  let phi = mid + up * widths.reduce((s, w) => s + w, 0) / r / 2;
  x.textAlign = 'center';
  chars.forEach((ch, i) => {
    const p = phi - up * widths[i] / r / 2;
    x.save(); x.translate(c.x + r * Math.cos(p), c.y + r * Math.sin(p)); x.rotate(p - up * Math.PI / 2); x.fillText(ch, 0, 0); x.restore();
    phi -= up * widths[i] / r;
  });
}
function settingsMark(x, cx, cy) { // a small orbit: quiet, and nothing like a button
  x.strokeStyle = ink(0.5); x.lineWidth = 1.1;
  x.beginPath(); x.ellipse(cx, cy, 11, 5, -0.5, 0, 7); x.stroke();
  x.fillStyle = ink(0.8); x.beginPath(); x.arc(cx, cy, 2.4, 0, 7); x.fill();
  x.beginPath(); x.arc(cx + 9.2, cy - 5.6, 1.5, 0, 7); x.fill();
}
function check(x, cx, cy, s) {
  x.strokeStyle = 'rgba(150, 255, 190, 0.9)'; x.lineWidth = s * 0.11; x.lineCap = 'round'; x.lineJoin = 'round';
  x.beginPath(); x.moveTo(cx, cy - s * 0.28); x.quadraticCurveTo(cx + s * 0.12, cy - s * 0.12, cx + s * 0.2, cy); x.quadraticCurveTo(cx + s * 0.4, cy - s * 0.5, cx + s * 0.62, cy - s * 0.62); x.stroke();
}

// The first screen. Its three groups turn about the screen's centre: moon high on the left with its words to the
// right, the evening star low on the right with its words to the left, and the planets' orbit crossing between.
const HOME = AX ? {
  moon: [76, 214, 88], daily: [136, 206], streak: [36, 304], archive: [36, 352], arc: null,
  planets: [[78, 640], [220, 618], [362, 600]], pd: 100,
  star: [62, 444], next: [112, 438], place: [112, 484],
} : {
  moon: [116, 272, 124], daily: [212, 254], streak: [212, 279], archive: [212, 346], arc: [214, 312, 172],
  planets: [[84, 606], [220, 560], [356, 544]], pd: 114,
  star: [334, 802], next: [268, 810], place: [268, 778], sub: [268, 836],
};
const PACKS = [
  { id: 'sky-lens', name: 'Lens', state: '', owned: true, rgb: '255, 96, 214' },
  { id: 'sky-escapement', name: 'Escapement', state: '2/3 free', rgb: '255, 176, 130' },
  { id: 'sky-prism', name: 'Prism', state: '1/3 free', rgb: '170, 224, 255' },
];

function buildHome() {
  const P = HOME;
  L.homeMoon = layer(W, H, (x) => {
    moon(x, P.moon[0], P.moon[1], P.moon[2]);
    if (P.arc) { // the archive: the moon's last phases trailing off along its path
      const kinds = ['full', 'half', 'full', 'ring', 'half', 'full', 'half'];
      kinds.forEach((kd, i) => { const u = i / 6; phase(x, P.arc[0] + 6 + u * (P.arc[2] - 12), P.arc[1] - 9 * Math.sin(u * Math.PI), 11, kd, 0.95 - 0.5 * u); });
    }
  });
  L.homeText = layer(W, H, (x) => {
    x.textBaseline = 'alphabetic';
    x.font = F.name(24); x.letterSpacing = '11px'; x.fillStyle = ink(0.96); x.textAlign = 'left';
    x.fillText('UNSTIR', 36, 112); x.letterSpacing = '0px';
    settingsMark(x, 396, 104);
    x.fillStyle = ink(1);
    if (AX) {
      x.font = F.name(22 * 1.82); x.fillText('Daily', P.daily[0], P.daily[1]); x.fillText('Fri 27 Nov', P.daily[0], P.daily[1] + 46);
      x.font = F.data(13 * k); x.fillStyle = ink(0.66); x.fillText('4 days running', P.streak[0], P.streak[1]);
      x.font = F.ui(15 * 2); x.fillStyle = ink(0.66); x.fillText('30 past dailies', P.archive[0] + 40, P.archive[1]);
      phase(x, P.archive[0] + 14, P.archive[1] - 10, 22, 'half', 0.9);
      numName(x, P.next[0], P.next[1], '15', 'Waterfall', 22 * 1.82, 'left');
      x.font = F.place(17 * 2); x.fillStyle = `rgba(${TIERS[1].rgb}, 0.9)`; x.fillText('whirlpool', P.place[0], P.place[1]);
    } else {
      x.font = F.name(22); x.fillText('Daily · Fri 27 Nov', P.daily[0], P.daily[1]);
      x.font = F.data(13); x.fillStyle = ink(0.6); x.fillText('4 days running', P.streak[0], P.streak[1]);
      x.font = F.ui(15); x.fillStyle = ink(0.6); x.fillText('30 past dailies', P.archive[0], P.archive[1]);
      x.textAlign = 'right';
      x.font = F.place(19); x.fillStyle = `rgba(${TIERS[1].rgb}, 0.92)`; x.fillText('whirlpool', P.place[0], P.place[1]);
      numName(x, P.next[0], P.next[1], '15', 'Waterfall', 28, 'right');
      x.textAlign = 'right'; x.font = F.data(13); x.fillStyle = ink(0.6); x.fillText('14 of 27 joined', P.sub[0], P.sub[1]);
    }
  });
  // The evening star, with the first two stars of a thread running on below the screen: there is more sky down there.
  L.homeStar = layer(W, H, (x) => {
    const [sx, sy] = P.star, rgb = TIERS[1].rgb;
    if (!AX) {
      const trail = [[sx, sy], [sx - 22, sy + 78], [sx - 78, sy + 142], [sx - 150, sy + 200]];
      thread(x, trail, 0, rgb, 0.7); thread(x, trail, 1, rgb, 0.45); thread(x, trail, 2, rgb, 0.3);
      star(x, trail[1][0], trail[1][1], 'faint', rgb); star(x, trail[2][0], trail[2][1], 'faint', rgb);
    }
    star(x, sx, sy, 'next', rgb);
  });
  L.homePlanets = layer(W, H, (x) => {
    const c = circleThrough(...P.planets), d = P.pd;
    const ang = (p) => Math.atan2(p[1] - c.y, p[0] - c.x);
    x.strokeStyle = ink(0.13); x.lineWidth = 0.9; // the orbit they share
    const a0 = ang([-40, P.planets[0][1] + 12]), a1 = ang([W + 40, P.planets[2][1] - 8]);
    x.beginPath(); x.arc(c.x, c.y, c.r, Math.min(a0, a1), Math.max(a0, a1)); x.stroke();
    PACKS.forEach((p, i) => planet(x, p.id, P.planets[i][0], P.planets[i][1], d, p.rgb));
    x.textBaseline = 'alphabetic';
    if (AX) { // names keep their size and step down under their own planets, each on a short thread
      const size = 15 * k, rows = [[36, 840, 'left'], [404, 778, 'right'], [404, 716, 'right']];
      PACKS.forEach((p, i) => {
        const [tx, ty, al] = rows[i], [px, py] = P.planets[i];
        const y0 = py + d / 2 + 8, y1 = ty - size + 2;
        x.strokeStyle = ink(0.24); x.lineWidth = 0.9; x.beginPath(); x.moveTo(px, y0);
        x.quadraticCurveTo(px - 16, (y0 + y1) / 2, px - 6, y1); if (y1 - y0 > 20) x.stroke();
        x.font = F.name(size); x.textAlign = al; x.fillStyle = ink(1);
        const label = p.owned ? p.name : `${p.name} · ${p.state}`;
        x.fillText(label, tx, ty);
        if (p.owned) check(x, tx + x.measureText(label).width + 10, ty - 2, size);
      });
      x.font = F.place(13 * k); x.textAlign = 'center'; x.fillStyle = ink(0.62);
      x.fillText('packs · first 3 levels', 220, 888); x.fillText('of each free', 220, 921);
    } else {
      PACKS.forEach((p, i) => {
        const [px, py] = P.planets[i];
        x.font = F.name(17); x.textAlign = 'center'; x.fillStyle = ink(1);
        const w = x.measureText(p.name).width;
        x.fillText(p.name, px - (p.owned ? 8 : 0), py + d / 2 + 28);
        if (p.owned) check(x, px - 8 + w / 2 + 6, py + d / 2 + 27, 17);
        x.font = F.data(13); x.fillStyle = ink(0.6); x.fillText(p.state, px, py + d / 2 + 48);
      });
      x.font = F.place(15); x.fillStyle = ink(0.62);
      const up = c.y < P.planets[1][1] ? 1 : -1;
      curveText(x, 'packs · first 3 levels of each free', c, c.r - up * (d / 2 + 22), ang(P.planets[1]), up);
    }
  });
}

function buildTier(i) {
  const T = TIERS[i], pts = FIGURES[i].map(([px, py]) => [220 + px, FIG_Y + py]);
  const cen = pts.reduce((s, p) => [s[0] + p[0] / pts.length, s[1] + p[1] / pts.length], [0, 0]);
  return layer(W, TIER_H, (x) => {
    x.textAlign = 'center'; x.textBaseline = 'alphabetic';
    x.font = F.place(46); x.fillStyle = T.locked ? `rgba(${T.rgb}, 0.6)` : `rgba(${T.rgb}, 1)`;
    x.fillText(T.id, 220, 152);
    if (T.locked) { x.font = F.ui(15); x.fillStyle = ink(0.62); x.fillText(T.locked, 220, 184); }
    else { x.font = F.data(13); x.fillStyle = ink(0.62); x.fillText(T.count, 220, 182); }
    const lit = T.solved;
    for (let n = 0; n < lit - 1; n++) thread(x, pts, n, T.rgb, 1);
    if (T.next) thread(x, pts, lit - 1, T.rgb, 0.45); // the thread being drawn, reaching for the next star
    pts.forEach(([px, py], n) => {
      const num = n + 1, isNext = T.next && T.next.n === num;
      const kind = isNext ? 'next' : num > lit ? 'faint' : T.notPar.includes(num) ? 'solved' : 'par';
      star(x, px, py, kind, T.rgb);
      if (isNext || T.locked) return;
      // Its number, set on the side away from its neighbours, as a star atlas letters its stars.
      const a = pts[Math.max(0, n - 1)], b = pts[Math.min(pts.length - 1, n + 1)];
      let nx = -(b[1] - a[1]), ny = b[0] - a[0]; const ln = Math.hypot(nx, ny) || 1; nx /= ln; ny /= ln;
      let best = null;
      for (const sgn of [1, -1]) {
        const qx = px + sgn * nx * 17, qy = py + sgn * ny * 17;
        const clear = Math.min(...pts.filter((_, m) => m !== n).map((o) => Math.hypot(o[0] - qx, o[1] - qy)));
        const out = Math.hypot(qx - cen[0], qy - cen[1]);
        const score = Math.min(clear, 40) + out * 0.02;
        if (!best || score > best.score) best = { qx, qy, score };
      }
      x.font = F.data(13); x.textAlign = 'center'; x.fillStyle = ink(num > lit ? 0.34 : 0.62);
      x.fillText(String(num).padStart(2, '0'), best.qx, best.qy + 4.5);
    });
    if (T.next) { const p = pts[T.next.n - 1]; numName(x, p[0], p[1] + 62, String(T.next.n), T.next.name, 24); }
  });
}

function buildAll() {
  L.ground = ground();
  L.far = starField(11, 170, 0.35, 0.95, []);
  L.mid = starField(29, 46, 0.6, 1.5, [[352, 448], [408, 470], [30, 566]]);
  L.cloud = { cool: nebula('60, 96, 190'), violet: nebula('150, 80, 230'), magenta: nebula('230, 70, 190'), amber: nebula('255, 150, 70'),
    teal: nebula('40, 190, 170'), blue: nebula('40, 100, 255'), cyan: nebula('70, 210, 255'), ember: nebula('255, 60, 40') };
  buildHome();
  L.tiers = TIERS.map((_, i) => buildTier(i));
  L.endless = layer(W, H, (x) => {
    x.textAlign = 'center';
    x.font = F.place(46); x.fillStyle = ink(0.95); x.fillText('endless', 220, 330);
    x.font = F.data(13); x.fillStyle = ink(0.62); x.fillText('tank 6 · brim 3 · best 9', 220, 362);
    x.font = F.name(24); x.fillStyle = ink(1); x.fillText('continue', 220, 450);
    x.fillStyle = ink(0.7); x.fillText('new run', 220, 500);
  });
  L.status = layer(W, 50, (x) => { if (IM['sky-status']) x.drawImage(IM['sky-status'], 0, 0, W, 50); });
  L.tank = layer(404, 404, (x) => {
    x.beginPath(); x.arc(202, 202, 201, 0, 7); x.clip();
    if (IM['sky-tank']) x.drawImage(IM['sky-tank'], -1, -1, 406, 406);
  });
  L.play = layer(W, 220, (x) => {
    numName(x, 220, 150, '15', 'Waterfall', 28);
    x.font = F.data(13); x.textAlign = 'center'; x.fillStyle = ink(0.6); x.fillText('moves 0 · par 8', 220, 178);
  });
  L.tap = layer(60, 60, (x) => { glow(x, 30, 30, 30, '255, 255, 255', 0.55); });
}

// ---------------------------------------------------------------- the timeline
// 0      launch at rest
// 1.5    a flick: the sky slides up to plughole, whole
// 4.4    a second flick: on to whirlpool, half drawn
// 7.9    a tap on the 15th star; the tank grows from it
// 9.7    the level, at rest
const DUR = 11200;
const SHOTS = RM ? {} : AX ? { launch: 0 } : { launch: 0, whirlpool: 7200, locked: 20000, plughole: 21000 };
const NEXT_PT = FIGURES[1][14];
const NEXT_SCREEN = [220 + NEXT_PT[0], tierTop(1) + FIG_Y + NEXT_PT[1] - tierScroll(1)];
const TANK = { x: 220, y: 500, d: 404 };

function scrollAt(t) {
  if (t >= 21000) return tierScroll(0);
  if (t >= 20000) return tierScroll(2);
  if (t < 4400) return mix(0, tierScroll(0), easeInOut(ramp(t, 1500, 3800)));
  return mix(tierScroll(0), tierScroll(1), easeInOut(ramp(t, 4400, 6800)));
}

let ctx;
function put(l, x, y, a = 1, w = l.w, h = l.h) {
  if (a <= 0 || y > H || y + h < 0) return;
  ctx.globalAlpha = a; ctx.drawImage(l.c, x, y, w, h);
}
function seek(t) {
  const sc = scrollAt(t);
  const film = t < 20000;
  const grow = film ? easeInOut(ramp(t, 8000, 9700)) : 0;
  ctx.setTransform(S, 0, 0, S, 0, 0);
  ctx.globalAlpha = 1; ctx.globalCompositeOperation = 'source-over';
  ctx.fillStyle = '#000'; ctx.fillRect(0, 0, W, H);

  // The sky: as the tank grows the whole of it swells a little about the tapped star and goes dark.
  const z = 1 + 0.35 * grow, skyA = 1 - ramp(grow, 0.15, 0.85);
  ctx.translate(NEXT_SCREEN[0], NEXT_SCREEN[1]); ctx.scale(z, z); ctx.translate(-NEXT_SCREEN[0], -NEXT_SCREEN[1]);
  put(L.ground, 0, -sc, skyA, W, TOTAL);
  for (const [l, sp] of [[L.far, 0.28]]) { const off = -((sc * sp) % H); put(l, 0, off, skyA); put(l, 0, off + H, skyA); }
  ctx.globalCompositeOperation = 'lighter';
  for (const c of CLOUDS) put(L.cloud[c.name], c.x - c.d / 2, c.y - c.d / 2 - sc * CLOUD_SPEED, c.a * skyA, c.d, c.d);
  ctx.globalCompositeOperation = 'source-over';
  { const off = -((sc * 0.58) % H); put(L.mid, 0, off, skyA); put(L.mid, 0, off + H, skyA); }
  put(L.homeMoon, 0, -sc * 0.82, skyA);
  put(L.homeText, 0, -sc, skyA);
  put(L.homeStar, 0, -sc, skyA);
  put(L.homePlanets, 0, -sc * 1.14, skyA);
  L.tiers.forEach((l, i) => put(l, 0, tierTop(i) - sc, skyA));
  put(L.endless, 0, END_TOP - sc, skyA);
  ctx.setTransform(S, 0, 0, S, 0, 0);

  if (film && t >= 7700) {
    const press = ramp(t, 7700, 7900) * (1 - ramp(t, 7950, 8300));
    put(L.tap, NEXT_SCREEN[0] - 30, NEXT_SCREEN[1] - 30, press);
    if (grow > 0) {
      const d = mix(10, TANK.d, grow), cx = mix(NEXT_SCREEN[0], TANK.x, grow), cy = mix(NEXT_SCREEN[1], TANK.y, grow);
      put(L.tank, cx - d / 2, cy - d / 2, ramp(grow, 0, 0.12), d, d);
      put(L.play, 0, 0, ramp(grow, 0.7, 1));
    }
  }
  ctx.globalCompositeOperation = 'lighter';
  put(L.status, 0, 0, 1);
  ctx.globalCompositeOperation = 'source-over';
  ctx.globalAlpha = 1;
}

(async function start() {
  Object.assign(document.body.style, { margin: 0, width: W + 'px', height: H + 'px', overflow: 'hidden', background: '#000' });
  const c = document.createElement('canvas');
  c.width = W * S; c.height = H * S;
  Object.assign(c.style, { position: 'absolute', left: 0, top: 0, width: W + 'px', height: H + 'px' });
  document.body.appendChild(c);
  ctx = c.getContext('2d');
  await Promise.all(['300 20px UPro', '400 20px UPro', 'italic 300 20px NY', '400 20px UMono'].map((f) => document.fonts.load(f)));
  await document.fonts.ready;
  await loadImages(['sky-lens', 'sky-escapement', 'sky-prism', 'sky-tank', 'sky-status']);
  buildAll();
  window.seek = seek; window.DURATION = DUR; window.SHOTS = SHOTS; window.DRAWS_AX = true;
  seek(0);
  document.body.dataset.ready = '1';
})();
