// Copyright © 2026 Jack Lusher. All rights reserved.

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
            + "voiceover \(UIAccessibility.isVoiceOverRunning), low power \(ProcessInfo.processInfo.isLowPowerModeEnabled)"
    }

    var body: some Scene {
        WindowGroup {
            if GPUBench.wanted { GPUBenchView() } else { RootView() }
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
    /// Skip the opening so shots land on a settled tank; UNSTIR_OPEN=1 (or v1's UNSTIR_STIR=1) keeps it.
    let still: Bool
    let autoplay: Bool
    /// UNSTIR_PACE=s: autoplay and UNSTIR_MOVES wait this long before each move (0.3 s unset).
    let pace: Double
    /// UNSTIR_BARE=1: the picture drawn unstirred whatever the stack, so a still shows a story's art as the stack has
    /// played it.
    let bare: Bool
    /// UNSTIR_ENDING=s: First Stir's last scene opens solved with the night forwards held s seconds in, or running from
    /// the start at -1, for films. Needs UNSTIR_SCREEN=clean.
    let ending: Double?
    /// UNSTIR_MOVES=-1:-1,1:-8: these moves played in order, each a knob's turn or the tank's (rod -1, as `Game.history`
    /// names it), as solve.sh prints a line. A ratchet's turn is a tap on it, a wait; with UNSTIR_FINGER, any turn of it
    /// but 1 taps halfway out the clock's disc instead. A turn of the open stir's knob takes it up again.
    let moves: [Twist]?
    /// UNSTIR_PLAYED=2:4,0:1: a line in UNSTIR_MOVES's form, committed through the real path as the level opens, so a
    /// still shows the tank part way through it.
    let played: [Twist]
    /// UNSTIR_FINGER=1: with UNSTIR_MOVES, a hand's pace instead, each move a fingertip drawn landing where the grab rule
    /// gives it the move's rod or the rim, carried round with the turn and lifted, for films.
    let finger: Bool
    /// UNSTIR_REST=s: with UNSTIR_FINGER, the seconds at rest before the first fingertip lands (2 when unset).
    let rest: Double
    /// UNSTIR_BREATH=s: on a layout with a swirl, its breath held s seconds into the tank's first rest. Unset, it runs
    /// live, or not at all while UNSTIR_CLOCK holds the clock. Never with UNSTIR_SWIRLED=1.
    let breath: Double?
    /// UNSTIR_BRIMDEMO=1: endless plays the approved film's run of the brim, two heals and then pushes until it spills.
    let brimDemo: Bool
    /// UNSTIR_SHARESHEET=1: the daily's share sheet open over its result card. ShareLink can't be opened without a tap,
    /// so this presents the UIKit sheet it wraps, with the same text.
    let shareSheet: Bool
    let bench: Bool
    /// UNSTIR_SWATCH=r, g or b: Prism's swatch for that channel held. UNSTIR_LETTERS=1: Prism as Differentiate Without
    /// Colour has it, its knobs spelling out their channels over the swatches.
    let swatch: Channels?
    let letters: Bool
    /// UNSTIR_WAVE=r: solve, then hold the solve wave at radius r (tank units).
    let wave: Double?
    /// UNSTIR_CLOCK=s: hold a live picture s seconds in, or endless's brim s seconds after its last change. It also stills
    /// the swirl's breath, so a shot on a layout with a swirl that sets none of this, UNSTIR_BREATH and UNSTIR_SWIRLED=1
    /// may catch a slosh.
    let clock: Double?
    /// UNSTIR_TOUR: menu, then level 01, then back, for filming the cross-fades.
    let tour: Bool
    /// UNSTIR_EXIT=left: the level, once open, left for the menu by "‹ levels"; =solved, as from its result card after
    /// a solve; =up, its tier's next tier's first level opened, as "up a notch" opens it, and that one left.
    let exit: String?
    /// UNSTIR_LOCKTAP=L8: on the menu, that locked row held as a tap leaves it, saying what opens it.
    let lockTap: String?
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
    /// UNSTIR_SETTINGS=1: the menu opens with the gear's sheet up. UNSTIR_CONSENT is read by `Analytics.configure`.
    let settings: Bool
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
    let pricing: Pricing
    /// UNSTIR_FAILED=offline (storefront, refused): why each failed product failed, or each pending one's ask again.
    let failure: Failure
    /// UNSTIR_PAYMENTS=0: purchases turned off on the device.
    let canPay: Bool
    /// UNSTIR_RESTORED=lens,prism (none, failed): what the last restore found.
    let restored: Restored?

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
    /// UNSTIR_TYPESIZE=accessibility3: Dynamic Type at that size (a `DynamicTypeSize` case), whatever the device's.
    let typeSize: DynamicTypeSize?
    /// Any UNSTIR_ variable but UNSTIR_UNLOCK and UNSTIR_ANALYTICS: analytics is then off unless UNSTIR_ANALYTICS=log
    /// logs it, and stores nothing either way.
    let harnessed: Bool
    /// Shots, films, the bench and the test host play no sound unless UNSTIR_SOUND=1. Not stored, so the next launch on
    /// the phone sounds; UNSTIR_UNLOCK alone is a phone launch.
    let mute: Bool

    init(_ env: [String: String]) {
        // UNSTIR_LEVEL counts in UNSTIR_TIER too.
        let tier = env["UNSTIR_TIER"].flatMap(Tier.init(rawValue:)) ?? .plughole
        // UNSTIR_UNLOCK on its own is for the phone: =1 stores the developer unlock, =0 clears it, and the launch is
        // otherwise a plain one. Alongside any other UNSTIR_ variable, unset clears it too, so no shot leaves the next
        // one unlocked. UNSTIR_ANALYTICS is for the phone too, and leaves the launch a plain one.
        let harnessed = env.keys.contains { $0.hasPrefix("UNSTIR_") && !["UNSTIR_UNLOCK", "UNSTIR_ANALYTICS"].contains($0) }
        self.harnessed = harnessed
        if harnessed || env["UNSTIR_UNLOCK"] != nil { Best.unlocked = env["UNSTIR_UNLOCK"] == "1" }
        menuTier = harnessed ? tier : nil
        // UNSTIR_BESTS=plughole:00-1,whirlpool:0,lens:000: a best for each of a tier's or a pack's levels from 01, one
        // character each: a digit is that many over par, - is none. For this launch only.
        for part in env["UNSTIR_BESTS"]?.split(separator: ",") ?? [] {
            let f = part.split(separator: ":")
            guard f.count == 2, let levels = Tier(rawValue: String(f[0]))?.levels ?? Pack(rawValue: String(f[0]))?.levels
            else { continue }
            for (level, c) in zip(levels, f[1]) {
                if let over = c.wholeNumberValue { Best(over: over, seconds: 60).fake(level.id) }
            }
        }
        // UNSTIR_TRIED=L14,lens-2: those levels started, for this launch only.
        for id in env["UNSTIR_TRIED"]?.split(separator: ",") ?? [] { Best.start(String(id), store: false) }
        fresh = env["UNSTIR_FRESH"] == "1"
        tierDemo = env["UNSTIR_TIERDEMO"] == "1"
        let spin = env["UNSTIR_TIERSPIN"]?.split(separator: ":").compactMap { Double($0) } ?? []
        tierSpin = spin.first.map { ($0, spin.count > 1 ? spin[1] : 0) }
        settings = env["UNSTIR_SETTINGS"] == "1"
        bench = env["UNSTIR_BENCH"] == "1"
        swatch = env["UNSTIR_SWATCH"].flatMap { $0.count == 1 ? Channels(letter: $0.first!) : nil }
            .flatMap { Channels.each.contains($0) ? $0 : nil }
        letters = env["UNSTIR_LETTERS"] == "1"
        wave = env["UNSTIR_WAVE"].flatMap(Double.init)
        clock = env["UNSTIR_CLOCK"].flatMap(Double.init)
        tour = env["UNSTIR_TOUR"] == "1"
        lockTap = env["UNSTIR_LOCKTAP"]
        exit = env["UNSTIR_EXIT"].flatMap { ["left", "solved", "up"].contains($0) ? $0 : nil }
        stopLook = env["UNSTIR_STOPLOOK"].flatMap(StopLook.init(rawValue:))
        purchases = Harness.purchases(env)
        prices = ["0", "unreachable"].contains(env["UNSTIR_PRICES"]) ? [:]
            : Dictionary(uniqueKeysWithValues: Pack.productIDs.map { ($0, $0 == Pack.completeID ? "$5.99" : "$2.99") })
        pricing = env["UNSTIR_PRICES"] == "unreachable" ? .unreachable : .fetching
        failure = env["UNSTIR_FAILED"].flatMap(Failure.init(rawValue:)) ?? .other
        canPay = env["UNSTIR_PAYMENTS"] != "0"
        restored = switch env["UNSTIR_RESTORED"] {
        case nil: nil
        case "none": .nothing
        case "failed": .failed
        case let names?: .found(Set(names.split(separator: ",").compactMap { Pack(rawValue: String($0)) }))
        }
        let opensLevel = bench || ["LEVEL", "MODE", "STACK", "WAVE", "PACK"].contains { env["UNSTIR_\($0)"] != nil }
        screen = env["UNSTIR_SCREEN"] ?? (opensLevel ? "level" : "menu")
        let n = min(max(Int(env["UNSTIR_LEVEL"] ?? "") ?? 1, 1), tier.levels.count)
        var level = switch env["UNSTIR_MODE"] ?? env["UNSTIR_LEVEL"] {
        case "daily": Level.daily()
        // UNSTIR_BRIM=n: endless opens with n notches on the brim, short of the spill, which only a push may bring.
        case "endless": Level.endless(Run(seed: 7, brim: min(max(Int(env["UNSTIR_BRIM"] ?? "") ?? 0, 0), Run.room - 1)))
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
            let depth = env["UNSTIR_DEPTH"].flatMap(Int.init) ?? (p.isLive ? Tank.fourTaps - p.fillEntries : 24)
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
        // UNSTIR_PAR=n: a stack's own par, where turning the tank costs moves its entry count misses.
        if let n = env["UNSTIR_PAR"].flatMap(Int.init) { level.fixedPar = n }
        // UNSTIR_SEIZED=1,4: those knobs seized on a turning tank, never the swirl, which has no knob.
        if let s = env["UNSTIR_SEIZED"] {
            level.seized = Set(s.split(separator: ",").compactMap { Int($0) }
                .filter { level.layout.rods.indices.contains($0) && $0 != level.layout.swirl })
            level.motion = level.seized.isEmpty ? .none : .tank
        }
        self.level = level
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
        ending = env["UNSTIR_ENDING"].flatMap(Double.init)
        func line(_ line: String) -> [Twist] {
            line.split(separator: ",").compactMap { move in
                let f = move.split(separator: ":").compactMap { Int($0) }
                return f.count == 2 && f[1] != 0 ? Twist(rod: f[0], steps: f[1]) : nil
            }
        }
        moves = env["UNSTIR_MOVES"].map(line)
        played = env["UNSTIR_PLAYED"].map(line) ?? []
        finger = env["UNSTIR_FINGER"] == "1"
        rest = env["UNSTIR_REST"].flatMap(Double.init) ?? 2
        breath = env["UNSTIR_BREATH"].flatMap(Double.init)
        brimDemo = env["UNSTIR_BRIMDEMO"] == "1"
        icon = env["UNSTIR_ICON"].flatMap(Int.init)
        shareSheet = env["UNSTIR_SHARESHEET"] == "1"
        card = env["UNSTIR_CARD"].flatMap(Offer.init(name:)).flatMap { $0.sold ? $0 : nil }
        cardScroll = env["UNSTIR_CARDSCROLL"] == "1"
        lands = env["UNSTIR_LANDS"].flatMap(Double.init)
        cardLevels = env["UNSTIR_CARDLEVELS"].flatMap(Int.init).map { min(max($0, 0), 30) } ?? 0
        shelfDemo = env["UNSTIR_SHELFDEMO"] == "1"
        typeSize = env["UNSTIR_TYPESIZE"].flatMap { s in DynamicTypeSize.allCases.first { "\($0)" == s } }
        mute = (harnessed || env.keys.contains { $0.hasPrefix("XCTest") }) && env["UNSTIR_SOUND"] != "1"
    }
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
    /// The row the next menu, or the pack's card over it, centres on (`MenuView.focus`).
    @State private var focus: Level?
    /// Kept apart from `harness`, which a first move to another screen drops.
    private let harnessed: Bool
    /// A fresh install's first launch, opening straight into plughole 01.
    private let welcoming: Bool
    @Environment(\.scenePhase) private var phase
    private let mute: Bool

    init() {
        let env = ProcessInfo.processInfo.environment
        let h = Harness(env)
        harnessed = h.harnessed
        Analytics.shared.configure(env: env, harnessed: h.harnessed)
        if let purchases = h.purchases {
            Store.shared.pretend(purchases, prices: h.prices, pricing: h.pricing, failure: h.failure, canPay: h.canPay,
                                 restored: h.restored)
        }
        let gate = h.screen == "menu" ? nil : Store.shared.card(for: h.level)
        // The test host is a plain launch, but must open on nothing that stores.
        let welcome = h.screen != "menu" ? nil
            : Self.opening(harnessed: h.harnessed && !h.fresh || env["XCTestConfigurationFilePath"] != nil,
                           welcomed: !h.fresh && Best.welcomed)
        welcoming = welcome != nil && !h.harnessed
        _level = State(initialValue: welcome ?? (h.screen == "menu" || gate != nil ? nil : h.level))
        // A plain launch's level has no harness, so it stores what it plays.
        _harness = State(initialValue: welcoming ? nil : h)
        mute = h.mute
        _card = State(initialValue: gate.map(Offer.pack) ?? h.card)
        _arrived = State(initialValue: gate)
        _placeholders = State(initialValue: h.cardLevels)
        _focus = State(initialValue: (h.menuTier ?? Tier.stored()).landing())
        _typeSize = State(initialValue: h.typeSize)
    }

    var body: some View {
        // The outgoing screen is black before the incoming one starts, so the two never show at once.
        let dip = AnyTransition.asymmetric(insertion: .opacity.animation(.easeOut(duration: 0.15).delay(0.12)),
                                           removal: .opacity.animation(.easeIn(duration: 0.12)))
        ZStack {
            if let n = harness?.icon {
                IconView(n: n)
            } else if let level {
                LevelView(level: level, harness: harness,
                          onExit: { show(nil, solved: $0) },
                          onNext: { show($0) },
                          onLook: { show(nil, look: $0) })
                    .id(level)
                    .transition(dip)
            } else {
                MenuView(start: harness?.menuTier ?? look, demo: harness?.tierDemo ?? false, frozen: harness?.tierSpin,
                         settings: harness?.settings ?? false, card: $card, clock: harness?.clock, placeholders: placeholders,
                         shelfDemo: harness?.shelfDemo ?? false, cardScroll: harness?.cardScroll ?? false, focus: focus,
                         held: harness?.lockTap, arrived: arrived) {
                    show($0)
                }
                .transition(dip)
            }
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
        // The menu has a bed of its own. A level's crossfades in over it and carries on into the next level of its tier.
        .onChange(of: level?.id, initial: true) { Sound.shared.bed(level?.bed ?? .menu) }
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
            await Store.shared.start()
            // After the store, so a snapshot sees the packs owned.
            Analytics.shared.start(env: env, harnessed: harnessed)
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
            guard let exit = harness?.exit, let left = level else { return }
            try? await Task.sleep(for: .seconds(1))
            if exit == "up", let up = left.tier.step(1)?.levels.first {
                show(up)
                try? await Task.sleep(for: .seconds(1))
            }
            show(nil, solved: exit == "solved")
        }
    }

    /// A fresh install's first launch opens straight into plughole 01 (Jack's call C4, round 13), and only the first: a
    /// player who backs out of it without a move, which C3 leaves free, isn't sent back on every launch. Never under the
    /// harness, which UNSTIR_FRESH answers for.
    static func opening(harnessed: Bool, welcomed: Bool, best: (String) -> Best? = Best.load,
                        started: (String) -> Bool = Best.started) -> Level? {
        let first = Level.plughole[0]
        return harnessed || welcomed || best(first.id) != nil || started(first.id) ? nil : first
    }

    /// A level past its pack's taste that the player doesn't own shows the pack's card over the menu instead.
    /// `look`: the tier the menu opens on in place of the stored one, locked or not. `solved`: the level left is.
    private func show(_ next: Level?, keep: Bool = false, look: Tier? = nil, solved: Bool = false) {
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
        let gate = next.flatMap { Store.shared.card(for: $0) }
        // The gate's note shows on the showing it opens, never again on a return to the card.
        arrived = gate
        // A failure shown before a level isn't still there after it, though the card it was on comes back.
        if next != nil { Store.shared.forgetFailures() }
        if gate != nil { card = gate.map(Offer.pack) }
        // A gate's card opens on buying (`arrived`), not on a row.
        if let level { focus = gate == nil ? level.focus(solved: solved) : nil }
        let opens = next.map(Store.shared.opens) ?? true
        // The daily's and endless's rows are marked new until either first opens.
        if let next, opens, next.run != nil || next.id.hasPrefix("daily-"), !Best.modesSeen { Best.seeModes(store: !harnessed) }
        // So a launch after the app dies in a level comes back on its tier too.
        if let next, gate == nil, opens, next.tier.levels.contains(where: { $0.id == next.id }) { Tier.store(next.tier) }
        withAnimation(.easeInOut(duration: 0.25)) { level = gate == nil && opens ? next : nil }
    }
}

private struct TypeSize: ViewModifier {
    let size: DynamicTypeSize?

    func body(content: Content) -> some View {
        if let size { content.dynamicTypeSize(size) } else { content }
    }
}
