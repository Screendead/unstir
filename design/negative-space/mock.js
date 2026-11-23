// Copyright © 2026 Jack Lusher. All rights reserved.
// Draws one screen of one direction: mock.html?d=a|b|c&s=menu|play|result|prism|card|settings[&rm=1][&ax=1].
// The glass, covers and clip are crops of real screenshots (crop.py); nothing here draws a picture.

const q = new URLSearchParams(location.search);
const D = (q.get('d') || 'a').toUpperCase();
const S = q.get('s') || 'menu';
const RM = q.get('rm') === '1';
const AX = q.get('ax') === '1';
const G = '../../build/negative-space/glass/';

document.body.className = [D, 's-' + S, RM ? 'rm' : '', AX ? 'ax' : ''].join(' ');
const phone = document.getElementById('phone');

// Tier and pack sweeps, as the app draws them.
const SWEEP = {
  plughole: ['#00f0ff', '#ff2bd6', '#ffb000'],
  whirlpool: ['#ff1438', '#ff2bd6', '#9a2cff'],
  prism: ['#ff2a2a', '#2aff5a', '#3a6bff'],
};
// The hue walk of a tier's level numbers (oklch, first to last), as the app colours them.
// The walk runs the long way round, over twelve numbers, as the before shots show it.
const WALK = { plughole: [0.639, 0.34, 190, 430], whirlpool: [0.62, 0.3, 23, 301] };
const hue = (tier, n) => {
  const [l, c, h0, h1] = WALK[tier];
  return `oklch(${l} ${c} ${(h0 + (h1 - h0) * ((n - 1) % 12) / 11) % 360})`;
};

// Arrival order: each element given `i` arrives that many steps after the screen's first.
let step = 0;
const h = (tag, cls, html = '', i) => {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  e.innerHTML = html;
  if (i !== undefined) { e.style.setProperty('--i', i); e.classList.add('arrive'); }
  return e;
};
const add = (parent, ...kids) => { kids.forEach(k => k && parent.appendChild(k)); return parent; };
const img = (src, cls) => `<img class="${cls || ''}" src="${G}${src}">`;
const dots = (n, cls = '') =>
  `<span class="dots ${cls}">${[1, 2, 3].map(k => `<i class="${k <= n ? 'on' : ''}" style="--k:${k}"></i>`).join('')}</span>`;
const lock = '<svg class="lock" viewBox="0 0 10 12"><rect x="1" y="5" width="8" height="6.5" rx="1.2"/><path d="M3 5V3.6a2 2 0 0 1 4 0V5" fill="none" stroke-width="1.4"/></svg>';
const gear = '<svg class="gear" viewBox="0 0 24 24"><path d="M12 8.6a3.4 3.4 0 1 0 0 6.8 3.4 3.4 0 0 0 0-6.8Zm8.2 4.6-.1-2.4 2-1.6-2-3.4-2.4.8-2-1.2L13.2 2.9H9.8L9.3 5.4l-2 1.2-2.4-.8-2 3.4 2 1.6-.1 1.2.1 1.2-2 1.6 2 3.4 2.4-.8 2 1.2.5 2.5h3.4l.5-2.5 2-1.2 2.4.8 2-3.4-2-1.6Z" fill="none" stroke-width="1.1"/></svg>';
const sweepCSS = (t) => `linear-gradient(90deg, ${SWEEP[t].join(', ')})`;

add(phone, h('img', 'status', '', undefined));
phone.querySelector('.status').src = G + 'status.png';

// Mist and pool: the light behind the chrome in B and C.
function light(cls, colours, extra = '') {
  const e = h('div', 'light ' + cls);
  e.innerHTML = colours.map((c, k) => `<b style="--c:${c};--k:${k}"></b>`).join('') + extra;
  return e;
}

const screens = {};

// ---------- The menu, as menu-all-done: every plughole level at par, the daily four days running, the dock. ----------
const ROWS = [
  [1, 'Drop', 3, 1], [2, 'Drip', 3, 1], [3, 'Trickle', 3, 2], [4, 'Ripple', 3, 2], [5, 'Bubble', 3, 3],
  [6, 'Fizz', 3, 3], [7, 'Sprinkle', 3, 4], [8, 'Mist', 3, 3], [9, 'Spray', 4, 2],
];
const DOCK = ['first-stir', 'lens', 'escapement', 'prism', 'triptych'];
const NEW = ['lens', 'escapement', 'prism'];
const DOCKNAME = { 'first-stir': 'First Stir', lens: 'Lens', escapement: 'Escapement', prism: 'Prism', triptych: 'Triptych I' };

screens.menu = () => {
  const p = phone;
  if (D === 'B') add(p, light('pool menu-pool', SWEEP.plughole));
  if (D === 'C') add(p, light('mist', SWEEP.plughole));
  add(p, add(h('div', 'menu-head', '', 0), h('div', 'wordmark', 'UNSTIR'), h('div', 'gearbtn', gear)));
  const strip = h('div', 'strip', '', 1);
  ['plughole', 'whirlpool', 'vortex', 'maelstrom'].forEach((t, k) => {
    strip.appendChild(h('span', 'tier' + (k === 0 ? ' on' : ''), t));
    if (D === 'A' && k < 3) strip.appendChild(h('span', 'sep', '·'));
  });
  add(p, strip);

  if (D === 'B') {
    // The focus: today's daily, large, with its pool of light; endless and the archive one quiet line under it.
    const f = h('div', 'focus', '', 2);
    f.innerHTML = `<span class="kicker">today</span><span class="big">Daily</span>
      <span class="sub">Mon 23 Nov · 4 days running&ensp;${dots(2)}</span><span class="go">play ›</span>`;
    add(p, f);
    add(p, h('div', 'pair', `<span>endless <em>best 9</em></span><span class="dim">archive <em>with any pack</em></span>`, 3));
  } else {
    const today = h('div', 'today', '', 2);
    today.innerHTML = `
      <div class="row daily"><span class="num">day</span><span class="title">Daily · Mon 23 Nov<small>4 days running</small></span>${dots(2)}</div>
      <div class="row"><span class="num">past</span><span class="title dim">Archive</span><span class="aside">with any pack</span></div>
      <div class="row"><span class="num">∞</span><span class="title">Endless</span><span class="aside">best 9</span></div>`;
    add(p, today);
  }

  const list = h('div', 'list', '', D === 'B' ? 4 : 3);
  list.appendChild(h('div', 'tierhead', `<span class="name">plughole</span><span class="prog">27 of 27 at par</span>`));
  ROWS.forEach(([n, title]) => {
    const r = h('div', 'row lvl solved');
    r.style.setProperty('--hue', hue('plughole', n));
    r.innerHTML = `<span class="num">${String(n).padStart(2, '0')}</span><span class="title">${title}</span>${dots(3)}`;
    list.appendChild(r);
  });
  add(p, list);

  const dock = h('div', 'dock', '', 5);
  dock.innerHTML = `<div class="covers">${DOCK.map(c =>
    `<div class="cover${NEW.includes(c) ? ' new' : ''}">${img('cover-' + c + '.png')}${D === 'A' ? `<span>${DOCKNAME[c]}</span>${NEW.includes(c) ? '<em>new</em>' : ''}` : ''}</div>`).join('')}</div>`;
  add(p, dock);
};

// ---------- The menu mid-way, as menu-landing: plughole 01 to 13 solved, the list centred on 14, the next to play. ----------
const NAMES = ['Drop', 'Drip', 'Trickle', 'Ripple', 'Bubble', 'Fizz', 'Sprinkle', 'Mist', 'Spray', 'Splash', 'Puddle',
  'Froth', 'Suds', 'Lather', 'Steam', 'Gurgle', 'Rinse', 'Drizzle', 'Shower'];
const NEXT = 14;
screens.landing = () => {
  const p = phone;
  if (D === 'B') add(p, light('pool landing-pool', SWEEP.plughole));
  if (D === 'C') add(p, light('mist', SWEEP.plughole));
  add(p, add(h('div', 'menu-head', '', 0), h('div', 'wordmark', 'UNSTIR'), h('div', 'gearbtn', gear)));
  const strip = h('div', 'strip', '', 1);
  ['plughole', 'whirlpool', 'vortex', 'maelstrom'].forEach((t, k) => {
    strip.appendChild(h('span', 'tier' + (k === 0 ? ' on' : '') + (k > 0 ? ' locked' : ''), t + (k > 0 && D === 'A' ? lock : '')));
    if (D === 'A' && k < 3) strip.appendChild(h('span', 'sep', '·'));
  });
  add(p, strip);
  const list = h('div', 'list landing', '', 2);
  for (let n = 10; n <= 19; n++) {
    const title = NAMES[n - 1], nn = String(n).padStart(2, '0');
    const r = h('div', 'row lvl' + (n === NEXT ? ' next' : '') + (n < NEXT ? ' solved' : '') + (n > NEXT ? ' ahead' : ''));
    r.style.setProperty('--hue', hue('plughole', n));
    const detail = LANDING_DETAIL;
    if (n === NEXT && D === 'B') {
      r.innerHTML = `<span class="num">${nn}</span><span class="title">${title}<small>${detail}</small></span><span class="go">play ›</span>`;
    } else {
      r.innerHTML = `<span class="num">${nn}</span><span class="title">${title}${n === NEXT ? `<small>${detail}</small>` : ''}</span>` +
        (n < NEXT ? dots(2) : n > NEXT ? lock : '');
    }
    list.appendChild(r);
  }
  add(p, list);
  const dock = h('div', 'dock', '', 3);
  dock.innerHTML = `<div class="covers">${DOCK.map(c =>
    `<div class="cover${NEW.includes(c) ? ' new' : ''}">${img('cover-' + c + '.png')}${D === 'A' ? `<span>${DOCKNAME[c]}</span>${NEW.includes(c) ? '<em>new</em>' : ''}` : ''}</div>`).join('')}</div>`;
  add(p, dock);
};
const LANDING_DETAIL = '4 rods · par 4';

// ---------- Play: plughole 01 as dealt, the opening stir's caption under it. ----------
screens.play = () => playScreen({
  tier: 'plughole', n: 1, title: 'Drop', count: 'moves 0 / par 1', glass: 'play01.png',
  note: 'Turn a rod to look. Let go where you started and nothing happens.', undo: 'undo · 10',
});

// ---------- Prism 01 as dealt: its level colour (white today) and the swatches. ----------
screens.prism = () => playScreen({
  tier: 'prism', n: 1, title: 'Frond', count: 'moves 0 / par 3', glass: 'prism01.png',
  note: 'Each rod stirs only its knob’s colours.', undo: 'undo · 10', prism: true,
});

function playScreen(o) {
  const p = phone;
  const nn = String(o.n).padStart(2, '0');
  if (D === 'C') add(p, light('mist play-mist', SWEEP[o.tier]));
  const numColour = o.prism ? null : hue(o.tier, o.n);
  const head = h('div', 'playhead', '', 0);
  head.innerHTML = `<span class="back">‹ levels</span><span class="count">${o.count}</span>`;
  add(p, head);
  const title = h('div', 'leveltitle', '', 1);
  title.innerHTML = `<span class="num" ${numColour ? `style="--hue:${numColour}"` : ''}>${nn}</span><span class="title">${o.title}</span>`;
  if (o.prism) {
    title.classList.add('prismtitle');
    if (D === 'A') title.insertAdjacentHTML('afterbegin', '<span class="packtag">PRISM</span>');
  }
  add(p, title);
  if (D === 'B') add(p, light('pool tank-pool', SWEEP[o.tier]));
  add(p, h('div', 'tank', img(o.glass)));
  const cap = h('div', 'caption', o.note, 2);
  add(p, cap);
  const ctl = h('div', 'controls', `<span class="ctl undo">${o.undo}</span><span class="ctl reset">reset</span>`, 3);
  add(p, ctl);
}

// ---------- The result, as result-fullest: plughole 27 at par with a stir undone, a new best, up a notch. ----------
screens.result = () => resultScreen({
  tier: 'plughole', n: 27, title: 'Drain', glass: 'drain-solved.png', marks: 2,
  verdict: 'at par', verdictWord: '', stats: 'moves 9 · par 9', hint: 'clean needs no undo or reset',
  best: 'new best · was +6', next: 'WHIRLPOOL',
});
function resultScreen(o) {
  const p = phone;
  const nn = String(o.n).padStart(2, '0');
  if (D === 'C') add(p, light('mist bloom', SWEEP[o.tier]));
  const head = h('div', 'playhead', `<span class="back">‹ levels</span><span class="count"></span>`);
  add(p, head);
  const title = h('div', 'leveltitle', `<span class="num" ${o.prism ? '' : `style="--hue:${hue(o.tier, o.n)}"`}>${nn}</span><span class="title">${o.title}</span>`);
  if (o.prism) title.classList.add('prismtitle');
  add(p, title);
  add(p, h('div', 'stamp', 'unstirred.', 0));
  if (D === 'B') add(p, light('pool result-pool', SWEEP[o.tier]));
  add(p, h('div', 'tank solved', img(o.glass)));
  const card = h('div', 'card');
  if (D === 'A') {
    add(card,
      h('div', 'marks', dots(o.marks, 'big'), 1),
      h('div', 'verdict par', o.verdict, 2),
      h('div', 'stats', o.stats, 2),
      h('div', 'best', `${o.best}<br>${o.hint}`, 2));
  } else if (D === 'B') {
    add(card,
      h('div', 'marks', dots(o.marks, 'big drops'), 1),
      h('div', 'verdict', `${o.verdict}<span class="nb">${o.best}</span>`, 2));
  } else {
    add(card,
      h('div', 'marks', dots(o.marks, 'big'), 1),
      h('div', 'verdict', o.verdict, 2),
      h('div', 'stats', o.stats, 2),
      h('div', 'best', `${o.best}<br>${o.hint}`, 2));
  }
  add(p, card);
  const acts = h('div', 'actions', '', 4);
  acts.innerHTML = `<span class="act quiet">again</span>
    <span class="act primary up"><small>up a notch</small><span class="upname">${o.next} ›</span></span>`;
  acts.style.setProperty('--sweep', sweepCSS('whirlpool'));
  add(p, acts);
}

// ---------- Prism's pack card, unowned. ----------
screens.card = () => {
  const p = phone;
  if (D === 'B') add(p, light('pool card-pool', SWEEP.prism));
  if (D === 'C') add(p, light('mist', SWEEP.prism));
  add(p, h('div', 'cardback', '‹ menu', 0));
  if (D === 'A') add(p, h('div', 'eyebrow', 'PACK · PAID ADD-ON', 0));
  add(p, h('div', 'packname', 'Prism', 0));
  add(p, h('div', 'pitch', 'each rod stirs only some colours', 1));
  add(p, h('div', 'clip', img('prism-clip.png'), 1));
  const facts = h('div', 'facts', '', 2);
  facts.innerHTML = `30 specimens in five trays<br>levels 1–3 free, no purchase<br><span class="dim">letters for colour-blind play, in settings</span>`;
  add(p, facts);
  const buy = h('div', 'buyrow', `<span class="buy">buy&ensp;$2.99</span><span class="try">try 3 free ›</span>`, 3);
  add(p, buy);
  add(p, h('div', 'bundle', 'or all three in Triptych I · $5.99 · save $2.98 ›', 3));
  add(p, h('div', 'restore', 'restore purchases', 4));
  const ch = h('div', 'chapter', '', 4);
  ch.innerHTML = `<div class="tierhead"><span class="name">two colours</span><span class="prog">0 of 6</span></div>
    <div class="row lvl"><span class="num">01</span><span class="title">Frond</span></div>
    <div class="row lvl"><span class="num">02</span><span class="title">Bracken</span></div>`;
  add(p, ch);
};

// ---------- Settings, over the menu. ----------
screens.settings = () => {
  const p = phone;
  screens.menu();
  add(p, h('div', 'under'));
  const sheet = h('div', 'sheet', '', 0);
  const sw = (t, d, on) => `<div class="set"><span class="st">${t}${d ? `<small>${d}</small>` : ''}</span><i class="toggle ${on ? 'on' : ''}"></i></div>`;
  const ln = (t, d, arrow) => `<div class="set link"><span class="st">${t}${d ? `<small>${d}</small>` : ''}</span>${arrow ? '<b class="arr">↗</b>' : ''}</div>`;
  const keepDetail = D === 'A' ? false : D === 'B' ? false : false;
  sheet.innerHTML = `<div class="grab"></div><div class="sheettitle">settings</div>` +
    `<div class="group">` +
    sw('music', keepDetail && 'the beds under the menu and the levels', true) +
    sw('sounds', '', true) + sw('haptics', '', true) +
    sw('colour letters', D === 'B' ? '' : 'R, G and B on Prism’s knobs', false) +
    `</div><div class="group">` +
    ln('restore purchases', '', false) + ln('report a problem', '', true) + ln('privacy policy', '', true) +
    `</div><div class="version">Unstir 1.0 (1)</div>`;
  add(p, sheet);
};

(screens[S] || screens.menu)();
if (AX) {
  const col = h('div', 'axcol');
  [...phone.children].filter(e => !e.matches('.status, .light')).forEach(e => col.appendChild(e));
  phone.appendChild(col);
}
document.fonts.ready.then(() => { document.body.dataset.ready = '1'; });

// The renderer steps every animation to a time in ms; nothing plays on its own then.
window.seek = (t) => {
  for (const a of document.getAnimations()) { a.pause(); a.currentTime = t; }
};
