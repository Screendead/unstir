// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// A place on the slope handed to another piece's view: the column as seen now, the point the view goes at, how big
/// it is there, and how far the dive's words have arrived (0 at the overview, 1 in the dive).
struct SlopeSpot {
    let view: SlopeView
    /// The column's ledge the place belongs to: the archive's own, or the ledge over a hollow.
    let ledge: Int
    let point: CGPoint
    let side: CGFloat
    let near: Double
}

/// The slope's menu (docs/slope.md, 2 and 3): the main column at its two rests, the overview with the whole column on
/// one screen and the dive at full depth, which scrolls from the surface to the drop-off, and the travel between
/// them. It takes what `MenuView` takes and opens a level through `onPick`, with where its pebble lies on the screen.
///
/// The dive at rest is a `SlopeDive`, scrolled by the finger; the overview and every move of the camera is a
/// `SlopeScene`, which the two hand over to each other on the same camera.
struct SlopeMenu: View {
    /// A tier asked for by name: a closed "up a notch", the harness's.
    let start: Tier?
    /// The row the dive opens on: the level just left, or after a solve the one after it.
    let focus: Level?
    /// A level has been open since launch: the menu comes back in the dive, where a cold launch rests on the overview.
    let returning: Bool
    @Binding var settings: Bool
    @Binding var card: Offer?
    @Binding var archive: Bool
    /// UNSTIR_DAILY's day, which the daily keeps in place of today's.
    var day: Date?
    /// UNSTIR_CLOCK: the ground's clock held.
    var clock: Double?
    /// UNSTIR_LOCKTAP: a closed row held tapped.
    var held: String?
    /// Drawn under a level a back swipe is sliding off.
    var peeking = false
    /// The level playing beside the menu.
    var playing: Level?
    /// Bumped by every level opened, left or finished.
    var revision = 0
    /// Endless's saved run, as the root last read it.
    var run: Resume?
    /// The ground's light, 1 unless something dims the world: consent draws it at 0.35. It animates.
    var light = 1.0
    /// Only the ground: the words, pebbles and hollows hidden and dead, as under the consent question.
    var bare = false
    /// A pack's hollow in plughole's wall (`SlopeHollow`, piece D): a view whose top centre goes at the spot's point.
    /// Until it lands, a plain dull pebble.
    var hollow: ((Offer, SlopeSpot) -> AnyView)?
    /// The archive's ledge (piece E): a view that places itself in the slope's layer on the spot's ledge, as a
    /// `SlopeLedgeRow` does. Until it lands, a plain dull pebble.
    var archiveLedge: ((SlopeSpot) -> AnyView)?
    /// A level to open, and where its pebble lies in the menu's own frame; nil where it has none (endless).
    let onPick: (Level, CGPoint?) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.scenePhase) private var phase

    /// The scene's camera: the ledge it holds, the share of the screen's height it holds it at (nil is where the
    /// overview has it), and the zoom.
    @State private var hold = 0
    @State private var share: CGFloat?
    @State private var zoom: CGFloat = 0
    /// The dive is up, the finger's to scroll, resting on `aim`.
    @State private var diving = false
    @State private var aim: SlopeAim?
    /// The camera is moving, so the scene has the screen; and, on a travel into the dive, where it ends and what it
    /// does on arriving, which a tap skips to.
    @State private var moving = false
    @State private var travel: Travel?
    @State private var journeys = 0
    /// The journey whose arrival has already done what it was for.
    @State private var done = 0
    /// Where the finger has left the camera, in the dive and on an overview that scrolls; nothing is drawn from it.
    @State private var scroll = SlopeScroll()
    @State private var surfaced = true
    /// The back swipe following the finger, how far across the screen it has pulled, and the finger on it.
    @State private var swiping = false
    @State private var pull: CGFloat = 0
    @GestureState private var dragging = false
    /// The overview pulled past its place by a finger, and let go to settle back: down, the night stands over the
    /// surface (`SlopeEggs`). `drawn` is the same pull made for the finger, the harness's.
    @GestureState(resetTransaction: Transaction(animation: .spring(duration: 0.7, bounce: 0.3))) private var tug: CGFloat = 0
    @State private var drawn: CGFloat = 0
    /// A stone skimming along the water line, and how many times it has touched, for the hand to feel.
    @State private var skim: SlopeSkim?
    @State private var skips = 0

    @State private var rest: Menu.Rest?
    @State private var shown = Tier.stored()
    @State private var today: Date
    @State private var model: SlopeMenuModel
    @State private var saved: Resume?
    @State private var arm = NewRunArm()
    @State private var supporter = Settings.supporter
    @State private var announced: Set<Offer> = []

    private struct Travel {
        let aim: SlopeAim
        let then: () -> Void
    }

    init(start: Tier? = nil, focus: Level? = nil, returning: Bool = false, settings: Binding<Bool>, card: Binding<Offer?>,
         archive: Binding<Bool> = .constant(false), day: Date? = nil, clock: Double? = nil, held: String? = nil, peeking: Bool = false,
         playing: Level? = nil, revision: Int = 0, run: Resume? = nil, light: Double = 1, bare: Bool = false, hollow: ((Offer, SlopeSpot) -> AnyView)? = nil,
         archiveLedge: ((SlopeSpot) -> AnyView)? = nil, onPick: @escaping (Level, CGPoint?) -> Void) {
        self.start = start
        self.focus = focus
        self.returning = returning
        _settings = settings
        _card = card
        _archive = archive
        self.day = day
        self.clock = clock
        self.held = held
        self.peeking = peeking
        self.playing = playing
        self.revision = revision
        self.run = run
        self.light = light
        self.bare = bare
        self.hollow = hollow
        self.archiveLedge = archiveLedge
        self.onPick = onPick
        let now = day ?? .now
        _today = State(initialValue: now)
        _saved = State(initialValue: run)
        _model = State(initialValue: SlopeMenuModel(today: now, saved: run, playing: playing))
        _rest = State(initialValue: Menu.rest(start: start, focus: playing ?? focus, returning: returning || playing != nil))
    }

    private var covered: Bool { card != nil || archive || settings }
    /// Idle is the ground's own to answer: its water goes still (`SlopeEggs`).
    private var still: Bool { covered || peeking || playing != nil || Power.shared.saving }
    private var eggs: SlopeEggs {
        var eggs = SlopeEggs(today)
        eggs.skim = skim
        eggs.seams = model.tiers.map(\.seam)
        return eggs
    }

    var body: some View {
        watched
            .onChange(of: phase) { if phase == .active { today = day ?? .now } }
            .onChange(of: today) { reload() }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in today = .now }
            .onChange(of: covered || playing != nil) { Power.shared.touched() }
            .task(id: yours) {
                // "Lens is yours": said once to VoiceOver, and standing five seconds in sight; covered, it waits.
                guard let offer = yours else { return }
                if announced.insert(offer).inserted { AccessibilityNotification.Announcement(offer.yours).post() } // loc: verbatim localized by Offer
                guard clock == nil, (try? await Task.sleep(for: .seconds(5))) != nil else { return }
                Store.shared.said(offer)
            }
    }

    /// The approval the menu says now (2.10): none while anything covers the slope.
    private var yours: Offer? { Shop.saying(Store.shared.approved.first, covered: covered || playing != nil, shelved: true) }

    /// The screen, read afresh when a best, a purchase or a switch could change what it shows.
    private var watched: some View {
        GeometryReader { geo in screen(geo) }
            .background(Color.black.ignoresSafeArea())
            .onChange(of: revision) { reload() }
            .onChange(of: playing?.id) { reload() }
            .onChange(of: settings) {
                supporter = Settings.supporter
                if !settings { reload() }
            }
            .onChange(of: Sync.revision.count) { reload() }
            .onChange(of: Store.shared.ready) { reload() }
            .onChange(of: Store.shared.bought) { reload() }
    }

    private func screen(_ geo: GeometryProxy) -> some View {
        let size = CGSize(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                          height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
        let plan = SlopeMenuPlan(size: size, type: typeSize, model: model, top: geo.safeAreaInsets.top, bottom: geo.safeAreaInsets.bottom)
        // As it comes up in the dive, the menu is there from its first frame, under the level's leaving.
        let opening = rest.flatMap { plan.aim($0) }
        let below = (diving && !surfaced) || (opening != nil && !diving)
        return ZStack(alignment: .topLeading) {
            if diving || opening != nil {
                dive(plan, aim: diving ? aim : opening)
            } else if zoom == 0, !moving, plan.scrolls {
                wade(plan)
            } else {
                scene(plan)
            }
            chrome(plan, below: below && !bare)
        }
        .environment(\.slopeStill, Power.shared.idle && !reduceMotion && !still)
        .haptic(.impact(weight: .light, intensity: 0.6), trigger: skips) { _, now in now > 0 }
        .onAppear {
            settle(plan)
            #if DEBUG
            SlopeEggHarness.start()
            if SlopeEggHarness.wanted == .skim {
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    var stone = SlopeSkim(from: 150, over: 9, speed: SlopeEggHarness.speed, width: plan.size.width, luck: 0)
                    stone?.held = SlopeEggHarness.held
                    if stone?.held != nil, !reduceMotion { skim = stone } else { throwStone(stone) }
                }
            }
            if SlopeEggHarness.wanted == .seam {
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    enter(.plughole, plan)
                }
            }
            if SlopeEggHarness.wanted == .pebble {
                go(to: SlopeAim(ledge: plan.deep.count - 1, share: 0.3), plan)
            }
            if SlopeEggHarness.wanted == .night || SlopeEggHarness.wanted == .deep {
                let pull: CGFloat = SlopeEggHarness.wanted == .deep ? -215 : 215
                if SlopeEggHarness.posed { drawn = pull } else { Task {
                    try? await Task.sleep(for: .seconds(1))
                    withAnimation(.easeInOut(duration: 1.6)) { drawn = pull }
                    try? await Task.sleep(for: .seconds(6.6))
                    withAnimation(.spring(duration: 0.7, bounce: 0.3)) { drawn = 0 }
                } }
            }
            #endif
        }
        .onChange(of: dragging) { if !dragging { released(plan) } }
        .onChange(of: start) { if let start { enter(start, plan) } }
    }

    private func reload() {
        saved = run
        model = SlopeMenuModel(today: today, saved: run, playing: playing)
    }

    // MARK: The two rests

    /// The overview, and every move of the camera.
    private func scene(_ plan: SlopeMenuPlan) -> some View {
        // The pull gives as a scroll's end does.
        let h = plan.size.height, pulled = tug * h * 0.55 / (h + 0.55 * abs(tug)) + drawn
        let at = (share ?? plan.overview(holding: hold)) + (zoom == 0 && !moving ? pulled / h : 0)
        return SlopeScene(column: plan.column, focus: hold, at: at, z: zoom, held: still, look: SlopeLook(light: light), clock: clock, near: !plan.large,
                          eggs: eggs) { view in
            world(view, plan, cull: true)
            // Pulled up past its foot, the overview's words sink away under the status bar as the dive's do.
            let over = view.top - view.lay.travel(height: view.size.height).upperBound
            if over > 0, view.lay.e <= 0, plan.top > 0 {
                let veil = plan.top + 30
                SlopeGround(view: view, held: still, look: SlopeLook(light: light), clock: clock ?? 0, near: !plan.large, band: veil, eggs: eggs)
                    .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: plan.top / veil),
                                                 .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
                    .opacity(min(over / 24, 1))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        // Open water and air take a drag too, not only the words.
        .contentShape(Rectangle())
        .allowsHitTesting(!moving)
        // A drag takes the screen from the words under it; a tap is still theirs. Under Reduce Motion nothing follows
        // the finger here, and the dive's own bounce is the one way past either end.
        .highPriorityGesture(DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .updating($tug) { drag, tug, _ in
                // A drag along the water line is a stone's, and pulls nothing.
                if !flicks(drag, water: 0.188 * h) { tug = drag.translation.height }
            }
            .onEnded { flick($0, water: 0.188 * h, plan) }, including: zoom == 0 && !moving && !reduceMotion ? .all : .subviews)
        .overlay {
            // A tap during the travel skips to its end.
            if travel != nil { Color.clear.contentShape(Rectangle()).onTapGesture { arrive(journeys) }.ignoresSafeArea() }
        }
    }

    /// The dive at rest, the finger's to scroll, opened where the camera came to rest.
    private func dive(_ plan: SlopeMenuPlan, aim: SlopeAim?) -> some View {
        SlopeDive(column: plan.column, aim: aim, held: still, look: SlopeLook(light: light), clock: clock, near: !plan.large, eggs: eggs, onMove: { top in
            scroll.top = top
            let up = top < 1
            if up != surfaced { surfaced = up }
        }) { view in
            world(view, plan, cull: false)
        }
        .simultaneousGesture(MagnifyGesture().onEnded { if $0.magnification < 0.8 { rise(plan) } })
        .simultaneousGesture(DragGesture(minimumDistance: 12, coordinateSpace: .global).onEnded { flick($0, water: -scroll.top, plan) })
        // The edge swipe has the screen's leading edge to itself: a drag over the whole dive would take the rows' taps.
        .overlay(alignment: .leading) {
            Color.clear.frame(width: Self.edge).contentShape(Rectangle()).gesture(backSwipe(plan)).ignoresSafeArea()
                .accessibilityHidden(true)
        }
    }

    /// How far in from the leading edge the back swipe starts.
    private static let edge: CGFloat = 20

    /// The overview where its words outgrow the screen, at the largest type sizes: it scrolls, opening at its top.
    private func wade(_ plan: SlopeMenuPlan) -> some View {
        SlopeDive(column: plan.column, z: 0, held: still, look: SlopeLook(light: light), clock: clock, near: false, eggs: eggs,
                  onMove: { scroll.wide = $0 }) { view in
            world(view, plan, cull: false)
        }
    }

    private func world(_ view: SlopeView, _ plan: SlopeMenuPlan, cull: Bool) -> some View {
        SlopeMenuWorld(view: view, plan: plan, model: model, cull: cull, held: held, supporter: Store.shared.bought && supporter,
                       saved: saved, yours: yours, arm: $arm, voiceOver: voiceOver, hollow: hollow, archiveLedge: archiveLedge,
                       openSettings: { settings = true },
                       enter: { enter($0, plan) },
                       visit: { offer in go(to: plan.hollow(offer), plan) },
                       openArchive: {
                           Log.write("archive shown")
                           withAnimation(.snappy(duration: 0.42)) { archive = true }
                       },
                       pick: { level, ledge in pick(level, ledge: ledge, plan) },
                       newRun: {
                           Resume.remove("endless")
                           saved = nil
                           pick(.endless(Run(seed: .random(in: .min ... .max))), ledge: nil, plan, anew: true)
                       })
            .opacity(bare ? 0 : 1).allowsHitTesting(!bare).accessibilityHidden(bare)
            .animation(.easeOut(duration: 0.6), value: bare)
    }

    // MARK: The skimming stone

    /// The drag began by the water line, at `water` on the screen, and runs along it. The drag is read in the screen's
    /// space, as the water line is: a view's own starts under the status bar.
    private func flicks(_ drag: DragGesture.Value, water: CGFloat) -> Bool {
        abs(drag.startLocation.y - water) < 40 && abs(drag.translation.width) > 2 * abs(drag.translation.height)
    }

    /// A drag let go: along the water line and fast enough, it throws a stone (`SlopeSkim`). Reduce Motion and a
    /// saving `Power` throw none.
    private func flick(_ drag: DragGesture.Value, water: CGFloat, _ plan: SlopeMenuPlan) {
        guard flicks(drag, water: water), water > plan.top + 30 else { return }
        throwStone(SlopeSkim(from: drag.location.x, over: min(max(water - drag.location.y, 4), 30), speed: drag.velocity.width,
                             width: plan.size.width))
    }

    private func throwStone(_ stone: SlopeSkim?) {
        guard let stone, skim == nil, !reduceMotion, !Power.shared.saving else { return }
        Log.write("slope skim \(stone.touches)")
        skim = stone
        skips = 0
        Task {
            for i in 0 ..< stone.touches {
                try? await Task.sleep(for: .seconds(stone.time(i) - (i > 0 ? stone.time(i - 1) : 0)))
                skips = i + 1
            }
            try? await Task.sleep(for: .seconds(SlopeSkim.lingers))
            skim = nil
        }
    }

    // MARK: Travel

    /// The menu came up in the dive: the camera's state takes over from the opening.
    private func settle(_ plan: SlopeMenuPlan) {
        guard let rest else { return }
        self.rest = nil
        scroll.wide = plan.wide.travel(height: plan.size.height).lowerBound
        guard let aim = plan.aim(rest) else { return }
        hold = min(aim.ledge, plan.deep.count - 1)
        share = aim.share
        zoom = 1
        self.aim = aim
        diving = true
        surfaced = plan.deep.rest(aim, height: plan.size.height) < 1
        if case let .tier(tier) = rest {
            Tier.store(tier)
            shown = tier
        }
    }

    /// A tap on a tier's band, or its name asked for: the camera sinks into it and lands by 2.7. The tier's sound
    /// plays once as it lands in a tier other than the one last shown.
    private func enter(_ tier: Tier, _ plan: SlopeMenuPlan) {
        Log.write("slope dive \(tier.rawValue)")
        go(to: plan.landing(tier), plan) {
            if tier != shown { Sound.shared.play(.tier) }
            Tier.store(tier)
            shown = tier
            reload()
        }
    }

    /// The camera travels to rest on `target` in the dive, from wherever it is, then the dive is the finger's.
    /// `early`: what it does on arriving starts as the camera slows into its rest, 0.4 s short of the travel's end,
    /// so a level opens as the camera arrives and not after it has stood still.
    private func go(to target: SlopeAim, _ plan: SlopeMenuPlan, early: Bool = false, then: @escaping () -> Void = {}) {
        guard !moving else { return }
        journeys += 1
        let journey = journeys
        if diving {
            // Already in the dive: it scrolls itself to a new aim.
            aim = aim == target ? SlopeAim(ledge: target.ledge, share: target.share + 0.0001) : target
            return DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.9)) { if journeys == journey { then() } }
        }
        // The scene starts from where the overview stands on the ledge it will hold.
        hold = target.ledge
        share = plan.scrolls ? (plan.wide.tops[target.ledge] - scroll.wide) / plan.size.height : nil
        moving = true
        travel = Travel(aim: target, then: then)
        guard !reduceMotion else {
            return withAnimation(.easeOut(duration: 0.24)) { arrive(journey) }
        }
        // A frame on, so the travel starts from that camera and not from the last ledge held.
        DispatchQueue.main.async {
            guard journeys == journey, travel != nil else { return }
            withAnimation(.easeOut(duration: 1.1)) {
                share = target.share
                zoom = 1
            } completion: {
                arrive(journey)
            }
            if early {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    guard journeys == journey, travel != nil, done != journey else { return }
                    done = journey
                    then()
                }
            }
        }
    }

    /// The travel's end, reached or skipped to.
    private func arrive(_ journey: Int) {
        guard journey == journeys, let travel else { return }
        self.travel = nil
        moving = false
        hold = travel.aim.ledge
        share = travel.aim.share
        zoom = 1
        aim = travel.aim
        diving = true
        surfaced = false
        if done != journey {
            done = journey
            travel.then()
        }
    }

    /// "↑ surface", a pinch in and the edge swipe: the dive rises to the overview.
    private func rise(_ plan: SlopeMenuPlan) {
        guard diving, !moving else { return }
        Log.write("slope surface")
        lift(plan)
        guard !reduceMotion else { return withAnimation(.easeOut(duration: 0.24)) { surface(plan) } completion: { moving = false } }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 1.1)) { surface(plan) } completion: { moving = false }
        }
    }

    /// The scene takes the dive's camera, holding the ledge nearest the screen's middle.
    private func lift(_ plan: SlopeMenuPlan) {
        let middle = scroll.top + plan.size.height / 2
        let n = plan.deep.tops.indices.min { abs(plan.deep.tops[$0] - middle) < abs(plan.deep.tops[$1] - middle) } ?? 0
        hold = n
        share = (plan.deep.tops[n] - scroll.top) / plan.size.height
        zoom = 1
        moving = true
        diving = false
    }

    private func surface(_ plan: SlopeMenuPlan) {
        share = nil
        zoom = 0
        surfaced = true
        scroll.wide = plan.wide.travel(height: plan.size.height).lowerBound
    }

    /// The edge swipe in the dive (2.11): the zoom follows the finger from 1 toward 0.6; let go past 0.4 of the
    /// width, or flicked, it rises; else it springs back. Under Reduce Motion nothing follows the finger.
    private func backSwipe(_ plan: SlopeMenuPlan) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($dragging) { _, dragging, _ in dragging = true }
            .onChanged { drag in
                pull = drag.translation.width / plan.size.width
                guard !reduceMotion else { return }
                if !swiping {
                    guard diving, !moving, drag.translation.width > abs(drag.translation.height) else { return }
                    swiping = true
                    lift(plan)
                }
                zoom = 1 - 0.4 * min(max(pull, 0), 1)
            }
            .onEnded { drag in
                if drag.predictedEndTranslation.width > 0.8 * plan.size.width { pull = 1 }
            }
    }

    /// The finger has left the edge swipe, lifted or taken by the system.
    private func released(_ plan: SlopeMenuPlan) {
        let far = pull > 0.4
        pull = 0
        if reduceMotion {
            if far { rise(plan) }
            return
        }
        guard swiping else { return }
        swiping = false
        if far {
            withAnimation(.easeOut(duration: 0.9)) { surface(plan) } completion: { moving = false }
        } else {
            journeys += 1
            let journey = journeys
            travel = Travel(aim: SlopeAim(ledge: hold, share: share ?? 0.49), then: {})
            withAnimation(.spring(duration: 0.4)) { zoom = 1 } completion: { arrive(journey) }
        }
    }

    // MARK: Opening a level

    /// A row, the way on, the daily or endless tapped. From the dive it opens where it lies; from the overview the
    /// camera first sinks to its ledge (2.9), endless's off the last ledge into the dark.
    private func pick(_ level: Level, ledge: Int?, _ plan: SlopeMenuPlan, anew: Bool = false) {
        guard Menu.opens(level, playing: playing, anew: anew) else { return }
        // Where the pebble lies on the screen under a camera at `top`.
        func seat(_ top: CGFloat) -> CGPoint? {
            ledge.map { CGPoint(x: plan.deep.seat($0).x, y: plan.deep.seat($0).y - top) }
        }
        guard !diving else { return onPick(level, seat(scroll.top)) }
        let target = ledge.map { SlopeAim(ledge: $0, share: plan.rest(on: $0)) } ?? plan.foot
        go(to: target, plan, early: true) { onPick(level, seat(plan.deep.rest(target, height: plan.size.height))) }
    }

    // MARK: Over the slope

    /// "↑ surface" at the top leading corner, where the play screen's way back stands, whenever the surface is out
    /// of sight, and under it a message (2.10).
    private func chrome(_ plan: SlopeMenuPlan, below: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if below {
                Button { rise(plan) } label: {
                    Text("\u{2191} surface", comment: "The slope's menu, in the dive: rises to the whole column")
                        .font(.slope(.ui, .body)).ink(.ink2).hit()
                }
                .accessibilityLabel(Text("Surface", comment: "VoiceOver: the slope's menu, in the dive. Rises to the whole column"))
                .transition(.opacity)
            }
            if let yours, below {
                Text(yours.yours).font(.slope(.place, .body)).foregroundStyle(yours.ink).transition(.opacity) // loc: verbatim localized by Offer
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        // The water's shade under the words, which here lie over the rock.
        .background {
            if below {
                Ellipse().fill(Color(0x04090E).opacity(0.5)).padding(.horizontal, -18).padding(.vertical, -10).blur(radius: 22)
                    .allowsHitTesting(false)
            }
        }
        .padding(.leading, 4).padding(.top, 2)
        .animation(.easeOut(duration: 0.3), value: below)
        .animation(.easeInOut(duration: 0.4), value: yours)
        .accessibilitySortPriority(2)
    }
}

/// Where the finger has left the dive's camera: read as the dive rises or a level opens from it, never drawn from.
@MainActor private final class SlopeScroll {
    /// The dive's camera, and the overview's where it scrolls.
    var top: CGFloat = 0
    var wide: CGFloat = 0
}

// MARK: - The plan

/// The main column for one screen, type size and state of the menu, and every measure the menu sets things by: the
/// room each stretch's header needs, where the words start, where the camera rests.
struct SlopeMenuPlan {
    let size: CGSize
    let type: DynamicTypeSize
    /// The top safe area, under which the dive's top control stands.
    let top: CGFloat
    /// The bottom safe area, which the overview's last words keep clear of.
    let bottom: CGFloat
    let column: SlopeColumn
    /// The column at full depth, the dive, and closed, the overview.
    let deep: SlopeLay
    let wide: SlopeLay
    /// Each stretch's header's own height in the dive, the shallows' first.
    let headers: [CGFloat]
    /// The offers whose hollows show, and the level of plughole each lies under.
    let hollows: [(offer: Offer, after: Int)]

    var large: Bool { type.isAccessibilitySize }
    /// Where the overview's words start, and their room.
    var beside: CGFloat { large ? 96 : 180 - max(440 - size.width, 0) / 2 }
    var room: CGFloat { max(size.width - beside - 16, 80) }
    /// The overview's words outgrow the screen, so it scrolls.
    var scrolls: Bool {
        let travel = wide.travel(height: size.height)
        return travel.upperBound > travel.lowerBound + 1
    }

    /// From a header's foot to its stretch's first ledge, and from a stretch's top at the overview to its words.
    static let headerFoot: CGFloat = 48
    static let bandLead: CGFloat = -8

    init(size: CGSize, type: DynamicTypeSize, model: SlopeMenuModel, top: CGFloat, bottom: CGFloat = 0) {
        self.size = size
        self.type = type
        self.top = top
        self.bottom = bottom
        let large = type.isAccessibilitySize
        var column = SlopeColumn.main(size: size, type: type)
        func line(_ s: SlopeSize) -> CGFloat { SlopeMeasure.line(s, at: type) }
        func words(_ n: Int, seat: Int) -> (x: CGFloat, width: CGFloat) {
            let x = large ? 96 : column.lip + column.step * CGFloat(seat) + 4 * sin(2.4 * CGFloat(n) + 1) + 18
            return (x, max(size.width - x - 16, 80))
        }
        let beside = max(size.width - (large ? 96 : 180 - max(440 - size.width, 0) / 2) - 16, 80)
        var headers: [CGFloat] = [model.modes ? line(.title) : 0]
        column.stretches[0].header = model.modes ? line(.title) + 16 : 0
        // The daily's row: its title, and its run's line where it has one.
        column.stretches[0].rows = [line(.body) + line(.detail) + 60 + (large ? line(.body) : 0)]
        if let daily = model.daily {
            // At the overview the shallows hold "today", the day and its run beside the first ledge, and the archive's
            // two lines beside the third: each third of the stretch holds its own words.
            let today = line(.title) + SlopeMeasure.height(daily.ledge.name, .body, width: beside, at: type)
                + (daily.ledge.facts.map { SlopeMeasure.height($0, .detail, width: beside, at: type) } ?? 0) + 4
            let archive = line(.body) + (large ? 2 : 1) * line(.detail)
            column.stretches[0].height = max(column.stretches[0].height ?? 0, 1.5 * (today - line(.title) * 0.5 + line(.body) * 0.5 + 8),
                                              3 * (archive - line(.body) * 0.5 + (large ? 18 : 8)))
        }
        hollows = model.hollows.map { ($0, SlopeMenuPlan.hollowAfter($0)) }
        var needs: [CGFloat] = []
        for (t, tier) in model.tiers.enumerated() {
            let first = SlopeColumn.ledge(tier: t, level: 1), room = words(first, seat: 0).width
            var height: CGFloat
            if let below = tier.tier.below, !tier.open {
                height = SlopeGate.height(tier.tier, below: below, width: room, at: type)
            } else {
                height = line(.title) + 3 + SlopeMeasure.height(tier.progress, .detail, width: room, at: type)
                if let caption = model.packs, t == 0 { height += 3 + SlopeMeasure.height(caption, .detail, width: room, at: type) }
            }
            headers.append(height)
            column.stretches[t + 1].header = max(column.pitch, height + 40)
            // A row whose words need more than the pitch has its own.
            var rows: [CGFloat] = []
            for (i, ledge) in tier.ledges.enumerated() {
                let room = words(first + i, seat: i % 9).width
                var need: CGFloat = 0
                if ledge.state == .frontier {
                    let big = UIFontMetrics(forTextStyle: .title1).scaledValue(for: 28 * 1.15, compatibleWith:
                        UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(type)))
                    let name = UIFont.systemFont(ofSize: big, weight: .light)
                    let across = (ledge.name as NSString).size(withAttributes: [.font: name]).width
                    need = name.lineHeight * ceil(across / max(room - line(.body) * 1.6, 40))
                        + SlopeMeasure.height(ledge.facts ?? "", .label, width: room * 0.9, at: type) + 10
                } else if large {
                    need = SlopeMeasure.height(ledge.name, .body, width: room - line(.label) * 1.8, at: type)
                        + (ledge.marks != nil ? 16 : 0) + SlopeMeasure.height(ledge.facts ?? "", .detail, width: room * 0.9, at: type) + 8
                }
                // A hollow's row of its own at the largest sizes, in the room under this ledge.
                if large, t == 0, hollows.contains(where: { $0.after == i + 1 }) { need = max(need, line(.body)) + Self.hollowRow(type) }
                rows.append(need > 0 ? need + 60 : 0)
            }
            column.stretches[t + 1].rows = rows
            // At the overview a stretch is as tall as its words need, where that is more than its share of the screen.
            var need = Self.bandLead + line(.title) + 3 + SlopeMeasure.height(tier.reason ?? tier.progress, .detail, width: beside, at: type) + (large ? 18 : 8)
            if model.wayOn?.tier == tier.tier { need += line(.body) + 14 }
            if t == 0, let packs = model.packs {
                need += SlopeMeasure.height(packs, .detail, width: beside, at: type) + 10
                    + (model.packNames.map { SlopeMeasure.height($0, .detail, width: beside, at: type) + 2 } ?? 0)
            }
            needs.append(need)
        }
        // Each tier first takes what its words need; what is left of the tiers' share of the screen is shared out
        // evenly (1.6). Where the needs alone pass it, each has its need and the overview scrolls.
        let share = column.stretches.dropFirst().reduce(0) { $0 + ($1.height ?? 0) }
        let spare = max(share - needs.reduce(0, +), 0) / CGFloat(max(needs.count, 1))
        for (t, need) in needs.enumerated() { column.stretches[t + 1].height = need + spare }
        // Endless's word, its line and "new run" under its middle; the default sizes fit what the overview leaves.
        if model.modes, large { column.under = line(.title) / 2 + 2 * line(.detail) + line(.body) + 24 }
        self.headers = headers
        self.column = column
        deep = SlopeLay(column, z: 1)
        wide = SlopeLay(column, z: 0)
    }

    /// The level of plughole a shelf's offer lies under (8.1): Lens between 6 and 7, then every five; Debug's First
    /// Stir between 2 and 3.
    static func hollowAfter(_ offer: Offer) -> Int {
        switch offer {
        case .pack(.lens): 6
        case .pack(.escapement): 11
        case .pack(.prism): 16
        case .complete: 21
        default: 2
        }
    }

    /// A hollow's row of its own at the largest sizes: the opening, its name and its line.
    static func hollowRow(_ type: DynamicTypeSize) -> CGFloat { 58 + 2 * SlopeMeasure.line(.detail, at: type) + 24 }

    /// Where the dive's words start beside ledge `n`, and their room.
    func words(_ n: Int) -> (x: CGFloat, width: CGFloat) {
        let x = large ? 96 : deep.tips[n] + 18
        return (x, max(size.width - x - 16, 80))
    }

    /// The share of the screen's height at which the overview, at its top, holds ledge `n`.
    func overview(holding n: Int) -> CGFloat {
        (wide.tops[n] + 0.188 * size.height) / size.height
    }

    /// The first ledge of the stretch ledge `n` is in.
    private func first(of n: Int) -> Int { deep.ledge(stretch: deep.places[n].stretch) }

    /// Where the camera rests on ledge `n` (2.7), as the share it holds the ledge at: 0.49 of the height, unless that
    /// would cut its stretch's header by the top control; then the header whole, 24 pt under the control. Inside the
    /// dive's travel either way.
    func rest(on n: Int) -> CGFloat {
        let h = size.height, range = deep.travel(height: h)
        var camera = deep.tops[n] - 0.49 * h
        let s = deep.places[n].stretch, lead = deep.tops[first(of: n)] - Self.headerFoot
        let head = lead - headers[s], control = top + 44
        if headers[s] > 0, lead - camera > 0, head - camera < control + 24 { camera = head - control - 24 }
        camera = min(max(camera, range.lowerBound), range.upperBound)
        return (deep.tops[n] - camera) / h
    }

    /// Where a dive into `tier` lands: the first level without a best, else the first short of par, else its first
    /// ledge; a closed tier on its gate.
    func landing(_ tier: Tier) -> SlopeAim {
        let t = Tier.allCases.firstIndex(of: tier) ?? 0, first = SlopeColumn.ledge(tier: t, level: 1)
        guard tier.isOpen(), let n = tier.landing().flatMap(SlopeColumn.ledge(of:)) else {
            // The header, or the gate, whole under the top control.
            let h = size.height, range = deep.travel(height: h)
            let camera = min(max(deep.tops[first] - Self.headerFoot - headers[t + 1] - top - 44 - 24, range.lowerBound), range.upperBound)
            return SlopeAim(ledge: first, share: (deep.tops[first] - camera) / h)
        }
        return SlopeAim(ledge: n, share: rest(on: n))
    }

    /// The dive's aim for an offer's hollow: the ledge over it, a little above the middle, so the hollow is.
    func hollow(_ offer: Offer) -> SlopeAim {
        let n = SlopeColumn.ledge(tier: 0, level: Self.hollowAfter(offer))
        let h = size.height, range = deep.travel(height: h)
        let camera = min(max(deep.between(n) - 0.49 * h, range.lowerBound), range.upperBound)
        return SlopeAim(ledge: n, share: (deep.tops[n] - camera) / h)
    }

    /// The dive's foot: endless's word at the middle of the screen, held by the last ledge.
    var foot: SlopeAim {
        let n = deep.count - 1
        return SlopeAim(ledge: n, share: (deep.tops[n] - deep.travel(height: size.height).upperBound) / size.height)
    }

    /// The dive's aim for where the menu rests as it comes up; nil is the overview.
    func aim(_ rest: Menu.Rest) -> SlopeAim? {
        switch rest {
        case .overview: nil
        case let .ledge(level): SlopeColumn.ledge(of: level).map { SlopeAim(ledge: $0, share: self.rest(on: $0)) }
        case let .tier(tier): landing(tier)
        }
    }
}

// MARK: - The model

/// What the menu shows, read once as it comes up and again when a best, a purchase or the day could change it, never
/// on a frame of the camera's travel.
struct SlopeMenuModel {
    struct TierRows {
        let tier: Tier
        let open: Bool
        let levels: [Level]
        let ledges: [SlopeLedge]
        /// "13/27 at par".
        let progress: String
        /// Every level at par: its rock holds a seam of gold (`SlopeEggs`).
        let seam: Bool
        /// "opens with every whirlpool level solved"; nil for an open tier.
        let reason: String?
        let spoken: String
    }

    let tiers: [TierRows]
    /// The daily, the archive and endless show (plughole 23 solved, or the unlock).
    let modes: Bool
    let sandbox: Bool
    let daily: (level: Level, ledge: SlopeLedge)?
    /// The tier the player is in, and its frontier: the overview's way on.
    let wayOn: (tier: Tier, level: Level)?
    /// Endless's level, a saved run's or a new one's, its line and whether it is still marked new.
    let endless: Level
    let endlessLine: String?
    let endlessNew: Bool
    /// The best run's tanks, as lights under the word while no run is saved.
    let lights: Int
    let spokenEndless: (label: String, value: String, hint: String)
    /// The shelf's offers once the hollows show, the packs' line under plughole's name and, at the overview, their names.
    let hollows: [Offer]
    let packs: String?
    let packNames: String?
    /// The offer the packs' line dives to: the first marked new, else the first unowned, else the first.
    let packLead: Offer?
    /// The archive's row (2.5), and whether a tap opens it.
    let archive: SlopeLedge?
    let archiveOpen: Bool

    @MainActor init(today: Date, saved: Resume?, playing: Level?) {
        let unlocked = Best.unlocked, lead = Menu.lead(unlocked: unlocked)
        modes = lead.modes
        sandbox = lead.sandbox
        tiers = Tier.allCases.map { tier in
            let open = tier.isOpen(), levels = Array(tier.levels.prefix(27)), frontier = tier.frontier()?.id
            let ledges = levels.enumerated().map { i, level in
                Self.ledge(level, i, of: levels, tier: tier, open: open, unlocked: unlocked, frontier: frontier, playing: playing?.id)
            }
            let par = tier.atPar()
            return TierRows(tier: tier, open: open, levels: levels, ledges: ledges, progress: Menu.progress(tier),
                            seam: !par.isEmpty && par.allSatisfy { $0 }, reason: open ? nil : Menu.reason(tier),
                            spoken: open ? String(localized: "\(tier.word), \(par.filter { $0 }.count) of \(par.count) at par",
                                                  comment: "VoiceOver: a tier on the slope's overview. The tier, its levels at par, of all")
                                : tier.spoken)
        }
        // The tier the player is in carries the way on; with every level of it solved, the first open tier with one left.
        let stored = Tier.stored()
        wayOn = ([stored] + Tier.allCases).lazy.compactMap { tier in tier.frontier().map { (tier, $0) } }.first
        let new = !Best.modesSeen
        if lead.modes {
            let day = Level.daily(today), run = Daily.run(today: today), lines = Menu.dailyLines(day, run: run)
            let result = Best.load(day.id), tried = result == nil && Best.started(day.id)
            let mark = Archive.Mark(result, started: tried)
            let spoken = Spoken.marked(Spoken.row(day, result: result, tanks: 0, detail: lines.detail, enabled: true, needs: nil,
                                                  started: tried, new: new), playing: playing?.id == day.id)
            daily = (day, SlopeLedge(name: day.title, state: result == nil ? .next : .solved,
                                     marks: new && result == nil ? nil : ResultMarks.filled(mark), margin: ResultMarks.margin(mark),
                                     word: new && result == nil ? String(localized: "new") : nil, facts: lines.under,
                                     playing: playing?.id == day.id, label: spoken.label, value: spoken.value, hint: spoken.hint))
        } else {
            daily = nil
        }
        let kept = saved?.run, tanks = Best.tanks
        endless = .endless(kept ?? Run(seed: .random(in: .min ... .max)))
        endlessLine = Menu.endlessLine(saved, tanks: tanks)
        endlessNew = new && kept == nil
        lights = kept == nil ? min(tanks, 24) : 0
        spokenEndless = Spoken.marked(Spoken.row(endless, result: nil, tanks: tanks,
                                                 detail: kept != nil ? endlessLine : nil,
                                                 enabled: true, needs: nil, started: kept != nil, new: new && kept == nil),
                                      playing: playing?.run != nil)
        let store = Store.shared
        let shelf = Shop.shown() ? Offer.shelf().filter { $0 != .complete || store.offersComplete } : []
        hollows = shelf
        let sold = Pack.sold()
        packs = shelf.isEmpty ? nil : Menu.packsCaption(owned: sold.filter { store.state($0) == .owned }.count, of: sold.count)
        // A name keeps to one line: the names break only between them.
        packNames = shelf.isEmpty ? nil : shelf.map { $0.name.replacingOccurrences(of: " ", with: "\u{00A0}") }.joined(separator: " \u{00B7} ")
        packLead = shelf.first { offer in offer.pack.map { Marks.line($0, owned: store.state($0) == .owned || !store.ready, fits: $0.fits(), played: $0.tastePlayed())?.new == true } ?? false }
            ?? shelf.first { $0.pack.map { store.state($0) != .owned } ?? true } ?? shelf.first
        if lead.modes {
            let days = Archive.days(today: today).map { Level.daily($0, archived: true) }
            let atPar = days.filter { Best.load($0.id)?.over == 0 }.count
            // Unsaid until the store has read what the player owns, so an owner never meets it closed.
            let known = store.ready, open = known && Archive.open
            let spoken = Spoken.archiveRow(open: open, days: days.count, atPar: atPar)
            archiveOpen = open
            archive = SlopeLedge(name: String(localized: "Archive"), state: open ? .solved : .closed,
                                 facts: !known ? String(localized: "\(days.count) past dailies", comment: "The menu's archive row. Past dailies")
                                     : open ? String(localized: "\(days.count) past dailies \u{00B7} \(atPar) at par",
                                                     comment: "The menu's archive row, open. Past dailies, then those at par")
                                     : String(localized: "\(days.count) past dailies \u{00B7} comes with any pack",
                                              comment: "The menu's archive row, shut. Past dailies"),
                                 opens: known && !open ? String(localized: "unlocked by purchasing any pack") : nil, reason: true,
                                 label: spoken.label, value: spoken.value, hint: spoken.hint)
        } else {
            archive = nil
            archiveOpen = false
        }
    }

    /// A tier's level as its ledge's row (2.2).
    @MainActor private static func ledge(_ level: Level, _ i: Int, of levels: [Level], tier: Tier, open: Bool, unlocked: Bool,
                                         frontier: String?, playing: String?) -> SlopeLedge {
        let reached = Menu.reached(i, of: levels, unlocked: unlocked), enabled = open && reached
        let result = Best.load(level.id), tried = result == nil && Best.started(level.id)
        let mark = Archive.Mark(result, started: tried)
        let state: SlopeLedge.State = !enabled ? .closed : result != nil ? .solved : level.id == frontier ? .frontier : tried ? .tried : .open
        let spoken = Spoken.marked(Spoken.row(level, result: result, tanks: 0, detail: nil, enabled: enabled,
                                              needs: open && !reached ? levels[i - 1] : nil, gate: open ? nil : tier.below, started: tried),
                                   playing: level.id == playing, frontier: level.id == frontier)
        return SlopeLedge(number: level.label, name: level.title, state: state, marks: enabled ? ResultMarks.filled(mark) : nil,
                          margin: ResultMarks.margin(mark), facts: Menu.facts(level), playing: level.id == playing,
                          opens: Menu.closedLine(i, of: levels, below: tier.below, open: open, reached: reached),
                          glow: tier.rock.light, label: spoken.label, value: spoken.value, hint: spoken.hint)
    }
}

// MARK: - The world

/// Everything the menu sets on the main column, drawn from one view of it: the overview's words while the depth is
/// closed, the dive's once it has opened, and the pebbles all the way between.
private struct SlopeMenuWorld: View {
    let view: SlopeView
    let plan: SlopeMenuPlan
    let model: SlopeMenuModel
    /// Leaves out what is off the screen: the scene lays everything out again each frame, the dive once.
    let cull: Bool
    let held: String?
    let supporter: Bool
    let saved: Resume?
    /// "Lens is yours", standing under the wordmark while it is said (2.10).
    let yours: Offer?
    @Binding var arm: NewRunArm
    let voiceOver: Bool
    let hollow: ((Offer, SlopeSpot) -> AnyView)?
    let archiveLedge: ((SlopeSpot) -> AnyView)?
    let openSettings: () -> Void
    let enter: (Tier) -> Void
    /// The packs' line or a small hollow tapped at the overview: the dive to that offer's hollow.
    let visit: (Offer) -> Void
    let openArchive: () -> Void
    let pick: (Level, Int?) -> Void
    let newRun: () -> Void

    @AccessibilityFocusState private var newRunFocused: Bool

    private var lay: SlopeLay { view.lay }
    /// 1 in the dive, 0 until the depth is nearly open: the names fade in as the pitch passes 44 pt.
    private var near: Double { lay.e >= 1 ? 1 : min(max((lay.e - 0.8) / 0.2, 0), 1) }
    /// 1 at the overview, gone a fifth of the way in.
    private var wide: Double { lay.e <= 0 ? 1 : 1 - min(lay.e / 0.2, 1) }
    private var large: Bool { plan.large }
    /// The status bar's room, which the dive's words fade under; at the largest sizes, where the words stand under the
    /// top control, its room too.
    private var bars: CGFloat { plan.top + 8 + (large ? SlopeMeasure.line(.body, at: plan.type) + 16 : 0) }

    private func shown(_ y: CGFloat, _ reach: CGFloat = 120) -> Bool { !cull || y > -reach && y < view.size.height + reach }

    var body: some View {
        SlopeLayer {
            surface
            shallows
            ForEach(Array(model.tiers.enumerated()), id: \.offset) { t, tier in
                band(t, tier)
                header(t, tier)
                ForEach(Array(tier.ledges.enumerated()), id: \.offset) { i, ledge in
                    let n = SlopeColumn.ledge(tier: t, level: i + 1)
                    if shown(view.y(lay.tops[n])) {
                        SlopeLedgeRow(ledge: ledge, view: view, n: n, near: near, bars: bars, held: tier.levels[i].id == held) {
                            pick(tier.levels[i], n)
                        }
                    }
                }
            }
            hollows
            foot
            unnumbered
        }
    }

    /// The unnumbered pebble on its spur under the last ledge, the dive's alone (`SlopeEggs.nook`).
    @ViewBuilder private var unnumbered: some View {
        if near > 0, let nook = SlopeEggs.nook(lay), shown(view.point(nook.seat).y) {
            SlopeUnnumbered().opacity(near).rested(at: view.point(nook.seat))
        }
    }

    // MARK: The surface and the shallows

    /// The wordmark in the air, with the supporter's glint after it, and the settings' stone on the bank.
    @ViewBuilder private var surface: some View {
        let bank = view.bank
        if shown(bank.y, 200) {
            HStack(alignment: .top, spacing: 4) {
                Text(verbatim: "UNSTIR").font(.slope(.name, .display)).tracking(9).ink(.ink) // loc: verbatim the wordmark
                if supporter {
                    let light = SlopeColumn.Rock.sand.light
                    SupporterMark(sweep: LinearGradient(colors: [light, light], startPoint: .leading, endPoint: .trailing), glow: light)
                        .scaleEffect(14.0 / 13).padding(.top, 5)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(supporter ? Text("Unstir, supporter", comment: "VoiceOver: the menu's title, with the supporter mark") // loc: verbatim a key, or the name
                                : Text(verbatim: "Unstir")).accessibilityAddTraits(.isHeader)
            .slopePlace(CGPoint(x: 32, y: bank.y - 30), anchor: .bottomLeading)
            // The stone's own line holds a message while one stands: "Lens is yours" (2.10).
            HStack(spacing: 18) {
                Stone(action: openSettings) {
                    Text("settings", comment: "The slope's menu: the stone on the bank, which opens settings").font(.slope(.ui, .detail))
                }
                .accessibilityLabel("Settings")
                if let yours, wide > 0 {
                    Text(yours.yours).font(.slope(.place, .body)).foregroundStyle(yours.ink).opacity(wide) // loc: verbatim localized by Offer
                        .accessibilityHidden(true).transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: yours)
            .slopePlace(CGPoint(x: bank.x - 10, y: bank.y), anchor: UnitPoint(x: 0, y: 0.62))
        }
    }

    /// The daily on the first ledge under "today", and the archive two ledges down, once the daily opens; bare
    /// ledges until then.
    @ViewBuilder private var shallows: some View {
        if let daily = model.daily {
            let n = SlopeColumn.today, seat = view.seat(n)
            if shown(seat.y) {
                if wide > 0 {
                    // Beside the ledge at the overview: the header, the day and its run.
                    Button { pick(daily.level, n) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("today").font(.slope(.place, .title)).ink(.ink)
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(daily.ledge.name).font(.slope(.ui, .body)).ink(.ink) // loc: verbatim localized by Level.daily
                                if let word = daily.ledge.word {
                                    Text(word).font(.slope(.data, .detail)).ink(.ink) // loc: verbatim localized by the model
                                } else if let marks = daily.ledge.marks {
                                    ResultMarks(filled: marks, margin: daily.ledge.margin)
                                }
                            }
                            if let facts = daily.ledge.facts {
                                Text(facts).font(.slope(.data, .detail)).ink(.ink2) // loc: verbatim localized by Menu.dailyLines
                            }
                        }
                        .multilineTextAlignment(.leading)
                        .frame(width: plan.room, alignment: .leading)
                        .hit(12, 0)
                    }
                    .modifier(Speech((daily.ledge.label, daily.ledge.value, daily.ledge.hint)))
                    .opacity(wide).allowsHitTesting(wide >= 1)
                    .slopeLine(CGPoint(x: plan.beside, y: seat.y - 8))
                }
                if near > 0 {
                    Text("today").font(.slope(.place, .title)).ink(.ink).accessibilityAddTraits(.isHeader).opacity(near).slopeUnderBars(bars)
                        .slopePlace(CGPoint(x: plan.words(n).x, y: view.y(lay.tops[n]) - SlopeMenuPlan.headerFoot + 22), anchor: .bottomLeading)
                }
                SlopeLedgeRow(ledge: daily.ledge, view: view, n: n, near: near, bars: bars) { pick(daily.level, n) }
            }
            let a = SlopeColumn.archive, at = view.seat(a)
            if shown(at.y) {
                let spot = SlopeSpot(view: view, ledge: a, point: at, side: lay.half(.dull) * 2, near: near)
                if let archiveLedge {
                    archiveLedge(spot)
                } else if let archive = model.archive {
                    // Until piece E's lands: the archive's row by 2.5, closed until any pack is bought.
                    if wide > 0 {
                        Button { model.archiveOpen ? openArchive() : () } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(archive.name).font(.slope(.ui, .body)).ink(model.archiveOpen ? .ink : .ink4) // loc: verbatim localized by the model
                                if let facts = archive.facts { Text(facts).font(.slope(.ui, .detail)).ink(.ink3) } // loc: verbatim localized by the model
                            }
                            .multilineTextAlignment(.leading)
                            .frame(width: plan.room, alignment: .leading)
                            .hit(12, 0)
                        }
                        .modifier(Speech((archive.label, archive.value, archive.hint)))
                        .opacity(wide).allowsHitTesting(wide >= 1)
                        .slopeLine(CGPoint(x: plan.beside, y: at.y - 4))
                    }
                    SlopeLedgeRow(ledge: archive, view: view, n: a, near: near, bars: bars, open: openArchive)
                }
            }
        }
    }

    // MARK: A tier

    /// A tier at the overview: its whole band is the way into it, and beside it stand its name, its progress or
    /// what opens it, and, on the tier the player is in, the way on.
    @ViewBuilder private func band(_ t: Int, _ tier: SlopeMenuModel.TierRows) -> some View {
        if wide > 0 {
            let first = SlopeColumn.ledge(tier: t, level: 1), top = view.y(lay.tops[first])
            let next = t + 1 < model.tiers.count ? view.y(lay.tops[first + 27]) : view.y(lay.foot)
            Button { enter(tier.tier) } label: {
                Color.clear.frame(width: view.size.width, height: max(next - top, 44)).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(tier.spoken) // loc: verbatim localized by the model
            .allowsHitTesting(wide >= 1)
            .slopePlace(CGPoint(x: 0, y: top - 10), anchor: .topLeading)
            VStack(alignment: .leading, spacing: 3) {
                // The band's own button says both to VoiceOver.
                Text(tier.tier.word).font(.slope(.place, .title)).ink(tier.open ? .ink : .ink4).accessibilityHidden(true) // loc: verbatim localized by Tier.word
                Text(tier.reason ?? tier.progress).font(.slope(tier.open ? .data : .ui, .detail)).ink(.ink3).accessibilityHidden(true) // loc: verbatim localized by Menu
                if let way = model.wayOn, way.tier == tier.tier, let n = SlopeColumn.ledge(of: way.level) {
                    Button { pick(way.level, n) } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(way.level.label).font(.slope(.data, .body)).ink(.ink) // loc: verbatim a number
                            Text(verbatim: way.level.title + " \u{203A}").font(.slope(.name, .body)).ink(.ink)
                        }
                        .padding(.top, 4)
                        .hit(12, 12)
                    }
                    .accessibilityLabel(Text("next, \(way.level.label), \(way.level.title)",
                                             comment: "VoiceOver: the slope's overview, the way on. The next level's number, then its name"))
                    .allowsHitTesting(wide >= 1)
                }
                if t == 0, let packs = model.packs, let lead = model.packLead {
                    // The packs' line and their names: with the small hollows in the rock, the way to them.
                    Button { visit(lead) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(packs).font(.slope(.ui, .detail)).ink(.ink3) // loc: verbatim localized by Menu.packsCaption
                            if let names = model.packNames { Text(names).font(.slope(.ui, .detail)).ink(.ink2) } // loc: verbatim the packs' names
                        }
                        .multilineTextAlignment(.leading)
                        .padding(.top, 5)
                        .hit(8, 12)
                    }
                    .allowsHitTesting(wide >= 1)
                }
            }
            .frame(width: plan.room, alignment: .leading)
            .accessibilityElement(children: .contain)
            .opacity(wide)
            .slopePlace(CGPoint(x: plan.beside, y: top + SlopeMenuPlan.bandLead), anchor: .topLeading)
        }
    }


    /// A tier's header in the dive, over its first ledge at the words' x: its name, its progress and, under
    /// plughole's, the packs' caption; a closed tier's is its gate.
    @ViewBuilder private func header(_ t: Int, _ tier: SlopeMenuModel.TierRows) -> some View {
        let first = SlopeColumn.ledge(tier: t, level: 1), foot = view.y(lay.tops[first]) - SlopeMenuPlan.headerFoot
        if near > 0, shown(foot, 400) {
            let at = plan.words(first)
            Group {
                if let below = tier.tier.below, !tier.open {
                    SlopeGate(tier: tier.tier, below: below, rock: tier.tier.rock, width: at.width) { pick($0, SlopeColumn.ledge(of: $0)) }
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(tier.tier.word).font(.slope(.place, .title)).ink(.ink).accessibilityAddTraits(.isHeader) // loc: verbatim localized by Tier.word
                        Text(tier.progress).font(.slope(.data, .detail)).ink(.ink3) // loc: verbatim localized by Menu.progress
                        if t == 0, let caption = model.packs {
                            Text(caption).font(.slope(.ui, .detail)).ink(.ink3) // loc: verbatim localized by Menu.packsCaption
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .frame(width: at.width, alignment: .leading)
                }
            }
            .opacity(near)
            .slopeUnderBars(bars)
            .slopePlace(CGPoint(x: at.x, y: foot), anchor: .bottomLeading)
        }
    }

    // MARK: The hollows and the foot

    /// The packs' hollows in plughole's wall (8.1). At the overview they are small in the rock on the leading side of
    /// plughole's terraces, 16 pt across and 24 pt apart; as the depth opens each travels to its place between two
    /// ledges and grows to 58 pt.
    @ViewBuilder private var hollows: some View {
        let first = SlopeColumn.ledge(tier: 0, level: 1), e = lay.e
        ForEach(Array(plan.hollows.enumerated()), id: \.element.offer) { i, place in
            let above = SlopeColumn.ledge(tier: 0, level: place.after), side = 16 + 42 * e
            // At the largest sizes there is no rock beside the ledges: the hollow has a row of its own under its ledge.
            let deep = large ? view.y(lay.tops[above] + lay.drops[above] - SlopeMenuPlan.hollowRow(plan.type) - 6)
                : view.y(lay.between(above)) - side / 2
            let far = view.y(lay.tops[first]) + 24 + 24 * CGFloat(i) - 8
            let x = 18 + ((large ? 48 : 56) - 18) * e, y = far + (deep - far) * e
            if shown(y) {
                let spot = SlopeSpot(view: view, ledge: above, point: CGPoint(x: x, y: y), side: side, near: near)
                Group {
                    if let hollow {
                        hollow(place.offer, spot)
                    } else {
                        AnyView(SlopePebble(kind: .dull, width: lay.half(.dull) * 2, lean: SlopePebble.lean(place.after))
                            .frame(width: side, height: side))
                    }
                }
                // The pinned way back wins: a hollow fades whole as it rises to it.
                .slopeUnderBars(near > 0 ? plan.top + 52 : 0, lead: 0)
                // At the overview a tap on one dives to it, and the packs' line speaks for them all; in the dive the
                // hollow's own view takes its taps.
                .overlay {
                    if wide >= 1 {
                        Button { visit(place.offer) } label: { Color.clear.contentShape(Rectangle()).hit(14, 14) }
                            .buttonStyle(.plain).accessibilityHidden(true)
                    }
                }
                .slopePlace(spot.point, anchor: .top)
            }
        }
    }

    /// The drop-off: endless in the open water under the last ledge, with nothing to rest on.
    @ViewBuilder private var foot: some View {
        let y = view.y(lay.endless), x = view.size.width * 0.57
        if model.modes, shown(y, 300) {
            let continues = saved?.run != nil
            VStack(spacing: 4) {
                Button { pick(model.endless, nil) } label: {
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("endless", comment: "The slope's menu: endless, written as a place under the last ledge")
                                .font(.slope(.place, .title)).ink(.ink)
                            if model.endlessNew { Text("new").font(.slope(.data, .detail)).ink(.ink) }
                        }
                        if let line = model.endlessLine {
                            Text(line).font(.slope(.data, .detail)).ink(continues ? .ink2 : .ink3) // loc: verbatim localized by Menu.endlessLine
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: view.size.width - 48)
                    .hit(10, 16)
                }
                .modifier(Speech(model.spokenEndless))
                if continues { newRunControl.opacity(max(near, wide)) }
                if model.lights > 0 { lights }
            }
            .slopePlace(CGPoint(x: x, y: y), anchor: UnitPoint(x: 0.5, y: 0))
            // At the overview the word stands as much higher as keeps its line and "new run" clear of the home bar.
            .offset(y: -SlopeMeasure.line(.title, at: plan.type) / 2 - (large ? 0 : lift(from: y, continues: continues) * (1 - lay.e)))
        }
        if model.sandbox, near > 0, shown(y, 400) {
            // Debug's sandbox, out of v1: a plain row under the brink.
            Button { pick(.sandbox, nil) } label: {
                Text("anything goes").font(.slope(.ui, .body)).ink(.ink3).hit()
            }
            .opacity(near)
            .slopePlace(CGPoint(x: x, y: y + 0.36 * view.size.height))
        }
    }

    /// How far endless's words rise at the overview so their last line ends 8 pt over the bottom safe area.
    private func lift(from y: CGFloat, continues: Bool) -> CGFloat {
        func line(_ s: SlopeSize) -> CGFloat { SlopeMeasure.line(s, at: plan.type) }
        // Measured where the camera rests: pulled past an end of its travel, the words go with the water.
        let travel = lay.travel(height: view.size.height)
        let y = y + view.top - min(max(view.top, travel.lowerBound), travel.upperBound)
        let words = line(.title) / 2 + (model.endlessLine != nil ? 4 + line(.detail) : 0) + (continues ? 10 + line(.body) : 0)
        return max(y + words - (view.size.height - plan.bottom - 8), 0)
    }

    /// One small light per tank of the best run, hanging in the dark: how far down the player has been.
    private var lights: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< model.lights, id: \.self) { i in
                let fade = 1 - Double(i) / 26
                Circle().fill(RadialGradient(colors: [Color(0xFFE8B4).opacity(0.9 * fade), Color(0xFFE8B4).opacity(0)], center: .center,
                                             startRadius: 0, endRadius: 4))
                    .frame(width: 8, height: 8).frame(height: 14)
            }
        }
        .padding(.top, 10)
        .frame(height: 24, alignment: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// "new run" under a saved run's line: a first tap arms it for two seconds, in amber, and a second drops the run
    /// and starts another; under VoiceOver it stays armed until focus leaves.
    private var newRunControl: some View {
        Button {
            guard arm.tap(held: voiceOver) else {
                AccessibilityNotification.Announcement(String(localized: "Tap again for a new run",
                                                                comment: "VoiceOver: endless's new run, armed")).post()
                return
            }
            newRun()
        } label: {
            (!arm.armed ? Text("new run", comment: "Endless's row: drops the saved run")
                : Text("new run? tap again", comment: "Endless's row: armed, a second tap drops the saved run"))
                .font(.slope(.ui, .body)).foregroundStyle(arm.armed ? Page.night.stop : SlopeInk.ink2.colour).hit()
        }
        .accessibilityLabel(!arm.armed ? Text("New run", comment: "VoiceOver: starts a new endless run") // loc: verbatim each a key
                            : Text("New run, tap again to confirm", comment: "VoiceOver: endless's new run, armed"))
        .accessibilityHint("Drops the saved run and starts another.")
        .accessibilityFocused($newRunFocused)
        .onChange(of: newRunFocused) { if !newRunFocused && voiceOver { arm.disarm() } }
        .task(id: arm) {
            guard arm.armed, !voiceOver, (try? await Task.sleep(for: .seconds(ResetArm.window))) != nil else { return }
            arm.disarm()
        }
        .padding(.top, 6)
    }
}
