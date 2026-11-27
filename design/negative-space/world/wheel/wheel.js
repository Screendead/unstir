// Copyright © 2026 Jack Lusher. All rights reserved.
// The wheel: the whole game as one emblem. Four concentric bands of 27 enamel cells, plughole outermost and maelstrom
// innermost, endless the dark centre. Each band is turned so its next level rests at the index under the emblem, so
// a zoom into a band is a scale and a slide, never a turn. Built as the app must build it: every piece of art is
// drawn once into a layer below, and seek(t) only places those layers (translate, scale, a rigid turn, opacity).
// Nothing is drawn per frame and nothing moves at rest.

const W = 440, H = 956;
const q = new URLSearchParams(location.search);
const S = Number(q.get('scale') || 3);
const AX = q.get('ax') === '1';
const GLASS = '../../../../build/negative-space/glass/';
const TAU = Math.PI * 2, STEP = TAU / 27;

const ramp = (t, a, b) => Math.min(1, Math.max(0, (t - a) / (b - a)));
const smooth = (x) => x * x * (3 - 2 * x);
const ease = (x) => 1 - Math.pow(1 - x, 3);
const mix = (a, b, x) => a + (b - a) * x;

const WHIRLPOOL = ['Spring', 'Headwaters', 'Creek', 'Brook', 'Stream', 'Shallows', 'Stepping stone', 'Riverbend',
  'Millpond', 'Dam', 'Floodgate', 'Water wheel', 'Rapids', 'Cascade', 'Waterfall', 'Plunge pool', 'Ravine', 'Canyon',
  'Meander', 'Sandbank', 'Wetland', 'Eddy', 'Tributary', 'Watershed', 'Floodplain', 'Salt marsh', 'Estuary'];

// A mid-game player: plughole done, whirlpool 14 of 27, the rest locked. `next` is the cell at the index.
const TIERS = [
  { name: 'plughole', from: [244, 208, 140], to: [58, 190, 172], r0: 148, r1: 176, solved: 27, next: 0,
    notPar: [6, 11, 19] },
  { name: 'whirlpool', from: [214, 128, 255], to: [112, 92, 255], r0: 115, r1: 143, solved: 14, next: 14,
    notPar: [3, 7, 8, 10, 12] },
  { name: 'vortex', from: [52, 104, 255], to: [58, 196, 255], r0: 82, r1: 110, solved: 0, next: 0, locked: true },
  { name: 'maelstrom', from: [255, 64, 72], to: [255, 132, 64], r0: 49, r1: 77, solved: 0, next: 0, locked: true },
];
const R = 176, CORE = 42, GAP = 4.5;
const Z = 2.75;                      // the zoom into a band
const GROUND = [11, 16, 27];           // dark glass is mixed with the ground, so a cell's fill and edge are one tone
const rgb = (c, a = 1) => `rgba(${c[0] | 0},${c[1] | 0},${c[2] | 0},${a})`;
const hue = (tier, i) => tier.from.map((v, k) => mix(v, tier.to[k], i / 26));
const lighten = (c, x) => c.map(v => mix(v, 255, x));

// Angles run from the index at the bottom of the emblem, positive to the right, so numbers read left to right.
const at = (r, th) => [r * Math.sin(th), r * Math.cos(th)];
const phi = (th) => Math.PI / 2 - th;

function layer(w, h, draw) {
  const c = document.createElement('canvas');
  c.width = Math.ceil(w * S); c.height = Math.ceil(h * S);
  const ctx = c.getContext('2d');
  ctx.scale(S, S);
  draw(ctx);
  return { c, w, h };
}
function put(ctx, L, cx, cy, { scale = 1, alpha = 1, turn = 0, ax = 0.5, ay = 0.5 } = {}) {
  if (alpha <= 0.002) return;
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.translate(cx, cy);
  if (turn) ctx.rotate(turn);
  ctx.scale(scale, scale);
  ctx.drawImage(L.c, -L.w * ax, -L.h * ay, L.w, L.h);
  ctx.restore();
}

// One enamel cell: an annular sector with soft corners, its gaps parallel-sided.
function cellPath(ctx, r0, r1, th, z) {
  const c = 2.6 * z, g = GAP * z / 2 + c;
  const a0 = th - STEP / 2, a1 = th + STEP / 2;
  const ro = r1 * z - c, ri = r0 * z + c;
  ctx.beginPath();
  ctx.arc(0, 0, ro, phi(a0 + g / ro), phi(a1 - g / ro), true);
  ctx.arc(0, 0, ri, phi(a1 - g / ri), phi(a0 + g / ri), false);
  ctx.closePath();
  return c;
}
function cell(ctx, tier, i, z, style) {
  const th = (i - tier.next) * STEP;
  const c = cellPath(ctx, tier.r0, tier.r1, th, z);
  ctx.lineJoin = 'round';
  const col = hue(tier, i);
  if (style === 'lit' || style === 'par') {
    const g = ctx.createRadialGradient(0, 0, tier.r0 * z, 0, 0, tier.r1 * z);
    const k = style === 'par' ? 1 : 0.66;
    g.addColorStop(0, rgb(col.map(v => v * 0.62 * k)));
    g.addColorStop(0.7, rgb(col.map(v => v * k)));
    g.addColorStop(1, rgb(lighten(col, 0.3).map(v => v * mix(0.62, 1, k))));
    ctx.fillStyle = g; ctx.strokeStyle = g; ctx.lineWidth = 2 * c;
    ctx.fill(); ctx.stroke();
    // enamel: a thin light along the outer edge, and at par a bright pip set into the cell
    if (z > 1) return;
    const e = (GAP * z / 2 + 3 * z) / (tier.r1 * z);
    ctx.beginPath(); ctx.arc(0, 0, tier.r1 * z - 2.2 * z, phi(th - STEP / 2 + e), phi(th + STEP / 2 - e), true);
    ctx.lineWidth = 0.9 * z; ctx.lineCap = 'round'; ctx.strokeStyle = `rgba(255,255,255,${0.42 * k})`; ctx.stroke();
    if (style === 'par') {
      const [x, y] = at(tier.r0 + 6.5, th);
      ctx.beginPath(); ctx.arc(x, y, 1.5, 0, TAU); ctx.fillStyle = 'rgba(255,255,255,0.9)'; ctx.fill();
    }
  } else if (style === 'glow') {
    ctx.fillStyle = ctx.strokeStyle = rgb(col); ctx.lineWidth = 2 * c; ctx.fill(); ctx.stroke();
  } else {
    // dark glass: an edge and a fill of one outline, each mixed with the ground so they never double up
    const a = style === 'locked' ? 0.72 : 1, w = style === 'next' ? 1.3 * Math.sqrt(z) : Math.max(0.75, 0.4 * z);
    const tone = (x) => rgb(col.map((v, n) => mix(GROUND[n], v, x)));
    ctx.fillStyle = ctx.strokeStyle = style === 'next' ? '#fff' : tone(0.36 * a); ctx.lineWidth = 2 * c;
    ctx.fill(); ctx.stroke();
    ctx.fillStyle = ctx.strokeStyle = tone(style === 'next' ? 0.16 : 0.1 * a); ctx.lineWidth = 2 * (c - w);
    ctx.fill(); ctx.stroke();
  }
}
const styleOf = (tier, i) => tier.locked ? 'locked' : i < tier.solved ? (tier.notPar.includes(i) ? 'lit' : 'par')
  : i === tier.next && tier.solved < 27 ? 'next' : 'open';

function bandCells(ctx, tier, z, only) {
  for (let i = 0; i < 27; i++) { const s = styleOf(tier, i); if (!only || only(s, i)) cell(ctx, tier, i, z, s); }
}
function glowOf(side, z, blur, alpha, paint) {
  const raw = layer(side, side, (c) => { c.translate(side / 2, side / 2); paint(c); });
  return (ctx) => {
    ctx.save(); ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.filter = `blur(${blur * S}px)`; ctx.globalAlpha = alpha; ctx.globalCompositeOperation = 'lighter';
    ctx.drawImage(raw.c, 0, 0);
    ctx.restore();
  };
}

const L = {};
const IMG = {};
function build() {
  L.ground = layer(W, H, (c) => {
    const g = c.createRadialGradient(W / 2, 400, 40, W / 2, 440, 620);
    g.addColorStop(0, '#111827'); g.addColorStop(0.45, '#0a0f19'); g.addColorStop(1, '#04060a');
    c.fillStyle = g; c.fillRect(0, 0, W, H);
  });

  // The emblem at rest: every band, the lit cells' light, the dark centre and its one point.
  const side = 2 * R + 80;
  L.emblem = layer(side, side, (c) => {
    glowOf(side, 1, 9, 0.5, (g) => TIERS.forEach(t => {
      for (let i = 0; i < t.solved; i++) cell(g, t, i, 1, 'glow');
    }))(c);
    c.translate(side / 2, side / 2);
    c.beginPath(); c.arc(0, 0, R + 9, 0, TAU);
    c.lineWidth = 0.75; c.strokeStyle = 'rgba(214,196,160,0.22)'; c.stroke();
    TIERS.forEach(t => bandCells(c, t, 1));
    const sheen = c.createLinearGradient(-R, -R, R, R);           // one light, from the upper left, on the enamel
    sheen.addColorStop(0, 'rgba(255,255,255,0.16)'); sheen.addColorStop(0.5, 'rgba(255,255,255,0)');
    sheen.addColorStop(1, 'rgba(0,0,10,0.28)');
    c.globalCompositeOperation = 'source-atop'; c.fillStyle = sheen; c.fillRect(-R, -R, 2 * R, 2 * R);
    c.globalCompositeOperation = 'source-over';
    const core = c.createRadialGradient(0, 0, 0, 0, 0, CORE);
    core.addColorStop(0, '#000'); core.addColorStop(0.8, '#020305'); core.addColorStop(1, 'rgba(2,3,5,0)');
    c.fillStyle = core; c.beginPath(); c.arc(0, 0, CORE, 0, TAU); c.fill();
    const pt = c.createRadialGradient(0, -8, 0, 0, -8, 9);
    pt.addColorStop(0, 'rgba(255,255,255,1)'); pt.addColorStop(0.22, 'rgba(255,255,255,0.9)');
    pt.addColorStop(0.3, 'rgba(190,220,255,0.25)'); pt.addColorStop(1, 'rgba(190,220,255,0)');
    c.fillStyle = pt; c.fillRect(-10, -18, 20, 20);
    if (AX) return;                       // drawn smaller there, so the word leaves the emblem for the page below
    c.font = 'italic 300 15px NY'; c.textAlign = 'center'; c.fillStyle = 'rgba(255,255,255,0.7)';
    c.fillText('endless', 0, 17);
  });
  // The index under the emblem: a small brass drop.
  L.index = layer(20, 20, (c) => {
    c.translate(10, 10); c.beginPath();
    c.moveTo(0, -5.5); c.quadraticCurveTo(4.6, 0, 0, 5.5); c.quadraticCurveTo(-4.6, 0, 0, -5.5);
    c.fillStyle = 'rgba(232,212,170,0.9)'; c.fill();
  });

  // A locked band answering a touch: its own light, and the cells still to solve in the band before it.
  L.lockedGlow = layer(side, side, (c) => {
    glowOf(side, 1, 7, 0.55, (g) => { for (let i = 0; i < 27; i++) cell(g, TIERS[2], i, 1, 'glow'); })(c);
    c.translate(side / 2, side / 2);
    for (let i = 0; i < 27; i++) {
      cellPath(c, TIERS[2].r0 - 2.2, TIERS[2].r1 + 2.2, i * STEP, 1);
      c.lineWidth = 1; c.strokeStyle = rgb(lighten(hue(TIERS[2], i), 0.35), 0.8); c.stroke();
    }
    for (let i = 15; i < 27; i++) {
      cellPath(c, TIERS[1].r0 - 2.2, TIERS[1].r1 + 2.2, (i - 14) * STEP, 1);
      c.lineWidth = 1; c.strokeStyle = rgb(lighten(hue(TIERS[1], i), 0.4), 0.85); c.stroke();
    }
  });

  // Whirlpool's band drawn sharp at the zoom: cells, numbers, marks and names turn together as one ring.
  const tier = TIERS[1];
  const far = tier.r1 * Z + 64, cs = 2 * far;
  L.close = layer(cs, cs, (c) => {
    glowOf(cs, Z, 16, 0.42, (g) => { for (let i = 0; i < tier.solved; i++) cell(g, tier, i, Z, 'glow'); })(c);
    c.translate(cs / 2, cs / 2);
    bandCells(c, tier, Z);
    const rm = (tier.r0 + tier.r1) / 2 * Z;
    for (let i = 0; i < 27; i++) {
      const th = (i - tier.next) * STEP, s = styleOf(tier, i), done = s === 'lit' || s === 'par';
      c.save();
      c.rotate(-th);
      c.textAlign = 'center';
      c.font = '300 26px UPro';
      c.fillStyle = done ? 'rgba(18,10,40,0.86)' : s === 'next' ? '#fff' : 'rgba(255,255,255,0.62)';
      c.fillText(String(i + 1).padStart(2, '0'), 0, rm + 5);
      if (done) for (const [k, x] of [[0, -6], [1, 6]]) {       // one dot solved, two at par
        c.beginPath(); c.arc(x, rm + 21, 2.4, 0, TAU);
        if (k === 0 || s === 'par') { c.fillStyle = 'rgba(18,10,40,0.8)'; c.fill(); }
        else { c.lineWidth = 1; c.strokeStyle = 'rgba(18,10,40,0.6)'; c.stroke(); }
      }
      c.font = (s === 'next' ? '400' : '300') + ' 17px UPro';
      c.fillStyle = s === 'next' ? '#fff' : done ? 'rgba(255,255,255,0.86)' : 'rgba(255,255,255,0.5)';
      c.fillText(WHIRLPOOL[i], 0, tier.r1 * Z + 34);
      c.restore();
    }
  });
  // Vortex above it, a ghost: where the band sits in the whole.
  const gs = 2 * TIERS[2].r1 * Z + 20;
  L.ghost = layer(gs, gs, (c) => { c.translate(gs / 2, gs / 2); bandCells(c, TIERS[2], Z); });

  // The far side of the zoomed ring is kept off the band's screen by the ground itself, drawn once more over it.
  L.veil = layer(W, 560, (c) => {
    c.drawImage(L.ground.c, 0, 0, W, H);
    const m = c.createLinearGradient(0, 0, 0, 560);
    m.addColorStop(0, '#000'); m.addColorStop(0.6, '#000'); m.addColorStop(1, 'rgba(0,0,0,0)');
    c.globalCompositeOperation = 'destination-in'; c.fillStyle = m; c.fillRect(0, 0, W, 560);
  });

  L.status = layer(W, 54, (c) => c.drawImage(IMG.status, 0, 0, W, 54));
  L.touch = layer(64, 64, (c) => {
    const g = c.createRadialGradient(32, 32, 0, 32, 32, 30);
    g.addColorStop(0, 'rgba(255,255,255,0.5)'); g.addColorStop(0.7, 'rgba(255,255,255,0.28)');
    g.addColorStop(1, 'rgba(255,255,255,0)');
    c.fillStyle = g; c.fillRect(0, 0, 64, 64);
  });

  const text = (w, h, draw) => layer(w, h, (c) => { c.textAlign = 'center'; c.textBaseline = 'alphabetic'; draw(c); });
  const spaced = (c, s, x, y, gap) => {
    const ws = [...s].map(ch => c.measureText(ch).width), total = ws.reduce((a, b) => a + b, 0) + gap * (s.length - 1);
    let p = x - total / 2;
    c.textAlign = 'left';
    [...s].forEach((ch, i) => { c.fillText(ch, p, y); p += ws[i] + gap; });
    c.textAlign = 'center';
  };
  const tick = (c, x, y, k = 1) => {
    c.beginPath(); c.moveTo(x - 5 * k, y - 4 * k); c.lineTo(x - 1.5 * k, y); c.lineTo(x + 5.5 * k, y - 10 * k);
    c.lineWidth = 1.6 * k; c.lineCap = c.lineJoin = 'round'; c.strokeStyle = '#7fe0b8'; c.stroke();
  };
  const purple = rgb(lighten(hue(TIERS[1], 14), 0.25));

  if (!AX) {
    L.top = text(W, 230, (c) => {
        c.font = '250 30px UPro'; c.fillStyle = '#fff'; spaced(c, 'UNSTIR', W / 2, 108, 13);
      c.textAlign = 'left';
      c.font = 'italic 300 22px NY'; c.fillStyle = 'rgba(255,255,255,0.95)'; c.fillText('today', 30, 162);
      const tw = c.measureText('today').width;
      c.beginPath(); c.arc(30 + tw + 12, 156, 3.6, 0, TAU);       // unplayed: a hollow mark
      c.lineWidth = 1.2; c.strokeStyle = 'rgba(244,208,140,0.95)'; c.stroke();
      c.font = '300 17px UPro'; c.fillStyle = 'rgba(255,255,255,0.86)'; c.fillText('Daily · Fri 27 Nov', 30, 186);
      c.font = '400 13px UMono'; c.fillStyle = 'rgba(255,255,255,0.52)'; c.fillText('4 days running', 30, 206);
      c.textAlign = 'right';
      c.font = 'italic 300 22px NY'; c.fillStyle = 'rgba(255,255,255,0.95)'; c.fillText('archive', W - 30, 162);
      c.font = '300 17px UPro'; c.fillStyle = 'rgba(255,255,255,0.86)'; c.fillText('30 past dailies', W - 30, 186);
    });
    L.next = text(W, 60, (c) => {
      c.font = '300 28px UPro';
      const a = '15', b = 'Waterfall', gap = 12, wa = c.measureText(a).width, wb = c.measureText(b).width;
      c.textAlign = 'left';
      c.fillStyle = purple; c.fillText(a, (W - wa - wb - gap) / 2, 40);
      c.fillStyle = '#fff'; c.fillText(b, (W - wa - wb - gap) / 2 + wa + gap, 40);
    });
    L.locked = text(W, 70, (c) => {
      c.font = 'italic 300 26px NY'; c.fillStyle = rgb(lighten(hue(TIERS[2], 14), 0.35)); c.fillText('vortex', W / 2, 26);
      c.font = '300 17px UPro'; c.fillStyle = 'rgba(255,255,255,0.86)';
      c.fillText('opens with every whirlpool level solved', W / 2, 52);
    });
    const cover = (name, title, state, owned) => layer(160, 150, (c) => {
      c.drawImage(IMG['cover-' + name], 34, 0, 92, 92);
      c.textAlign = 'center';
      c.font = '300 17px UPro'; c.fillStyle = 'rgba(255,255,255,0.92)';
      const w = c.measureText(title).width;
      c.fillText(title, 80 - (owned ? 9 : 0), 116);
      if (owned) tick(c, 80 + w / 2 + 2, 115);
      if (state) { c.font = '400 13px UMono'; c.fillStyle = 'rgba(255,255,255,0.52)'; c.fillText(state, 80, 135); }
    });
    L.lens = cover('lens', 'Lens', '', true);
    L.escapement = cover('escapement', 'Escapement', '3 free');
    L.prism = cover('prism', 'Prism', '2/3 free');
    L.foot = text(W, 80, (c) => {
      c.font = '300 15px UPro'; c.fillStyle = 'rgba(255,255,255,0.55)';
      c.fillText('packs · first 3 levels of each free', W / 2, 18);
      c.font = '300 15px UPro'; c.fillStyle = 'rgba(255,255,255,0.42)'; c.fillText('settings', W / 2 + 9, 62);
      const sw = c.measureText('settings').width;
      c.beginPath(); c.arc(W / 2 - sw / 2 - 2, 57, 3.2, 0, TAU);
      c.lineWidth = 1; c.strokeStyle = 'rgba(255,255,255,0.5)'; c.stroke();
    });
  } else buildAX(text, tick, purple);

  L.zoomTop = text(W, 320, (c) => {
    c.font = 'italic 300 46px NY'; c.fillStyle = purple; c.fillText('whirlpool', W / 2, 222);
    c.font = '400 13px UMono'; c.fillStyle = 'rgba(255,255,255,0.55)'; c.fillText('14 / 27 solved  ·  9 at par', W / 2, 252);
  });
  // The way back: the whole emblem in miniature.
  L.back = layer(60, 60, (c) => {
    c.translate(30, 30);
    [16, 11.5, 7, 2.5].forEach((r, k) => {
      c.beginPath(); c.arc(0, 0, r, 0, TAU); c.lineWidth = 2.2;
      c.strokeStyle = rgb(hue(TIERS[k], 13), k < 2 ? 0.85 : 0.4); c.stroke();
    });
  });
  L.tank = layer(404, 404, (c) => c.drawImage(IMG.tank, 0, 0, 404, 404));
  L.play = text(W, 240, (c) => {
    c.font = '300 28px UPro';
    const a = '15', b = 'Waterfall', gap = 12, wa = c.measureText(a).width, wb = c.measureText(b).width;
    c.textAlign = 'left';
    c.fillStyle = purple; c.fillText(a, (W - wa - wb - gap) / 2, 150);
    c.fillStyle = '#fff'; c.fillText(b, (W - wa - wb - gap) / 2 + wa + gap, 150);
    c.textAlign = 'center';
    c.font = '400 13px UMono'; c.fillStyle = 'rgba(255,255,255,0.55)'; c.fillText('moves 0  ·  par 8', W / 2, 178);
  });
}

// Accessibility type: the text keeps its size (body 17 -> 40), the emblem gives way, and the page scrolls.
function buildAX(text, tick, purple) {
  L.top = text(W, H, (c) => {
    c.font = '250 30px UPro'; c.fillStyle = '#fff';
    const s = 'UNSTIR', ws = [...s].map(ch => c.measureText(ch).width);
    let p = W / 2 - (ws.reduce((a, b) => a + b, 0) + 65) / 2;
    c.textAlign = 'left'; [...s].forEach((ch, i) => { c.fillText(ch, p, 108); p += ws[i] + 13; });
    c.font = '300 46px UPro';
    const a = '15', b = 'Waterfall', gap = 16, wa = c.measureText(a).width, wb = c.measureText(b).width;
    c.fillStyle = purple; c.fillText(a, (W - wa - wb - gap) / 2, 446);
    c.fillStyle = '#fff'; c.fillText(b, (W - wa - wb - gap) / 2 + wa + gap, 446);
    c.textAlign = 'center';
    c.font = 'italic 300 40px NY'; c.fillStyle = 'rgba(255,255,255,0.95)'; c.fillText('today', W / 2 - 12, 528);
    const tw = c.measureText('today').width;
    c.beginPath(); c.arc(W / 2 + tw / 2 + 8, 517, 6.5, 0, TAU); c.lineWidth = 2; c.strokeStyle = 'rgba(244,208,140,0.95)'; c.stroke();
    c.font = '300 40px UPro'; c.fillStyle = 'rgba(255,255,255,0.86)'; c.fillText('Daily · Fri 27 Nov', W / 2, 576);
    c.font = '400 30px UMono'; c.fillStyle = 'rgba(255,255,255,0.52)'; c.fillText('4 days running', W / 2, 616);
    c.font = 'italic 300 40px NY'; c.fillStyle = 'rgba(255,255,255,0.95)'; c.fillText('archive', W / 2, 700);
    c.font = '300 40px UPro'; c.fillStyle = 'rgba(255,255,255,0.86)'; c.fillText('30 past dailies', W / 2, 748);
    // The covers stay on the first screen at their size; their names follow one to a row as the page scrolls.
    [['lens', 78], ['escapement', 220], ['prism', 362]].forEach(([n, x]) => c.drawImage(IMG['cover-' + n], x - 46, 796, 92, 92));
    c.font = '300 40px UPro'; c.fillStyle = 'rgba(255,255,255,0.92)';
    const lw = c.measureText('Lens').width;
    c.fillText('Lens', 78 + lw / 2 - 46, 940); tick(c, 78 + lw - 46 + 22, 938, 2.2);
  });
}

// Where the emblem rests, and where the tapped band's index comes to at the zoom.
const REST = { x: W / 2, y: AX ? 252 : 408, scale: AX ? 0.62 : 1 };
const BAND = (TIERS[1].r0 + TIERS[1].r1) / 2;
const INDEX_Y = 604;                                   // the focused cell's centre on the zoomed screen
const T = { tap: 1500, zoom: [1750, 3050], drag: [4300, 5500], back: [6300, 7300], tap2: 8050, grow: [8300, 9700] };
const DURATION = 11600;
const LOCKED_AT = 20000;

function touch(ctx, t, at0, x, y, hold = 260) {
  const a = Math.min(ramp(t, at0 - 120, at0), 1 - ramp(t, at0 + hold, at0 + hold + 260));
  put(ctx, L.touch, x, y, { alpha: a, scale: mix(1.25, 1, ramp(t, at0 - 120, at0)) });
}

function draw(ctx, t) {
  put(ctx, L.ground, 0, 0, { ax: 0, ay: 0 });
  const locked = t >= LOCKED_AT;
  if (locked) t = 0;
  const k = AX ? 0 : smooth(ramp(t, ...T.zoom));            // 0 the whole, 1 the band
  const g = ease(ramp(t, ...T.grow));                       // the tank growing from the cell
  const s = Math.pow(Z, k) * REST.scale * mix(1, 1.22, g);
  const iy = mix(REST.y + BAND * REST.scale, INDEX_Y, smooth(k)) + 30 * g;
  const cy = iy - BAND * s;
  const out = 1 - g;

  // the whole emblem, handing over to the band drawn sharp
  put(ctx, L.emblem, REST.x, cy, { scale: s, alpha: 1 - ramp(k, 0.4, 0.85) });
  if (locked) put(ctx, L.lockedGlow, REST.x, cy, { scale: s });
  if (k > 0) {
    const d0 = smooth(ramp(t, ...T.drag)), d1 = smooth(ramp(t, ...T.back));
    const turn = (d0 - d1) * 2 * STEP;
    const ca = ramp(k, 0.4, 0.8) * out * out;
    put(ctx, L.ghost, REST.x, cy, { scale: s / Z, alpha: 0.55 * ca * ramp(k, 0.6, 1) });
    put(ctx, L.close, REST.x, cy, { scale: s / Z, alpha: ca, turn });
    put(ctx, L.veil, 0, 0, { ax: 0, ay: 0, alpha: ramp(k, 0.3, 0.55) * out });
    put(ctx, L.index, REST.x, iy - 14 * Z - 15, { alpha: ramp(k, 0.8, 1) * out });
  }

  // the launch screen's own things leave in two directions at their own speeds as the emblem comes forward
  const away = ease(ramp(k, 0, 0.6)), la = 1 - ramp(k, 0, 0.45);
  if (AX) put(ctx, L.top, 0, 0, { ax: 0, ay: 0 });
  else if (la > 0) {
    put(ctx, L.top, 0, -90 * away, { ax: 0, ay: 0, alpha: la });
    const base = REST.y + R;
    put(ctx, L.index, W / 2, base + 22 + 60 * away, { alpha: la });
    put(ctx, locked ? L.locked : L.next, 0, base + (locked ? 26 : 22) + 110 * away, { ax: 0, ay: 0, alpha: la });
    const py = REST.y + 346 + 190 * away;
    put(ctx, L.lens, 69, py - 34 + 29, { alpha: la });
    put(ctx, L.prism, 371, py - 34 + 29, { alpha: la });
    put(ctx, L.escapement, 220, py + 29 + 40 * away, { alpha: la });
    put(ctx, L.foot, 0, 868 + 240 * away, { ax: 0, ay: 0, alpha: la });
  }
  if (locked) put(ctx, L.touch, W / 2 + 96, REST.y + 38, { alpha: 0.9 });

  // the band's own screen
  const za = ramp(k, 0.7, 1) * out;
  put(ctx, L.zoomTop, 0, mix(-40, 0, ease(ramp(k, 0.5, 1))) - 60 * g, { ax: 0, ay: 0, alpha: za });
  put(ctx, L.back, W / 2, 884 + 40 * g, { alpha: za });

  // the tank, from the cell tapped
  if (g > 0) {
    put(ctx, L.tank, W / 2, mix(INDEX_Y, 500, g), { scale: mix(0.2, 1, g), alpha: ramp(g, 0, 0.25) });
    put(ctx, L.play, 0, 0, { ax: 0, ay: 0, alpha: ramp(t, T.grow[1] - 300, T.grow[1] + 300) });
  }

  put(ctx, L.status, 0, 0, { ax: 0, ay: 0 });
  touch(ctx, t, T.tap, W / 2 - 96, REST.y - 96);
  if (t > T.drag[0] - 200 && t < T.back[1] + 400) {         // a finger sliding the ring, and letting it come back
    const d0 = smooth(ramp(t, ...T.drag)), d1 = smooth(ramp(t, ...T.back));
    const a = Math.min(ramp(t, T.drag[0] - 150, T.drag[0]), 1 - ramp(t, T.back[1], T.back[1] + 250));
    put(ctx, L.touch, W / 2 + 90 - 200 * (d0 - d1), INDEX_Y + 110, { alpha: a });
  }
  touch(ctx, t, T.tap2, W / 2, INDEX_Y, 200);
}

window.DRAWS_AX = true;
window.DURATION = DURATION;
window.SHOTS = { launch: 0, band: 3700, locked: LOCKED_AT, play: 11000 };

const load = (name) => new Promise((res) => {
  const im = new Image(); im.onload = () => { IMG[name] = im; res(); }; im.onerror = () => res();
  im.src = GLASS + 'wheel-' + name + '.png';
});
const fonts = ['250 30px UPro', '300 28px UPro', '400 17px UPro', 'italic 300 22px NY', '400 13px UMono'];
Promise.all([...fonts.map(f => document.fonts.load(f)),
  ...['cover-lens', 'cover-escapement', 'cover-prism', 'tank', 'status'].map(load)])
  .then(() => document.fonts.ready).then(() => {
    Object.assign(document.body.style, { margin: 0, width: W + 'px', height: H + 'px', overflow: 'hidden', background: '#000' });
    const view = document.createElement('canvas');
    view.width = W * S; view.height = H * S;
    Object.assign(view.style, { position: 'absolute', left: 0, top: 0, width: W + 'px', height: H + 'px' });
    document.body.appendChild(view);
    const ctx = view.getContext('2d');
    build();
    window.seek = (t) => { ctx.setTransform(S, 0, 0, S, 0, 0); ctx.clearRect(0, 0, W, H); draw(ctx, t); };
    window.seek(0);
    document.body.dataset.ready = '1';
  });
