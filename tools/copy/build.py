#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: tools/copy/build.py   Writes docs/copy-cut.md and docs/copy-keep.txt from tools/copy/inventory.json (made by
# tools/copy/inventory.py from slope/base and origin/slope/integrate) and the verdicts below. A string no verdict names
# is kept. Indexes are positions in inventory.json: remake the verdicts if it is remade.
import json, os, re, sys

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.dirname(os.path.dirname(here))
inv = json.load(open(os.path.join(here, 'inventory.json')))
catalog = json.load(open(os.path.join(root, 'Sources', 'Localizable.xcstrings')))['strings']

STRINGY = re.compile(r'name|word|title|label|pitch|moved|movesSpoken|rods\(|shortLine|more$|free$|complete|saving|picture'
                     r'|mark\(|counted|named|countWord|display|ended|spoken|number|bundleName|^day$|^to$|^\$0$')
FORM = {  # catalog forms the rule above gets wrong
    346: '%@ \u00B7 par %lld', 559: 'moves %lld / par %lld', 401: '%@ and %@', 655: 'replay 01\u2013%@ \u203A', 351: '%lld rods \u00B7 par %lld \u00B7 %@',
    392: '%lld/%lld free', 393: '%lld of %lld free levels solved', 376: 'levels 1\u2013%lld free, no purchase',
    353: 'solve %@ to open', 352: 'solve every %@ level to open', 4: '%lld over par', 626: '%lld over par',
    14: 'done %lld/%lld at par', 335: '%lld/%lld at par', 737: '%@, %lld of %lld at par', 398: '%lld more in %@.',
    373: '%@ \u00B7 %lld levels', 660: '\u00B7 save %@ \u203A', 623: '%@ on the packs you don\'t have',
    678: 'Level %lld, %@.', 720: 'rods: %lld \u203A', 721: 'rods: %lld \u00B7 %@ \u203A', 722: '%lld rods \u203A',
    716: 'sound, haptics, colour letters: [gear] on the menu', 680: 'locked, solve level %@ first',
    681: 'locked, solve %@ level %@ first', 574: 'new best \u00B7 was %@', 575: 'best \u00B7 %@',
}


def form(i):
    if i in FORM: return FORM[i]
    t = inv[i]['text']
    def sub(m): return '%@' if STRINGY.search(m.group(1)) else '%lld'
    t = re.sub(r'\\\(((?:[^()]|\((?:[^()]|\([^()]*\))*\))*)\)', sub, t)
    t = re.sub(r'\\u\{([0-9A-Fa-f]+)\}', lambda m: chr(int(m.group(1), 16)), t)
    return t.replace('\\"', '"')


# Where a string shows, for those the code's own comment doesn't place (or places too briefly).
WHERE = {
    6: 'menu, archive row: tag where a level number would be', 7: 'menu, archive row; the archive\'s title',
    8: 'menu, archive row for 2 s when tapped while locked', 12: 'archive: eyebrow over its title',
    13: 'archive: paragraph under its title', 14: 'archive: count under its title',
    53: 'Escapement: stamped over the tank when the clocks run out', 319: 'VoiceOver: the settings button',
    325: 'menu: heading over the sandbox row', 326: 'menu: the wordmark', 328: 'VoiceOver: the tier picker',
    334: 'VoiceOver hint: endless\'s "new run"', 339: 'closed tier\'s gate: before the unsolved level numbers ("short: 21\u201327")',
    561: 'play: undo button in the sandbox', 562: 'play: undo button with undos left', 566: 'play: undo button with undos left',
    568: 'play: reset button', 576: 'result: moves, where there is no par', 577: 'result, endless spilled: part of "tanks cleared 7 \u00B7 new best"',
    578: 'result, endless spilled: part of "tanks cleared 7 \u00B7 new best"', 581: 'result: moves and par',
    582: 'result: under the facts when at par but not clean', 583: 'result, a daily replayed: under the facts',
    584: 'result: button to a pack', 585: 'VoiceOver: result\'s button to a pack', 586: 'result, last free level: button to the packs',
    587: 'VoiceOver: result\'s button to the packs', 588: 'result: replay button', 589: 'VoiceOver: result\'s replay button',
    590: 'result, daily: share button', 591: 'VoiceOver: result\'s share button', 602: 'Escapement, lost: the result\'s line',
    603: 'undo button with undos left', 605: 'Escapement, lost: replay button', 606: 'VoiceOver: Escapement\'s lost replay button',
    624: 'pack page: under the facts while some of its levels are not yet in the build', 625: 'pack page: before the store\'s first read',
    655: 'pack page: replays the free levels. The last one\'s number', 661: 'VoiceOver: pack page\'s bundle line',
    662: 'VoiceOver: pack page\'s bundle line, its value. Price, then saving', 663: 'pack page: under the bundle line, its purchase failed',
    666: 'menu: beside the packs\' header', 700: 'VoiceOver: an opening stir, skippable', 702: 'VoiceOver: the tank. Its rods',
    703: 'VoiceOver hint: the tank', 707: 'play: reset button armed, 2 s', 716: 'plughole 01, first open, once: under the note',
    723: 'Escapement: label of the tick counter', 724: 'VoiceOver: Escapement\'s tick counter',
    354: 'number word, part of "The first three are free." and "all three packs"', 355: 'number word, part of "The first three are free." and "all three packs"',
    356: 'number word, as above', 357: 'number word, as above', 358: 'number word, as above',
    398: 'pack page: second half of the line over buying ("The first three are free. 27 more in Prism.")',
    399: 'pack page, over buying, reached after the free levels. Number word, then "27 more in Prism."',
    400: 'pack page, over buying, reached by tapping a locked level. Number word, then "27 more in Prism."',
    401: 'list of pack names ("Lens, Escapement and Prism")',
    403: 'Lens\'s levels counted; part of "25 panels unstirred" and the pack page\'s facts',
    404: 'Escapement\'s levels counted; part of other lines as Lens\'s', 405: 'Prism\'s levels counted; part of other lines as Lens\'s',
    378: 'restore purchases, running; replaces the control\'s words', 379: 'restore purchases, done; shown before "\u00B7 restore purchases"',
    380: 'restore purchases, nothing found; shown before "\u00B7 restore purchases"', 381: 'restore purchases, failed; shown before "\u00B7 restore purchases"',
    607: 'daily\'s share text: part of a line joined by " \u00B7 "', 608: 'moves played: part of the share line and of VoiceOver\'s sentences',
    609: 'daily\'s share text: moves ("7 moves"), then par; part of a line joined by " \u00B7 "',
    610: 'daily\'s share text: part of a line joined by " \u00B7 "', 611: 'daily\'s share text: part of a line joined by " \u00B7 "',
    659: 'pack page: first part of the bundle line ("or all three in Triptych I \u00B7 $5.99 \u00B7 save $2.98 \u203A")',
    660: 'pack page: last part of the bundle line', 377: 'bundle\'s page: what is free',
    0: 'daily and archive: result word (solved at par, first try, no undo or reset)', 1: 'result word: at par',
    2: 'result word: started, never solved', 3: 'result word: at par', 15: 'menu: header over the daily; archive: under today\'s number',
    27: 'settings\' title; menu: the settings stone', 51: 'a switch\'s state', 52: 'a switch\'s state',
    139: 'under the tank while a level\'s opening stir plays', 317: 'back button to the menu ("\u2191 levels"); heading of a pack\'s level list',
    316: 'back button to the archive ("\u2191 archive")', 394: 'back button to the menu ("\u2191 menu")',
    336: 'a closed tier\'s state', 345: 'menu beside the tank (wide windows): the row being played',
    347: 'menu: daily, endless or a pack not yet opened', 388: 'pack: Ask to Buy sent', 573: 'result word: solved over par, or an Escapement problem solved',
    522: 'stamped over a solved tank; the curtain after a tier\'s last level', 397: 'VoiceOver: a back button',
    332: 'VoiceOver: starts a new endless run', 604: 'VoiceOver: undo button. Undos left',
    476: 'Escapement: under the tank. Its tick budget', 567: 'Escapement: the wait button',
}

# Verdicts. A string named in none of them is kept as it stands.
CUT = {
    12: 'repeats the title "Archive" under it',
    13: 'explains the archive; the row and the practice caption already say what counts',
    14: 'the menu\'s archive row already gives this count; the slope\'s archive (docs/slope.md 7) leaves it out',
    32: 'says what "music" is', 34: 'says what "sounds" is', 36: 'says what "haptics" is',
    41: 'says what "restore purchases" does', 42: 'says what a privacy policy is',
    44: 'says what the switch does; Prism\'s page keeps its own line pointing at the switch, and that is where the letters matter',
    46: 'says where the mark shows; the mark is by the title on the menu as soon as the switch is on',
    320: 'flavour under "Sandbox"',
    323: 'VoiceOver\'s hint on the endless row, a pitch for the mode; the sighted row says nothing here, and the first tank\'s note, which VoiceOver reads too, gives the brim\'s rule',
    310: 'flavour; the sandbox\'s undo button already shows no count',
    363: 'slogan; the bundle\'s facts name its packs and its saving',
    365: 'audience advice; the three free levels show the buyer how hard the pack is. The pack proposals Jack picked from gave these lines ("Its card says \'after plughole\'"), and the approved pack page shows three fact lines: this leaves two',
    366: 'audience advice, as Lens\'s', 367: 'audience advice, as Lens\'s', 368: 'audience advice, as Lens\'s',
    370: 'the count ("25 panels") stays; "in four issues" is flavour and the level list shows its chapters',
    371: 'the count ("30 problems") stays; "in five chapters" is flavour', 372: 'the count ("30 specimens") stays; "in five trays" is flavour',
    474: '"Three clocks." is on the glass; the level shows "Unstir in %lld ticks." alone',
    582: 'teaches what clean is; learnt from the marks',
    583: 'teaches what clean is; the practice caption under the tank already says the first try counts',
    634: 'second line under "waiting for approval"; the button already reads "asked". It is already dropped when a failed ask shows its own line (approved 2026-11-02)',
    635: 'second line under "Triptych I is waiting for approval"',
    706: '"watch the stir" tells the player to look at the screen; shows "tap to skip" alone',
}
# before -> after
TRIM = {
    168: ('Turn a rod to look.', 'the second sentence is learnt on the first let-go; the ghost finger shows the turn'),
    240: ('Turn the glass\'s edge.', 'the second sentence is what the player then sees'),
    271: ('One knob has seized. Turn the tank.', 'the move count shows that turns count'),
    376: ('levels 1\u2013%lld free', '"no purchase" repeats "free"'),
    631: ('\u2713 owned', '"all three packs open" repeats "owned"'),
    632: ('\u2713 owned', '"every level open" repeats "owned"'),
    637: ('%@ is no longer shared with you', 'reassurance'),
    638: ('%@ isn\'t on this Apple ID any more', 'reassurance'),
    517: ('%@', 'VoiceOver needs the bundle\'s name; the slogan is cut and "A level from each pack, played." describes a picture'),
    518: ('%@: %@.', '"A level played." describes a picture'),
}
# Would be cut or trimmed, but the words rest on a call of Jack's: (the call, what is proposed)
NOTES = [171, 173, 175, 177, 180, 182, 185, 187, 190, 192, 194, 199, 201, 205, 210, 214, 222, 242, 244, 254, 273, 275, 281, 284, 293]
CALL = {
    740: ('Plughole 01 shows one quiet line under its note, once ever, pointing at settings. Jack asked for it on 2026-11-02 and ruled the same day that it stays as built; the slope rewords it because the gear is gone, and the slope\'s own open call 7 offers dropping it.',
          'cut, with its VoiceOver sentence: "settings" is now written on the opening screen'),
    741: ('VoiceOver\'s sentence for the same line.', 'cut with it'),
    519: ('The game\'s one credit, after the last free level. Jack set its words on 2026-11-11.',
          'trim to "made by screendead": the thanks is the kind of line this pass removes'),
    520: ('VoiceOver\'s sentence for the credit.', 'trim to "Made by screendead."'),
    325: ('The heading over the sandbox row. Jack put the sandbox at the end of the list "under \'anything goes\'" on 2026-11-01.',
          'cut: a heading over one row named "Sandbox"'),
    471: ('Escapement chapter 2\'s line under the tank. Jack settled this wording when the wait button came back (recorded 2026-11-13).',
          'trim to "Unstir in %lld ticks.": the second sentence is a hint'),
    718: ('The caption shown as Escapement\'s wait button is demonstrated. Jack\'s call of 2026-11-12 brought the wait button back on condition that the game makes clear a clock can tick with no knob turned.',
          'cut: problem 2\'s note ("Tap wait: the clock ticks, nothing turns.") and the demonstration itself make it clear; VoiceOver keeps its hint'),
}
NOTES_CALL = ('The strategy lines under the free tiers\' tanks. When Jack renamed every level on 2026-11-01 (plain nouns, one world per tier), the hints the old titles carried were moved into these notes, and on 2026-11-02 he ruled on one of them (plughole 02 has no note, as built).',
              'cut all 25: each is a tip a player finds by playing. The three notes that introduce a control (plughole 01, vortex 01, maelstrom 01) stay, trimmed as above, with the frost day\'s line and endless\'s first-tank rule')
# Today's words the slope (docs/slope.md 11 and 12) already replaces or drops: index -> what stands there instead
GONE = {
    6: 'dropped (slope call 9: the daily, archive and endless are marked by where they are)',
    303: 'dropped, as "past"',
    328: 'dropped: the tier chips become the tiers\' names on the water',
    612: '"bundle"', 613: '"bundle \u00B7 paid add-on"', 614: '"pack"', 615: '"pack \u00B7 paid add-on"',
    616: 'dropped: the facts stand without their keys', 617: 'dropped, as "for"', 621: 'dropped, as "for"',
    623: '"save %@" (the key "save" and the price)',
    664: '"packs \u00B7 paid add-ons \u00B7 first 3 levels of each free", under plughole\'s name',
    665: '"packs", under plughole\'s name', 666: 'joined into the line above',
    716: '"sound, haptics, colour letters: in settings, at the surface" (see the calls)',
    717: '"Sound, haptics and colour letters are in settings, at the surface of the menu." (see the calls)',
}
# The same catalog key written twice in code: listed once, under the second index.
DUP = {337: 729, 324: 733, 321: 734, 326: None}
SKIP = {47: 'editors\' build', 48: 'editors\' build', 359: 'First Stir', 364: 'First Stir', 369: 'First Stir', 402: 'First Stir'}
# Kept, where the wording itself is a call of Jack's: a rewrite changes what he decided.
FIXED = {
    20: 'consent card\'s question (2026-10-26)', 21: 'consent card\'s one line (2026-10-26)', 22: 'consent card\'s link (2026-10-26)',
    23: 'consent card\'s link, open (2026-10-28)', 707: '"reset? tap again" for 2 s (2026-11-01)',
    158: 'the pushed tick\'s words, and "again" against "reset" (2026-11-01)', 157: 'the pushed tick\'s words with no undo left (2026-11-01)',
    374: '"Lens is yours" after an Ask to Buy approval (2026-11-01)', 586: '"more puzzles in the packs \u203A" stays as built (2026-11-02)',
    8: 'the locked archive\'s words when tapped, Jack\'s own (2026-11-02)', 11: 'the locked archive row\'s line stays (2026-11-02)',
    400: 'the skip-ahead line over buying (2026-11-02)', 375: 'one line on Prism\'s page for the colour letters (2026-11-01)',
    345: '"playing" under the row being played (2026-11-03)', 670: 'VoiceOver\'s "next" stays (2026-11-11)',
    349: '"frost day" on the daily\'s row (2026-11-12)', 625: '"checking purchases\u2026" (2026-11-10)',
    395: '"\u2715 close" beside the menu (2026-11-03)', 593: '"more in Lens \u203A" on a pack\'s last free level (2026-11-01)',
    475: 'the wait button\'s explanation (2026-11-12)', 522: '"unstirred." heads the result (2026-11-04)',
    470: 'Escapement: a turn-back is not free, so the rule is stated (2026-10-24)',
}

GROUPS = {'fs': [], 'title': [], 'pic': [], 'chap': []}
rest = []
for i, x in enumerate(inv):
    k = x['key'] or ''
    if all(f.startswith('FirstStir') for f in x['files']): GROUPS['fs'].append(i)
    elif k.endswith('.title'): GROUPS['title'].append(i)
    elif k.startswith('picture.') or k.startswith('layout.'): GROUPS['pic'].append(i)
    elif k.startswith('chapter.'): GROUPS['chap'].append(i)
    else: rest.append(i)

named = set(CUT) | set(TRIM) | set(CALL) | set(NOTES) | set(GONE) | set(SKIP) | set(DUP)
assert all(i in rest for i in named), [i for i in named if i not in rest]
for a, b in [(CUT, TRIM), (CUT, CALL), (CUT, GONE), (TRIM, CALL), (TRIM, GONE), (CALL, GONE)]:
    assert not set(a) & set(b), set(a) & set(b)
assert not set(NOTES) & (set(CUT) | set(TRIM) | set(CALL) | set(GONE))
for i in NOTES: assert (inv[i]['key'] or '').endswith('.note'), inv[i]
KEEP, forms = [], set()  # trims and calls stay listed; a catalog key written twice in code is listed once
for i in rest:
    if i in CUT or i in GONE or i in SKIP or i in DUP: continue
    f = TRIM[i][0] if i in TRIM else None
    if not inv[i]['key']:
        f = f or form(i)
        if f in forms:
            assert i not in CALL and i not in NOTES, i
            DUP[i] = None
            continue
        forms.add(f)
    KEEP.append(i)


def where(i):
    if i in WHERE: return WHERE[i]
    c = inv[i]['comments']
    if not c: sys.exit(f'no place for {i}: {inv[i]["text"]}')
    return c[0] if len(c) == 1 else c[0] + ' (and ' + str(len(c) - 1) + ' more)'


def level(key):
    m = re.match(r'level\.([A-Za-z-]+?)-?(\d+)\.(title|note)', key)
    tier = {'L': 'plughole', 'N': 'whirlpool', 'V': 'vortex', 'M': 'maelstrom'}.get(m.group(1), m.group(1))
    return f'{tier} {int(m.group(2)):02d}'


def cell(s): return s.replace('|', '\\|')


# Text the inventory's patterns don't reach, added by hand.
ach = open(os.path.join(root, 'Sources', 'Achievements.swift')).read()
def cases(name):
    body = re.search(r'var ' + name + r': String \{\s*switch self \{(.*?)\n        \}', ach, re.S).group(1)
    return re.findall(r'case \.(\w+): "([^"]*)"', body)
ACH = {n: cases(n) for n in ('title', 'goal', 'earned')}
HAND_KEEP = [
    ('mail.subject', 'report a problem: the mail\'s subject. The app\'s version, then this', '%@: a problem'),
    ('mail.body', 'report a problem: the mail\'s first line, over the device\'s details', 'What happened:'),
    ('mail.to', 'report a problem, with no mail account: the share text\'s first line. The address', 'To: %@'),
    ('shelf.open', 'VoiceOver: an action on the bundle\'s page that opens one of its packs. The pack', 'Open %@'),
    ('share.name', 'daily\'s share text: its first words. The daily\'s number', 'Unstir #%lld'),
]
HAND_NAMES = [('name.app', 'the app', 'Unstir'), ('name.wordmark', 'menu: the wordmark', 'UNSTIR'), ('name.bundle', 'the bundle of the three packs', 'Triptych I'),
              ('name.pack.lens', 'pack', 'Lens'), ('name.pack.escapement', 'pack', 'Escapement'), ('name.pack.prism', 'pack', 'Prism')]
# The slope's words for screens not yet built (origin/slope/d-packs and e-archive do not exist): docs/slope.md 7 and 8.
SPEC = [
    ('slope.pack.eyebrow', 'pack page: over its name, unowned', 'pack \u00B7 paid add-on'),
    ('slope.pack.eyebrow.owned', 'pack page: over its name, owned', 'pack'),
    ('slope.bundle.eyebrow', 'bundle\'s page: over its name, unowned', 'bundle \u00B7 paid add-on'),
    ('slope.bundle.eyebrow.owned', 'bundle\'s page: over its name, owned', 'bundle'),
    ('slope.pack.levels', 'pack page: after the count on its floor ("0/30 at par \u00B7 levels \u2193"); opens the pack\'s level list', '\u00B7 levels \u2193'),
    ('slope.pack.floor.spoken', 'VoiceOver: pack page\'s way to its levels. Levels, then how many at par', 'Levels, %lld, %lld at par'),
    ('slope.back', 'every back button: the arrow, then "levels", "menu", "archive" or a pack\'s name', '\u2191 %@'),
    ('slope.close', 'wide windows: closes a page opened beside the menu', '\u2715 close'),
]

ids, lines, seen_id = {}, [], set()
def add(id, place, text):
    assert id not in seen_id, id
    assert '|' not in text and '\n' not in text, text
    seen_id.add(id); lines.append(f'{id} | {place} | {text}')

count = {}
for i in KEEP:
    x = inv[i]
    if x['key']:
        id = x['key']
    else:
        stem = next(f for f in x['files'] if not f.startswith('FirstStir')).replace('.swift', '').lower()
        count[stem] = count.get(stem, 0) + 1
        id = f'{stem}.{count[stem]:02d}'
    ids[i] = id
    text = TRIM[i][0] if i in TRIM else form(i)
    place = where(i)
    if x['key'] and x['key'].endswith('.note'): place = f'{level(x["key"])}: one line under the tank'
    plural = catalog.get(form(i), {}).get('localizations', {}).get('en', {}).get('variations', {}).get('plural')
    if not re.search('[A-Za-z]', text.replace('%lld', '').replace('%@', '')): continue
    if plural and i not in TRIM:
        add(id + '.one', place + ' (one)', plural['one']['stringUnit']['value'])
        add(id + '.other', place + ' (more than one)', plural['other']['stringUnit']['value'])
    else:
        add(id, place, text)
for id, place, text in HAND_KEEP + SPEC: add(id, place, text)
for case, text in ACH['goal']: add(f'achievement.{case}.goal', f'Game Center: how to earn "{dict(ACH["title"])[case]}"', text)
for case, text in ACH['earned']: add(f'achievement.{case}.earned', f'Game Center: "{dict(ACH["title"])[case]}", once earned', text)
for i in GROUPS['pic']:
    k = inv[i]['key']
    add(k, 'sandbox: the picture control\'s value' if k.startswith('picture.') else 'sandbox: the rods control\'s value', form(i))
names = list(HAND_NAMES)
for i in range(159, 167): names.append((f'name.tier.{inv[i]["text"]}', 'tier' + (', as written on the menu' if inv[i]['text'].islower() else ''), inv[i]['text']))
for i in GROUPS['chap']: names.append(('name.' + inv[i]['key'], where(i), form(i)))
for case, text in ACH['title']: names.append((f'name.achievement.{case}', 'Game Center achievement', text))
for i in GROUPS['title']: names.append(('name.' + inv[i]['key'], level(inv[i]['key']), form(i)))
tier_names = set(range(159, 167))
lines = [l for l in lines if not any(l.startswith(ids[i] + ' |') for i in tier_names)]
for id, place, text in names: add(id, place, text)

header = ('Unstir is an iPhone puzzle game: rods under a tank of picture twist it, and the player turns them back in the right order. '
          'Below is every piece of text it shows or speaks, one per line as: id | where it appears | current text. '
          'Rewrite only the text. Keep each line\'s case as it is (the app writes most things in lower case); keep it short; '
          'keep %lld, %@ and the like, in the same order; keep symbols such as \u203A \u2191 \u2193 \u00B7 \u2713 \u2715 \u21BA \u2197; '
          'make nothing longer, because text on screen never shrinks to fit; lines marked VoiceOver are spoken, not shown; '
          'lines whose id starts with "name." are names and do not change.')
open(os.path.join(root, 'docs', 'copy-keep.txt'), 'w').write(header + '\n' + '\n'.join(lines) + '\n')

# copy-cut.md
def files(i): return ', '.join(inv[i]['files'])
out = []
w = out.append
n_notes = len(NOTES)
kept_strings = len(KEEP) - len(CALL) - n_notes
w('# Copy cut\n')
w('Every piece of text the game shows or speaks, judged against one rule (Jack, 2026-11-23): a word stays only if a player')
w('cannot play, buy, restore, understand a lock or use the app accessibly without it, or the App Store or the law asks for')
w('it. This file lists what goes; `docs/copy-keep.txt` lists what stays, for rewriting. Nothing in `Sources/` is changed')
w('yet: apply these once the slope\'s pieces are merged.\n')
w('Read from `slope/base` and `origin/slope/integrate` (which holds the menu, play, result, settings and consent builders\'')
w('work); `tools/copy/inventory.py` lists the strings and `tools/copy/build.py` holds each verdict and writes both files.')
w('`origin/slope/d-packs` and `origin/slope/e-archive` did not exist on 2026-11-23, so the pack pages\' and the archive\'s')
w('words are today\'s (`Shelf.swift`, `Offer.swift`, `Archive.swift`) plus what `docs/slope.md` 7 and 8 specify. Placeholders')
w('are written as the String Catalog writes them (`%lld` a number, `%@` words).\n')
w('## Counts\n')
total = len(rest) - len(SKIP) - len(DUP) + len(HAND_KEEP) + len(SPEC) + len(ACH['goal']) * 3 + len(GROUPS['pic']) + len(GROUPS['chap']) + len(GROUPS['title']) + len(HAND_NAMES)
kept_total = kept_strings + len(HAND_KEEP) + len(SPEC) + len(ACH['goal']) * 3 + len(GROUPS['pic']) + len(GROUPS['chap']) + len(GROUPS['title']) + len(HAND_NAMES)
w('| | Strings |')
w('|---|---|')
w(f'| Inventoried | {total} |')
w(f'| Kept | {kept_total}, of them {len(TRIM)} trimmed, and {len(GROUPS["title"]) + len(GROUPS["chap"]) + len(ACH["title"]) + len(HAND_NAMES) + 8} names |')
w(f'| Cut | {len(CUT)} |')
w(f'| Calls for Jack | {len(CALL) + n_notes} ({len(CALL)} lines and the {n_notes} strategy notes, as one call) |')
w(f'| Gone with the slope already | {len(GONE)} |')
w(f'\nNot judged: First Stir\'s {len(GROUPS["fs"]) + 4} strings (the pack is out of v1 and no release build sells it), the editors\' build\'s two, and')
w('debug and harness text. A string used in several places counts once; a plural counts once.\n')

w('## Cut\n')
w('| Words | Where | Why |')
w('|---|---|---|')
for i in rest:
    if i in CUT: w(f'| {cell(form(i))} | {cell(where(i))} ({files(i)}) | {cell(CUT[i])} |')
w('\n## Trimmed\n')
w('| Today | Becomes | Where | Why |')
w('|---|---|---|---|')
for i in rest:
    if i in TRIM:
        place = level(inv[i]['key']) + ', under the tank' if inv[i]['key'] else where(i)
        w(f'| {cell(form(i))} | {cell(TRIM[i][0])} | {cell(place)} ({files(i)}) | {cell(TRIM[i][1])} |')
w('\nWhat follows from the cuts: a pack page\'s facts lose "after plughole" and the like entirely, and what a pack holds reads')
w('"25 panels"; Escapement\'s fifth chapter opens with "Unstir in %lld ticks." alone; a replay\'s opening shows "tap to skip";')
w('the five settings switches and three links stand without a second line, so VoiceOver gets no hint from them, and the')
w('analytics switch keeps its line, which says what is sent.\n')

w('## Calls for Jack\n')
w('Each would be cut or trimmed by the rule, but its words rest on a decision of his, so it stays, and is in')
w('`docs/copy-keep.txt`, until he agrees.\n')
w('| Words | Where | His decision | Proposed |')
w('|---|---|---|---|')
for i in rest:
    if i in CALL: w(f'| {cell(form(i))} | {cell(where(i))} ({files(i)}) | {cell(CALL[i][0])} | {cell(CALL[i][1])} |')
w(f'| The {n_notes} notes listed below | under the tank, one per level (Levels.swift) | {cell(NOTES_CALL[0])} | {cell(NOTES_CALL[1])} |')
w('\nThe strategy notes in that call:\n')
w('| Level | Note |')
w('|---|---|')
for i in NOTES: w(f'| {level(inv[i]["key"])} | {cell(form(i))} |')

w('\n## Gone with the slope already\n')
w('Today\'s words that `docs/slope.md` (11 and 12) replaces or drops. No decision here; only the slope\'s wording is in')
w('`docs/copy-keep.txt`.\n')
w('| Today | On the slope |')
w('|---|---|')
for i in rest:
    if i in GONE: w(f'| {cell(form(i))} | {cell(GONE[i])} |')
w('| "\u2039 levels", "\u2039 menu", "\u2039 archive", "\u2039 Triptych I" | "\u2191 levels", "\u2191 menu", "\u2191 archive", "\u2191 Triptych I" |')
w('| "UP A NOTCH", "WHIRLPOOL \u203A" | "up a notch", "whirlpool \u203A" |')

w('\n## Kept, with wording Jack decided\n')
w('These stay, and are in `docs/copy-keep.txt`, but their words were themselves his call: a rewrite of one changes that call.\n')
w('| Words | The call |')
w('|---|---|')
for i in rest:
    if i in FIXED and i in KEEP: w(f'| {cell(form(i))} | {cell(FIXED[i])} |')
w('| Solve a daily clean: at par on the first try, with no undo or reset. | No Wake\'s Game Center text (2026-11-13) |')
w('| every achievement\'s title | a stored value: a live achievement\'s title never changes |')

w('\n## Seen on the way\n')
w('- The sandbox\'s picture and rods controls show code names where no English was written: "glassTwin", "chainmailTwin",')
w('  "coralTwin", "neuronsTwin", "marblingTwin", "engineTurned", "triSwirl", "quadSwirl", "eyeSwirl", "pentSwirl", "hexSwirl".')
w('  They are kept as labels and listed for rewriting.')
w('- v1 ships with analytics off, so the consent card and the analytics switch are not in v1\'s build; they are kept for the')
w('  build that has them.')
open(os.path.join(root, 'docs', 'copy-cut.md'), 'w').write('\n'.join(out) + '\n')
print(f'inventoried {total}, kept {kept_total} (trimmed {len(TRIM)}), cut {len(CUT)}, call {len(CALL) + n_notes}, gone {len(GONE)}; keep.txt lines {len(lines)}')
