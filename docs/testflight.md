# Reading TestFlight

Jack's call TFREAD = D: TestFlight play is read from three places, since v1 ships no analytics (AN1 = A).

1. **Sessions per tester, polled daily** from App Store Connect by `tools/tf-poll.py`. Day-2 return, the number plan
   step 1 watches, comes from the day-to-day diffs.
2. **Testers' logs**, sent on day 3 from settings, "report a problem": every touch, move, purchase and error.
3. **A five-question survey** in the build's What to Test field (draft below, for Jack).

Each claim below is marked as **read** (from Apple's documentation, the code or a run here) or **unchecked**
(inferred, and settled by the two-day check).

## What the API gives

Read, from Apple's App Store Connect API reference (`GET /v1/apps/{id}/metrics/betaTesterUsages`, added in API 3.1,
and the `AppsBetaTesterUsagesV1MetricResponse` schema):

- The call needs `groupBy=betaTesters` or `filter[betaTesters]`. `period` is one of `P7D`, `P30D`, `P90D`, `P365D`;
  `limit` is 200 at most, and further pages come through `links.next`.
- Each item in `data` is one tester: `dimensions.betaTesters.data` holds the tester's opaque id, and `dataPoints` a list
  of `{start, end, values: {sessionCount, crashCount, feedbackCount}}`.
- The token is an ES256 JWT: header `{alg, kid, typ}`, payload `{iss, iat, exp, aud: "appstoreconnect-v1"}`, at
  most 20 minutes long for this endpoint (it is not on the list of resources that take long-lived tokens).

Unchecked: how long each data point spans (one for the whole window or one per day), how late a session shows up,
what Apple counts as a session, and whether internal testers and public-link testers are listed. The script copes with
either span: it sums a tester's data points and keeps the earliest start and latest end in the CSV, so the two-day
check shows which it is.

The window is rolling, so a daily diff of `P7D` totals would also subtract the day that left the window. The script
asks for `P365D`, whose total only grows during a test shorter than a year, so each day's diff is that day's new
sessions. If a total ever falls, the report says so.

## Running it

It needs `python3` and `openssl`, nothing else. Read: `tools/tf-poll-test.py` passes under the launch agent's
environment below, macOS's own Python 3.9 and LibreSSL 3.3 with `PATH=/usr/bin:/bin:/usr/sbin:/sbin`.

One-time setup:

1. In App Store Connect, Users and Access, Integrations, App Store Connect API, make a team key and download its
   `.p8` (Apple lets you download it once). The endpoint's page names no role; unchecked which is the least that
   answers. Try Developer, and App Manager if the poll gets a 403.
2. Keep the `.p8` outside the repo, readable only by you, e.g. `~/.unstir-testflight/AuthKey_<id>.p8`
   with `chmod 600`.
3. Set, in the shell (never in a tracked file):

   | Variable | Holds |
   |---|---|
   | `ASC_KEY_ID` | the key's id, from the Integrations tab |
   | `ASC_ISSUER_ID` | the issuer id, at the top of the same tab |
   | `ASC_KEY_PATH` | the `.p8`'s path |
   | `ASC_APP_ID` | the app's App Store Connect id (step 4) |
   | `TF_POLL_CSV` | optional; the CSV, default `~/.unstir-testflight/usage.csv` |
   | `TF_POLL_PERIOD` | optional; the window, default `P365D` |

4. `tools/tf-poll.py --app-id com.screendead.Unstir` prints the app's id (the bundle id is `project.yml`'s prefix and
   target); put it in `ASC_APP_ID`.

Then:

- `tools/tf-poll.py` polls once, stores today's row per tester (a second poll the same day replaces the first) and
  prints the report.
- `tools/tf-poll.py --report` prints the report from the CSV alone.
- `tools/tf-poll.py --dry-run` needs no key: it replays the three saved responses in `tools/tf-poll-samples/`
  (written from Apple's schema, fake ids), each named for its poll date, into a throwaway CSV. It should end
  `day-2 return: 1 of 3 (33%), 1 waiting`. `--dry-run a.json b.json` replays chosen ones, e.g. two days apart, to see
  a missed poll reported as unknown.
- `python3 tools/tf-poll-test.py` checks the token against a throwaway key, a poll against a local stand-in for the
  API (two pages through `links.next`) and the dry run's number.

### Polling daily

A launch agent polls each morning; launchd runs a calendar job missed while the Mac slept when it wakes (read:
`man launchd.plist`), but not one missed while it was off. Save as
`~/Library/LaunchAgents/com.screendead.unstir.tf-poll.plist`, with the paths and values filled in, then
`launchctl load` it:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.screendead.unstir.tf-poll</string>
  <key>ProgramArguments</key>
  <array><string>/usr/bin/python3</string><string>/path/to/the/repo/tools/tf-poll.py</string></array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>ASC_KEY_ID</key><string>...</string>
    <key>ASC_ISSUER_ID</key><string>...</string>
    <key>ASC_KEY_PATH</key><string>/Users/you/.unstir-testflight/AuthKey_KEYID.p8</string>
    <key>ASC_APP_ID</key><string>...</string>
  </dict>
  <key>StartCalendarInterval</key><dict><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>/Users/you/.unstir-testflight/poll.log</string>
  <key>StandardErrorPath</key><string>/Users/you/.unstir-testflight/poll.log</string>
</dict>
</plist>
```

Start polling the day the invites go out, before anyone installs: a tester already playing at the first poll has their
earlier play folded into day 1, and the report says so.

### How the report reads day 2

A "day" is the 24 hours before a poll. A tester's day 1 is the first poll that shows new sessions; they returned on
day 2 if the poll one calendar day later shows new sessions too. Day-2 return is returned over returned plus not
returned. A tester whose next poll hasn't happened is "waiting", and one whose day 1 or day 2 falls in a missed poll is
"unknown", never guessed. Play just before and just after 09:00 lands in two days, and an evening plus the next
early morning in one.

The CSV holds only Apple's opaque tester ids, never names or emails (App Store Connect maps an id to a tester). It
stays outside the repo.

## The two-day check on Jack's own install

Before any stranger is invited, prove the pipeline on Jack's phone. It answers every unchecked point above.

| When | Do | Expect |
|---|---|---|
| Day 0 | Set up the key and the launch agent; run `tools/tf-poll.py` once. | It runs; Jack is listed with 0 sessions, or not at all (then note whether internal testers are listed). |
| Day 1 | Install the TestFlight build; play one session in the evening. Note the time. | |
| Day 2, 09:00 poll | Check the report. | Jack shows day 1, +1. If +0, the metric lags: wait for day 3's poll. |
| Day 2 | Play twice in the evening, an hour apart, the app closed between. | |
| Day 2 | Tap the gear, then "report a problem". | A mail (or the share sheet) already addressed to the support address, the log attached: the build carries `SUPPORT_ADDRESS`. |
| Day 3, 09:00 poll | Check the report and the CSV. | Jack "returned". The diff says whether two openings an hour apart are one session or two, and `window_start` and `window_end` whether each data point spans the window or a day. |

If the sessions show a day late, every reading shifts by that day: note the lag here and read day 2 from the poll
after. If Jack is never listed, the metric doesn't cover internal testers: add him to an external group, as the
strangers will be.

## Day 3: the log

On day 3 each tester is asked to send their log: the gear beside the menu's title, then "report a problem". With an
account in Apple's Mail it opens a mail to the support address with the log attached; otherwise the share sheet
carries the address, the subject and the log to whichever app takes it (read: `SettingsSheet` in `Consent.swift`).
The log holds touches, moves, purchases and errors, and no name (`Log.swift`; the privacy policy keeps support mail
and logs 12 months). Without `SUPPORT_ADDRESS` in the build, the share sheet carries the log alone, with no address,
so the TestFlight archive is built with it set (`Config/Local.xcconfig` for an Xcode archive).

The ask, a draft for Jack: "Day 3: please send us your log. Tap the gear by the title, then 'report a problem', and
send. It holds your moves and touches, never who you are."

## The What to Test text (a draft for Jack)

**Draft, for Jack: the wording is his.** Apple's documentation states no length for the field (unchecked; one
developer reports text over about 2 KB not showing in TestFlight), so this stays under 1 KB. It holds the day-3 ask too,
since testers read this field and nothing else reaches public-link testers. Answers come back through TestFlight's own
feedback (a screenshot shared to TestFlight, or Send Beta Feedback in the TestFlight app), so `feedbackCount` in the
poll shows who answered.

```
Thanks for testing Unstir. Play as you would any game, with no help from us: that is the test.

On day 3, please tap the gear by the title, then "report a problem", and send the log. It holds your moves and touches, never who you are.

Then answer these in TestFlight's feedback (take a screenshot, or open TestFlight and tap Send Beta Feedback):
1. Did you come back the day after you first played? What brought you back, or what didn't?
2. Where did you stop, and why?
3. In the first three levels of each tier or pack you opened, what was unclear?
4. Did anything feel broken or slow, or turn the wrong way?
5. In one sentence, what is Unstir?
```

Measured with a script: 646 characters.

Why these five: 1 cross-checks the day-2 number with the reason behind it; 2 finds where testers get stuck; 3 asks
of each opening, where the game teaches itself (Plughole, Whirlpool, Vortex, Maelstrom, Lens, Escapement, Prism);
4 points at what the log should show; 5 tests whether they got the goal without help, plan step 1's first question.
