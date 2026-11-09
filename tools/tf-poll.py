#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""TestFlight play, read from App Store Connect's per-tester session counts (docs/testflight.md).

  tf-poll.py                       poll once: store today's counts per tester, then print the report; a
                                   date already polled keeps its first poll and only prints the report
  tf-poll.py --force               poll again today, replacing today's first poll
  tf-poll.py --report              print the report from what is stored
  tf-poll.py --app-id BUNDLE_ID    print the app's App Store Connect id, for ASC_APP_ID
  tf-poll.py --dry-run [SAMPLE...] replay saved responses (default tools/tf-poll-samples/*.json), each
                                   named for its poll date, into a throwaway CSV and print the report

Environment: ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH (the .p8) sign the token; ASC_APP_ID names the app;
TF_POLL_CSV is where the counts go (default ~/.unstir-testflight/usage.csv), each poll's raw response
going to raw/<poll date>.json beside it; TF_POLL_PERIOD is the window asked for (default P365D). Needs python3 and openssl, nothing else.
"""

import argparse
import base64
import csv
import datetime
import glob
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

API = "https://api.appstoreconnect.apple.com"
FIELDS = ["poll_date", "polled_at", "tester", "sessions", "crashes", "feedback", "window_start", "window_end",
          "period", "data_points"]
SAMPLES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tf-poll-samples")


def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_to_raw(der):
    """An ECDSA signature as openssl writes it (DER SEQUENCE of two INTEGERs) to JWS's r || s, 32 bytes each."""
    def length(at):
        n = der[at]
        if n < 0x80:
            return n, at + 1
        k = n & 0x7F
        return int.from_bytes(der[at + 1:at + 1 + k], "big"), at + 1 + k

    if der[0] != 0x30:
        raise ValueError("not a DER sequence")
    _, at = length(1)
    out = b""
    for _ in range(2):
        if der[at] != 0x02:
            raise ValueError("not a DER integer")
        n, at = length(at + 1)
        out += der[at:at + n].lstrip(b"\0").rjust(32, b"\0")
        at += n
    return out


def token(key_id, issuer, key_path, now=None):
    """A team key's ES256 token, as Apple's "Generating tokens for API requests" lays it out: 20 minutes is the
    longest lifetime it accepts for this endpoint."""
    now = int(now if now is not None else time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {"iss": issuer, "iat": now, "exp": now + 19 * 60, "aud": "appstoreconnect-v1"}
    signing = (b64url(json.dumps(header, separators=(",", ":")).encode()) + "."
               + b64url(json.dumps(payload, separators=(",", ":")).encode()))
    der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path, "-binary"], input=signing.encode(),
                         capture_output=True, check=True).stdout
    return signing + "." + b64url(der_to_raw(der))


def env(name):
    value = os.environ.get(name, "").strip()
    if not value:
        sys.exit(f"tf-poll: set {name} (see docs/testflight.md)")
    return os.path.expanduser(value)


def getter():
    jwt = token(env("ASC_KEY_ID"), env("ASC_ISSUER_ID"), env("ASC_KEY_PATH"))

    def get(url):
        request = urllib.request.Request(url, headers={"Authorization": f"Bearer {jwt}"})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")
            try:
                errors = json.loads(body).get("errors", [])
                body = "; ".join(f"{x.get('title', '')}: {x.get('detail', '')}" for x in errors) or body
            except ValueError:
                pass
            sys.exit(f"tf-poll: {e.code} from {url.split('?')[0]}: {body}")
    return get


def usage_url(app_id, period):
    query = urllib.parse.urlencode({"groupBy": "betaTesters", "period": period, "limit": 200})
    return f"{API}/v1/apps/{urllib.parse.quote(app_id)}/metrics/betaTesterUsages?{query}"


def fetch_pages(get, url):
    """Every page of a paged response, following links.next until it is absent."""
    pages = []
    while url:
        page = get(url)
        pages.append(page)
        url = page.get("links", {}).get("next")
    return pages


def rows_from(pages, poll_date, polled_at, period):
    """One row per tester: the window's sessions, crashes and feedback summed over its data points, and how many
    points there were (one for the whole window, or one per day: the window columns read the same either way)."""
    testers = {}
    for page in pages:
        for item in page.get("data", []):
            tester = item.get("dimensions", {}).get("betaTesters", {}).get("data")
            if not tester:
                continue
            row = testers.setdefault(tester, {"poll_date": poll_date, "polled_at": polled_at, "tester": tester,
                                              "sessions": 0, "crashes": 0, "feedback": 0, "window_start": "",
                                              "window_end": "", "period": period, "data_points": 0})
            for point in item.get("dataPoints", []):
                row["data_points"] += 1
                values = point.get("values", {})
                row["sessions"] += values.get("sessionCount", 0) or 0
                row["crashes"] += values.get("crashCount", 0) or 0
                row["feedback"] += values.get("feedbackCount", 0) or 0
                start, end = point.get("start", ""), point.get("end", "")
                if start and (not row["window_start"] or start < row["window_start"]):
                    row["window_start"] = start
                if end > row["window_end"]:
                    row["window_end"] = end
    return [testers[t] for t in sorted(testers)]


def load(path):
    if not os.path.exists(path):
        return []
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def raw_path(path, poll_date):
    return os.path.join(os.path.dirname(os.path.abspath(path)), "raw", f"{poll_date}.json")


def write_atomically(path, write):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    temp = path + ".new"
    with open(temp, "w", newline="") as f:
        write(f)
    os.replace(temp, path)


def store(path, rows, poll_date):
    """Adds a poll's rows, replacing any earlier rows on the same date (only --force gets here with one)."""
    kept = [r for r in load(path) if r["poll_date"] != poll_date] + rows
    kept.sort(key=lambda r: (r["poll_date"], r["tester"]))

    def write(f):
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(kept)
    write_atomically(path, write)


def first_poll(path, poll_date):
    """When the date's poll ran, or None. The raw response marks a poll, since one that lists no tester stores no
    row; a CSV row marks one made before the raw responses were kept."""
    raw = raw_path(path, poll_date)
    if os.path.exists(raw):
        with open(raw) as f:
            return json.load(f).get("polled_at", "?")
    return next((r["polled_at"] for r in load(path) if r["poll_date"] == poll_date), None)


def poll(path, poll_date, polled_at, period, fetch, force=False, out=None):
    """Stores one poll, unless the date was polled already: a second poll the same day would move that day's
    boundary and could turn a return into a miss. Returns whether it stored."""
    out = out or sys.stdout
    earlier = first_poll(path, poll_date)
    if earlier and not force:
        print(f"tf-poll: {poll_date} was polled at {earlier}; keeping that poll (--force replaces it)", file=out)
        return False
    pages = fetch()
    rows = rows_from(pages, poll_date, polled_at, period)
    write_atomically(raw_path(path, poll_date),
                     lambda f: json.dump({"poll_date": poll_date, "polled_at": polled_at, "period": period,
                                          "pages": pages}, f, indent=1))
    store(path, rows, poll_date)
    points = sorted({r["data_points"] for r in rows})
    print(f"stored {len(rows)} tester(s) for {poll_date} in {path}; data points per tester: "
          f"{', '.join(map(str, points)) or 'none'}", file=out)
    return True


def day(text):
    return datetime.date.fromisoformat(text)


def report(rows, out=None):
    """Each poll's new sessions per tester (the diff from the poll before), and day-2 return.

    A tester's day 1 is the first poll whose diff is positive; they returned on day 2 if the poll one calendar
    day later shows a positive diff too. Without a poll on that day, the answer waits (no later poll yet) or is
    unknown (a gap), never guessed."""
    out = out or sys.stdout
    if not rows:
        print("tf-poll: nothing stored yet", file=out)
        return
    polls = sorted({r["poll_date"] for r in rows})
    total = {(r["poll_date"], r["tester"]): int(r["sessions"]) for r in rows}
    testers = sorted({r["tester"] for r in rows})
    last = day(polls[-1])
    returned, missed, waiting, unknown, idle = [], [], [], [], []
    negative = []
    lines = []
    for tester in testers:
        diffs, before = {}, 0
        for poll in polls:
            if (poll, tester) not in total:
                continue
            now = total[(poll, tester)]
            if now < before:
                negative.append((tester, poll))
            diffs[poll] = max(0, now - before)
            before = now
        played = [p for p in polls if diffs.get(p, 0) > 0]
        if not played:
            idle.append(tester)
            continue
        first = day(played[0])
        second = (first + datetime.timedelta(days=1)).isoformat()
        earlier = [p for p in polls if p < played[0]]
        if earlier and (first - day(earlier[-1])).days > 1:
            status = f"unknown: day 1 is somewhere from {earlier[-1]} to {played[0]}, polls missed between"
            unknown.append(tester)
        elif second in diffs:
            status = "returned" if diffs[second] > 0 else "did not return"
            (returned if diffs[second] > 0 else missed).append(tester)
        elif day(second) > last:
            status = "waiting for tomorrow's poll"
            waiting.append(tester)
        else:
            status = f"unknown: no reading on {second}"
            unknown.append(tester)
        if played[0] == polls[0]:
            status += " (day 1 is the first poll, so it may hold earlier play)"
        crashes = max((int(r["crashes"]) for r in rows if r["tester"] == tester), default=0)
        feedback = max((int(r["feedback"]) for r in rows if r["tester"] == tester), default=0)
        by_day = "  ".join(f"{p[5:]}:+{diffs[p]}" for p in polls if p in diffs)
        lines.append(f"  {tester}  day 1 {played[0]}, {len(played)} day(s) played, {crashes} crash(es), "
                     f"{feedback} feedback  {status}\n    new sessions  {by_day}")
    print(f"polls: {len(polls)}, {polls[0]} to {polls[-1]}; testers seen: {len(testers)}, "
          f"never played: {len(idle)}", file=out)
    for line in lines:
        print(line, file=out)
    settled = len(returned) + len(missed)
    if settled:
        print(f"day-2 return: {len(returned)} of {settled} ({100 * len(returned) / settled:.0f}%)", end="", file=out)
    else:
        print("day-2 return: no tester's day 2 is in yet", end="", file=out)
    extra = [f"{len(waiting)} waiting" if waiting else "", f"{len(unknown)} unknown (missed poll)" if unknown else ""]
    print("".join(f", {e}" for e in extra if e), file=out)
    for tester, poll in negative:
        print(f"note: {tester}'s total fell at {poll}; the window may have dropped old sessions "
              f"(TF_POLL_PERIOD too short?)", file=out)


def default_csv():
    return os.path.expanduser(os.environ.get("TF_POLL_CSV", "~/.unstir-testflight/usage.csv"))


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", nargs="*", metavar="SAMPLE", help="replay saved responses, no key needed")
    mode.add_argument("--report", action="store_true", help="print the report from the stored CSV")
    mode.add_argument("--app-id", metavar="BUNDLE_ID", help="look up the app's id")
    mode.add_argument("--force", action="store_true", help="poll again today, replacing today's first poll")
    parser.add_argument("--csv", help="the CSV (default $TF_POLL_CSV; a throwaway one for --dry-run)")
    args = parser.parse_args()
    period = os.environ.get("TF_POLL_PERIOD", "P365D")

    if args.dry_run is not None:
        samples = sorted(args.dry_run or glob.glob(os.path.join(SAMPLES, "*.json")))
        with tempfile.TemporaryDirectory() as scratch:
            path = args.csv or os.path.join(scratch, "usage.csv")
            for sample in samples:
                poll_date = os.path.splitext(os.path.basename(sample))[0]
                day(poll_date)
                with open(sample) as f:
                    page = json.load(f)
                print(f"dry run: {os.path.basename(sample)} as the poll of {poll_date}")
                poll(path, poll_date, f"{poll_date}T09:00:00Z", period, lambda: [page])
            report(load(path))
        return

    if args.report:
        report(load(args.csv or default_csv()))
        return

    if args.app_id:
        query = urllib.parse.urlencode({"filter[bundleId]": args.app_id, "fields[apps]": "bundleId,name"})
        for app in getter()(f"{API}/v1/apps?{query}").get("data", []):
            print(app["id"], app.get("attributes", {}).get("bundleId", ""), app.get("attributes", {}).get("name", ""))
        return

    path = args.csv or default_csv()
    now = datetime.datetime.now(datetime.timezone.utc)
    poll(path, datetime.date.today().isoformat(), now.strftime("%Y-%m-%dT%H:%M:%SZ"), period,
         lambda: fetch_pages(getter(), usage_url(env("ASC_APP_ID"), period)), force=args.force)
    report(load(path))


if __name__ == "__main__":
    main()
