// Copyright © 2026 Jack Lusher. All rights reserved.

import UIKit
import XCTest
@testable import Unstir

/// Requests a test's transport took, answered with `status`.
final class Wire: @unchecked Sendable {
    private let lock = NSLock()
    private var taken: [URLRequest] = []
    let status: Int

    init(status: Int = 200) { self.status = status }

    var requests: [URLRequest] { lock.withLock { taken } }

    var transport: Sender.Transport {
        { request in
            self.lock.withLock { self.taken.append(request) }
            return (Data("{}".utf8), HTTPURLResponse(url: request.url!, statusCode: self.status, httpVersion: nil,
                                                     headerFields: nil)!)
        }
    }

    /// Event names over every request, in order.
    var names: [String] {
        requests.flatMap { r -> [String] in
            let events = (try? JSONSerialization.jsonObject(with: r.httpBody ?? Data())) as? [[String: Any]] ?? []
            return events.compactMap { $0["eventName"] as? String }
        }
    }

    var sessions: [String] {
        requests.flatMap { r -> [String] in
            let events = (try? JSONSerialization.jsonObject(with: r.httpBody ?? Data())) as? [[String: Any]] ?? []
            return events.compactMap { $0["sessionId"] as? String }
        }
    }
}

@MainActor
final class AnalyticsTests: XCTestCase {
    private var defaults: UserDefaults!
    private var queue: URL!
    private let endpoint = Sender.Endpoint(key: "A-EU-0000000000")!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "AnalyticsTests")!
        defaults.removePersistentDomain(forName: "AnalyticsTests")
        queue = FileManager.default.temporaryDirectory.appending(path: "analytics-\(UUID().uuidString).json")
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: "AnalyticsTests")
        try? FileManager.default.removeItem(at: queue)
    }

    private func analytics(_ wire: Wire, stores: Bool = true) -> Analytics {
        let a = Analytics(defaults: defaults)
        a.today = { "2026-10-01" }
        a.start(.send(endpoint, queue: queue, transport: wire.transport), stores: stores)
        return a
    }

    /// Lets the sender's task run.
    private func settle(_ a: Analytics) async {
        for _ in 0..<100 where !(a.sender?.queue.isEmpty ?? true) { try? await Task.sleep(for: .milliseconds(20)) }
        try? await Task.sleep(for: .milliseconds(50))
    }

    func testNothingIsQueuedOrSentUntilYes() async {
        let wire = Wire()
        let a = analytics(wire)
        XCTAssertEqual(a.consent, .undecided)
        a.opened(today: "2026-10-01")
        a.cardSeen(.lens)
        a.purchased(Pack.lens.productID)
        a.opened(today: "2026-10-02")
        a.decide(false)
        a.opened(today: "2026-10-08")
        a.tasteFinished(.lens)
        a.phase(.background)
        a.today = { "2026-10-08" }
        await settle(a)
        XCTAssertNil(a.sender)
        XCTAssertFalse(FileManager.default.fileExists(atPath: queue.path))
        XCTAssertTrue(wire.requests.isEmpty)

        a.decide(true)
        await settle(a)
        XCTAssertEqual(wire.names, ["installed", "returned", "snapshot", "snapshot"])
        XCTAssertEqual(wire.requests.first?.value(forHTTPHeaderField: "App-Key"), "A-EU-0000000000")
        XCTAssertEqual(wire.requests.first?.url?.absoluteString, "https://eu.aptabase.com/api/v0/events")
    }

    func testSayingNoDropsWhatIsQueued() async throws {
        let wire = Wire(status: 503)
        let a = analytics(wire)
        a.decide(true)
        await settle(a)
        XCTAssertTrue(FileManager.default.fileExists(atPath: queue.path))
        // The queue outlives the app.
        let relaunched = Sender(endpoint: endpoint, file: queue, transport: Wire(status: 503).transport)
        XCTAssertEqual(relaunched.queue.map(\.name), ["installed"])

        a.decide(false)
        XCTAssertNil(a.sender)
        XCTAssertFalse(FileManager.default.fileExists(atPath: queue.path))
        XCTAssertEqual(defaults.string(forKey: "analytics.consent"), "no")
    }

    func testALaunchWithNothingDueSendsWhatWasQueued() async throws {
        let failing = Sender(endpoint: endpoint, file: queue, transport: Wire(status: 503).transport)
        failing.add(Event(name: "level", props: ["outcome": .text("solved")], time: .now,
                          session: Analytics.newSession()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: queue.path))
        // Relaunched later the same day, with the install already sent: nothing comes due.
        defaults.set("yes", forKey: "analytics.consent")
        var tally = Tally()
        _ = tally.opened(today: "2026-10-01", consented: true)
        defaults.set(try JSONEncoder().encode(tally), forKey: "analytics")
        let wire = Wire()
        let a = analytics(wire)
        await settle(a)
        XCTAssertEqual(wire.names, ["level"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: queue.path))
    }

    func testASessionEndsAfterAnHourIdle() async {
        let wire = Wire()
        let a = analytics(wire)
        a.decide(true)
        a.cardSeen(.lens)
        a.touched = .now - Analytics.idle - 60
        a.tasteFinished(.lens)
        a.cardSeen(.escapement)
        await settle(a)
        XCTAssertEqual(wire.names, ["installed", "card", "taste", "card"])
        let s = wire.sessions
        XCTAssertEqual(s.count, 4)
        XCTAssertEqual(s[0], s[1])
        XCTAssertNotEqual(s[1], s[2])
        XCTAssertEqual(s[2], s[3])
    }

    func testReturnedOncePerDay() {
        var t = Tally()
        XCTAssertEqual(t.opened(today: "2026-10-01", consented: true), [.installed(day: 1)])
        XCTAssertEqual(t.opened(today: "2026-10-01", consented: true), [])
        XCTAssertEqual(t.opened(today: "2026-10-02", consented: true), [.returned(day: 2), .snapshot(milestone: 2, day: 2)])
        XCTAssertEqual(t.opened(today: "2026-10-02", consented: true), [])
        XCTAssertEqual(t.opened(today: "2026-10-04", consented: true), [.returned(day: 4)])
        // The clock set back.
        XCTAssertEqual(t.opened(today: "2026-10-03", consented: true), [])
        XCTAssertEqual(t.opened(today: "2026-09-20", consented: true), [])
        XCTAssertEqual(t.opened(today: "2026-10-05", consented: true), [.returned(day: 5)])
        XCTAssertEqual(t.days, [1, 2, 4, 3, 5])
        // Across a month, a year and a change of clocks.
        XCTAssertEqual(Tally.number(of: "2027-01-01", from: "2026-12-31"), 2)
        XCTAssertEqual(Tally.number(of: "2026-10-26", from: "2026-10-24"), 3)
        XCTAssertNil(Tally.number(of: "garbage", from: "2026-10-24"))
    }

    func testSnapshotsComeOnceEachAtDaysTwoSevenAndThirty() {
        var t = Tally()
        var at: [Int: [Int]] = [:]
        for d in 0..<45 {
            let day = Best.day(Date(timeIntervalSince1970: 1_790_000_000 + Double(d) * 86400), in: TimeZone(identifier: "UTC")!)
            for case .snapshot(let m, let n) in t.opened(today: day, consented: true) + t.opened(today: day, consented: true) {
                at[n, default: []].append(m)
            }
        }
        XCTAssertEqual(at, [2: [2], 7: [7], 30: [30]])

        // A yes given late sends each milestone passed, once, with the day it went out on.
        var late = Tally()
        _ = late.opened(today: "2026-10-01", consented: false)
        _ = late.opened(today: "2026-10-03", consented: false)
        XCTAssertEqual(late.opened(today: "2026-10-09", consented: true),
                       [.installed(day: 9), .returned(day: 9), .snapshot(milestone: 2, day: 9),
                        .snapshot(milestone: 7, day: 9)])
        XCTAssertEqual(late.opened(today: "2026-10-09", consented: true), [])
        XCTAssertEqual(late.days, [1, 3, 9])
    }

    func testPacksSendOncePerInstall() async {
        let wire = Wire()
        let a = analytics(wire)
        a.decide(true)
        for _ in 0..<2 {
            a.cardSeen(.lens)
            a.tasteFinished(.lens)
            a.purchased(Pack.lens.productID)
            a.purchased(Pack.completeID)
            a.purchased("not.a.product")
        }
        await settle(a)
        XCTAssertEqual(wire.names, ["installed", "card", "taste", "purchased", "purchased"])
        XCTAssertEqual(a.snapshot(milestone: 2, day: 2)["lens"], .text("card,taste"))
        XCTAssertEqual(a.snapshot(milestone: 2, day: 2)["escapement"], .text("none"))
    }

    func testTheWireCarriesNoIdentifier() throws {
        let a = Analytics(defaults: defaults)
        a.start(.log, stores: false)
        let events = [
            Event(name: "snapshot", props: a.snapshot(milestone: 7, day: 9), time: .now, session: Analytics.newSession()),
            Event(name: "level", props: ["id": .text("L4"), "outcome": .text("quit"), "moves": .int(7), "par": .int(4),
                                         "undos": .int(1), "resets": .int(0)], time: .now, session: Analytics.newSession()),
        ]
        let body = Sender.body(events, release: true)
        let text = String(decoding: body, as: UTF8.self)
        XCTAssertNil(text.firstMatch(of: /[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/))
        if let vendor = UIDevice.current.identifierForVendor?.uuidString { XCTAssertFalse(text.contains(vendor)) }
        for word in ["install", "user", "device", "vendor", "identifier", "advert", "locale", "osVersion"] {
            XCTAssertFalse(text.lowercased().contains(word.lowercased()), word)
        }
        let wire = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        XCTAssertEqual(wire.count, 2)
        for event in wire {
            XCTAssertEqual(Set(event.keys), ["timestamp", "sessionId", "eventName", "systemProps", "props"])
            let system = try XCTUnwrap(event["systemProps"] as? [String: Any])
            XCTAssertEqual(Set(system.keys), ["isDebug", "osName", "appVersion", "appBuildNumber", "sdkVersion"])
            XCTAssertEqual(system["isDebug"] as? Bool, false)
            XCTAssertEqual(system["osName"] as? String, "iOS")
            // The server's limits: a key of 40 characters at most, and a string cut at 180.
            for (key, value) in try XCTUnwrap(event["props"] as? [String: Any]) {
                XCTAssertLessThanOrEqual(key.count, 40, key)
                if let s = value as? String { XCTAssertLessThanOrEqual(s.count, 180, key) }
            }
        }
        // Two sessions, so the snapshot shares none with the other row.
        XCTAssertNotEqual(wire[0]["sessionId"] as? String, wire[1]["sessionId"] as? String)
    }

    func testAHarnessedLaunchStoresNothing() async {
        let wire = Wire()
        let a = analytics(wire, stores: false)
        a.decide(true)
        a.opened(today: "2026-10-02")
        a.cardSeen(.lens)
        a.undid()
        await settle(a)
        XCTAssertFalse(wire.names.isEmpty)
        XCTAssertNil(defaults.object(forKey: "analytics"))
        XCTAssertNil(defaults.object(forKey: "analytics.consent"))

        let off = Analytics(defaults: defaults)
        off.start(env: ["UNSTIR_LEVEL": "3"], harnessed: true, key: "A-EU-0000000000")
        XCTAssertFalse(off.on)
        let keyless = Analytics(defaults: defaults)
        keyless.start(env: [:], harnessed: false, key: "")
        XCTAssertFalse(keyless.on)
        let logging = Analytics(defaults: defaults)
        logging.start(env: ["UNSTIR_ANALYTICS": "log"], harnessed: false, key: nil)
        XCTAssertTrue(logging.on)
        XCTAssertNil(logging.sender)
        XCTAssertNil(defaults.object(forKey: "analytics"))
    }

    func testAKeyNamesItsRegion() {
        XCTAssertEqual(Sender.Endpoint(key: "A-EU-1234567890")?.url.host(), "eu.aptabase.com")
        XCTAssertEqual(Sender.Endpoint(key: "A-US-1234567890")?.url.host(), "us.aptabase.com")
        XCTAssertNil(Sender.Endpoint(key: "A-SH-1234567890"))
        XCTAssertNil(Sender.Endpoint(key: "$(APTABASE_KEY)"))
        XCTAssertNil(Sender.Endpoint(key: ""))
    }

    func testAKilledLevelSendsItsQuitNextLaunch() async {
        let wire = Wire()
        let a = analytics(wire)
        a.decide(true)
        let game = Game(level: Level.plughole[3], tankTurned: true, swirled: true, bank: (10, nil))
        game.commit(rod: 0, steps: 1)
        a.suspended(game)
        XCTAssertEqual(a.tally.pending?.props["outcome"], .text("quit"))
        // Killed: the next launch reads the tally back and sends it.
        let next = analytics(wire)
        await settle(next)
        await settle(a)
        XCTAssertEqual(wire.names.filter { $0 == "level" }.count, 1)
        XCTAssertNil(next.tally.pending)

        // Back to the front instead, nothing is pending.
        a.suspended(game)
        a.resumed()
        XCTAssertNil(a.tally.pending)
    }
}
