#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: tools/copy/inventory.py <tree> [<tree>...]   Prints, as JSON, each player-text literal in <tree>/Sources/*.swift
# (String(localized:), LocalizedStringResource, Text, accessibility label/value/hint, Announcement), once per text.
import re, glob, os, sys, json
skip = {'SlopeHarness.swift', 'GPUBench.swift', 'OracleBench.swift', 'DragProbe.swift', 'Log.swift'}
S = r'"((?:[^"\\\n]|\\.)*)"'
ML = r'"""\n(.*?)"""'
lead = (r'(String\(localized:\s*|LocalizedStringResource\(\s*|Text\(\s*|\.accessibility(?:Label|Value|Hint)\(\s*(?:Text\(\s*)?'
        r'|Announcement\(\s*(?:String\(localized:\s*)?)')
rx = re.compile(lead + r'(?:' + ML + '|' + S + r')(?:\s*,\s*defaultValue:\s*' + S + r')?(?:\s*,\s*comment:\s*' + S + r')?', re.S)
seen, out = {}, []
for root in sys.argv[1:]:
    for f in sorted(glob.glob(root + '/Sources/*.swift')):
        n = os.path.basename(f)
        if n in skip: continue
        t = open(f).read()
        for m in rx.finditer(t):
            ls = t.rfind('\n', 0, m.start()) + 1
            if t[ls:m.start()].lstrip().startswith('//'): continue
            ml, s, dv, c = m.group(2), m.group(3), m.group(4), m.group(5)
            text = dv if dv is not None else (re.sub(r'\s*\\?\n\s*', ' ', ml).strip() if ml is not None else s)
            key = s if dv is not None else None
            if not re.search(r'[A-Za-z]', re.sub(r'\\\((?:[^()]|\([^()]*\))*\)', '', text)): continue
            k = key or text
            if k in seen:
                e = seen[k]
                if n not in e['files']: e['files'].append(n)
                if c and c not in e['comments']: e['comments'].append(c)
                continue
            e = dict(key=key, text=text, files=[n], comments=[c] if c else [])
            seen[k] = e; out.append(e)
json.dump(out, sys.stdout, ensure_ascii=False, indent=1)
