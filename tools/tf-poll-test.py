#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Checks tf-poll.py without an App Store Connect key: its token verifies against a throwaway P-256 key; a poll
against a local stand-in for the API follows links.next, stores every tester and keeps the raw response; a second
poll the same day keeps the first unless forced; and the report's readings (day-2 return over the saved samples,
both gaps, a falling total) hold. Run: python3 tools/tf-poll-test.py"""

import base64
import contextlib
import http.server
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import threading
import urllib.parse

sys.dont_write_bytecode = True
here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("tf_poll", os.path.join(here, "tf-poll.py"))
tf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tf)


def unb64(text):
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def raw_to_der(raw):
    def integer(b):
        b = b.lstrip(b"\0") or b"\0"
        if b[0] & 0x80:
            b = b"\0" + b
        return b"\x02" + bytes([len(b)]) + b
    body = integer(raw[:32]) + integer(raw[32:])
    return b"\x30" + bytes([len(body)]) + body


def check_token(scratch):
    key, pub = os.path.join(scratch, "AuthKey_TEST.p8"), os.path.join(scratch, "pub.pem")
    ec = os.path.join(scratch, "ec.pem")
    subprocess.run(["openssl", "ecparam", "-name", "prime256v1", "-genkey", "-noout", "-out", ec], check=True)
    subprocess.run(["openssl", "pkcs8", "-topk8", "-nocrypt", "-in", ec, "-out", key], check=True)
    subprocess.run(["openssl", "ec", "-in", key, "-pubout", "-out", pub], check=True, capture_output=True)
    for attempt in range(20):
        jwt = tf.token("TESTKEY123", "00000000-0000-0000-0000-000000000000", key, now=1_800_000_000)
        head, body, sig = jwt.split(".")
        assert json.loads(unb64(head)) == {"alg": "ES256", "kid": "TESTKEY123", "typ": "JWT"}
        claims = json.loads(unb64(body))
        assert claims["aud"] == "appstoreconnect-v1" and claims["exp"] - claims["iat"] <= 20 * 60, claims
        raw = unb64(sig)
        assert len(raw) == 64, len(raw)
        with open(os.path.join(scratch, "sig.der"), "wb") as f:
            f.write(raw_to_der(raw))
        done = subprocess.run(["openssl", "dgst", "-sha256", "-verify", pub, "-signature",
                               os.path.join(scratch, "sig.der")], input=f"{head}.{body}".encode(),
                              capture_output=True)
        assert done.returncode == 0, done.stdout + done.stderr
    return key


def check_poll(scratch, key):
    with open(os.path.join(here, "tf-poll-samples", "2026-11-12.json")) as f:
        sample = json.load(f)
    seen = []

    class Stand(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            seen.append((self.path, self.headers.get("Authorization", "")))
            query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            page = dict(sample)
            if "cursor" in query:
                page["data"], page["links"] = sample["data"][3:], {"self": self.path}
            else:
                page["data"] = sample["data"][:3]
                page["links"] = {"self": self.path, "next": f"{tf.API}{self.path}&cursor=Mw"}
            body = json.dumps(page).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass

    server = http.server.HTTPServer(("127.0.0.1", 0), Stand)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    tf.API = f"http://127.0.0.1:{server.server_port}"
    path = os.path.join(scratch, "usage.csv")
    os.environ.update({"ASC_KEY_ID": "TESTKEY123", "ASC_ISSUER_ID": "00000000-0000-0000-0000-000000000000",
                       "ASC_KEY_PATH": key, "ASC_APP_ID": "0000000000", "TF_POLL_CSV": path})
    sys.argv = ["tf-poll.py"]
    with contextlib.redirect_stdout(io.StringIO()):
        tf.main()
    server.shutdown()
    assert len(seen) == 2, seen
    assert seen[0][0].startswith("/v1/apps/0000000000/metrics/betaTesterUsages?"), seen[0][0]
    assert "groupBy=betaTesters" in seen[0][0] and "period=P365D" in seen[0][0], seen[0][0]
    assert all(auth.startswith("Bearer ") and auth.count(".") == 2 for _, auth in seen)
    rows = tf.load(path)
    assert sorted(r["tester"] for r in rows) == sorted(d["dimensions"]["betaTesters"]["data"]
                                                       for d in sample["data"]), rows
    assert sum(int(r["sessions"]) for r in rows) == 9, rows
    assert {r["data_points"] for r in rows} == {"1"}, rows
    with open(tf.raw_path(path, rows[0]["poll_date"])) as f:
        raw = json.load(f)
    assert [len(p["data"]) for p in raw["pages"]] == [3, len(sample["data"]) - 3], raw


def replay(names):
    """The report over saved samples, each stored as its date's 09:00 poll."""
    out = io.StringIO()
    with tempfile.TemporaryDirectory() as scratch:
        path = os.path.join(scratch, "usage.csv")
        for name in names:
            with open(os.path.join(here, "tf-poll-samples", name)) as f:
                page = json.load(f)
            poll = name[:-5]
            tf.poll(path, poll, poll + "T09:00:00Z", "P365D", lambda: [page], out=io.StringIO())
        tf.report(tf.load(path), out)
    return out.getvalue()


def page(sessions, points=1):
    """A response listing each tester with their window total, split over `points` data points."""
    data = []
    for tester, total in sessions.items():
        shares = [total // points + (1 if i < total % points else 0) for i in range(points)]
        data.append({"dimensions": {"betaTesters": {"data": tester}},
                     "dataPoints": [{"start": f"2026-01-{i + 1:02}T00:00:00Z", "end": f"2026-01-{i + 2:02}T00:00:00Z",
                                     "values": {"sessionCount": n, "crashCount": 0, "feedbackCount": 0}}
                                    for i, n in enumerate(shares)]})
    return {"data": data, "links": {"self": "stand-in"}}


def polls(sequence, force_at=()):
    """Runs (poll date, time, {tester: window total}) polls in order; returns each poll's verdict and the report."""
    out = io.StringIO()
    with tempfile.TemporaryDirectory() as scratch:
        path = os.path.join(scratch, "usage.csv")
        stored = [tf.poll(path, date, f"{date}T{at}Z", "P365D", lambda s=sessions: [page(s)],
                          force=(date, at) in force_at, out=io.StringIO())
                  for date, at, sessions in sequence]
        rows = tf.load(path)
        tf.report(rows, out)
    return stored, rows, out.getvalue()


def check_report():
    text = replay(["2026-11-10.json", "2026-11-11.json", "2026-11-12.json"])
    assert "day-2 return: 1 of 3 (33%), 1 waiting" in text, text

    # Without the 11-11 poll: a's and b's day 2 has no reading, and c's and d's day 1 could be 11-11 or 11-12.
    text = replay(["2026-11-10.json", "2026-11-12.json"])
    assert text.count("unknown: no reading on 2026-11-11") == 2, text
    assert text.count("unknown: day 1 is somewhere from 2026-11-10 to 2026-11-12, polls missed between") == 2, text
    assert "day-2 return: no tester's day 2 is in yet, 4 unknown (missed poll)" in text, text


def check_same_day():
    # Plays at 10:00 on the 1st and the 2nd. A hand poll at 20:00 on the 1st must not move the 1st's boundary to
    # 20:00, which would fold the first play into the 1st and leave the 2nd's 09:00 poll showing nothing new.
    t = "tester-t"
    sequence = [("2026-12-01", "09:00:00", {t: 0}), ("2026-12-01", "20:00:00", {t: 1}),
                ("2026-12-02", "09:00:00", {t: 1}), ("2026-12-03", "09:00:00", {t: 2})]
    stored, rows, text = polls(sequence)
    assert stored == [True, False, True, True], stored
    assert [r["polled_at"] for r in rows if r["poll_date"] == "2026-12-01"] == ["2026-12-01T09:00:00Z"], rows
    assert "returned" in text and "day-2 return: 1 of 1 (100%)" in text, text

    # Forced, the hand poll replaces the 09:00 one: the misreading the guard is there to stop.
    stored, rows, text = polls(sequence, force_at={("2026-12-01", "20:00:00")})
    assert stored == [True, True, True, True], stored
    assert [r["polled_at"] for r in rows if r["poll_date"] == "2026-12-01"] == ["2026-12-01T20:00:00Z"], rows
    assert "day-2 return: 0 of 1 (0%)" in text, text

    # A first poll listing no tester stores no row, but still holds the date.
    stored, rows, text = polls([("2026-12-01", "09:00:00", {})] + sequence[1:])
    assert stored == [True, False, True, True], stored
    assert not [r for r in rows if r["poll_date"] == "2026-12-01"], rows
    assert "day-2 return: 1 of 1 (100%)" in text, text


def check_points_and_fall():
    with tempfile.TemporaryDirectory() as scratch:
        path = os.path.join(scratch, "usage.csv")
        tf.poll(path, "2026-12-01", "2026-12-01T09:00:00Z", "P365D", lambda: [page({"u": 7}, points=3)],
                out=io.StringIO())
        (row,) = tf.load(path)
        assert row["sessions"] == "7" and row["data_points"] == "3", row
        with open(tf.raw_path(path, "2026-12-01")) as f:
            assert json.load(f)["pages"] == [page({"u": 7}, points=3)]

    _, _, text = polls([("2026-12-01", "09:00:00", {"u": 0}), ("2026-12-02", "09:00:00", {"u": 3}),
                        ("2026-12-03", "09:00:00", {"u": 1})])
    assert "note: u's total fell at 2026-12-03" in text, text


with tempfile.TemporaryDirectory() as scratch:
    check_token(scratch)
    check_poll(scratch, os.path.join(scratch, "AuthKey_TEST.p8"))
check_report()
check_same_day()
check_points_and_fall()
print("tf-poll: all checks pass")
