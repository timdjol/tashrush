#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

check_file() {
  if [[ -f "$project_dir/$1" ]]; then
    printf 'OK      %s\n' "$1"
  else
    printf 'MISSING %s\n' "$1"
    failures=$((failures + 1))
  fi
}

check_absent_text() {
  local file="$1"
  local text="$2"
  if grep -q "$text" "$project_dir/$file"; then
    printf 'REPLACE %s contains %s\n' "$file" "$text"
    failures=$((failures + 1))
  else
    printf 'OK      %s has no %s placeholder\n' "$file" "$text"
  fi
}

check_file android/app/google-services.json
check_file ios/Runner/GoogleService-Info.plist
check_file android/key.properties
check_file docs/PRIVACY_POLICY.md
check_absent_text docs/PRIVACY_POLICY.md '\[CONTACT_EMAIL\]'
check_absent_text docs/PRIVACY_POLICY.md '\[PUBLISH_DATE\]'
check_absent_text android/app/src/main/AndroidManifest.xml '3940256099942544'
check_absent_text ios/Runner/Info.plist '3940256099942544'

if (( failures > 0 )); then
  printf '\nRelease readiness: %d item(s) still require attention.\n' "$failures"
  exit 1
fi

printf '\nRelease readiness: local configuration checks passed.\n'
