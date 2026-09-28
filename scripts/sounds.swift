// Copyright © 2026 Jack Lusher. All rights reserved.
// scripts/sounds.sh's helper: finishes Csound's float renders into the shipped formats and measures what ffmpeg does
// not (onsets, loop seams, lengths as AVAudioFile decodes them). Every file is read through AVAudioFile, as the game
// reads it.
//   finish <in> <out.caf|out.wav> <gain dB> [trim]   gain, optionally trim the tail at -70 dB, write 16-bit CAF or
//                                                    float WAV (the encoder's input)
//   onset <file>                                     ms to the first sample within 40 dB of the peak
//   seam <file> [reference]                          the wrap from the last frame to the first, against the file's
//                                                    own steps; with a reference, the decoded file's error at its ends
//   clean <file>                                     exits 0 if the file is a whole loop (48 s) whose wrap is ordinary
//   wrap <in> <out.wav> <frames>                     the loop with its last frames before it and its first after it,
//                                                    for the encoder, so neither end of the AAC starts cold
//   gapless <file.m4a> <frames> <loop frames>        marks those frames as priming and remainder in the file's
//                                                    iTunSMPB, so AVAudioFile decodes exactly the loop, and zeroes
//                                                    the MP4 creation and modification times, so a rerun is
//                                                    byte-identical
import AVFoundation
import Foundation

let args = CommandLine.arguments
func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(1)
}

func read(_ path: String) -> (samples: [[Double]], rate: Double) {
    guard let file = try? AVAudioFile(forReading: URL(fileURLWithPath: path), commonFormat: .pcmFormatFloat32,
                                      interleaved: false),
          let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
          (try? file.read(into: buffer)) != nil, let data = buffer.floatChannelData
    else { fail("cannot read \(path)") }
    let n = Int(buffer.frameLength)
    let samples = (0..<Int(buffer.format.channelCount)).map { c in (0..<n).map { Double(data[c][$0]) } }
    return (samples, file.processingFormat.sampleRate)
}

func write(_ samples: [[Double]], rate: Double, to path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.removeItem(at: url)
    let n = samples[0].count, channels = samples.count
    let int16 = path.hasSuffix(".caf")
    let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: rate, AVNumberOfChannelsKey: channels,
        AVLinearPCMBitDepthKey: int16 ? 16 : 32, AVLinearPCMIsFloatKey: !int16, AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsNonInterleaved: false,
    ]
    guard let file = try? AVAudioFile(forWriting: url, settings: settings,
                                      commonFormat: int16 ? .pcmFormatInt16 : .pcmFormatFloat32, interleaved: false),
          let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(n))
    else { fail("cannot write \(path)") }
    buffer.frameLength = AVAudioFrameCount(n)
    for c in 0..<channels {
        if int16 {
            let out = buffer.int16ChannelData![c]
            for i in 0..<n { out[i] = Int16(max(-32768, min(32767, (samples[c][i] * 32767).rounded()))) }
        } else {
            let out = buffer.floatChannelData![c]
            for i in 0..<n { out[i] = Float(samples[c][i]) }
        }
    }
    do { try file.write(from: buffer) } catch { fail("cannot write \(path): \(error)") }
}

func peak(_ samples: [[Double]]) -> [Double] {
    (0..<samples[0].count).map { i in samples.map { abs($0[i]) }.max()! }
}

func percentile(_ values: [Double], _ p: Double) -> Double {
    let sorted = values.sorted()
    return sorted[min(sorted.count - 1, Int((p / 100 * Double(sorted.count - 1)).rounded()))]
}

func rmsDB(_ x: ArraySlice<Double>) -> Double {
    10 * log10(x.reduce(0) { $0 + $1 * $1 } / Double(x.count) + 1e-30)
}

/// A highpass biquad (RBJ), run over x.
func highpass(_ x: [Double], _ f0: Double, _ q: Double, rate: Double) -> [Double] {
    let w = 2 * Double.pi * f0 / rate, c = cos(w), al = sin(w) / (2 * q), a0 = 1 + al
    let b0 = (1 + c) / 2 / a0, b1 = -(1 + c) / a0, b2 = (1 + c) / 2 / a0, a1 = -2 * c / a0, a2 = (1 - al) / a0
    var y = [Double](repeating: 0, count: x.count)
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0
    for i in 0..<x.count {
        let v = b0 * x[i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x[i]; y2 = y1; y1 = v; y[i] = v
    }
    return y
}

switch args.count > 1 ? args[1] : "" {
case "finish":
    guard args.count >= 5, let db = Double(args[4]) else { fail("finish <in> <out> <gain dB> [trim]") }
    var (x, rate) = read(args[2])
    let g = pow(10, db / 20)
    x = x.map { $0.map { $0 * g } }
    if args.count > 5, args[5] == "trim" {
        // The sketch's trim: 20 ms past the last sample within 70 dB of the peak, then a 20 ms fade.
        let a = peak(x), top = a.max()!
        let last = a.lastIndex { $0 > top * pow(10, -70.0 / 20) } ?? 0
        let end = min(a.count, last + Int(0.02 * rate)), fade = min(end, Int(0.02 * rate))
        x = x.map { ch in
            (0..<end).map { i in
                let k = i - (end - fade)
                return k < 0 ? ch[i] : ch[i] * pow(cos(Double.pi / 2 * Double(k) / Double(fade - 1)), 2)
            }
        }
    }
    write(x, rate: rate, to: args[3])

case "onset":
    let a = peak(read(args[2]).samples), top = a.max()!
    let i = a.firstIndex { $0 >= top * pow(10, -40.0 / 20) } ?? 0
    print(String(format: "%.2f", 1000 * Double(i) / 48000))

case "seam", "clean":
    let (x, rate) = read(args[2])
    let n = x[0].count
    var clean = n == 2304000
    if args[1] == "seam" { print("frames \(n)") }
    for (c, v) in x.enumerated() {
        let steps: [Double] = (1..<n).map { i in abs(v[i] - v[i - 1]) }
        let curves: [Double] = (2..<n).map { i in
            let d: Double = v[i] - 2 * v[i - 1]
            return abs(d + v[i - 2])
        }
        let jump: Double = abs(v[0] - v[n - 1])
        let curve: Double = abs(v[1] - 2 * v[0] + v[n - 1])
        clean = clean && jump <= percentile(steps, 99) && curve <= percentile(curves, 99)
        let lsb = { (d: Double) in String(format: "%.0f", d * 32767) }
        if args[1] == "seam" {
            print("ch\(c) jump \(lsb(jump)) LSB; steps median \(lsb(percentile(steps, 50))), p99 \(lsb(percentile(steps, 99))), "
                  + "max \(lsb(steps.max()!)); curvature at the wrap \(lsb(curve)) against a p99 of \(lsb(percentile(curves, 99)))")
        }
    }
    let q = Int(0.25 * rate)
    let around = x.map { rmsDB($0[(n - q)...]) - rmsDB($0[..<q]) }
    // A click is a burst above 4 kHz: rank the 2 ms round the wrap among every 2 ms of the file.
    let half = n / 2, w = Int(0.002 * rate)
    var energy = [Double](repeating: 0, count: n)
    for v in x {
        let rolled = Array(v[half...] + v[..<half])
        let h = highpass(highpass(rolled, 4000, 0.54, rate: rate), 4000, 1.31, rate: rate)
        for i in 0..<n { energy[i] += h[i] * h[i] }
    }
    var windows: [Double] = []
    var i = 0
    while i + w <= n { windows.append(energy[i..<(i + w)].reduce(0, +)); i += w }
    let wrap = energy[(half - w / 2)..<(half + w / 2)].reduce(0, +)
    let rank = Double(windows.filter { $0 < wrap }.count) / Double(windows.count)
    if args[1] == "clean" {
        // The decoded loop's full length, and a wrap no more extreme than 1 in 100 of its own steps and curvatures,
        // nor louder above 4 kHz than 1 in 10 of its 2 ms windows.
        exit(clean && rank <= 0.9 ? 0 : 1)
    }
    print(String(format: "rms last 250 ms against first 250 ms: %+.2f dB", around.reduce(0, +) / Double(around.count)))
    print(String(format: "energy above 4 kHz at the wrap is above %.0f%% of the file's 2 ms windows", 100 * rank))
    if args.count > 3 {
        let (r, _) = read(args[3])
        guard r[0].count == n else { print("reference has \(r[0].count) frames: lengths differ"); break }
        let e = q / 5
        for (c, v) in x.enumerated() {
            let err = (0..<n).map { v[$0] - r[c][$0] }
            let s = rmsDB(r[c][...])
            print(String(format: "ch%d error against the source: whole %.1f dB, first 50 ms %.1f dB, last 50 ms %.1f dB "
                         + "(re the source's rms)", c, rmsDB(err[...]) - s, rmsDB(err[..<e]) - s, rmsDB(err[(n - e)...]) - s))
        }
    }

case "wrap":
    guard args.count >= 5, let pad = Int(args[4]) else { fail("wrap <in> <out.wav> <frames>") }
    let (x, rate) = read(args[2])
    write(x.map { Array($0.suffix(pad) + $0 + $0.prefix(pad)) }, rate: rate, to: args[3])

case "gapless":
    guard args.count >= 5, let pad = Int(args[3]), let frames = Int(args[4]),
          var data = FileManager.default.contents(atPath: args[2]) else { fail("gapless <file.m4a> <frames> <loop frames>") }
    // iTunSMPB: " 00000000 PPPPPPPP RRRRRRRR VVVVVVVVVVVVVVVV ..." in hex: priming, remainder, valid frames.
    guard let tag = data.range(of: Data("iTunSMPB".utf8)),
          let at = data.range(of: Data(" 00000000 ".utf8), in: tag.upperBound..<data.count)?.lowerBound
    else { fail("no iTunSMPB in \(args[2])") }
    let old = String(decoding: data[at..<(at + 44)], as: UTF8.self).split(separator: " ")
    guard old.count == 4, let prime = Int(old[1], radix: 16), let remain = Int(old[2], radix: 16),
          let valid = Int(old[3], radix: 16), valid == frames + 2 * pad
    else { fail("unexpected iTunSMPB in \(args[2])") }
    let hex = { (v: Int, w: Int) in String(repeating: "0", count: w - String(v, radix: 16).count) + String(v, radix: 16).uppercased() }
    let new = " 00000000 \(hex(prime + pad, 8)) \(hex(remain + pad, 8)) \(hex(frames, 16))"
    data.replaceSubrange(at..<(at + 44), with: Data(new.utf8))
    // Walks the box tree through moov, trak and mdia and zeroes the times in mvhd, tkhd and mdhd.
    func walk(_ start: Int, _ end: Int) {
        var at = start
        while at + 8 <= end {
            let size = Int(data[at..<(at + 4)].reduce(0) { $0 << 8 | UInt32($1) })
            let type = String(decoding: data[(at + 4)..<(at + 8)], as: UTF8.self)
            guard size >= 8, at + size <= end else { return }
            switch type {
            case "moov", "trak", "mdia": walk(at + 8, at + size)
            case "mvhd", "tkhd", "mdhd":
                let wide = data[at + 8] == 1
                for k in (at + 12)..<(at + 12 + (wide ? 16 : 8)) { data[k] = 0 }
            default: break
            }
            at += size
        }
    }
    walk(0, data.count)
    FileManager.default.createFile(atPath: args[2], contents: data)

default:
    fail("usage: sounds.swift finish|onset|seam|wrap|gapless ...")
}
