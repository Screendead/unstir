// Copyright © 2026 Jack Lusher. All rights reserved.

import AVFoundation
import os
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

    /// A sold pack's layer over plughole's bed (Jack's call SOUNDSK: Lens B, Escapement B, Prism A); none elsewhere.
    var layer: Sound.Layer? { pack.flatMap { Sound.Layer(rawValue: $0.rawValue) } }
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

extension View {
    /// A bare label's target grown to Apple's 44 pt minimum round it, laid out as the label alone, so nothing moves.
    func hit(_ vertical: CGFloat = 14, _ horizontal: CGFloat = 8) -> some View {
        padding(.vertical, vertical).padding(.horizontal, horizontal).contentShape(Rectangle())
            .padding(.vertical, -vertical).padding(.horizontal, -horizontal)
    }
}

/// The settings' switches, stored as `music.off`, `sounds.off` and `haptics.off`, each absent while on, and the colour
/// letters' choice (`Letters`).
enum Settings {
    /// A harnessed launch's switches, read in place of the stored ones and never stored, so a tap in one shot lasts only
    /// that launch. Keyed `music`, `sounds`, `haptics`, `supporter` and `letters` (absent while unchosen).
    static let held = OSAllocatedUnfairLock<[String: Bool]?>(initialState: nil)

    static var music: Bool {
        get { on("music") }
        set { set("music", newValue) }
    }

    static var sounds: Bool {
        get { on("sounds") }
        set { set("sounds", newValue) }
    }

    static var haptics: Bool {
        get { on("haptics") }
        set { set("haptics", newValue) }
    }

    /// The supporter mark on the menu and the daily's share line, shown once the player owns a pack (Jack's call M6,
    /// round 14); on until switched off.
    static var supporter: Bool {
        get { on("supporter") }
        set { set("supporter", newValue) }
    }

    /// For the log and a report: "music on, sounds off, haptics on, supporter on, letters system".
    static var summary: String {
        let letters = Letters.choice.map { $0 ? "on" : "off" } ?? "system"
        return ["music", "sounds", "haptics", "supporter"].map { "\($0) \(on($0) ? "on" : "off")" }.joined(separator: ", ")
            + ", letters \(letters)"
    }

    private static func on(_ name: String) -> Bool {
        held.withLock { $0.map { $0[name] ?? true } } ?? !UserDefaults.standard.bool(forKey: "\(name).off")
    }

    /// Writes into `held` where the harness holds the switches; false where they are stored.
    static func keep(_ name: String, _ value: Bool?) -> Bool {
        held.withLock { held in
            guard held != nil else { return false }
            held![name] = value
            return true
        }
    }

    private static func set(_ name: String, _ on: Bool) {
        guard !keep(name, on) else { return }
        if on {
            UserDefaults.standard.removeObject(forKey: "\(name).off")
        } else {
            UserDefaults.standard.set(true, forKey: "\(name).off")
        }
    }
}

extension View {
    /// Every system haptic goes through here, so the settings' switch silences them all.
    func haptic<T: Equatable>(_ feedback: SensoryFeedback, trigger: T, when: ((T, T) -> Bool)? = nil) -> some View {
        sensoryFeedback(feedback, trigger: trigger) { old, new in Settings.haptics && (when?(old, new) ?? true) }
    }

    /// The feedback `pick` names for each change of `trigger`, none where it names none.
    func haptic<T: Equatable>(trigger: T, _ pick: @escaping (T, T) -> SensoryFeedback?) -> some View {
        sensoryFeedback(trigger: trigger) { old, new in Settings.haptics ? pick(old, new) : nil }
    }
}

/// Effects on a pool of players, so quick ones overlap, and one looping bed under the menu or a level. Only `queue`
/// touches the engine and the buffers: callers post to it, so the main actor never waits on a file load or an engine
/// start. A bed decodes on it too, so an effect can wait behind one, but beds change only between screens.
final class Sound: @unchecked Sendable {
    static let shared = Sound()

    enum Effect: Equatable, Sendable {
        case push, seized, solve, spilled, tap, undo, reset, tier
        /// A rod's drag passing a step, under its haptic (Jack, 2026-11-11, taking back SND1 = B).
        case tick
        /// Escapement's clock ticking a tooth, the steel pawl on its ratchet wheel (Jack's call soundsk2 = D, round 16).
        case ratchet
        /// The nth heal since the level opened or was reset.
        case heal(Int)
    }

    /// The file an effect plays: the `n`th of a tap's or a tick's four, in turn, so quick ones don't ring alike.
    static func file(_ effect: Effect, _ n: Int) -> String {
        switch effect {
        case .tap: "tap-\(n % 4 + 1)"
        case .tick: "tick-\(n % 4 + 1)"
        case .ratchet: "ratchet-\(n % 4 + 1)"
        case .push: "push"
        case .seized: "seized"
        case .solve: "solve"
        case .spilled: "spilled"
        case .undo: "undo"
        case .reset: "reset"
        case .tier: "switch"
        case .heal(let n): "heal-\(((n - 1) % 6 + 6) % 6 + 1)"
        }
    }

    /// Named by file.
    enum Bed: String, Sendable { case menu, plughole = "loop", whirlpool, vortex, maelstrom }

    /// A pack's layer over the bed: `layer-<name>.m4a` its loop, and `layer-<name>-<part>.caf` the one-shots played over
    /// it, each decoded only while the layer is wanted.
    enum Layer: String, Sendable {
        case lens, escapement, prism
        var loop: String { "layer-\(rawValue)" }
        func part(_ name: String) -> String { "\(loop)-\(name)" }
    }

    /// The layers' tempo, 75 bpm. The loop's first beat sits `lead` into its file, as scripts/sounds.sh turns it.
    static let beat = 0.8
    private static let lead = 0.2
    /// The loop gives way to its resolution over this, from the beat after the solve.
    private static let resolveFade: Float = 0.5
    /// A bed or loop no longer wanted runs on unheard this long, so a quick return, as through a pack's or tier's list
    /// into its next level, takes it up where it has got to rather than from its start.
    static let hold = 15.0
    /// Prism's swell starts this long before the resolution's beat, but never before the solve.
    private static let swell = 0.4
    /// Escapement B's reed: the motif's notes, a move each, and the solve's D.
    static let reeds = ["a4", "b4", "a4", "e4", "g4", "a4", "g4", "e4"]

    /// A bed's player. There are two, so the old bed fades out while the new one fades in.
    private struct Deck {
        let player = AVAudioPlayerNode()
        var name = ""
        var buffer: AVAudioPCMBuffer?
        /// 0 to 1 along the fade. The volume follows it equal-power, so a crossfade of two unrelated beds does not dip.
        var level: Float = 0
        /// When it fell silent, unwanted: it stops once `hold` has passed.
        var quiet: Double?
    }

    /// The layer deck's course apart from the engine, in host seconds: which loop plays, how loud, and the beats it
    /// counts. One loop runs on through every level of its pack, the solve only ducking it under the resolution.
    struct LayerTrack {
        enum Action: Equatable {
            case none
            /// The loop starts from its file's start at this host second.
            case start(Layer, at: Double)
            case stop
        }

        private(set) var playing: Layer?
        /// 0 to 1, the volume equal-power along it.
        private(set) var level: Float = 0
        /// The playing loop's first beat, from which its beats and eighths count.
        private(set) var firstBeat: Double?
        /// The resolution's beat: the loop holds until then, and fades under it over `resolveFade`.
        private(set) var resolving: Double?
        /// The first bar line after the resolution has rung out, where the loop comes back over the crossfade.
        private(set) var returning: Double?
        /// When the loop fell silent, unwanted.
        private var quiet: Double?

        /// The host second of the first beat, or `step` of the loop's beats, at or after `time`; nil while none plays.
        func next(_ step: Double, after time: Double) -> Double? {
            guard let first = firstBeat else { return nil }
            return first + (max(time - first, 0) / step - 1e-9).rounded(.up) * step
        }

        /// The solve at `now`, its resolution `ringing` seconds long: the resolution's beat, nil while no loop plays.
        mutating func resolve(at now: Double, ringing: Double) -> Double? {
            guard playing != nil, let beat = next(Sound.beat, after: now) else { return nil }
            resolving = beat
            returning = next(4 * Sound.beat, after: beat + ringing)
            return beat
        }

        func settled(wanted: Layer?) -> Bool {
            playing == wanted && (wanted == nil || level == 1) && resolving == nil && quiet == nil
        }

        /// One 20 ms step of the fader at `now`, with `wanted` the loop that should sound. Only another pack's loop
        /// restarts the deck; the same one, wanted again, carries on in place.
        mutating func step(wanted: Layer?, now: Double) -> Action {
            var action = Action.none
            if let wanted, wanted != playing {
                // A moment ahead, so the first beat's host time is the one played.
                let start = now + 0.05
                self = LayerTrack(playing: wanted, firstBeat: start + Sound.lead)
                action = .start(wanted, at: start)
            }
            guard playing != nil else { return action }
            let ducked = resolving.map { now >= $0 } == true && returning.map { now < $0 } == true
            let up = playing == wanted && !ducked
            // Left before the resolution's beat, the loop holds to it.
            if !up, playing != wanted, let r = resolving, now < r { return action }
            let rate = 0.02 / (!up && resolving != nil ? Sound.resolveFade : Sound.crossfade)
            level = up ? min(level + rate, 1) : max(level - rate, 0)
            if up, level == 1, let back = returning, now >= back {
                resolving = nil
                returning = nil
            }
            guard level == 0, playing != wanted else {
                quiet = nil
                return action
            }
            resolving = nil
            returning = nil
            let since = quiet ?? now
            quiet = since
            guard now - since >= Sound.hold else { return action }
            self = LayerTrack()
            return .stop
        }
    }

    /// Host time in seconds, as `LayerTrack` and the decks' holds count it.
    private static func now() -> Double { AVAudioTime.seconds(forHostTime: mach_absolute_time()) }

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
    private var taps = 0
    private var ratchets = 0
    private var ticks = 0
    private var bed: Bed?
    /// The wanted layer, kept through its resolution so its one-shots stay decoded.
    private var layer: Layer?
    /// The level was solved: no reed or second resolution until the layer is wanted afresh.
    private var resolved = false
    private var layerFiles: [String: URL] = [:]
    private var layerBuffers: [String: AVAudioPCMBuffer] = [:]
    /// The layer whose files are all decoded: its loop alone, kept by a deck still playing it, is not enough.
    private var stocked: String?
    private var layerPlayer = AVAudioPlayerNode()
    /// The loop on `layerPlayer`, so `stock` keeps it decoded.
    private var layerLoop: AVAudioPCMBuffer?
    private var track = LayerTrack()
    private var fader: DispatchSourceTimer?
    /// In the background, where the engine cannot start.
    private var suspended = false
    /// Logs a failed start once, not on every effect while it keeps failing.
    private var failed = false
    /// Another app's music is playing: the bed gives way to it, and effects still sound.
    private var hushed = false
    /// The settings' switches, read as the first sound is wanted and set as they change.
    private var musicOn = Settings.music
    private var soundsOn = Settings.sounds

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
                self.layerPlayer = AVAudioPlayerNode()
                self.layerLoop = nil
                self.track = LayerTrack()
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
            self.layerFiles = [:]
            self.layerBuffers = [:]
            self.stocked = nil
            // Effects are CAF, beds AAC in .m4a or ALAC in CAF, and a layer's files wait until it is wanted.
            for ext in on ? ["caf", "m4a"] : [] {
                for url in Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Sounds/glass") ?? [] {
                    let name = url.deletingPathExtension().lastPathComponent
                    if name.hasPrefix("layer-") {
                        self.layerFiles[name] = url
                    } else if Bed(rawValue: name) == nil {
                        self.buffers[name] = self.load(url)
                    } else {
                        self.bedFiles[name] = url
                    }
                }
            }
            self.note("sound \(on ? "on" : "off"): \(self.buffers.count) effects, \(self.bedFiles.count) beds, "
                      + "\(self.layerFiles.count) layer files")
            self.fade()
        }
    }

    @MainActor func play(_ effect: Effect) {
        // A drag ticks up to ten times a second, which would crowd the recorder's lines, and a sound switched off
        // never plays.
        if effect != .tick, Settings.sounds { Log.write("sound \(effect)") }
        queue.async { self.start(effect) }
    }

    /// The settings' music switch: the bed fades out over the crossfade, and back in.
    func music(_ on: Bool) {
        queue.async {
            self.musicOn = on
            self.fade()
        }
    }

    /// The settings' sounds switch: every effect and button.
    func sounds(_ on: Bool) {
        queue.async { self.soundsOn = on }
    }

    /// The bed under the menu or a level: a new one crossfades in over the old.
    func bed(_ bed: Bed) {
        queue.async {
            self.bed = bed
            self.listen()
            self.fade()
        }
    }

    /// A pack's layer over the bed, or none: it comes in with the bed's crossfade and loops from its first beat. Wanted
    /// again, by the next level of its pack or another try, it carries on where it has got to.
    func layer(_ layer: Layer?) {
        queue.async {
            self.layer = layer
            self.resolved = false
            self.fade()
        }
    }

    /// Escapement B's reed: the motif's `n`th note, a move's, on the loop's next eighth. Silent while no loop plays.
    func reed(_ n: Int) {
        queue.async {
            guard self.layer == .escapement, !self.resolved, self.track.playing == .escapement,
                  self.wantedLayer == .escapement, let at = self.track.next(Self.beat / 2, after: Self.now())
            else { return }
            self.shoot(Layer.escapement.part(Self.reeds[(n % 8 + 8) % 8]), at: at)
        }
    }

    /// The solve: the loop holds to the next beat and gives way to its resolution there, over `resolveFade`, running on
    /// unheard and coming back on the bar after the resolution has rung out. Escapement's reed lands on D at once, with
    /// the chime. Nothing while no loop plays.
    func resolve() {
        queue.async {
            guard let layer = self.layer, !self.resolved else { return }
            self.resolved = true
            let now = Self.now(), end = self.layerBuffers[layer.part("end")]
            let ringing = end.map { Double($0.frameLength) / self.format.sampleRate } ?? 0
            guard self.track.playing == layer, self.wantedLayer == layer,
                  let beat = self.track.resolve(at: now, ringing: ringing)
            else { return }
            if layer == .escapement { self.shoot(layer.part("d4"), at: nil) }
            self.shoot(layer.part("end"), at: beat)
            if layer == .prism {
                self.shoot(layer.part("swell"), at: beat > now + Self.swell ? beat - Self.swell : nil)
            }
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
        guard soundsOn else { return }
        let name = Self.file(effect, effect == .ratchet ? ratchets : effect == .tick ? ticks : taps)
        if effect == .tick { ticks += 1 }
        if effect == .tap { taps += 1 }
        if effect == .ratchet { ratchets += 1 }
        guard !suspended, let buffer = buffers[name], run(),
              let i = ends.indices.min(by: { ends[$0] < ends[$1] }) else { return }
        ends[i] = DispatchTime.now().uptimeNanoseconds + UInt64(Double(buffer.frameLength) / format.sampleRate * 1e9)
        voices[i].scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !voices[i].isPlaying { voices[i].play() }
    }

    /// A layer's one-shot on a voice of its own, at the host second given or now.
    private func shoot(_ name: String, at time: Double?) {
        guard !suspended, let buffer = layerBuffers[name], run(),
              let i = ends.indices.min(by: { ends[$0] < ends[$1] }) else { return }
        let now = Self.now()
        let wait = time.map { max($0 - now, 0) } ?? 0
        ends[i] = DispatchTime.now().uptimeNanoseconds
            + UInt64((wait + Double(buffer.frameLength) / format.sampleRate) * 1e9)
        voices[i].stop()
        voices[i].scheduleBuffer(buffer, at: nil)
        voices[i].play(at: time.flatMap { $0 > now ? AVAudioTime(hostTime: AVAudioTime.hostTime(forSeconds: $0)) : nil })
        note(String(format: "sound %@ in %.3f s", name, wait))
    }

    /// Starts the engine if it is not running, building it first if need be; false if it cannot start.
    private func run() -> Bool {
        if let engine, engine.isRunning { return true }
        do {
            let session = AVAudioSession.sharedInstance()
            // Mixes with the player's own music and falls silent with the ring switch.
            try session.setCategory(.ambient)
            // Short IO buffers, so an effect lands with its haptic.
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
        layerPlayer = AVAudioPlayerNode()
        for node in voices + decks.map(\.player) + [layerPlayer] {
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
            decks[i].quiet = nil
        }
        layerPlayer.stop()
        layerLoop = nil
        track = LayerTrack()
        beds = [:]
        layerBuffers = [:]
        stocked = nil
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

    /// The bed's file, or plughole's loop where there is no such bed; none while another app's music plays or music
    /// is off.
    private var wantedName: String? {
        guard let bed, !hushed, musicOn else { return nil }
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
        // A layer's files, all of them, while it is wanted with music on: the one-shots outlast its loop.
        let prefix = layer.flatMap { !hushed && musicOn ? $0.loop : nil }
        if let prefix, stocked != prefix {
            // The loop a deck kept playing is the one taken up again, so it is not decoded afresh.
            for (file, url) in layerFiles where file.hasPrefix(prefix) && layerBuffers[file] == nil {
                layerBuffers[file] = load(url)
            }
            note("sound layer \(prefix): \(layerBuffers.count) files")
        }
        stocked = prefix
        layerBuffers = layerBuffers.filter { file in
            prefix.map { file.key.hasPrefix($0) } ?? false || layerLoop === file.value
        }
    }

    /// The layer whose loop should sound, once `stock` has decoded it: none while another app's music plays or with
    /// music off.
    private var wantedLayer: Layer? {
        guard let layer, !hushed, musicOn, layerBuffers[layer.loop] != nil else { return nil }
        return layer
    }

    /// Only the wanted bed plays, at full level, or nothing does when there is none.
    private var settled: Bool {
        let wanted = wanted?.buffer
        return decks.allSatisfy { $0.buffer == nil || $0.buffer === wanted && $0.level == 1 }
            && (wanted == nil || decks.contains { $0.buffer === wanted })
            && track.settled(wanted: wantedLayer)
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
            decks[i].quiet = nil
            note("sound bed \(wanted.name)")
        }
        let rate = 0.02 / Self.crossfade, now = Self.now()
        for i in decks.indices where decks[i].buffer != nil {
            let up = decks[i].buffer === wanted?.buffer
            decks[i].level = up ? min(decks[i].level + rate, 1) : max(decks[i].level - rate, 0)
            decks[i].player.volume = sin(decks[i].level * .pi / 2)
            guard decks[i].level == 0 else {
                decks[i].quiet = nil
                continue
            }
            let since = decks[i].quiet ?? now
            decks[i].quiet = since
            guard now - since >= Self.hold else { continue }
            decks[i].player.stop()
            // By identity: the same bed decoded again, sound turned off and on, may be the one fading in.
            if beds[decks[i].name] === decks[i].buffer { beds[decks[i].name] = nil }
            decks[i].buffer = nil
            decks[i].quiet = nil
            note("sound bed \(decks[i].name) out")
        }
        stepLayer()
        guard settled else { return }
        stopFading()
        if wanted == nil && track.playing == nil { rest() }
    }

    /// The layer's share of a fader step: its loop in from its first beat over the crossfade, ducked under a
    /// resolution, or out, over the crossfade or, from the resolution's beat, over `resolveFade`.
    private func stepLayer() {
        let wanted = wantedLayer
        if let wanted, wanted != track.playing, !run() { return }
        switch track.step(wanted: wanted, now: Self.now()) {
        case .start(let layer, let at):
            if layerLoop != nil { note("sound layer cut") }
            guard let loop = layerBuffers[layer.loop] else { return }
            layerPlayer.stop()
            layerPlayer.volume = 0
            layerPlayer.scheduleBuffer(loop, at: nil, options: .loops)
            layerPlayer.play(at: AVAudioTime(hostTime: AVAudioTime.hostTime(forSeconds: at)))
            layerLoop = loop
            note("sound layer \(layer.loop)")
        case .stop:
            layerPlayer.stop()
            layerLoop = nil
            note("sound layer out")
        case .none:
            break
        }
        layerPlayer.volume = sin(track.level * .pi / 2)
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
        guard decks.allSatisfy({ $0.buffer == nil }), track.playing == nil, fader == nil, let engine, engine.isRunning
        else { return }
        engine.pause()
    }

    private func note(_ line: String) {
        Task { @MainActor in Log.write(line) }
    }
}

/// Escapement: one of a move's ticks as it lands after the lift, with what sounds and what is felt as it does.
struct TickCue: Equatable {
    var at: Double
    var sounds: [Sound.Effect]
    var haptic: SensoryFeedback
    /// The tick that solves the tank: the solve's chime, haptic and wave land with it, through the view, which plays
    /// them once whether the tick or the win's own change comes first.
    var solves = false
}

extension Game {
    /// Escapement: each of the newest move's ticks, landing as its clock's core starts to turn and its flap falls: a beat
    /// after the lift, then a turn apart. Every tick is the ratchet's steel with its rigid haptic (Jack's calls soundsk2
    /// = D and soundsk-haptic = B, round 16). One that pushed has the error haptic, and the move's first push sounds the
    /// push over its ratchet: a pushed tick's own, unless the move's stir pushed first (Jack's calls tk-push = B and
    /// tk-multi = C, round 16). The move that solves the tank lands the solve's chime and success haptic with its last
    /// tick, and the wave with them (tk-finish = B). A move that runs the tank out of ticks plays its ticks as any
    /// other move does. None on a level without clocks.
    var tickCues: [TickCue] {
        var push = !stirPushed
        return tick.enumerated().map { i, t in
            var cue = TickCue(at: LevelView.tickAt(i), sounds: [.ratchet],
                              haptic: t.pushed ? .error : .impact(flexibility: .rigid, intensity: 0.9))
            if t.pushed && push { cue.sounds.append(.push); push = false }
            if solved && i == tick.count - 1 { cue.haptic = .success; cue.solves = true }
            return cue
        }
    }

    /// Escapement: when the newest move's solve lands after its lift, nil where none waits for a tick.
    var solveAt: Double? { tickCues.last(where: \.solves)?.at }

    /// Plays the newest move's ticks at their times while they stand, handing each to `felt` for its haptic and, on the
    /// solving tick, the wave: an undo or a reset takes the rest back with the move, and leaving the level cancels the
    /// wait. Each cue is read as it lands, so a win the fine pass calls after the lift still lands on its last tick.
    func soundTicks(_ felt: (TickCue) -> Void) async {
        let lift = landed
        var i = 0
        while i < tickCues.count {
            guard (try? await Task.sleep(until: lift + .seconds(tickCues[i].at), tolerance: .milliseconds(2))) != nil,
                  i < tickCues.count
            else { return }
            let cue = tickCues[i]
            for sound in cue.sounds { Sound.shared.play(sound) }
            felt(cue)
            i += 1
        }
    }
}
