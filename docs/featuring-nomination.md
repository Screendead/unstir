# Apple featuring nomination

A brief for the App Store featuring nomination, item 58 of the plan. Part 1 covers how nominations work. Part 2 says
what the game can truthfully claim. Part 3 is a prompt for a writing model. It holds everything that model needs, so it
reads no files and opens no pages. Drafted 2026-11-23. Apple's pages were read that day, and the product facts were
checked against `master` that day.

## 1. How nominations work

Read on 2026-11-23 from Apple's "Getting featured" page (developer.apple.com/app-store/getting-featured/) and the App
Store Connect help page "Nominate your app for featuring". The first page was read word for word. The help page came
through as a summary, so its field details are not quoted.

- **Where.** App Store Connect → Apps → Unstir → Featuring → Nominations → "+" → Create Nomination. It needs the
  Account Holder, Admin, App Manager or Marketing role, so the developer account must exist first.
- **Types.** App Launch ("the launch or pre-order of your new app or game"), New Content (new content, offers or
  events), and App Enhancements (new features or significant updates). v1 is an **App Launch**. Later packs and big
  updates can each get their own nomination as New Content or App Enhancements. Apple states no limit on how many
  nominations you send.
- **Fields.** The form asks for:
  - a name for the nomination (Apple's eyes only)
  - the type
  - a description: the 1,000-character box, "Tell us the details of your nomination"
  - the publish date, a day or a range
  - related apps, up to 10
  - countries and regions (pre-filled from the app's availability)
  - localizations (pre-filled)
  - optional In-App Events
  - **Supplemental Materials**: up to 5 URLs, which may include "TestFlight public links" and art assets
  - **Helpful Details**: accessibility, inclusivity, priority, "unique aspects of your app or team"

  The help page states no character limits. The 1,000 is what the form itself shows.
- **Timing.** The "Getting featured" page: "a minimum of two weeks notice… we recommend submitting a nomination up to
  three months in advance". The help page asks for at least three weeks. Go by the longer one: send it as soon as the
  launch date is set, ideally three months ahead.
- **After sending.** The type and related apps are fixed once submitted; everything else can be edited and resubmitted.
  If the game is considered, Apple may email Admin, App Manager and Marketing users for promotional artwork. That
  artwork is separate from the store screenshots.
- **What editors weigh** ("there's no checklist of requirements"): user experience, UI design, innovation, uniqueness
  ("a fresh approach to a familiar category"), accessibility, localization, and the product page. For games they also
  weigh gameplay design, art, controls, technical performance and overall value. Monetisation is not a listed
  criterion. Still, a game with no ads, nothing sold for advantage and no dark patterns is what editors tend to
  feature. That last point is a reading of what they feature, not a rule Apple states.

### Using the other fields well

- **Supplemental Materials (5 links)** carry the proof, so the description doesn't need to describe the links:
  - the editors' TestFlight public link: the build with the visible "open every tier" switch, for editors only
  - the editors' reel: a 60-second film of the later tiers and packs
  - the App Store preview
  - optionally a social clip or a press page
- **Helpful Details** is the place for accessibility at length and for "unique aspects of the team". A solo developer
  is exactly such an aspect.
- **Localizations.** The game is English only. Localization is one of Apple's criteria, so this is the weakest line in
  the nomination. Every string is already in a String Catalog, ready to translate. Translating into even a few
  languages before launch would strengthen the nomination more than any wording could.

## 2. What the game can claim

Checked against `master` on 2026-11-23.

**True, and worth saying:**
- One developer made the game: code, pictures, sound and puzzle design.
- **The mechanic.** A picture sits in a glass tank of thick fluid. Rods under the glass have stirred it in turn, and
  each stir left a ring of sheared picture. Turn the rods back in the right order and the picture snaps clean.
- **The rule.** The last stir is on top: where two rings cross, the newer one runs unbroken across the older. Letting
  go of a knob where you started does nothing, so you can look before you commit.
- **Free: four tiers of 27 levels, 108 levels in all.**
  - Plughole: neon pictures, three to seven rods.
  - Whirlpool: live pictures that move as you play (glass, chainmail, coral, neurons, marbled ink).
  - Vortex: a swirl as wide as the glass, stirring through every other rod.
  - Maelstrom: seized knobs. You turn the whole tank to bring seams round to a working knob, and some levels need a
    plan.

  Each tier opens when every level of the one before it is solved.
- **Every day.** One daily tank for everyone on the same date. About one day in seven is a frost day, when two knobs
  freeze. The daily is shared as three dots: solved, at par, clean. Endless mode has no undo, reset or par; a brim
  fills with every wasted stir and spills at eight.
- **Three paid packs**, each with its own rule. The first three levels of each are free to play.
  - Lens: 25 panels where some rods zoom instead of turning, read against a halftone dot screen.
  - Escapement: 30 composed problems with clocks that tick a step after every move.
  - Prism: 30 specimens drawn in red, green and blue light, where each rod stirs only some of the colours.

  Triptych I bundles all three. Family Sharing is on. Any purchase also opens the archive of past dailies and adds a
  small supporter mark, which can be switched off.
- **Fair monetisation.** No ads, no timers, no energy, no account. Undos are never sold: a small bank refills on each
  day you play. Reset is free.
- **Privacy.** The privacy label is Data Not Collected. Progress stays on the phone. The rating is expected to be 4+.
- **Craft.**
  - The app bundles no image files: every picture is drawn by code, and the live ones are Metal shaders that move as
    you play.
  - All sound is synthesised from the game's own sources: a music bed, and a layer for each pack.
  - Haptics.
  - 16 Game Center achievements.
- **Accessibility.**
  - VoiceOver speaks what the screen shows as glyphs, counts or colour.
  - Reduce Motion has its own still versions of every animation.
  - Text follows Dynamic Type, and the tank shrinks to make room rather than the text.
  - Colour letters follow Differentiate Without Colour.
  - Sound, music and haptics each have their own switch.
- **Par.** Every level has a par, the fewest moves that unstir it. Tests prove par is the solver's optimum for Vortex,
  Maelstrom, Lens and Prism. Escapement's book is proved by its own prover. No test was found for Plughole and
  Whirlpool, so say "every level has a par, its fewest moves" and don't claim "proved for every level".

**Never claim:**
- leaderboards (there are none)
- any language but English
- iPad, Mac or Vision Pro (iPhone only, iOS 17 and later)
- iCloud sync (off in v1)
- analytics
- First Stir (out of v1)
- availability in the EU or EEA at launch (not sold there at first)
- a finished iPhone Duo layout (its last stage needs a real device)
- press, awards, tester numbers or reviews

**Only Jack can fill:**
- the launch date
- whether the editors' TestFlight link and reel will be in the links
- any line about himself beyond "made by one developer"
- whether a pre-order is planned

## 3. The prompt

Paste everything inside the fence into the writing model as is. Before pasting the result, fill the [BRACKETS] and
check its length with `pbpaste | wc -m`.

```text
You are writing the text for one box on Apple's App Store featuring nomination form, for an iPhone game called Unstir. The box is labelled "Tell us the details of your nomination. Only the App Store team will see this." Its hard limit is 1,000 characters, spaces and line breaks included. You have everything you need below. Do not invent any fact that is not listed here.

WHO READS IT
Apple's App Store editors. They read many of these. They pick games for features and stories by user experience, UI design, innovation, uniqueness ("a fresh approach to a familiar category"), accessibility, localization and the quality of the product page. For games they also weigh gameplay design, art, controls, technical performance and overall value. They want to grasp in seconds what the game is, why it is different, and why it is worth featuring. Marketing language counts against you. Specific, verifiable detail counts for you.

THE NOMINATION
Type: App Launch. Launch date: [LAUNCH DATE]. Other fields on the same form already carry the links (an editors' TestFlight build with every tier open, and a 60-second film of the later tiers), the dates and the countries, so do not spend characters describing links, dates or countries. One short closing clause may note that an editors' build is linked.

THE GAME (all confirmed true)
- Made by one developer: code, pictures, sound and puzzle design.
- Mechanic: a picture sits in a glass tank of thick fluid. Rods under the glass have stirred it in turn, each stir leaving a ring of sheared picture. The player turns the rods back in the right order and the picture snaps clean.
- The rule to read: the last stir is on top. Where two rings cross, the newer one runs unbroken across the older. Letting go of a knob where you started does nothing, so you can look before committing.
- Free: 108 levels in four tiers of 27. Plughole (neon pictures, three to seven rods), Whirlpool (live pictures that move as you play: glass, chainmail, coral, neurons, marbled ink), Vortex (a swirl as wide as the glass that stirs through every other rod), Maelstrom (seized knobs: the player turns the whole tank to bring seams round to a working knob; some levels need a plan). Each tier opens when the one before it is solved.
- Every level has a par, its fewest moves.
- A daily tank, the same for everyone on the same date. About one day in seven is a frost day, when two knobs freeze. The result is shared as three dots: solved, at par, clean. Endless mode: no undo, reset or par; a brim fills with every wasted stir and spills at eight.
- Three paid packs, each adding a new rule. The first three levels of each are free. Lens (25 panels): some rods zoom instead of turning, read against a halftone dot screen. Escapement (30 composed problems): clocks tick a step after every move. Prism (30 specimens): each picture is drawn in red, green and blue light, and each rod stirs only some colours. Triptych I bundles all three. Family Sharing is on.
- Monetisation: no ads, no timers, no energy, no account. Undos are never sold; a small bank refills each day you play. Reset is always free.
- Privacy label: Data Not Collected. Progress stays on the phone.
- Craft: the app ships no image files. Every picture is drawn by code, and the live pictures are Metal shaders that move as you play. All sound and music is synthesised from the game's own sources. Haptics. 16 Game Center achievements.
- Accessibility: VoiceOver labels everything shown as a glyph, count or colour. Reduce Motion has still versions of every animation. Text follows Dynamic Type, and the tank shrinks to make room rather than the text. Colour letters follow Differentiate Without Colour.
- iPhone only, iOS 17 and later. English only.

NEVER SAY OR IMPLY
Leaderboards, other languages, iPad, Mac, Vision Pro, iCloud sync, a story mode, press, awards, reviews, player or tester numbers, "relaxing", "addictive", "unique", "innovative", "stunning", "revolutionary", "beautiful", "perfect for", or any comparison with another game. Do not call it "a match-3", "a sliding puzzle" or "a Rubik's cube": it is none of those.

WHAT TO WRITE
1. Open with one sentence that makes an editor see the mechanic: a stirred picture and rods turned back in order. Make it concrete enough to picture, not abstract.
2. Then what makes it worth featuring, in this order of weight: the new mechanic and its one readable rule; the depth (four free tiers that each add something, then three packs that each add a rule); the craft (pictures drawn live in Metal, synthesised sound, made by one person); fairness (no ads, undos never sold, Data Not Collected); accessibility in one short clause.
3. Leave out anything that does not fit. Depth of one strong point beats a list of everything.

STYLE
Plain British English. Short declarative sentences. Present tense. No exclamation marks, emoji, headings, bullet points, quotation marks or markdown: it is a plain-text box. At most three short paragraphs separated by single blank lines. Write as the developer, in the first person singular ("I made"), sparingly. Name the tiers and packs only where the name adds something an editor can picture.

LENGTH
Aim for 800 to 900 characters, so the developer has room to add a line. Never exceed 950. You cannot count characters reliably, so keep it short: roughly 130 to 150 words.

OUTPUT
Give three versions, each with a different opening angle:
A. Lead with the mechanic.
B. Lead with the one-person craft.
C. Lead with fairness and the daily.
Put each version alone in its own plain code block, with nothing else inside the block. After the three, give one line per version naming its single strongest sentence. Nothing else.
```
