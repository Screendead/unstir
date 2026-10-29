; Copyright © 2026 Jack Lusher. All rights reserved.
; The glass set's voices and rooms, shared by effects.csd and beds.csd. Each voice follows the numpy sketch it
; replaces (the first glass sketch, sound-src/sketch.py, now only in git history) sample for sample (ksmps = 1), then
; adds what the sketch could not do: the strike rings the glass's own modes, and the longer rooms are reverbsc behind
; an allpass diffuser.

gisine ftgen 0, 0, 65536, 10, 1
; How loud the strike rings the modes; 0 gives the sketch's glass.
gichink init 0.05

; ------------------------------------------------------------------ pitch: D, with the pentatonic D E G A B
opcode Hz, i, i
  im xin
  xout 440 * 2 ^ ((im - 69) / 12)
endop

; Scale step k up from base (74 = D5).
opcode Degree, i, ij
  ik, ibase xin
  ibase = ibase < 0 ? 74 : ibase
  iscale[] fillarray 0, 2, 5, 7, 9
  io = floor(ik / 5)
  xout Hz(ibase + 12 * io + iscale[ik - 5 * io])
endop

; ------------------------------------------------------------------ filters
; The RBJ cookbook biquads the sketch used (type 0 lowpass, 1 highpass, 2 bandpass at constant 0 dB peak).
opcode RBJ, a, aiij
  ain, itype, if0, iq xin
  iq = iq < 0 ? 0.7071 : iq
  iw = 2 * $M_PI * if0 / sr
  ic = cos(iw)
  ial = sin(iw) / (2 * iq)
  if itype == 0 then
    ib0 = (1 - ic) / 2
    ib1 = 1 - ic
    ib2 = (1 - ic) / 2
  elseif itype == 1 then
    ib0 = (1 + ic) / 2
    ib1 = -(1 + ic)
    ib2 = (1 + ic) / 2
  else
    ib0 = ial
    ib1 = 0
    ib2 = -ial
  endif
  aout biquad ain, ib0, ib1, ib2, 1 + ial, -2 * ic, 1 - ial
  xout aout
endop

; The sketch's band of noise, a Gaussian iw wide in log frequency (its exp(-log2(f / c)^2 / iw)), round a centre kc
; that may move: four bandpasses in series, each wide enough that together they are 3 dB down where the Gaussian is.
opcode Band, a, aki
  ain, kc, iw xin
  ib = 2 * sinh(sqrt(0.3466 * iw) * log(2)) / sqrt(2 ^ 0.25 - 1)
  a1 butterbp ain, kc, ib * kc
  a1 butterbp a1, kc, ib * kc
  a1 butterbp a1, kc, ib * kc
  a1 butterbp a1, kc, ib * kc
  xout a1
endop

; Unit-variance white noise from the global seed.
opcode Noise, a, 0
  iseed random 0.001, 0.999
  anz rand sqrt(3), iseed, 1
  xout anz
endop

; ------------------------------------------------------------------ voices
; amp * exp(-t / tau) * sin(2 pi f t + phase), phase in radians.
opcode Mode, a, iiio
  ifq, itau, iamp, iph xin
  aenv expon 1, 20 * itau, exp(-20)
  aosc poscil 1, ifq, gisine, iph / (2 * $M_PI)
  xout iamp * aenv * aosc
endop

; One partial of a struck glass: a pair beating slowly, the second at 0.45 and a random phase.
opcode Doublet, a, iiii
  ifr, iamp, itau, id xin
  iamp = ifr > 15000 ? 0 : iamp
  iph random 0, 1
  aenv expon 1, 20 * itau, exp(-20)
  a1 poscil 1, ifr, gisine
  a2 poscil 0.45, ifr + id, gisine, iph
  xout iamp * aenv * (a1 + a2) / 1.45
endop

; The strike's noise, ringing the glass's modes (new in Csound): each mode a resonator whose ring is a third of the
; partial's, so the attack is a glassy chink that differs a little on every hit, and the bar's higher modes flash.
opcode Chink, a, aiii
  aclick, ifq, idecay, ibright xin
  ir[] fillarray 1, 2.76, 5.40, 8.93, 13.34, 18.64
  ia[] fillarray 0.5, 0.28, 0.16, 0.08, 0.05, 0.03
  idv[] fillarray 1, 2.3, 4.5, 7, 10, 14
  ik = 0
  ifr[] init 6
  iq[] init 6
  ig[] init 6
  while ik < 6 do
    ifr[ik] = min(ifq * ir[ik], 16000)
    iq[ik] = $M_PI * ifr[ik] * idecay / idv[ik] / 3
    ig[ik] = ifq * ir[ik] > 16000 ? 0 : ia[ik] * (ik == 0 ? 1 : ibright)
    ik += 1
  od
  a0 mode aclick, ifr[0], iq[0]
  a1 mode aclick, ifr[1], iq[1]
  a2 mode aclick, ifr[2], iq[2]
  a3 mode aclick, ifr[3], iq[3]
  a4 mode aclick, ifr[4], iq[4]
  a5 mode aclick, ifr[5], iq[5]
  xout ig[0] * a0 + ig[1] * a1 + ig[2] * a2 + ig[3] * a3 + ig[4] * a4 + ig[5] * a5
endop

; A struck glass (the sketch's glass()): free-bar partials 1, 2.76, 5.40, 8.93 as slow-beating doublets, a soft FM
; onset and a noise click; now also the bar's fifth mode (13.34) and the chink. idur only shapes the tail fade.
opcode Glass, a, iiiiiii
  ifq, idur, idecay, ibright, istrike, ifm, idoublet xin
  a1 Doublet ifq, 1, idecay, idoublet
  a2 Doublet ifq * 2.76, 0.28 * ibright, idecay / 2.3, idoublet * sqrt(2.76)
  a3 Doublet ifq * 5.40, 0.10 * ibright, idecay / 4.5, idoublet * sqrt(5.40)
  a4 Doublet ifq * 8.93, 0.035 * ibright, idecay / 7, idoublet * sqrt(8.93)
  a5 Doublet ifq * 13.34, 0.012 * ibright, idecay / 10, idoublet * sqrt(13.34)
  asum = a1 + a2 + a3 + a4 + a5
  ; FM strike: sin(2 pi f t + idx sin(2 pi 3.5 f t)), idx = fm 2.2 exp(-t / 35 ms)
  ifm0 = max(ifm, 1e-9)
  aidx expon ifm0 * 2.2, 0.7, ifm0 * 2.2 * exp(-20)
  aph phasor ifq
  amod poscil 1, ifq * 3.5, gisine
  acar tablei aph + aidx * amod / (2 * $M_PI), gisine, 1, 0, 1
  afmenv expon 1, 20 * 0.09, exp(-20)
  asum += ifm * 0.5 * afmenv * acar
  ; the click: highpassed noise, gone in a few ms
  aclenv expon 1, 20 * 0.0012, exp(-20)
  anz Noise
  aclick RBJ anz * aclenv, 1, 3500
  asum += istrike * 0.18 * aclick
  asum += istrike * gichink * Chink(aclick, ifq, idecay, ibright)
  aenv cosseg 0, 0.0006, 1, idur * 0.7 - 0.0006, 1, idur * 0.3, 0
  xout asum * aenv
endop

; A bubble (the sketch's bubble()): a decaying sine whose pitch rises as it nears the surface.
opcode Bubble, a, iiiio
  if0, irise, itau, iamp, idur xin
  idur = idur > 0 ? idur : min(8 * itau + 0.01, 0.6)
  kt timeinsts
  kf = if0 * (1 + irise * (1 - exp(-kt / (2.5 * itau))))
  aosc poscil 1, kf, gisine
  adec expon 1, 20 * itau, exp(-20)
  arise expon 1, 20 * 0.0006, exp(-20)
  aenv cosseg 1, idur * 0.8, 1, idur * 0.2, 0
  xout iamp * adec * (1 - arise) * aosc * aenv
endop

; A bowed-glass swell (the sketch's swell()): sin^2 over its length, a slow beat and a hint of the 2.76 partial.
opcode Swell, a, iioo
  ifq, idur, ibeat, iglassy xin
  ibeat = ibeat == 0 ? 0.35 : ibeat
  iglassy = iglassy == 0 ? 0.06 : iglassy
  iph random 0, 1
  aenv cosseg 0, idur / 2, 1, idur / 2, 0
  a1 poscil 1, ifq, gisine
  a2 poscil 0.6, ifq + ibeat, gisine, iph
  a3 poscil iglassy, ifq * 2.76, gisine
  a4 poscil 0.12, 2 * ifq, gisine
  xout aenv * (a1 + a2 + a3 + a4) / 1.6
endop

; Constant-power pan, p from -1 (left) to 1 (right).
opcode Pan, aa, ai
  ain, ip xin
  ith = (ip + 1) * $M_PI / 4
  xout ain * cos(ith), ain * sin(ith)
endop

; ------------------------------------------------------------------ passes
; Where the sketch scaled a part by its own peak, a first pass records the part into a table (from the instrument's
; start, one sample per k-cycle) and a later pass reads it back knowing the peak.
opcode Record, 0, ai
  ain, ift xin
  kn init 0
  tablew k(ain), kn, ift
  kn += 1
endop

opcode Play, a, i
  ift xin
  kn init 0
  kv table kn, ift
  kn += 1
  xout a(kv)
endop

opcode TabPeak, i, i
  ift xin
  imax = 0
  ii = 0
  while ii < ftlen(ift) do
    imax = max(imax, abs(table:i(ii, ift)))
    ii += 1
  od
  xout imax
endop

opcode Tab, i, i
  idur xin
  ift ftgen 0, 0, -round(idur * sr), -2, 0
  xout ift
endop

; Linear interpolation through breakpoints at init, as numpy's interp (held at the ends).
opcode Interp, i, ii[]i[]
  ix, ixs[], iys[] xin
  il = lenarray(ixs)
  iy = iys[il - 1]
  if ix < ixs[0] then
    iy = iys[0]
  endif
  ik = 0
  while ik < il - 1 do
    if ix >= ixs[ik] && ix < ixs[ik + 1] then
      iy = iys[ik] + (iys[ik + 1] - iys[ik]) * (ix - ixs[ik]) / (ixs[ik + 1] - ixs[ik])
    endif
    ik += 1
  od
  xout iy
endop

; ------------------------------------------------------------------ rooms
; The sketch's impulse response: seeded noise, each band decaying at its own rate (long in the lows, short in the
; highs), faded in over ifade and normalised to unit energy. Built at init into a table.
opcode NoiseIR, i, iiio
  idur, irtlo, irthi, ifade xin
  ifade = ifade == 0 ? 0.004 : ifade
  iN = round(idur * sr)
  ift ftgen 0, 0, -iN, -2, 0
  iedge[] fillarray 250, 700, 1800, 4500, 9000
  ilp[] init 5
  ic[] init 5
  ienv[] init 6
  ig[] init 6
  ib = 0
  while ib < 6 do
    ilo = ib == 0 ? 60 : iedge[ib - 1]
    ihi = ib == 5 ? sr / 2 : iedge[ib]
    iu = limit(log(sqrt(ilo * ihi) / 150) / log(10000 / 150), 0, 1)
    ig[ib] = exp(-6.91 / (irtlo * (irthi / irtlo) ^ iu * sr))
    ienv[ib] = 1
    if ib < 5 then
      ic[ib] = 1 - exp(-2 * $M_PI * iedge[ib] / sr)
    endif
    ib += 1
  od
  isum = 0
  ii = 0
  while ii < iN do
    ix = gauss:i(3.83)
    iy = 0
    ib = 0
    while ib < 5 do
      ilp[ib] = ilp[ib] + ic[ib] * (ix - ilp[ib])
      iy += ilp[ib] * ienv[ib]
      ix -= ilp[ib]
      ienv[ib] = ienv[ib] * ig[ib]
      ib += 1
    od
    iy = (iy + ix * ienv[5]) * min(1, ii / (ifade * sr))
    ienv[5] = ienv[5] * ig[5]
    tableiw iy, ii, ift
    isum += iy * iy
    ii += 1
  od
  inorm = 1 / sqrt(isum)
  ii = 0
  while ii < iN do
    tableiw table:i(ii, ift) * inorm, ii, ift
    ii += 1
  od
  xout ift
endop

; A short dense room, as the sketch's: dry plus iwet of the noise IR (64 samples, 1.3 ms, of convolution latency).
opcode Room, a, aiiii
  ain, idur, irtlo, irthi, iwet xin
  ift NoiseIR idur, irtlo, irthi
  awet ftconv ain, ift, 64
  xout ain + iwet * awet
endop

; Four allpasses, gain 0.7, at 3.1, 5.3, 7.9 and 11.7 ms.
opcode ApChain, a, a
  ain xin
  ig = 0.7
  a1 alpass ain, -3 * 0.0031 / log10(ig), 0.0031
  a2 alpass a1, -3 * 0.0053 / log10(ig), 0.0053
  a3 alpass a2, -3 * 0.0079 / log10(ig), 0.0079
  a4 alpass a3, -3 * 0.0117 / log10(ig), 0.0117
  xout a4
endop

; A longer room: an allpass diffuser fills reverbsc's first 44 ms, then reverbsc's modulated tail. Mono in, mono out
; (the mean of reverbsc's two sides). inorm scales the wet to unit energy for that feedback and cutoff (see HallNorm).
opcode Hall, a, aiiii
  ain, ifb, ico, iwet, inorm xin
  ad ApChain ain
  aL, aR reverbsc ad, ad, ifb, ico, sr, 0.5
  xout ain + iwet * inorm * (0.35 * ad + 0.5 * (aL + aR))
endop

