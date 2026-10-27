; Copyright © 2026 Jack Lusher. All rights reserved.
; The glass set's effects, one per run: scripts/sounds.sh passes the instrument (FX), its argument (N: a heal's number
; or a variant), the length to write (DUR), the seed (SEED) and the output file (OUT). Mono, 48 kHz, 32-bit float; the
; script sets the level. An effect that needs a part's peak records the part in a first pass, so its output instrument
; starts late and fout writes only from there.
<CsoundSynthesizer>
<CsOptions>
-n -d -m0
</CsOptions>
<CsInstruments>
sr = 48000
ksmps = 1
nchnls = 1
0dbfs = 1
seed $SEED

#include "glass.udo"

; Hall settings (feedback, cutoff), each with the scale that brings its wet to unit energy (measured on an impulse),
; so a wet level means what the sketch's did.
#define HEAL_HALL #0.8, 5000#
#define HEAL_NORM #2.144#
#define SOLVE_HALL #0.82, 4000#
#define SOLVE_NORM #2.172#
#define SPILL_HALL #0.78, 4000#
#define SPILL_NORM #2.272#
#define SHORT_HALL #0.7, 4000#
#define SHORT_NORM #2.428#

gaBus init 0

; Writes the effect from the calling instrument's start, for idur seconds with a 20 ms fade at the end, then ends the
; run.
opcode Out, 0, ai
  ain, idur xin
  event_i "e", 0, idur
  aend cosseg 1, idur - 0.02, 1, 0.02, 0
  fout "$OUT", 16, ain * aend
endop

; ------------------------------------------------------------------ voices other instruments schedule into gaBus
; p4 frequency, p5 the glass's length (for its tail fade), p6 decay, p7 brightness, p8 strike, p9 FM, p10 level
instr v_glass
  ag Glass p4, p5, p6, p7, p8, p9, 0.9
  gaBus += p10 * ag
endin

; p4 start frequency, p5 rise, p6 decay, p7 level
instr v_bubble
  ab Bubble p4, p5, p6, p7, p3
  gaBus += ab
endin

; p4 frequency, p5 level
instr v_swell
  as Swell p4, p3
  gaBus += p5 * as
endin

; ------------------------------------------------------------------ tick
; One 30° detent (variant p4, 0 to 3): a tiny glass bead at D7 with a little body near D5, 50 ms.
instr tick
  iv = p4
  ip[] fillarray 1.0, 1.028, 0.974, 1.012
  isp[] fillarray 1.0, 0.97, 1.03, 1.0
  ifq = Hz(98) * ip[iv]
  a1 Mode ifq, 0.006, 1
  a2 Mode ifq * 1.62 * isp[iv], 0.0035, 0.45, 1
  a3 Mode ifq * 2.41, 0.0022, 0.25 * isp[iv], 2
  a4 Mode Hz(74) * ip[iv] * (1 + 0.02 * iv), 0.0045, 0.55
  anv expon 1, 20 * 0.0007, exp(-20)
  anz Noise
  a5 RBJ anz * anv, 1, 2500
  aramp cosseg 0, 0.00025, 1
  Out (a1 + a2 + a3 + a4 + 0.2 * a5) * aramp, p3
endin

; ------------------------------------------------------------------ push
; A wrong stir: an Eb4-E4-F4 cluster, out of key, in murky FM that clears (each carrier modulated at half its own
; frequency), sagging 3.5%, lowpassed at 1.3 kHz, with a low bubble "blup" and a short room.
instr push
  id = 0.55
  asag expon 1, 20 * 0.18, exp(-20)
  ksag = 1 - 0.035 * (1 - k(asag))
  aidx expon 1.6, 20 * 0.08, 1.6 * exp(-20)
  ; sin(ph + idx sin(ph / 2)) with ph = 4 pi psi, psi a phasor at half the frequency
  ap1 phasor Hz(63) * ksag / 2, random:i(0, 0.5)
  ap2 phasor Hz(64) * ksag / 2, random:i(0, 0.5)
  ap3 phasor Hz(65) * ksag / 2, random:i(0, 0.5)
  ay = tablei:a(2 * ap1 + aidx * tablei:a(ap1, gisine, 1, 0, 1) / (2 * $M_PI), gisine, 1, 0, 1)
  ay += 0.9 * tablei:a(2 * ap2 + aidx * tablei:a(ap2, gisine, 1, 0, 1) / (2 * $M_PI), gisine, 1, 0, 1)
  ay += 0.7 * tablei:a(2 * ap3 + aidx * tablei:a(ap3, gisine, 1, 0, 1) / (2 * $M_PI), gisine, 1, 0, 1)
  adec expon 1, 20 * 0.13, exp(-20)
  aatk expon 1, 20 * 0.002, exp(-20)
  ay RBJ ay * adec * (1 - aatk), 0, 1300, 0.8
  ay += 0.35 * Bubble(430, 0.35, 0.045, 1, id)
  aenv cosseg 0, 0.0008, 1, id * 0.7 - 0.0008, 1, id * 0.3, 0
  ay Room ay * aenv, 0.8, 0.6, 0.35, 0.10
  Out ay, p3
endin

; ------------------------------------------------------------------ heal
; The nth heal (p4): a bubble plip rising into a struck glass on step n - 1 up from D5 (D5 E5 G5 A5 B5 D6), with an
; octave-down body and a twelfth of sparkle, in a 2 s room.
instr heal
  ifq Degree p4 - 1
  a1 Glass ifq, 3, 1.1, 0.9, 0.8, 0.55, 0.9
  a2 Glass ifq / 2, 3, 0.5, 0.2, 0, 0, 0.9
  a3 Glass ifq * 3, 3, 0.35, 0.3, 0, 0, 0.9
  ab Bubble ifq * 1.5, 0.45, 0.012, 0.5
  ay Hall a1 + 0.3 * a2 + 0.1 * a3 + ab, $HEAL_HALL, 0.22, $HEAL_NORM
  Out ay, p3
endin

; ------------------------------------------------------------------ tank
; One step of the whole tank: a knock, seven damped stone-and-steel modes from 188 to 1905 Hz, a 420 Hz band of rumble
; on the haptic's own curve (1, 0.5 at 30 ms, 0 at 95 ms), a 92 Hz sub for headphones, saturation, a short room.
; Three passes, as the sketch scales the rumble, the knock and then the whole body by their peaks.
gitRum Tab 0.5
gitKnock Tab 0.5
gitBody Tab 0.5

instr tank
  schedule "tank_parts", 0, 0.5
  schedule "tank_body", 0.5, 0.5
  schedule "tank_out", 1, p3
  turnoff
endin

instr tank_parts
  acurve linseg 1, 0.03, 0.5, 0.065, 0
  aph phasor 55
  agrit = 1 + 0.6 * tablei:a(aph + 2 * poscil:a(1, 13, gisine) / (2 * $M_PI), gisine, 1, 0, 1)
  anz Noise
  arum RBJ anz, 2, 420, 0.9
  Record arum * acurve * agrit, gitRum
  aknv expon 1, 20 * 0.0015, exp(-20)
  anz2 Noise
  aknock RBJ anz2 * aknv, 1, 1200
  Record aknock, gitKnock
endin

instr tank_body
  ay Mode 188, 0.050, 1.0, random:i(0, 2 * $M_PI)
  ay += Mode(262, 0.040, 0.9, random:i(0, 2 * $M_PI))
  ay += Mode(347, 0.032, 0.75, random:i(0, 2 * $M_PI))
  ay += Mode(463, 0.024, 0.6, random:i(0, 2 * $M_PI))
  ay += Mode(611, 0.018, 0.45, random:i(0, 2 * $M_PI))
  ay += Mode(789, 0.013, 0.35, random:i(0, 2 * $M_PI))
  ay += Mode(1905, 0.006, 0.25, random:i(0, 2 * $M_PI))
  ay += 0.5 * Mode(92, 0.06, 1.0)
  ay += 1.4 * Play(gitRum) / TabPeak(gitRum)
  ay += 0.9 * Play(gitKnock) / TabPeak(gitKnock)
  aenv linseg 1, 0.09, 0.8, 0.05, 0
  Record ay * aenv, gitBody
endin

instr tank_out
  ay = tanh(1.5 * Play(gitBody) / TabPeak(gitBody))
  aramp cosseg 0, 0.0003, 1
  ay Room ay * aramp, 0.6, 0.45, 0.25, 0.12
  Out ay, p3
endin

; ------------------------------------------------------------------ seized
; A touch on a dead knob: an 11 ms noise burst band-limited to 180-1100 Hz and seven close modes damped in 8 ms.
gitSeized Tab 0.2

instr seized
  schedule "seized_burst", 0, 0.2
  schedule "seized_out", 0.2, p3
  turnoff
endin

instr seized_burst
  anv expon 1, 20 * 0.011, exp(-20)
  anz Noise
  ay RBJ anz * anv, 1, 180
  ay RBJ ay, 0, 1100
  ay RBJ ay, 0, 1100
  Record ay, gitSeized
endin

instr seized_out
  ay = Play(gitSeized) / TabPeak(gitSeized)
  ay += 0.18 * Mode(297, 0.008, 1, random:i(0, 2 * $M_PI))
  ay += 0.18 * Mode(331, 0.008, 1, random:i(0, 2 * $M_PI))
  ay += 0.18 * Mode(368, 0.008, 1, random:i(0, 2 * $M_PI))
  ay += 0.18 * Mode(412, 0.008, 1, random:i(0, 2 * $M_PI))
  ay += 0.18 * Mode(455, 0.008, 1, random:i(0, 2 * $M_PI))
  ay += 0.18 * Mode(517, 0.008, 1, random:i(0, 2 * $M_PI))
  ay += 0.18 * Mode(583, 0.008, 1, random:i(0, 2 * $M_PI))
  aatk expon 1, 20 * 0.0015, exp(-20)
  Out ay * (1 - aatk), p3
endin

; ------------------------------------------------------------------ solve
; The bloom: 11 rising bubbles (the wave), a quick E5-G5-B5-E6 wash, and at 0.42 s D4-D5-A5-D6 landing on the tonic
; with a bowed D4 swell under it, a breath of air near 6.5 kHz, in a 3 s room.
gitAir Tab 1.4

instr solve
  schedule "solve_air", 0, 1.4
  it0 = 1.4
  ii = 0
  while ii < 11 do
    iat = max(0, 0.045 * ii + random:i(-0.01, 0.01))
    if0 = 900 * 2 ^ (ii * 0.13 + random:i(-0.08, 0.08))
    schedule "v_bubble", it0 + iat, min(8 * 0.018 + 0.01, 0.6), if0, 0.5, 0.018, 0.35 * (1 - ii / 14)
    ii += 1
  od
  iwash[] fillarray 0, 76, 0.30, 0.07, 79, 0.28, 0.14, 83, 0.24, 0.22, 88, 0.16
  ii = 0
  while ii < 12 do
    schedule "v_glass", it0 + iwash[ii], 1.6, Hz(iwash[ii + 1]), 1.6, 0.45, 0.7, 0.5, 0.3, iwash[ii + 2]
    ii += 3
  od
  iland[] fillarray 62, 0.35, 74, 0.6, 81, 0.45, 86, 0.55
  ii = 0
  while ii < 8 do
    schedule "v_glass", it0 + 0.42, 2.58, Hz(iland[ii]), 2.58, iland[ii] > 62 ? 1.2 : 0.9, 0.8, 0.7, 0.5, iland[ii + 1]
    ii += 2
  od
  schedule "v_swell", it0 + 0.3, 2.6, Hz(62), 0.25
  schedule "solve_out", it0, p3
  turnoff
endin

instr solve_air
  anz Noise
  ay RBJ anz, 2, 6500, 1.71
  alin linseg 0, 0.35, 1
  adec expsega 1, 0.35, 1, 20 * 0.3, exp(-20)
  Record ay * alin * adec, gitAir
endin

instr solve_out
  ay = gaBus
  clear gaBus
  ay += 0.06 * Play(gitAir) / TabPeak(gitAir)
  aramp cosseg 0, 0.0005, 1
  ay Hall ay * aramp, $SOLVE_HALL, 0.3, $SOLVE_NORM
  afade cosseg 1, p3 - 0.6, 1, 0.6, 0
  Out ay * afade, p3
endin

; ------------------------------------------------------------------ spilled
; Endless overflows: a stream of bubbles swelling to 170 a second, rushing water whose centre glides 900 -> 1300 ->
; 350 Hz with a flutter, A4 then D4 glass falling to the tonic, three last drips into near-silence.
gitWater Tab 4.2

instr spilled
  schedule "spilled_water", 0, 4.2
  it0 = 4.2
  its[] fillarray 0, 0.9, 1.4, 1.9, 2.7, 3.0
  irs[] fillarray 20, 90, 170, 110, 8, 0
  is = 0
  while is < 3 do
    is += -log(1 - random:i(0, 1)) / max(Interp(is, its, irs), 1)
    if is < 3 then
      irate = Interp(is, its, irs)
      ibig = random:i(0, 1) < 0.3 ? 1 : 0
      if0 = ibig == 1 ? random:i(260, 520) : 2 ^ random:i(log2(600), log2(2200))
      iamp = (ibig == 1 ? 0.5 : 0.25) * random:i(0.4, 1) * min(1, irate / 90)
      irise random 0.2, 0.7
      itau = random:i(0.01, 0.035) * (ibig == 1 ? 2 : 1)
      schedule "v_bubble", it0 + is, min(8 * itau + 0.01, 0.6), if0, irise, itau, iamp
    endif
  od
  schedule "v_glass", it0 + 0.15, 2.4, Hz(69), 2.4, 0.9, 0.5, 0.3, 0.2, 0.28
  schedule "v_glass", it0 + 1.7, 2.4, Hz(62), 2.4, 0.9, 0.5, 0.3, 0.2, 0.34
  schedule "v_bubble", it0 + 3.05, 0.17, 1500, 0.5, 0.02, 0.22
  schedule "v_bubble", it0 + 3.5, 0.17, 1320, 0.5, 0.02, 0.12
  schedule "v_bubble", it0 + 4.0, 0.17, 1180, 0.5, 0.02, 0.05
  schedule "spilled_out", it0, p3
  turnoff
endin

instr spilled_water
  aenv linseg 0.05, 1, 0.6, 0.5, 1, 0.5, 0.7, 0.9, 0.05, 0.4, 0
  kc linseg 900, 1.5, 1300, 0.7, 800, 1, 350
  anz Noise
  ay Band anz, kc, 1.2
  Record ay * aenv, gitWater
endin

instr spilled_out
  ay = gaBus
  clear gaBus
  kfl poscil 4, 0.7, gisine
  aflutter poscil 0.35, 9 + kfl, gisine
  ay += 0.55 * Play(gitWater) * (1 + aflutter) / TabPeak(gitWater)
  aramp cosseg 0, 0.005, 1
  ay Hall ay * aramp, $SPILL_HALL, 0.25, $SPILL_NORM
  asink linseg 1, 3.2, 1, p3 - 3.2, 0.3
  afade cosseg 1, p3 - 0.3, 1, 0.3, 0
  Out ay * asink * afade, p3
endin

; ------------------------------------------------------------------ tap (new)
; A button (variant p4, 0 to 3): a small soft glass on A5 with a touch of A4 body, a few cents and a strike apart from
; one variant to the next, in the short room. Quieter and far shorter than a heal.
instr tap
  iv = p4
  ip[] fillarray 1.0, 1.0035, 0.9965, 1.0017
  idb[] fillarray 0.9, 1.25, 0.7, 1.1
  ifq = Hz(81) * ip[iv]
  a1 Glass ifq, 0.5, 0.14, 0.5, 0.35, 0.2, idb[iv]
  a2 Mode Hz(69) * ip[iv], 0.012, 0.3
  aramp cosseg 0, 0.0006, 1
  ay Room (a1 + a2) * aramp, 0.35, 0.3, 0.2, 0.08
  Out ay, p3
endin

; ------------------------------------------------------------------ switch (new)
; Changing tier on the menu: the list stirs away and unstirs into the next over about 0.6 s. A swish of water whose
; centre rises and falls while its swirl slows from 14 to 5 turns a second, small bubbles in the middle, and A5 and D6
; settling at 0.45 s.
instr switch
  schedule "switch_swish", 0, 0.7
  ib[] fillarray 0.08, 1000, 0.14, 1250, 0.19, 900, 0.25, 1400, 0.31, 1150, 0.38, 1600
  ii = 0
  while ii < 12 do
    schedule "v_bubble", ib[ii], 0.13, ib[ii + 1] * random:i(0.95, 1.05), 0.6, 0.014, 0.12
    ii += 2
  od
  schedule "v_glass", 0.45, 1.0, Hz(81), 1.0, 0.3, 0.6, 0.3, 0.25, 0.25
  schedule "v_glass", 0.47, 1.0, Hz(86), 1.0, 0.25, 0.6, 0.2, 0.2, 0.17
  schedule "switch_out", 0, p3
  turnoff
endin

instr switch_swish
  kc linseg 500, 0.28, 1400, 0.32, 600
  aenv linseg 0, 0.15, 1, 0.15, 1, 0.35, 0
  kswirl linseg 14, 0.6, 5
  asw poscil 0.4, kswirl, gisine
  anz Noise
  ay Band anz, kc, 1.0
  gaBus += 0.9 * ay * aenv * (1 + asw)
endin

instr switch_out
  ay = gaBus
  clear gaBus
  ay Hall ay, $HEAL_HALL, 0.18, $HEAL_NORM
  Out ay, p3
endin

; ------------------------------------------------------------------ undo (new)
; A stir running backwards: a short forward stir (an E5 and B5 glass struck, a swish of water falling from 1.2 kHz to
; 500 Hz, three bubbles, a small room) is recorded, then played in reverse, so the room swells in, the swish rises,
; the bubbles sink and the glass grows into its strike. A faint bead at 0 answers the finger straight away.
gitFwd Tab 0.5

instr undo
  schedule "undo_fwd", 0, 0.5
  schedule "v_glass", 0, 0.5, Hz(76), 0.5, 0.35, 0.6, 0.6, 0.4, 0.5
  schedule "v_glass", 0.03, 0.47, Hz(83), 0.47, 0.3, 0.5, 0.4, 0.3, 0.22
  schedule "v_bubble", 0.02, 0.1, 1000, 0.6, 0.012, 0.12
  schedule "v_bubble", 0.06, 0.1, 1300, 0.6, 0.012, 0.1
  schedule "v_bubble", 0.1, 0.1, 1150, 0.6, 0.012, 0.08
  schedule "undo_out", 0.5, p3
  turnoff
endin

instr undo_fwd
  kc expseg 1200, 0.4, 500
  aenv expon 1, 20 * 0.12, exp(-20)
  anz Noise
  ay Band anz, kc, 0.9
  ay = gaBus + 0.5 * ay * aenv
  clear gaBus
  ay Hall ay, $SHORT_HALL, 0.35, $SHORT_NORM
  ; the recording's last 5 ms fades in, so the reversed start is soft
  afade cosseg 1, 0.495, 1, 0.005, 0
  Record ay * afade, gitFwd
endin

instr undo_out
  ; read backwards, and let it stop on a 5 ms fade rather than a cut
  kn init ftlen(gitFwd) - 1
  kv table kn, gitFwd
  kn = max(kn - 1, 0)
  aend cosseg 1, 0.495, 1, 0.005, 0
  ay = a(kv) * aend
  ay += 0.12 * Mode(Hz(98), 0.004, 1)
  ay Room ay, 0.35, 0.3, 0.2, 0.1
  Out ay, p3
endin

; ------------------------------------------------------------------ reset (new)
; The tank pouring back to its scramble, about a second: water rushing in and rising, a stream of bubbles that swells
; and ebbs, the heals' notes running back down (B5 A5 G5 E5 D5) and a low D4 glass as it settles.
instr reset
  schedule "reset_pour", 0, 1.1
  its[] fillarray 0, 0.35, 0.6, 0.95, 1.0
  irs[] fillarray 30, 110, 140, 20, 0
  is = 0
  while is < 1 do
    is += -log(1 - random:i(0, 1)) / max(Interp(is, its, irs), 1)
    if is < 1 then
      irate = Interp(is, its, irs)
      if0 = 2 ^ random:i(log2(500), log2(1800))
      itau random 0.01, 0.025
      schedule "v_bubble", is, min(8 * itau + 0.01, 0.6), if0, random:i(0.3, 0.7), itau, 0.2 * random:i(0.4, 1) * min(1, irate / 110)
    endif
  od
  irun[] fillarray 83, 0.22, 81, 0.2, 79, 0.18, 76, 0.16, 74, 0.16
  ii = 0
  while ii < 10 do
    schedule "v_glass", 0.05 + 0.09 * ii / 2, 1.2, Hz(irun[ii]), 1.2, 0.6, 0.6, 0.4, 0.3, irun[ii + 1]
    ii += 2
  od
  schedule "v_glass", 0.78, 1.6, Hz(62), 1.6, 0.9, 0.6, 0.5, 0.3, 0.3
  schedule "reset_out", 0, p3
  turnoff
endin

instr reset_pour
  kc expseg 350, 0.8, 1100, 0.3, 700
  aenv linseg 0, 0.35, 1, 0.3, 1, 0.4, 0
  kfl poscil 2, 1.3, gisine
  afl poscil 0.3, 9 + kfl, gisine
  anz Noise
  ay Band anz, kc, 1.0
  anz2 Noise
  afz Band anz2, 4000, 0.6
  gaBus += (0.8 * ay + 0.08 * afz) * aenv * (1 + afl)
endin

instr reset_out
  ay = gaBus
  clear gaBus
  ay Hall ay, $SPILL_HALL, 0.25, $SPILL_NORM
  Out ay, p3
endin

; ------------------------------------------------------------------ undo, early (a variant for Jack's ear)
; The same stir running backwards, squeezed into 0.22 s so its body peaks a quarter of a second after the press
; instead of half a second, then the E5 glass rings on forward, softly, as if the stir had landed back in place.
gitFwdEarly Tab 0.22
gaRing init 0

instr undo_early
  schedule "undo_early_fwd", 0, 0.22
  schedule "v_glass", 0, 0.22, Hz(76), 0.22, 0.35, 0.6, 0.6, 0.4, 0.5
  schedule "v_glass", 0.015, 0.205, Hz(83), 0.205, 0.3, 0.5, 0.4, 0.3, 0.22
  schedule "v_bubble", 0.01, 0.1, 1000, 0.6, 0.012, 0.12
  schedule "v_bubble", 0.035, 0.1, 1300, 0.6, 0.012, 0.1
  schedule "v_bubble", 0.06, 0.1, 1150, 0.6, 0.012, 0.08
  schedule "undo_early_out", 0.22, p3
  schedule "undo_early_ring", 0.44, 0.6
  turnoff
endin
instr undo_early_fwd
  kc expseg 1200, 0.18, 500
  aenv expon 1, 20 * 0.06, exp(-20)
  anz Noise
  ay Band anz, kc, 0.9
  ay = gaBus + 0.5 * ay * aenv
  clear gaBus
  ay Hall ay, $SHORT_HALL, 0.35, $SHORT_NORM
  afade cosseg 1, 0.215, 1, 0.005, 0
  Record ay * afade, gitFwdEarly
endin
instr undo_early_ring
  ; no strike: it carries on from the reversed strike, which has just sounded
  ag Glass Hz(76), 0.6, 0.3, 0.5, 0, 0, 0.9
  aon cosseg 0, 0.004, 1
  gaRing += 0.18 * ag * aon
endin
instr undo_early_out
  kn init ftlen(gitFwdEarly) - 1
  kv table kn, gitFwdEarly
  kn = max(kn - 1, 0)
  aend cosseg 1, 0.215, 1, 0.005, 0
  ay = a(kv) * aend + gaRing
  clear gaRing
  ay += 0.12 * Mode(Hz(98), 0.004, 1)
  ay Room ay, 0.35, 0.3, 0.2, 0.1
  Out ay, p3
endin

schedule "$FX", 0, $DUR, $N
</CsInstruments>
<CsScore>
</CsScore>
</CsoundSynthesizer>
