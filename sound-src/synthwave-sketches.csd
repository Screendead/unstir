; Copyright © 2026 Jack Lusher. All rights reserved.
; Sketches for the synthwave menu, for Jack's ear: three directions (outrun, night, dark), each a menu bed of 16 bars
; and four menu effects (a bead's tap, the tier swipe, a level opening, a locked bead's tap).
; scripts/synthwave-sketches.sh passes the sketch (SKETCH), its tempo (BPM), the seconds to render (DUR) and the
; output (OUT); NOLEAD leaves a bed's top line out, and BASSONLY renders the bass alone, dry, to measure it. Stereo, 48 kHz, 32-bit float; the script sets the level and cuts
; a bed's loop from its second period.
;
; Every event of a bed is scheduled from a beat number on one grid (giB). No voice draws a random number that
; reaches its pitch or timing, so a bed's periods are the same notes with the same phases and the loop's cut is clean.
<CsoundSynthesizer>
<CsOptions>
-n -d -m0
</CsOptions>
<CsInstruments>
sr = 48000
ksmps = 4
nchnls = 2
0dbfs = 1
seed 4101

gisine ftgen 0, 0, 65536, 10, 1

giB = 60 / $BPM
giBars = 16
giLoop = giBars * 4 * giB
#ifdef NOLEAD
giLeadOn = 0
#else
giLeadOn = 1
#end

gaL init 0
gaR init 0
gaRvL init 0
gaRvR init 0
gaDl init 0
gaGate init 0
gaPad init 0
gaBass init 0
gkPump init 1
gkGate init 0
giLeadLast init 0

; The patch: each direction's song sets these before its notes start.
giLeadDet init 7
giLeadSub init 0.2
giLeadCut init 4200
giLeadRes init 0.25
giLeadAtk init 0.03
giLeadDrive init 1.6
giLeadGlide init 0.035
giLeadRv init 0.25
giLeadDl init 0.3
giPadDet init 8
giPadCut init 1800
giPadDrive init 1.3
giPadAtk init 0.25
giPadRel init 0.4
giPadPump init 0.5
giPadRv init 0.3
giPlkPw init 0.3
giPlkCut init 3800
giPlkDec init 0.12
giPlkRes init 0.3
giPlkDrive init 1.5
giPlkRv init 0.2
giPlkDl init 0.35
giBassDet init 6
giBassCut init 1400
giBassDec init 0.14
giBassRes init 0.3
giBassDrive init 2.2
giBassPump init 0.6
giTineNdx init 2.2
giTineRv init 0.3
giTineDl init 0.35
giSnTone init 190
giSnCut init 7000
giHatCut init 8500
giDlFb init 0.38
giRvFb init 0.84
giRvCut init 7000
giRvMix init 0.5
giGateMix init 1.1
giTape init 1.1

opcode Hz, i, i
  im xin
  xout 440 * 2 ^ ((im - 69) / 12)
endop

; A voice's output at ipan (0 left, 1 right; nothing sits past 0.35 or 0.65), with sends to the hall and the delay.
opcode Out, 0, aiii
  a1, ipan, irv, idl xin
  aL = a1 * sqrt(2 * (1 - ipan))
  aR = a1 * sqrt(2 * ipan)
  gaL += aL
  gaR += aR
  gaRvL += irv * aL
  gaRvR += irv * aR
  gaDl += idl * a1
endop

; Schedules triples of beat, beats held and MIDI note on an instrument for ireps periods: p4 the note, p5 its level.
opcode Notes, 0, Si[]iiii
  Sins, iev[], itrans, iamp, igate, ireps xin
  ir = 0
  while ir < ireps do
    ii = 0
    while ii < lenarray(iev) do
      schedule Sins, (iev[ii] + ir * giBars * 4) * giB, iev[ii + 1] * giB * igate, iev[ii + 2] + itrans, iamp
      ii += 3
    od
    ir += 1
  od
endop

; ------------------------------------------------------------------ the kit
; Defined first: the kick sets the pump the bass and pad read on the same cycle. p4 level, p5 the pump's depth.
instr kick
  kf expseg 250, 0.014, 120, 0.07, 54, 0.3, 46
  a1 oscili 1, kf
  ac rand 1
  ac butterhp ac, 1800
  ac butterlp ac, 5500
  kce expseg 1, 0.009, 0.001, 1, 0.001
  aenv transeg 1, p3, -3.5, 0
  a1 = tanh(2.8 * (a1 * aenv + 0.35 * ac * kce))
  kp transeg 1, p3 * 0.85, -2.5, 0
  gkPump = 1 - p5 * kp
  Out a1 * p4, 0.5, 0, 0
endin

; p4 level, p5 its send to the gated room, p6 the seconds the gate holds.
instr snare
  an rand 1
  ab butterbp an, 1900, 2200
  ah butterhp an, 3200
  ah butterlp ah, giSnCut
  ken transeg 1, 0.17, -5, 0
  kf expseg giSnTone * 1.9, 0.018, giSnTone, 1, giSnTone * 0.94
  at oscili 1, kf
  ket transeg 1, 0.12, -4, 0
  a1 = tanh(3 * ((1.4 * ab + 0.5 * ah) * ken + 0.8 * at * ket))
  adc linsegr 1, 0.01, 0
  a1 *= adc
  gkGate linseg 1, p6, 1, 0.045, 0, 1, 0
  gaGate += a1 * p5
  Out a1 * p4, 0.5, 0, 0
endin

; Six squares at an 808's ratios through a band: the crunch of a hat without the hiss. p4 level, p5 decay.
instr hat
  a1 vco2 1, 205.3 * 1.4, 10
  a2 vco2 1, 304.4 * 1.4, 10
  a3 vco2 1, 369.6 * 1.4, 10
  a4 vco2 1, 522.7 * 1.4, 10
  a5 vco2 1, 540 * 1.4, 10
  a6 vco2 1, 800 * 1.4, 10
  as = a1 + a2 + a3 + a4 + a5 + a6
  as butterbp as, 6200, 3200
  as butterhp as, 4500
  as butterlp as, giHatCut
  kenv expseg 1, p5, 0.001, 1, 0.001
  adc linsegr 0, 0.001, 1, 0.01, 0
  Out tanh(2 * as) * kenv * adc * p4, 0.56, 0.08, 0
endin

; p4 level, p5 Hz, p6 its send to the gated room.
instr tom
  kf expseg p5 * 1.7, 0.035, p5, 1, p5 * 0.8
  a1 oscili 1, kf
  aenv transeg 1, p3, -3.5, 0
  a1 = tanh(2.4 * a1 * aenv)
  gaGate += a1 * p6
  Out a1 * p4, 0.5, 0.1, 0
endin

; ------------------------------------------------------------------ the pitched voices: p4 MIDI note, p5 level
instr bass
  ihz = Hz(p4)
  a1 vco2 0.5, ihz
  a2 vco2 0.4, ihz * cent(giBassDet)
  a3 vco2 0.5, ihz, 2, 0.4
  kcut expseg giBassCut, giBassDec, giBassCut * 0.28, 1, giBassCut * 0.22
  af moogladder a1 + a2 + a3, kcut, giBassRes
  af = tanh(giBassDrive * af)
  aenv linsegr 0, 0.003, 1, 0.03, 0
  kpm = 1 - giBassPump * (1 - gkPump)
  ab = af * aenv * p5 * kpm
  gaBass += ab
  Out ab, 0.5, 0, 0
endin

; Two saws and a pulse, with a square an octave under: each note glides in from the last one's pitch and its vibrato
; comes in late.
instr lead
  ihz = Hz(p4)
  ifrom = giLeadLast > 0 ? giLeadLast : ihz
  giLeadLast = ihz
  kf expseg ifrom, giLeadGlide, ihz, 1, ihz
  kvd linseg 0, 0.2, 0, 0.3, 1, 1, 1
  kvl oscili 1, 5.6
  kf = kf * (1 + 0.0045 * kvd * kvl)
  kpw oscili 0.28, 0.9
  a1 vco2 0.33, kf * cent(giLeadDet)
  a2 vco2 0.33, kf * cent(-giLeadDet)
  a3 vco2 0.33, kf, 2, 0.5 + kpw
  a4 vco2 giLeadSub, kf * 0.5, 10
  kcut expseg giLeadCut * 0.3, giLeadAtk, giLeadCut, 1.5, giLeadCut * 0.55
  af moogladder a1 + a2 + a3 + a4, kcut, giLeadRes
  af = tanh(giLeadDrive * af)
  aenv linsegr 0, 0.006, 1, 0.08, 0
  Out af * aenv * p5, 0.5, giLeadRv, giLeadDl
endin

; Two saws and a pulse whose width turns, into the chorus.
instr pad
  ihz = Hz(p4)
  kpw oscili 0.33, 0.4
  a1 vco2 0.4, ihz * cent(giPadDet)
  a2 vco2 0.4, ihz * cent(-giPadDet)
  a3 vco2 0.35, ihz, 2, 0.5 + kpw
  kcut linseg giPadCut * 0.5, p3 * 0.4, giPadCut, p3 * 0.6, giPadCut * 0.7, 1, giPadCut * 0.7
  af moogladder a1 + a2 + a3, kcut, 0.15
  af = tanh(giPadDrive * af)
  aenv linsegr 0, giPadAtk, 1, giPadRel, 0
  kpm = 1 - giPadPump * (1 - gkPump)
  af = af * aenv * p5 * kpm
  gaPad += af
  gaRvL += giPadRv * af
  gaRvR += giPadRv * af
endin

; A pulse and a saw through a filter that snaps shut. p6 pan.
instr pluck
  ihz = Hz(p4)
  a1 vco2 0.5, ihz, 2, giPlkPw
  a2 vco2 0.3, ihz * cent(6)
  kcut expseg giPlkCut, giPlkDec, giPlkCut * 0.14, 1, giPlkCut * 0.1
  af moogladder a1 + a2, kcut, giPlkRes
  kenv expseg 1, giPlkDec * 2.2, 0.01, 1, 0.001
  adc linsegr 0, 0.002, 1, 0.03, 0
  af = tanh(giPlkDrive * af) * kenv * adc * p5
  Out af, (p6 == 0 ? 0.5 : p6), giPlkRv, giPlkDl
endin

; An FM electric piano: a tine's bark that mellows as it rings, into the chorus.
instr tine
  ihz = Hz(p4)
  kndx expseg giTineNdx, 0.35, giTineNdx * 0.3, 2, giTineNdx * 0.12
  a1 foscili 1, ihz, 1, 1, kndx, gisine
  kn2 expseg 1.6, 0.06, 0.05, 1, 0.01
  a2 foscili 0.3, ihz, 1, 5, kn2, gisine
  kenv expseg 1, 1.4, 0.3, 3, 0.08
  adc linsegr 0, 0.003, 1, 0.25, 0
  af = tanh(1.5 * (a1 + a2)) * kenv * adc * p5
  gaPad += 0.6 * af
  Out 0.5 * af, 0.5, giTineRv, giTineDl
endin

; A detuned saw that slides from p4 to p5 (MIDI) as its filter moves from p7 to p8 Hz. p6 level; p9 0 swells, 1 falls.
instr sweep
  kf expseg Hz(p4), p3, Hz(p5)
  a1 vco2 0.4, kf * cent(9)
  a2 vco2 0.4, kf * cent(-9)
  a3 vco2 0.3, kf * 0.5, 10
  kcut expseg p7, p3, p8
  af moogladder a1 + a2 + a3, kcut, 0.3
  af = tanh(2 * af)
  krise linseg 0.12, p3 - 0.04, 1, 0.04, 0
  kfall expseg 1, p3, 0.02
  adc linsegr 0, 0.004, 1, 0.02, 0
  Out af * ((1 - p9) * krise + p9 * kfall) * adc * p6, 0.5, 0.3, 0.2
endin

; ------------------------------------------------------------------ outrun: A minor at 120, Am F C G, two bars each
opcode OutrunPatch, 0, 0
  giLeadDet = 8
  giLeadSub = 0.22
  giLeadCut = 4600
  giLeadRes = 0.28
  giLeadDrive = 1.9
  giPadCut = 1500
  giPadPump = 0.65
  giBassCut = 1500
  giBassDrive = 2.6
  giBassPump = 0.7
  giPlkCut = 4200
  giSnTone = 195
endop

instr outrun
  OutrunPatch
  iroot[] fillarray 33, 33, 29, 29, 36, 36, 31, 31
  iarp[] fillarray 0, 0, 12, 0, 7, 0, 12, 7
  ichord[] fillarray 57, 60, 64, 57, 60, 65, 55, 60, 64, 55, 59, 62
  ireps = 3
  ir = 0
  while ir < ireps do
    ibar = 0
    while ibar < 16 do
      it = (ir * 16 + ibar) * 4 * giB
      ifill = (ibar % 8 == 7) ? 1 : 0
      ik = 0
      while ik < 4 do
        schedule "kick", it + ik * giB, 0.3, 0.9, 1
        ik += 1
      od
      schedule "snare", it + giB, 0.32, 0.5, 0.5, 0.24
      if ifill == 0 then
        schedule "snare", it + 3 * giB, 0.32, 0.5, 0.5, 0.24
      else
        schedule "tom", it + 3 * giB, 0.3, 0.55, 196, 0.35
        schedule "tom", it + 3.25 * giB, 0.3, 0.5, 196, 0.35
        schedule "tom", it + 3.5 * giB, 0.35, 0.55, 147, 0.35
        schedule "tom", it + 3.75 * giB, 0.45, 0.6, 110, 0.35
      endif
      ih = 0
      while ih < 8 do
        schedule "hat", it + ih * 0.5 * giB, 0.1, (ih % 2 == 1 ? 0.2 : 0.1), (ih == 7 ? 0.16 : 0.045)
        schedule "bass", it + ih * 0.5 * giB, 0.4 * giB, iroot[ibar % 8] + iarp[ih], (ih % 2 == 0 ? 0.62 : 0.5)
        ih += 1
      od
      if ibar % 2 == 0 then
        ic = (ibar % 8) / 2 * 3
        schedule "pad", it, 8 * giB - 0.1, ichord[ic], 0.13
        schedule "pad", it, 8 * giB - 0.1, ichord[ic + 1], 0.13
        schedule "pad", it, 8 * giB - 0.1, ichord[ic + 2], 0.13
      endif
      ibar += 1
    od
    ir += 1
  od
  ihook[] fillarray 1.5, 0.5, 76, 2, 1.5, 81, 3.5, 1, 79, 4.5, 0.5, 76, 5, 1.5, 74, 6.5, 1.5, 76, \
    8.5, 0.5, 77, 9, 1.5, 81, 10.5, 1, 84, 11.5, 0.5, 81, 12, 2.5, 79, 14.5, 0.5, 77, 15, 0.5, 76, 15.5, 1.5, 79, \
    17.5, 0.5, 76, 18, 1.5, 79, 19.5, 1, 84, 20.5, 0.5, 83, 21, 2, 79, 23.5, 1.5, 83, \
    25, 0.5, 81, 25.5, 1, 79, 26.5, 1.5, 74, 28, 2.5, 76, \
    33.5, 0.5, 81, 34, 1.5, 84, 35.5, 1, 83, 36.5, 0.5, 81, 37, 1.5, 79, 38.5, 1.5, 81, \
    40.5, 0.5, 84, 41, 1.5, 88, 42.5, 1, 86, 43.5, 0.5, 84, 44, 2.5, 81, 46.5, 0.5, 84, 47, 0.5, 86, 47.5, 1.5, 88, \
    49.5, 0.5, 86, 50, 1.5, 84, 51.5, 1, 79, 52.5, 0.5, 84, 53, 2, 88, 55.5, 1.5, 86, \
    57, 0.5, 84, 57.5, 1, 83, 58.5, 1.5, 79, 60, 2.5, 83
  if giLeadOn == 1 then
    Notes "lead", ihook, 0, 0.3, 0.92, ireps
  endif
  turnoff
endin

instr outrunTap
  OutrunPatch
  giPlkDec = 0.2
  giPlkDrive = 2.4
  schedule "pluck", 0.02, 0.3, 81, 0.6
  schedule "pluck", 0.02, 0.3, 88, 0.25
  turnoff
endin
instr outrunSwipe
  OutrunPatch
  irun[] fillarray 57, 60, 64, 69, 72, 76, 81, 84
  ii = 0
  while ii < 8 do
    schedule "pluck", 0.02 + ii * 0.055, 0.2, irun[ii], 0.3 + 0.04 * ii
    ii += 1
  od
  schedule "sweep", 0.02, 0.46, 45, 57, 0.4, 500, 5000, 0
  turnoff
endin
instr outrunOpen
  OutrunPatch
  giPadAtk = 0.01
  giPadRel = 0.7
  giPadCut = 3200
  giPadPump = 0
  schedule "kick", 0.02, 0.3, 0.9, 0
  schedule "snare", 0.02, 0.4, 0.45, 0.6, 0.32
  istab[] fillarray 45, 52, 57, 64, 69
  ii = 0
  while ii < 5 do
    schedule "pad", 0.02, 0.5, istab[ii], 0.2
    ii += 1
  od
  schedule "sweep", 0.14, 1.2, 81, 45, 0.35, 5000, 250, 1
  turnoff
endin
instr outrunLocked
  OutrunPatch
  giBassCut = 700
  giBassPump = 0
  schedule "bass", 0.02, 0.07, 45, 0.7
  schedule "bass", 0.14, 0.1, 40, 0.7
  turnoff
endin

; ------------------------------------------------------------------ night: D major at 96, Gmaj7 A Bm7 F#m7
opcode NightPatch, 0, 0
  giPadDet = 6
  giPadCut = 2100
  giPadDrive = 1.15
  giPadAtk = 0.5
  giPadRel = 0.8
  giPadPump = 0.25
  giPadRv = 0.4
  giBassDet = 4
  giBassCut = 1500
  giBassDec = 0.3
  giBassRes = 0.25
  giBassDrive = 2.8
  giBassPump = 0.45
  giPlkPw = 0.22
  giPlkCut = 2600
  giPlkDec = 0.16
  giPlkDrive = 1.3
  giPlkRv = 0.3
  giPlkDl = 0.45
  giTineRv = 0.4
  giTineDl = 0.4
  giSnTone = 170
  giSnCut = 5500
  giHatCut = 7500
  giRvFb = 0.88
  giRvMix = 0.6
  giDlFb = 0.45
endop

instr night
  NightPatch
  iroot[] fillarray 31, 31, 33, 33, 35, 35, 30, 30
  ichord[] fillarray 55, 59, 62, 66, 57, 61, 64, 69, 59, 62, 66, 69, 57, 61, 64, 66
  ipat[] fillarray 0, 1, 2, 3, -1, 2, 3, 1
  ireps = 3
  ir = 0
  while ir < ireps do
    ibar = 0
    while ibar < 16 do
      it = (ir * 16 + ibar) * 4 * giB
      ic = int((ibar % 8) / 2) * 4
      schedule "kick", it, 0.34, 0.8, 1
      schedule "kick", it + 2.5 * giB, 0.34, 0.65, 1
      schedule "snare", it + 2 * giB, 0.5, 0.3, 0.55, 0.38
      ih = 0
      while ih < 4 do
        schedule "hat", it + (ih + 0.5) * giB, 0.1, 0.1, (ih == 3 ? 0.12 : 0.05)
        ih += 1
      od
      if ibar % 2 == 0 then
        schedule "bass", it, 2.4 * giB, iroot[ibar % 8], 0.6
        schedule "bass", it + 2.5 * giB, 0.9 * giB, iroot[ibar % 8], 0.5
        schedule "bass", it + 3.5 * giB, 0.45 * giB, iroot[ibar % 8] + 7, 0.5
        ip = 0
        while ip < 4 do
          schedule "pad", it, 8 * giB - 0.2, ichord[ic + ip], 0.1
          ip += 1
        od
      else
        schedule "bass", it, 2.9 * giB, iroot[ibar % 8], 0.6
        schedule "bass", it + 3 * giB, 0.9 * giB, iroot[ibar % 8] + 12, 0.45
      endif
      ih = 0
      while ih < 8 do
        if ipat[ih] >= 0 then
          schedule "pluck", it + ih * 0.5 * giB, 0.45 * giB, ichord[ic + ipat[ih]] + 12, (ih % 4 == 1 ? 0.2 : 0.14), \
            (ih % 2 == 0 ? 0.4 : 0.6)
        endif
        ih += 1
      od
      ibar += 1
    od
    ir += 1
  od
  imotif[] fillarray 0.5, 1.5, 78, 2, 1, 81, 3, 2.5, 83, 6.5, 1.5, 81, \
    8.5, 1.5, 76, 10, 1, 81, 11, 3, 85, 14.5, 1.5, 83, \
    16.5, 1.5, 78, 18, 1, 83, 19, 2.5, 86, 22.5, 1.5, 85, \
    24.5, 1.5, 81, 26, 1, 76, 27, 4, 73, \
    33, 1, 83, 34, 1.5, 86, 35.5, 3, 90, 39.5, 1.5, 88, \
    41.5, 0.5, 85, 42, 1.5, 88, 43.5, 3, 81, 47.5, 1.5, 78, \
    49.5, 0.5, 83, 50, 1.5, 86, 51.5, 2.5, 85, 54.5, 1.5, 83, \
    56.5, 1.5, 81, 58, 1, 85, 59, 4, 76
  if giLeadOn == 1 then
    Notes "tine", imotif, 0, 0.42, 1, ireps
  endif
  turnoff
endin

instr nightTap
  NightPatch
  schedule "tine", 0.02, 0.35, 83, 0.6
  turnoff
endin
instr nightSwipe
  NightPatch
  irun[] fillarray 62, 66, 69, 71, 74, 78, 81, 86
  ii = 0
  while ii < 8 do
    schedule "tine", 0.02 + ii * 0.06, 0.3, irun[ii], 0.3 + 0.03 * ii
    ii += 1
  od
  schedule "sweep", 0.02, 0.5, 50, 62, 0.22, 400, 2600, 0
  turnoff
endin
instr nightOpen
  NightPatch
  giPadAtk = 0.08
  giPadRel = 1.2
  giPadPump = 0
  iswell[] fillarray 50, 57, 62, 66, 69
  ii = 0
  while ii < 5 do
    schedule "pad", 0.02, 0.7, iswell[ii], 0.17
    ii += 1
  od
  schedule "tine", 0.02, 1.2, 78, 0.4
  schedule "tine", 0.17, 1.1, 81, 0.4
  schedule "tine", 0.32, 1.3, 86, 0.45
  schedule "sweep", 0.3, 1.3, 74, 38, 0.2, 2600, 180, 1
  turnoff
endin
instr nightLocked
  NightPatch
  giBassCut = 500
  giBassDec = 0.1
  giBassPump = 0
  schedule "bass", 0.02, 0.08, 50, 0.7
  schedule "bass", 0.16, 0.12, 45, 0.7
  turnoff
endin

; ------------------------------------------------------------------ dark: E minor at 100, Em Em C D, Em Em C B
opcode DarkPatch, 0, 0
  giLeadDet = 14
  giLeadSub = 0.4
  giLeadCut = 2600
  giLeadRes = 0.38
  giLeadAtk = 0.07
  giLeadDrive = 3
  giLeadGlide = 0.06
  giLeadRv = 0.3
  giLeadDl = 0.25
  giPadDet = 13
  giPadCut = 1100
  giPadDrive = 2
  giPadAtk = 0.15
  giPadPump = 0.75
  giBassDet = 9
  giBassCut = 1800
  giBassDec = 0.12
  giBassRes = 0.4
  giBassDrive = 3.6
  giBassPump = 0.8
  giPlkCut = 2200
  giPlkRes = 0.45
  giPlkDrive = 2.4
  giSnTone = 160
  giSnCut = 5500
  giHatCut = 7000
  giRvFb = 0.87
  giRvCut = 5500
  giGateMix = 1.4
  giTape = 1.5
endop

instr dark
  DarkPatch
  iroot[] fillarray 28, 28, 28, 28, 36, 36, 38, 38, 28, 28, 28, 28, 36, 36, 35, 35
  ichord[] fillarray 52, 59, 64, 67, 55, 60, 64, 67, 57, 62, 66, 69, 52, 59, 64, 67, 55, 60, 64, 67, 59, 63, 66, 71
  icbar[] fillarray 0, 4, 6, 8, 12, 14
  iclen[] fillarray 4, 2, 2, 4, 2, 2
  ioct[] fillarray 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 12, 0, 0
  iacc[] fillarray 1, 0.6, 0.8, 0.6
  ireps = 3
  ir = 0
  while ir < ireps do
    ibar = 0
    while ibar < 16 do
      it = (ir * 16 + ibar) * 4 * giB
      ifill = (ibar % 8 == 7) ? 1 : 0
      ik = 0
      while ik < 4 do
        schedule "kick", it + ik * giB, 0.36, 1, 1
        schedule "hat", it + (ik + 0.5) * giB, 0.2, 0.14, 0.11
        ik += 1
      od
      schedule "snare", it + giB, 0.45, 0.5, 0.7, 0.34
      if ifill == 0 then
        schedule "snare", it + 3 * giB, 0.45, 0.5, 0.7, 0.34
      else
        schedule "tom", it + 3 * giB, 0.35, 0.6, 123, 0.5
        schedule "tom", it + 3.5 * giB, 0.4, 0.6, 98, 0.5
        schedule "tom", it + 3.75 * giB, 0.5, 0.65, 82, 0.5
      endif
      ih = 0
      while ih < 16 do
        schedule "bass", it + ih * 0.25 * giB, 0.2 * giB, iroot[ibar] + ioct[ih], 0.5 * iacc[ih % 4]
        ih += 1
      od
      ibar += 1
    od
    ic = 0
    while ic < 6 do
      it = (ir * 16 + icbar[ic]) * 4 * giB
      ip = 0
      while ip < 4 do
        schedule "pad", it, iclen[ic] * 4 * giB - 0.1, ichord[ic * 4 + ip], 0.12
        ip += 1
      od
      ic += 1
    od
    ir += 1
  od
  imotif[] fillarray 1.5, 0.5, 64, 2, 1.5, 67, 3.5, 2.5, 66, 6, 1, 64, 7, 0.5, 62, 7.5, 2.5, 59, \
    10.5, 0.5, 64, 11, 1.5, 67, 12.5, 1, 71, 13.5, 1.5, 69, 15, 0.5, 67, 15.5, 2.5, 72, \
    18.5, 0.5, 71, 19, 1.5, 67, 20.5, 1, 64, 21.5, 2, 67, 23.5, 2.5, 69, \
    26.5, 0.5, 66, 27, 1.5, 69, 28.5, 3, 74, \
    33.5, 0.5, 71, 34, 1.5, 76, 35.5, 2.5, 74, 38, 1, 71, 39, 0.5, 69, 39.5, 2.5, 67, \
    42.5, 0.5, 71, 43, 1.5, 76, 44.5, 1, 79, 45.5, 1.5, 78, 47, 0.5, 74, 47.5, 2.5, 76, \
    50.5, 0.5, 79, 51, 1.5, 76, 52.5, 1, 72, 53.5, 2, 76, 55.5, 2.5, 75, \
    58.5, 0.5, 71, 59, 1.5, 75, 60.5, 3, 78
  if giLeadOn == 1 then
    Notes "lead", imotif, 0, 0.3, 0.92, ireps
  endif
  turnoff
endin

instr darkTap
  DarkPatch
  giPlkDec = 0.2
  giPlkDrive = 3
  schedule "pluck", 0.02, 0.3, 64, 0.6
  schedule "pluck", 0.02, 0.3, 52, 0.4
  turnoff
endin
instr darkSwipe
  DarkPatch
  irun[] fillarray 40, 47, 52, 55, 59, 64
  ii = 0
  while ii < 6 do
    schedule "pluck", 0.02 + ii * 0.075, 0.25, irun[ii], 0.35 + 0.04 * ii
    ii += 1
  od
  schedule "sweep", 0.02, 0.5, 28, 52, 0.5, 180, 3200, 0
  schedule "tom", 0.5, 0.4, 0.5, 82, 0.5
  turnoff
endin
instr darkOpen
  DarkPatch
  giBassCut = 2400
  giBassDec = 0.7
  giBassPump = 0
  schedule "kick", 0.02, 0.36, 1, 0
  schedule "snare", 0.02, 0.5, 0.4, 0.7, 0.4
  schedule "bass", 0.02, 1.1, 28, 0.6
  schedule "sweep", 0.1, 1.3, 76, 40, 0.4, 3500, 160, 1
  turnoff
endin
instr darkLocked
  DarkPatch
  giBassCut = 600
  giBassPump = 0
  schedule "bass", 0.02, 0.08, 40, 0.7
  schedule "bass", 0.15, 0.13, 35, 0.7
  turnoff
endin

; ------------------------------------------------------------------ the desk
; Defined last, so it reads every voice's output on the same cycle. The chorus turns a whole number of times a loop.
instr master
  event_i "e", 0, p3
  ilfo = max(1, round(0.55 * giLoop)) / giLoop
  alfo oscili 1, ilfo
  ac1 vdelay3 gaPad, 9 + 3.2 * alfo, 30
  ac2 vdelay3 gaPad, 9 - 3.2 * alfo, 30
  apL = 0.62 * (gaPad + ac1)
  apR = 0.62 * (gaPad + ac2)
  abuf delayr 2
  atap deltap3 0.75 * giB
  atapf tone atap, 3500
  delayw gaDl + giDlFb * atapf
  awL, awR reverbsc gaRvL + 0.25 * atap, gaRvR + 0.25 * atap, giRvFb, giRvCut
  agL, agR reverbsc gaGate, gaGate, 0.9, 5200
  ag interp gkGate
  aL = gaL + apL + 0.8 * atap + giRvMix * awL + giGateMix * ag * agL
  aR = gaR + apR + 0.8 * atap + giRvMix * awR + giGateMix * ag * agR
  aL butterhp aL, 28
  aR butterhp aR, 28
#ifdef BASSONLY
  aL = gaBass
  aR = gaBass
#end
  fout "$OUT", 16, tanh(giTape * aL) / giTape, tanh(giTape * aR) / giTape
  clear gaL, gaR, gaRvL, gaRvR, gaDl, gaGate, gaPad, gaBass
endin

schedule "$SKETCH", 0, 0.01
schedule "master", 0, $DUR
</CsInstruments>
<CsScore>
</CsScore>
</CsoundSynthesizer>
