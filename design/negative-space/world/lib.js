// Copyright © 2026 Jack Lusher. All rights reserved.
// Shared by the redesign worlds (basin, ink, descent): one 440 x 956 pt phone drawn by a full-screen fragment shader
// (the stand-in for the app's Metal pass) under a 2D canvas for type and glass, driven by one timeline in ms.
// A world page calls World.start({ shader, uniforms(t), draw(ctx, t), duration, shots }) and the harness
// (render.mjs) steps it with seek(t). Nothing plays on its own clock, so every still and frame is reproducible.

const W = 440, H = 956;
const q = new URLSearchParams(location.search);
const World = {
  W, H,
  rm: q.get('rm') === '1',          // Reduce Motion: the world draws its settled state, transitions cut or fade
  ax: q.get('ax') === '1',          // accessibility type: roles at AX3 (body 17 -> 40)
  scale: Number(q.get('scale') || 3),
  glass: '../../../../build/negative-space/glass/',
  images: {},

  // Smooth steps for a timeline: 0 before a, 1 after b.
  ramp(t, a, b) { return Math.min(1, Math.max(0, (t - a) / (b - a))); },
  ease(x) { return x < 0 ? 0 : x > 1 ? 1 : 1 - Math.pow(1 - x, 3); },
  settle(x) { // a damped arrival: overshoots a touch and settles, like liquid finding level
    if (x <= 0) return 0; if (x >= 1) return 1;
    return 1 - Math.exp(-6 * x) * Math.cos(5 * x);
  },
  mix(a, b, x) { return a + (b - a) * x; },

  // Type roles in points at the default size; text never goes under these.
  type: { display: 34, title: 28, headline: 17, body: 17, label: 15, detail: 13 },
  pt(role) { return World.type[role] * (World.ax ? World.axScale[role] : 1); },
  axScale: { display: 1.6, title: 1.9, headline: 2.35, body: 2.35, label: 2.2, detail: 2.3 },

  async load(names) {
    await Promise.all(names.map(n => new Promise((res) => {
      const im = new Image();
      im.onload = () => { World.images[n] = im; res(); };
      im.onerror = () => res();
      im.src = World.glass + n + '.png';
    })));
  },

  // Text along a circle: centre (cx, cy), radius r, centred on angle a (radians, 0 = right, -PI/2 = top).
  // inward: letters stand with their feet towards the centre (text on the top of an arc reads left to right).
  arcText(ctx, text, cx, cy, r, a, { inward = true } = {}) {
    const chars = [...text];
    const widths = chars.map(c => ctx.measureText(c).width);
    const total = widths.reduce((s, w) => s + w, 0);
    let ang = a - (inward ? 1 : -1) * total / r / 2;
    ctx.save();
    for (let i = 0; i < chars.length; i++) {
      const w = widths[i];
      const mid = ang + (inward ? 1 : -1) * w / r / 2;
      ctx.save();
      ctx.translate(cx + r * Math.cos(mid), cy + r * Math.sin(mid));
      ctx.rotate(mid + (inward ? Math.PI / 2 : -Math.PI / 2));
      ctx.fillText(chars[i], -w / 2, 0);
      ctx.restore();
      ang += (inward ? 1 : -1) * w / r;
    }
    ctx.restore();
  },

  // A glass crop drawn as a disc of diameter d centred at (cx, cy).
  disc(ctx, name, cx, cy, d, alpha = 1) {
    const im = World.images[name];
    if (!im) return;
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.drawImage(im, cx - d / 2, cy - d / 2, d, d);
    ctx.restore();
  },

  start(spec) {
    const s = World.scale;
    const gl$ = document.createElement('canvas');
    const ui$ = document.createElement('canvas');
    for (const c of [gl$, ui$]) {
      c.width = W * s; c.height = H * s;
      Object.assign(c.style, { position: 'absolute', left: 0, top: 0, width: W + 'px', height: H + 'px' });
      document.body.appendChild(c);
    }
    Object.assign(document.body.style, { margin: 0, width: W + 'px', height: H + 'px', overflow: 'hidden', background: '#000', position: 'relative' });
    const gl = gl$.getContext('webgl2', { premultipliedAlpha: false, preserveDrawingBuffer: true });
    const vs = `#version 300 es
      in vec2 p; out vec2 uv; void main() { uv = p * .5 + .5; uv.y = 1. - uv.y; gl_Position = vec4(p, 0, 1); }`;
    const fs = `#version 300 es
      precision highp float; in vec2 uv; out vec4 o;
      uniform float t; uniform vec2 res; uniform float rm;
      ${spec.shader}`;
    const sh = (type, src) => {
      const x = gl.createShader(type); gl.shaderSource(x, src); gl.compileShader(x);
      if (!gl.getShaderParameter(x, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(x));
      return x;
    };
    const prog = gl.createProgram();
    gl.attachShader(prog, sh(gl.VERTEX_SHADER, vs)); gl.attachShader(prog, sh(gl.FRAGMENT_SHADER, fs));
    gl.linkProgram(prog); gl.useProgram(prog);
    const buf = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, buf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
    const loc = gl.getAttribLocation(prog, 'p'); gl.enableVertexAttribArray(loc);
    gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);
    const ctx = ui$.getContext('2d');
    // Optional textures: spec.textures = { name: () => canvas } are uploaded each frame they are asked for.
    const tex = {};
    World.texture = (name, canvas, unit) => {
      if (!tex[name]) tex[name] = gl.createTexture();
      gl.activeTexture(gl.TEXTURE0 + unit); gl.bindTexture(gl.TEXTURE_2D, tex[name]);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, canvas);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.uniform1i(gl.getUniformLocation(prog, name), unit);
    };
    World.seek = (t) => {
      gl.viewport(0, 0, gl$.width, gl$.height);
      gl.uniform1f(gl.getUniformLocation(prog, 't'), t);
      gl.uniform2f(gl.getUniformLocation(prog, 'res'), W, H);
      gl.uniform1f(gl.getUniformLocation(prog, 'rm'), World.rm ? 1 : 0);
      const u = spec.uniforms ? spec.uniforms(t) : {};
      for (const [k, v] of Object.entries(u)) {
        const l = gl.getUniformLocation(prog, k);
        if (Array.isArray(v)) gl['uniform' + v.length + 'fv'](l, v); else gl.uniform1f(l, v);
      }
      if (spec.beforeGL) spec.beforeGL(t, gl);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      ctx.setTransform(s, 0, 0, s, 0, 0);
      ctx.clearRect(0, 0, W, H);
      spec.draw(ctx, t);
    };
    window.seek = World.seek;
    window.DURATION = spec.duration;
    window.SHOTS = spec.shots;
    const faces = (spec.fonts || []).map(f => document.fonts.load(f));
    Promise.all(faces).then(() => document.fonts.ready).then(() => { World.seek(0); document.body.dataset.ready = '1'; });
  },
};
window.World = World;
