// Copyright © 2026 Jack Lusher. All rights reserved.
// Renders a redesign world with one headless Chrome over the DevTools protocol, its timeline stepped by seek(t):
//   node render.mjs <world> stills   each of the world's SHOTS at 3x, and again under Reduce Motion (-rm) and, if the
//                                    world draws it, accessibility type (-ax)
//   node render.mjs <world> film     its whole timeline at 2x and 30 fps, through ffmpeg
// into build/negative-space/world/<world>/. Run it under busy-run.
// A world with several timelines is named <world>:<variant> (eggs:skim): the page gets ?egg=<variant>, draws only
// its default state, and its stills and film are named after the variant, so variants render side by side.
import { spawn, execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const [worldArg, mode = 'stills', only] = process.argv.slice(2);
const [world, variant] = worldArg.split(':');
const pick = variant ? `&egg=${variant}` : '';
const tagged = variant ? `-${variant}` : '';
const out = resolve(here, '../../../build/negative-space/world', world);
mkdirSync(out, { recursive: true });
const chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const port = 9400 + Math.floor(Math.random() * 500);
const profile = resolve(out, `.chrome${tagged}`);
const proc = spawn(chrome, ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
  '--allow-file-access-from-files', '--hide-scrollbars', '--force-color-profile=srgb', 'about:blank'], { stdio: 'ignore' });
process.on('exit', () => proc.kill());   // a run that throws leaves no Chrome behind
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
let target;
for (let k = 0; k < 60 && !target; k++) {
  try { target = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find(t => t.type === 'page'); }
  catch {}
  if (!target) await sleep(200);
}
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise(r => ws.addEventListener('open', r));
let id = 0;
const waiting = new Map();
const logs = [];
ws.addEventListener('message', (m) => {
  const msg = JSON.parse(m.data);
  if (msg.method === 'Runtime.exceptionThrown') logs.push(msg.params.exceptionDetails.exception?.description || msg.params.exceptionDetails.text);
  if (msg.method === 'Runtime.consoleAPICalled' && msg.params.type === 'error') logs.push(msg.params.args.map(a => a.value).join(' '));
  if (msg.id && waiting.has(msg.id)) { waiting.get(msg.id)(msg); waiting.delete(msg.id); }
});
const send = (method, params = {}) => new Promise((res, rej) => {
  const i = ++id;
  waiting.set(i, (msg) => msg.error ? rej(new Error(`${method}: ${msg.error.message}`)) : res(msg.result));
  ws.send(JSON.stringify({ id: i, method, params }));
});
const evaluate = async (expression) =>
  (await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true })).result.value;
await send('Page.enable');
await send('Runtime.enable');

async function open(extra, scale) {
  await send('Emulation.setDeviceMetricsOverride', { width: 440, height: 956, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url: `file://${here}/${world}/index.html?scale=${scale}${extra}${pick}` });
  for (let k = 0; k < 200; k++) {
    if (await evaluate(`document.readyState === 'complete' && document.body && document.body.dataset.ready === '1'`)) return;
    await sleep(50);
  }
  throw new Error(`${world} never became ready: ${logs.join(' | ')}`);
}
async function shot(file, format = 'png') {
  const { data } = await send('Page.captureScreenshot', { format, quality: format === 'jpeg' ? 90 : undefined,
    clip: { x: 0, y: 0, width: 440, height: 956, scale: 1 } });
  writeFileSync(file, Buffer.from(data, 'base64'));
}

// The canvases are drawn at `scale` x but laid out at 440 x 956 pt, so the screenshot is taken at device scale `scale`.
async function setScale(scale) {
  await send('Emulation.setDeviceMetricsOverride', { width: 440, height: 956, deviceScaleFactor: scale, mobile: false });
}

if (mode === 'stills') {
  for (const [extra, tag] of variant ? [['', '']] : [['', ''], ['&rm=1', '-rm'], ['&ax=1', '-ax']]) {
    await open(extra, 3);
    await setScale(3);
    const shots = await evaluate('JSON.stringify(window.SHOTS)').then(JSON.parse);
    if (tag === '-ax' && !(await evaluate('!!window.DRAWS_AX'))) continue;
    for (const [name, t] of Object.entries(shots)) {
      if (only && name !== only) continue;
      await evaluate(`seek(${t})`);
      await shot(`${out}/${name}${tag}.png`);
    }
  }
  console.log(`${world}: stills in ${out}`);
} else if (mode === 'film') {
  await open('', 2);
  await setScale(2);
  const duration = await evaluate('window.DURATION');
  const frames = `${out}/frames${tagged}`;
  rmSync(frames, { recursive: true, force: true });
  mkdirSync(frames, { recursive: true });
  let n = 0;
  for (let t = 0; t < duration; t += 1000 / 30) {
    await evaluate(`seek(${t})`);
    await shot(`${frames}/${String(n++).padStart(5, '0')}.jpg`, 'jpeg');
  }
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-framerate', '30', '-i', `${frames}/%05d.jpg`,
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', '-movflags', '+faststart', `${out}/${variant || 'film'}.mp4`]);
  rmSync(frames, { recursive: true, force: true });
  console.log(`${worldArg}: film of ${n} frames`);
}
if (logs.length) console.log('page errors:', logs.join(' | '));
ws.close();
const exited = new Promise(r => proc.on('exit', r));
proc.kill();
await exited;
rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
