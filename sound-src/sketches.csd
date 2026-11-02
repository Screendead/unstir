; Copyright © 2026 Jack Lusher. All rights reserved.
; Rough sketches of the packs' sound for Jack's ear, never in the app: each sold pack's layer over plughole's bed
; (Lens, Escapement, Prism), two takes of each, and Escapement's ratchet tick, five takes. scripts/sounds.sh listen
; passes the sketch (SKETCH), the seed (SEED), the length (DUR) and the output (OUT). Stereo, 48 kHz, 32-bit float;
; the script sets the level.
;
; Every layer plays one motif, the piece's (giMN, giMD), at 75 bpm, a bar 3.2 s. Bars 1 to 5 are play; bar 6, at
; 16 s, is the solve, the only place any layer lands on D.
<CsoundSynthesizer>
<CsOptions>
-n -d -m0
</CsOptions>
<CsInstruments>
sr = 48000
ksmps = 1
nchnls = 2
0dbfs = 1
seed $SEED

#include "glass.udo"

giBeat = 0.8
giSolve = 16

; The motif: A4 B4 A4 E4 G4 A4 G4 E4 in beats, two bars, ending on E so it never comes to rest.
giMN[] fillarray 69, 71, 69, 64, 67, 69, 67, 64
giMD[] fillarray 1, 0.5, 0.5, 1, 1, 1.5, 0.5, 2

gaL init 0
gaR init 0
gaSL init 0
gaSR init 0

opcode Bus, 0, aai
  aL, aR, isend xin
  gaL += aL
  gaR += aR
  gaSL += isend * aL
  gaSR += isend * aR
endop

; Decays by 60 dB in 6.91 tau.
opcode Decay, a, i
  itau xin
  aenv expon 1, 6.91 * itau, 0.001
  xout aenv
endop

; Schedules the motif on an instrument from beat 0 until beat iend: each duration times iscale, itrans semitones
; and icents off, ioffset seconds late. The instrument gets p4 frequency, p5 level, p6 pan, p7 send, p8 colour.
opcode Motif, 0, Siiiiiiiii
  Sins, iscale, itrans, iend, iamp, ipan, icents, ioffset, isend, icol xin
  ib = 0
  ii = 0
  while ib < iend do
    idb = giMD[ii % 8] * iscale
    ilen = min(idb, iend - ib)
    ifq = Hz(giMN[ii % 8] + itrans) * 2 ^ (icents / 1200)
    schedule Sins, ib * giBeat + ioffset, ilen * giBeat, ifq, iamp, ipan, isend, icol
    ib += idb
    ii += 1
  od
endop

; ------------------------------------------------------------------ voices
; An electric piano, FM 1:1 with a tine at 7.1 that dies in 60 ms; the damper falls when the note ends. The pan
; rolls a little at 4.2 Hz. At 1:1 the lower sidebands fold onto 0 Hz, so it is DC-blocked.
instr ep
  inote = p3
  p3 = inote + 1.6
  kndx expseg 2.4, 0.5, 0.5, p3, 0.3
  a1 foscili 1, p4, 1, 1, kndx, gisine
  a1 dcblock2 a1
  a2 poscil 0.12, p4 * 7.1, gisine
  atine Decay 0.009
  adec Decay 0.9
  arel linseg 1, inote, 1, 0.35, 0, 1.25, 0
  aatk cosseg 0, 0.003, 1
  ay butterlp (a1 + a2 * atine) * adec * arel * aatk, 4500
  kp = p6 + 0.15 * poscil:k(1, 4.2, gisine)
  kth = (kp + 1) * $M_PI / 4
  Bus p5 * ay * cos(kth), p5 * ay * sin(kth), p7
endin

; A halftone dot: a short struck glass.
instr dot
  p3 = 1.6
  ag Glass p4, 1.6, 0.35, 0.6, 0.7, 0.4, 0.9
  aL, aR Pan p5 * ag, p6
  Bus aL, aR, p7
endin

; A bowed glass over the note's length.
instr bowed
  as Swell p4, p3
  aL, aR Pan p5 * as, p6
  Bus aL, aR, p7
endin

; An ocarina: a sine with a little of its second and third, breath round the note, vibrato that comes in late.
; p8 colour: 0 dark, 1 bright.
instr ocarina
  inote = p3
  p3 = inote + 0.15
  kvd linseg 0, 0.25, 0, 0.4, 1, 1, 1
  kvib poscil 0.0035, 5.2, gisine
  kf = p4 * (1 + kvib * kvd)
  a1 poscil 1, kf, gisine
  a2 poscil 0.18 * (0.5 + p8), 2 * kf, gisine
  a3 poscil 0.06 * p8, 3 * kf, gisine
  anz Noise
  abr butterbp anz, kf, kf * 0.25
  aenv linseg 0, 0.05, 1, max(inote - 0.05, 0.01), 0.85, 0.15, 0
  ay butterlp (a1 + a2 + a3 + 0.12 * abr) * aenv, 2000 + 2500 * p8
  aL, aR Pan p5 * ay, p6
  Bus aL, aR, p7
endin

; A felt piano note, close and dry: four damped partials and the hammer's thump.
instr felt
  p3 = 1.4
  ay Mode p4, 0.5, 1
  ay += Mode(2 * p4, 0.22, 0.45, 1)
  ay += Mode(3.01 * p4, 0.11, 0.2, 2)
  ay += Mode(4.03 * p4, 0.06, 0.1, 3)
  anz Noise
  ath butterlp anz * Decay(0.0012), 500
  aatk cosseg 0, 0.002, 1
  ay butterlp (ay + 0.3 * ath) * aatk, 2200
  aL, aR Pan p5 * ay, p6
  Bus aL, aR, p7
endin

; A muted reed: a square through a closing lowpass, short.
instr reed
  inote = p3
  p3 = inote + 0.06
  a1 vco2 1, p4, 10
  kcf expseg 2200, 0.08, 900, p3, 700
  ay moogladder a1, kcf, 0.1
  aenv linseg 0, 0.012, 1, max(inote - 0.012, 0.01), 0.7, 0.06, 0
  aL, aR Pan 0.4 * p5 * ay * aenv, p6
  Bus aL, aR, p7
endin

; A cold FM bell pad note (1:3.5 and 1:1.41), slow in and out.
instr bell
  aatk linseg 0, 1.4, 1, p3 - 2.8, 1, 1.4, 0
  kndx = 0.9 + 0.25 * poscil:k(1, 0.13, gisine, random:i(0, 1))
  a1 foscili 1, p4, 1, 3.5, kndx, gisine
  a2 foscili 0.5, p4 * 1.002, 1, 1.41, 0.6, gisine
  ay butterlp (a1 + a2) * aatk, 3200
  aL, aR Pan p5 * ay, p6
  Bus aL, aR, p7
endin

; The same bell struck.
instr bellhit
  p3 = 3
  kndx expseg 2, 0.4, 0.6, p3, 0.4
  a1 foscili 1, p4, 1, 3.5, kndx, gisine
  a2 foscili 0.4, p4 * 1.002, 1, 1.41, 0.5, gisine
  aatk cosseg 0, 0.002, 1
  ay butterlp (a1 + a2) * Decay(0.6) * aatk, 3600
  aL, aR Pan p5 * ay, p6
  Bus aL, aR, p7
endin

; ------------------------------------------------------------------ the muted kit
; A felt kick: p4 level.
instr kick
  p3 = 0.5
  kf expseg 120, 0.045, 52, 0.4, 44
  a1 poscil 1, kf, gisine
  aenv expseg 1, 0.4, 0.001
  anz Noise
  acl butterlp anz * Decay(0.0015), 800
  ay butterlp tanh(1.6 * (a1 * aenv + 0.25 * acl)), 400
  Bus 0.7 * p4 * ay, 0.7 * p4 * ay, 0.05
endin

; A scuff, muffled: p4 level, p5 pan.
instr scuff
  p3 = 0.4
  anz Noise
  aenv expseg 0.001, 0.006, 1, 0.07, 0.15, 0.25, 0.001
  ay butterbp anz * aenv, 1300, 1800
  ay butterlp ay, 3200
  aL, aR Pan p4 * ay, p5
  Bus aL, aR, 0.15
endin

; ------------------------------------------------------------------ the ratchet's tick
; One mode of a small steel part, struck by ain: ifq Hz, decaying as Decay's itau, its impulse response iamp high. A
; two-pole resonator, unscaled, rings 1 / sin(w) high; mode would put the upper modes sharp (14.9 kHz near 19).
opcode Ring, a, aiii
  ain, ifq, itau, iamp xin
  xout iamp * sin(2 * $M_PI * ifq / sr) * reson(ain, ifq, 1 / ($M_PI * itau), 0)
endop

; Six modes at ifq times each ratio, each with its decay and level. Written out, as an opcode called in a loop is one
; instance, and the filters would share their state.
opcode Steel, a, aii[]i[]i[]
  ain, ifq, ir[], itau[], iamp[] xin
  a0 Ring ain, ifq * ir[0], itau[0], iamp[0]
  a1 Ring ain, ifq * ir[1], itau[1], iamp[1]
  a2 Ring ain, ifq * ir[2], itau[2], iamp[2]
  a3 Ring ain, ifq * ir[3], itau[3], iamp[3]
  a4 Ring ain, ifq * ir[4], itau[4], iamp[4]
  a5 Ring ain, ifq * ir[5], itau[5], iamp[5]
  xout a0 + a1 + a2 + a3 + a4 + a5
endop

; One tooth dropping: p4 take, p5 level, p6 pan. Each tick a few percent off the last. Round 15's two, both soft and
; through a room: 0 a pencil's tap on paper over wood, 1 a brass pawl lifting and falling on its tooth, its ring in D
; and muted. Round 16's three, metal on metal and dry (Jack: "an actual small piece of metal ticking against another
; small piece of metal"), none tuned to the key: 2 a watch's escapement, the pallet unlocking and the tooth dropping
; on it 4 to 5 ms later, almost pure click above 6 kHz; 3 a steel pawl snapping onto a steel ratchet wheel, a bright
; tink near 2.4 kHz with one bounce of the pawl; 4 a counter's click spring on its wheel, a larger part, a short clack
; with a body near 1.4 kHz under faster overtones.
instr rtick
  p3 = 0.25
  ij random -0.03, 0.03
  anz Noise
  aimp mpulse 1, 0
  if p4 == 0 then
    a1 butterbp anz * Decay(0.0015), 3200 * (1 + ij), 2500
    a2 butterbp anz * Decay(0.006), 5500, 3000
    a3 Mode 820 * (1 + ij), 0.007, 0.5
    a3 += Mode(1370 * (1 + ij), 0.004, 0.3, 1)
    a3 += Mode(240 * (1 + ij), 0.012, 0.25, 2)
    ay = a1 + 0.25 * a2 + a3
  elseif p4 == 1 then
    alift butterhp anz * Decay(0.0006), 3000
    alift = 0.1 * alift + Mode(4100, 0.0015, 0.12)
    ifq = Hz(86) * (1 + ij / 3)
    adrop butterhp anz * Decay(0.001), 2000
    adrop = 0.4 * adrop + Mode(ifq, 0.012, 1)
    adrop += Mode(ifq * 2.32, 0.006, 0.45, 1)
    adrop += Mode(ifq * 4.25, 0.004, 0.25, 2)
    adrop += Mode(330, 0.01, 0.35, 0.5)
    adrop delay adrop, 0.022
    ay butterlp alift + adrop, 6000
  elseif p4 == 2 then
    ahit butterhp anz * Decay(0.00012), 5000
    ahit = aimp + 0.15 * ahit
    ahit = 0.4 * ahit + delay(ahit, 0.0045 * (1 + 5 * ij))
    ir[] fillarray 1, 1.41, 1.83, 2.37, 0.74, 1.12
    itau[] fillarray 0.004, 0.003, 0.002, 0.0014, 0.0025, 0.0035
    iamp[] fillarray 0.6, 0.45, 0.3, 0.2, 0.25, 0.3
    ay Steel ahit, 6300 * (1 + ij / 2), ir, itau, iamp
    ay = butterhp(ay, 3000) + 0.15 * ahit
  elseif p4 == 3 then
    ahit butterhp anz * Decay(0.0003), 3000
    ahit = aimp + 0.12 * ahit
    ahit += 0.3 * delay(ahit, 0.0018 * (1 + 3 * ij))
    ir[] fillarray 1, 1.47, 2.31, 3.62, 3.67, 1.013
    itau[] fillarray 0.008, 0.0065, 0.005, 0.0035, 0.003, 0.0075
    iamp[] fillarray 0.4, 0.4, 0.6, 0.65, 0.5, 0.25
    ay Steel ahit, 2400 * (1 + ij / 2), ir, itau, iamp
    ay += 0.1 * ahit
  else
    ahit butterbp anz * Decay(0.0006), 3500, 4000
    ahit = aimp + 0.2 * ahit
    ir[] fillarray 1, 1.06, 2.2, 3.4, 5.1, 7.3
    itau[] fillarray 0.007, 0.006, 0.0045, 0.0035, 0.0022, 0.0015
    iamp[] fillarray 0.4, 0.25, 0.6, 0.7, 0.65, 0.45
    ay Steel ahit, 1500 * (1 + ij / 2), ir, itau, iamp
    ay += 0.12 * ahit
  endif
  aatk cosseg 0, 0.0002, 1
  if p4 < 2 then
    ay Room ay * aatk, 0.12, 0.15, 0.08, 0.06
  else
    ; Each take's level to round 15's brass pawl's loudest 400 ms, so a take stands in Escapement's layer as that did.
    igain[] fillarray 0, 0, 5.8, -0.3, 1.8
    ay *= aatk * ampdb(igain[p4] + 30 * ij)
  endif
  aL, aR Pan p5 * ay, p6
  Bus aL, aR, 0
endin

; Ticks after a lift at ilift, one per running clock, as the game times them (Level's tickBeat 0.15 s, tickTurn
; 0.3 s); returns when the last lands.
opcode Ticks, i, iii
  ilift, iclocks, itake xin
  ipans[] fillarray -0.3, 0.3, 0
  ij = 0
  while ij < iclocks do
    schedule "rtick", ilift + 0.15 + 0.3 * ij, 0.25, itake, 0.6, ipans[ij]
    ij += 1
  od
  xout ilift + 0.15 + 0.3 * (iclocks - 1)
endop

; ------------------------------------------------------------------ sketches
; Lens A, two lenses: the motif on electric piano against itself at half speed an octave down, both landing on D.
instr lensA
  Motif "ep", 1, 0, 20, 0.42, -0.35, 0, 0, 0.25, 0
  Motif "ep", 2, -12, 20, 0.5, 0.35, 0, 0, 0.25, 0
  schedule "ep", giSolve, 2.5, Hz(62), 0.45, -0.35, 0.3
  schedule "ep", giSolve, 2.5, Hz(50), 0.5, 0.35, 0.3
  turnoff
endin

; Lens B, the halftone's three pitches: glass dots at three scales (each twice the last, as a lens step), high and
; quick, middle, and a low bowed glass at a quarter speed.
instr lensB
  Motif "dot", 1, 12, 20, 0.32, -0.5, 0, 0, 0.35, 0
  Motif "dot", 2, 0, 20, 0.45, 0.45, 0, 0, 0.3, 0
  Motif "bowed", 4, -12, 20, 0.4, 0, 0, 0, 0.2, 0
  schedule "dot", giSolve, 1.6, Hz(74), 0.32, -0.5, 0.35
  schedule "dot", giSolve, 1.6, Hz(62), 0.45, 0.45, 0.3
  schedule "bowed", giSolve, 3.6, Hz(50), 0.45, 0, 0.2
  turnoff
endin

; A player's moves (lift times) and how many clocks run on each; the eleventh solves, its last tick at 16 s.
giMoves[] fillarray 0.8, 2.6, 3.7, 5.9, 7.0, 8.9, 10.2, 11.6, 12.9, 14.3, 15.55
giClocks[] fillarray 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2

; Escapement's play: each move steps the motif one note (iquant: on the lift, or on the next eighth), and the solve's
; last tick lands it on D.
opcode Escape, 0, Siiii
  Slead, ilen, iamp, itake, iquant xin
  ik = 0
  while ik < lenarray(giMoves) do
    ilift = giMoves[ik]
    ilast Ticks ilift, giClocks[ik], itake
    if ik < lenarray(giMoves) - 1 then
      it = iquant == 1 ? ceil(ilift / (giBeat / 2) - 1e-9) * giBeat / 2 : ilift
      schedule Slead, it, ilen, Hz(giMN[ik % 8]), iamp, 0, 0.04, 0
    else
      schedule Slead, ilast, 4 * ilen, Hz(62), iamp, 0, 0.08, 0
    endif
    ik += 1
  od
endop

; Escapement A, the workshop: a felt kick on 1 and a scuff on 3, half time, a ghost scuff every other bar; a felt
; piano close and dry, its notes on the lift; the pencil's ticks.
instr escA
  ib = 0
  while ib < 5 do
    schedule "kick", ib * 3.2, 0.5, 0.6
    schedule "scuff", ib * 3.2 + 1.6, 0.4, 0.28, 0.1
    if ib % 2 == 1 then
      schedule "scuff", ib * 3.2 + 2.8, 0.4, 0.1, -0.2
    endif
    ib += 1
  od
  schedule "kick", giSolve, 0.5, 0.4
  Escape "felt", 1, 0.5, 0, 0
  turnoff
endin

; Escapement B, the pawl: the foot drum on 1 and the and of 2, scuffs on 2 and 4 with faint ghosts; a muted reed,
; its notes on the next eighth after the lift; ticks of take itake (rtick's p4), round 15's the brass pawl's.
opcode EscB, 0, i
  itake xin
  ib = 0
  while ib < 5 do
    is = ib * 3.2
    schedule "kick", is, 0.5, 0.6
    schedule "kick", is + 1.2, 0.5, 0.35
    schedule "scuff", is + 0.8, 0.4, 0.26, -0.1
    schedule "scuff", is + 2.4, 0.4, 0.26, 0.1
    schedule "scuff", is + 2.0, 0.4, 0.07, -0.3
    schedule "scuff", is + 3.0, 0.4, 0.06, 0.3
    ib += 1
  od
  schedule "kick", giSolve, 0.5, 0.4
  Escape "reed", 0.45, 0.55, itake, 1
endop
instr escB
  EscB 1
  turnoff
endin
; Jack kept Escapement B's layer (round 16); these play it with round 16's ticks.
instr escBtickC
  EscB 2
  turnoff
endin
instr escBtickD
  EscB 3
  turnoff
endin
instr escBtickE
  EscB 4
  turnoff
endin

; Prism A, three channels out of tune: the motif on three ocarinas 14 cents apart (red left, green, blue right) over
; a held cold bell chord, D4 A4 E5; the solve brings them to one D.
instr prismA
  Motif "ocarina", 1, 0, 20, 0.26, -0.7, -14, 0, 0.3, 0.5
  Motif "ocarina", 1, 0, 20, 0.26, 0, 0, 0, 0.3, 0.5
  Motif "ocarina", 1, 0, 20, 0.26, 0.7, 14, 0, 0.3, 0.5
  ipad[] fillarray 62, -0.4, 69, 0.4, 76, 0
  ii = 0
  while ii < 6 do
    schedule "bell", 0, giSolve + 0.4, Hz(ipad[ii]), 0.1, ipad[ii + 1], 0.4
    ii += 2
  od
  ii = 0
  while ii < 3 do
    schedule "ocarina", giSolve, 2.6, Hz(62), 0.26, (ii - 1) * 0.7, 0.35, 0.5
    ii += 1
  od
  schedule "bell", giSolve - 0.4, 3.8, Hz(62), 0.12, 0, 0.4
  schedule "bell", giSolve - 0.4, 3.8, Hz(69), 0.1, 0, 0.4
  turnoff
endin

; Prism B, three channels out of register: the same three a few cents apart and a flam late (green 45 ms, blue
; 90 ms), red dark and blue bright, over cold bells struck twice a bar; the solve strikes them together, in tune.
instr prismB
  Motif "ocarina", 1, 0, 20, 0.26, -0.7, -6, 0, 0.3, 0
  Motif "ocarina", 1, 0, 20, 0.26, 0, 3, 0.045, 0.3, 0.5
  Motif "ocarina", 1, 0, 20, 0.26, 0.7, 9, 0.09, 0.3, 1
  ihits[] fillarray 74, 69, 76, 71
  ib = 0
  while ib < 10 do
    schedule "bellhit", ib * 1.6, 3, Hz(ihits[ib % 4]), 0.08, ib % 2 == 0 ? -0.5 : 0.5, 0.5
    ib += 1
  od
  ii = 0
  while ii < 3 do
    schedule "ocarina", giSolve, 2.6, Hz(62), 0.26, (ii - 1) * 0.7, 0.35, ii / 2
    ii += 1
  od
  schedule "bellhit", giSolve, 3, Hz(74), 0.1, 0, 0.5
  schedule "bellhit", giSolve, 3, Hz(62), 0.1, 0, 0.5
  turnoff
endin

; One tick alone.
instr tickA
  schedule "rtick", 0.02, 0.25, 0, 0.6, 0
  turnoff
endin
instr tickB
  schedule "rtick", 0.02, 0.25, 1, 0.6, 0
  turnoff
endin
instr tickC
  schedule "rtick", 0.02, 0.25, 2, 0.6, 0
  turnoff
endin
instr tickD
  schedule "rtick", 0.02, 0.25, 3, 0.6, 0
  turnoff
endin
instr tickE
  schedule "rtick", 0.02, 0.25, 4, 0.6, 0
  turnoff
endin

; Ticks in play: seven moves on one, two and three clocks.
opcode TickRun, 0, i
  itake xin
  imoves[] fillarray 1.0, 3.2, 4.6, 7.0, 8.8, 10.5, 12.4
  iclocks[] fillarray 1, 1, 2, 1, 2, 3, 2
  ik = 0
  while ik < lenarray(imoves) do
    ilast Ticks imoves[ik], iclocks[ik], itake
    ik += 1
  od
endop
instr ticksA
  TickRun 0
  turnoff
endin
instr ticksB
  TickRun 1
  turnoff
endin
instr ticksC
  TickRun 2
  turnoff
endin
instr ticksD
  TickRun 3
  turnoff
endin
instr ticksE
  TickRun 4
  turnoff
endin

; Defined last, so it reads every voice's output on the same cycle.
instr master
  event_i "e", 0, p3
  awL, awR reverbsc gaSL, gaSR, 0.85, 7000, sr, 0.5
  ifade = min(1.5, p3 / 4)
  afade cosseg 1, p3 - ifade, 1, ifade, 0
  fout "$OUT", 16, (gaL + 1.65 * awL) * afade, (gaR + 1.65 * awR) * afade
  clear gaL, gaR, gaSL, gaSR
endin

schedule "$SKETCH", 0, 0.01
schedule "master", 0, $DUR
</CsInstruments>
<CsScore>
</CsScore>
</CsoundSynthesizer>
