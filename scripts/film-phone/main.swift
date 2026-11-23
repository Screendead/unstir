// Copyright © 2026 Jack Lusher. All rights reserved.
// Usage: build/film-phone/record [--sound] [--from-black] <out.mov> [device name]   (scripts/film.sh builds it)
// Records the screen of an iPhone plugged into the Mac, as QuickTime's movie recording does, until SIGINT: every frame
// the phone sends, at the time the Mac's capture stamps on it, as H.264. The phone sends 60 frames a second and,
// while its picture moves, leaves one out now and then (one in 14 to 19 on a 13 Pro Max, 2026-11-23): a 33 ms step
// that a film cut at 30 frames a second does not show.
// --sound records the phone's sound with it, which takes the phone's output for as long as the recording runs.
// --from-black keeps the phone's home screen, which is the owner's own, out of the file: nothing is written until
// SIGUSR1, sent once the app is launched, and then not before a frame is black, as the app's launch is.
// Says "watching" on stderr once frames arrive. On SIGINT prints when its first written frame was captured, in seconds
// of CLOCK_UPTIME_RAW, the clock scripts/film.sh times a take on, and a line of the take's frame times on stderr.
// Exits 1 if the Mac dropped a frame the phone sent: the take would hitch where the phone did not.
// The process that runs it needs the Mac's Camera permission (and Microphone with --sound); the phone must be
// unlocked and have trusted this Mac.
import AVFoundation
import CoreMediaIO
import Darwin

func say(_ message: String) { FileHandle.standardError.write(Data("record: \(message)\n".utf8)) }
func fail(_ message: String) -> Never {
    say(message)
    exit(1)
}

var arguments = Array(CommandLine.arguments.dropFirst())
var sound = false, fromBlack = false
while let flag = arguments.first, flag.hasPrefix("--") {
    switch flag {
    case "--sound": sound = true
    case "--from-black": fromBlack = true
    default: fail("unknown option \(flag)")
    }
    arguments.removeFirst()
}
guard (1...2).contains(arguments.count) else { fail("usage: record [--sound] [--from-black] <out.mov> [device name]") }
let out = URL(fileURLWithPath: arguments[0])
let wanted = arguments.count == 2 ? arguments[1] : nil

func allowed(_ media: AVMediaType, _ name: String) {
    switch AVCaptureDevice.authorizationStatus(for: media) {
    case .authorized: return
    case .notDetermined:
        let asked = DispatchSemaphore(value: 0)
        var granted = false
        AVCaptureDevice.requestAccess(for: media) { granted = $0; asked.signal() }
        asked.wait()
        if !granted { fail("the \(name) permission was refused") }
    default: fail("the app running this has no \(name) permission (System Settings, Privacy & Security, \(name))")
    }
}
allowed(.video, "Camera")
if sound { allowed(.audio, "Microphone") }

// A plugged-in iPhone's screen is a capture device only for a process that asks for screen capture devices.
var allow: UInt32 = 1
var address = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
                                        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                                        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &allow)

func phone() -> AVCaptureDevice? {
    AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .muxed, position: .unspecified).devices
        .first { device in wanted.map { device.localizedName.contains($0) } ?? true }
}
// The device appears a moment after the property is set.
var found: AVCaptureDevice?
let deadline = Date().addingTimeInterval(15)
while found == nil, Date() < deadline {
    found = phone()
    if found == nil { RunLoop.current.run(until: Date().addingTimeInterval(0.2)) }
}
guard let device = found else {
    fail("no iPhone\(wanted.map { " named \($0)" } ?? "") to record: plug it in, unlock it and trust this Mac")
}

/// Everything here runs on the capture's one queue.
final class Recorder: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    /// Frames the encoder may fall behind by before the take fails: it catches up between them, and a frame is never
    /// dropped to keep time.
    static let room = 180
    let writer: AVAssetWriter
    let audio: AVAssetWriterInput?
    var video: AVAssetWriterInput?
    var waiting: [CMSampleBuffer] = []
    var times: [Double] = []
    var size = CMVideoDimensions(width: 0, height: 0)
    /// Frames the capture gave up on before handing them over.
    var late = 0
    var problem: String?
    var seen = false
    var armed = false
    private var writes: Bool

    init(_ url: URL, sound: Bool, fromBlack: Bool) throws {
        writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        writes = !fromBlack
        if sound {
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 48000, AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 256_000,
            ])
            input.expectsMediaDataInRealTime = true
            writer.add(input)
            audio = input
        } else {
            audio = nil
        }
    }

    /// Whether a frame is the app's black: its mean luma, from a grid of its pixels, and its four corners' too, as the
    /// launch grows the app's black out of the home screen as a rounded card, and the wallpaper shows at its corners
    /// until it fills the screen. Black is 16 in the video range the phone's frames come in.
    private func dark(_ buffer: CMSampleBuffer) -> Bool {
        guard let pixels = CMSampleBufferGetImageBuffer(buffer) else { return false }
        CVPixelBufferLockBaseAddress(pixels, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixels, .readOnly) }
        let planar = CVPixelBufferIsPlanar(pixels)
        guard let base = planar ? CVPixelBufferGetBaseAddressOfPlane(pixels, 0) : CVPixelBufferGetBaseAddress(pixels) else { return false }
        let width = planar ? CVPixelBufferGetWidthOfPlane(pixels, 0) : CVPixelBufferGetWidth(pixels)
        let height = planar ? CVPixelBufferGetHeightOfPlane(pixels, 0) : CVPixelBufferGetHeight(pixels)
        let row = planar ? CVPixelBufferGetBytesPerRowOfPlane(pixels, 0) : CVPixelBufferGetBytesPerRow(pixels)
        // A packed frame is BGRA: its green stands for its luma.
        let (step, offset) = planar ? (1, 0) : (4, 1)
        var sum = 0, n = 0, corners = 0, m = 0
        for y in stride(from: 0, to: height, by: 16) {
            let line = base.advanced(by: y * row).assumingMemoryBound(to: UInt8.self)
            for x in stride(from: 0, to: width, by: 16) {
                sum += Int(line[x * step + offset])
                n += 1
            }
        }
        for y in Array(stride(from: 2, to: 26, by: 4)) + Array(stride(from: height - 26, to: height - 2, by: 4)) {
            let line = base.advanced(by: y * row).assumingMemoryBound(to: UInt8.self)
            for x in Array(stride(from: 2, to: 26, by: 4)) + Array(stride(from: width - 26, to: width - 2, by: 4)) {
                corners += Int(line[x * step + offset])
                m += 1
            }
        }
        return n > 0 && sum < 28 * n && corners < 22 * m
    }

    private func drain() {
        guard let video else { return }
        while let next = waiting.first, video.isReadyForMoreMediaData {
            guard video.append(next) else {
                problem = "writing failed: \(String(describing: writer.error))"
                return
            }
            times.append(CMSampleBufferGetPresentationTimeStamp(next).seconds)
            waiting.removeFirst()
        }
    }

    /// Writes what the encoder still owes, once the capture has stopped.
    func finish() {
        let limit = Date().addingTimeInterval(20)
        while problem == nil, !waiting.isEmpty, Date() < limit {
            drain()
            if !waiting.isEmpty { usleep(2000) }
        }
        if problem == nil, !waiting.isEmpty { problem = "the encoder never took the last \(waiting.count) frames" }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput buffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard problem == nil else { return }
        guard output is AVCaptureVideoDataOutput else {
            if video != nil, let audio, audio.isReadyForMoreMediaData { audio.append(buffer) }
            return
        }
        if !seen {
            seen = true
            say("watching")
        }
        if !writes {
            guard armed, dark(buffer) else { return }
            writes = true
        }
        if video == nil {
            guard let format = CMSampleBufferGetFormatDescription(buffer) else { return }
            size = CMVideoFormatDescriptionGetDimensions(format)
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: Int(size.width), AVVideoHeightKey: Int(size.height),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 40_000_000, AVVideoExpectedSourceFrameRateKey: 60, AVVideoMaxKeyFrameIntervalKey: 60,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                ],
            ])
            input.expectsMediaDataInRealTime = true
            guard writer.canAdd(input) else { problem = "can't encode \(size.width) x \(size.height)"; return }
            writer.add(input)
            guard writer.startWriting() else { problem = "can't write: \(String(describing: writer.error))"; return }
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(buffer))
            video = input
        }
        waiting.append(buffer)
        drain()
        if waiting.count > Self.room { problem = "the encoder fell \(waiting.count) frames behind" }
    }

    func captureOutput(_ output: AVCaptureOutput, didDrop buffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output is AVCaptureVideoDataOutput, writes { late += 1 }
    }
}

let recorder: Recorder
do { recorder = try Recorder(out, sound: sound, fromBlack: fromBlack) } catch { fail("can't write \(out.path): \(error)") }
try? FileManager.default.removeItem(at: out)

let session = AVCaptureSession()
let queue = DispatchQueue(label: "record")
do {
    let input = try AVCaptureDeviceInput(device: device)
    guard session.canAddInput(input) else { fail("can't record from \(device.localizedName)") }
    session.addInput(input)
} catch {
    fail("can't record from \(device.localizedName): \(error.localizedDescription)")
}
let frames = AVCaptureVideoDataOutput()
frames.alwaysDiscardsLateVideoFrames = false
frames.setSampleBufferDelegate(recorder, queue: queue)
guard session.canAddOutput(frames) else { fail("\(device.localizedName) gives no video") }
session.addOutput(frames)
if sound {
    let samples = AVCaptureAudioDataOutput()
    samples.setSampleBufferDelegate(recorder, queue: queue)
    guard session.canAddOutput(samples) else { fail("\(device.localizedName) gives no sound") }
    session.addOutput(samples)
}
session.startRunning()

signal(SIGUSR1, SIG_IGN)
let arm = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
arm.setEventHandler { queue.async { recorder.armed = true } }
arm.resume()

signal(SIGINT, SIG_IGN)
let stop = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
stop.setEventHandler {
    session.stopRunning()
    queue.sync { recorder.finish() }
    if let problem = recorder.problem { fail(problem) }
    guard let video = recorder.video, let first = recorder.times.first, let last = recorder.times.last else {
        fail(recorder.seen ? "no frame was black after the launch, so nothing was written"
                           : "\(device.localizedName) sent no frames: is it unlocked?")
    }
    video.markAsFinished()
    recorder.audio?.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    recorder.writer.finishWriting { done.signal() }
    done.wait()
    guard recorder.writer.status == .completed else { fail("can't finish \(out.path): \(String(describing: recorder.writer.error))") }
    let steps = zip(recorder.times, recorder.times.dropFirst()).map { $1 - $0 }.sorted()
    let median = steps.isEmpty ? 0 : steps[steps.count / 2]
    say(String(format: "%@, %d x %d, %d frames in %.3f s, median step %.2f ms, %d steps over 25 ms, %d over 42 ms (longest %.1f ms)",
               device.localizedName, recorder.size.width, recorder.size.height, recorder.times.count, last - first, median * 1000,
               steps.filter { $0 > 0.025 }.count, steps.filter { $0 > 0.042 }.count, (steps.last ?? 0) * 1000))
    if recorder.late > 0 { fail("the Mac dropped \(recorder.late) frames the phone sent") }
    print(String(format: "%.6f", first))
    exit(0)
}
stop.resume()
dispatchMain()
