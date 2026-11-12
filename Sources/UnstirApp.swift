// Copyright © 2026 Jack Lusher. All rights reserved.

import StoreKit
import SwiftUI

@main
struct UnstirApp: App {
    init() {
        // No uptime: the log can leave the phone, and its time stamp less the uptime is the boot's instant.
        Log.write("launch, boot session \(Best.bootSession == nil ? "unread" : "read")")
    }

    /// What a sent log needs to say about where it came from, and nothing about whose phone it is. Read once the
    /// first screen is up: the type size is unset before then.
    static var device: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let os = ProcessInfo.processInfo.operatingSystemVersion
        var machine = utsname()
        uname(&machine)
        let model = withUnsafeBytes(of: &machine.machine) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
        let type = UIApplication.shared.preferredContentSizeCategory.rawValue.replacingOccurrences(of: "UICTContentSizeCategory", with: "")
        return "device: app \(info["CFBundleShortVersionString"] ?? "?") (\(info["CFBundleVersion"] ?? "?")), iOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion), "
            + "\(model), \(Locale.current.identifier), type \(type), reduce motion \(UIAccessibility.isReduceMotionEnabled), "
            + "voiceover \(UIAccessibility.isVoiceOverRunning), low power \(ProcessInfo.processInfo.isLowPowerModeEnabled), "
            + Settings.summary + ", taps \(Taps.shared.summary)"
    }

    var body: some Scene {
        WindowGroup {
            if GPUBench.wanted {
                GPUBenchView()
            } else if let window = HarnessWindow.wanted {
                HarnessWindow(window, content: RootView())
            } else {
                RootView()
            }
        }
    }
}

/// Launch-time state for screenshots without touch (set via SIMCTL_CHILD_UNSTIR_*).
struct Harness {
    let screen: String
    let level: Level
    let live: (rod: Int, steps: Double)?
    /// UNSTIR_TANK=n: the tank turned n steps, through the real path.
    let tank: Int
    /// UNSTIR_TANKLIVE=degrees: a turn of the tank held mid-drag, on top of UNSTIR_TANK.
    let tankLive: Double?
    /// UNSTIR_TOUCH=x,y: a finger down at that point of the tank (tank units, y down), not yet moved; with UNSTIR_LIVE or
    /// UNSTIR_TANKLIVE, where it went down before carrying the turn round.
    let touch: SIMD2<Double>?
    /// UNSTIR_TURNED=rod:steps: a turn committed through the real path and left open, as a finger has just let it go.
    let turned: Twist?
    /// UNSTIR_TANKTURNED=1: the player has turned the tank before, so the rim no longer shows how; unset, they never have.
    /// Either way for this launch only, whatever the harness turns. Nil without the harness, which reads and stores the
    /// real flag.
    let tankTurned: Bool?
    /// UNSTIR_SWIRLED=1: likewise for the swirl.
    let swirled: Bool?
    /// UNSTIR_SHAKE=s: with UNSTIR_TOUCH on a seized knob, its shake and the rim's pulse held s seconds in.
    let shake: Double?
    /// UNSTIR_UNDOS=n: the undo bank, and the stored day of its last refill, for this launch only. A harnessed launch
    /// reads the stored bank unless set, and never stores either, nor the refill's anchor, which starts afresh. With
    /// UNSTIR_TODAY and no day stored, as on the shots' fresh install, the last refill was long ago, so the level opens
    /// on a refill. Nil without the harness, which reads and stores the real ones.
    let bank: (undos: Int, refilled: String?)?
    /// UNSTIR_TODAY=yyyy-MM-dd: the day the level opens on, for the bank's refill.
    let today: String?
    /// UNSTIR_NOW=HH:mm: the daily's result card reads the next daily from that time today.
    let now: Date?
    /// UNSTIR_DAILY=yyyymmdd: the day the daily is dealt for, the menu's row and UNSTIR_MODE=daily's level, at noon.
    let day: Date?
    /// Skip the opening so shots land on a settled tank; UNSTIR_OPEN=1 (or v1's UNSTIR_STIR=1) keeps it.
    let still: Bool
    let autoplay: Bool
    /// UNSTIR_PACE=s: autoplay and UNSTIR_MOVES wait this long before each move (0.3 s unset).
    let pace: Double
    /// UNSTIR_BARE=1: the picture drawn unstirred whatever the stack, so a still shows a story's art as the stack has
    /// played it.
    let bare: Bool
    /// UNSTIR_CLEAN=1: a level drawn as its glass and picture alone, every control, count, line and fingertip hidden
    /// and the status bar too, for App Store art that may show no interface.
    let clean: Bool
    /// UNSTIR_ENDING=s: First Stir's last scene opens solved with the night forwards held s seconds in, or running from
    /// the start at -1, for films. Needs UNSTIR_SCREEN=clean.
    let ending: Double?
    /// UNSTIR_MOVES=-1:-1,1:-8: these moves played in order, each a knob's turn or the tank's (rod -1, as `Game.history`
    /// names it), as solve.sh prints a line. A ratchet's turn is a tap on it, a wait; with UNSTIR_FINGER, any turn of it
    /// but 1 taps halfway out the clock's disc instead. A turn of the open stir's knob takes it up again. `u` is an undo
    /// through the control, with its sound, `w` a wait through Escapement's wait control, and `p<s>` rests s seconds more
    /// before the next step.
    let moves: [Step]?
    enum Step: Equatable { case twist(Twist), undo, wait, rest(Double) }
    /// UNSTIR_PLAYED=2:4,0:1: a line in UNSTIR_MOVES's form, committed through the real path as the level opens, so a
    /// still shows the tank part way through it.
    let played: [Twist]
    /// UNSTIR_FINGER=1: with UNSTIR_MOVES, a hand's pace instead, each move a fingertip drawn landing where the grab rule
    /// gives it the move's rod or the rim, carried round with the turn and lifted, for films.
    let finger: Bool
    /// UNSTIR_REST=s: with UNSTIR_FINGER, the seconds at rest before the first fingertip lands (2 when unset).
    let rest: Double
    /// UNSTIR_TURN=s: with UNSTIR_FINGER, the seconds a knob's turn takes a step (0.1 unset), for reading a slow drag.
    let turn: Double
    /// UNSTIR_BREATH=s: on a layout with a swirl, its breath held s seconds into the tank's first rest. Unset, it runs
    /// live, or not at all while UNSTIR_CLOCK holds the clock. Never with UNSTIR_SWIRLED=1.
    let breath: Double?
    /// UNSTIR_BRIMDEMO=1: endless plays the approved film's run of the brim, two heals and then pushes until it spills.
    let brimDemo: Bool
    /// UNSTIR_RESETARMED=1: the reset control held armed by a first tap, "reset? tap again", for stills.
    let resetArmed: Bool
    /// UNSTIR_SHARESHEET=1: the daily's share sheet open over its result card, as its share button opens it.
    let shareSheet: Bool
    /// UNSTIR_REVIEW=log: the rating request is logged instead of made, as an unharnessed launch would make it.
    let reviewLog: Bool
    let bench: Bool
    /// UNSTIR_TAPDRAG=n: once the tank is the player's, n drags of a knob drawn through the real let-go, each landing a
    /// move, for `Taps` on the phone.
    let tapDrags: Int?
    /// UNSTIR_SWATCH=r, g or b: Prism's swatch for that channel held. UNSTIR_LETTERS=1: Prism with the colour letters,
    /// its knobs spelling out their channels over the swatches, whatever the settings say. UNSTIR_LETTERSCHOICE=0 or 1:
    /// the settings' colour letters chosen off or on, for this launch only (`switches`).
    let swatch: Channels?
    let letters: Bool
    /// UNSTIR_WAVE=r: solve, or play UNSTIR_PLAYED, then hold the solve wave at radius r (tank units).
    let wave: Double?
    /// UNSTIR_CLOCK=s: hold a live picture s seconds in, or endless's brim s seconds after its last change. It also stills
    /// the swirl's breath, so a shot on a layout with a swirl that sets none of this, UNSTIR_BREATH and UNSTIR_SWIRLED=1
    /// may catch a slosh.
    let clock: Double?
    /// UNSTIR_TOUR: menu, then level 01, then back, for filming the cross-fades.
    let tour: Bool
    /// UNSTIR_EXIT=left: the level, once open, left for the menu by "‹ levels"; =solved, as from its result card after
    /// a solve; =up, its tier's next tier's first level opened, as "up a notch" opens it, and that one left; =swipe,
    /// left through the back swipe's commit, sliding off over the menu.
    let exit: String?
    /// UNSTIR_BACKSWIPE=0.4: the level held that share of the way into a back swipe, the menu under it; =run, the
    /// swipe played a second in by a drawn fingertip and let go.
    let backSwipe: Double?
    let backSwipeRun: Bool
    /// UNSTIR_LOCKTAP=L8: on the menu, that locked row held as a tap leaves it, saying what opens it.
    let lockTap: String?
    /// UNSTIR_PICK=L12: a second and a half in, that level (a tier's or a pack's, by id) picked as its row in the menu
    /// picks it; beside play, the playing level leaves for it. The harness's other flags carry over to it.
    /// UNSTIR_PICK=archive opens the archive then, as its row does.
    let pick: Level?
    let pickArchive: Bool
    /// UNSTIR_FRESH=1: the launch takes a plain launch's first screen as a fresh install would, into plughole 01, and
    /// stores nothing of it.
    let fresh: Bool
    /// UNSTIR_TIER=whirlpool: the tier the menu opens on, locked or not, plughole when unset. Nil on a launch without
    /// the harness, which opens on the stored tier.
    let menuTier: Tier?
    /// UNSTIR_TIERDEMO: the menu switches tiers on a timer, through the calls a finger makes.
    let tierDemo: Bool
    /// UNSTIR_TIERSPIN=angle[:fade]: the menu's list held mid-twist.
    let tierSpin: (spin: Double, fade: Double)?
    /// UNSTIR_ARCHIVE=1: the menu opens with the archive's calendar up.
    let archive: Bool
    /// UNSTIR_SETTINGS=1: the menu opens with the gear's sheet up. UNSTIR_CONSENT is read by `Analytics.configure`.
    let settings: Bool
    /// UNSTIR_MUSIC=0, UNSTIR_SOUNDS=0, UNSTIR_HAPTICS=0 and UNSTIR_SUPPORTER=0: the sheet's switches off, with
    /// UNSTIR_LETTERSCHOICE, for `Settings.held`. A harnessed launch's switches start on and unchosen whatever is
    /// stored, and a tap on one lasts only that launch; nil on a plain launch.
    let switches: [String: Bool]?
    /// UNSTIR_OWNED and UNSTIR_STORE, in place of StoreKit's for this launch; never stored, and nil in Release.
    let purchases: Ledger?

    /// UNSTIR_OWNED=lens,escapement (or complete): those owned. UNSTIR_STORE=lens:pending,complete:revoked: each
    /// product (a pack's prefix, or complete) in that `Purchase` state, or `unshared`, revoked as a family's share. Nil in Release or with neither set.
    static func purchases(_ env: [String: String], release: Bool = Build.release) -> Ledger? {
        guard !release, env["UNSTIR_OWNED"] != nil || env["UNSTIR_STORE"] != nil else { return nil }
        func product(_ name: Substring) -> String? {
            name == "complete" ? Pack.completeID : Pack(rawValue: String(name))?.productID
        }
        var ledger = Ledger()
        for name in env["UNSTIR_OWNED"]?.split(separator: ",") ?? [] {
            if let id = product(name) { ledger.record(id, .owned) }
        }
        for part in env["UNSTIR_STORE"]?.split(separator: ",") ?? [] {
            let f = part.split(separator: ":")
            if f.count == 2, let id = product(f[0]), f[1] == "unshared" {
                ledger.record(id, .revoked, shared: true)
            } else if f.count == 2, let id = product(f[0]), let state = Purchase(rawValue: String(f[1])) {
                ledger.record(id, state)
            }
        }
        return ledger
    }

    /// With `purchases`, the prices StoreKit/Unstir.storekit sets, as the App Store would show them on a US storefront;
    /// none with UNSTIR_PRICES=0, as before StoreKit answers, or UNSTIR_PRICES=unreachable, after its fetch failed.
    let prices: [String: String]
    /// The same prices as numbers, for Complete's saving.
    let amounts: [String: Decimal]
    let pricing: Pricing
    /// UNSTIR_FAILED=offline (storefront, refused): why each failed product failed, or each pending one's ask again.
    let failure: Failure
    /// UNSTIR_PAYMENTS=0: purchases turned off on the device.
    let canPay: Bool
    /// UNSTIR_RESTORED=lens,prism (none, failed): what the last restore found.
    let restored: Restored?
    /// UNSTIR_APPROVED=lens (or complete): with the store's states set, that offer's Ask to Buy approval waits to be said.
    let approved: [Offer]
    /// UNSTIR_STORE=...,unread: with the store's states set, the launch's first read of the entitlements never ends.
    let unread: Bool

    /// UNSTIR_STOPLOOK=left: what an Escapement tank lost to its last clock stopping shows (`StopLook`), stamp unset.
    let stopLook: StopLook?

    /// UNSTIR_ICON=n: app-icon candidate n alone on the screen (`IconView`).
    let icon: Int?
    /// UNSTIR_CARD=lens (a pack's prefix, or complete): that pack's card open over the menu.
    let card: Offer?
    /// UNSTIR_CARDLEVELS=n: in Debug, the card lists n placeholder levels while its pack has none.
    let cardLevels: Int
    /// UNSTIR_SHELFDEMO=1: the menu opens Lens's card from the dock and closes it, through the calls a finger makes.
    let shelfDemo: Bool
    /// UNSTIR_CARDSCROLL=1: with UNSTIR_CARD, the card opens scrolled to its list of levels.
    let cardScroll: Bool
    /// UNSTIR_LANDS=s: with UNSTIR_CARD and the store's states set, the card's product is bought s seconds in.
    let lands: Double?
    /// UNSTIR_PROMOTED=lens (a pack's prefix, or complete): a second in, a purchase of it started on the App Store's
    /// product page; with the store's states set, it lands in them.
    let promoted: Offer?
    /// UNSTIR_PROMO=lens (a pack's prefix, or complete): that offer's promoted-purchase image alone, 1024 px square at the
    /// screen's centre, for scripts/promo.sh.
    let promo: Offer?
    /// UNSTIR_TYPESIZE=accessibility3: Dynamic Type at that size (a `DynamicTypeSize` case), whatever the device's.
    let typeSize: DynamicTypeSize?
    /// Any UNSTIR_ variable but UNSTIR_UNLOCK and UNSTIR_ANALYTICS: analytics is then off unless UNSTIR_ANALYTICS=log
    /// logs it, and stores nothing either way.
    let harnessed: Bool
    let resume: Resume?
    /// Shots, films, the bench and the test host play no sound unless UNSTIR_SOUND=1. Not stored, so the next launch on
    /// the phone sounds; UNSTIR_UNLOCK alone is a phone launch.
    let mute: Bool

    init(_ env: [String: String]) {
        // UNSTIR_LEVEL counts in UNSTIR_TIER too.
        let tier = env["UNSTIR_TIER"].flatMap(Tier.init(rawValue:)) ?? .plughole
        // UNSTIR_UNLOCK on its own is for the phone: =1 stores the developer unlock, =0 clears it, and the launch is
        // otherwise a plain one. Alongside any other UNSTIR_ variable, unset clears it too, so no shot leaves the next
        // one unlocked. UNSTIR_ANALYTICS and UNSTIR_TAPS are for the phone too, and leave the launch a plain one.
        let harnessed = env.keys.contains { $0.hasPrefix("UNSTIR_") && !["UNSTIR_UNLOCK", "UNSTIR_ANALYTICS", "UNSTIR_TAPS"].contains($0) }
        self.harnessed = harnessed
        if harnessed || env["UNSTIR_UNLOCK"] != nil { Best.unlocked = env["UNSTIR_UNLOCK"] == "1" }
        menuTier = harnessed ? tier : nil
        // UNSTIR_BESTS=plughole:00-1,whirlpool:0,lens:000: a best for each of a tier's or a pack's levels from 01, one
        // character each: a digit is that many over par, c clean, - is none. For this launch only.
        for part in env["UNSTIR_BESTS"]?.split(separator: ",") ?? [] {
            let f = part.split(separator: ":")
            // endless:9: the run's best, 9 tanks.
            if f.count == 2, f[0] == "endless", let n = Int(f[1]) { UserDefaults.standard.register(defaults: ["endless.tanks": n]) }
            guard f.count == 2, let levels = Tier(rawValue: String(f[0]))?.levels ?? Pack(rawValue: String(f[0]))?.levels
            else { continue }
            for (level, c) in zip(levels, f[1]) {
                if c == "c" { Best(over: 0, seconds: 60, clean: true).fake(level.id) }
                if let over = c.wholeNumberValue { Best(over: over, seconds: 60).fake(level.id) }
            }
        }
        // UNSTIR_TRIED=L14,lens-2: those levels started, for this launch only.
        for id in env["UNSTIR_TRIED"]?.split(separator: ",") ?? [] { Best.start(String(id), store: false) }
        // UNSTIR_DAILIES=n: today's daily and the n-1 days before it solved at par, for this launch only.
        let calendar = Calendar(identifier: .gregorian)
        for k in 0 ..< max(env["UNSTIR_DAILIES"].flatMap(Int.init) ?? 0, 0) {
            if let day = calendar.date(byAdding: .day, value: -k, to: .now) { Best(over: 0, seconds: 60).fake(Level.dailyID(day)) }
            // A daily solved was opened, so the modes' rows are no longer new.
            Best.seeModes(store: false)
        }
        fresh = env["UNSTIR_FRESH"] == "1"
        tierDemo = env["UNSTIR_TIERDEMO"] == "1"
        let spin = env["UNSTIR_TIERSPIN"]?.split(separator: ":").compactMap { Double($0) } ?? []
        tierSpin = spin.first.map { ($0, spin.count > 1 ? spin[1] : 0) }
        settings = env["UNSTIR_SETTINGS"] == "1"
        archive = env["UNSTIR_ARCHIVE"] == "1"
        // UNSTIR_ARCHIVED=1:c,3:0,6:2,9:t: the daily that many days before today kept a best from the archive, clean,
        // that many over par, or only tried, for this launch only.
        for part in env["UNSTIR_ARCHIVED"]?.split(separator: ",") ?? [] {
            let f = part.split(separator: ":")
            guard f.count == 2, let k = Int(f[0]), let day = calendar.date(byAdding: .day, value: -k, to: .now) else { continue }
            let id = Level.dailyID(day)
            if f[1] == "t" { Best.start(id, store: false) } else if f[1] == "c" {
                Best(over: 0, seconds: 60, clean: true, archived: true).fake(id)
            } else if let over = Int(f[1]) {
                Best(over: over, seconds: 60, archived: true).fake(id)
            }
        }
        bench = env["UNSTIR_BENCH"] == "1"
        tapDrags = env["UNSTIR_TAPDRAG"].flatMap(Int.init)
        swatch = env["UNSTIR_SWATCH"].flatMap { $0.count == 1 ? Channels(letter: $0.first!) : nil }
            .flatMap { Channels.each.contains($0) ? $0 : nil }
        letters = env["UNSTIR_LETTERS"] == "1"
        if harnessed {
            var held = ["music", "sounds", "haptics", "supporter"].reduce(into: [String: Bool]()) {
                $0[$1] = env["UNSTIR_\($1.uppercased())"] != "0" // loc: verbatim an environment key
            }
            if let c = env["UNSTIR_LETTERSCHOICE"], ["0", "1"].contains(c) { held["letters"] = c == "1" }
            switches = held
        } else {
            switches = nil
        }
        wave = env["UNSTIR_WAVE"].flatMap(Double.init)
        clock = env["UNSTIR_CLOCK"].flatMap(Double.init)
        tour = env["UNSTIR_TOUR"] == "1"
        lockTap = env["UNSTIR_LOCKTAP"]
        pickArchive = env["UNSTIR_PICK"] == "archive"
        pick = env["UNSTIR_PICK"].flatMap { id in (Tier.allCases.flatMap(\.levels) + Pack.allCases.flatMap(\.levels)).first { $0.id == id } }
        exit = env["UNSTIR_EXIT"].flatMap { ["left", "solved", "up", "swipe"].contains($0) ? $0 : nil }
        backSwipe = env["UNSTIR_BACKSWIPE"].flatMap(Double.init).map { min(max($0, 0), 1) }
        backSwipeRun = env["UNSTIR_BACKSWIPE"] == "run"
        stopLook = env["UNSTIR_STOPLOOK"].flatMap(StopLook.init(rawValue:))
        purchases = Harness.purchases(env)
        amounts = ["0", "unreachable"].contains(env["UNSTIR_PRICES"]) ? [:]
            : Dictionary(uniqueKeysWithValues: Pack.productIDs.map { ($0, Decimal(string: $0 == Pack.completeID ? "5.99" : "2.99")!) })
        prices = amounts.mapValues { "$\($0)" }
        pricing = env["UNSTIR_PRICES"] == "unreachable" ? .unreachable : amounts.isEmpty ? .fetching : .fetched
        failure = env["UNSTIR_FAILED"].flatMap(Failure.init(rawValue:)) ?? .other
        canPay = env["UNSTIR_PAYMENTS"] != "0"
        restored = switch env["UNSTIR_RESTORED"] {
        case nil: nil
        case "none": .nothing
        case "failed": .failed
        case let names?: .found(Set(names.split(separator: ",").compactMap { Pack(rawValue: String($0)) }))
        }
        approved = env["UNSTIR_APPROVED"]?.split(separator: ",").compactMap { Offer(name: String($0)) } ?? []
        unread = env["UNSTIR_STORE"]?.split(separator: ",").contains("unread") ?? false
        // UNSTIR_SEENLEVELS=lens:20: that pack's card last opened when the pack had 20 levels, for this launch only.
        for part in env["UNSTIR_SEENLEVELS"]?.split(separator: ",") ?? [] {
            let f = part.split(separator: ":")
            if f.count == 2, let pack = Pack(rawValue: String(f[0])), let n = Int(f[1]) {
                UserDefaults.standard.register(defaults: [Marks.levelsKey(pack): n])
            }
        }
        let opensLevel = bench || ["LEVEL", "MODE", "STACK", "WAVE", "PACK"].contains { env["UNSTIR_\($0)"] != nil }
        screen = env["UNSTIR_SCREEN"] ?? (opensLevel ? "level" : "menu")
        day = env["UNSTIR_DAILY"].flatMap(Int.init).flatMap {
            calendar.date(from: DateComponents(year: $0 / 10000, month: $0 / 100 % 100, day: $0 % 100, hour: 12))
        }
        let n = min(max(Int(env["UNSTIR_LEVEL"] ?? "") ?? 1, 1), tier.levels.count)
        var level = switch env["UNSTIR_MODE"] ?? env["UNSTIR_LEVEL"] {
        // UNSTIR_DAILY=yyyymmdd: that day's daily, as played on its day.
        case "daily": Level.daily(day ?? .now)
        // UNSTIR_DAY=n: the daily n days back, from the archive; yesterday's when unset.
        case "archive": Level.daily(calendar.date(byAdding: .day, value: -max(Int(env["UNSTIR_DAY"] ?? "") ?? 1, 1),
                                                      to: .now)!, archived: true)
        // UNSTIR_BRIM=n: endless opens with n notches on the brim, short of the spill, which only a push may bring.
        // UNSTIR_RESUMETANK=n, with UNSTIR_RESUME: on the run's tank n, from 0.
        case "endless": Level.endless(Run(seed: 7, tank: env["UNSTIR_RESUME"] == nil ? 0 : max(Int(env["UNSTIR_RESUMETANK"] ?? "") ?? 0, 0),
                                          brim: min(max(Int(env["UNSTIR_BRIM"] ?? "") ?? 0, 0), Run.room - 1)))
        case "sandbox": Level.sandbox
        default: tier.levels[n - 1]
        }
        #if DEBUG
        // UNSTIR_PACK=lens: that pack's level UNSTIR_LEVEL, a placeholder past the levels it has.
        if let pack = env["UNSTIR_PACK"].flatMap(Pack.init(rawValue:)) {
            let number = max(Int(env["UNSTIR_LEVEL"] ?? "") ?? 1, 1)
            level = pack.levels.indices.contains(number - 1) ? pack.levels[number - 1] : pack.placeholder(number)
        }
        #endif
        let picture = env["UNSTIR_PICTURE"].flatMap(Picture.init(rawValue:))
        if bench {
            // UNSTIR_DEPTH overrides. A live picture's heaviest frame is the most entries that keep four taps, and the drag.
            let p = picture ?? tier.levels[0].picture
            let depth = env["UNSTIR_DEPTH"].flatMap(Int.init) ?? (p.isLive ? min(Tank.fourTaps - p.fillEntries, Tank.maxStack) : 24)
            var rng = SplitMix64(state: 24)
            level = Level(id: "bench", tier: tier, label: "bn", title: "Bench: mixed sizes, depth \(depth)", picture: p,
                          layout: .eye, scramble: Layout.eye.scramble(depth: depth, inversions: 6, rng: &rng))
        }
        if let picture { level.picture = picture }
        if env["UNSTIR_STACK"] != nil {
            level.layout = env["UNSTIR_LAYOUT"].flatMap(Layout.init(rawValue:)) ?? level.layout
        }
        // UNSTIR_LENSES=0,2: those slots lenses, never the swirl; they change how UNSTIR_STACK merges as it is parsed.
        if let s = env["UNSTIR_LENSES"] {
            level.lenses = Set(s.split(separator: ",").compactMap { Int($0) }
                .filter { level.layout.rods.indices.contains($0) && $0 != level.layout.swirl })
        }
        // UNSTIR_MASKS=0:r,1:c: Prism's channels by slot, which change how UNSTIR_STACK merges as the lenses do.
        if let m = env["UNSTIR_MASKS"].flatMap(Channels.masks) {
            level.masks = m.filter { level.layout.rods.indices.contains($0.key) && $0.key != level.layout.swirl }
        }
        if let s = env["UNSTIR_STACK"] {
            level.scramble = .parse(s, in: level.layout, lenses: level.lenses, masks: level.masks)
        }
        // UNSTIR_DEEP=n: the level's stack cut, or repeated as it stands, to n entries, at most a full stack: no commit
        // merges where the copies meet, so it may be a stack no play reaches.
        if let n = env["UNSTIR_DEEP"].flatMap(Int.init), !level.scramble.isEmpty {
            var deep = level.scramble
            while deep.count < min(n, Tank.maxStack) { deep += level.scramble }
            level.scramble = Array(deep.prefix(min(n, Tank.maxStack)))
        }
        // UNSTIR_PAR=n: a stack's own par, where turning the tank costs moves its entry count misses.
        if let n = env["UNSTIR_PAR"].flatMap(Int.init) { level.fixedPar = n }
        // UNSTIR_SEIZED=1,4: those knobs seized on a turning tank, never the swirl, which has no knob.
        if let s = env["UNSTIR_SEIZED"] {
            level.seized = Set(s.split(separator: ",").compactMap { Int($0) }
                .filter { level.layout.rods.indices.contains($0) && $0 != level.layout.swirl })
            level.motion = level.seized.isEmpty ? .none : .tank
        }
        self.level = level
        // UNSTIR_RESUME=0:+2,1:-3,u: the level's try saved with that line, the launch's only save. Empty, with endless,
        // the run saved on its tank with no move yet.
        resume = env["UNSTIR_RESUME"].map {
            Resume(id: level.id, print: level.print, firstTry: true, actions: Resume.actions($0, on: level), run: level.run)
        }
        // A run saved was opened, so the modes' rows are no longer new.
        if resume?.run != nil { Best.seeModes(store: false) }
        tank = env["UNSTIR_TANK"].flatMap(Int.init) ?? 0
        tankLive = env["UNSTIR_TANKLIVE"].flatMap(Double.init)
        let xy = env["UNSTIR_TOUCH"]?.split(separator: ",").compactMap { Double($0) } ?? []
        touch = xy.count == 2 ? SIMD2(xy[0], xy[1]) : nil
        let t = env["UNSTIR_TURNED"]?.split(separator: ":").compactMap { Int($0) } ?? []
        turned = t.count == 2 && level.layout.rods.indices.contains(t[0]) ? Twist(rod: t[0], steps: t[1]) : nil
        tankTurned = harnessed ? env["UNSTIR_TANKTURNED"] == "1" : nil
        swirled = harnessed ? env["UNSTIR_SWIRLED"] == "1" : nil
        shake = env["UNSTIR_SHAKE"].flatMap(Double.init)
        today = env["UNSTIR_TODAY"].flatMap { $0.wholeMatch(of: /\d{4}-\d{2}-\d{2}/) == nil ? nil : $0 }
        let hm = env["UNSTIR_NOW"]?.split(separator: ":").compactMap { Int($0) } ?? []
        now = hm.count == 2 ? Calendar(identifier: .gregorian).date(bySettingHour: hm[0], minute: hm[1], second: 0, of: .now) : nil
        let undos = env["UNSTIR_UNDOS"].flatMap(Int.init).map { min(max($0, 0), 10) } ?? Best.undos
        bank = harnessed ? (undos, Best.refilled ?? (today == nil ? nil : "0000-00-00")) : nil
        let f = env["UNSTIR_LIVE"]?.split(separator: ":") ?? []
        if f.count == 2, let rod = Int(f[0]), level.layout.rods.indices.contains(rod), let steps = Double(f[1]) {
            live = (rod, steps)
        } else {
            live = nil
        }
        still = harnessed && env["UNSTIR_OPEN"] != "1" && env["UNSTIR_STIR"] != "1"
        autoplay = env["UNSTIR_AUTOPLAY"] == "1"
        pace = env["UNSTIR_PACE"].flatMap(Double.init) ?? 0.3
        bare = env["UNSTIR_BARE"] == "1"
        clean = harnessed && env["UNSTIR_CLEAN"] == "1"
        ending = env["UNSTIR_ENDING"].flatMap(Double.init)
        func line(_ line: String) -> [Twist] {
            line.split(separator: ",").compactMap { move in
                let f = move.split(separator: ":").compactMap { Int($0) }
                return f.count == 2 && f[1] != 0 ? Twist(rod: f[0], steps: f[1]) : nil
            }
        }
        moves = env["UNSTIR_MOVES"].map { line in
            line.split(separator: ",").compactMap { step -> Step? in
                if step == "u" { return .undo }
                if step == "w" { return .wait }
                if step.first == "p" { return Double(step.dropFirst()).map(Step.rest) }
                let f = step.split(separator: ":").compactMap { Int($0) }
                return f.count == 2 && f[1] != 0 ? .twist(Twist(rod: f[0], steps: f[1])) : nil
            }
        }
        played = env["UNSTIR_PLAYED"].map(line) ?? []
        finger = env["UNSTIR_FINGER"] == "1"
        rest = env["UNSTIR_REST"].flatMap(Double.init) ?? 2
        turn = env["UNSTIR_TURN"].flatMap(Double.init) ?? 0.1
        breath = env["UNSTIR_BREATH"].flatMap(Double.init)
        brimDemo = env["UNSTIR_BRIMDEMO"] == "1"
        resetArmed = env["UNSTIR_RESETARMED"] == "1"
        icon = env["UNSTIR_ICON"].flatMap(Int.init)
        shareSheet = env["UNSTIR_SHARESHEET"] == "1"
        reviewLog = env["UNSTIR_REVIEW"] == "log"
        card = env["UNSTIR_CARD"].flatMap(Offer.init(name:)).flatMap { $0.sold ? $0 : nil }
        cardScroll = env["UNSTIR_CARDSCROLL"] == "1"
        lands = env["UNSTIR_LANDS"].flatMap(Double.init)
        promoted = env["UNSTIR_PROMOTED"].flatMap(Offer.init(name:))
        promo = env["UNSTIR_PROMO"].flatMap(Offer.init(name:))
        cardLevels = env["UNSTIR_CARDLEVELS"].flatMap(Int.init).map { min(max($0, 0), 30) } ?? 0
        shelfDemo = env["UNSTIR_SHELFDEMO"] == "1"
        typeSize = env["UNSTIR_TYPESIZE"].flatMap { s in DynamicTypeSize.allCases.first { "\($0)" == s } }
        mute = (harnessed || env.keys.contains { $0.hasPrefix("XCTest") }) && env["UNSTIR_SOUND"] != "1"
    }
}

/// UNSTIR_FRAME=951x669 lays the app out in a window of that size, shrunk to fit the simulator, with UNSTIR_INSETS
/// (top,leading,bottom,trailing points) as its safe area: the iPhone Duo's inner display, which no simulator can be
/// driven to headlessly. UNSTIR_FOLD=x,y,w,h (window points) folds it there, as the system's division region would, and
/// draws the fold as a band. UNSTIR_THEN=s changes pose s seconds in, to UNSTIR_THENFRAME, UNSTIR_THENINSETS and
/// UNSTIR_THENFOLD (each the first pose's unless given; UNSTIR_THENFOLD=none lies it flat), as opening, closing or
/// folding the phone would. It shows Unstir's own layout, not the system's bars.
struct HarnessWindow: View {
    struct Pose {
        let size: CGSize
        let insets: EdgeInsets
        let fold: CGRect?
    }

    let poses: [Pose]
    /// When the second pose comes, in seconds.
    let then: Double?
    let content: AnyView
    @State private var at = 0

    struct Spec {
        let poses: [Pose]
        let then: Double?
    }

    static let wanted: Spec? = {
        let env = ProcessInfo.processInfo.environment
        func numbers(_ key: String, _ by: Character) -> [Double]? {
            env[key].map { $0.split(separator: by).compactMap { Double($0) } }
        }
        guard let f = numbers("UNSTIR_FRAME", "x"), f.count == 2 else { return nil }
        func insets(_ i: [Double]?) -> EdgeInsets? {
            i.flatMap { $0.count == 4 ? EdgeInsets(top: $0[0], leading: $0[1], bottom: $0[2], trailing: $0[3]) : nil }
        }
        func fold(_ r: [Double]?) -> CGRect? { r.flatMap { $0.count == 4 ? CGRect(x: $0[0], y: $0[1], width: $0[2], height: $0[3]) : nil } }
        let first = Pose(size: CGSize(width: f[0], height: f[1]), insets: insets(numbers("UNSTIR_INSETS", ",")) ?? EdgeInsets(),
                         fold: fold(numbers("UNSTIR_FOLD", ",")))
        guard let then = env["UNSTIR_THEN"].flatMap(Double.init) else { return Spec(poses: [first], then: nil) }
        let g = numbers("UNSTIR_THENFRAME", "x")
        let second = Pose(size: g?.count == 2 ? CGSize(width: g![0], height: g![1]) : first.size,
                          insets: insets(numbers("UNSTIR_THENINSETS", ",")) ?? first.insets,
                          fold: env["UNSTIR_THENFOLD"] == "none" ? nil : fold(numbers("UNSTIR_THENFOLD", ",")) ?? first.fold)
        return Spec(poses: [first, second], then: then)
    }()

    init(_ spec: Spec, content: some View) {
        poses = spec.poses
        then = spec.then
        self.content = AnyView(content)
    }

    var body: some View {
        let pose = poses[at], size = pose.size
        GeometryReader { screen in
            // One scale for every pose, so a change of pose changes only the window.
            let k = poses.map { min(1, screen.size.width / $0.size.width, screen.size.height / $0.size.height) }.min() ?? 1
            content
                .environment(\.harnessFold, pose.fold)
                .safeAreaPadding(pose.insets)
                .frame(width: size.width, height: size.height)
                .background(Color.black)
                .overlay(alignment: .topLeading) {
                    if let f = pose.fold {
                        Rectangle().fill(Color(white: 0.5).opacity(0.35))
                            .frame(width: f.width, height: f.height).offset(x: f.minX, y: f.minY).allowsHitTesting(false)
                    }
                }
                .clipped()
                .scaleEffect(k)
                .frame(width: screen.size.width, height: screen.size.height)
        }
        .ignoresSafeArea()
        .background(Color(white: 0.25))
        .task {
            guard let then, (try? await Task.sleep(for: .seconds(then))) != nil else { return }
            Log.write("harness pose \(poses[1].size)")
            at = 1
        }
    }
}

extension EnvironmentValues {
    /// UNSTIR_FOLD's fold, in the harness window's points.
    @Entry var harnessFold: CGRect? = nil
}

/// UNSTIR_BENCH: turns a rod every frame for 20 s, as a drag that never stops would, then prints the frame intervals.
/// Display-link intervals show main-thread stalls, not frames the render server or GPU drops after the callback.
@MainActor
final class Bench: NSObject {
    private var drive: ((Double) -> Void)?
    /// A live picture: lets go after the drag, then times 20 s more with nothing driven but the background's clock.
    private let still: (() -> Void)?
    private var first = 0.0, last = 0.0
    private var intervals: [Double] = []

    init(drive: @escaping (Double) -> Void, still: (() -> Void)? = nil) {
        self.drive = drive
        self.still = still
    }

    func start() {
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 120, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
    }

    @objc private func tick(_ link: CADisplayLink) {
        if first == 0 { first = link.timestamp } else { intervals.append((link.timestamp - last) * 1e6) }
        last = link.timestamp
        drive?(link.timestamp - first)
        guard last - first >= 20 else { return }
        let s = intervals.sorted()
        func p(_ q: Double) -> Int { Int(s[min(Int(Double(s.count) * q), s.count - 1)]) }
        let worst = intervals.indices.max { intervals[$0] < intervals[$1] }!
        let heat = ["nominal", "fair", "serious", "critical"][ProcessInfo.processInfo.thermalState.rawValue]
        print("BENCH \(drive == nil ? "still " : "")n=\(s.count) p50=\(p(0.5))us p95=\(p(0.95))us p99=\(p(0.99))us max=\(Int(s.last!))us at frame \(worst) \(heat)")
        guard drive != nil, let still else { link.invalidate(); exit(0) }
        still()
        drive = nil
        first = 0
        intervals = []
    }
}

struct RootView: View {
    @State private var level: Level?
    @State private var harness: Harness?
    /// The pack card over the menu: a level past its pack's taste opens it in the level's place.
    @State private var card: Offer?
    /// The pack whose card a level past its taste opened in the level's place, while that card is up.
    @State private var arrived: Pack?
    /// UNSTIR_CARDLEVELS, kept past the harness's first launch so the card's list stays while it is played from.
    @State private var placeholders = 0
    @State private var typeSize: DynamicTypeSize?
    /// The tier the next menu opens on, set by a closed tier's button on a result card.
    @State private var look: Tier?
    /// The menu's settings sheet; UNSTIR_SETTINGS=1 opens with it up.
    @State private var settings: Bool
    /// The archive's calendar over the menu, kept while a past daily is played from it so leaving returns there.
    @State private var archive: Bool
    /// The row the next menu, or the pack's card over it, centres on (`MenuView.focus`).
    @State private var focus: Level?
    /// The level's saved try, replayed as it opens (Jack's call C2, round 13).
    @State private var resumed: Game?
    /// The menu is drawn under the level while a back swipe slides it off (Jack's call C19, round 13).
    @State private var peeking = false
    /// The window splits, as the open Duo held like a book does: a level plays beside the menu, the tank and the level's
    /// chrome in the leading half and the menu in the trailing half (Jack's calls D-layout = 3, DUOMENU = B and
    /// s5-chrome = B, round 16).
    @State private var wide = false
    /// The trailing half as the playing level lays it out, the menu's beside it, in `Self.space`.
    @State private var slot: CGRect?
    /// The level whose result or lost card covers the menu beside it.
    @State private var covering: String?
    /// A level picked beside play, which the playing level leaves for through its own way out, saving its try, and
    /// whether the harness carries over to it.
    @State private var switching: Level?
    @State private var keeping = false
    /// Bumped by every level opened, left or finished, so a menu that stays up beside play reads afresh.
    @State private var revision = 0
    /// The card or the archive a level beside play was opened from, which would cover the list following the level: put
    /// away while it plays, and back as it leaves, as on a phone they wait under the level.
    @State private var parked: (card: Offer?, archive: Bool)?
    @Environment(\.harnessFold) private var harnessFold
    /// Kept apart from `harness`, which a first move to another screen drops.
    private let harnessed: Bool
    /// The harness's one save, so a plain launch's left on the simulator never reaches a shot.
    private let harnessSave: Resume?
    /// A fresh install's first launch, opening straight into plughole 01.
    private let welcoming: Bool
    @Environment(\.scenePhase) private var phase
    @Environment(\.requestReview) private var requestReview
    private let mute: Bool

    init() {
        let env = ProcessInfo.processInfo.environment
        let h = Harness(env)
        harnessed = h.harnessed
        harnessSave = h.resume
        Marks.stored = !h.harnessed
        // UNSTIR_PAYOFFAT=s holds the curtain call (`Payoff`) s seconds in on a level opened solved, and
        // UNSTIR_PAYOFFSKIP=s ends it s seconds in, as a tap does.
        Payoff.frozen = env["UNSTIR_PAYOFFAT"].flatMap(Double.init)
        Payoff.skips = env["UNSTIR_PAYOFFSKIP"].flatMap(Double.init)
        #if DEBUG
        // UNSTIR_EDITORS=1: settings shows the editors' switch, for its shot.
        Build.editorsSwitch = Build.editors || h.harnessed && env["UNSTIR_EDITORS"] == "1"
        #endif
        // Here, not in Harness, which the tests build too.
        Settings.held.withLock { $0 = h.switches }
        Analytics.shared.configure(env: env, harnessed: h.harnessed)
        Taps.shared.configure(env: env, harnessed: h.harnessed)
        // The launch's, not the level's harness, which a level opened from the card's next no longer has.
        Review.harnessed = h.harnessed && !h.reviewLog || env["XCTestConfigurationFilePath"] != nil
        Review.logs = h.reviewLog
        GameCenter.shared.plays = GameCenter.built && !h.harnessed && env["XCTestConfigurationFilePath"] == nil
        Sync.shared.plays = Sync.plays(built: Sync.built, harnessed: h.harnessed, env: env)
        if let purchases = h.purchases {
            Store.shared.pretend(purchases, prices: h.prices, amounts: h.amounts, pricing: h.pricing, failure: h.failure, canPay: h.canPay,
                                 restored: h.restored, approved: h.approved, ready: !h.unread)
        }
        let gate = h.screen == "menu" ? nil : Store.shared.card(for: h.level)
        // The test host is a plain launch, but must open on nothing that stores.
        let welcome = h.screen != "menu" ? nil
            : Self.opening(harnessed: h.harnessed && !h.fresh || env["XCTestConfigurationFilePath"] != nil,
                           welcomed: !h.fresh && Best.welcomed)
        welcoming = welcome != nil && !h.harnessed
        let menu = h.screen == "menu" || gate != nil || !Store.shared.opens(h.level)
        _level = State(initialValue: welcome ?? (menu ? nil : h.level))
        // Yesterday's daily and a level an update took out leave no save behind; a harnessed launch's are its own.
        if !h.harnessed { Resume.prune(known: Resume.known) }
        _resumed = State(initialValue: welcome != nil || menu ? nil
                         : Self.resume(h.level, from: Self.save(h.level.id, harnessed: h.harnessed, h.resume), harness: h,
                                       stores: !h.harnessed))
        // A plain launch's level has no harness, so it stores what it plays.
        _harness = State(initialValue: welcoming ? nil : h)
        _settings = State(initialValue: welcome == nil && menu && h.settings)
        _archive = State(initialValue: welcome == nil && (h.archive || h.level.archived && !menu))
        mute = h.mute
        // Complete's card opens, as from the dock, only while it is on offer, or as an owner's home.
        let card = h.card.flatMap { $0 != .complete || Store.shared.offersComplete || Store.shared.state(.complete) == .owned ? $0 : nil }
        _card = State(initialValue: gate.map(Offer.pack) ?? card)
        _arrived = State(initialValue: gate)
        _placeholders = State(initialValue: h.cardLevels)
        _focus = State(initialValue: (h.menuTier ?? Tier.stored()).landing())
        _typeSize = State(initialValue: h.typeSize)
    }

    /// Where the menu and a level beside it measure from.
    static let space = "root"

    /// A level plays beside the menu.
    private var beside: Bool { wide && level != nil }

    /// The menu is up with nothing over it: a card, the consent question, the settings sheet.
    private var calm: Bool {
        level == nil && card == nil && !archive && !settings && !(Analytics.shared.asks && Analytics.shared.consent == .undecided)
    }

    var body: some View {
        // The outgoing screen is black before the incoming one starts, so the two never show at once.
        let dip = AnyTransition.asymmetric(insertion: .opacity.animation(.easeOut(duration: 0.15).delay(0.12)),
                                           removal: .opacity.animation(.easeIn(duration: 0.12)))
        ZStack {
            if let n = harness?.icon {
                IconView(n: n)
            } else if let offer = harness?.promo {
                PromoArt(offer: offer)
            } else {
                // First, so the menu a back swipe uncovers is the one that stays up once the level has gone. Under the
                // level it opens as leaving would open it, not on the harness's tier. Beside play it stays up, over the
                // level, whose ground it leaves uncovered.
                if level == nil || peeking || beside {
                    MenuView(start: level == nil ? harness?.menuTier ?? look : nil, demo: harness?.tierDemo ?? false,
                             frozen: harness?.tierSpin, settings: $settings, card: $card, archive: $archive, clock: harness?.clock, day: harness?.day,
                             placeholders: placeholders, shelfDemo: harness?.shelfDemo ?? false,
                             cardScroll: harness?.cardScroll ?? false, focus: focus, held: harness?.lockTap, arrived: arrived,
                             run: Self.save("endless", harnessed: harnessed, harnessSave), peeking: level != nil && !beside,
                             playing: beside ? level : nil, slot: slot, revision: revision,
                             covered: beside && covering == level?.id) {
                        show($0)
                    }
                    .allowsHitTesting(level == nil || beside)
                    .accessibilityHidden(level != nil && !beside)
                    .transition(level == nil ? dip : wide ? .opacity : .identity)
                    .zIndex(beside ? 1 : 0)
                }
                if let level {
                    LevelView(level: level, harness: harness, resumed: resumed, storesResume: !harnessed,
                              onExit: { show(nil, solved: $0) },
                              // Never through a switch beside the menu: the level is finished, so it sends no quit.
                              onNext: { proceed($0) },
                              onLook: { show(nil, look: $0) },
                              onOffer: { pack in
                                  card = .pack(pack)
                                  // Beside the menu the card opens over the trailing half, the level under it.
                                  if !beside { show(nil, solved: true) }
                              },
                              onPeek: { solved in
                                  if let solved { focus = level.focus(solved: solved) }
                                  peeking = solved != nil
                              },
                              besideMenu: wide, switching: switching,
                              onSwitch: { next in
                                  switching = nil
                                  proceed(next, keep: keeping)
                              },
                              onMenu: { slot = $0 },
                              onFinish: { revision += 1 },
                              // Keyed by the level, so a level leaving after the next has shown its card never uncovers it.
                              onCover: { covers in
                                  if covers { covering = level.id } else if covering == level.id { covering = nil }
                              })
                        .id(level)
                        .transition(dip)
                        // Heard before the menu beside it.
                        .accessibilitySortPriority(beside ? 1 : 0)
                }
            }
        }
        .coordinateSpace(.named(Self.space))
        .onGeometryChange(for: Bool.self) {
            MenuLayout.of(size: $0.size, insets: $0.safeAreaInsets, fold: PlayLayout.fold($0, harness: harnessFold)).splits
        } action: { new in
            // The phone opened mid-level: a card or the archive left under the level would cover the list beside it, so
            // it goes, before the menu is drawn there, until the level leaves, as on a phone it waits under the level.
            if new, level != nil, card != nil || archive { park() }
            wide = new
        }
        .background(Color.black)
        .buttonStyle(Sounding())
        .modifier(TypeSize(size: typeSize))
        // A failure belongs to the card that showed it, so every change of card forgets it: back, another pack, or a
        // level's gate. Here, since the menu isn't up while a level is, and a card shown again doesn't always appear anew.
        .onChange(of: card) {
            Store.shared.forgetFailures()
            if card != arrived.map(Offer.pack) { arrived = nil }
        }
        // A promoted purchase opens its offer's card over the menu; an open level leaves for it on its own way out.
        .onChange(of: Store.shared.promoted, initial: true) {
            guard let offer = Store.shared.promoted else { return }
            settings = false
            card = offer
        }
        .onChange(of: phase) {
            Log.write("phase \(phase)")
            Analytics.shared.phase(phase)
            // Not on inactive: Control Center and the app switcher pass through it.
            Sound.shared.foreground(phase != .background)
        }
        .onAppear {
            Sound.shared.use(on: !mute)
            if welcoming { Best.welcomed = true }
        }
        .modifier(AgeChecked(menu: calm,
                             played: !harnessed && ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil))
        // Game Center signs in only once the menu has settled, and holds its sheet while anything covers the menu.
        .task(id: calm) {
            GameCenter.shared.calm = false
            guard calm, GameCenter.shared.plays, (try? await Task.sleep(for: GameCenter.settle)) != nil else { return }
            GameCenter.shared.calm = true
            GameCenter.shared.signIn()
        }
        // The menu has a bed of its own. A level's crossfades in over it and carries on into the next level of its tier,
        // a pack's with the pack's layer over it.
        .onChange(of: level?.id, initial: true) {
            Sound.shared.bed(level?.bed ?? .menu)
            Sound.shared.layer(level?.layer)
        }
        // Closed again mid-level, a card or the archive parked as the phone opened waits under the level, as on a phone,
        // if it opened that level. The slot goes with the menu beside play, so a later one waits for the level's own.
        .onChange(of: beside) {
            if !beside {
                slot = nil
                if let p = parked, let level {
                    if Self.returns(to: p, from: level) {
                        card = p.card
                        archive = p.archive
                    }
                    parked = nil
                }
            }
        }
        .task {
            Log.write(UnstirApp.device)
            Power.shared.watch()
            await Log.trim()
        }
        .task {
            // A test host's listener would finish the transactions the StoreKit tests watch, and its analytics would
            // count the tests.
            let env = ProcessInfo.processInfo.environment
            guard env["XCTestConfigurationFilePath"] == nil else { return }
            Sync.shared.start()
            await Store.shared.start()
            // After the store, so a snapshot sees the packs owned.
            Analytics.shared.start(env: env, harnessed: harnessed)
        }
        // Only in front: leaving cancels the wait, and coming back waits again.
        .task(id: [Review.shared.pending, phase == .active]) {
            guard Review.shared.pending, phase == .active,
                  (try? await Task.sleep(for: .seconds(Review.wait))) != nil else { return }
            Review.shared.pending = false
            guard Review.due(opened: .whirlpool, asked: Best.reviewAsked, harnessed: Review.harnessed,
                             purchased: Store.shared.landed) else { return }
            Log.write("review requested\(Review.logs ? " (UNSTIR_REVIEW=log)" : "")")
            guard !Review.logs else { return }
            Best.reviewAsked = true
            requestReview()
        }
        .task {
            guard let offer = harness?.promoted else { return }
            try? await Task.sleep(for: .seconds(1))
            Store.shared.promote(offer.productID)
        }
        .task {
            guard let s = harness?.lands, let id = card?.productID else { return }
            try? await Task.sleep(for: .seconds(s))
            Store.shared.land(id)
        }
        .task {
            guard harness?.tour == true else { return }
            try? await Task.sleep(for: .seconds(1.5))
            show(Level.plughole[0], keep: true)
            try? await Task.sleep(for: .seconds(4))
            show(nil)
        }
        .task {
            guard harness?.pick != nil || harness?.pickArchive == true,
                  (try? await Task.sleep(for: .seconds(1.5))) != nil else { return }
            if let next = harness?.pick { show(next, keep: true) } else { withAnimation(.snappy(duration: 0.42)) { archive = true } }
        }
        .task {
            // The swipe's leaves through the level's own commit.
            guard let exit = harness?.exit, exit != "swipe", let left = level else { return }
            try? await Task.sleep(for: .seconds(1))
            if exit == "up", let up = left.tier.step(1)?.levels.first {
                show(up)
                try? await Task.sleep(for: .seconds(1))
            }
            show(nil, solved: exit == "solved")
        }
    }

    /// The save for `id`: on disk, or under the harness UNSTIR_RESUME's alone.
    static func save(_ id: String, harnessed: Bool, _ harnessSave: Resume?) -> Resume? {
        harnessed ? harnessSave.flatMap { $0.id == id ? $0 : nil } : Resume.load(id)
    }

    /// `level`'s saved try `r` replayed, or nil to open it afresh. `stores`: the try saves on, as on any launch but the
    /// harness's; a save it drops goes.
    static func resume(_ level: Level, from r: Resume?, harness: Harness?, stores: Bool) -> Game? {
        guard !level.sandbox, level.keepsProgress, let r else { return nil }
        guard let game = Game.resumed(level, from: r, tankTurned: harness?.tankTurned, swirled: harness?.swirled,
                                      bank: harness?.bank, storesProgress: harness?.harnessed != true, storesResume: stores)
        else {
            if stores { Resume.remove(level.id) }
            return nil
        }
        return game
    }

    /// A fresh install's first launch opens straight into plughole 01 (Jack's call C4, round 13), and only the first: a
    /// player who backs out of it without a move, which C3 leaves free, isn't sent back on every launch. Never under the
    /// harness, which UNSTIR_FRESH answers for.
    static func opening(harnessed: Bool, welcomed: Bool, best: (String) -> Best? = Best.load,
                        started: (String) -> Bool = Best.started) -> Level? {
        let first = Level.plughole[0]
        return harnessed || welcomed || best(first.id) != nil || started(first.id) ? nil : first
    }

    /// A card or the archive put away while a level beside the menu played comes back as `level` leaves only if it
    /// opened that level, whose way out leads back to it, as on a phone.
    static func returns(to parked: (card: Offer?, archive: Bool), from level: Level) -> Bool {
        if parked.archive { return level.archived }
        guard let pack = level.pack, let card = parked.card else { return false }
        return card == .pack(pack) || card == .complete && Pack.bundled.contains(pack)
    }

    /// The daily's and endless's rows are marked new until either first opens.
    static func seesModes(_ next: Level?, opens: Bool) -> Bool {
        guard let next, opens else { return false }
        return next.run != nil || next.id.hasPrefix("daily-")
    }

    /// A level past its pack's taste that the player doesn't own shows the pack's card over the menu instead.
    /// `look`: the tier the menu opens on in place of the stored one, locked or not. `solved`: the level left is.
    private func show(_ next: Level?, keep: Bool = false, look: Tier? = nil, solved: Bool = false) {
        // Beside play, another level leaves the playing one through its own way out, which saves its try and lets go of
        // a finger, and then opens; the playing level itself opens nothing.
        if beside, let next, let level {
            switch Self.besidePick(next, playing: level, gated: Store.shared.card(for: next) != nil,
                                   opens: Store.shared.opens(next)) {
            case .same:
                // Its own card's play: the card goes, to come back as the level leaves.
                if card != nil || archive { park() }
            case .stays:
                // Just after launch the store may not yet have read what the player owns: decided again once it has.
                if Store.shared.ready {
                    open(next, keep: keep, look: nil, solved: false)
                } else {
                    Task {
                        await Store.shared.settled()
                        show(next, keep: keep)
                    }
                }
            case .switches:
                if switching == nil {
                    keeping = keep
                    switching = next
                }
            }
            return
        }
        proceed(next, keep: keep, look: look, solved: solved)
    }

    /// What a level picked beside play does there, decided before the playing level leaves, so one that won't open
    /// leaves it untouched.
    enum BesidePick: Equatable {
        /// The playing level's own: it opens nothing.
        case same
        /// A gate's card opens over the trailing half, or nothing does, and the playing level stays in the tank.
        case stays
        /// The playing level leaves through its own way out, its try saved and a finger let go, and this one opens.
        case switches
    }

    nonisolated static func besidePick(_ next: Level, playing: Level, gated: Bool, opens: Bool) -> BesidePick {
        if next == playing { return .same }
        return gated || !opens ? .stays : .switches
    }

    /// The card or the archive goes while a level beside the menu plays, as it would cover the list following the level,
    /// to come back as that level leaves.
    private func park() {
        parked = (card, archive)
        card = nil
        archive = false
    }

    private func proceed(_ next: Level?, keep: Bool = false, look: Tier? = nil, solved: Bool = false) {
        // Just after launch the store may not yet have read what the player owns, so a gate waits for it.
        if let next, !Store.shared.ready, Store.shared.card(for: next) != nil {
            Task {
                await Store.shared.settled()
                open(next, keep: keep, look: look, solved: solved)
            }
        } else {
            open(next, keep: keep, look: look, solved: solved)
        }
    }

    private func open(_ next: Level?, keep: Bool, look: Tier?, solved: Bool) {
        if !keep { harness = nil }
        self.look = look
        revision += 1
        let gate = next.flatMap { Store.shared.card(for: $0) }
        let opens = next.map { Store.shared.opens($0) } ?? true
        // Beside play a level that doesn't open leaves the playing one where it is: a gate's card opens over the menu
        // in the trailing half.
        let stays = beside && next != nil && (gate != nil || !opens)
        // The gate's note shows on the showing it opens, never again on a return to the card.
        arrived = gate
        // A failure shown before a level isn't still there after it, though the card it was on comes back.
        if next != nil { Store.shared.forgetFailures() }
        if wide, next != nil, !stays, gate == nil, opens {
            if card != nil || archive { park() }
        }
        if gate != nil { card = gate.map(Offer.pack) }
        if next == nil, let p = parked, let level {
            if Self.returns(to: p, from: level) {
                card = p.card
                archive = p.archive
            }
            parked = nil
        }
        // A gate's card opens on buying (`arrived`), not on a row.
        if let level, !stays { focus = gate == nil ? level.focus(solved: solved) : nil }
        if stays { return }
        if Self.seesModes(next, opens: opens), !Best.modesSeen { Best.seeModes(store: !harnessed) }
        // So a launch after the app dies in a level comes back on its tier too.
        if let next, gate == nil, opens, next.tier.levels.contains(where: { $0.id == next.id }) { Tier.store(next.tier) }
        // Here, never in LevelView's init, which SwiftUI reruns for a level it already shows.
        resumed = next.flatMap {
            gate == nil && opens ? Self.resume($0, from: Self.save($0.id, harnessed: harnessed, harnessSave), harness: harness,
                                               stores: !harnessed) : nil
        }
        covering = nil
        // Together, so a menu a back swipe uncovered stays up as the level goes.
        withAnimation(.easeInOut(duration: 0.25)) {
            level = gate == nil && opens ? next : nil
            peeking = false
        }
    }
}

private struct TypeSize: ViewModifier {
    let size: DynamicTypeSize?

    func body(content: Content) -> some View {
        if let size { content.dynamicTypeSize(size) } else { content }
    }
}
