// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import SwiftUI

/// The player's answer to the one analytics question. Nothing is sent, queued or started until it is `yes`.
enum Consent: String, Sendable {
    case undecided, yes, no
}

/// A property value as Aptabase files it: a JSON number lands in its numeric props, a string in its string props.
enum Prop: Codable, Equatable, Sendable {
    case int(Int), text(String)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let n = try? c.decode(Int.self) { self = .int(n) } else { self = .text(try c.decode(String.self)) }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .int(let n): try c.encode(n)
        case .text(let s): try c.encode(s)
        }
    }
}

struct Event: Codable, Equatable, Sendable {
    var name: String
    var props: [String: Prop]
    var time: Date
    /// Held only in memory, in the queue and in a pending quit: Aptabase refuses an event without one. A snapshot has its
    /// own.
    var session: String
}

/// What the layer keeps between launches, besides consent. None of it leaves the phone except inside an event.
struct Tally: Codable, Equatable {
    /// The local day of the first launch, as `Best.day` writes it.
    var installed: String?
    /// Day numbers the app came to the front on, day 1 the install's.
    var days: [Int] = []
    /// The newest day `returned` went out for.
    var returned = 1
    /// Once-per-install events sent: "installed", "snapshot.7", "card.lens", "purchased.complete".
    var sent: Set<String> = []
    /// What happened on the phone whether or not it was sent, for the snapshot: "card.lens", "taste.lens".
    var seen: Set<String> = []
    var undos = 0
    /// The quit the open level would send, written as the app leaves the front: an app killed there sends it next launch.
    var pending: Event?

    static let milestones = [2, 7, 30]

    /// Day 1 is `from`; nil for a malformed day.
    static func number(of day: String, from: String) -> Int? {
        func date(_ s: String) -> Date? {
            let f = DateFormatter()
            f.calendar = Calendar(identifier: .gregorian)
            f.timeZone = TimeZone(identifier: "UTC")
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: s)
        }
        guard let a = date(from), let b = date(day) else { return nil }
        return Int((b.timeIntervalSince(a) / 86400).rounded()) + 1
    }

    enum Due: Equatable {
        case installed(day: Int), returned(day: Int), snapshot(milestone: Int, day: Int)
    }

    /// The app is at the front on local day `today`: records the day, and returns what is due if the player has said
    /// yes. Each is marked sent here, so nothing comes due twice; a day reached with the clock set back is no return.
    mutating func opened(today: String, consented: Bool) -> [Due] {
        if installed == nil { installed = today }
        guard let day = Tally.number(of: today, from: installed!), day >= 1 else { return [] }
        if !days.contains(day) { days.append(day) }
        guard consented else { return [] }
        var due: [Due] = []
        if sent.insert("installed").inserted { due.append(.installed(day: day)) }
        if day > returned {
            returned = day
            due.append(.returned(day: day))
        }
        for m in Tally.milestones where day >= m && sent.insert("snapshot.\(m)").inserted {
            due.append(.snapshot(milestone: m, day: day))
        }
        return due
    }
}

/// Anonymous counts for Aptabase, behind the player's consent. `shared` stays off until `start`, and a launch under the
/// test runner never starts it.
@MainActor
final class Analytics {
    static let shared = Analytics()

    enum Mode {
        case off
        /// UNSTIR_ANALYTICS=log: each event goes to the flight recorder instead.
        case log
        case send(Sender.Endpoint, queue: URL, transport: Sender.Transport)
    }

    private(set) var consent: Consent
    private(set) var tally: Tally
    private var mode = Mode.off
    /// False for a harnessed or logging launch, whose consent and tally last only that launch.
    private var stores = false
    private let defaults: UserDefaults
    /// Nil until the player says yes, and again after they say no.
    private(set) var sender: Sender?
    /// Renewed after `idle` with no event, as Aptabase's SDK does: the server drops, unannounced, an event whose session
    /// began more than 7 days ago, and iOS can keep the app suspended that long.
    private var session = Analytics.newSession()
    var touched = Date.now
    static let idle: TimeInterval = 3600
    /// The local calendar day, plain: a clock set ahead can fake a return, which no player gains anything by.
    var today: () -> String = { Best.day() }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        consent = defaults.string(forKey: "analytics.consent").flatMap(Consent.init(rawValue:)) ?? .undecided
        tally = defaults.data(forKey: "analytics").flatMap { try? JSONDecoder().decode(Tally.self, from: $0) } ?? Tally()
    }

    /// The launch's mode: logging with UNSTIR_ANALYTICS=log, which counts as a yes and stores nothing; off under any
    /// other harness flag or without an app key; otherwise sending.
    func start(env: [String: String], harnessed: Bool,
               key: String? = Bundle.main.object(forInfoDictionaryKey: "AptabaseKey") as? String) {
        if env["UNSTIR_ANALYTICS"] == "log" {
            consent = .yes
            start(.log, stores: false)
        } else if !harnessed {
            // Without a key the answer is still kept, for the build that has one.
            stores = true
            guard let endpoint = key.flatMap(Sender.Endpoint.init(key:)) else { return }
            start(.send(endpoint, queue: URL.libraryDirectory.appending(path: "analytics-queue.json"),
                        transport: { try await URLSession.shared.data(for: $0) }), stores: true)
        }
    }

    func start(_ mode: Mode, stores: Bool) {
        self.mode = mode
        self.stores = stores
        wake()
        if let killed = tally.pending {
            tally.pending = nil
            emit(killed)
        }
        opened()
    }

    var on: Bool {
        if case .off = mode { return false }
        return true
    }

    /// What the first-launch question and the settings switch set.
    func decide(_ yes: Bool) {
        consent = yes ? .yes : .no
        if stores { defaults.set(consent.rawValue, forKey: "analytics.consent") }
        guard on else { return }
        if yes {
            wake()
            opened()
        } else {
            tally.pending = nil
            save()
            sender?.discard()
            sender = nil
            if case .send(_, let queue, _) = mode { try? FileManager.default.removeItem(at: queue) }
        }
    }

    /// The app came to the front.
    func opened(today: String? = nil) {
        guard on else { return }
        let due = tally.opened(today: today ?? self.today(), consented: consent == .yes)
        save()
        for d in due {
            switch d {
            case .installed(let day): send("installed", ["day": .int(day)])
            case .returned(let day): send("returned", ["day": .int(day)])
            case .snapshot(let m, let day): emit(Event(name: "snapshot", props: snapshot(milestone: m, day: day),
                                                       time: .now, session: Analytics.newSession()))
            }
        }
    }

    func phase(_ phase: ScenePhase) {
        switch phase {
        case .active: opened()
        case .background: sender?.flush()
        default: break
        }
    }

    // MARK: Play

    /// A level or run ends on its own: solved, or the brim spilled. An endless tank solved is no end: the run goes on.
    func finished(_ game: Game) {
        guard on else { return }
        if game.level.run != nil {
            if game.spilled, let e = Analytics.report(game, "spilled") { send(e.name, e.props) }
            return
        }
        guard game.solved, let e = Analytics.report(game, "solved") else { return }
        send(e.name, e.props)
        if let pack = game.level.pack, (1...pack.taste).allSatisfy({ Best.load(pack.id($0)) != nil }) {
            tasteFinished(pack)
        }
    }

    /// The player leaves for the menu: a level unsolved is a quit, and so is a run that has not spilled.
    func left(_ game: Game) {
        guard on, let e = Analytics.quit(game) else { return }
        send(e.name, e.props)
    }

    /// The app leaves the front with `game` open: if it is killed there, its quit goes out next launch.
    func suspended(_ game: Game) {
        guard on, consent == .yes, let e = Analytics.quit(game) else { return }
        tally.pending = Event(name: e.name, props: e.props, time: .now, session: currentSession())
        save()
    }

    func resumed() {
        guard tally.pending != nil else { return }
        tally.pending = nil
        save()
    }

    func undid() {
        guard on else { return }
        tally.undos += 1
        save()
    }

    /// The level event, or endless's run event, for `outcome`; nil for the sandbox, which counts nothing. Each daily is
    /// `daily`: its date is the event's.
    static func report(_ game: Game, _ outcome: String) -> (name: String, props: [String: Prop])? {
        let level = game.level
        if let run = level.run {
            return ("run", ["outcome": .text(outcome), "tanks": .int(run.tank + (game.solved ? 1 : 0)),
                            "moves": .int(game.moves)])
        }
        guard !level.sandbox else { return nil }
        return ("level", ["id": .text(level.id.hasPrefix("daily-") ? "daily" : level.id), "outcome": .text(outcome),
                          "moves": .int(game.moves), "par": .int(game.par), "undos": .int(game.undos),
                          "resets": .int(game.resets)])
    }

    private static func quit(_ game: Game) -> (name: String, props: [String: Prop])? {
        // A solved endless tank is `finished`, but its run goes on: only a spill ends a run.
        if game.level.run != nil {
            return game.spilled ? nil : report(game, "quit")
        }
        return game.finished ? nil : report(game, "quit")
    }

    // MARK: Packs

    /// Each once per install. The pack card's view calls `cardSeen` as it shows.
    func cardSeen(_ pack: Pack) { once("card", pack.rawValue) }
    func tasteFinished(_ pack: Pack) { once("taste", pack.rawValue) }

    /// A verified purchase made on this phone, of a pack or Complete.
    func purchased(_ productID: String) {
        let name = productID == Pack.completeID ? "complete" : Pack.allCases.first { $0.productID == productID }?.rawValue
        if let name { once("purchased", name) }
    }

    private func once(_ event: String, _ product: String) {
        guard on else { return }
        let key = "\(event).\(product)"
        tally.seen.insert(key)
        if consent == .yes, tally.sent.insert(key).inserted { send(event, ["pack": .text(product)]) }
        save()
    }

    // MARK: Snapshot

    /// One player's history from what the phone stores. Nothing in it ties it to their other events.
    func snapshot(milestone: Int, day: Int) -> [String: Prop] {
        var p: [String: Prop] = ["milestone": .int(milestone), "day": .int(day),
                                 "days": .text(tally.days.sorted().map(String.init).joined(separator: ",")),
                                 "undos": .int(tally.undos), "bank": .int(Best.undos), "endless": .int(Best.tanks)]
        var started = 0
        for tier in Tier.allCases {
            p[tier.rawValue] = .int(tier.levels.lastIndex { Best.load($0.id) != nil }.map { $0 + 1 } ?? 0)
            started += tier.levels.filter { Best.started($0.id) }.count
        }
        p["started"] = .int(started)
        p["dailies"] = .int(defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("best.daily-") }.count)
        let owned = Store.shared.ledger.owned
        for pack in Pack.allCases {
            let flags = [tally.seen.contains("card.\(pack.rawValue)") ? "card" : nil,
                         tally.seen.contains("taste.\(pack.rawValue)") ? "taste" : nil,
                         owned.contains(pack) ? "owned" : nil].compactMap { $0 }
            p[pack.rawValue] = .text(flags.isEmpty ? "none" : flags.joined(separator: ","))
        }
        return p
    }

    // MARK: Output

    private func send(_ name: String, _ props: [String: Prop]) {
        emit(Event(name: name, props: props, time: .now, session: currentSession()))
    }

    private func currentSession() -> String {
        if Date.now.timeIntervalSince(touched) > Analytics.idle { session = Analytics.newSession() }
        touched = .now
        return session
    }

    private func emit(_ event: Event) {
        guard consent == .yes else { return }
        switch mode {
        case .off: return
        case .log:
            let props = (try? JSONEncoder.sorted.encode(event.props)).map { String(decoding: $0, as: UTF8.self) } ?? ""
            Log.write("analytics \(event.name) \(props)")
        case .send:
            wake()
            sender?.add(event)
        }
    }

    /// Builds the sender under a yes, which sends what an earlier launch left queued with no new event to carry it.
    private func wake() {
        guard consent == .yes, sender == nil, case .send(let endpoint, let queue, let transport) = mode else { return }
        sender = Sender(endpoint: endpoint, file: queue, transport: transport)
    }

    private func save() {
        guard stores, let data = try? JSONEncoder().encode(tally) else { return }
        defaults.set(data, forKey: "analytics")
    }

    /// Aptabase's numeric form: the start's epoch seconds, then eight random digits. It checks the start against the
    /// clock, and refuses one more than 7 days old.
    static func newSession() -> String {
        String(UInt64(Date.now.timeIntervalSince1970) * 100_000_000 + UInt64.random(in: 0...99_999_999))
    }
}

/// Posts events to Aptabase from a queue kept in a file, so a killed app sends what it had queued on its next launch.
@MainActor
final class Sender {
    typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    struct Endpoint: Equatable, Sendable {
        let url: URL
        let key: String

        /// An Aptabase app key names its region: A-EU-0123456789. Only the hosted EU and US regions are known; any
        /// other key leaves analytics off.
        init?(key: String) {
            let parts = key.split(separator: "-")
            guard parts.count == 3, let host = ["EU": "eu.aptabase.com", "US": "us.aptabase.com"][String(parts[1])] else {
                return nil
            }
            url = URL(string: "https://\(host)/api/v0/events")!
            self.key = key
        }
    }

    /// The server's most per request.
    static let batch = 25
    /// The server refuses an event more than a day old.
    static let stale: TimeInterval = 23 * 3600
    static let cap = 500

    private let endpoint: Endpoint
    private let file: URL
    private let transport: Transport
    private(set) var queue: [Event]
    private var sending = false
    private var retry: Task<Void, Never>?

    init(endpoint: Endpoint, file: URL, transport: @escaping Transport) {
        self.endpoint = endpoint
        self.file = file
        self.transport = transport
        queue = (try? Data(contentsOf: file)).flatMap { try? JSONDecoder().decode([Event].self, from: $0) } ?? []
        flush()
    }

    func add(_ event: Event) {
        queue.append(event)
        queue = Array(queue.suffix(Sender.cap))
        save()
        flush()
    }

    func discard() {
        retry?.cancel()
        queue = []
        try? FileManager.default.removeItem(at: file)
    }

    func flush() {
        guard !sending, !queue.isEmpty else { return }
        sending = true
        Task {
            await send()
            sending = false
        }
    }

    /// A batch the server takes or refuses (4xx) leaves the queue, as the SDK does; on no answer or a 5xx or 429 it
    /// stays, and a retry comes a minute later.
    func send() async {
        let fresh = queue.filter { $0.time.timeIntervalSinceNow > -Sender.stale }
        if fresh.count < queue.count {
            Log.write("analytics dropped \(queue.count - fresh.count) stale")
            queue = fresh
            save()
        }
        while !queue.isEmpty {
            let batch = Array(queue.prefix(Sender.batch))
            var request = URLRequest(url: endpoint.url, timeoutInterval: 10)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(endpoint.key, forHTTPHeaderField: "App-Key")
            request.setValue("Unstir", forHTTPHeaderField: "User-Agent")
            request.httpBody = Sender.body(batch)
            let status: Int
            do {
                status = ((try await transport(request)).1 as? HTTPURLResponse)?.statusCode ?? 0
            } catch {
                status = 0
            }
            if status == 0 || status == 429 || status >= 500 {
                Log.write("analytics send failed \(status), \(queue.count) queued")
                retry?.cancel()
                retry = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(60))
                    if !Task.isCancelled { self?.flush() }
                }
                return
            }
            if status >= 300 { Log.write("analytics refused \(status), \(batch.count) dropped") }
            // Events added while the request was out sit behind the batch.
            queue.removeFirst(min(batch.count, queue.count))
            save()
        }
    }

    private func save() {
        if queue.isEmpty {
            try? FileManager.default.removeItem(at: file)
        } else if let data = try? JSONEncoder().encode(queue) {
            try? data.write(to: file, options: .atomic)
        }
    }

    /// Everything that goes over the wire. `osName` keeps the server from reading the event as a browser's; `isDebug`
    /// files Debug builds apart; the versions tell TestFlight builds apart. No locale, device or OS version.
    static func body(_ events: [Event], release: Bool = Build.release, info: [String: Any]? = Bundle.main.infoDictionary)
        -> Data {
        struct System: Encodable {
            var isDebug: Bool, osName = "iOS", appVersion: String, appBuildNumber: String, sdkVersion = "unstir@1"
        }
        struct Wire: Encodable {
            var timestamp: String, sessionId: String, eventName: String, systemProps: System, props: [String: Prop]
        }
        let system = System(isDebug: !release, appVersion: info?["CFBundleShortVersionString"] as? String ?? "",
                            appBuildNumber: info?["CFBundleVersion"] as? String ?? "")
        let time = ISO8601DateFormatter()
        let wire = events.map {
            Wire(timestamp: time.string(from: $0.time), sessionId: $0.session, eventName: $0.name, systemProps: system,
                 props: $0.props)
        }
        return (try? JSONEncoder.sorted.encode(wire)) ?? Data()
    }
}

extension JSONEncoder {
    static var sorted: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }
}
