#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/archive-ios.sh [upload|export|archive] [xcodebuild settings...]   Archives Release for a generic iOS
# device into build/archive, then signs it for App Store Connect and uploads it to TestFlight (upload, the default),
# or writes the .ipa to build/export (export); archive stops after the archive. Settings after the mode go to the
# archive, e.g. CODE_SIGNING_ALLOWED=NO for an unsigned check.
# Takes the shell's build switches as scripts/build-ios.sh does (scripts/build-settings.sh), with AGE_RANGE YES unless
# set; EDITORS=YES makes the editors' build. SUPPORT_ADDRESS and POLICY_URL, from the shell or Config/Local.xcconfig,
# must be set to upload or export: without the first a tester's "report a problem" carries no address, without the
# second settings' privacy policy opens this repo's draft (docs/testflight.md).
# BUILD_NUMBER sets CFBundleVersion; unset, it is the UTC date and time, e.g. 20261112.1530 (no leading zero), which
# rises on every archive. UNSTIR_TEAM, if set, signs for that team in place of project.yml's.
# ASC_KEY_PATH, ASC_KEY_ID and ASC_ISSUER_ID name an App Store Connect API key (the .p8 stays outside the repo); unset,
# xcodebuild signs and uploads with the account signed in to Xcode.
set -euo pipefail
[[ -n "${ASC_KEY_PATH:-}" && "$ASC_KEY_PATH" != /* ]] && ASC_KEY_PATH="$PWD/$ASC_KEY_PATH"
cd "$(dirname "$0")/.."
mode="${1:-upload}"
(( $# )) && shift
case "$mode" in
  upload | export | archive) ;;
  *) echo "unknown mode: $mode (upload, export or archive)" >&2; exit 2 ;;
esac

AGE_RANGE="${AGE_RANGE:-YES}"
source scripts/build-settings.sh

if [[ -n "${BUILD_NUMBER:-}" ]]; then
  number="$BUILD_NUMBER"
else
  stamp=$(date -u +%Y%m%d.%H%M)
  number="${stamp%.*}.$((10#${stamp#*.}))"
fi
[[ "$number" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || { echo "BUILD_NUMBER must be one to three integers joined by dots: $number" >&2; exit 2; }

# Whether a setting has a value in the shell or Config/Local.xcconfig.
given() { [[ -n "${!1:-}" ]] || grep -Eqs "^[[:space:]]*$1[[:space:]]*=[[:space:]]*[^[:space:]]" Config/Local.xcconfig; }
if [[ "$mode" != archive ]]; then
  given SUPPORT_ADDRESS ||
    { echo "SUPPORT_ADDRESS is empty: set it in the shell or Config/Local.xcconfig, or testers' logs come with no address" >&2; exit 1; }
  given POLICY_URL ||
    { echo "POLICY_URL is empty: set it in the shell or Config/Local.xcconfig, or settings' privacy policy opens the repo's draft" >&2; exit 1; }
fi

auth=()
if [[ -n "${ASC_KEY_PATH:-}${ASC_KEY_ID:-}${ASC_ISSUER_ID:-}" ]]; then
  [[ -n "${ASC_KEY_PATH:-}" && -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" ]] ||
    { echo "set all three of ASC_KEY_PATH, ASC_KEY_ID and ASC_ISSUER_ID, or none" >&2; exit 2; }
  [[ -r "$ASC_KEY_PATH" ]] || { echo "can't read ASC_KEY_PATH" >&2; exit 2; }
  auth=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi
team=()
[[ -n "${UNSTIR_TEAM:-}" ]] && team=(DEVELOPMENT_TEAM="$UNSTIR_TEAM")

# The measuring probes never ship: refused from the shell, and held off over Config/Local.xcconfig and any setting given.
[[ "${PROBES:-}" == YES ]] && { echo "PROBES=YES is for measuring, never for an archive" >&2; exit 2; }
name="Unstir-$number"
[[ "${EDITORS:-}" == YES ]] && name+="-editors"
archive="build/archive/$name.xcarchive"
rm -rf "$archive"

xcodegen generate --quiet
echo "archiving $name"
xcodebuild -quiet -project Unstir.xcodeproj -scheme Unstir -configuration Release -destination "generic/platform=iOS" \
  -derivedDataPath build -archivePath "$archive" -allowProvisioningUpdates ${auth[@]+"${auth[@]}"} \
  ${settings[@]+"${settings[@]}"} ${team[@]+"${team[@]}"} CURRENT_PROJECT_VERSION="$number" "$@" PROBES=NO archive

app="$archive/Products/Applications/Unstir.app"
read_plist() { /usr/libexec/PlistBuddy -c "Print :$1" "$app/Info.plist" 2>/dev/null || true; }
built=$(read_plist CFBundleVersion)
support=$(read_plist SupportAddress)
policy=$(read_plist PolicyURL)
entitlements=$(codesign -d --entitlements - --xml "$app" 2>/dev/null || true)
echo "archived $archive: version $(read_plist CFBundleShortVersionString) ($built)," \
  "support address $([[ -n "$support" ]] && echo set || echo EMPTY),"
  "policy URL $([[ "$policy" =~ ^https?:// ]] && echo set || echo UNSET)," \
  "age range entitlement $([[ "$entitlements" == *com.apple.developer.declared-age-range* ]] && echo signed in || echo absent)," \
  "Game Center $(read_plist GameCenter), its entitlement $([[ "$entitlements" == *com.apple.developer.game-center* ]] && echo signed in || echo absent)"
[[ "$built" == "$number" ]] || { echo "the archive's build number is $built, not $number" >&2; exit 1; }
[[ "$mode" == archive ]] && exit 0
[[ -n "$support" ]] || { echo "the archive's SupportAddress is empty: not exporting it" >&2; exit 1; }
# As the app reads it (SettingsSheet.policy): anything but an http or https URL opens the repo's draft.
[[ "$policy" =~ ^https?:// ]] || { echo "the archive's PolicyURL isn't an http or https URL: not exporting it" >&2; exit 1; }
if [[ "$AGE_RANGE" == YES && "$entitlements" != *com.apple.developer.declared-age-range* ]]; then
  echo "the archive isn't signed with Declared Age Range's entitlement: not exporting it" >&2
  exit 1
fi
if [[ "$(read_plist GameCenter)" == YES && "$entitlements" != *com.apple.developer.game-center* ]]; then
  echo "the archive builds Game Center in but isn't signed with its entitlement: not exporting it" >&2
  exit 1
fi

options="build/archive/$name-ExportOptions.plist"
plutil -create xml1 "$options"
plutil -insert method -string app-store-connect "$options"
plutil -insert destination -string "$mode" "$options"
plutil -insert signingStyle -string automatic "$options"
# Xcode would otherwise set its own build number on upload, so the one in the archive and the device log would differ.
plutil -insert manageAppVersionAndBuildNumber -bool NO "$options"
plutil -insert uploadSymbols -bool YES "$options"
[[ -n "${UNSTIR_TEAM:-}" ]] && plutil -insert teamID -string "$UNSTIR_TEAM" "$options"

echo "$( [[ "$mode" == upload ]] && echo uploading || echo exporting ) $name"
xcodebuild -quiet -exportArchive -archivePath "$archive" -exportOptionsPlist "$options" -exportPath "build/export/$name" \
  -allowProvisioningUpdates ${auth[@]+"${auth[@]}"}
echo "done: build/export/$name"
