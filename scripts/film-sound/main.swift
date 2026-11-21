// Copyright © 2026 Jack Lusher. All rights reserved.
// Usage: build/film-sound/record <device name> <out.caf>   (scripts/film.sh builds it)
// Records an audio input device (scripts/film.sh: BlackHole, the Mac's output during a take) until SIGINT, then prints
// when its first sample was captured, in seconds of CLOCK_UPTIME_RAW, the clock film.sh times the video's start on.
// Exits 1, saying how much, if the device's sample clock skipped: a lost buffer is a click in the take.
// ffmpeg's avfoundation input recorded these until 2026-11-21 and lost about 85 ms of sound a second (#268).
import AVFoundation
import CoreAudio
import Darwin

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("record: \(message)\n".utf8))
    exit(1)
}

func device(named name: String) -> AudioDeviceID? {
    let system = AudioObjectID(kAudioObjectSystemObject)
    var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                             mScope: kAudioObjectPropertyScopeGlobal,
                                             mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return nil }
    var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
    guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return nil }
    for id in ids {
        var nameAddress = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName,
                                                     mScope: kAudioObjectPropertyScopeGlobal,
                                                     mElement: kAudioObjectPropertyElementMain)
        var cfName: Unmanaged<CFString>?
        var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &nameAddress, 0, nil, &nameSize, &cfName) == noErr,
              let found = cfName?.takeRetainedValue() else { continue }
        if found as String == name { return id }
    }
    return nil
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else { fail("usage: record <device name> <out.caf>") }
guard var id = device(named: arguments[1]) else { fail("no audio device named \(arguments[1])") }

// The engine's input is the named device, not the Mac's default input, which the take leaves alone.
let engine = AVAudioEngine()
let input = engine.inputNode
guard let unit = input.audioUnit,
      AudioUnitSetProperty(unit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &id,
                           UInt32(MemoryLayout<AudioDeviceID>.size)) == noErr
else { fail("can't record from \(arguments[1])") }
let format = input.outputFormat(forBus: 0)
guard format.sampleRate > 0, format.channelCount > 0 else { fail("\(arguments[1]) gives no input format") }

var file: AVAudioFile?
do {
    file = try AVAudioFile(forWriting: URL(fileURLWithPath: arguments[2]), settings: format.settings,
                           commonFormat: format.commonFormat, interleaved: format.isInterleaved)
} catch {
    fail("can't write \(arguments[2]): \(error)")
}

// The tap's thread writes these; the main queue reads them only after the engine has stopped.
var first: UInt64?
var next: AVAudioFramePosition = 0
var lost: AVAudioFramePosition = 0
var gaps = 0
var writeError: Error?
input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, when in
    if first == nil {
        first = when.hostTime
    } else if when.isSampleTimeValid, when.sampleTime != next {
        gaps += 1
        lost += abs(when.sampleTime - next)
    }
    next = when.sampleTime + AVAudioFramePosition(buffer.frameLength)
    do { try file?.write(from: buffer) } catch { writeError = error }
}
do { try engine.start() } catch { fail("can't start recording: \(error)") }

signal(SIGINT, SIG_IGN)
let stop = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
stop.setEventHandler {
    input.removeTap(onBus: 0)
    engine.stop()
    file = nil  // closes it, its header whole
    if let writeError { fail("writing \(arguments[2]): \(writeError)") }
    guard let first else { fail("\(arguments[1]) gave no sound") }
    if gaps > 0 {
        fail(String(format: "lost %.3f s of sound in %d gaps", Double(lost) / format.sampleRate, gaps))
    }
    var base = mach_timebase_info_data_t()
    mach_timebase_info(&base)
    print(String(format: "%.6f", Double(first) * Double(base.numer) / Double(base.denom) / 1e9))
    exit(0)
}
stop.resume()
dispatchMain()
