# Copyright © 2026 Jack Lusher. All rights reserved.
# The analytics question, settings and the supporter mark. Sourced in order by scripts/shots.sh.
# The analytics question and settings. UNSTIR_CONSENT=ask asks, =yes or =no answers, for the launch only.
shot consent-ask "First launch: the analytics question over the dimmed menu, one line and a link to what it sends, which waits for yes or no." CONSENT=ask
shot consent-sends "First launch: the analytics question with its link opened, the full list of what it sends under the link that hides it again." CONSENT=sends
shot consent-gear "Menu with the settings gear beside the title, analytics answered yes." CONSENT=yes
shot consent-settings-on "The gear's sheet: music, sounds, haptics and colour letters, the analytics switch on, report a problem and privacy policy." CONSENT=yes SETTINGS=1
shot consent-settings-off "The gear's sheet: music, sounds, haptics and colour letters, the analytics switch off, report a problem and privacy policy." CONSENT=no SETTINGS=1
shot settings "Settings: music, sounds and haptics on, colour letters, restore purchases, report a problem, privacy policy, the version." SETTINGS=1
shot settings-quiet "Settings with music and haptics off." SETTINGS=1 MUSIC=0 HAPTICS=0
shot settings-restored "The gear's sheet after a restore found nothing: nothing to restore on this Apple ID." \
  SETTINGS=1 STORE=lens:unowned RESTORED=none
shot settings-supporter "The gear's sheet with a pack owned: a supporter mark switch, on, under colour letters." SETTINGS=1 OWNED=lens
shot menu-supporter "Menu with a pack owned: the supporter mark, a hairline four-pointed glint in plughole's sweep, after the title." \
  OWNED=lens BESTS=plughole:000000000 CONSENT=yes
shot menu-supporter-off "The same with the settings' supporter mark switched off: the title alone, as before any purchase." \
  OWNED=lens BESTS=plughole:000000000 CONSENT=yes SUPPORTER=0
shot menu-no-supporter "The same with nothing owned: no mark." BESTS=plughole:000000000 CONSENT=yes
# The editors' build's switch (EDITORS=YES), which UNSTIR_EDITORS=1 shows in a Debug build.
shot settings-editors "The editors' build's settings: open every tier, every level and pack too, without buying, under colour letters, off." \
  SETTINGS=1 EDITORS=1
