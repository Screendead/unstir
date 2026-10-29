// Copyright © 2026 Jack Lusher. All rights reserved.

import AVFoundation
import SwiftUI

extension Level {
    /// Each tier's own bed; the daily, endless, the sandbox and the packs, which have none yet, are plughole's.
    var bed: Sound.Bed {
        switch tier {
        case .plughole: .plughole
        case .whirlpool: .whirlpool
        case .vortex: .vortex
        case .maelstrom: .maelstrom
        }
    }
}

/// Every button sounds as it acts. RootView sets this for the whole app, and undo and reset set their own sound. The
/// menu's tier names and rows stay plain and sound from their actions.
struct Sounding: PrimitiveButtonStyle {
    var effect = Sound.Effect.tap

    func makeBody(configuration: Configuration) -> some View {
        // A style of its own, or the button would take this one from the environment and build itself again.
        Button(role: configuration.role) {
            Sound.shared.play(effect)
            configuration.trigger()
        } label: {
            configuration.label
        }
        .buttonStyle(.plain)
    }
}

extension ShareLink {
    /// A share link taps as it opens, beside its own action rather than through `Sounding`, which has not been seen to
    /// open the sheet.
    @MainActor func shareTap() -> some View {
        buttonStyle(.plain).simultaneousGesture(TapGesture().onEnded { Sound.shared.play(.tap) })
    }
}

/// Effects on a pool of players, so quick ones overlap, and one looping bed under the menu or a level. Only `queue`
/// touches the engine and the buffers: callers post to it, so the main actor never waits on a file load or an engine
/// start. A bed decodes on it too, so a tick can wait behind one, but beds change only between screens.
final class Sound: @unchecked Sendable {
    static let shared = Sound()

    enum Effect: Equatable, Sendable {
        case tick, push, tank, seized, solve, spilled, tap, undo, reset, tier
        /// The nth heal since the level opened or was reset.
        case heal(Int)
    }

    /// Named by file.
    enum Bed: String, Sendable { case menu, plughole = "loop", whirlpool, vortex, maelstrom }

    /// A bed's player. There are two, so the old bed fades out while the new one fades in.
    private struct Deck {
        let player = AVAudioPlayerNode()
        var name = ""
        var buffer: AVAudioPCMBuffer?
        /// 0 to 1 along the fade. The volume follows it equal-power, so a crossfade of two unrelated beds does not dip.
        var level: Float = 0
    }

    private static let crossfade: Float = 1.5
    private let queue = DispatchQueue(label: "com.screendead.Unstir.sound", qos: .userInteractive)
    /// Every buffer is converted to this on load, so any player can take any sound.
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
    /// Built on the first sound or bed, so with sound off the audio session never opens.
    private var engine: AVAudioEngine?
    private var voices: [AVAudioPlayerNode] = []
    /// When each voice's sound ends, in uptime nanoseconds. A new sound takes the voice that ends first, which is a
    /// finished one whenever there is one.
    private var ends: [UInt64] = []
    private var decks: [Deck] = []
    private var on = false
    /// The glass set's effects.
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    /// The glass set's beds. Each is 18 MB decoded, so only the wanted one and any still fading out are kept.
    private var bedFiles: [String: URL] = [:]
    private var beds: [String: AVAudioPCMBuffer] = [:]
    private var ticks = 0
    private var taps = 0
    private var bed: Bed?
    private var fader: DispatchSourceTimer?
    /// In the background, where the engine cannot start.
    private var suspended = false
    /// Logs a failed start once, not on every tick while it keeps failing.
    private var failed = false
    /// Another app's music is playing: the bed gives way to it, and effects still sound.
    private var hushed = false

    private init() {
        let centre = NotificationCenter.default
        // The system has stopped the engine for a call, an alarm or Siri; it may never say the interruption ended, so
        // the return to the foreground restarts it too.
        centre.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let began = raw.flatMap(AVAudioSession.InterruptionType.init) == .began
            self.queue.async { began ? self.halt() : self.resume() }
        }
        // A new route or sample rate stops the engine and drops what its players had scheduled.
        centre.addObserver(forName: .AVAudioEngineConfigurationChange, object: nil, queue: nil) { note in
            let id = note.object.map { ObjectIdentifier($0 as AnyObject) }
            self.queue.async {
                guard let engine = self.engine, id == ObjectIdentifier(engine) else { return }
                self.halt()
                self.resume()
            }
        }
        let hint = AVAudioSession.silenceSecondaryAudioHintNotification
        centre.addObserver(forName: hint, object: nil, queue: nil) { note in
            let raw = note.userInfo?[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt
            let begins = raw.flatMap(AVAudioSession.SilenceSecondaryAudioHintType.init) == .begin
            self.queue.async {
                self.hushed = begins
                self.fade()
            }
        }
        // The old engine and its nodes are dead: drop them untouched, and the next sound builds new ones.
        centre.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: nil) { _ in
            self.queue.async {
                self.fader?.cancel()
                self.fader = nil
                self.engine = nil
                self.voices = []
                self.ends = []
                self.decks = []
                self.resume()
            }
        }
    }

    /// Decodes the effects off the main actor, all of them, so no effect waits on its file. A bed decodes when it is
    /// wanted.
    func use(on: Bool) {
        queue.async {
            guard on != self.on else { return }
            self.on = on
            self.buffers = [:]
            self.bedFiles = [:]
            self.beds = [:]
            // Effects are CAF, beds AAC in .m4a or ALAC in CAF.
            for ext in on ? ["caf", "m4a"] : [] {
                for url in Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Sounds/glass") ?? [] {
                    let name = url.deletingPathExtension().lastPathComponent
                    if Bed(rawValue: name) == nil { self.buffers[name] = self.load(url) } else { self.bedFiles[name] = url }
                }
            }
            self.note("sound \(on ? "on" : "off"): \(self.buffers.count) effects, \(self.bedFiles.count) beds")
            self.fade()
        }
    }

    @MainActor func play(_ effect: Effect) {
        // A drag ticks up to ten times a second, which would crowd the recorder's 3000 lines.
        if effect != .tick { Log.write("sound \(effect)") }
        queue.async { self.start(effect) }
    }

    /// The bed under the menu or a level: a new one crossfades in over the old.
    func bed(_ bed: Bed) {
        queue.async {
            self.bed = bed
            self.listen()
            self.fade()
        }
    }

    /// Off in the background, back in the foreground.
    func foreground(_ active: Bool) {
        queue.async {
            guard active == self.suspended else { return }
            self.suspended = !active
            if active { self.resume() } else { self.halt() }
        }
    }

    // Everything below runs on `queue`.

    private func load(_ url: URL) -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: url), file.processingFormat.sampleRate == format.sampleRate,
              let read = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: read)) != nil, let source = read.floatChannelData,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: read.frameLength), let out = buffer.floatChannelData
        else {
            note("sound \(url.lastPathComponent) not loaded")
            return nil
        }
        buffer.frameLength = read.frameLength
        // A mono file goes to both channels at full level, as its loudness was measured.
        let channels = Int(read.format.channelCount)
        for c in 0..<2 { out[c].update(from: source[min(c, channels - 1)], count: Int(read.frameLength)) }
        return buffer
    }

    private func start(_ effect: Effect) {
        let name = switch effect {
        case .tick: "tick-\(ticks % 4 + 1)"
        case .tap: "tap-\(taps % 4 + 1)"
        case .push: "push"
        case .tank: "tank"
        case .seized: "seized"
        case .solve: "solve"
        case .spilled: "spilled"
        case .undo: "undo"
        case .reset: "reset"
        case .tier: "switch"
        case .heal(let n): "heal-\(((n - 1) % 6 + 6) % 6 + 1)"
        }
        if effect == .tick { ticks += 1 }
        if effect == .tap { taps += 1 }
        guard !suspended, let buffer = buffers[name], run(),
              let i = ends.indices.min(by: { ends[$0] < ends[$1] }) else { return }
        ends[i] = DispatchTime.now().uptimeNanoseconds + UInt64(Double(buffer.frameLength) / format.sampleRate * 1e9)
        voices[i].scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !voices[i].isPlaying { voices[i].play() }
    }

    /// Starts the engine if it is not running, building it first if need be; false if it cannot start.
    private func run() -> Bool {
        if let engine, engine.isRunning { return true }
        do {
            let session = AVAudioSession.sharedInstance()
            // Mixes with the player's own music and falls silent with the ring switch.
            try session.setCategory(.ambient)
            // Short IO buffers, so a tick lands with its haptic.
            try? session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
            try (engine ?? build()).start()
            if failed { note("sound engine started") }
            failed = false
            // An interruption can end without a word while the app stays in front: the next sound brings the bed back.
            fade()
            return true
        } catch {
            if !failed { note("sound engine did not start: \(error.localizedDescription)") }
            failed = true
            return false
        }
    }

    private func build() -> AVAudioEngine {
        let engine = AVAudioEngine()
        voices = (0..<12).map { _ in AVAudioPlayerNode() }
        ends = Array(repeating: 0, count: voices.count)
        decks = [Deck(), Deck()]
        for node in voices + decks.map(\.player) {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }
        self.engine = engine
        return engine
    }

    /// Everything stops; the engine's players have lost what they had scheduled, or are about to. No bed stays decoded
    /// in the background.
    private func halt() {
        fader?.cancel()
        fader = nil
        for voice in voices { voice.stop() }
        ends = ends.map { _ in 0 }
        for i in decks.indices {
            decks[i].player.stop()
            decks[i].buffer = nil
            decks[i].level = 0
        }
        beds = [:]
        engine?.pause()
    }

    private func resume() {
        guard !suspended else { return }
        listen()
        fade()
    }

    /// The hint's notification reaches only an app in front, so the hint is read afresh on a new bed and on return.
    private func listen() {
        hushed = AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint
    }

    /// The bed's file, or plughole's loop where there is no such bed; none while another app's music plays.
    private var wantedName: String? {
        guard let bed, !hushed else { return nil }
        return bedFiles[bed.rawValue] == nil ? Bed.plughole.rawValue : bed.rawValue
    }

    /// The wanted bed, once `stock` has decoded it.
    private var wanted: (name: String, buffer: AVAudioPCMBuffer)? {
        wantedName.flatMap { name in beds[name].map { (name, $0) } }
    }

    /// Decodes the wanted bed if need be, and drops every other that no deck is playing.
    private func stock() {
        while let name = wantedName, beds[name] == nil, let url = bedFiles[name] {
            // A bed that will not load is dropped, so plughole's loop plays in its place.
            guard let buffer = load(url) else { bedFiles[name] = nil; continue }
            beds[name] = buffer
            note("sound bed \(name): \(buffer.frameLength) frames")
        }
        let name = wantedName
        beds = beds.filter { bed in bed.key == name || decks.contains { $0.buffer === bed.value } }
    }

    /// Only the wanted bed plays, at full level, or nothing does when there is none.
    private var settled: Bool {
        let wanted = wanted?.buffer
        return decks.allSatisfy { $0.buffer == nil || $0.buffer === wanted && $0.level == 1 }
            && (wanted == nil || decks.contains { $0.buffer === wanted })
    }

    /// Runs the fader until the bed is settled.
    private func fade() {
        guard !suspended else { return }
        stock()
        guard fader == nil, !settled else { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(20))
        timer.setEventHandler { self.step() }
        timer.resume()
        fader = timer
    }

    /// One 20 ms step of the crossfade: the wanted bed in and up, started on the quieter deck if neither has it, and
    /// the other down and out.
    private func step() {
        let wanted = wanted
        if let wanted, !decks.contains(where: { $0.buffer === wanted.buffer }) {
            guard run(), let i = decks.indices.min(by: { decks[$0].level < decks[$1].level }) else { return stopFading() }
            // A third bed before a crossfade has ended cuts the quieter of the two short.
            if decks[i].buffer != nil { note("sound bed \(decks[i].name) cut") }
            decks[i].player.stop()
            decks[i].player.volume = 0
            decks[i].player.scheduleBuffer(wanted.buffer, at: nil, options: .loops)
            decks[i].player.play()
            decks[i].name = wanted.name
            decks[i].buffer = wanted.buffer
            decks[i].level = 0
            note("sound bed \(wanted.name)")
        }
        let rate = 0.02 / Self.crossfade
        for i in decks.indices where decks[i].buffer != nil {
            let up = decks[i].buffer === wanted?.buffer
            decks[i].level = up ? min(decks[i].level + rate, 1) : max(decks[i].level - rate, 0)
            decks[i].player.volume = sin(decks[i].level * .pi / 2)
            if decks[i].level == 0 {
                decks[i].player.stop()
                // By identity: the same bed decoded again, sound turned off and on, may be the one fading in.
                if beds[decks[i].name] === decks[i].buffer { beds[decks[i].name] = nil }
                decks[i].buffer = nil
                note("sound bed \(decks[i].name) out")
            }
        }
        guard settled else { return }
        stopFading()
        if wanted == nil { rest() }
    }

    private func stopFading() {
        fader?.cancel()
        fader = nil
    }

    /// With no bed to play, as when sound is off, pauses the engine once the last effect has rung out.
    private func rest() {
        let now = DispatchTime.now().uptimeNanoseconds, busy = ends.max() ?? 0
        guard busy <= now else {
            queue.asyncAfter(deadline: .now() + .nanoseconds(Int(busy - now)) + .milliseconds(500)) { self.rest() }
            return
        }
        guard decks.allSatisfy({ $0.buffer == nil }), fader == nil, let engine, engine.isRunning else { return }
        engine.pause()
    }

    private func note(_ line: String) {
        Task { @MainActor in Log.write(line) }
    }
}
