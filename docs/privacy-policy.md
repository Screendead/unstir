# Unstir privacy policy

> **Draft, 2026-10-27, not for publishing yet.** Written from the code on `master` and the `analytics` branch. It needs
> Jack's check and a lawyer's before it goes live: nothing in it is settled law. Bracketed fields are for Jack to fill
> in App Store Connect's copy or the hosted page, never in this public repo. Remove this box before publishing.
>
> Open legal questions **(check)**:
> 1. Whether the analytics rows are personal data under the GDPR. No identifier is sent, but a day-30 summary is one
>    player's history, and the server sees the address each request comes from.
> 2. Whether a child's Yes is valid consent (GDPR article 8: 13 to 16 depending on the country) in a game rated for
>    all ages, and what COPPA asks of a game US children may play.
> 3. Whether Aptabase offers a data processing agreement, how long it keeps request addresses, and where its EU
>    region's servers are.
> 4. Whether the counts the game keeps on the phone before the question is answered (the install's day) need consent
>    under ePrivacy article 5(3). The menu waits for an answer, so this covers the first launch only.
> 5. Which law governs, and whether a representative in the EU or UK is needed.
>
> If the analytics branch isn't merged, cut the "If you say yes to analytics" section and the Aptabase lines: the game
> then sends nothing at all.

*Last updated: [date of publishing]*

Unstir is a puzzle game made by [developer's name, as on the App Store seller line] ("we"). This page says what the
game keeps, what it sends and to whom.

## In short

- Your progress stays on your phone. There is no account and no sign-in.
- The game asks you once whether it may send counts of how you play. Nothing is sent unless you say yes, and you can
  change your answer at any time in settings.
- It never sends your name, your Apple ID, your contacts, your photos, your precise location or any identifier for
  you, your phone or your install.
- There are no ads, no tracking across apps or websites, and no data sold or shared with advertisers.

## What stays on your phone

The game keeps these on your phone only. They never leave it except as described below:
- Your progress: best scores, which levels you have started, the tier the menu shows, endless's best run.
- The undo bank and the day it last refilled. To keep the refill fair when the phone's clock is changed, the game also
  keeps the last time it trusted, the phone's time since it started up, and an identifier of that start-up that the
  system provides. These are used only on the phone.
- Which lessons you have learnt (turning the tank, using the swirl).
- Your answer to the analytics question and a short tally used to build the summaries described below (if you say
  no, only the install's day is kept).
- A log of recent play (the last 3,000 lines: where each touch landed and moved, each move, undo and reset, levels
  opened, failed purchases, and when the app started). It is kept for finding bugs and sent only if you send it
  yourself.

Deleting the app deletes all of it. If your phone backs up to iCloud or a computer, the backup includes it, under your
backup's own terms.

## Purchases

Packs and Complete are sold through Apple's App Store. Apple handles payment, and we never see your payment details or
Apple ID. The game checks Apple's signed record of what you own on the phone, with no server of ours. Apple's privacy
policy covers Apple's part.

## If you say yes to analytics

The game sends counts of how you play to Aptabase, an analytics service, on its EU region. We use them to see whether
the game is clear, where players get stuck and whether they come back. What is sent:

- That the game was installed, and on each later day you open it, which day it is since install (day 2, day 3, ...).
- For each level you finish or leave: which level (every daily is sent as "daily"), whether you solved it or left,
  your moves, its par, and the undos and resets you used. For an endless run: how it ended, the tanks cleared and the
  moves. Nothing is sent for the sandbox.
- Once each: that you saw a pack's card, finished its free levels, or bought a pack or Complete on this phone (the
  product's name only, no price or receipt).
- On days 2, 7 and 30, one summary: which days you played, undos used and banked, endless's best, the furthest level
  in each tier, levels started, dailies solved first time, and for each pack whether you saw it, finished its free
  levels and own it.
- With each event: its time, a random number for the current sitting (renewed after an hour without play), whether the
  build is a development (debug) build, and the app's version. No device model, system version or language.

No identifier for you, your phone or your install is sent, so the events can't be tied to one another beyond a single
sitting, or to you. Aptabase sees the internet address each request comes from, as any server does, and uses it to
record roughly which country it came from. [Aptabase's handling of that address and its retention period, from its
current policy: to be checked.]

The legal basis is your consent [(GDPR article 6(1)(a)), to be confirmed]. Saying no, or turning analytics off in
settings, stops all sending at once, deletes anything waiting to be sent and clears the tally on the phone, keeping
only the install's day so day numbers stay right if you say yes later. Your progress is not affected.

Because nothing sent identifies you, we can't find your events among others' to show or delete them. Turning
analytics off is the way to stop them. [How this squares with access and erasure rights under the GDPR: to be checked.]

## If you send a log

Settings has a "send log" button. It opens your phone's share sheet with the play log described above, and you choose
where it goes, for example an email to us. The game sends nothing by itself. If you email it, we receive your email
address with it and use both only to look into the bug you reported. [How long such emails are kept: to be decided.]

## Sharing a result

The daily's share button opens your phone's share sheet with a line of text (the daily's number or date, your moves
and par, and a square per move). It goes only where you send it.

## Children

The game is for everyone. It sends no identifier for you, your phone or your install. [What the analytics question means for
children's consent in each region: to be checked.]

## Changes

If this policy changes, the new version will be posted here with a new date. [Whether a change to what the game sends
asks the question again: Jack's call; the game doesn't do this today.]

## Contact

[Privacy contact address]
