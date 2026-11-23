// Copyright © 2026 Jack Lusher. All rights reserved.
// Renders the mock-ups with one headless Chrome over the DevTools protocol, every animation stepped by time:
//   node render.mjs stills [d...]   each screen of each direction at 3x, and its Reduce Motion still
//   node render.mjs films [d...]    each direction's motion at 2x and 30 fps, through ffmpeg
// into build/negative-space/. Run it under busy-run, as it loads the Mac.
import { spawn, execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const out = resolve(here, '../../build/negative-space');
const chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const port = 9333;
const [mode = 'stills', ...dirs] = process.argv.slice(2);
const DIRS = dirs.length ? dirs : ['a', 'b', 'c'];
const SCREENS = ['menu', 'play', 'result', 'prism', 'card', 'settings'];

const profile = resolve(out, '.chrome');
const proc = spawn(chrome, ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
  '--allow-file-access-from-files', '--hide-scrollbars', '--force-color-profile=srgb', 'about:blank'],
  { stdio: 'ignore' });
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

let target;
for (let k = 0; k < 50 && !target; k++) {
  try { target = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find(t => t.type === 'page'); }
  catch { await sleep(200); }
}
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise(r => ws.addEventListener('open', r));
let id = 0;
const waiting = new Map();
ws.addEventListener('message', (m) => {
  const msg = JSON.parse(m.data);
  if (msg.id && waiting.has(msg.id)) { waiting.get(msg.id)(msg); waiting.delete(msg.id); }
});
const send = (method, params = {}) => new Promise((res, rej) => {
  const i = ++id;
  waiting.set(i, (msg) => msg.error ? rej(new Error(`${method}: ${msg.error.message}`)) : res(msg.result));
  ws.send(JSON.stringify({ id: i, method, params }));
});
const evaluate = async (expression) =>
  (await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true })).result.value;

async function open(d, s, extra = '', scale = 3) {
  await send('Emulation.setDeviceMetricsOverride', { width: 440, height: 956, deviceScaleFactor: scale, mobile: false });
  await send('Page.navigate', { url: `file://${here}/mock.html?d=${d}&s=${s}${extra}` });
  for (let k = 0; k < 100; k++) {
    if (await evaluate(`document.readyState === 'complete' && document.body.dataset.ready === '1'`)) break;
    await sleep(50);
  }
  await evaluate(`Promise.all([...document.images].map(i => i.decode().catch(() => {})))`);
}
async function shot(file, format = 'png') {
  const { data } = await send('Page.captureScreenshot', { format, quality: format === 'jpeg' ? 92 : undefined });
  writeFileSync(file, Buffer.from(data, 'base64'));
}

await send('Page.enable');
if (mode === 'stills') {
  mkdirSync(`${out}/stills`, { recursive: true });
  for (const d of DIRS) for (const s of SCREENS) {
    for (const [extra, tag] of [['', ''], ['&rm=1', '-rm']]) {
      await open(d, s, extra);
      await evaluate('seek(9000)');
      await shot(`${out}/stills/${d}-${s}${tag}.png`);
    }
    console.log(`stills ${d}`);
  }
} else if (mode === 'ax') {
  mkdirSync(`${out}/stills`, { recursive: true });
  for (const d of DIRS) for (const s of ['menu', 'result']) {
    await open(d, s, '&ax=1');
    await evaluate('seek(9000)');
    await shot(`${out}/stills/${d}-${s}-ax.png`);
  }
} else if (mode === 'films') {
  // Each film: the menu arriving, the result arriving, the card arriving, with a beat of its standing motion.
  const parts = [['menu', 3200], ['result', 4600], ['card', 2800]];
  for (const d of DIRS) {
    const frames = `${out}/frames-${d}`;
    rmSync(frames, { recursive: true, force: true });
    mkdirSync(frames, { recursive: true });
    let n = 0;
    for (const [s, ms] of parts) {
      await open(d, s, '', 2);
      for (let t = 0; t < ms; t += 1000 / 30) {
        await evaluate(`seek(${t})`);
        await shot(`${frames}/${String(n++).padStart(5, '0')}.jpg`, 'jpeg');
      }
    }
    execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-framerate', '30', '-i', `${frames}/%05d.jpg`,
      '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', '-movflags', '+faststart', `${out}/film-${d}.mp4`]);
    rmSync(frames, { recursive: true, force: true });
    console.log(`film ${d}: ${n} frames`);
  }
}
ws.close();
proc.kill();
