// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import Observation
import os

/// The bests on the phone kept in step with the player's iCloud key-value store (Jack's call ICLOUD = A, round 16),
/// behind the build's ICLOUD: NO, until the App ID has iCloud's key-value storage, makes no call to the store. With it
/// YES, a plain launch reconciles the two as it starts, again whenever iCloud brings a change and after every best it
/// saves. Bests only: the undo bank and its anchor never sync, nor does anything else the game stores. The harness, the
/// test host and the editors' build never sync, nor does a phone while the developer unlock is on (Jack's call
/// icloud-editors = A, round 16), so progress made with every level open stays on that phone.
@MainActor
final class Sync {
    static let shared = Sync()

    /// Info.plist's `iCloudSync`, which the build's ICLOUD sets.
    nonisolated static let built = Bundle.main.object(forInfoDictionaryKey: "iCloudSync") as? String == "YES"
    /// The store's one key, holding every best as level id to the JSON `best.<id>` holds on the phone: the store takes
    /// at most 1024 keys, and the dailies alone add a best a day. Never rename it.
    nonisolated static let key = "bests"
    /// Bumped whenever a reconcile writes a best to the phone, so every view that read one draws again.
    nonisolated static let revision = Revision()

    /// A plain launch of a build with sync: set once, by `RootView`, from `plays(built:harnessed:env:)`.
    var plays = false
    private var started = false

    /// Whether a launch syncs: only a build with sync, and never the editors' build, the harness or the test host.
    nonisolated static func plays(built: Bool, editors: Bool = Build.editors, harnessed: Bool, env: [String: String]) -> Bool {
        built && !editors && !harnessed && env["XCTestConfigurationFilePath"] == nil
    }

    func start() {
        guard plays, !started else { return }
        started = true
        let store = NSUbiquitousKeyValueStore.default
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: store, queue: .main) { note in
            let reason = note.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
            MainActor.assumeIsolated { Sync.shared.changed(reason) }
        }
        // Writes made before the store's first download from iCloud are dropped; that download's notification
        // reconciles again, so the phone's bests still go up.
        store.synchronize()
        reconcile("launch")
    }

    /// After a best is saved on the phone.
    func saved() {
        guard started else { return }
        reconcile("best")
    }

    private func changed(_ reason: Int?) {
        switch reason {
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            Log.write("sync: over the store's quota")
        case NSUbiquitousKeyValueStoreAccountChange:
            // A new account's store: the phone's bests are kept and merged into it, never dropped.
            reconcile("account")
        case NSUbiquitousKeyValueStoreInitialSyncChange:
            reconcile("first download")
        default:
            reconcile("change")
        }
    }

    private func reconcile(_ why: String) {
        let (took, sent) = Self.reconcile(NSUbiquitousKeyValueStore.default, UserDefaults.standard)
        guard took + sent > 0 else { return }
        Log.write("sync (\(why)): took \(took), sent \(sent)")
        if took > 0 { Self.revision.bump() }
    }

    /// Whether `a` replaces `b` on the other side, by the rank `Best.save` keeps (`Best.standing`): as on one phone the
    /// archive replays a day kept on its day as practice, a synced archive solve never moves `Daily.run`. A tie keeps
    /// `b`, the one that side already holds.
    nonisolated static func beats(_ a: Best, _ b: Best) -> Bool { a.standing < b.standing }

    /// What each side takes from the other: every id whose best there beats its own, or that it lacks.
    nonisolated static func merge(local: [String: Best], cloud: [String: Best])
        -> (local: [String: Best], cloud: [String: Best]) {
        (cloud.filter { id, c in local[id].map { beats(c, $0) } ?? true },
         local.filter { id, l in cloud[id].map { beats(l, $0) } ?? true })
    }

    /// Merges the phone's bests (`best.<id>` in `defaults`' `domain`) with the store's both ways and returns how many
    /// each took. Only the domain's stored values, never registered ones, which are the harness's for one launch. A
    /// best the phone takes is stored as the store's own bytes, and a store entry this build can't read is never
    /// written over, so a later version's fields survive an older one's reconcile. While the domain holds the developer
    /// unlock (`Best.unlocked`), nothing is read from the store or written to either side: bests made with it on are
    /// sent with the rest by the first reconcile after it is cleared.
    @discardableResult
    nonisolated static func reconcile(_ cloud: Cloud, _ defaults: UserDefaults,
                                      domain: String = Bundle.main.bundleIdentifier ?? "") -> (took: Int, sent: Int) {
        let phone = defaults.persistentDomain(forName: domain) ?? [:]
        guard phone[Best.unlockKey] as? Bool != true else { return (0, 0) }
        let stored = cloud.dictionary(forKey: key) ?? [:]
        let remote = stored.compactMapValues { ($0 as? Data).flatMap(Best.decode) }
        var local = [String: Best]()
        for (k, v) in phone where k.hasPrefix("best.") {
            if let best = (v as? Data).flatMap(Best.decode) { local[String(k.dropFirst("best.".count))] = best }
        }
        let (take, all) = merge(local: local, cloud: remote)
        let send = all.filter { stored[$0.key] == nil || remote[$0.key] != nil }
        for id in take.keys { defaults.set(stored[id], forKey: "best.\(id)") }
        if !send.isEmpty {
            var next = stored
            for (id, best) in send { next[id] = try? JSONEncoder().encode(best) }
            cloud.set(next, forKey: key)
        }
        return (take.count, send.count)
    }

    /// A counter views observe through `Best.load`, which any thread may call: the store's changes land on the
    /// phone outside any view's own state, so a row that reads a best draws again when one does.
    final class Revision: Observable, Sendable {
        private let registrar = ObservationRegistrar()
        private let value = OSAllocatedUnfairLock(initialState: 0)

        var count: Int {
            registrar.access(self, keyPath: \.count)
            return value.withLock { $0 }
        }

        func bump() {
            registrar.withMutation(of: self, keyPath: \.count) { value.withLock { $0 += 1 } }
        }
    }
}

/// The key-value store's calls `Sync.reconcile` makes, so the tests reconcile against a dictionary.
protocol Cloud: AnyObject {
    func dictionary(forKey key: String) -> [String: Any]?
    func set(_ value: Any?, forKey key: String)
}

extension NSUbiquitousKeyValueStore: Cloud {}
