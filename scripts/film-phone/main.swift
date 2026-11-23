// Copyright © 2026 Jack Lusher. All rights reserved.
// Usage: build/film-phone/record [--sound] <out.mov> [device name]   (scripts/film.sh builds it)
// Records the screen of an iPhone plugged into the Mac, as QuickTime's movie recording does, until SIGINT: every frame
// the phone sends, at the time the Mac's capture stamps on it, as H.264. --sound records the phone's sound with it,
// which takes the phone's output for as long as the recording runs. Then prints when its first frame was captured, in
// seconds of CLOCK_UPTIME_RAW, the clock scripts/film.sh times a take on, and a line of the take's frame times on
// stderr. Exits 1 if the capture dropped a frame: the take would hitch where the phone did not.
// The process that runs it needs the Mac's Camera permission (and Microphone with --sound); the phone must be
// unlocked and have trusted this Mac.
import AVFoundation
import CoreMediaIO
import Darwin

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("record: \(message)\n".utf8))
    exit(1)
}

var arguments = Array(CommandLine.arguments.dropFirst())
let sound = arguments.first == "--sound"
if sound { arguments.removeFirst() }
guard (1...2).contains(arguments.count) else { fail("usage: record [--sound] <out.mov> [device name]") }
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

final class Recorder: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    let writer: AVAssetWriter
    let audio: AVAssetWriterInput?
    var video: AVAssetWriterInput?
    var times: [Double] = []
    var size = CMVideoDimensions(width: 0, height: 0)
    var dropped = 0
    var problem: String?

    init(_ url: URL, sound: Bool) throws {
        writer = try AVAssetWriter(outputURL: url, fileType: .mov)
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

    func captureOutput(_ output: AVCaptureOutput, didOutput buffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard problem == nil else { return }
        guard output is AVCaptureVideoDataOutput else {
            if video != nil, let audio, audio.isReadyForMoreMediaData { audio.append(buffer) }
            return
        }
        let time = CMSampleBufferGetPresentationTimeStamp(buffer)
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
            writer.startSession(atSourceTime: time)
            video = input
        }
        if video!.isReadyForMoreMediaData, video!.append(buffer) {
            times.append(time.seconds)
        } else if writer.status == .failed {
            problem = "writing failed: \(String(describing: writer.error))"
        } else {
            dropped += 1
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didDrop buffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output is AVCaptureVideoDataOutput { dropped += 1 }
    }
}

let recorder: Recorder
do { recorder = try Recorder(out, sound: sound) } catch { fail("can't write \(out.path): \(error)") }
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

signal(SIGINT, SIG_IGN)
let stop = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
stop.setEventHandler {
    session.stopRunning()
    queue.sync {}
    if let problem = recorder.problem { fail(problem) }
    guard let video = recorder.video, let first = recorder.times.first, let last = recorder.times.last else {
        fail("\(device.localizedName) sent no frames: is it unlocked?")
    }
    video.markAsFinished()
    recorder.audio?.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    recorder.writer.finishWriting { done.signal() }
    done.wait()
    guard recorder.writer.status == .completed else { fail("can't finish \(out.path): \(String(describing: recorder.writer.error))") }
    let steps = zip(recorder.times, recorder.times.dropFirst()).map { $1 - $0 }.sorted()
    let median = steps.isEmpty ? 0 : steps[steps.count / 2]
    let long = steps.filter { $0 > 1.5 * median }
    FileHandle.standardError.write(Data(String(
        format: "record: %@, %d x %d, %d frames in %.3f s, median step %.2f ms, %d steps over 1.5 of it (longest %.1f ms), %d dropped\n",
        device.localizedName, recorder.size.width, recorder.size.height, recorder.times.count, last - first, median * 1000,
        long.count, (steps.last ?? 0) * 1000, recorder.dropped).utf8))
    if recorder.dropped > 0 { fail("the capture dropped \(recorder.dropped) frames") }
    print(String(format: "%.6f", first))
    exit(0)
}
stop.resume()
dispatchMain()
