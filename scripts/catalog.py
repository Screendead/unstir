#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Hand edits to Sources/Localizable.xcstrings that a command-line build never makes (it writes no keys back).

  scripts/catalog.py plural <key> <one> [<other>] [--comment <text>]
      An English plural entry: `one`, and `other` (the key itself unless given), for a key with one count, as
      "%lld moves" with "%lld move". Without it a plural key reads "1 moves".
  scripts/catalog.py fixed <comment>
      Marks do-not-translate every key in Sources/*.swift whose `String(localized:)` or `LocalizedStringResource`
      carries exactly this comment."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Sources" / "Localizable.xcstrings"


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def plural(catalog, args):
    comment = None
    if "--comment" in args:
        i = args.index("--comment")
        comment = args[i + 1]
        args = args[:i] + args[i + 2:]
    if len(args) not in (2, 3):
        sys.exit(__doc__)
    key, one = args[0], args[1]
    other = args[2] if len(args) == 3 else key
    entry = catalog["strings"].setdefault(key, {})
    if comment:
        entry["comment"] = comment
    entry.setdefault("localizations", {})["en"] = {"variations": {"plural": {"one": unit(one), "other": unit(other)}}}


def fixed(catalog, args):
    if len(args) != 1:
        sys.exit(__doc__)
    pattern = re.compile(r'(?:String\(localized: |LocalizedStringResource\()"((?:[^"\\]|\\.)*)",\s*comment: "'
                         + re.escape(args[0]) + '"\\)')
    keys = [k for f in sorted((ROOT / "Sources").glob("*.swift")) for k in pattern.findall(f.read_text())]
    if not keys or any("\\" in k for k in keys):
        sys.exit(f"no keys, or a key with an escape, under that comment: {len(keys)}")
    for key in keys:
        entry = catalog["strings"].setdefault(key, {})
        entry["comment"] = args[0]
        entry["shouldTranslate"] = False
    print(f"{len(set(keys))} keys marked do-not-translate")


def main(argv):
    commands = {"plural": plural, "fixed": fixed}
    if not argv or argv[0] not in commands:
        sys.exit(__doc__)
    catalog = json.loads(CATALOG.read_text())
    commands[argv[0]](catalog, argv[1:])
    CATALOG.write_text(json.dumps(catalog, indent=2, ensure_ascii=False, sort_keys=True, separators=(",", " : ")) + "\n")


if __name__ == "__main__":
    main(sys.argv[1:])
