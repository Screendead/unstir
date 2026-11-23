// Copyright © 2026 Jack Lusher. All rights reserved.
// Ink: every word around the tank is ink in still water. It arrives as a drop that blooms and condenses into crisp
// letters, and leaves by dissolving into a pale haze that clears. Nothing turns or swirls: the stir is the game's own.
// The ground is one shader pass (deep ink-blue water, a faint wash of the tier's inks, slow suspended motes); the
// words, drops and glass are drawn over it. Times are ms on one timeline: the film, then two scenes kept for stills.

// W and H come from lib.js.
const RM = World.rm;
const M = 40;                       // the page's margin
const PI = Math.PI;
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const smooth = (a, b, x) => { const u = clamp((x - a) / (b - a)); return u * u * (3 - 2 * u); };

// Inks. A tier writes in its own three; a pack in its own.
const INK = {
  plughole: ['#47e4ff', '#ff62da', '#ffb64e'],
  whirlpool: ['#ff5468', '#ff5ccf', '#a874ff'],
  prism: ['#ff4040', '#40ff70', '#5582ff'],
  lens: ['#47e4ff', '#ff62da', '#ffe14e'],
  escapement: ['#f1e7d2', '#ff5a44', '#f1e7d2'],
  triptych: ['#ecc66e', '#47e4ff', '#ff5a44'],
  white: ['#f3f1ec', '#f3f1ec', '#f3f1ec'],
};
const PAPER = '#ece9e2';            // the ink of plain words: warm white, never pure
// A level's own ink: the tier's hue walk, light for words already solved, full for the one to play next.
const walk = (n, light) => `oklch(${light ? 0.88 : 0.8} ${light ? 0.07 : 0.16} ${(190 + 240 * ((n - 1) % 12) / 11) % 360})`;

// Sizes never fall under today's role for the same job, at any type size.
const sz = (base, role) => Math.max(base, World.pt(role));
const font = (size, { italic = false, weight = 400 } = {}) => `${italic ? 'italic ' : ''}${weight} ${size}px NY`;

// ---------------------------------------------------------------------------------------------------------------
// Elements. Each arrives over `dur` ms after its scene's start plus `delay`, and leaves with its scene.

function text(str, x, y, o = {}) {
  return { kind: 'text', str, x, y, size: o.size || 17, italic: !!o.italic, weight: o.weight || 400,
    ink: o.ink || PAPER, inks: o.inks, align: o.align || 'left', alpha: o.alpha ?? 1, delay: o.delay || 0,
    dur: o.dur || 1700, haze: !!o.haze, under: !!o.under, from: o.from, register: o.register, glow: o.glow ?? 0.4 };
}
function drops(x, y, n, ink, o = {}) {
  return { kind: 'drops', x, y, n, ink, r: o.r || 2.4, gap: o.gap || 8, delay: o.delay || 0, dur: o.dur || 1500,
    alpha: o.alpha ?? 1, stagger: o.stagger || 0, count: o.count || 3 };
}
function glass(name, cx, cy, d, o = {}) {
  return { kind: 'glass', name, cx, cy, d, delay: o.delay || 0, dur: o.dur || 1400, ink: o.ink || INK.plughole[0],
    blot: !!o.blot, from: o.from };
}

// The ink's state at arrival progress a (0..1, may run past 1) and dissolve progress d (0..1).
function state(a, d) {
  if (RM) return { alpha: clamp(a * 4) * (1 - d), blur: 0, cloud: 0, haze: 0, k: 1 };
  const k = World.ease(a);
  return {
    alpha: smooth(0.08, 0.7, a) * (1 - d),
    blur: 11 * Math.pow(1 - clamp(k), 2) + 15 * d * d,
    cloud: 0.3 * Math.sin(PI * clamp(a * 1.15)),
    haze: 0.16 * Math.sin(PI * d),
    k: clamp(k),
  };
}

function measure(ctx, el) {
  ctx.font = font(el.size, el);
  return ctx.measureText(el.str).width;
}

function inkCloud(ctx, x, y, r, colour, alpha) {
  if (alpha <= 0.002 || r <= 0) return;
  const g = ctx.createRadialGradient(x, y, 0, x, y, r);
  g.addColorStop(0, colour);
  g.addColorStop(0.45, colour);
  g.addColorStop(1, 'rgba(0,0,0,0)');
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.globalCompositeOperation = 'screen';
  ctx.filter = `blur(${Math.max(2, r * 0.25)}px)`;
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.ellipse(x, y, r, r * 0.72, 0, 0, 2 * PI); ctx.fill();
  ctx.restore();
}

// A soft brush stroke under a word: a curve thick in the middle, tapering to nothing, never a rule.
function brush(ctx, x0, x1, y, colour, alpha) {
  const w = x1 - x0, sag = 2.2;
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.fillStyle = colour;
  ctx.beginPath();
  ctx.moveTo(x0, y);
  ctx.bezierCurveTo(x0 + w * 0.3, y + sag + 1.4, x0 + w * 0.7, y + sag + 1.2, x1, y - 0.6);
  ctx.bezierCurveTo(x0 + w * 0.7, y + sag - 0.1, x0 + w * 0.3, y + sag, x0, y);
  ctx.fill();
  ctx.restore();
}

function drawText(ctx, el, a, d) {
  const s = state(a, d);
  ctx.font = font(el.size, el);
  const w = ctx.measureText(el.str).width;
  const x = el.align === 'center' ? el.x - w / 2 : el.align === 'right' ? el.x - w : el.x;
  const cy = el.y - el.size * 0.32;
  const inks = el.inks || [el.ink, el.ink, el.ink];
  // The drop: a cloud that blooms from where it fell towards the word, then thins as the letters condense.
  if (s.cloud > 0) {
    const fx = el.from ? World.mix(el.from[0], x + w / 2, s.k) : x + w / 2;
    const fy = el.from ? World.mix(el.from[1], cy, s.k) : cy;
    const r = World.mix(6, Math.max(w * 0.62, el.size * 1.1), World.ease(clamp(a * 1.3)));
    // Plain words bloom from a faint blue-grey drop; a white cloud would read as a smudge.
    const plain = !el.inks && !el.register && /^#(ece9e2|f4f2ee|f6f5f2|f3f1ec)$/i.test(el.ink);
    inkCloud(ctx, fx, fy, r, plain ? '#7f93c4' : inks[1], s.cloud * el.alpha * (el.haze ? 0.5 : plain ? 0.4 : 1));
  }
  if (s.haze > 0) inkCloud(ctx, x + w / 2, cy, w * 0.6 + 12, '#c9d2e6', s.haze * el.alpha);
  let alpha = s.alpha * el.alpha;
  if (alpha <= 0.003) return;
  let fill;
  if (el.inks) {
    fill = ctx.createLinearGradient(x, 0, x + w, 0);
    el.inks.forEach((c, i) => fill.addColorStop(i / (el.inks.length - 1), c));
  } else fill = el.ink;
  ctx.save();
  ctx.textBaseline = 'alphabetic';
  if (el.haze) { ctx.filter = `blur(${4.2 + s.blur}px)`; alpha *= 1; }
  else if (s.blur > 0.05) ctx.filter = `blur(${s.blur}px)`;
  if (el.register) {
    // Three inks printed slightly off register, meeting in white where they overlap.
    ctx.globalCompositeOperation = 'screen';
    const off = el.register;
    [[INK.prism[0], -off, 0.4], [INK.prism[1], off * 0.8, -off * 0.5], [INK.prism[2], 0.2, off * 0.7]].forEach(([c, dx, dy]) => {
      ctx.globalAlpha = alpha;
      ctx.fillStyle = c;
      ctx.shadowColor = c; ctx.shadowBlur = 14 * s.k;
      ctx.fillText(el.str, x + dx, el.y + dy);
    });
  } else {
    ctx.globalAlpha = alpha;
    ctx.fillStyle = fill;
    // Ink bleeds a little into the water around each letter.
    if (!el.haze && el.glow > 0) { ctx.shadowColor = inks[1]; ctx.shadowBlur = 9; }
    ctx.globalAlpha = alpha;
    ctx.fillText(el.str, x, el.y);
    if (!el.haze && el.glow > 0) { ctx.shadowBlur = 0; ctx.globalAlpha = alpha * (1 - el.glow); ctx.fillText(el.str, x, el.y); }
  }
  ctx.restore();
  if (el.under) brush(ctx, x + 1, x + w - 1, el.y + el.size * 0.32, inks[1], 0.55 * alpha * s.k);
  return w;
}

function drawDrops(ctx, el, a, d) {
  for (let i = 0; i < el.count; i++) {
    const ai = a - (el.stagger * i) / el.dur;
    const s = state(ai, d);
    const alpha = s.alpha * el.alpha;
    if (alpha <= 0.003) continue;
    const x = el.x + i * el.gap, y = el.y;
    const r = el.r * (RM ? 1 : World.mix(1.9, 1, s.k));
    ctx.save();
    ctx.globalAlpha = alpha;
    if (s.blur > 0.05) ctx.filter = `blur(${s.blur * 0.4}px)`;
    if (i < el.n) {
      ctx.fillStyle = el.ink;
      ctx.shadowColor = el.ink; ctx.shadowBlur = el.r * 2.5;
      ctx.beginPath(); ctx.arc(x, y, r, 0, 2 * PI); ctx.fill();
    } else {
      ctx.strokeStyle = el.ink; ctx.lineWidth = Math.max(1, el.r * 0.38);
      ctx.globalAlpha = alpha * 0.85;
      ctx.beginPath(); ctx.arc(x, y, r - ctx.lineWidth / 2, 0, 2 * PI); ctx.stroke();
    }
    ctx.restore();
  }
}

function drawGlass(ctx, el, a, d) {
  const s = state(a, d);
  // A halo of ink in the water behind the glass; nothing is ever drawn over it.
  const cx = el.from ? World.mix(el.from[0], el.cx, World.ease(clamp(a * 1.1))) : el.cx;
  const cy = el.from ? World.mix(el.from[1], el.cy, World.ease(clamp(a * 1.1))) : el.cy;
  const size = el.from && !RM ? World.mix(el.d * 0.25, el.d, World.ease(clamp(a * 1.1))) : el.d;
  if (s.cloud > 0) inkCloud(ctx, cx, cy, size * 0.7, el.ink, s.cloud * 0.8);
  if (s.haze > 0) inkCloud(ctx, cx, cy, size * 0.6, '#c9d2e6', s.haze);
  const alpha = RM ? s.alpha : smooth(0.15, 0.75, a) * (1 - d);
  if (alpha <= 0.003) return;
  if (el.blot) {
    // A pack's cover as a round ink blot: its own picture, its edge feathered into the water.
    const im = World.images[el.name];
    if (!im) return;
    const off = document.createElement('canvas');
    const px = Math.ceil(size * 2);
    off.width = off.height = px;
    const o = off.getContext('2d');
    o.drawImage(im, 0, 0, px, px);
    o.globalCompositeOperation = 'destination-in';
    const g = o.createRadialGradient(px / 2, px / 2, px * 0.32, px / 2, px / 2, px / 2);
    g.addColorStop(0, '#000'); g.addColorStop(1, 'rgba(0,0,0,0)');
    o.fillStyle = g; o.fillRect(0, 0, px, px);
    ctx.save();
    ctx.globalAlpha = alpha;
    if (s.blur > 0.05) ctx.filter = `blur(${s.blur * 0.5}px)`;
    ctx.drawImage(off, cx - size / 2, cy - size / 2, size, size);
    ctx.restore();
  } else {
    World.disc(ctx, el.name, cx, cy, size, alpha);
  }
}

function drawEl(ctx, el, a, d) {
  if (a <= 0) return;
  if (el.kind === 'text') drawText(ctx, el, a, d);
  else if (el.kind === 'drops') drawDrops(ctx, el, a, d);
  else if (el.kind === 'glass') drawGlass(ctx, el, a, d);
}

// ---------------------------------------------------------------------------------------------------------------
// Layout helpers.

// A passage of words, each perhaps followed by its marks, set like prose: wrapped, never ruled into rows.
function passage(ctx, items, x0, x1, y, o = {}) {
  const size = o.size, lead = o.lead || size * 2.05, els = [];
  ctx.font = font(size, o);
  const space = ctx.measureText(' ').width * (o.spaceMul || 2.6);
  let x = x0, line = 0;
  const rows = [[]];
  for (const it of items) {
    const w = ctx.measureText(it.str).width;
    if (x + w > x1 && x > x0) { x = x0; line++; rows.push([]); }
    rows[line].push({ it, x, w });
    x += w + space;
  }
  rows.forEach((row, li) => {
    // A ragged left edge, a little like hand-set type: each line starts a touch in or out.
    const indent = o.ragged ? [0, 14, 4, 20, 8, 0, 16][li % 7] : 0;
    row.forEach(({ it, x }, k) => {
      const yy = y + li * lead;
      const delay = (o.delay || 0) + (li * 4 + k) * (o.step ?? 90);
      els.push(text(it.str, x + indent, yy, { size, italic: o.italic, ink: it.ink, alpha: it.alpha ?? 1,
        delay, haze: it.haze, glow: it.haze ? 0 : 0.35 }));
      if (it.marks !== undefined) {
        ctx.font = font(size, o);
        const wx = ctx.measureText(it.str).width;
        // The marks sit under the word, centred, like a diacritic: one to three drops, hollow where not earned.
        els.push(drops(x + indent + wx / 2 - 6, yy + size * 0.42, it.marks, it.markInk || it.ink, { r: 1.7, gap: 6,
          delay: delay + 300, alpha: 0.85 }));
      }
    });
  });
  return { els, bottom: y + (rows.length - 1) * lead };
}

function wrapLines(ctx, str, width, size, o = {}) {
  ctx.font = font(size, o);
  const words = str.split(' '), lines = [];
  let cur = '';
  for (const w of words) {
    const tryLine = cur ? cur + ' ' + w : w;
    if (ctx.measureText(tryLine).width > width && cur) { lines.push(cur); cur = w; } else cur = tryLine;
  }
  if (cur) lines.push(cur);
  return lines;
}

// ---------------------------------------------------------------------------------------------------------------
// Scenes: what each page holds, laid out at draw time so accessibility type reflows it.

const PLUG_NAMES = ['Drop', 'Drip', 'Trickle', 'Ripple', 'Bubble', 'Fizz', 'Sprinkle', 'Mist', 'Spray', 'Splash',
  'Puddle', 'Froth', 'Suds', 'Lather', 'Steam', 'Gurgle', 'Rinse', 'Drizzle', 'Shower', 'Downpour', 'Overflow',
  'Bathwater', 'Spin', 'Whirl', 'Spiral', 'Last drop', 'Drain'];
const WHIRL_NAMES = ['Spring', 'Headwaters', 'Creek', 'Brook', 'Stream', 'Shallows', 'Stepping stone', 'Riverbend',
  'Millpond', 'Dam', 'Floodgate', 'Water wheel', 'Rapids', 'Cascade'];
const PACKS = [['lens', 'Lens', true], ['escapement', 'Escapement', true], ['prism', 'Prism', true],
  ['triptych', 'Triptych I', false]];

const pos = {};   // where things landed, for fingers and drops that start from them

function head(ctx, els, o = {}) {
  const y = 98;
  els.push(text('Unstir', M, y, { size: sz(26, 'headline'), italic: true, weight: 500, inks: INK.plughole, delay: 0 }));
  els.push(text('settings', W - M, y, { size: sz(15, 'label'), italic: true, ink: PAPER, alpha: 0.72, align: 'right',
    delay: 200, glow: 0 }));
  pos.settings = [W - M - 30, y - 6];
}

function dock(ctx, els, y0, delay) {
  const d = 62, n = PACKS.length, gap = (W - 2 * M - d) / (n - 1);
  PACKS.forEach(([key, name, fresh], i) => {
    const cx = M + d / 2 + gap * i, cy = y0 + (i % 2 ? 10 : 0);
    els.push(glass('cover-' + key, cx, cy, d, { blot: true, delay: delay + i * 160, ink: INK[key][1] }));
    const ty = cy + d / 2 + sz(15, 'label') + 4;
    els.push(text(name, cx, ty, { size: sz(15, 'label'), italic: true, inks: key === 'prism' ? INK.prism : null,
      ink: INK[key][key === 'escapement' ? 0 : 1], align: 'center', delay: delay + i * 160 + 200, glow: 0.25 }));
    if (fresh) els.push(drops(cx + measureLabel(ctx, name) / 2 + 8, ty - 5, 1, INK[key][1], { r: 2.2, count: 1, delay: delay + i * 160 + 500 }));
    pos['pack-' + key] = [cx, cy];
  });
}
function measureLabel(ctx, s) { ctx.font = font(sz(15, 'label'), { italic: true }); return ctx.measureText(s).width; }

// The menu, mid-way: 01 to 13 solved at par with a stir undone, 14 next, the rest still undissolved ink.
function menuMid(ctx) {
  const els = [];
  head(ctx, els);
  const T = sz(58, 'display'), Lb = sz(15, 'label'), B = sz(17, 'body');
  const ty = 98 + T * 1.6, sy = ty + Lb + 16;
  els.push(text('plughole', M - 3, ty, { size: T, italic: true, weight: 300, inks: INK.plughole, delay: 250, dur: 2000 }));
  els.push(text('13 of 27 at par', M, sy, { size: Lb, italic: true, alpha: 0.72, delay: 600, glow: 0 }));
  // The next tier waits at the page's edge, its ink not yet condensed.
  els.push(text('whirlpool', W - 52, 132, { size: sz(26, 'headline'), italic: true, weight: 300, inks: INK.whirlpool,
    align: 'left', alpha: 0.55, haze: true, delay: 900 }));
  const items = PLUG_NAMES.slice(0, 13).map((s, i) => ({ str: s, ink: walk(i + 1, true), marks: 2, markInk: walk(i + 1, false) }));
  const p = passage(ctx, items, M, W - M, sy + Math.max(84, B * 2.8), { size: B, delay: 500, step: 70, ragged: true, spaceMul: 3.4, lead: B * 2.5 });
  els.push(...p.els);
  pos.drop = [M + 20, 284];
  // The one to play next, large and fully inked.
  let y = p.bottom + Math.max(96, Lb * 2 + sz(52, 'display') * 1.05);
  els.push(text('14', M, y - sz(52, 'display') * 0.86, { size: sz(15, 'label'), italic: true, ink: walk(14, false), delay: 1300, glow: 0.2 }));
  els.push(text('Lather', M - 2, y, { size: sz(52, 'display'), italic: true, weight: 300, ink: walk(14, false), delay: 1200, dur: 2100 }));
  els.push(text('4 rods · par 4', M, y + sz(15, 'label') + 14, { size: sz(15, 'label'), italic: true, alpha: 0.78, delay: 1500, glow: 0 }));
  pos.lather = [M + 80, y - 18];
  // The rest: ink still suspended, not yet words.
  y += Math.max(96, Lb * 2 + B * 2.6);
  const locked = PLUG_NAMES.slice(14, 22).map((s) => ({ str: s, ink: '#cfd6ea', alpha: 0.32, haze: true }));
  const q = passage(ctx, locked, M, W - M, y, { size: sz(17, 'body'), delay: 1500, step: 50, spaceMul: 3.4, ragged: true, lead: sz(17, 'body') * 2.3 });
  els.push(...q.els);
  els.push(text('the rest settle into words as you solve', M, q.bottom + 44, { size: sz(13, 'detail'), italic: true,
    alpha: 0.7, delay: 1900, glow: 0 }));
  if (!World.ax) dock(ctx, els, 846, 1600);
  return els;
}

// Whirlpool, still locked: its name inked, its levels haze.
function menuWhirl(ctx) {
  const els = [];
  head(ctx, els);
  const T = sz(58, 'display');
  els.push(text('whirlpool', M - 3, 190, { size: T, italic: true, weight: 300, inks: INK.whirlpool, delay: 150, dur: 2000 }));
  els.push(text('opens when every plughole level is solved', M, 190 + sz(15, 'label') + 16, { size: sz(15, 'label'),
    italic: true, alpha: 0.75, delay: 400, glow: 0 }));
  els.push(text('plughole', 50, 132, { size: sz(26, 'headline'), italic: true, weight: 300, inks: INK.plughole,
    align: 'right', alpha: 0.6, delay: 700 }));
  els.push(text('vortex', W - 40, 132, { size: sz(26, 'headline'), italic: true, weight: 300, inks: ['#7a6bff', '#3d7bff', '#2ad6c2'],
    align: 'left', alpha: 0.5, haze: true, delay: 800 }));
  const locked = WHIRL_NAMES.map((s) => ({ str: s, ink: '#e7c9d8', alpha: 0.3, haze: true }));
  const q = passage(ctx, locked, M, W - M, 300, { size: sz(17, 'body'), delay: 600, step: 50, spaceMul: 3.4, ragged: true, lead: sz(17, 'body') * 2.4 });
  els.push(...q.els);
  dock(ctx, els, 846, 900);
  return els;
}

// The menu with every plughole level at par: today's three sentences, the finished passage, the next tier open.
function menuToday(ctx) {
  const els = [];
  head(ctx, els);
  const B = sz(17, 'body');
  let y = 172;
  const daily = 'Today’s daily, four days running.';
  els.push(text(daily, M, y, { size: sz(22, 'headline'), italic: true, inks: [INK.plughole[2], '#ffd27a', INK.plughole[2]], delay: 200 }));
  const ctxw = (() => { ctx.font = font(sz(22, 'headline'), { italic: true }); return ctx.measureText(daily).width; })();
  els.push(drops(M + ctxw + 10, y - 7, 2, INK.plughole[2], { r: 2.6, gap: 9, delay: 700 }));
  y += sz(22, 'headline') * 1.6;
  els.push(text('Endless, best nine.', M, y, { size: B, italic: true, ink: INK.plughole[0], delay: 400 }));
  y += B * 1.8;
  els.push(text('The archive comes with any pack.', M, y, { size: B, italic: true, ink: PAPER, alpha: 0.72, delay: 550, glow: 0 }));
  y += 92;
  els.push(text('plughole', M - 3, y, { size: sz(58, 'display'), italic: true, weight: 300, inks: INK.plughole, delay: 500, dur: 2000 }));
  els.push(text('27 of 27 at par', M, y + sz(15, 'label') + 16, { size: sz(15, 'label'), italic: true, alpha: 0.72, delay: 700, glow: 0 }));
  const items = PLUG_NAMES.map((s, i) => ({ str: s, ink: walk(i + 1, true), marks: 3, markInk: walk(i + 1, false) }));
  const p = passage(ctx, items, M, W - M, y + 80, { size: B, delay: 800, step: 40, ragged: true, spaceMul: 3, lead: B * 2.3 });
  els.push(...p.els);
  y = p.bottom + 84;
  els.push(text('up a notch', M, y - sz(34, 'title') * 0.95, { size: sz(13, 'detail'), italic: true, alpha: 0.72, delay: 1700, glow: 0 }));
  els.push(text('whirlpool ›', M - 2, y, { size: sz(34, 'title'), italic: true, weight: 300, inks: INK.whirlpool, delay: 1600, dur: 2000 }));
  els.push(text('Spring, 3 rods · par 2', M, y + sz(15, 'label') + 12, { size: sz(15, 'label'), italic: true, alpha: 0.75, delay: 1900, glow: 0 }));
  dock(ctx, els, 856, 2000);
  return els;
}

// A level in play: the glass on the page, its name above, its count and note below, two inked words at the foot.
function play(ctx, o) {
  const els = [];
  const L = sz(17, 'body');
  els.push(text('‹ levels', M, 98, { size: L, italic: true, alpha: 0.85, delay: 0, glow: 0 }));
  const titleSize = sz(34, 'display');
  const numY = 140, titleY = numY + titleSize + 6;
  els.push(text(o.num, W / 2, numY, { size: sz(15, 'label'), italic: true, ink: o.numInk, align: 'center', delay: 100,
    glow: o.white ? 0.5 : 0.2 }));
  els.push(text(o.title, W / 2, titleY, { size: titleSize, italic: true, weight: 300, ink: o.ink, align: 'center',
    delay: 50, dur: 1900, from: o.from }));
  // The glass: as large as the page allows under its words, never bigger than today's 403 pt.
  const foot = H - 64;
  const below = sz(15, 'label') * 1.9 + o.noteLines(ctx).length * L * 1.55 + 40;
  const top = titleY + 34;
  const d = Math.min(403, foot - 60 - below - top);
  const cy = top + d / 2;
  els.push(glass(o.glass, W / 2, cy, d, { delay: 250, ink: o.ink }));
  let y = cy + d / 2 + 34;
  els.push(text(o.count, W / 2, y, { size: sz(15, 'label'), italic: true, align: 'center', alpha: 0.75, delay: 700, glow: 0 }));
  y += L * 1.9;
  o.noteLines(ctx).forEach((ln, i) => {
    els.push(text(ln, W / 2, y + i * L * 1.55, { size: L, align: 'center', alpha: 0.9, delay: 900 + i * 120, glow: 0.2 }));
  });
  els.push(text('undo · 10', M, foot, { size: L, italic: true, alpha: 0.62, under: true, delay: 1200, glow: 0 }));
  els.push(text('reset', W - M, foot, { size: L, italic: true, alpha: 0.9, under: true, align: 'right', delay: 1300, glow: 0 }));
  return els;
}
const playDrop = (ctx) => play(ctx, {
  num: '01', title: 'Drop', ink: walk(1, false), numInk: walk(1, false), glass: 'play01', count: 'moves 0 / par 1',
  from: pos.drop,
  noteLines: (c) => wrapLines(c, 'Turn a rod to look. Let go where you started and nothing happens.', W - 2 * M - 30, sz(17, 'body')),
});
const playPrism = (ctx) => play(ctx, {
  num: '01', title: 'Frond', ink: '#f6f5f2', numInk: '#ffffff', white: true, glass: 'prism01', count: 'moves 0 / par 3',
  noteLines: (c) => wrapLines(c, 'Each rod stirs only its knob’s colours.', W - 2 * M - 30, sz(17, 'body')),
});

// The result: "unstirred." blooms from a drop over the solved glass; the marks fall as drops.
function result(ctx) {
  const els = [];
  const B = sz(17, 'body'), D = sz(13, 'detail'), U = sz(44, 'display'), N = sz(30, 'title');
  els.push(text('‹ levels', M, 98, { size: B, italic: true, alpha: 0.85, glow: 0 }));
  const titleY = World.ax ? 98 + B * 1.5 : 98;
  els.push(text('27  Drain', World.ax ? M : W / 2, titleY, { size: B, italic: true, ink: walk(27, true),
    align: World.ax ? 'left' : 'center', delay: 100, glow: 0.2 }));
  const uy = titleY + 108 + (World.ax ? U * 0.3 : 0);
  els.push(text('unstirred.', W / 2, uy, { size: U, italic: true, weight: 300, ink: '#f4f2ee', align: 'center',
    delay: 500, dur: 2300, glow: 0.45 }));
  // From the foot up: the two ways on, then the words, then the glass takes what is left (never more than 384).
  const foot = H - 56;
  const sent = wrapLines(ctx, 'at par, and a new best (it was +6).', W - 2 * M, B, { italic: true });
  const hint = wrapLines(ctx, 'clean needs no undo or reset', W - 2 * M, D, { italic: true });
  const block = 16 + 34 + sent.length * B * 1.45 + hint.length * D * 1.5 + 12;
  const footTop = foot - N - D * 1.4 - 28;
  const top = uy + 36;
  const d = Math.min(384, footTop - block - top - 26);
  const cy = World.ax ? top + d / 2 : 467;
  els.push(glass('drain-solved', W / 2, cy, d, { delay: 0, ink: INK.plughole[1] }));
  let y = cy + d / 2 + 30;
  els.push(drops(W / 2 - 16, y, 2, '#f4f2ee', { r: 5, gap: 16, delay: 1300, dur: 1300, stagger: 260 }));
  y += 40;
  sent.forEach((ln, i) => els.push(text(ln, W / 2, y + i * B * 1.45, { size: B, italic: true, align: 'center', delay: 1900, glow: 0.2 })));
  y += (sent.length - 1) * B * 1.45 + D * 1.9;
  hint.forEach((ln, i) => els.push(text(ln, W / 2, y + i * D * 1.5, { size: D, italic: true, align: 'center', alpha: 0.7, delay: 2200, glow: 0 })));
  els.push(text('again', M, foot, { size: B, italic: true, alpha: 0.8, under: true, delay: 2500, glow: 0 }));
  els.push(text('up a notch', W - M, foot - N - 6, { size: D, italic: true, alpha: 0.72, align: 'right', delay: 2500, glow: 0 }));
  els.push(text('whirlpool ›', W - M, foot, { size: N, italic: true, weight: 300, inks: INK.whirlpool, align: 'right',
    delay: 2300, dur: 2100 }));
  return els;
}

// Prism's pack, unowned: an editorial spread, its name printed off register.
function pack(ctx) {
  const els = [];
  const B = sz(17, 'body'), Lb = sz(15, 'label'), D = sz(13, 'detail'), N = sz(30, 'title'), P = sz(88, 'display');
  const wrap = (str, size, o, x, y, lead, el) => {
    const ls = wrapLines(ctx, str, W - 2 * M, size, o);
    ls.forEach((ln, i) => els.push(text(ln, x, y + i * lead, { size, ...o, ...el })));
    return y + (ls.length - 1) * lead;
  };
  els.push(text('‹ menu', M, 98, { size: B, italic: true, alpha: 0.85, glow: 0 }));
  pos.menu = [M + 26, 92];
  let y = 206;
  els.push(text('Prism', M - 4, y, { size: P, italic: true, weight: 400, register: 2.4, delay: 200, dur: 2200 }));
  y = wrap('each rod stirs only some colours', B, { italic: true }, M, y + B * 2.3, B * 1.4, { alpha: 0.88, delay: 600, glow: 0.2 });
  // The plate: as large as the page leaves room for, never larger than 270.
  const rest = World.ax ? 220 : 270;
  const d = rest;
  const cy = y + 28 + d / 2;
  els.push(glass('prism-clip', World.ax ? W / 2 : W / 2 + 26, cy, d, { delay: 300, ink: '#9aa0ff', from: pos['pack-prism'] }));
  y = cy + d / 2 + 50;
  y = wrap('30 specimens in five trays.', B, {}, M, y, B * 1.45, { delay: 1100, glow: 0.2 });
  y = wrap('Levels 1–3 free, no purchase.', B, {}, M, y + B * 1.6, B * 1.45, { delay: 1250, glow: 0.2 });
  y = wrap('letters for colour-blind play, in settings', D, { italic: true }, M, y + B * 1.5, D * 1.5, { alpha: 0.72, delay: 1400, glow: 0 });
  y += N * 2.2;
  els.push(text('buy $2.99', M, y, { size: N, italic: true, weight: 400, ink: '#f6f5f2', under: true, delay: 1500, glow: 0.5 }));
  if (World.ax) y += B * 2.2;
  els.push(text('try 3 free ›', World.ax ? M : W - M, y, { size: B, italic: true, align: World.ax ? 'left' : 'right', alpha: 0.9, under: true, delay: 1650, glow: 0 }));
  y = wrap('or all three in Triptych I · $5.99 · save $2.98 ›', Lb, { italic: true }, M, y + Lb * 3.3, Lb * 1.5,
    { ink: INK.triptych[0], alpha: 0.9, delay: 1800, glow: 0 });
  y = wrap('restore purchases', D, { italic: true }, M, y + Lb * 2.3, D * 1.5, { alpha: 0.7, delay: 1900, glow: 0 });
  wrap('two colours — Frond, Bracken, Fiddlehead, Maidenhair, Spore, Tree fern', Lb, { italic: true }, M, Math.max(y + Lb * 3.4, 890), Lb * 1.6,
    { alpha: 0.8, delay: 2000, glow: 0 });
  return els;
}

// Settings: a short letter, each state a word that can be re-inked by a tap.
function settings(ctx) {
  const els = [];
  els.push(text('‹ menu', M, 98, { size: sz(17, 'body'), italic: true, alpha: 0.85, glow: 0 }));
  const S = sz(26, 'title'), lead = S * 1.45, gap = S * 0.55;
  let y = 236;
  const line = (lead_, state, on, delay) => {
    // The sentence wraps like prose; its state word stays with the last line when it fits.
    ctx.font = font(S, { weight: 300 });
    const lines = wrapLines(ctx, lead_.trim(), W - 2 * M, S, { weight: 300 });
    const last = lines[lines.length - 1] + ' ';
    ctx.font = font(S, { weight: 300 });
    const lw = ctx.measureText(last).width;
    ctx.font = font(S, { italic: true });
    const sw = ctx.measureText(state).width;
    lines.forEach((ln, i) => els.push(text(i === lines.length - 1 ? last : ln, M, y + i * lead, { size: S, weight: 300, delay, glow: 0.15 })));
    let sx = M + lw, sy = y + (lines.length - 1) * lead;
    if (sx + sw > W - M) { sx = M; sy += lead; }
    els.push(text(state, sx, sy, { size: S, italic: true, weight: 400, ink: on ? INK.plughole[0] : '#aeb6c8', under: true,
      delay: delay + 250, glow: on ? 0.5 : 0 }));
    y = sy + lead + gap;
  };
  line('Music is', 'on.', true, 200);
  line('Sounds are', 'on.', true, 380);
  line('Haptics are', 'on.', true, 560);
  line('Colour letters are', 'off.', false, 740);
  const Lb = sz(15, 'label');
  const fine = wrapLines(ctx, 'R, G and B on Prism’s knobs', W - 2 * M, Lb, { italic: true });
  fine.forEach((ln, i) => els.push(text(ln, M, y - gap - lead + S * 0.5 + Lb + i * Lb * 1.5, { size: Lb, italic: true, alpha: 0.7, delay: 1000, glow: 0 })));
  y += fine.length * Lb * 1.5 + 30;
  const L = sz(17, 'body');
  els.push(text('Restore purchases.', M, y, { size: L, italic: true, alpha: 0.9, under: true, delay: 1200, glow: 0 }));
  els.push(text('Report a problem ↗', M, y + L * 2.2, { size: L, italic: true, alpha: 0.9, ink: INK.plughole[2], delay: 1350, glow: 0 }));
  els.push(text('Privacy policy ↗', M, y + L * 4.4, { size: L, italic: true, alpha: 0.9, ink: INK.plughole[2], delay: 1500, glow: 0 }));
  els.push(text('Unstir 1.0 (1)', M, Math.max(H - 70, y + L * 4.4 + sz(13, 'detail') * 2.4), { size: sz(13, 'detail'), italic: true, alpha: 0.65, delay: 1700, glow: 0 }));
  return els;
}

// ---------------------------------------------------------------------------------------------------------------
// The timeline. Each scene: when it starts arriving, when it starts to dissolve, how far it drifts while it does.

const SCENES = [
  { build: menuMid, in: 0, out: 5200, drift: -1, tier: 0 },
  { build: menuWhirl, in: 5500, out: 7400, drift: 1, tier: 1, enter: 1 },
  { build: menuMid, in: 7700, out: 10100, tier: 0, enter: -1 },
  { build: playDrop, in: 10300, out: 13400, tier: 0 },
  { build: result, in: 13800, out: 17800, tier: 0 },
  { build: menuMid, in: 18100, out: 20500, tier: 0 },
  { build: pack, in: 20800, out: 25500, tier: 2 },
  { build: menuMid, in: 25800, out: 27500, tier: 0, quick: true },
  { build: settings, in: 27800, out: 32600, tier: 0 },
  // Kept off the film, for their stills.
  { build: playPrism, in: 34000, out: 39000, tier: 2 },
  { build: menuToday, in: 42000, out: 50000, tier: 0 },
];
const FINGER = [
  { at: 4300, to: 5100, from: [380, 470], dest: [120, 470] },
  { at: 6600, to: 7400, from: [80, 470], dest: [330, 470] },
  { at: 9400, to: 10000, from: null, dest: null, tap: true, target: 'drop' },
  { at: 19800, to: 20400, from: null, dest: null, tap: true, target: 'pack-prism' },
  { at: 25000, to: 25450, from: null, dest: null, tap: true, target: 'menu' },
  { at: 26900, to: 27450, from: null, dest: null, tap: true, target: 'settings' },
];
const SHOTS = { menu: 3950, play: 13100, result: 17500, pack: 24650, settings: 31700, prism: 38000, 'menu-today': 47500 };
const DURATION = 32100;

function drawFinger(ctx, t) {
  if (RM) return;
  for (const f of FINGER) {
    if (t < f.at - 300 || t > f.to + 300) continue;
    const from = f.from || pos[f.target] || [W / 2, H / 2];
    const dest = f.dest || from;
    const u = World.ease(clamp((t - f.at) / (f.to - f.at)));
    const x = World.mix(from[0], dest[0], u), y = World.mix(from[1], dest[1], u);
    const vis = smooth(f.at - 300, f.at, t) * (1 - smooth(f.to, f.to + 300, t));
    const press = f.tap ? Math.sin(PI * clamp((t - f.at) / (f.to - f.at))) : 0.6;
    ctx.save();
    ctx.globalAlpha = 0.22 * vis;
    ctx.fillStyle = '#ffffff';
    ctx.filter = 'blur(3px)';
    ctx.beginPath(); ctx.arc(x, y, 22 - 3 * press, 0, 2 * PI); ctx.fill();
    ctx.globalAlpha = 0.3 * vis * (0.5 + press);
    ctx.beginPath(); ctx.arc(x, y, 12, 0, 2 * PI); ctx.fill();
    ctx.restore();
  }
}

// ---------------------------------------------------------------------------------------------------------------

function tierMix(t) {
  // The wash in the water follows the page's inks: 0 plughole, 1 whirlpool, 2 prism.
  let cur = 0;
  for (const s of SCENES) if (t >= s.in) cur = s.tier;
  return cur;
}

World.load(['play01', 'drain-solved', 'prism01', 'prism-clip', 'cover-lens', 'cover-escapement', 'cover-prism',
  'cover-triptych', 'status']).then(() => World.start({
  fonts: ['300 58px NY', 'italic 300 58px NY', 'italic 400 17px NY', '400 17px NY', 'italic 500 26px NY'],
  duration: DURATION,
  shots: SHOTS,
  // The water: deep ink-blue, lighter towards the surface, a faint wash of the page's inks drifting near the top,
  // and suspended motes falling very slowly. At rest only the motes move; the app may hold it still.
  shader: `
    uniform vec3 inkA; uniform vec3 inkB; uniform vec3 inkC; uniform float wash;
    float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
    float n(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3. - 2. * f);
      return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
    float motes(vec2 p, float scale, float speed, float tt) {
      p.y -= tt * speed; p /= scale;
      vec2 i = floor(p), f = fract(p);
      float r = h(i); vec2 c = vec2(h(i + 3.1), h(i + 7.7));
      float d = length(f - c) * scale;
      return step(.8, r) * smoothstep(.9, .0, d) * (.4 + .6 * h(i + 11.));
    }
    void main() {
      vec2 p = uv * res;
      float tt = rm > .5 ? 0. : t / 1000.;
      vec3 deep = vec3(.018, .024, .052), upper = vec3(.04, .052, .095);
      vec3 col = mix(upper, deep, smoothstep(0., 1., uv.y));
      // a faint light from above, soft as through water
      col += vec3(.03, .04, .06) * exp(-pow((p.x - res.x * .55) / 260., 2.) - pow(p.y / 420., 2.));
      // the page's inks, diffused into the water near the top, drifting very slowly sideways
      float drift = tt * 2.;
      float a1 = exp(-pow((p.x - 90. - drift) / 150., 2.) - pow((p.y - 150.) / 120., 2.));
      float a2 = exp(-pow((p.x - 250. + drift * .6) / 160., 2.) - pow((p.y - 120.) / 110., 2.));
      float a3 = exp(-pow((p.x - 380. - drift * .4) / 150., 2.) - pow((p.y - 190.) / 130., 2.));
      col += wash * .055 * (inkA * a1 + inkB * a2 + inkC * a3);
      // the grain of the water, barely there
      col += (n(p * .9) - .5) * .008;
      // suspended motes: two depths, the far ones smaller and slower
      col += vec3(.55, .62, .75) * (motes(p, 34., 3.2, tt) * .13 + motes(p + 70., 21., 1.6, tt) * .07);
      o = vec4(col, 1.);
    }`,
  uniforms(t) {
    const hex = (c) => [1, 3, 5].map(i => parseInt(c.slice(i, i + 2), 16) / 255);
    const order = [INK.plughole, INK.whirlpool, INK.prism];
    // Blend the wash between the inks of the scene leaving and the scene arriving.
    let from = 0, to = 0, u = 1;
    for (let i = 0; i < SCENES.length; i++) {
      const s = SCENES[i];
      if (t >= s.in) { from = to; to = s.tier; u = clamp((t - s.in) / 1600); }
    }
    const a = order[from], b = order[to];
    const m = (k) => hex(a[k]).map((v, j) => World.mix(v, hex(b[k])[j], u));
    return { inkA: m(0), inkB: m(1), inkC: m(2), wash: 1 };
  },
  draw(ctx, t) {
    for (const s of SCENES) {
      if (t < s.in - 10) continue;
      const end = s.out ?? Infinity;
      if (t > end + 2200) continue;
      const els = s.build(ctx);
      const leave = (el) => s.out == null ? 0 : World.ease(clamp((t - s.out - (el.outDelay || 0)) / (s.quick ? 900 : 1400)));
      // While a page dissolves it drifts a little the way the finger went; the next drifts in after it.
      const dx = RM ? 0 : (s.out != null ? (s.drift || 0) * 26 * World.ease(clamp((t - s.out) / 1400)) : 0)
        + (s.enter ? s.enter * 26 * (1 - World.ease(clamp((t - s.in) / 1600))) : 0);
      ctx.save();
      ctx.translate(dx, 0);
      for (const el of els) {
        const a = (t - s.in - el.delay) / (s.quick ? el.dur * 0.6 : el.dur);
        drawEl(ctx, el, RM ? (t - s.in - el.delay > 0 ? a * 3 : 0) : a, leave(el));
      }
      ctx.restore();
    }
    drawFinger(ctx, t);
    const st = World.images.status;
    if (st) ctx.drawImage(st, 0, 0, W, 54);
  },
}));
window.DRAWS_AX = true;
