// Copyright © 2026 Jack Lusher. All rights reserved.
// The Basin: one still, round pool seen from straight above. Levels are droplets resting on a faint current that
// spirals in to a drain; the daily is the moon's reflection; packs drift as lily pads; settings are ripple rings.
// Nothing here stirs: things glide along the current, bob, and ripple outward. The glass is drawn as cropped.

const { ramp, ease, settle, mix } = World;  // W and H come from lib.js
const RM = World.rm;
const pt = (role) => World.pt(role);

// ---------- Palette ----------
const INK = '234,243,244';            // type and highlights
const AQUA = '150,224,232';           // droplet light
const MOON = '242,234,216';           // the moon and the daily
const ink = (a) => `rgba(${INK},${a})`;
const aqua = (a) => `rgba(${AQUA},${a})`;
const moon = (a) => `rgba(${MOON},${a})`;

// ---------- The basin ----------
const BASIN = { x: 220, y: 478, r: 520 };

// ---------- Today's words ----------
const PLUGHOLE = ['Drop', 'Drip', 'Trickle', 'Ripple', 'Bubble', 'Fizz', 'Sprinkle', 'Mist', 'Spray', 'Splash', 'Puddle',
  'Froth', 'Suds', 'Lather', 'Steam', 'Gurgle', 'Rinse', 'Drizzle', 'Shower', 'Downpour', 'Overflow', 'Bathwater',
  'Spin', 'Whirl', 'Spiral', 'Last drop', 'Drain'];
const PARS = [1, 1, 2, 2, 3, 3, 4, 3, 2, 4, 5, 6, 7, 4, 5, 3, 7, 8, 6, 7, 8, 6, 7, 8, 8, 9, 9];
const RODS = (n) => (n <= 8 ? 3 : 4);

// ---------- The current: a spiral from the lower right in to the drain ----------
// It winds just under two turns in to the drain, and runs only a little way out past the front slot before it leaves
// the screen, so levels already played drift out of sight low on the left instead of over the type at the top.
const SPIRAL = (() => {
  const c = { x: 220, y: 470 }, rOut = 264, rIn = 26, th = 4.2 * Math.PI, sx = 1.0, sy = 1.18, pw = 1.0;
  const rf = 232, af = 62 * Math.PI / 180;                     // the front slot: radius and angle
  const qf = th * Math.pow((rf - rIn) / (rOut - rIn), 1 / pw);
  const phi0 = af - qf;
  const pts = [];
  let len = 0, prev = null;
  for (let k = 0; k <= 2400; k++) {
    const q = th * (1 - k / 2400);                    // q = th at the outer end, 0 at the drain
    const r = rIn + (rOut - rIn) * Math.pow(q / th, pw);
    const a = q + phi0;
    const p = { x: c.x + r * Math.cos(a) * sx, y: c.y + r * Math.sin(a) * sy, r, q };
    if (prev) len += Math.hypot(p.x - prev.x, p.y - prev.y);
    p.u = len; pts.push(p); prev = p;
  }
  const at = (u) => {
    u = Math.max(0, Math.min(len, u));
    let lo = 0, hi = pts.length - 1;
    while (hi - lo > 1) { const m = (lo + hi) >> 1; if (pts[m].u < u) lo = m; else hi = m; }
    const a = pts[lo], b = pts[hi], f = (u - a.u) / Math.max(1e-6, b.u - a.u);
    return { x: mix(a.x, b.x, f), y: mix(a.y, b.y, f), r: mix(a.r, b.r, f), u };
  };
  let front = 0;
  for (const p of pts) if (p.q >= qf) front = p.u;
  // Offsets k (levels from the front, inward positive) to arc length; spacing shrinks as the current narrows,
  // scaled so that the tier's last level rests at the drain's lip when the next level is at the front.
  let G = 60;
  const walk = (k, g) => {
    let u = front;
    const step = Math.sign(k) * 0.02;
    for (let x = 0; Math.abs(x) < Math.abs(k) - 1e-9; x += step) {
      const p = at(u);
      u += step * g * (0.42 + 0.58 * p.r / rOut);
    }
    return u;
  };
  let lo = 20, hi = 200;
  for (let i = 0; i < 30; i++) { G = (lo + hi) / 2; if (walk(13, G) < len - 34) lo = G; else hi = G; }
  const offs = new Map();
  const U = (k) => {
    const key = Math.round(k * 1000);
    if (!offs.has(key)) offs.set(key, walk(k, G));
    return offs.get(key);
  };
  return { c, pts, len, at, U, front, rOut };
})();

// ---------- Drawing helpers ----------
function font(weight, size, family = 'NY', style = '') {
  return `${style} ${weight} ${size}px ${family}`.trim();
}
function text(ctx, s, x, y, { size = 17, weight = 400, family = 'NY', style = '', color = ink(0.92), align = 'left', track = 0, stretch } = {}) {
  ctx.save();
  ctx.font = font(weight, size, family, style);
  if (stretch) ctx.fontStretch = stretch;
  ctx.letterSpacing = track + 'px';
  ctx.fillStyle = color;
  ctx.textAlign = align;
  ctx.fillText(s, x, y);
  ctx.restore();
}
function arc(ctx, s, cx, cy, r, a, { size = 17, weight = 400, family = 'NY', style = '', color = ink(0.92), inward = true, track = 0, stretch } = {}) {
  ctx.save();
  ctx.font = font(weight, size, family, style);
  if (stretch) ctx.fontStretch = stretch;
  ctx.letterSpacing = track + 'px';
  ctx.fillStyle = color;
  World.arcText(ctx, s, cx, cy, r, a, { inward });
  ctx.restore();
}
function glow(ctx, x, y, r, rgb, a) {
  const g = ctx.createRadialGradient(x, y, 0, x, y, r);
  g.addColorStop(0, `rgba(${rgb},${a})`);
  g.addColorStop(0.35, `rgba(${rgb},${a * 0.35})`);
  g.addColorStop(1, `rgba(${rgb},0)`);
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
}
// A droplet: a lens of light with a bright meniscus on its upper left, like water standing on water.
function droplet(ctx, x, y, r, { light = 1, rgb = AQUA, halo = 2.6 } = {}) {
  if (light > 0.05) glow(ctx, x, y, r * halo, rgb, 0.22 * light);
  const g = ctx.createRadialGradient(x - r * 0.35, y - r * 0.4, r * 0.1, x, y, r);
  g.addColorStop(0, `rgba(255,255,255,${0.85 * light + 0.1})`);
  g.addColorStop(0.45, `rgba(${rgb},${0.55 * light + 0.12})`);
  g.addColorStop(1, `rgba(${rgb},${0.10 * light + 0.04})`);
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = `rgba(255,255,255,${0.25 * light + 0.08})`;
  ctx.lineWidth = 0.7;
  ctx.beginPath(); ctx.arc(x, y, r - 0.4, Math.PI * 1.05, Math.PI * 1.7); ctx.stroke();
}
function mote(ctx, x, y, filled, a = 1) {
  ctx.save();
  if (filled) {
    glow(ctx, x, y, 7, INK, 0.35 * a);
    ctx.fillStyle = ink(0.95 * a);
    ctx.beginPath(); ctx.arc(x, y, 3, 0, Math.PI * 2); ctx.fill();
  } else {
    ctx.strokeStyle = ink(0.7 * a); ctx.lineWidth = 1;
    ctx.beginPath(); ctx.arc(x, y, 2.8, 0, Math.PI * 2); ctx.stroke();
  }
  ctx.restore();
}
function marks(ctx, x, y, r, n, a = 1, from = -1.15) {
  for (let k = 0; k < 3; k++) {
    const ang = from + k * 0.42;
    mote(ctx, x + (r + 8) * Math.cos(ang), y + (r + 8) * Math.sin(ang), k < n, a);
  }
}
function ring(ctx, x, y, r, a, w = 1, rgb = INK) {
  ctx.strokeStyle = `rgba(${rgb},${a})`; ctx.lineWidth = w;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke();
}
function fingertip(ctx, x, y, press) {
  glow(ctx, x, y, 34, '255,255,255', 0.16 + 0.1 * press);
  ctx.fillStyle = `rgba(255,255,255,${0.22 + 0.12 * press})`;
  ctx.beginPath(); ctx.arc(x, y, 15 - 2 * press, 0, Math.PI * 2); ctx.fill();
}
const bob = (t, seed, amp = 1.4) => (RM ? 0 : amp * Math.sin(t * 0.0011 + seed * 2.3) + amp * 0.5 * Math.sin(t * 0.0007 + seed));

// ---------- The timeline ----------
// Each scene fades in over [a, b] and out over [c, d]; draw() gets its alpha.
const T = {
  menuIn: [0, 600], menuOut: [6300, 7000],
  dragStart: 2900, dragEnd: 3700, glideEnd: 5300, tap: 5900,
  playIn: [6600, 7400], playOut: [9300, 9900],
  resultIn: [9900, 10300], resultOut: [13700, 14300],
  todayIn: [14300, 14900], todayOut: [17300, 18200],
  padStart: 17000, padEnd: 18400,
  packIn: [17900, 18500], packOut: [20900, 21500],
  prismIn: [21300, 21900], prismOut: [23500, 24000],
  today2In: [23600, 24200],
  setStart: 24300, setEnd: 25600,
  end: 27200,
};
const fade = (t, [a, b], out) => (out ? 1 - ease(ramp(t, out[0], out[1])) : 1) * ease(ramp(t, a, b));

// ---------- Scene: the menu (plughole 01 to 13 solved at par with a stir undone, 14 next) ----------
function focusAt(t) {
  if (t < T.dragStart) return 14;
  if (t < T.dragEnd) return 14 - 1.2 * ease(ramp(t, T.dragStart, T.dragEnd));
  // a glide on the current: 12.8 -> 1, settling
  return mix(12.8, 1, settle(ramp(t, T.dragEnd, T.glideEnd)));
}

function spiralCurrent(ctx, a) {
  // The faint current itself: a soft line of light along the spiral, brighter where the levels rest.
  ctx.save();
  ctx.lineCap = 'round';
  for (let i = 1; i < SPIRAL.pts.length; i += 2) {
    const p = SPIRAL.pts[i], q = SPIRAL.pts[i - 1];
    const near = Math.exp(-Math.pow((p.u - SPIRAL.front) / 520, 2));
    ctx.strokeStyle = aqua((0.05 + 0.08 * near) * a);
    ctx.lineWidth = 1 + 2.2 * (p.r / SPIRAL.rOut);
    ctx.beginPath(); ctx.moveTo(q.x, q.y); ctx.lineTo(p.x, p.y); ctx.stroke();
  }
  ctx.restore();
}

function drawLevels(ctx, t, a, { focus, solvedTo, nextAt, marksN, labels = true, skip = -1 }) {
  // Back to front: inner (later) droplets first.
  const order = [];
  for (let n = 1; n <= 27; n++) order.push(n);
  order.sort((x, y) => y - x);
  const positions = {};
  for (const n of order) {
    const k = n - focus;
    const u = SPIRAL.U(k);
    if (u < -40 || u > SPIRAL.len) continue;
    const p = SPIRAL.at(u);
    const depth = p.r / SPIRAL.rOut;
    const x = p.x + bob(t, n, 0.9), y = p.y + bob(t, n + 7, 1.1);
    positions[n] = { x, y, depth };
    if (x < -30 || x > W + 30 || y < -30 || y > H + 30) continue;
    if (n === skip) continue;
    const solved = n <= solvedTo, isNext = n === nextAt, locked = n > nextAt;
    const prox = Math.exp(-Math.pow(k, 2) / 2.2);          // how near the front this droplet rests
    let r = 3 + 6.5 * depth;
    if (isNext) r = mix(r, 15, prox);
    else r += 2.5 * prox;
    const light = locked ? 0.12 : solved ? 0.55 + 0.25 * prox : 1;
    ctx.save();
    ctx.globalAlpha = a * (locked ? 0.75 : 1);
    if (locked) {
      ctx.fillStyle = 'rgba(120,150,160,0.35)';
      ctx.beginPath(); ctx.arc(x, y, r * 0.8, 0, Math.PI * 2); ctx.fill();
      ring(ctx, x, y, r * 0.8, 0.22, 0.7, '170,200,210');
    } else {
      droplet(ctx, x, y, r, { light, halo: isNext ? 3.6 : 2.4 });
      if (isNext) ring(ctx, x, y, r + 7 + (RM ? 0 : 1.5 * Math.sin(t * 0.0016)), 0.25, 0.8, AQUA);
    }
    if (solved && prox > 0.02) marks(ctx, x, y, r, marksN(n), prox, -1.25);
    ctx.restore();
  }
  if (!labels) return positions;
  // Names: the front droplet's in full, its two neighbours' faint, the rest unnamed.
  for (const n of order) {
    const pos = positions[n];
    if (!pos) continue;
    const k = n - focus;
    const prox = Math.exp(-Math.pow(k, 2) / 0.12);
    const nb = Math.exp(-Math.pow(Math.abs(k) - 1, 2) / 0.12) * (1 - prox);
    const nn = String(n).padStart(2, '0');
    if (prox > 0.03) {
      const la = a * prox;
      const x = pos.x - 30, y = pos.y - (World.ax ? 40 : 6);
      ctx.save(); ctx.font = font(300, pt('title')); const w = ctx.measureText(PLUGHOLE[n - 1]).width; ctx.restore();
      text(ctx, PLUGHOLE[n - 1], x, y, { size: pt('title'), weight: 300, color: ink(0.97 * la), align: 'right' });
      text(ctx, nn, x - w - 10, y, { size: pt('label'), family: 'UPro', weight: 500, color: ink(0.74 * la), align: 'right' });
      text(ctx, `${RODS(n)} rods · par ${PARS[n - 1]}`, x, y + pt('label') + 9, { size: pt('label'), family: 'UPro', weight: 400, color: ink(0.74 * la), align: 'right' });
    } else if (nb > 0.03 && !World.ax) {
      const la = a * nb;
      text(ctx, `${nn}  ${PLUGHOLE[n - 1]}`, pos.x - 18, pos.y + 5, { size: pt('body'), weight: 400, color: ink(0.66 * la), align: 'right' });
    }
  }
  return positions;
}

function drawRimType(ctx, a, { open = 1 } = {}) {
  // UNSTIR and the tiers ride an arc concentric with the basin's rim.
  arc(ctx, 'UNSTIR', BASIN.x, BASIN.y, World.ax ? 360 : 378, -Math.PI / 2, { size: pt('display'), weight: 200, family: 'UPro', stretch: 'expanded', track: 9, color: ink(0.9 * a) });
  const r = World.ax ? 300 : 340;
  arc(ctx, 'plughole', BASIN.x, BASIN.y, r, -Math.PI / 2, { size: pt('label'), family: 'UPro', weight: 500, track: 1.5, color: ink(0.95 * a) });
  if (!World.ax) arc(ctx, 'whirlpool', BASIN.x, BASIN.y, r, -Math.PI / 2 + 0.43, { size: pt('label'), family: 'UPro', weight: 400, track: 1.5, color: ink((open ? 0.7 : 0.62) * a) });
  if (!World.ax) arc(ctx, 'vortex', BASIN.x, BASIN.y, r, -Math.PI / 2 + 0.78, { size: pt('label'), family: 'UPro', weight: 400, track: 1.5, color: ink(0.62 * a) });
  arc(ctx, 'maelstrom', BASIN.x, BASIN.y, r, -Math.PI / 2 - 0.47, { size: pt('label'), family: 'UPro', weight: 400, track: 1.5, color: ink(0.0 * a) });
  // A small mark under the current tier: one droplet on the arc.
  const ax = BASIN.x, ay = BASIN.y - r + 14;
  droplet(ctx, ax, ay, 2.4, { light: a, halo: 3 });
  if (World.ax) [0.5, 0.62, 0.74].forEach((da) => droplet(ctx, BASIN.x + r * Math.cos(-Math.PI / 2 + da), BASIN.y + r * Math.sin(-Math.PI / 2 + da), 3, { light: 0.5 * a, halo: 2 }));
  // The settings: two small rings, a ripple, top right.
  ring(ctx, 404, 92, 5, 0.7 * a, 1);
  ring(ctx, 404, 92, 10, 0.4 * a, 1);
}

function drawPads(ctx, t, a, { lift = -1, liftT = 0 } = {}) {
  // Packs as lily pads drifting low on the water: the real covers, each with a soft shadow and a sheen.
  const pads = [
    { n: 'cover-first-stir', x: 58, y: 872, d: 58, s: 1 },
    { n: 'cover-lens', x: 140, y: 902, d: 64, s: 2, fresh: 1 },
    { n: 'cover-escapement', x: 232, y: 884, d: 60, s: 3, fresh: 1 },
    { n: 'cover-prism', x: 318, y: 906, d: 64, s: 4, fresh: 1 },
    { n: 'cover-triptych', x: 396, y: 866, d: 56, s: 5 },
  ];
  pads.forEach((p, i) => {
    let x = p.x + (RM ? 0 : 3 * Math.sin(t * 0.0004 + p.s)), y = p.y + bob(t, p.s, 1.6), d = p.d;
    if (i === lift) {
      const f = ease(liftT);
      x = mix(x, 220, f); y = mix(y, 418, f); d = mix(d, 300, f);
    }
    ctx.save();
    ctx.globalAlpha = a;
    glow(ctx, x + 2, y + 4, d * 0.75, '0,0,0', 0.55);
    World.disc(ctx, p.n, x, y, d, a);
    ring(ctx, x, y, d / 2 + 0.5, 0.18, 1);
    if (p.fresh && i !== lift) mote(ctx, x, y + d / 2 + 9, true, 0.9);
    ctx.restore();
  });
}

function drawMenu(ctx, t, a) {
  if (a <= 0) return;
  ctx.save();
  ctx.globalAlpha = 1;
  spiralCurrent(ctx, a);
  const focus = focusAt(t);
  const tapF = ramp(t, T.tap, T.tap + 900);
  const skip = t > T.tap + 120 ? 1 : -1;
  drawLevels(ctx, t, a, { focus, solvedTo: 13, nextAt: 14, marksN: () => 2, skip });
  drawRimType(ctx, a, { open: 0 });
  drawPads(ctx, t, a);
  // The flick: a fingertip lands on the front droplet, draws a short way in along the current, lifts.
  if (t > T.dragStart - 300 && t < T.dragEnd + 400) {
    const f = ease(ramp(t, T.dragStart, T.dragEnd));
    const p = SPIRAL.at(SPIRAL.front + 150 * f);
    const press = ramp(t, T.dragStart - 300, T.dragStart) * (1 - ramp(t, T.dragEnd, T.dragEnd + 400));
    if (!RM) fingertip(ctx, p.x, p.y, press);
  }
  if (t > T.tap - 400 && t < T.tap + 500) {
    const p = SPIRAL.at(SPIRAL.front);
    const press = ramp(t, T.tap - 400, T.tap) * (1 - ramp(t, T.tap, T.tap + 500));
    if (!RM) fingertip(ctx, p.x, p.y, press);
  }
  ctx.restore();
}

// The tapped droplet grows into the tank: a widening lens of light that the glass then fills.
function drawGrow(ctx, t) {
  const f = ramp(t, T.tap + 100, T.playIn[1]);
  if (f <= 0 || f >= 1) return;
  const p = SPIRAL.at(SPIRAL.front);
  const e = ease(f);
  const x = mix(p.x, TANK.x, e), y = mix(p.y, TANK.y, e), r = mix(15, TANK.d / 2, e);
  ctx.save();
  ctx.globalAlpha = 1 - ramp(f, 0.7, 1);
  droplet(ctx, x, y, r, { light: 1 - 0.6 * e, halo: 1.6 });
  ctx.restore();
}

// ---------- Scene: play (plughole 01 as dealt) ----------
const TANK = { x: 220, y: 470, d: 403 };
function tankGeom() {
  // At accessibility sizes the tank gives way to the type, never the other way round.
  return World.ax ? { x: 220, y: 440, d: 300 } : TANK;
}
// Lines broken to fit a width at the role's size: at accessibility sizes the note runs to more lines, never smaller.
function wrap(ctx, lines, max, { size, family = 'UPro', weight = 400 }) {
  ctx.save(); ctx.font = font(weight, size, family);
  const out = [];
  for (const line of lines) {
    let cur = '';
    for (const w of line.split(' ')) {
      const next = cur ? cur + ' ' + w : w;
      if (ctx.measureText(next).width > max && cur) { out.push(cur); cur = w; } else cur = next;
    }
    out.push(cur);
  }
  ctx.restore();
  return out;
}
function levelsDroplet(ctx, a, label = 'levels') {
  droplet(ctx, 34, 92, 6, { light: a });
  text(ctx, label, 50, 98, { size: pt('body'), family: 'UPro', weight: 400, color: ink(0.86 * a) });
}
function drawPlay(ctx, t, a, o) {
  if (a <= 0) return;
  const g = tankGeom();
  ctx.save();
  ctx.globalAlpha = a;
  World.disc(ctx, o.glass, g.x, g.y, g.d);
  ctx.restore();
  const r = g.d / 2;
  levelsDroplet(ctx, a);
  arc(ctx, o.title, g.x, g.y, r + 22, -Math.PI / 2, { size: pt('title'), weight: 300, color: ink(0.96 * a) });
  // The level's number sits small just above its name, in white light (on Prism, never one channel's colour).
  arc(ctx, o.num, g.x, g.y, r + 22 + pt('title') + 6, -Math.PI / 2, { size: pt('label'), family: 'UPro', weight: 500, track: 2, color: ink(0.8 * a) });
  if (o.pack) arc(ctx, o.pack, g.x, g.y, r + 22 + pt('title') + 6, -Math.PI / 2 - 0.42, { size: pt('label'), family: 'UPro', weight: 400, track: 2, color: ink(0.66 * a) });
  arc(ctx, o.count, g.x, g.y, r + 8 + 0.74 * pt('label'), Math.PI / 2, { size: pt('label'), family: 'UPro', weight: 400, color: ink(0.78 * a), inward: false });
  // The note: two short lines, floating.
  const ny = g.y + r + 16 + pt('label') + (World.ax ? 34 : 46);
  wrap(ctx, o.note, 392, { size: pt('label'), family: 'UPro', weight: 400 }).forEach((line, i) =>
    text(ctx, line, 220, ny + i * (pt('label') * 1.4), { size: pt('label'), family: 'UPro', weight: 400, color: ink(0.74 * a), align: 'center' }));
  // Undo and reset: two droplets low left and right.
  const cy = World.ax ? 922 : 878;
  droplet(ctx, 44, cy, 7, { light: 0.55 * a });
  text(ctx, o.undo, 62, cy + 6, { size: pt('body'), family: 'UPro', weight: 400, color: ink(0.8 * a) });
  droplet(ctx, 396, cy, 7, { light: 0.55 * a });
  text(ctx, 'reset', 378, cy + 6, { size: pt('body'), family: 'UPro', weight: 400, color: ink(0.86 * a), align: 'right' });
}

// ---------- Scene: the result (plughole 27 at par with a stir undone, a new best, up a notch) ----------
const RTANK = { x: 220, y: 446, d: 384 };
function drawResult(ctx, t, a) {
  if (a <= 0) return;
  const g = RTANK, r = g.d / 2;
  ctx.save(); ctx.globalAlpha = a; World.disc(ctx, 'drain-solved', g.x, g.y, g.d); ctx.restore();
  levelsDroplet(ctx, a);
  const t0 = T.resultIn[0];
  const word = RM ? 1 : settle(ramp(t, t0 + 500, t0 + 1700));
  arc(ctx, 'unstirred.', g.x, g.y, r + 24 + (1 - word) * 10, -Math.PI / 2, { size: pt('title'), weight: 300, style: 'italic', color: ink(0.97 * a * Math.min(1, word * 1.2)) });
  arc(ctx, '27 · Drain', g.x, g.y, r + 24 + pt('title') + 10, -Math.PI / 2, { size: pt('label'), family: 'UPro', weight: 400, track: 1, color: ink(0.7 * a) });
  // The marks: three motes coming to rest on the water just under the bezel.
  for (let k = 0; k < 3; k++) {
    const land = RM ? 1 : settle(ramp(t, t0 + 1100 + k * 260, t0 + 2000 + k * 260));
    const ang = Math.PI / 2 - (k - 1) * 0.09;   // left to right: solved, at par, clean
    const rr = r + 18 + (1 - land) * 16;
    if (land > 0) mote(ctx, g.x + rr * Math.cos(ang), g.y + rr * Math.sin(ang), k < 2, a * Math.min(1, land * 1.5));
  }
  const la = a * (RM ? 1 : ease(ramp(t, t0 + 1600, t0 + 2500)));
  arc(ctx, 'at par · new best, was +6', g.x, g.y, r + 46, Math.PI / 2, { size: pt('body'), weight: 400, color: ink(0.92 * la), inward: false });
  text(ctx, 'clean needs no undo or reset', 220, g.y + r + 104, { size: pt('detail'), family: 'UPro', weight: 400, color: ink(0.7 * la), align: 'center' });
  // Again and up a notch: two droplets; the one for whirlpool glides off towards the rim.
  const ga = a * (RM ? 1 : ease(ramp(t, t0 + 2200, t0 + 3000)));
  const drift = RM ? 0 : 14 * ease(ramp(t, t0 + 2600, t0 + 4200));
  droplet(ctx, 44, 878, 7, { light: 0.55 * ga });
  text(ctx, 'again', 62, 884, { size: pt('body'), family: 'UPro', weight: 400, color: ink(0.82 * ga) });
  const wx = 356 + drift, wy = 872 - drift * 0.3;
  droplet(ctx, wx + 20, wy, 9, { light: ga, rgb: '255,120,170', halo: 3.4 });
  text(ctx, 'whirlpool ›', wx + 2, wy + 6, { size: pt('body'), weight: 400, color: ink(0.96 * ga), align: 'right' });
  text(ctx, 'up a notch', wx + 2, wy - 20, { size: pt('detail'), family: 'UPro', weight: 400, color: ink(0.7 * ga), align: 'right' });
}

// ---------- Scene: the menu with today (every plughole level at par; the daily, the archive, endless) ----------
const MOONP = { x: 92, y: 226, r: 28 };
const DRAIN = { x: 220, y: 470 };
function drawToday(ctx, t, a, { dim = 0, lift = -1, liftT = 0 } = {}) {
  if (a <= 0) return;
  const k = a * (1 - dim);
  spiralCurrent(ctx, k);
  // Every level at par: the whole tier rests on the current, each droplet with its two motes, none singled out.
  drawLevels(ctx, t, k, { focus: 14, solvedTo: 27, nextAt: 28, marksN: () => 2, labels: false });
  drawRimType(ctx, k, { open: 1 });
  // The daily: today's moon on the water. The archive: past moons, fainter, drifting after it.
  const mb = bob(t, 11, 0.8);
  [[290, 208, 12, 0.34], [320, 199, 8, 0.24], [342, 194, 5, 0.17]].forEach(([x, y, r, al]) => {
    glow(ctx, x, y + mb, r * 2.4, MOON, al * 0.45 * k);
    ctx.fillStyle = moon(al * k); ctx.beginPath(); ctx.arc(x, y + mb, r, 0, Math.PI * 2); ctx.fill();
  });
  text(ctx, 'archive', 278, 242 + mb, { size: pt('label'), family: 'UPro', weight: 400, color: ink(0.74 * k) });
  text(ctx, 'comes with any pack', 278, 242 + pt('detail') + 8 + mb, { size: pt('detail'), family: 'UPro', weight: 400, color: ink(0.66 * k) });
  arc(ctx, 'today', MOONP.x, MOONP.y + mb, MOONP.r + 10, -Math.PI / 2, { size: pt('label'), family: 'UPro', weight: 500, track: 1.5, color: moon(0.95 * k) });
  text(ctx, 'daily', MOONP.x + MOONP.r + 18, MOONP.y + 2 + mb, { size: pt('body'), weight: 400, color: ink(0.96 * k) });
  text(ctx, '4 days running', MOONP.x + MOONP.r + 18, MOONP.y + 2 + pt('detail') + 10 + mb, { size: pt('detail'), family: 'UPro', weight: 400, color: ink(0.74 * k) });
  marks(ctx, MOONP.x, MOONP.y + mb, MOONP.r, 2, k, 1.2);
  // Endless: the drain itself.
  text(ctx, 'endless', DRAIN.x, DRAIN.y + 4, { size: pt('label'), family: 'UPro', weight: 500, track: 1, color: ink(0.86 * k), align: 'center' });
  text(ctx, 'best 9', DRAIN.x, DRAIN.y + 4 + pt('detail') + 6, { size: pt('detail'), family: 'UPro', weight: 400, color: ink(0.72 * k), align: 'center' });
  drawPads(ctx, t, k, { lift, liftT });
}

// ---------- Scene: Prism's pack (unowned) ----------
function prismWord(ctx, s, cx, cy, r, a) {
  // Three passes off register, red, green and blue: where they meet the word is white.
  ctx.save();
  ctx.globalCompositeOperation = 'lighter';
  const off = [[-1.6, '255,60,60'], [0, '60,255,110'], [1.6, '80,120,255']];
  for (const [dx, rgb] of off) arc(ctx, s, cx + dx, cy, r, -Math.PI / 2, { size: pt('display'), weight: 400, color: `rgba(${rgb},${0.9 * a})` });
  ctx.restore();
}
function drawPack(ctx, t, a) {
  if (a <= 0) return;
  const c = { x: 220, y: 418 }, d = 300, r = d / 2;
  ctx.save(); ctx.globalAlpha = a; World.disc(ctx, 'prism-clip', c.x, c.y, d); ctx.restore();
  levelsDroplet(ctx, a, 'menu');
  // The thirty specimens: a ring of tiny droplets, the three free ones lit.
  for (let k = 0; k < 30; k++) {
    const ang = -Math.PI / 2 + (k / 30) * Math.PI * 2 + 0.06;
    const rr = r + 15;
    const x = c.x + rr * Math.cos(ang), y = c.y + rr * Math.sin(ang);
    if (k < 3) droplet(ctx, x, y, 3, { light: a, halo: 3 });
    else { ctx.fillStyle = aqua(0.3 * a); ctx.beginPath(); ctx.arc(x, y, 1.8, 0, Math.PI * 2); ctx.fill(); }
  }
  prismWord(ctx, 'Prism', c.x, c.y, r + 34, a);
  arc(ctx, 'each rod stirs only some colours', c.x, c.y, r + 32, Math.PI / 2, { size: pt('body'), weight: 400, style: 'italic', color: ink(0.9 * a), inward: false });
  const fy = 676;
  text(ctx, '30 specimens in five trays', 220, fy, { size: pt('label'), family: 'UPro', color: ink(0.86 * a), align: 'center' });
  text(ctx, 'levels 1–3 free, no purchase', 220, fy + 24, { size: pt('label'), family: 'UPro', color: ink(0.86 * a), align: 'center' });
  text(ctx, 'letters for colour-blind play, in settings', 220, fy + 46, { size: pt('detail'), family: 'UPro', color: ink(0.68 * a), align: 'center' });
  // Buy: the brightest droplet on the water. Try: a smaller one beside it.
  const by = 800;
  glow(ctx, 128, by, 92, AQUA, 0.22 * a);
  ctx.save();
  const pg = ctx.createRadialGradient(112, by - 18, 6, 128, by, 50);
  pg.addColorStop(0, `rgba(255,255,255,${a})`); pg.addColorStop(0.6, `rgba(214,242,246,${a})`); pg.addColorStop(1, `rgba(160,214,222,${a})`);
  ctx.fillStyle = pg; ctx.beginPath(); ctx.arc(128, by, 50, 0, Math.PI * 2); ctx.fill();
  ctx.restore();
  text(ctx, 'buy $2.99', 128, by + 6, { size: pt('body'), family: 'UPro', weight: 600, color: `rgba(6,20,26,${a})`, align: 'center' });
  droplet(ctx, 248, by, 6, { light: 0.6 * a });
  text(ctx, 'try 3 free ›', 262, by + 6, { size: pt('body'), family: 'UPro', weight: 400, color: ink(0.9 * a) });
  arc(ctx, 'or all three in Triptych I · $5.99 · save $2.98 ›', 220, 478, 430, Math.PI / 2, { size: pt('detail'), family: 'UPro', color: ink(0.7 * a), inward: false });
  arc(ctx, 'restore purchases', 220, 478, 462, Math.PI / 2, { size: pt('detail'), family: 'UPro', color: ink(0.66 * a), inward: false });
}

// ---------- Scene: settings, ripple rings rising from the bottom edge over the dimmed menu ----------
const SET = { x: 220, y: 1010 };
const RINGS = [
  { r: 150, label: 'music · on', on: true },
  { r: 214, label: 'sounds · on', on: true },
  { r: 278, label: 'haptics · on', on: true },
  { r: 342, label: 'colour letters · off', on: false },
  { r: 418, label: 'restore purchases', link: true },
  { r: 476, label: 'report a problem ↗   ·   privacy policy ↗', link: true },
];
function drawSettings(ctx, t, a) {
  if (a <= 0) return;
  RINGS.forEach((g, i) => {
    const f = RM ? a : a * settle(ramp(t, T.setStart + i * 110, T.setStart + 900 + i * 110));
    if (f <= 0) return;
    const rr = g.r * mix(0.7, 1, Math.min(1, f));
    const bright = g.on === true ? 0.75 : g.on === false ? 0.2 : 0.12;
    ctx.save();
    if (g.on) { ctx.shadowColor = aqua(0.6); ctx.shadowBlur = 10; }
    ring(ctx, SET.x, SET.y, rr, bright * Math.min(1, f), g.on ? 1.6 : 1, g.on ? AQUA : INK);
    ctx.restore();
    const col = g.on === false ? ink(0.72 * f) : g.link ? ink(0.8 * f) : ink(0.96 * f);
    arc(ctx, g.label, SET.x, SET.y, rr + 10, -Math.PI / 2, { size: pt('body'), family: 'UPro', weight: g.on ? 500 : 400, color: col });
    if (g.sub) arc(ctx, g.sub, SET.x, SET.y, rr - 10 - pt('detail'), -Math.PI / 2, { size: pt('detail'), family: 'UPro', color: ink(0.66 * f) });
  });
  const f = RM ? a : a * ease(ramp(t, T.setStart + 700, T.setStart + 1500));
  arc(ctx, 'settings', SET.x, SET.y, 548, -Math.PI / 2, { size: 20, weight: 300, style: 'italic', color: ink(0.95 * f) });
  text(ctx, 'Unstir 1.0 (1)', 220, 942, { size: pt('detail'), family: 'UPro', color: ink(0.62 * f), align: 'center' });
}

// ---------- Uniforms for the water ----------
function uniforms(t) {
  const menuA = fade(t, T.menuIn, T.menuOut);
  const todayA = Math.max(fade(t, T.todayIn, T.todayOut), ease(ramp(t, T.today2In[0], T.today2In[1])));
  const dim = ease(ramp(t, T.setStart - 200, T.setStart + 800));
  const playA = Math.max(fade(t, T.playIn, T.playOut), fade(t, T.prismIn, T.prismOut));
  const resA = fade(t, T.resultIn, T.resultOut);
  const packA = fade(t, T.packIn, T.packOut);
  const drainA = Math.max(menuA, todayA);
  const tank = resA > 0.01 ? [RTANK.x, RTANK.y, RTANK.d / 2] : packA > 0.01 ? [220, 418, 150] : [tankGeom().x, tankGeom().y, tankGeom().d / 2];
  const tankA = Math.max(playA, resA, packA);
  const rip = RM ? 0 : ramp(t, T.resultIn[0] + 100, T.resultIn[0] + 3600);
  return {
    drain: [DRAIN.x, DRAIN.y], drainA,
    moon: [MOONP.x, MOONP.y + bob(t, 11, 0.8)], moonA: todayA * (1 - dim * 0.7),
    tank, tankA,
    rip, ripA: RM ? 0 : resA,
    dim: dim * 0.82,
    hue: 0,
  };
}

const shader = `
uniform vec2 drain; uniform float drainA;
uniform vec2 moon; uniform float moonA;
uniform vec3 tank; uniform float tankA;
uniform float rip; uniform float ripA;
uniform float dim;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) {
  vec2 i = floor(p), f = fract(p); f = f * f * (3. - 2. * f);
  return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y);
}
void main() {
  vec2 p = uv * res;
  vec2 bc = vec2(220., 478.);
  float R = 520.;
  float d = length(p - bc);
  // The water: a deep blue-green that darkens towards the rim, lit faintly from above.
  vec3 deep = vec3(.010, .026, .036), mid = vec3(.022, .060, .074);
  vec3 col = mix(mid, deep, smoothstep(60., R, d));
  // A slow surface shimmer: broad patches of light drifting in two directions, never swirling.
  float tt = rm > .5 ? 0. : t;
  float a = n(p * .0055 + vec2(tt * .000021, tt * .000013));
  float b = n(p * .0090 + vec2(-tt * .000017, tt * .000024) + 7.3);
  float sh = smoothstep(.42, .9, a * .65 + b * .55);
  col += vec3(.040, .090, .100) * sh * .55;
  // The rim: stone beyond, with a soft wet highlight at the water's edge.
  float stone = smoothstep(R - 1., R + 3., d);
  col = mix(col, vec3(.020, .024, .028) + .012 * n(p * .08), stone);
  float lip = exp(-pow((d - R) / 3.5, 2.));
  float lit = .55 + .45 * cos(atan(p.y - bc.y, p.x - bc.x) + 2.3);
  col += vec3(.30, .44, .48) * lip * .45 * lit;
  col *= 1. - .35 * smoothstep(R - 140., R - 2., d) * (1. - stone);
  // The drain: a dark well with a faint lit lip.
  float dd = length(p - drain);
  col *= mix(1., .10 + .90 * smoothstep(30., 78., dd), drainA);
  col += vec3(.26, .40, .44) * drainA * exp(-pow((dd - 44.) / 2.2, 2.)) * .30;
  // The moon's reflection: a pale disc whose edge trembles a little on the water.
  float md = length(p - moon) - 28. - (rm > .5 ? 0. : .45 * sin(atan(p.y - moon.y, p.x - moon.x) * 3. + t * .0015));
  col += vec3(.95, .91, .82) * moonA * (smoothstep(1.5, -1.5, md) * .78 + exp(-max(md, 0.) / 26.) * .10);
  // The tank seats in the water: a soft shadow ring and a little light thrown off the glass.
  float td = length(p - tank.xy) - tank.z;
  col *= 1. - tankA * .55 * exp(-max(td, 0.) / 22.) * step(0., td);
  col += vec3(.06, .10, .12) * tankA * exp(-max(td - 6., 0.) / 60.) * step(0., td) * .6;
  // The solve's ripple: one ring spreading out from the glass and fading.
  float rr = tank.z + 10. + rip * 360.;
  col += vec3(.40, .62, .66) * ripA * (1. - rip) * exp(-pow((length(p - tank.xy) - rr) / 3., 2.)) * .55;
  col += vec3(.20, .34, .38) * ripA * (1. - rip) * exp(-pow((length(p - tank.xy) - rr * .82) / 2., 2.)) * .3;
  col *= 1. - dim;
  o = vec4(col, 1.);
}`;

function draw(ctx, t) {
  const menuA = fade(t, T.menuIn, T.menuOut);
  const playA = fade(t, T.playIn, T.playOut);
  const resA = fade(t, T.resultIn, T.resultOut);
  const todayA = fade(t, T.todayIn, T.todayOut);
  const packA = fade(t, T.packIn, T.packOut);
  const prismA = fade(t, T.prismIn, T.prismOut);
  const today2A = ease(ramp(t, T.today2In[0], T.today2In[1]));
  const setA = ease(ramp(t, T.setStart - 100, T.setStart + 500));
  const dim = ease(ramp(t, T.setStart - 200, T.setStart + 800)) * 0.93;
  drawMenu(ctx, t, menuA);
  drawGrow(ctx, t);
  drawPlay(ctx, t, playA, {
    glass: 'play01', num: '01', title: 'Drop', count: 'moves 0 / par 1', undo: 'undo · 10',
    note: ['Turn a rod to look.', 'Let go where you started and nothing happens.'],
  });
  drawResult(ctx, t, resA);
  drawToday(ctx, t, todayA, { lift: 3, liftT: ramp(t, T.padStart, T.padEnd) });
  drawPack(ctx, t, packA);
  drawPlay(ctx, t, prismA, {
    glass: 'prism01', num: '01', pack: 'prism', title: 'Frond', count: 'moves 0 / par 3', undo: 'undo · 10',
    note: ['Each rod stirs only its knob’s colours.'],
  });
  drawToday(ctx, t, today2A, { dim });
  drawSettings(ctx, t, setA);
  // The status bar, as the phone draws it.
  const s = World.images.status;
  if (s) ctx.drawImage(s, 0, 0, W, 54);
}

window.DRAWS_AX = true;
World.load(['play01', 'drain-solved', 'prism01', 'prism-clip', 'cover-first-stir', 'cover-lens', 'cover-escapement',
  'cover-prism', 'cover-triptych', 'status']).then(() => World.start({
  fonts: ['300 28px NY', 'italic 300 28px NY', '400 17px UPro', '200 34px UPro', '600 17px UPro'],
  shader, uniforms, draw,
  duration: T.end,
  shots: { menu: 2400, play: 9000, result: 13300, 'menu-today': 16700, pack: 20600, prism: 23200, settings: 26800 },
}));
