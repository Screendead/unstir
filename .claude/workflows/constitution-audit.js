export const meta = {
  name: 'constitution-audit',
  description: 'Audit Unstir code against CONSTITUTION.md: each owner brings one area into line and commits on its own branch; nothing is only reported',
  whenToUse: 'Between waves, when no other worker edits the code: every few waves, or when the suite or the code has grown. Args: {base: "<ref>", tag: "<short id, e.g. a1>", constitution: "<path, only when base lacks CONSTITUTION.md>"}.',
  phases: [{ title: 'Audit', detail: 'eight owners, one area each, fixing in their own worktree' }],
}
const base = (args && args.base) || 'origin/master'
const tag = (args && args.tag) || 'a1'
const constitution = (args && args.constitution) || 'CONSTITUTION.md in your worktree'
const REPO = '~/development/unstir'
const ROOT = '~/development/unstir-worktrees'
const T = 'UnstirTests'
const common = (name) => `
You are a senior owner at the studio making Unstir, an iPhone puzzle game (SwiftUI + Metal). Read ${constitution} first, then the global code rule: comments state constraints the code cannot show, and nothing else; an abstraction exists only to remove a repeated idea; notes and analysis stay out of tracked files unless they are a document someone asked for.

Your piece: bring one area of the code into line with the constitution and that rule. You fix what you find and commit it; nothing is only reported. You are not reviewing anyone: you own this area's fitness now.

Set up, with the Bash sandbox disabled (git worktree add and the Metal toolchain need it): git -C ${REPO} worktree add -b audit/${name} ${ROOT}/${name} ${base}; then xcrun metal --version once. Work only in ${ROOT}/${name}. Commit as you go, atomic commits with plain messages (no attribution, no model names, nothing personal); do not push. Do not edit CONSTITUTION.md, HANDOFF.md, HANDOFF.private.md, docs/decisions.md or docs/history.md. Other owners audit other areas at the same time: stay in yours.

Never touch, whatever they look like:
- Stored names and the pins on them (Never rename a stored value; PackTests' and AchievementTests' pins), the frozen generator and its vectors (testDailyVectors, testEndlessVectors), testThePrintNeverChanges, testNoLaterPackJoinsTheBundle, testNoTrackedConfigHoldsAPrivateValue, testADefaultBuildHasNoEditorsSwitch, CatalogTests' loc-lint, or a test or comment that cites one of Jack's calls.
- Any test named in CLAUDE.md, docs/architecture.md or .github/workflows (the -skip-testing lists): keep its name.
- Copyright header lines.
- Code a test, a script (scripts/ cuts SplitMix64 and the generator out of Levels.swift, Picture.cells out of LivePictures.swift, and compiles Twist.swift and Solver.swift), a launch variable (UNSTIR_*, the harness cases) or a compilation condition (EDITORS, PROBES, DEBUG) reaches: a "no caller" claim needs a search of Sources/, UnstirTests/, scripts/, project.yml and Config/.
- What the player sees or hears. This audit changes no behaviour.

Behaviour must not change. Prove it the cheapest way that could fail. Build: from your worktree, xcodegen generate --quiet && xcodebuild build-for-testing -project Unstir.xcodeproj -scheme Unstir -destination 'generic/platform=iOS Simulator' -derivedDataPath build CODE_SIGNING_ALLOWED=NO -quiet. Tests: make your own simulator (xcrun simctl create "Unstir Agent ${name}" "iPhone 17 Pro Max"), run xcodebuild test-without-building with the same project, scheme and derivedDataPath and -destination 'platform=iOS Simulator,id=<its udid>', with -only-testing:${T}/<Class> for each class your area touches; at the end shut it down and xcrun simctl delete it. Never use "Unstir iPhone 17 Pro Max", another owner's simulator or the phone. Trash, never rm. Keep this Mac's load short: build once before and once after, not after every edit.

When you remove or rename something docs/architecture.md describes, fix its entry in the same commit.

Hand-in (at most 150 words): what you removed or changed and why, in numbers where they exist (tests, lines, seconds), anything you judged should stay against first appearance and why, commit ids.
`
const testOwner = (files) => `YOUR AREA: these files in ${T}/: ${files}. The constitution: "The eye is the test." Time your classes first on your simulator (xcodebuild prints seconds per test; note them). For each test decide: does it guard something the eye cannot see (a save, purchase or achievement that must load, a level the generator or solver must deal or prove, the shader and its Swift copy agreeing, a store or privacy rule, a crash) that would be costly to break unnoticed? Keep those, made fast. Delete tests that only prove a piece was done, pin today's tuning numbers, duplicate another test, or are stale; merge near-duplicates; cut the cost of slow ones (fewer screens, sizes or frames sampled where every case walks the same code) without losing what they guard. A layout or look the eye checks on a screenshot is the eye's, not a test's. Helpers used only by deleted tests go too. Report the before and after count and time of your classes.`
const codeOwner = (area) => `YOUR AREA: ${area}. Read every file. Remove comments that narrate, restate the code, record history ("was", "before", "now", "used to", dates, PR numbers) or hold analysis; keep and sharpen those stating a constraint the code cannot show. Remove dead code (unused functions, parameters, flags, branches no caller reaches: prove with the search above) and abstractions that wrap one use. Leave formatting alone; do not rename for taste.`
const parts = {
  [`${tag}-tests-layout`]: testOwner('PlayLayoutTests.swift (about 92 of the suite\'s 196 seconds on CI)'),
  [`${tag}-tests-core`]: testOwner('UnstirTests.swift (152 tests)'),
  [`${tag}-tests-packs`]: testOwner('EscapementTests, LensTests, LensDetailTests, PrismTests, StirMapTests.swift (StirMapTests and StirMapPackTests), PackTests'),
  [`${tag}-tests-rest`]: testOwner('SolverTests and Solver.swift, TapLawTests, TapsTests, SoundTests, ToneTests, AnalyticsTests, AchievementTests, SyncTests, CatalogTests, AgeCheckTests, ResumeTests, ShareTests, ArchiveTests, ClipTests, HandTests, PayoffTests, ResultMarksTests, ShaderKit.swift and FreshDefaults.swift (shared: keep what others use), StoreTests.swift (LedgerTests here; StoreTests only through scripts/test-store.sh test -destination \'platform=iOS Simulator,id=<udid>\' -only-testing:UnstirTests/StoreTests) and FirstStirTests (the nightly runs it; its render takes two minutes, so time it once)'),
  [`${tag}-play`]: codeOwner('the game and its screens in Sources/: TankView, Game, Menu, Shelf, UnstirApp, PlayLayout, Buttons, Page, Type, Payoff, PayoffViews, ResultCard, ResultMarks, Lessons, Hand, Rods, Power, Frost, FrostLook, Spoken, Consent, AgeRange, Share, ShareSheet, EscapementViews, DragProbe, Clip. Prove with the build and the classes that cover them (PlayLayoutTests, UnstirTests, ClipTests, HandTests, PayoffTests, ResumeTests)'),
  [`${tag}-model`]: codeOwner('the model and services in Sources/: Twist, Levels, Pack, Store, Sync, Analytics, Archive, Resume, Achievements, GameCenter, Taps, TapLaw, Log, StirMap, Sound, Tone, GPUBench, OracleBench. Prove with the build, the classes that cover them (UnstirTests, PackTests, SolverTests, TapLawTests, TapsTests, SoundTests, AnalyticsTests, SyncTests, StirMapTests, StirMapPackTests) and scripts/solve.sh quad 0:+3,2:-4 0 before and after (same output)'),
  [`${tag}-render`]: codeOwner('the drawing code: every .metal file in Sources/ with Shader.swift (Unstir.metal and its Swift copy Tank.profile, Tank.twist, Tank.lens change together), Halftone, Pictures, LivePictures, VortexPictures, Engraving, Brim, Icon, StoryScene, LensArt*, EscapementArt*, FirstStir*. Prove with the build, LensDetailTests, PrismTests, EscapementTests and StirMapPackTests, scripts/picture-lab.sh render on two pictures before and after, and UNSTIR_SIM=<your udid> scripts/shots.sh on a few cases (a whirlpool, a Lens, an Escapement and a Prism level) before and after: look at each pair with Read; they must match'),
  [`${tag}-tools`]: `YOUR AREA: scripts/, tools/, .github/workflows and the documents: README.md, docs/architecture.md, docs/testflight.md, docs/store-page.md and the design docs, and the Commands section of CLAUDE.md. Delete scripts nothing uses any more (search the repo, the docs and the workflows for callers); make docs that describe code and commands match the code (fix or cut what is wrong); cut repeated or stale material where git holds the history. Do not rewrite decisions, pitches or Jack's quotes. Run scripts/doc-size.sh, actionlint .github/workflows/*.yml if you touch a workflow, and bash -n on each script you edit; no app build is needed unless you change project.yml.`,
}
const picks = {
  // Opus: which tests guard real risk is judgement a plausible wrong deletion would hide; medium: one bounded list each.
  [`${tag}-tests-layout`]: ['opus', 'medium'],
  [`${tag}-tests-core`]: ['opus', 'medium'],
  [`${tag}-tests-packs`]: ['opus', 'medium'],
  [`${tag}-tests-rest`]: ['opus', 'medium'],
  // Sonnet: comment and dead-code removal is checked by the build, the tests and a search; medium: many files to read.
  [`${tag}-play`]: ['sonnet', 'medium'],
  [`${tag}-model`]: ['sonnet', 'medium'],
  // Opus: drawing code where a removed line can change the picture subtly; medium: proved by renders and shots.
  [`${tag}-render`]: ['opus', 'medium'],
  // Sonnet: unused scripts and stale docs are found by searching; medium: broad but shallow.
  [`${tag}-tools`]: ['sonnet', 'medium'],
}
phase('Audit')
const results = await parallel(Object.keys(parts).map(name => () =>
  agent(common(name) + parts[name], { label: name, phase: 'Audit', model: picks[name][0], effort: picks[name][1] })
    .then(r => ({ name, branch: `audit/${name}`, worktree: `${ROOT}/${name}`, report: r }))))
return results.filter(Boolean)
