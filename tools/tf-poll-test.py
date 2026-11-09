#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Checks tf-poll.py without an App Store Connect key: its token verifies against a throwaway P-256 key, a poll
against a local stand-in for the API follows links.next and stores every tester, and the report's day-2 return
over the saved samples is 1 of 3. Run: python3 tools/tf-poll-test.py"""

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


def check_report():
    out = io.StringIO()
    with tempfile.TemporaryDirectory() as scratch:
        path = os.path.join(scratch, "usage.csv")
        for name in sorted(os.listdir(os.path.join(here, "tf-poll-samples"))):
            with open(os.path.join(here, "tf-poll-samples", name)) as f:
                page = json.load(f)
            poll = name[:-5]
            tf.store(path, tf.rows_from([page], poll, poll + "T09:00:00Z", "P365D"), poll)
        tf.report(tf.load(path), out)
    assert "day-2 return: 1 of 3 (33%), 1 waiting" in out.getvalue(), out.getvalue()


with tempfile.TemporaryDirectory() as scratch:
    check_token(scratch)
    check_poll(scratch, os.path.join(scratch, "AuthKey_TEST.p8"))
check_report()
print("tf-poll: all checks pass")
