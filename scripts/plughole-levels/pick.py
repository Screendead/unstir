#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/plughole-levels/pick.py <pool dir> <Levels.swift>
# The pool holds one `scripts/plughole-levels.sh search` TSV per band, named <layout>-<depth>-<inversions>.tsv
# (seeds 1 to 3000 dealt 19-27). Prints the three lowest seeds that meet each slot; the first is the pick.
import csv, os, sys, re

os.chdir(sys.argv[1])
# The other tiers' scrambles, and plughole's own as it stands, so a pick never copies one.
existing = set(re.findall(r'"([0-9:+\-,]+)"', open(sys.argv[2]).read()))
def load(f,hidden):
    out=[]
    for r in csv.DictReader(open(f),delimiter='\t'):
        if int(r['hidden'])!=hidden: continue
        tw=[(int(a),int(b)) for a,b in (x.split(':') for x in r['scramble'].split(','))]
        s=[b for a,b in tw]; n=len(s); pos=sum(1 for x in s if x>0)
        if max(pos,n-pos)>2*n/3 or r['scramble'] in existing: continue
        if max(abs(x) for x in s)>7: continue
        r['tw']=tw; r['rs']=float(r['right/step']); r['whole']=int(r['whole']); r['seed']=int(r['level'])
        out.append(r)
    return out
# slot: file, hidden, rs window, extra test
slots=[
 ('L19','pent-5-0.tsv',0,(1.55,1.60),lambda r:r['whole']>=2 and len({a for a,b in r['tw']})>=4),
 ('L20','pent-6-0.tsv',0,(1.48,1.53),lambda r:r['whole']==2),
 ('L21','pent-6-1.tsv',1,(1.42,1.47),lambda r:r['whole']==1),
 ('L22','pent-7-1.tsv',1,(1.37,1.42),lambda r:True),
 ('L23','hex-6-0.tsv',0,(1.80,1.85),lambda r:all(a!=0 for a,b in r['tw']) and r['whole']>=2),
 ('L24','hex-7-0.tsv',0,(1.65,1.72),lambda r:any(a==0 for a,b in r['tw'][:-2])),
 ('L25','hex-8-1.tsv',1,(1.58,1.63),lambda r:True),
 ('L26','hex-9-1.tsv',1,(1.50,1.56),lambda r:True),
 ('L27','hex-9-2.tsv',2,(1.42,1.47),lambda r:any(a==0 for a,b in r['tw'])),
]
prev=None
for name,f,h,(lo,hi),extra in slots:
    c=[r for r in load(f,h) if lo<=r['rs']<=hi and extra(r) and (prev is None or r['tw'][:3]!=prev)]
    c.sort(key=lambda r:r['seed'])
    for r in c[:3]:
        print(name,r['seed'],r['entries'],r['hidden'],r['whole'],r['rs'],r['forced'],r['scramble'])
    prev=c[0]['tw'][:3]
