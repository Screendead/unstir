; Copyright © 2026 Jack Lusher. All rights reserved.
; The glass set's beds, one per run: scripts/sounds.sh passes the bed (BED: plughole, whirlpool, vortex, maelstrom or menu),
; the seed (SEED), the output (OUT) and a second output for the hum alone at its level in the bed (STEM), for the
; phone check. Stereo, 48 kHz, 32-bit float, 48 s, seamless.
;
; Everything that repeats has a whole number of cycles in the loop, the noise is read from one loop-long table, and
; every event is played in each of three periods with the same parameters and the same seed. The first period
; measures the water's level, the second lets the room fill, and the third is written out. Its last 3 s crossfade
; into the second period's, so the last frame leads into the first exactly, whatever reverbsc's modulation did.
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

; Each bed's hum (pad and tube) against the rest of it: a little under the rest in the three levels' beds, so the
; glass sits on it, and level with the rest in the menu's, where it is most of what there is.
#define PLUG_HUM #0.53#
#define WHIRL_HUM #0.63#
#define VORT_HUM #0.65#
#define MAEL_HUM #0.67#
#define MENU_HUM #0.79#


giL = 48
giN = round(giL * sr)
giX = 3
giNoise ftgen 0, 0, -giN, -21, 6, 3.83

gaDroneL init 0
gaDroneR init 0
gaHumL init 0
gaHumR init 0
gaTube init 0
gaWaterL init 0
gaWaterR init 0
gaSendL init 0
gaSendR init 0
gaYL init 0
gaYR init 0
gaYDL init 0
gaYDR init 0
gaStemL init 0
gaStemR init 0

; Set by each bed's instrument.
giDroneLP init 1600
giHumCentre init 650
giHumDepth init 0.5
giHumRate init 2
giHumQ init 2
giFb init 0.86
giCo init 9000
giNorm init 1

; A frequency with a whole number of cycles in the loop.
opcode Qf, i, i
  if0 xin
  xout round(if0 * giL) / giL
endop

; Reseeds the global generator for one voice, so its three periods draw the same phases and noise.
opcode Reseed, 0, i
  iseed xin
  seed iseed
  ii = 0
  while ii < 8 do
    idummy random 0, 1
    ii += 1
  od
endop

opcode NewSeed, i, 0
  xout floor(random:i(1, 2 ^ 31 - 1))
endop

opcode Pick, i, i[]
  iarr[] xin
  xout iarr[min(floor(random:i(0, lenarray(iarr))), lenarray(iarr) - 1)]
endop

; icount irregular times over the loop, no two closer than igap, the wrap included.
opcode Events, i[], ii
  icount, igap xin
  its[] init icount
  iok = 0
  while iok == 0 do
    ii = 0
    while ii < icount do
      its[ii] = random:i(0, giL)
      ii += 1
    od
    its sorta its
    iok = 1
    ii = 0
    while ii < icount do
      inext = ii == icount - 1 ? its[0] + giL : its[(ii + 1) % icount]
      if inext - its[ii] < igap then
        iok = 0
      endif
      ii += 1
    od
  od
  xout its
endop

; Schedules an instrument at s in each of the three periods.
opcode Thrice, 0, Siiiiiiiii
  Sins, is, idur, i4, i5, i6, i7, i8, i9, i10 xin
  ik = 0
  while ik < 3 do
    schedule Sins, is + ik * giL, idur, i4, i5, i6, i7, i8, i9, i10
    ik += 1
  od
endop

; ------------------------------------------------------------------ voices
; The drone (the sketch's): p4 note, p5 level, p6 side (0 left, 1 right). A pair a few cycles per loop apart, an
; octave overtone, and a swell of whole cycles per loop.
instr drone
  Reseed p7
  ifq Qf Hz(p4)
  idet = floor(random:i(3, 8)) / giL * (p6 == 0 ? -1 : 1)
  irates[] fillarray 1, 2, 3, 5
  ilfo Pick irates
  alfo poscil 0.35, ilfo / giL, gisine, random:i(0, 1)
  av poscil 1, ifq, gisine, random:i(0, 1)
  av += poscil(0.6, ifq + idet, gisine, random:i(0, 1))
  av += poscil(0.18, 2 * ifq, gisine, random:i(0, 1))
  ay = p5 * (1 + alfo) * av
  gaDroneL += ay * (1 - p6)
  gaDroneR += ay * p6
endin

; The hum (new, from the neon sketch): p4 note, p5 level, p6 side. A pair of band-limited saws a few cycles per loop
; apart, swelling slowly; the slow filter is applied to all of them together in the mix.
instr hum
  Reseed p7
  ifq Qf Hz(p4)
  idet = floor(random:i(2, 6)) / giL * (p6 == 0 ? -1 : 1)
  irates[] fillarray 1, 2, 3
  ilfo Pick irates
  alfo poscil 0.3, ilfo / giL, gisine, random:i(0, 1)
  ; vco2's saw is 2 / (pi k) per partial; the sketch's was 1 / k
  a1 vco2 $M_PI / 2, ifq, 0, 0, random:i(0, 1)
  a2 vco2 $M_PI / 2, ifq + idet, 0, 0, random:i(0, 1)
  ay = p5 * (1 + alfo) * (a1 + a2)
  gaHumL += ay * (1 - p6)
  gaHumR += ay * p6
endin

; A tube's buzz on A2 (110 Hz, near a UK tube's 100 and in the key): harmonics shaped round 1.5 kHz so it buzzes in the
; mids, flickering slowly (a random mix of whole cycles per loop below 4 Hz). p4 level.
instr tube
  Reseed p5
  iargs[] init 180
  ik = 1
  while ik <= 60 do
    iargs[3 * (ik - 1)] = ik
    iargs[3 * (ik - 1) + 1] = exp(-((log2(110 * ik / 1500)) ^ 2) / 1.2) / sqrt(ik)
    iargs[3 * (ik - 1) + 2] = random:i(0, 360)
    ik += 1
  od
  ibuzz ftgen 0, 0, 65536, -9, iargs
  ifl[] init 3 * 191
  ik = 1
  while ik <= 191 do
    ifl[3 * (ik - 1)] = ik
    ifl[3 * (ik - 1) + 1] = sqrt(gauss:i(3.83) ^ 2 + gauss:i(3.83) ^ 2)
    ifl[3 * (ik - 1) + 2] = random:i(0, 360)
    ik += 1
  od
  iflick ftgen 0, 0, 262144, -9, ifl
  afl oscili 0.5 / TabPeak(iflick), 1 / giL, iflick
  abz oscili 1, 110, ibuzz
  gaTube += p4 * abz * (1 + afl)
endin

; Water (the sketch's band of noise; p4 kind: 0 breathing, 1 circling, 2 turbulent, 3 circling wider and faster), p5 level, p6 centre, p7 width
; (the sketch's Gaussian in octaves), p8 fizz. Each side reads the loop's noise half a loop apart. The first period
; measures the level; from the second on it is scaled to unit rms.
instr water
  kn init 0
  kv1 table kn, giNoise
  kv2 table (kn + giN / 2) % giN, giNoise
  kn = (kn + 1) % giN
  kt timeinsts
  if p4 == 2 then
    ; the sketch's 20 s excerpt turned 2, 7 and 3 times in 20 s: here 5, 17 and 7 times in 48
    kc = p6 * 2 ^ (1.1 * sin(2 * $M_PI * 5 * kt / giL) + 0.4 * sin(2 * $M_PI * 17 * kt / giL))
    kg = 0.7 + 0.3 * sin(2 * $M_PI * 7 * kt / giL)
  elseif p4 == 3 then
    kc = p6 * 2 ^ (0.8 * sin(2 * $M_PI * 3 * kt / giL))
    kg = 0.7 + 0.3 * sin(2 * $M_PI * 3 * kt / giL)
  elseif p4 == 1 then
    kc = p6 * 2 ^ (0.7 * sin(2 * $M_PI * 2 * kt / giL))
    kg = 0.75 + 0.25 * sin(2 * $M_PI * 3 * kt / giL)
  else
    kc = p6
    kg = 0.6 + 0.4 * sin(2 * $M_PI * 2 * kt / giL)
  endif
  a1 Band a(kv1), kc, p7
  a2 Band a(kv2), kc, p7
  az1 Band a(kv1), 6000, 0.3
  az2 Band a(kv2), 6000, 0.3
  aL = kg * a1 + p8 * az1
  aR = kg * a2 + p8 * az2
  if p4 >= 1 then
    ; it circles between the speakers
    kturn = sin(2 * $M_PI * (p4 == 2 ? 7 : (p4 == 3 ? 3 : 2)) * kt / giL)
    aL *= (p4 >= 2 ? 0.75 : 0.85) + (p4 >= 2 ? 0.25 : 0.15) * kturn
    aR *= (p4 >= 2 ? 0.75 : 0.85) - (p4 >= 2 ? 0.25 : 0.15) * kturn
  endif
  ksum init 0
  kgain init 1
  if kt < giL then
    ksum += (k(aL) ^ 2 + k(aR) ^ 2) / 2
  else
    kgain = 1 / sqrt(ksum / giN)
  endif
  gaWaterL += p5 * kgain * aL
  gaWaterR += p5 * kgain * aR
endin

; p4 frequency, p5 pan, p6 seed, p7 level
instr swell
  Reseed p6
  as Swell p4, p3
  aL, aR Pan p7 * as, p5
  gaSendL += aL
  gaSendR += aR
endin

; p4 frequency, p5 level, p6 decay, p7 pan, p8 seed
instr ping
  Reseed p8
  ag Glass p4, 5.0, p6, 0.6, 0.25, 0.25, 0.9
  aL, aR Pan p5 * ag, p7
  gaSendL += aL
  gaSendR += aR
endin

; A drip (new: its bubble is struck by a drop, a little plink a sixth above it before it rises). p4 frequency, p5
; rise, p6 decay, p7 level, p8 pan, p9 seed
instr drop
  Reseed p9
  ab Bubble p4, p5, p6, p7, p3
  aclv expon 1, 20 * 0.0004, exp(-20)
  anz Noise
  aplink mode anz * aclv, p4 * 1.68, 12
  aL, aR Pan ab + 0.1 * p7 * aplink, p8
  gaSendL += aL
  gaSendR += aR
endin

; ------------------------------------------------------------------ the beds' scores
; Drone notes and levels, hum notes and levels, swells, pings and drips, as numbers each bed sets.
opcode Drone, 0, i[]i[]
  inotes[], iamps[] xin
  ii = 0
  while ii < lenarray(inotes) do
    ic = 0
    while ic < 2 do
      schedule "drone", 0, 3 * giL, inotes[ii], iamps[ii], ic, NewSeed()
      ic += 1
    od
    ii += 1
  od
endop

opcode Hum, 0, i[]i[]ii
  inotes[], iamps[], itube, igain xin
  ii = 0
  while ii < lenarray(inotes) do
    ic = 0
    while ic < 2 do
      schedule "hum", 0, 3 * giL, inotes[ii], igain * iamps[ii], ic, NewSeed()
      ic += 1
    od
    ii += 1
  od
  schedule "tube", 0, 3 * giL, igain * itube, NewSeed()
endop

opcode Swells, 0, ii[]iii
  icount, ipool[], ilo, ihi, iamp xin
  its[] Events icount, 3
  ii = 0
  while ii < icount do
    idur = random:i(ilo, ihi)
    Thrice "swell", its[ii], idur, Qf(Hz(Pick(ipool))), random:i(-0.6, 0.6), NewSeed(), iamp, 0, 0, 0
    ii += 1
  od
endop

; p4 of Pings, optional: a scale on every ping's decay.
opcode Pings, 0, ii[]ip
  icount, inotes[], iamp, iring xin
  its[] Events icount, 2.2
  ii = 0
  while ii < icount do
    ifq = Hz(Pick(inotes))
    iamp1 = iamp * random:i(0.25, 0.45)
    Thrice "ping", its[ii], 5, ifq, iamp1, iring * random:i(1.2, 2.0), random:i(-0.8, 0.8), NewSeed(), 0, 0
    ii += 1
  od
endop

opcode Drips, 0, iii
  icount, imul, iamp xin
  its[] Events icount, 1.5
  ii = 0
  while ii < icount do
    iu random 0, 1
    ik = iu < 0.5 ? 1 : (iu < 0.8 ? 2 : 3)
    if0 = 2 ^ random:i(log2(700), log2(1900)) * imul
    ipan random -0.9, 0.9
    ij = 0
    iat = its[ii]
    while ij < ik do
      itau random 0.012, 0.03
      Thrice "drop", iat, min(8 * itau + 0.01, 0.6), if0 * random:i(0.92, 1.08), random:i(0.3, 0.8), itau, iamp * 0.16 * random:i(0.5, 1) * 0.8 ^ ij, ipan, NewSeed(), 0
      iat += random:i(0.35, 0.7)
      ij += 1
    od
    ii += 1
  od
endop

; Hall settings per bed (feedback, cutoff) and the scale that gives each side's wet unit energy (measured on an impulse
; into one side), so the wet levels mean what the sketch's did.

; plughole: the sketch's loop, now over the hum. D3 A3 D4 E4 A4 in the drone (D3 at half, as the sketch's room left it
; and the hum now holds it), the heals' scale in the pings.
instr plughole
  giDroneLP = 1600
  giHumCentre = 650
  giHumDepth = 0.5
  giHumQ = 2.2
  giHumRate = 2
  giFb = 0.86
  giCo = 9000
  giNorm = 1.653
  idronen[] fillarray 50, 57, 62, 64, 69
  idronea[] fillarray 0.15, 0.25, 0.30, 0.10, 0.14
  Drone idronen, idronea
  ihumn[] fillarray 38, 45, 50
  ihuma[] fillarray 0.30, 0.26, 0.22
  Hum ihumn, ihuma, 0.03, $PLUG_HUM
  iswells[] fillarray 62, 64, 69, 71, 74, 76
  Swells 7, iswells, 5, 8, 0.28
  ipings[] fillarray 74, 76, 79, 81, 83, 86, 88, 91
  Pings 9, ipings, 1
  Drips 10, 1, 1
  schedule "water", 0, 3 * giL, 0, 0.05, 480, 0.8, 0.06
  turnoff
endin

; whirlpool (new): between the two. The drone's E becomes G (D3 A3 D4 G4 A4, suspended), the pings take C for B
; (D E G A C), the water circles the speakers twice a loop, a 3.3 s room, the hum a little darker.
instr whirlpool
  giDroneLP = 1250
  giHumCentre = 580
  giHumDepth = 0.55
  giHumQ = 2.2
  giHumRate = 2
  giFb = 0.88
  giCo = 7500
  giNorm = 1.653
  idronen[] fillarray 50, 57, 62, 67, 69
  idronea[] fillarray 0.32, 0.28, 0.28, 0.12, 0.12
  Drone idronen, idronea
  ihumn[] fillarray 38, 45, 50
  ihuma[] fillarray 0.30, 0.27, 0.22
  Hum ihumn, ihuma, 0.035, $WHIRL_HUM
  iswells[] fillarray 62, 67, 69, 72, 74
  Swells 7, iswells, 5.5, 9, 0.28
  ipings[] fillarray 74, 76, 79, 81, 84, 86, 88
  Pings 8, ipings, 1
  Drips 8, 0.75, 1
  schedule "water", 0, 3 * giL, 1, 0.09, 430, 0.6, 0.04
  turnoff
endin

; vortex (new): wide and cold, the swirl's tier. Open fifths and a ninth in the drone (D3 A3 E4 A4), no third and no
; seventh, so it sits between whirlpool's suspension and maelstrom's minor; high, sparse pings on D E A B that ring
; longer, few drips, and a lower band of water circling the speakers three times a loop, the swirl turning; a 3.6 s room.
instr vortex
  giDroneLP = 1100
  giHumCentre = 540
  giHumDepth = 0.55
  giHumQ = 2.4
  giHumRate = 3
  giFb = 0.89
  giCo = 7000
  giNorm = 1.66
  idronen[] fillarray 50, 57, 64, 69
  idronea[] fillarray 0.34, 0.30, 0.16, 0.12
  Drone idronen, idronea
  ihumn[] fillarray 38, 45, 50
  ihuma[] fillarray 0.31, 0.27, 0.21
  Hum ihumn, ihuma, 0.035, $VORT_HUM
  iswells[] fillarray 57, 62, 64, 69, 76
  Swells 8, iswells, 6.5, 10, 0.28
  ipings[] fillarray 81, 86, 88, 93, 95
  Pings 7, ipings, 0.9, 1.6
  Drips 6, 0.6, 1
  schedule "water", 0, 3 * giL, 3, 0.11, 400, 0.5, 0.03
  turnoff
endin

; maelstrom: the sketch's excerpt as a whole loop, at its density. D Dorian (a Dm7 drone, D3 F3 A3 C4 D4), a turbulent
; band of noise that swirls up and down and circles the speakers, lower pings and bubbles, a 4 s room, the hum darkest.
instr maelstrom
  giDroneLP = 900
  giHumCentre = 480
  giHumDepth = 0.6
  giHumQ = 2.6
  giHumRate = 5
  giFb = 0.9
  giCo = 6000
  giNorm = 1.68
  idronen[] fillarray 50, 53, 57, 60, 62
  idronea[] fillarray 0.40, 0.30, 0.35, 0.20, 0.22
  Drone idronen, idronea
  ihumn[] fillarray 38, 45, 50
  ihuma[] fillarray 0.32, 0.28, 0.20
  Hum ihumn, ihuma, 0.04, $MAEL_HUM
  iswells[] fillarray 53, 57, 60, 62, 65, 67
  Swells 10, iswells, 7, 11.2, 0.28
  ipings[] fillarray 62, 65, 67, 69, 72, 74
  Pings 12, ipings, 1
  Drips 12, 0.5, 1
  schedule "water", 0, 3 * giL, 2, 0.16, 380, 0.35, 0
  turnoff
endin

; menu (new): the calmest. Only D3 A3 D4 in the drone, three long swells, five pings on the open notes (D5 A5 D6 E6),
; four drips, a faint breath of water, the hum's filter turning once a loop.
instr menu
  giDroneLP = 1200
  giHumCentre = 560
  giHumDepth = 0.35
  giHumQ = 1.6
  giHumRate = 1
  giFb = 0.88
  giCo = 7500
  giNorm = 1.653
  idronen[] fillarray 50, 57, 62
  idronea[] fillarray 0.26, 0.22, 0.20
  Drone idronen, idronea
  ihumn[] fillarray 38, 45, 50
  ihuma[] fillarray 0.28, 0.24, 0.20
  Hum ihumn, ihuma, 0.02, $MENU_HUM
  iswells[] fillarray 62, 69, 74
  Swells 3, iswells, 7, 10, 0.24
  ipings[] fillarray 74, 81, 86, 88
  Pings 5, ipings, 0.8
  Drips 4, 1, 0.8
  schedule "water", 0, 3 * giL, 0, 0.035, 480, 0.8, 0.04
  turnoff
endin

instr mix
  ; the drone under its lowpass, the hum under its slow filter
  aDL butterlp gaDroneL, giDroneLP
  aDR butterlp gaDroneR, giDroneLP
  kt timeinsts
  kfc = giHumCentre * 2 ^ (giHumDepth * sin(2 * $M_PI * giHumRate * kt / giL + 1) + 0.4 * giHumDepth * sin(2 * $M_PI * 5 * kt / giL))
  aHL zdf_2pole gaHumL, kfc, giHumQ, 0
  aHR zdf_2pole gaHumR, kfc, giHumQ, 0
  aHL += gaTube
  aHR += gaTube
  aOutL = aDL + aHL + gaWaterL
  aOutR = aDR + aHR + gaWaterR
  ; The sketch sent the drone to the room too, but a steady tone comes out of a room only louder or softer by
  ; wherever it lands among the room's resonances (up to 6 dB here), so the drone and the hum stay dry.
  awL, awR reverbsc 0.9 * gaSendL + 0.25 * gaWaterL, 0.9 * gaSendR + 0.25 * gaWaterR, giFb, giCo, sr, 0.5
  ayL = aOutL + 0.5 * gaSendL + giNorm * awL
  ayR = aOutR + 0.5 * gaSendR + giNorm * awR
  ; the mix a loop ago, for the writer's crossfade
  adL delayr giL
  delayw ayL
  adR delayr giL
  delayw ayR
  gaYL = ayL
  gaYR = ayR
  gaYDL = adL
  gaYDR = adR
  gaStemL = aHL
  gaStemR = aHR
  clear gaDroneL, gaDroneR, gaHumL, gaHumR, gaTube, gaWaterL, gaWaterR, gaSendL, gaSendR
endin

; The third period, its last 3 s crossfading into the second's, so it wraps onto its own first frame.
instr writer
  event_i "e", 0, p3
  aw cosseg 0, giL - giX, 0, giX, 1
  fout "$OUT", 16, gaYL + aw * (gaYDL - gaYL), gaYR + aw * (gaYDR - gaYR)
  fout "$STEM", 16, gaStemL, gaStemR
endin

schedule "$BED", 0, 0.01
schedule "mix", 0, 3 * giL
schedule "writer", 2 * giL, giL
</CsInstruments>
<CsScore>
</CsScore>
</CsoundSynthesizer>
