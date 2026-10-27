#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Unstir sound sketch: every sound here is synthesized from this file, no samples. The first glass set, as Jack first
played it on the phone; `scripts/sounds.sh sketch` puts its files in Sounds/sketch for comparing. Temporary: it goes
with the sketch's switch.

    python3 make.py            rebuild everything (WAVs, phone copies, spectrograms, reel, film, listen.md)
    python3 make.py --no-film  skip the film

All DSP is numpy (filters are applied in the frequency domain, reverb is FFT convolution), so every file is
sample-exact and reruns are byte-identical. ffmpeg only measures (ebur128), draws spectrograms, and encodes.
"""
import os, re, sys, wave, subprocess, json
import numpy as np

SR = 48000
HERE = os.path.dirname(os.path.abspath(__file__))
# The repo, for the film's recording; scripts/sounds.sh sketch runs this from build/sounds/sketch.
REPO = os.environ.get('UNSTIR_REPO', os.path.abspath(os.path.join(HERE, '..', '..', '..')))
FILM_IN = os.path.join(REPO, 'shots/film/autoplay-L09.mp4')
BUILD = os.path.join(HERE, 'build')
PHONE = os.path.join(HERE, 'phone')
SPEC = os.path.join(HERE, 'spec')
TAU = 2 * np.pi


def secs(s):
    return int(round(s * SR))


def tt(dur):
    return np.arange(secs(dur)) / SR


# ---------------------------------------------------------------- key
# Glass and water: D, with the pentatonic D E G A B. It has no third, so it sits under a major or a Dorian bed alike.
SCALE = [0, 2, 5, 7, 9]


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def degree(k, base=74):
    """Scale step k up from `base` (74 = D5)."""
    o, i = divmod(k, len(SCALE))
    return hz(base + 12 * o + SCALE[i])


# ---------------------------------------------------------------- filters (frequency domain)
def fastlen(n):
    best = 1 << (int(n - 1).bit_length())
    for a in (1, 3, 5, 9, 15, 25, 27, 45, 75, 81, 125):
        m = a
        while m < n:
            m *= 2
        best = min(best, m)
    return best


def rbj(kind, f0, q=0.7071, db=0.0):
    w0 = TAU * f0 / SR
    cw, sw = np.cos(w0), np.sin(w0)
    al = sw / (2 * q)
    A = 10 ** (db / 40)
    if kind == 'lp':
        b, a = [(1 - cw) / 2, 1 - cw, (1 - cw) / 2], [1 + al, -2 * cw, 1 - al]
    elif kind == 'hp':
        b, a = [(1 + cw) / 2, -(1 + cw), (1 + cw) / 2], [1 + al, -2 * cw, 1 - al]
    elif kind == 'bp':
        b, a = [al, 0, -al], [1 + al, -2 * cw, 1 - al]
    elif kind == 'peak':
        b, a = [1 + al * A, -2 * cw, 1 - al * A], [1 + al / A, -2 * cw, 1 - al / A]
    else:
        raise ValueError(kind)
    return np.array(b) / a[0], np.array(a) / a[0]


def response(stages, N):
    z = np.exp(-1j * TAU * np.arange(N // 2 + 1) / N)
    H = np.ones(N // 2 + 1, complex)
    for b, a in stages:
        H *= (b[0] + b[1] * z + b[2] * z * z) / (a[0] + a[1] * z + a[2] * z * z)
    return H


def filt(x, stages, circular=False, tail=0.0):
    """Causal IIR cascade. circular=True treats x as one period of a loop."""
    x = np.asarray(x, float)
    n = len(x)
    N = n if circular else fastlen(n + secs(tail) + secs(0.5))
    H = response(stages, N)
    if x.ndim == 2:
        H = H[:, None]
    y = np.fft.irfft(np.fft.rfft(x, N, axis=0) * H, N, axis=0)
    return y if circular else y[:n + secs(tail)]


def lp(x, f, q=0.7071, **k):
    return filt(x, [rbj('lp', f, q)], **k)


def hp(x, f, q=0.7071, **k):
    return filt(x, [rbj('hp', f, q)], **k)


def bp(x, f, q=1.0, **k):
    return filt(x, [rbj('bp', f, q)], **k)


# The phone-speaker check: an 8th-order Butterworth high-pass at 250 Hz, as four biquads.
PHONE_HP = [rbj('hp', 250.0, q) for q in (0.50980, 0.60134, 0.89998, 2.56292)]


def conv(x, h, circular=False):
    x = np.asarray(x, float)
    h = np.asarray(h, float)
    if circular:
        N = len(x)
        assert len(h) <= N
        return np.fft.irfft(np.fft.rfft(x, N, axis=0) * np.fft.rfft(h, N, axis=0), N, axis=0)
    n = len(x) + len(h) - 1
    N = fastlen(n)
    return np.fft.irfft(np.fft.rfft(x, N, axis=0) * np.fft.rfft(h, N, axis=0), N, axis=0)[:n]


def shape(x, gain, frame=2048, circular=False):
    """Time-varying spectral shaping by STFT overlap-add. gain(t[frames], f[bins]) -> (frames, bins)."""
    x = np.asarray(x, float)
    hop = frame // 4
    n0 = len(x)
    if not circular:
        n = -(-(n0 + 2 * frame) // hop) * hop
        x = np.concatenate([np.zeros(frame), x, np.zeros(n - n0 - frame)])
    n = len(x)
    assert n % hop == 0
    w = np.hanning(frame + 1)[:-1]
    starts = np.arange(0, n, hop)
    idx = (starts[:, None] + np.arange(frame)[None, :]) % n
    F = np.fft.rfft(x[idx] * w, axis=1)
    tc = (starts + frame / 2) / SR - (0 if circular else frame / SR)
    if circular:
        tc = tc % (n / SR)
    F *= gain(tc[:, None], np.fft.rfftfreq(frame, 1 / SR)[None, :])
    yf = np.fft.irfft(F, frame, axis=1) * w
    y = np.bincount(idx.ravel(), weights=yf.ravel(), minlength=n) / 1.5
    return y if circular else y[frame:frame + n0]


# ---------------------------------------------------------------- voices
def ramp_in(x, ms=1.0):
    n = min(len(x), max(1, int(SR * ms / 1000)))
    r = np.ones(len(x))
    r[:n] = np.sin(np.linspace(0, np.pi / 2, n)) ** 2
    return x * r if x.ndim == 1 else x * r[:, None]


def fade_out(x, dur):
    n = min(len(x), secs(dur))
    r = np.ones(len(x))
    r[len(x) - n:] = np.cos(np.linspace(0, np.pi / 2, n)) ** 2
    return x * r if x.ndim == 1 else x * r[:, None]


def tail_fade(x, frac):
    """Takes the last `frac` of x down to silence, so a ring cut at the buffer's end doesn't click."""
    n = int(len(x) * frac)
    r = np.ones(len(x))
    r[len(x) - n:] = np.cos(np.linspace(0, np.pi / 2, n)) ** 2
    return x * r


def mode(f, tau, dur, amp=1.0, phase=0.0):
    t = tt(dur)
    return amp * np.exp(-t / tau) * np.sin(TAU * f * t + phase)


def glass(f, dur, rng, decay=1.4, bright=1.0, strike=1.0, fm=0.6, doublet=0.9):
    """A struck glass: free-bar partials (1, 2.76, 5.40, 8.93), each a slow-beating doublet, with a soft FM onset."""
    t = tt(dur)
    y = np.zeros_like(t)
    for r, a, dv in ((1.0, 1.0, 1), (2.76, 0.28, 2.3), (5.40, 0.10, 4.5), (8.93, 0.035, 7)):
        fr = f * r
        if fr > 15000:
            continue
        a *= bright ** (r > 1)
        tau = decay / dv
        d = doublet * np.sqrt(r)
        y += a * np.exp(-t / tau) * (np.sin(TAU * fr * t) + 0.45 * np.sin(TAU * (fr + d) * t + rng.uniform(0, TAU))) / 1.45
    if fm:
        idx = fm * 2.2 * np.exp(-t / 0.035)
        y += fm * 0.5 * np.exp(-t / 0.09) * np.sin(TAU * f * t + idx * np.sin(TAU * f * 3.5 * t))
    if strike:
        click = hp(rng.standard_normal(len(t)) * np.exp(-t / 0.0012), 3500)[:len(t)]
        y += strike * 0.18 * click
    return tail_fade(ramp_in(y, 0.6), 0.3)


def bubble(f0, rng=None, rise=0.6, tau=0.03, dur=None, amp=1.0):
    """A bubble: a decaying sine whose pitch rises as it nears the surface."""
    dur = dur or min(8 * tau + 0.01, 0.6)
    t = tt(dur)
    f = f0 * (1 + rise * (1 - np.exp(-t / (2.5 * tau))))
    ph = TAU * np.cumsum(f) / SR
    env = np.exp(-t / tau) * (1 - np.exp(-t / 0.0006))
    return tail_fade(amp * env * np.sin(ph), 0.2)


def swell(f, dur, rng, beat=0.35, glassy=0.06):
    """A bowed-glass swell: a hann-shaped tone with a slow beat and a hint of the 2.76 partial."""
    t = tt(dur)
    env = np.sin(np.pi * t / dur) ** 2
    y = np.sin(TAU * f * t) + 0.6 * np.sin(TAU * (f + beat) * t + rng.uniform(0, TAU))
    y += glassy * np.sin(TAU * f * 2.76 * t) + 0.12 * np.sin(TAU * 2 * f * t)
    return env * y / 1.6


def make_ir(dur, rt_lo, rt_hi, rng, channels=1, fade=0.004):
    """Decaying noise with a frequency-dependent decay: long in the lows, shorter in the highs."""
    n = secs(dur)
    t = np.arange(n) / SR
    noise = rng.standard_normal((n, channels))
    X = np.fft.rfft(noise, axis=0)
    f = np.fft.rfftfreq(n, 1 / SR)
    edges = [0, 250, 700, 1800, 4500, 9000, SR / 2]
    ir = np.zeros((n, channels))
    for lo, hi in zip(edges[:-1], edges[1:]):
        m = ((f >= lo) & (f < hi)).astype(float)[:, None]
        band = np.fft.irfft(X * m, n, axis=0)
        fc = np.sqrt(max(lo, 60) * hi)
        u = np.clip(np.log(fc / 150) / np.log(10000 / 150), 0, 1)
        rt = rt_lo * (rt_hi / rt_lo) ** u
        ir += band * np.exp(-6.91 * t / rt)[:, None]
    ir *= np.minimum(1, t / fade)[:, None]
    ir /= np.sqrt((ir ** 2).sum(axis=0))
    return ir[:, 0] if channels == 1 else ir


def verb(x, ir, wet, tail=None):
    """Dry plus wet, output long enough for the tail."""
    y = conv(x, ir)
    out = y * wet
    out[:len(x)] += x
    if tail is not None:
        out = out[:len(x) + secs(tail)]
    return out


def pan(x, p):
    th = (p + 1) * np.pi / 4
    return np.stack([x * np.cos(th), x * np.sin(th)], axis=1)


def place(buf, x, at, circular=False):
    """Add x into buf at sample `at`, wrapping round the end when circular."""
    n = len(buf)
    x = x[:n]
    if circular:
        idx = (at + np.arange(len(x))) % n
        buf[idx] += x
    else:
        m = min(len(x), n - at)
        if m > 0:
            buf[at:at + m] += x[:m]
    return buf


def mixlen(parts, extra=0.0):
    return max(at + len(x) for at, x in parts) + secs(extra)


def mix(parts, n=None):
    n = n or mixlen(parts)
    ch = max((x.shape[1] if x.ndim == 2 else 1) for _, x in parts)
    buf = np.zeros((n, ch)) if ch > 1 else np.zeros(n)
    for at, x in parts:
        if ch > 1 and x.ndim == 1:
            x = np.stack([x, x], axis=1) * np.sqrt(0.5)
        place(buf, x, at)
    return buf


def trim_tail(x, floor_db=-70):
    a = np.abs(x) if x.ndim == 1 else np.abs(x).max(axis=1)
    thr = a.max() * 10 ** (floor_db / 20)
    last = np.nonzero(a > thr)[0][-1]
    return fade_out(x[:last + secs(0.02)], 0.02)


# ---------------------------------------------------------------- the glass-and-water sounds
def tick(v):
    """One 30-degree detent: a tiny glass bead click near D7, four round-robin variants."""
    rng = np.random.default_rng(100 + v)
    d = 0.05
    t = tt(d)
    p = (1.0, 1.028, 0.974, 1.012)[v]
    spread = (1.0, 0.97, 1.03, 1.0)[v]
    f = hz(98) * p  # D7
    y = mode(f, 0.006, d, 1.0) + mode(f * 1.62 * spread, 0.0035, d, 0.45, 1.0)
    y += mode(f * 2.41, 0.0022, d, 0.25 * spread, 2.0)
    y += mode(hz(74) * p * (1.0 + 0.02 * v), 0.0045, d, 0.55)  # a little body near D5, for the phone
    y += 0.2 * hp(rng.standard_normal(len(t)) * np.exp(-t / 0.0007), 2500)[:len(t)]
    return ramp_in(y, 0.25)


def push():
    """A wrong stir: an Eb-E-F cluster beating at ~19 and ~38 Hz, murky FM, sagging a little, with a low blup."""
    rng = np.random.default_rng(200)
    d = 0.55
    t = tt(d)
    y = np.zeros_like(t)
    sag = 1 - 0.035 * (1 - np.exp(-t / 0.18))
    for f, a in ((hz(63), 1.0), (hz(64), 0.9), (hz(65), 0.7)):
        ph = TAU * np.cumsum(f * sag) / SR + rng.uniform(0, TAU)
        idx = 1.6 * np.exp(-t / 0.08)
        y += a * np.sin(ph + idx * np.sin(0.5 * ph))
    y *= np.exp(-t / 0.13) * (1 - np.exp(-t / 0.002))
    y = lp(y, 1300, 0.8)[:len(t)]
    y += 0.35 * bubble(430, rise=0.35, tau=0.045, dur=d)[:len(t)]
    y = verb(tail_fade(ramp_in(y, 0.8), 0.3), make_ir(0.8, 0.6, 0.35, rng), 0.10, tail=0.35)
    return trim_tail(y)


def heal(n):
    """The n-th heal so far: a bubble plip that lands on a struck glass on scale step n-1 up from D5."""
    rng = np.random.default_rng(300 + n)
    f = degree(n - 1)
    d = 3.0
    y = glass(f, d, rng, decay=1.1, bright=0.9, strike=0.8, fm=0.55)
    y += 0.30 * glass(f / 2, d, rng, decay=0.5, bright=0.2, strike=0, fm=0)  # warmth an octave down
    y += 0.10 * glass(f * 3, d, rng, decay=0.35, bright=0.3, strike=0, fm=0)  # a twelfth of sparkle
    b = bubble(f * 1.5, rise=0.45, tau=0.012)
    y[:len(b)] += 0.5 * b
    y = verb(y, make_ir(2.4, 2.2, 1.0, rng), 0.22, tail=0.6)
    return trim_tail(y)


def tank():
    """One step of the whole tank: a knock at 0, stone-and-steel modes in 190-800 Hz, and a rumble on the haptic's
    own curve (1 at 0, 0.5 at 30 ms, 0 at 95 ms)."""
    rng = np.random.default_rng(400)
    d = 0.5
    t = tt(d)
    y = np.zeros_like(t)
    for f, tau, a in ((188, 0.050, 1.0), (262, 0.040, 0.9), (347, 0.032, 0.75), (463, 0.024, 0.6),
                      (611, 0.018, 0.45), (789, 0.013, 0.35), (1905, 0.006, 0.25)):
        y += mode(f, tau, d, a, rng.uniform(0, TAU))
    y += 0.5 * mode(92, 0.06, d, 1.0)  # sub for headphones; the phone won't play it
    curve = np.interp(t, [0, 0.03, 0.095], [1, 0.5, 0], right=0)
    grit = 1 + 0.6 * np.sin(TAU * 55 * t + 2 * np.sin(TAU * 13 * t))
    rum = bp(rng.standard_normal(len(t)), 420, 0.9)[:len(t)] * curve * grit
    y += 1.4 * rum / np.abs(rum).max()
    knock = hp(rng.standard_normal(len(t)) * np.exp(-t / 0.0015), 1200)[:len(t)]
    y += 0.9 * knock / np.abs(knock).max()
    y *= np.interp(t, [0, 0.09, 0.14, d], [1, 0.8, 0.0, 0.0])
    # Saturation thickens it, and without it the knock's peak holds the body 2 LU under its loudness target.
    y = np.tanh(1.5 * y / np.abs(y).max())
    y = verb(ramp_in(y, 0.3), make_ir(0.6, 0.45, 0.25, rng), 0.12, tail=0.4)
    return trim_tail(y)


def seized():
    """A touch on a dead knob: damped band-limited noise and a cluster of close, heavily damped modes. No pitch."""
    rng = np.random.default_rng(500)
    d = 0.2
    t = tt(d)
    n = rng.standard_normal(len(t)) * np.exp(-t / 0.011)
    y = filt(n, [rbj('hp', 180), rbj('lp', 1100), rbj('lp', 1100)])[:len(t)]
    y /= np.abs(y).max()
    for f in (297, 331, 368, 412, 455, 517, 583):
        y += 0.18 * mode(f, 0.008, d, 1.0, rng.uniform(0, TAU))
    y *= 1 - np.exp(-t / 0.0015)
    return trim_tail(y)


def solve():
    """The bloom: rising bubbles and a quick wash of E, G, B that clears as D4-D5-A5-D6 land on the tonic."""
    rng = np.random.default_rng(600)
    d = 3.0
    parts = []
    for i in range(11):  # the wave: a stream of bubbles, rising and thinning
        at = 0.045 * i + rng.uniform(-0.01, 0.01)
        f0 = 900 * 2 ** (i * 0.13 + rng.uniform(-0.08, 0.08))
        parts.append((secs(max(at, 0)), bubble(f0, rise=0.5, tau=0.018, amp=0.35 * (1 - i / 14))))
    for at, m, a in ((0.00, 76, 0.30), (0.07, 79, 0.28), (0.14, 83, 0.24), (0.22, 88, 0.16)):  # E5 G5 B5 E6
        parts.append((secs(at), a * glass(hz(m), 1.6, rng, decay=0.45, bright=0.7, strike=0.5, fm=0.3)))
    for m, a in ((62, 0.35), (74, 0.6), (81, 0.45), (86, 0.55)):  # D4 D5 A5 D6: the landing
        parts.append((secs(0.42), a * glass(hz(m), d - 0.42, rng, decay=1.2 if m > 62 else 0.9, bright=0.8, strike=0.7, fm=0.5)))
    parts.append((secs(0.3), 0.25 * swell(hz(62), 2.6, rng)))
    y = mix(parts, secs(d))
    sh = shape(rng.standard_normal(secs(1.4)), lambda tc, f: np.exp(-((np.log2(f + 1) - np.log2(6500)) ** 2) / 0.5)
               * (np.clip(tc / 0.35, 0, 1) * np.exp(-np.maximum(tc - 0.35, 0) / 0.3)))
    y[:len(sh)] += 0.06 * sh / np.abs(sh).max()
    y = verb(ramp_in(y, 0.5), make_ir(3.2, 2.8, 1.2, rng), 0.3, tail=0.3)
    return fade_out(y, 0.6)


def spilled():
    """The overflow: a pour of dense bubbles and rushing water that swells, spills, drains down and leaves three drips."""
    rng = np.random.default_rng(700)
    d = 4.2
    n = secs(d)
    y = np.zeros(n)
    rate = lambda s: np.interp(s, [0, 0.9, 1.4, 1.9, 2.7, 3.0], [20, 90, 170, 110, 8, 0])
    s = 0.0
    while s < 3.0:  # an inhomogeneous Poisson stream of bubbles
        s += rng.exponential(1 / max(rate(s), 1))
        if s >= 3.0:
            break
        big = rng.random() < 0.3
        f0 = rng.uniform(260, 520) if big else 2 ** rng.uniform(np.log2(600), np.log2(2200))
        a = (0.5 if big else 0.25) * rng.uniform(0.4, 1.0) * min(1, rate(s) / 90)
        place(y, bubble(f0, rise=rng.uniform(0.2, 0.7), tau=rng.uniform(0.01, 0.035) * (2 if big else 1), amp=a), secs(s))
    env = lambda tc: np.interp(tc, [0, 1.0, 1.5, 2.0, 2.9, 3.3], [0.05, 0.6, 1.0, 0.7, 0.05, 0])
    centre = lambda tc: np.interp(tc, [0, 1.5, 2.2, 3.2], [900, 1300, 800, 350])
    wat = shape(rng.standard_normal(n), lambda tc, f: env(tc) * np.exp(-(np.log2((f + 1) / centre(tc))) ** 2 / 1.2))
    flutter = 1 + 0.35 * np.sin(TAU * np.cumsum(9 + 4 * np.sin(TAU * 0.7 * tt(d))) / SR)
    y += 0.55 * wat * flutter / np.abs(wat).max()
    for at, m, a in ((0.15, 69, 0.28), (1.7, 62, 0.34)):  # A4 then down to D4
        place(y, a * glass(hz(m), 2.4, rng, decay=0.9, bright=0.5, strike=0.3, fm=0.2), secs(at))
    for at, f0, a in ((3.05, 1500, 0.22), (3.5, 1320, 0.12), (4.0, 1180, 0.05)):
        place(y, bubble(f0, rise=0.5, tau=0.02, amp=a), secs(at))
    y = verb(ramp_in(y, 5), make_ir(2.5, 2.0, 0.9, rng), 0.25, tail=0.4)
    y = y * np.interp(np.arange(len(y)) / SR, [0, 3.2, len(y) / SR], [1, 1, 0.3])
    return fade_out(y, 0.3)


# ---------------------------------------------------------------- the loops (built circularly, so the seam is exact)
def qf(f, L):
    """A frequency with a whole number of cycles in the loop."""
    return round(f * L) / L


def events(rng, L, count, min_gap):
    """Irregular times over [0, L) with no two closer than min_gap, wrap included."""
    while True:
        ts = np.sort(rng.uniform(0, L, count))
        gaps = np.diff(np.concatenate([ts, [ts[0] + L]]))
        if gaps.min() >= min_gap:
            return ts


def loop_bed(L, dark, seed):
    rng = np.random.default_rng(seed)
    n = secs(L)
    t = np.arange(n) / SR
    out = np.zeros((n, 2))
    send = np.zeros((n, 2))
    # the drone: detuned pairs, each with a slow swell of whole cycles per loop
    notes = ((50, 0.30), (57, 0.25), (62, 0.30), (64, 0.10), (69, 0.14)) if not dark else \
            ((50, 0.40), (53, 0.30), (57, 0.35), (60, 0.20), (62, 0.22))
    for m, a in notes:
        f = qf(hz(m), L)
        for ch in range(2):
            det = rng.integers(3, 8) / L * (1 if ch else -1)
            lfo = 1 + 0.35 * np.sin(TAU * rng.choice([1, 2, 3, 5]) * t / L + rng.uniform(0, TAU))
            v = np.sin(TAU * f * t + rng.uniform(0, TAU)) + 0.6 * np.sin(TAU * (f + det) * t + rng.uniform(0, TAU))
            v += 0.18 * np.sin(TAU * 2 * f * t + rng.uniform(0, TAU))
            out[:, ch] += a * lfo * v
    out = lp(out, 1600 if not dark else 900, circular=True)
    # bowed-glass swells
    pool = [62, 64, 69, 71, 74, 76] if not dark else [53, 57, 60, 62, 65, 67]
    for s in events(rng, L, 7 if not dark else 4, 3.0):
        dur = rng.uniform(5, 8) * (1.4 if dark else 1)
        place(send, pan(0.28 * swell(qf(hz(rng.choice(pool)), L), dur, rng), rng.uniform(-0.6, 0.6)), secs(s), True)
    # sparse struck glass
    steps = list(range(0, 8)) if not dark else None
    for s in events(rng, L, 9 if not dark else 5, 2.2):
        if dark:
            f = hz(rng.choice([62, 65, 67, 69, 72, 74]))  # D F G A C D: Dorian, down an octave
        else:
            f = degree(int(rng.choice(steps)))
        g = rng.uniform(0.25, 0.45) * glass(f, 5.0, rng, decay=rng.uniform(1.2, 2.0), bright=0.6, strike=0.25, fm=0.25)
        place(send, pan(g, rng.uniform(-0.8, 0.8)), secs(s), True)
    # droplets, some in drips of two or three
    for s in events(rng, L, 10 if not dark else 5, 1.5):
        k = rng.choice([1, 2, 3], p=[0.5, 0.3, 0.2])
        f0 = 2 ** rng.uniform(np.log2(700), np.log2(1900)) * (0.5 if dark else 1)
        p = rng.uniform(-0.9, 0.9)
        for j in range(k):
            b = bubble(f0 * rng.uniform(0.92, 1.08), rise=rng.uniform(0.3, 0.8), tau=rng.uniform(0.012, 0.03),
                       amp=0.16 * rng.uniform(0.5, 1.0) * 0.8 ** j)
            place(send, pan(b, p), secs(s + j * rng.uniform(0.35, 0.7)), True)
    # the water: a soft band of noise that breathes (whole cycles), plus a trace of fizz
    if not dark:
        wgain = lambda tc, f: (0.6 + 0.4 * np.sin(TAU * 2 * tc / L)) * np.exp(-(np.log2((f + 1) / 480)) ** 2 / 0.8) \
            + 0.06 * np.exp(-(np.log2((f + 1) / 6000)) ** 2 / 0.3)
    else:  # turbulence: a band that swirls up and down, three times a loop
        wgain = lambda tc, f: (0.7 + 0.3 * np.sin(TAU * 3 * tc / L)) * np.exp(
            -(np.log2((f + 1) / (380 * 2 ** (1.1 * np.sin(TAU * 2 * tc / L) + 0.4 * np.sin(TAU * 7 * tc / L))))) ** 2 / 0.35)
    for ch in range(2):
        w = shape(rng.standard_normal(n), wgain, frame=4096 if n % 1024 == 0 else 2048, circular=True)
        w /= np.sqrt(np.mean(w ** 2))
        if dark:  # it circles between the speakers
            w *= 0.75 + 0.25 * np.sin(TAU * 3 * t / L + ch * np.pi)
        out[:, ch] += (0.05 if not dark else 0.16) * w
    ir = make_ir(4.5 if not dark else 6.0, 4.0 if not dark else 5.5, 1.8 if not dark else 2.2, rng, channels=2)
    wet = conv(send, ir, circular=True)
    rv = conv(out, ir, circular=True)
    return out + send * 0.5 + 0.9 * wet + 0.25 * rv


# ---------------------------------------------------------------- neon hum (the second vibe)
# G, with the minor pentatonic G Bb C D F. Warm detuned saws, and a tube's buzz on 98 Hz (G2): a real UK tube buzzes at
# 100 Hz, twice the mains, and 98 keeps it in the key.
NSCALE = [0, 3, 5, 7, 10]
BUZZ = 98.0


def ndeg(k, base=67):
    """Scale step k up from `base` (67 = G4)."""
    o, i = divmod(k, len(NSCALE))
    return hz(base + 12 * o + NSCALE[i])


def partials(f, t, fc, order=2.0, square=False, phase=0.0, kmax=300):
    """A band-limited saw (or square), built from partials, through a lowpass whose cutoff may move per sample."""
    f = np.broadcast_to(np.asarray(f, float), t.shape)
    fc = np.broadcast_to(np.asarray(fc, float), t.shape)
    ph = TAU * np.cumsum(f) / SR + phase
    K = int(min(18000 / f.max(), 8 * fc.max() / f.min() + 1, kmax))
    y = np.zeros_like(t)
    for k in range(1, K + 1):
        if square and k % 2 == 0:
            continue
        y += np.sin(k * ph) / k / np.sqrt(1 + (k * f / fc) ** (2 * order))
    return y


def cents(c):
    return 2 ** (c / 1200)


def buzz(t, fc=1400, width=1.2, kmax=60, rng=None):
    """The tube: harmonics of 98 Hz with a bandpass shape, so it buzzes in the mids."""
    y = np.zeros_like(t)
    for k in range(1, kmax + 1):
        f = BUZZ * k
        g = np.exp(-(np.log2(f / fc)) ** 2 / width) / np.sqrt(k)
        y += g * np.sin(TAU * f * t + (rng.uniform(0, TAU) if rng is not None else 0))
    return y


def n_tick(v):
    rng = np.random.default_rng(1100 + v)
    d = 0.04
    t = tt(d)
    p = (1.0, 1.025, 0.976, 1.01)[v]
    f = ndeg(5) * p  # G5
    y = partials(f, t, fc=f * (1.2 + 5 * np.exp(-t / 0.003)), square=True) * np.exp(-t / 0.006)
    y += 0.25 * lp(rng.standard_normal(len(t)) * np.exp(-t / 0.0008), 5000)[:len(t)]
    return tail_fade(ramp_in(y, 0.2), 0.3)


def n_push():
    rng = np.random.default_rng(1200)
    d = 0.5
    t = tt(d)
    y = np.zeros_like(t)
    fc = 300 + 1600 * np.exp(-t / 0.07)
    for m, a, c in ((56, 1.0, -8), (57, 0.9, 5), (56, 0.6, 9)):  # Ab3 and A3 rubbing, out of the key
        y += a * partials(hz(m) * cents(c) * (1 - 0.03 * t), t, fc, phase=rng.uniform(0, TAU))
    y *= np.exp(-t / 0.14) * (1 - np.exp(-t / 0.002))
    y += 0.25 * buzz(t, fc=900, rng=rng) * np.exp(-t / 0.08)
    return trim_tail(verb(tail_fade(ramp_in(y, 0.5), 0.3), make_ir(0.7, 0.5, 0.3, rng), 0.1, tail=0.3))


def n_heal(n):
    rng = np.random.default_rng(1300 + n)
    f = ndeg(n - 1)
    d = 2.6
    t = tt(d)
    fc = f * (1.3 + 7 * np.exp(-t / 0.1))
    y = partials(f * cents(-4), t, fc, phase=rng.uniform(0, TAU)) + partials(f * cents(4), t, fc, phase=rng.uniform(0, TAU))
    y += 0.5 * partials(f / 2, t, fc * 0.8, square=True)
    y *= np.exp(-t / 0.8) * (1 - np.exp(-t / 0.0015))
    return trim_tail(verb(tail_fade(ramp_in(y, 0.5), 0.35), make_ir(2.0, 1.8, 0.9, rng), 0.2, tail=0.5))


def n_tank():
    rng = np.random.default_rng(1400)
    d = 0.45
    t = tt(d)
    f = BUZZ * (1 - 0.25 * (1 - np.exp(-t / 0.03)))
    y = 1.2 * partials(f, t, fc=250 + 1400 * np.exp(-t / 0.015), square=True) * np.exp(-t / 0.05)
    curve = np.interp(t, [0, 0.03, 0.095], [1, 0.5, 0], right=0)
    hum = buzz(t, fc=450, width=1.5, rng=rng)
    y += 1.0 * curve * hum / np.abs(hum).max()
    knock = hp(rng.standard_normal(len(t)) * np.exp(-t / 0.0015), 1500)[:len(t)]
    y += 0.7 * knock / np.abs(knock).max()
    y *= np.interp(t, [0, 0.09, 0.14, d], [1, 0.8, 0.0, 0.0])
    y = np.tanh(1.5 * y / np.abs(y).max())
    return trim_tail(verb(ramp_in(y, 0.3), make_ir(0.5, 0.4, 0.2, rng), 0.1, tail=0.3))


def n_seized():
    rng = np.random.default_rng(1500)
    d = 0.18
    t = tt(d)
    y = filt(rng.standard_normal(len(t)) * np.exp(-t / 0.012), [rbj('hp', 200), rbj('lp', 800), rbj('lp', 800)])[:len(t)]
    y /= np.abs(y).max()
    y += 0.25 * hp(rng.standard_normal(len(t)) * np.exp(-t / 0.0006), 2000)[:len(t)]
    return trim_tail(y * (1 - np.exp(-t / 0.0015)))


def n_solve():
    rng = np.random.default_rng(1600)
    d = 3.0
    t = tt(d)
    y = np.zeros_like(t)
    open_ = np.clip(t / 0.45, 0, 1)
    for m, a in ((70, 0.5), (72, 0.45), (77, 0.4)):  # Bb4 C5 F5: the bloom
        env = open_ * np.exp(-np.maximum(t - 0.45, 0) / 0.18)
        y += a * env * partials(hz(m) * cents(rng.uniform(-7, 7)), t, fc=500 + 2500 * open_, phase=rng.uniform(0, TAU))
    land = np.clip((t - 0.45) / 0.04, 0, 1) * np.exp(-np.maximum(t - 0.45, 0) / 1.1)
    fc = 900 + 2600 * np.exp(-np.maximum(t - 0.45, 0) / 0.5)
    for m, a in ((55, 0.5), (62, 0.45), (67, 0.5), (74, 0.4), (79, 0.35)):  # G3 D4 G4 D5 G5: home
        for c in (-5, 5):
            y += a * land * partials(hz(m) * cents(c), t, fc, phase=rng.uniform(0, TAU)) / 1.4
    y += 0.12 * open_ * np.exp(-np.maximum(t - 0.45, 0) / 0.3) * buzz(t, fc=2000, rng=rng)
    y = verb(tail_fade(ramp_in(y, 1.0), 0.3), make_ir(2.8, 2.4, 1.2, rng), 0.28, tail=0.3)
    return fade_out(y, 0.5)


def n_spilled():
    """The tube failing: the buzz stutters and sags, the pad slides down a fourth and closes, then two last flickers."""
    rng = np.random.default_rng(1700)
    d = 3.8
    t = tt(d)
    sag = np.interp(t, [0, 0.8, 2.6, d], [1, 1, 0.75, 0.75])
    fl = np.ones(len(t))
    s = 0.2
    while s < 3.4:  # stutters, closer together as it fails
        w = rng.uniform(0.02, 0.07)
        fl[secs(s):secs(s + w)] *= rng.uniform(0.0, 0.4)
        s += rng.exponential(0.35 if s < 1.5 else 0.15)
    fl = lp(fl, 60)[:len(t)]
    env = np.interp(t, [0, 0.05, 1.4, 2.8, 3.3], [0, 1, 0.9, 0.12, 0.0])
    b = np.zeros_like(t)
    ph = TAU * np.cumsum(BUZZ * sag) / SR
    for k in range(1, 50):
        g = np.exp(-(np.log2(BUZZ * k / 1300)) ** 2 / 1.3) / np.sqrt(k)
        b += g * np.sin(k * ph + rng.uniform(0, TAU))
    y = 0.8 * b * fl * env
    pad_env = np.interp(t, [0, 0.3, 1.8, 3.4], [0, 1, 0.7, 0])
    for m in (55, 62, 67):  # G3 D4 G4, sliding down to D3 A3 D4
        y += 0.35 * pad_env * partials(hz(m) * sag, t, fc=300 + 1200 * np.interp(t, [0, 1, 3.4], [1, 0.8, 0.05]))
    for at in (3.45, 3.62):
        k = secs(at)
        w = secs(0.035)
        y[k:k + w] += 0.3 * b[k:k + w] * np.hanning(w)
    y = verb(ramp_in(y, 3), make_ir(2.0, 1.8, 0.8, rng), 0.2, tail=0.5)
    return fade_out(y, 0.4)


def n_loop(L, seed):
    rng = np.random.default_rng(seed)
    n = secs(L)
    t = np.arange(n) / SR
    out = np.zeros((n, 2))
    send = np.zeros((n, 2))
    fc = 650 * 2 ** (0.5 * np.sin(TAU * 2 * t / L + 1.0) + 0.2 * np.sin(TAU * 5 * t / L))
    for m, a in ((43, 0.30), (50, 0.30), (55, 0.30), (58, 0.22), (62, 0.18)):  # G2 D3 G3 Bb3 D4
        f = qf(hz(m), L)
        for ch in range(2):
            det = rng.integers(2, 6) / L * (1 if ch else -1)
            lfo = 1 + 0.3 * np.sin(TAU * rng.choice([1, 2, 3]) * t / L + rng.uniform(0, TAU))
            v = partials(f, t, fc, phase=rng.uniform(0, TAU), kmax=40) + partials(f + det, t, fc, phase=rng.uniform(0, TAU), kmax=40)
            out[:, ch] += a * lfo * v
    # the tube, faint, with a slow flicker (smooth periodic noise)
    fl = shape(rng.standard_normal(n), lambda tc, f: (f < 4).astype(float), frame=16384 if n % 4096 == 0 else 8192, circular=True)
    fl = 1 + 0.5 * fl / np.abs(fl).max()
    bz = buzz(t, fc=1500, rng=rng)
    for ch in range(2):
        out[:, ch] += 0.03 * bz * fl
    for s in events(rng, L, 8, 2.5):  # soft plucks
        d = 2.4
        tp = tt(d)
        f = ndeg(int(rng.integers(0, 8)))
        g = partials(f, tp, fc=f * (1.2 + 3 * np.exp(-tp / 0.15))) * np.exp(-tp / 0.7) * (1 - np.exp(-tp / 0.004))
        place(send, pan(rng.uniform(0.12, 0.22) * tail_fade(g, 0.3), rng.uniform(-0.7, 0.7)), secs(s), True)
    ir = make_ir(4.0, 3.5, 1.5, rng, channels=2)
    return out + 0.5 * send + 0.8 * conv(send, ir, circular=True) + 0.2 * conv(out, ir, circular=True)


# ---------------------------------------------------------------- measuring
KW = [(np.array([1.53512485958697, -2.69169618940638, 1.19839281085285]), np.array([1.0, -1.69065929318241, 0.73248077421585])),
      (np.array([1.0, -2.0, 1.0]), np.array([1.0, -1.99004745483398, 0.99007225036621]))]


def block_power(x):
    y = filt(x, KW)[:len(x)]
    p = y ** 2 if y.ndim == 1 else (y ** 2).sum(axis=1)
    c = np.concatenate([[0], np.cumsum(p)])
    B, H = secs(0.4), secs(0.1)
    st = np.arange(0, len(p) - B + 1, H)
    return (c[st + B] - c[st]) / B


def lufs(p):
    return -0.691 + 10 * np.log10(np.maximum(p, 1e-30))


# A mono effect plays on both of the phone's speakers, so it is measured as dual mono (+3 dB), as ebur128's dualmono does.
def dual(x):
    return 10 * np.log10(2) if x.ndim == 1 else 0.0


def m_max(x):
    pad = np.zeros((secs(0.5),) + x.shape[1:])
    return lufs(block_power(np.concatenate([pad, x, pad])).max()) + dual(x)


def integrated(x):
    z = block_power(x)
    z = z[lufs(z) > -70]
    z = z[lufs(z) > lufs(z.mean()) - 10]
    return lufs(z.mean()) + dual(x)


def true_peak(x):
    X = np.fft.rfft(x, axis=0)
    N = 4 * len(x)
    Y = np.zeros((N // 2 + 1,) + X.shape[1:], complex)
    Y[:len(X)] = X
    return 20 * np.log10(np.abs(np.fft.irfft(Y, N, axis=0)).max() * 4)


def db(v):
    return 20 * np.log10(max(v, 1e-12))


def onset_ms(x, rel=-40):
    a = np.abs(x) if x.ndim == 1 else np.abs(x).max(axis=1)
    return 1000 * np.argmax(a >= a.max() * 10 ** (rel / 20)) / SR


def rms_db(x):
    return 10 * np.log10(np.mean(np.asarray(x) ** 2) + 1e-30)


def centroid(x):
    m = x if x.ndim == 1 else x.mean(axis=1)
    P = np.abs(np.fft.rfft(m)) ** 2
    f = np.fft.rfftfreq(len(m), 1 / SR)
    return (P * f).sum() / P.sum()


def band_share(x, lo, hi):
    m = x if x.ndim == 1 else x.mean(axis=1)
    P = np.abs(np.fft.rfft(m)) ** 2
    f = np.fft.rfftfreq(len(m), 1 / SR)
    return P[(f >= lo) & (f < hi)].sum() / P.sum()


def write_wav(path, x):
    x = np.asarray(x, float)
    q = np.clip(np.round(x * 32767), -32768, 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1 if x.ndim == 1 else x.shape[1])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(q.tobytes())
    return q.astype(float) / 32767


CEILING_TP = -1.2  # dBTP, a little under the -1 dBFS limit so the 16-bit rounding can't cross it

ROWS = []
FILES = {}


def measure(name, x, note=''):
    """Record the measurements for a written file and write its phone copy (not renormalised)."""
    ph = filt(x, PHONE_HP)[:len(x)]
    write_wav(os.path.join(PHONE, f'{name}.wav'), ph)
    row = dict(name=name, dur=len(x) / SR, ch=1 if x.ndim == 1 else 2, M=m_max(x),
               I=integrated(x) if len(x) > secs(1.0) else None, peak=db(np.abs(x).max()), tp=true_peak(x),
               onset=onset_ms(x), phone_loss=rms_db(ph) - rms_db(x), phone_dM=m_max(ph) - m_max(x),
               below250=band_share(x, 0, 250), centroid=centroid(x), note=note)
    ROWS.append(row)
    FILES[name] = x
    print(f"  {name:14s} {row['dur']:5.2f}s  M {row['M']:6.1f}  peak {row['peak']:5.1f}  TP {row['tp']:5.1f}  "
          f"onset {row['onset']:4.1f} ms  phone {row['phone_loss']:5.1f} dB {note}")
    return x


def finish(name, x, target, how='M'):
    """Normalise to the loudness target, hold the true peak under the ceiling, write the WAV and measure it."""
    x = np.asarray(x, float)
    cur = m_max(x) if how == 'M' else integrated(x)
    g = 10 ** ((target - cur) / 20)
    tp = true_peak(x * g)
    note = ''
    if tp > CEILING_TP:
        g *= 10 ** ((CEILING_TP - tp) / 20)
        note = f'peak-limited, {target - (m_max(x * g) if how == "M" else integrated(x * g)):.1f} LU under target'
    x = write_wav(os.path.join(HERE, f'{name}.wav'), x * g)
    return measure(name, x, note)


# ---------------------------------------------------------------- ffmpeg checks
def ffmpeg(*args, **k):
    return subprocess.run(['ffmpeg', '-hide_banner', '-nostdin', '-y', *args], capture_output=True, text=True, **k)


def ebur128(path, mono):
    dm = ':dualmono=true' if mono else ''
    r = ffmpeg('-nostats', '-i', path, '-af', f'apad=pad_dur=0.5,ebur128=peak=sample+true{dm}:framelog=info', '-f', 'null', '-')
    s = r.stderr
    Ms = [float(v) for v in re.findall(r' M:\s*(-?[\d.]+)', s) if v not in ('-', '')]
    summ = s[s.rfind('Summary:'):]
    grab = lambda pat: float(re.search(pat, summ, re.S).group(1))
    return dict(M=max(Ms) if Ms else float('nan'), I=grab(r'I:\s+(-?[\d.]+|-inf) LUFS') if 'I:' in summ else None,
                tp=grab(r'True peak:\s+Peak:\s+(-?[\d.]+|-inf)'), sp=grab(r'Sample peak:\s+Peak:\s+(-?[\d.]+|-inf)'))


def spectrogram(wav, png, dur):
    # Short sounds are padded so the picture has enough time columns to read.
    pad = max(0.0, 0.3 - dur)
    af = f'apad=pad_dur={pad},' if pad > 0 else ''
    ffmpeg('-i', wav, '-lavfi', f'{af}showspectrumpic=s=900x420:legend=1:fscale=log:drange=100:mode=combined', png)


def contact(pngs, out, cols=3):
    from PIL import Image, ImageDraw
    ims = [Image.open(p).convert('RGB') for p in pngs]
    w, h = ims[0].size
    rows = -(-len(ims) // cols)
    sheet = Image.new('RGB', (cols * w, rows * (h + 24)), 'black')
    d = ImageDraw.Draw(sheet)
    for i, (p, im) in enumerate(zip(pngs, ims)):
        x, y = (i % cols) * w, (i // cols) * (h + 24)
        sheet.paste(im.resize((w, h)), (x, y + 24))
        d.text((x + 8, y + 4), os.path.basename(p), fill='white')
    sheet.save(out)


# ---------------------------------------------------------------- the reel and the film
def reel(pre='', dest='reel.m4a'):
    gap = secs(1.0)
    parts, at = [], 0

    def add(x, dt=0.0):
        nonlocal at
        parts.append((at + secs(dt), x))

    # tick: a drag of eight detents at about 8 a second, the variants in turn
    for i in range(8):
        add(FILES[f'{pre}tick-{i % 4 + 1}'], i * 0.125)
    at = mixlen(parts) + gap
    for name in ('push',):
        add(FILES[pre + name]); at = mixlen(parts) + gap
    for k in range(1, 7):  # the heal run, a heal every 0.9 s so the climb is audible
        add(FILES[f'{pre}heal-{k}'], (k - 1) * 0.9)
    at = mixlen(parts) + gap
    for k in range(2):  # two tank steps
        add(FILES[pre + 'tank'], k * 0.7)
    at = mixlen(parts) + gap
    for name in ('seized', 'solve', 'spilled'):
        add(FILES[pre + name]); at = mixlen(parts) + gap
    fx = mix(parts)
    fx = np.stack([fx, fx], axis=1) * np.sqrt(0.5) * np.sqrt(2)  # mono centred, same level per channel
    # then 20 s of the loop with play laid on it
    L = FILES[pre + 'loop'][:secs(20)]
    over = []

    def drag(t0, n, rate=9.0, first=0):
        for i in range(n):
            over.append((secs(t0 + i / rate), FILES[f'{pre}tick-{(first + i) % 4 + 1}']))
        return t0 + (n - 1) / rate + 0.12

    # (drag start, detents, what the release plays). Heal 2 is the push turned back, which the game counts as a cancel.
    play = [(1.5, 2, ['heal-1']), (4.2, 3, ['push']), (6.3, 3, ['heal-2']), (8.8, 4, ['heal-3']), (11.0, 2, ['heal-4']),
            (12.9, 3, ['heal-5']), (14.8, 5, ['heal-6', 'solve'])]
    overlay, c = [], 0
    for t0, n, names in play:
        t = drag(t0, n, first=c)
        c += n
        for name in names:
            over.append((secs(t), FILES[pre + name]))
            overlay.append((name, t))
    ov = mix(over, len(L))
    tail = L + np.stack([ov, ov], axis=1) * 1.0
    tail = fade_out(tail, 1.5)
    out = np.concatenate([fx, np.zeros((gap, 2)), tail])
    tp = true_peak(out)
    if tp > CEILING_TP:
        out *= 10 ** ((CEILING_TP - tp) / 20)
    write_wav(os.path.join(BUILD, pre.replace('/', '-') + 'reel.wav'), out)
    ffmpeg('-i', os.path.join(BUILD, pre.replace('/', '-') + 'reel.wav'), '-c:a', 'aac', '-b:a', '256k', os.path.join(HERE, dest))
    return dict(dur=len(out) / SR, tp=true_peak(out), fx_end=len(fx) / SR, overlay=overlay)


def ease_in_out_time(p, x1=0.42, x2=0.58):
    """SwiftUI's .easeInOut is the cubic Bezier (0.42, 0, 0.58, 1): the time fraction at which progress reaches p."""
    s = np.linspace(0, 1, 20001)
    bx = 3 * (1 - s) ** 2 * s * x1 + 3 * (1 - s) * s ** 2 * x2 + s ** 3
    by = 3 * (1 - s) * s ** 2 + s ** 3  # y1 = 0, y2 = 1
    return float(np.interp(p, by, bx))


def film_frames(path=FILM_IN):
    """Every frame of a recording at its own timestamp (simctl writes a frame only when the screen changes)."""
    pts = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v', '-show_entries', 'frame=pts_time', '-of', 'csv=p=0',
                          path], capture_output=True, text=True).stdout.split()
    pts = np.array([float(p.strip(',')) for p in pts])
    side = 150
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-fps_mode', 'passthrough', '-vf',
                        f'crop=1200:1200:60:820,scale={side}:{side}', '-pix_fmt', 'rgb24', '-f', 'rawvideo', '-'],
                       capture_output=True)
    fr = np.frombuffer(r.stdout, np.uint8).reshape(-1, side, side, 3).astype(float)
    assert len(fr) == len(pts)
    return pts, fr, side


def seam_check(x):
    """The wrap from the last sample to the first, against the file's own sample-to-sample steps."""
    out = []
    for c in range(x.shape[1]):
        v = x[:, c]
        d1 = np.abs(np.diff(v))
        d2 = np.abs(np.diff(v, 2))
        w1 = abs(v[0] - v[-1])
        w2 = abs(v[1] - 2 * v[0] + v[-1])
        out.append(dict(jump=w1, med=np.median(d1), p99=np.percentile(d1, 99), max=d1.max(),
                        jump2=w2, p99_2=np.percentile(d2, 99), rank=(d1 < w1).mean()))
    around = rms_db(x[-secs(0.25):]) - rms_db(x[:secs(0.25)])
    # A click is a burst above 4 kHz: rank the 2 ms around the wrap among every 2 ms of the file.
    r = np.roll(x, len(x) // 2, axis=0)
    h = filt(r, [rbj('hp', 4000, q) for q in (0.54, 1.31)])[:len(r)]
    e = np.convolve((h ** 2).sum(axis=1), np.ones(secs(0.002)) / secs(0.002), mode='same')
    hf_rank = (e < e[len(x) // 2]).mean()
    return out, around, hf_rank


def ring_and_wave(pts, fr, side):
    """Per frame: the white of the solve's wave in the tank, and magenta round rod 2's knob (its cancel ring)."""
    yy, xx = np.mgrid[0:side, 0:side]
    disc = lambda cx, cy, r: np.hypot(xx - side / 2 * (1 + cx), yy - side / 2 * (1 + cy)) < r * side / 2
    R, G, B = fr[..., 0], fr[..., 1], fr[..., 2]
    white = ((R > 225) & (G > 225) & (B > 225))[:, disc(0, 0, 0.92)].mean(axis=1)
    # Level 9 is a quad: rod 0 top right, rod 2 bottom left (Layout ring(4, 0.5, 0.48, from: -45)).
    magenta2 = ((R > 150) & (B > 120) & (G < 90))[:, disc(-0.34, 0.34, 0.12)].mean(axis=1)
    k = np.nonzero((white > 2e-4) & (pts > 3))[0][0]
    j = np.nonzero((magenta2 > 0.004) & (pts > 3) & (pts < pts[k]))[0][0]
    return white, magenta2, j, k


def film_events():
    """Where the ticks, heals and solve go in autoplay-L09.mp4, found by frame differencing on the recording's clock."""
    pts, fr, side = film_frames()
    yy, xx = np.mgrid[0:side, 0:side]
    disc = lambda cx, cy, r: np.hypot(xx - side / 2 * (1 + cx), yy - side / 2 * (1 + cy)) < r * side / 2
    inside = disc(0, 0, 0.92)
    R, G, B = fr[..., 0], fr[..., 1], fr[..., 2]
    gray = fr.mean(axis=3)
    diff = np.concatenate([[0], np.abs(np.diff(gray, axis=0))[:, inside].mean(axis=1)])
    lum = gray[:, inside].mean(axis=1)
    white, magenta2, j, k = ring_and_wave(pts, fr, side)
    np.savetxt(os.path.join(BUILD, 'film-frames.csv'), np.stack([pts, diff, lum, white, magenta2], axis=1), delimiter=',',
               header='t,diff,lum,white,magenta_rod2', fmt='%.4f')
    between = lambda k: (pts[k - 1] + pts[k]) / 2  # a change lands between the frame that shows it and the one before
    launch = pts[np.argmax(lum < 40)]  # the app's black replaces the home screen, as film.sh finds it
    t_solve = between(k)  # the first white of the wave, which starts on the last commit
    t_heal1 = between(j)  # the magenta cancel ring appearing round rod 2's knob
    # Autoplay turns a rod by an .easeInOut of exactly 0.4 s, then lets go, and the commit comes straight away because the
    # settle has no distance to cover (TankView.play/release). So each turn ends on its commit.
    turns = [(t_heal1 - 0.4, 4), (t_solve - 0.4, 3)]  # "0:+3,2:-4": rod 2 back 4 steps, then rod 0 back 3
    # Cross-check: the first motion before the first commit, after the quiet that follows the wind-in.
    moving = np.nonzero((diff > 0.05) & (pts < t_heal1 - 0.1) & (pts > launch + 1))[0]
    gaps = np.diff(pts[moving])
    start1 = pts[moving[np.nonzero(gaps > 0.15)[0][-1] + 1]]
    ticks = [t0 + 0.4 * ease_in_out_time(i / m) for t0, m in turns for i in range(1, m + 1)]
    return dict(launch=launch, t_solve=t_solve, t_heal1=t_heal1, turns=turns, ticks=ticks, heals=[t_heal1, t_solve],
                seen_start1=start1, pause=turns[1][0] - t_heal1)


def make_film():
    ev = film_events()
    dur = 8.0 + 2.0
    n = secs(dur)
    parts = []
    for i, tk in enumerate(ev['ticks']):
        parts.append((secs(tk), FILES[f'tick-{i % 4 + 1}']))
    parts.append((secs(ev['heals'][0]), FILES['heal-1']))
    parts.append((secs(ev['heals'][1]), FILES['heal-2']))
    parts.append((secs(ev['t_solve']), FILES['solve']))
    fx = mix(parts, n)
    fx = np.stack([fx, fx], axis=1)
    bed = np.zeros((n, 2))
    lp0 = secs(ev['launch'])
    loop = FILES['loop']
    bed[lp0:] = loop[:n - lp0]
    ramp = np.clip((np.arange(n) - lp0) / secs(1.5), 0, 1)[:, None]
    out = fade_out(fx + bed * ramp, 1.0)
    tp = true_peak(out)
    if tp > CEILING_TP:
        out *= 10 ** ((CEILING_TP - tp) / 20)
    wav = os.path.join(BUILD, 'film-L09.wav')
    write_wav(wav, out)
    # Re-encoded at a constant 60 fps, with the last frame held 2 s so the solve's tail plays over the result card.
    # The fps filter keeps each frame at its source time; the -r output option lagged the picture by about 30 ms.
    r = ffmpeg('-i', FILM_IN, '-i', wav, '-map', '0:v', '-map', '1:a', '-vf', 'fps=60,tpad=stop_mode=clone:stop_duration=2',
               '-c:v', 'libx264', '-crf', '20', '-preset', 'medium', '-pix_fmt', 'yuv420p',
               '-c:a', 'aac', '-b:a', '256k', '-shortest', os.path.join(HERE, 'film-L09.mp4'))
    if r.returncode:
        print(r.stderr[-2000:])
    # Check the finished film: where its picture first shows the ring and the wave, against the audio's events.
    pts, fr, side = film_frames(os.path.join(HERE, 'film-L09.mp4'))
    _, _, j, k = ring_and_wave(pts, fr, side)
    ev['shown'] = (pts[j], pts[k])
    ev['lag'] = (pts[j] - ev['t_heal1'], pts[k] - ev['t_solve'])
    return ev


def spectrograms(names, sheet):
    pngs, phones = [], []
    for name in names:
        x = FILES[name]
        for src, dst, acc in ((os.path.join(HERE, f'{name}.wav'), os.path.join(SPEC, f'{name}.png'), pngs),
                              (os.path.join(PHONE, f'{name}.wav'), os.path.join(SPEC, 'phone', f'{name}.png'), phones)):
            spectrogram(src, dst, len(x) / SR)
            acc.append(dst)
    contact(pngs, os.path.join(SPEC, f'{sheet}.png'))
    contact(phones, os.path.join(SPEC, 'phone', f'{sheet}.png'))


WHAT = {
    'tick': 'one 30° detent while a rod is dragged: a tiny glass bead at D7 (2349 Hz) with a little body at D5, 50 ms. '
            'Four round-robin variants (pitch within ±3%, partial spacing, noise seed), chosen by detent count only',
    'push': 'a wrong stir: an Eb4-E4-F4 cluster, out of key, beating at about 19 and 38 Hz; murky FM that clears, a 3.5% '
            'sag, a low bubble "blup", lowpassed at 1.3 kHz',
    'heal': 'heal number n (heals so far, never twists left): a bubble plip rising into a struck glass on step n up from '
            'D5 (D5 E5 G5 A5 B5 D6). Glass = free-bar partials 1, 2.76, 5.40, 8.93 as slow-beating doublets, a soft FM '
            'strike, an octave-down body, a 2.2 s room',
    'heal-run': 'the six heals 0.9 s apart, to hear the climb (a listening file, not a game asset)',
    'tank': 'one step of the tank: a knock at 0 ms, seven damped stone-and-steel modes from 188 to 1905 Hz, a 420 Hz band '
            'of rumble riding the haptic\'s own curve (1, 0.5 at 30 ms, 0 at 95 ms), a 92 Hz sub for headphones, light '
            'saturation. The body is over by 140 ms, then a short room',
    'seized': 'a touch on a dead knob: an 11 ms noise burst band-limited to 180-1100 Hz and seven close modes damped in '
              '8 ms. No ring, no pitch',
    'solve': 'the bloom: 11 rising bubbles (the wave), a quick E5-G5-B5-E6 wash, and at 0.42 s D4-D5-A5-D6 landing on the '
             'tonic with a bowed D4 swell under it',
    'spilled': 'endless overflows: a stream of bubbles swelling to 170 a second, rushing water whose centre glides '
               '900 → 1300 → 350 Hz, A4 then D4 glass falling to the tonic, three last drips into near-silence',
    'loop': 'plughole\'s bed, 48 s stereo, seamless: a D drone (D3 A3 D4 E4 A4 in slow-beating pairs), 7 bowed-glass '
            'swells, 9 glass pings from the scale, 10 drips (some in twos and threes), a breathing band of water noise, a '
            '4 s reverb. '
            'Built as one period of a loop, so the wrap is like any other sample',
    'maelstrom': '20 s of how maelstrom would deepen the bed, also seamless: D Dorian (a Dm7 drone D3 F3 A3 C4 D4), a '
                 'turbulent band of noise that swirls up and down and circles the speakers, fewer and lower pings, '
                 'lower bubbles, a 5.5 s reverb',
    'neon/tick': 'a lowpassed square blip at G5 with a click, four variants',
    'neon/push': 'Ab3 and A3 saws rubbing (out of key) under a falling filter, with a burst of tube buzz',
    'neon/heal': 'heal n: a pair of saws 8 cents apart and a square an octave down, a filter pluck; G4 Bb4 C5 D5 F5 G5',
    'neon/heal-run': 'the six neon heals 0.9 s apart',
    'neon/tank': 'a square thump at G2 dropping a fourth, tube hum on the haptic curve, a knock, light saturation',
    'neon/seized': 'a dull noise thud and a click',
    'neon/solve': 'Bb4 C5 F5 swelling open, landing on G3 D4 G4 D5 G5 with a flare of tube buzz',
    'neon/spilled': 'the tube failing: its buzz stutters and sags, the pad slides down a fourth and closes, two last '
                    'flickers',
    'neon/loop': '48 s, seamless: a detuned saw pad on Gm (G2 D3 G3 Bb3 D4) under a slow filter, a faint 98 Hz tube buzz '
                 'that flickers, 8 soft plucks',
}


def what(name):
    base = re.sub(r'-\d$', '', name)
    return WHAT.get(name) or WHAT.get(base, '')


def listing(w, names, notes):
    """One line per file; a family's design is described once, on its first member."""
    seen = set()
    for name in names:
        m = re.match(r'(.*?)(tick|heal)-(\d)$', name)
        if m and m.group(1) + m.group(2) in seen:
            k = int(m.group(3))
            w(f"- `{name}.wav`: " + (f'variant {k}.' if m.group(2) == 'tick' else f'heal {k}, {notes[k - 1]}.'))
            continue
        if m:
            seen.add(m.group(1) + m.group(2))
            extra = ' This one is variant 1.' if m.group(2) == 'tick' else f' This one is heal 1, {notes[0]}.'
            w(f"- `{name}.wav`: {what(name)}.{extra}")
        else:
            w(f"- `{name}.wav`: {what(name)}.")


def write_listen(seams, rl, rn, ev, overlay, drag):
    L = []
    w = L.append
    w('# Unstir sound sketch: listen\n')
    w('Everything here is synthesized by `make.py` (numpy, no samples); `python3 make.py` rebuilds it all.\n')
    w('## Listen\n')
    w('```')
    w(f'cd {HERE}')
    w('afplay reel.m4a              # glass and water: every effect in order, then 20 s of the loop with play on it')
    w('open film-L09.mp4            # autoplay unstirring level 9, with ticks, heals, solve and the loop')
    w('afplay maelstrom.wav         # 20 s of the deeper bed')
    w('afplay build/loop-seam.wav   # the loop\'s last 4 s straight into its first 4 s')
    w('afplay neon/reel.m4a         # the second vibe, neon hum, same layout')
    w('afplay phone/heal-3.wav      # any file through the 250 Hz high-pass, roughly what a phone speaker keeps')
    w('```\n')
    t0 = rl['fx_end'] + 1.0
    w(f"The reel: effects from 0 to {rl['fx_end']:.1f} s (eight ticks at 8 a second, push, the heal run, two tank steps, "
      f"seized, solve, spilled), a second of silence, then 20 s of the loop from {t0:.1f} s with play laid on it: "
      + ', '.join(f'{name} at {t0 + at:.1f} s' for name, at in overlay)
      + '. Heal 2 there is the push being turned back, which the game counts as a cancel.\n')
    w('## Glass and water: D, with the pentatonic D E G A B\n')
    w('The scale has no third, so the heals and the solve sit over the major-ish plughole bed and the Dorian maelstrom '
      'alike. Heal n plays step n from D5, so heal 6 lands on the octave, D6. Past 6 it keeps climbing (E6, G6, ...) '
      'unless you decide otherwise.\n')
    listing(w, [r['name'] for r in ROWS if not r['name'].startswith('neon/')], 'D5 E5 G5 A5 B5 D6'.split())
    w('\n## Neon hum: G, with the minor pentatonic G Bb C D F\n')
    w('Warm detuned saws built from partials, and a tube buzz on 98 Hz (G2; a UK tube buzzes at 100 Hz, twice the '
      'mains, and 98 keeps it in the key). No maelstrom excerpt or film for this one.\n')
    listing(w, [r['name'] for r in ROWS if r['name'].startswith('neon/')], 'G4 Bb4 C5 D5 F5 G5'.split())
    w('\n## Measurements\n')
    agree = max(abs(r['M'] - r['ff']['M']) for r in ROWS)
    w('M is the loudest 400 ms momentary loudness (EBU R128), the fair measure for short sounds; I is integrated '
      'loudness, reported for the beds. Mono effects are measured as dual mono (+3 dB), since the phone plays them on '
      f'both speakers. make.py\'s own meter and ffmpeg `ebur128` differ by at most {agree:.2f} LU on M across all files; '
      'the table shows ffmpeg\'s. '
      'Onset: first sample within 40 dB of the file\'s peak. Phone: the change in M through an 8th-order Butterworth '
      'high-pass at 250 Hz (copies in `phone/`), and the share of energy below 250 Hz. Spectrograms are in `spec/` '
      '(`contact.png`, `contact-neon.png`, and the same under `spec/phone/`).\n')
    w('| file | s | M (LUFS) | I (LUFS) | sample peak (dBFS) | true peak (dBTP) | onset (ms) | phone ΔM (LU) | below 250 Hz |')
    w('|---|---|---|---|---|---|---|---|---|')
    for r in ROWS:
        f, fp = r['ff'], r['ff_phone']
        I = f"{f['I']:.1f}" if r['dur'] > 1.0 and f['I'] is not None else '-'
        w(f"| {r['name']} | {r['dur']:.2f} | {f['M']:.1f} | {I} | {f['sp']:.1f} | {f['tp']:.1f} | {r['onset']:.1f} | "
          f"{fp['M'] - f['M']:+.1f} | {100 * r['below250']:.0f}% |" + (f" {r['note']}" if r['note'] else ''))
    w('')
    w(f"Targets (M): solve -15, heal -16, tank -17, spilled -18, push -19, seized -22, tick -30 for a lone tick; a "
      f"drag at 10 detents a second measures {drag['glass']:.1f} (neon {drag['neon']:.1f}). Beds: I -32 (-31 for "
      f"maelstrom), 16 LU under a heal's M. Every file's true peak is -1.2 dBTP or lower (the limit is -1).\n")
    enc = ', '.join(f"`{name}` {ebur128(os.path.join(HERE, name), False)['tp']:.1f}"
                    for name in ('reel.m4a', 'neon/reel.m4a', 'film-L09.mp4') if os.path.exists(os.path.join(HERE, name)))
    w(f'Encoded files, true peak of the audio after AAC (dBTP): {enc}.\n')
    w('Seams (the jump from the last sample to the first, against the file\'s own sample-to-sample steps):\n')
    for name, (chs, around, hf) in seams.items():
        for c, x in enumerate(chs):
            w(f"- `{name}` ch{c}: jump {x['jump'] * 32767:.0f} LSB; median step {x['med'] * 32767:.0f}, 99th percentile "
              f"{x['p99'] * 32767:.0f}, largest {x['max'] * 32767:.0f}. Curvature at the wrap {x['jump2'] * 32767:.0f} LSB "
              f"against a 99th percentile of {x['p99_2'] * 32767:.0f}.")
        w(f"- `{name}`: RMS of the last 250 ms against the first 250 ms: {around:+.2f} dB. Energy above 4 kHz in the "
          f"2 ms round the wrap (where a click would show) is above {100 * hf:.0f}% of the file's 2 ms windows: an "
          f"ordinary moment, as it should be for a loop built as one period.")
    w('')
    if ev:
        w('## The film\n')
        w(f"`film-L09.mp4` is `shots/film/autoplay-L09.mp4` re-encoded at 60 fps with the last frame held 2 s for the "
          f"solve's tail. Times are on the recording's own clock, from each frame's timestamp (the recorder writes a "
          f"frame only when the screen changes), and each change is put halfway between the frame that shows it and the "
          f"one before.\n")
        w(f"- The app opens at {ev['launch']:.3f} s (the screen goes black); the loop fades in over 1.5 s from there.")
        w(f"- Heal 1 at {ev['t_heal1']:.3f} s: the magenta cancel ring first appears round rod 2's knob.")
        w(f"- Heal 2 and the solve at {ev['t_solve']:.3f} s: the first white of the wave, which starts on the last commit.")
        w(f"- Each autoplay turn is an `.easeInOut` of exactly 0.4 s that commits as it lets go (`TankView.play`), so "
          f"each turn is taken to end on its commit: rod 2 turns from {ev['turns'][0][0]:.3f} s (4 steps), rod 0 from "
          f"{ev['turns'][1][0]:.3f} s (3 steps; level 9's scramble is \"0:+3,2:-4\"). Cross-checks: the first motion "
          f"before heal 1 is seen at {ev['seen_start1']:.3f} s, and the pause between the turns comes out "
          f"{ev['pause'] * 1000:.0f} ms against the 300 ms sleep in the code.")
        w(f"- Ticks where the easing curve crosses each 30° (where `trunc(angle / 30°)` changes in a real drag): "
          + ', '.join(f'{x:.3f}' for x in ev['ticks'])
          + ' s. Autoplay moves the knob without a drag, so the game itself fires no ticks here; these are where a '
            'finger following the same curve would.')
        w(f"- Checked on the finished film: its picture first shows the ring at {ev['shown'][0]:.3f} s and the wave at "
          f"{ev['shown'][1]:.3f} s, {ev['lag'][0] * 1000:+.0f} and {ev['lag'][1] * 1000:+.0f} ms from their sounds (a 60 fps "
          f"frame is 17 ms).\n")
    w('## Wiring, as I read TankView.swift on turning-tank\n')
    w('tick on `ticks`, tank on `tankTicks` (where `Clunk.play()` is), push on `game.pushes`, heal on `game.cancels` '
      '(pitch from the count since the level opened), solve on `game.solved`, spilled on `game.runOver`. Seized has no '
      'trigger yet: it would go where the drag guard refuses a seized knob. Nothing is keyed to the angle, the rod or '
      'the stack, and nothing sounds continuously during a drag.\n')
    w('## What needs ears (questions for Jack)\n')
    for q in QUESTIONS:
        w(f'- {q}')
    w('\n## What the checks do not cover\n')
    for q in LIMITS:
        w(f'- {q}')
    with open(os.path.join(HERE, 'listen.md'), 'w') as f:
        f.write('\n'.join(L) + '\n')


QUESTIONS = [
    'Heal: is it the most satisfying sound here? Does the bubble plip into glass read as "one twist gone", and is 3 s of '
    'ring too long when heals come a second apart?',
    'The climb: is D5 up to D6 the right register, and what should happen past heal 6 on long levels: keep climbing '
    '(heal 11 is D7, shrill), fold back an octave, or hold the top note?',
    'Turning a push back counts as a cancel in the code, so it plays the next heal up. Fine, or should only a twist of the '
    'scramble climb the scale?',
    'Push: nudge or nasty? The Eb-E-F cluster beats at about 19 Hz; is that "mixed" or just sour?',
    'Tick: audible over the bed at -30, and not a machine gun at 10 a second? Too bright at D7?',
    'Tank against tick and seized: three clearly different things? Is the tank heavy enough on the phone speaker, and '
    'does it sit with the Clunk haptic?',
    'Seized: dead enough, or too close to the tank\'s knock?',
    'Solve with the last heal: the film plays both at once. Do they clash, or should the solve replace the last heal?',
    'Spilled: does it read as water overflowing, sad without scolding?',
    'Loop: level (16 LU under a heal), too much drone, too few pings, and does anything give away the 48 s repeat?',
    'Maelstrom: dark and turbulent enough, or just muddier?',
    'Glass and water against neon hum: which way, or a blend (glass heals over the neon bed)?',
]

LIMITS = [
    'A phone speaker is not a 250 Hz high-pass: it has its own resonances and top-end roll-off. Only the phone will tell.',
    'Loudness meters underrate very short sounds, so the tick\'s level is a guess until heard.',
    'Whether the dissonances read as "wrong" rather than "ugly", whether anything is fatiguing on the tenth hearing, '
    'and whether the reverbs sound like a tank or a cathedral.',
    'The reel and film audio are AAC at 256 kb/s, for listening only; the WAVs are the assets.',
    'The sub-250 Hz claim for iPhone speakers came in the brief as an inference; I did not measure a phone.',
]


def main():
    no_film = '--no-film' in sys.argv
    for d in (BUILD, PHONE, SPEC, os.path.join(SPEC, 'phone'), os.path.join(HERE, 'neon'), os.path.join(PHONE, 'neon'),
              os.path.join(SPEC, 'neon'), os.path.join(SPEC, 'phone', 'neon')):
        os.makedirs(d, exist_ok=True)
    print('glass and water: D, pentatonic D E G A B')
    for v in range(4):
        finish(f'tick-{v + 1}', tick(v), -30)
    finish('push', push(), -19)
    for k in range(1, 7):
        finish(f'heal-{k}', heal(k), -16)
    run = mix([(secs(0.9 * (k - 1)), FILES[f'heal-{k}']) for k in range(1, 7)])
    measure('heal-run', write_wav(os.path.join(HERE, 'heal-run.wav'), run), 'the six heals 0.9 s apart, not renormalised')
    finish('tank', tank(), -17)
    finish('seized', seized(), -22)
    finish('solve', solve(), -15)
    finish('spilled', spilled(), -18)
    finish('loop', loop_bed(48.0, False, 800), -32, how='I')
    finish('maelstrom', loop_bed(20.0, True, 900), -31, how='I')
    glass_names = [r['name'] for r in ROWS]

    print('neon hum: G, minor pentatonic G Bb C D F')
    for v in range(4):
        finish(f'neon/tick-{v + 1}', n_tick(v), -30)
    finish('neon/push', n_push(), -19)
    for k in range(1, 7):
        finish(f'neon/heal-{k}', n_heal(k), -16)
    run = mix([(secs(0.9 * (k - 1)), FILES[f'neon/heal-{k}']) for k in range(1, 7)])
    measure('neon/heal-run', write_wav(os.path.join(HERE, 'neon/heal-run.wav'), run), 'not renormalised')
    finish('neon/tank', n_tank(), -17)
    finish('neon/seized', n_seized(), -22)
    finish('neon/solve', n_solve(), -15)
    finish('neon/spilled', n_spilled(), -18)
    finish('neon/loop', n_loop(48.0, 1800), -32, how='I')
    neon_names = [r['name'] for r in ROWS if r['name'].startswith('neon/')]

    print('ffmpeg ebur128 cross-check')
    for row in ROWS:
        row['ff'] = ebur128(os.path.join(HERE, f"{row['name']}.wav"), row['ch'] == 1)
        row['ff_phone'] = ebur128(os.path.join(PHONE, f"{row['name']}.wav"), row['ch'] == 1)
        f = row['ff']
        print(f"  {row['name']:14s} ffmpeg M {f['M']:6.1f}  I {f['I'] if f['I'] is not None else float('nan'):6.1f}"
              f"  sample peak {f['sp']:5.1f}  true peak {f['tp']:5.1f}   phone M {row['ff_phone']['M']:6.1f}")

    seams = {}
    for name in ('loop', 'maelstrom', 'neon/loop'):
        seams[name] = seam_check(FILES[name])
        x = FILES[name]
        flat = name.replace('/', '-')
        write_wav(os.path.join(BUILD, f'{flat}-seam.wav'), np.concatenate([x[-secs(4):], x[:secs(4)]]))
        spectrogram(os.path.join(BUILD, f'{flat}-seam.wav'), os.path.join(SPEC, f'{flat}-seam.png'), 8)
        for c, s in enumerate(seams[name][0]):
            print(f"  seam {name} ch{c}: jump {s['jump']:.2e}  median step {s['med']:.2e}  p99 {s['p99']:.2e}"
                  f"  max {s['max']:.2e}  (jump is larger than {100 * s['rank']:.1f}% of steps)"
                  f"  2nd diff {s['jump2']:.2e} vs p99 {s['p99_2']:.2e}")
        print(f"  seam {name}: RMS last 250 ms minus first 250 ms = {seams[name][1]:+.2f} dB; energy above 4 kHz "
              f"at the wrap is above {100 * seams[name][2]:.0f}% of the file's 2 ms windows")

    print('spectrograms')
    spectrograms(glass_names, 'contact')
    spectrograms(neon_names, 'contact-neon')
    print('reels')
    rl = reel()
    print(f"  reel {rl['dur']:.1f} s, true peak {rl['tp']:.1f} dBTP, effects end at {rl['fx_end']:.1f} s")
    rn = reel('neon/', 'neon/reel.m4a')
    print(f"  neon reel {rn['dur']:.1f} s, true peak {rn['tp']:.1f} dBTP")
    ev = None
    if not no_film:
        print('film')
        ev = make_film()
        print(f"  launch {ev['launch']:.3f}  turns {[(round(a, 3), b) for a, b in ev['turns']]}  heals "
              f"{[round(h, 3) for h in ev['heals']]}  first motion seen {ev['seen_start1']:.3f} (turn 1 by commit - 0.4: "
              f"{ev['turns'][0][0]:.3f})  pause between turns {ev['pause'] * 1000:.0f} ms (code: 300)")
        print(f"  ticks {[round(x, 3) for x in ev['ticks']]}")
        print(f"  in the finished film the ring shows at {ev['shown'][0]:.3f} and the wave at {ev['shown'][1]:.3f}: "
              f"{ev['lag'][0] * 1000:.0f} and {ev['lag'][1] * 1000:.0f} ms after their sounds (one 60 fps frame is 17 ms)")
    drag = {k: m_max(mix([(secs(i / 10), FILES[f'{p}tick-{i % 4 + 1}']) for i in range(10)]))
            for k, p in (('glass', ''), ('neon', 'neon/'))}
    print(f"  a drag of 10 ticks a second: M {drag['glass']:.1f} (neon {drag['neon']:.1f})")
    write_listen(seams, rl, rn, ev, rl['overlay'], drag)
    with open(os.path.join(BUILD, 'measurements.json'), 'w') as f:
        json.dump(dict(rows=ROWS, seams={k: v[0] for k, v in seams.items()}, reel=rl, drag=drag,
                       film={k: v for k, v in (ev or {}).items()}), f, indent=1, default=float)


if __name__ == '__main__':
    main()
