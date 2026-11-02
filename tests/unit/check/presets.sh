#!/usr/bin/env bash
# Unit tests of scripts/check/presets.sh: each case breaks one rule in a copy
# of the presets. Inputs (environment): SCRIPTS, the scripts directory;
# PRESETS, the JSON files of the repository.
set -uo pipefail
export LC_ALL=C

# shellcheck source-path=SCRIPTDIR source=../lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib.sh"

setup() {
  work=$(mktemp -d)
  cp -r "$PRESETS" "$work/repo"
  chmod -R u+w "$work/repo"
}

# change FILE FILTER: rewrites FILE of the copy with the jq FILTER.
change() {
  local file=$work/repo/$1 filter=$2
  jq "$filter" "$file" >"$work/changed" && mv -- "$work/changed" "$file"
}

check() { "$SCRIPTS/check/presets.sh" "$work/repo"; }

setup
run "presets: the repository" ok check
finish

while IFS='|' read -r name file filter message; do
  setup
  change "$file" "$filter"
  run "presets: $name" fail check
  expect message "$message"
  finish
done <<'CASES'
inherited, a rule|org-inherited-config.json|.extends = [":semanticCommits"]|extends is not an onboarding key
inherited, onboarding|org-inherited-config.json|.onboarding = true|onboarding must be false
inherited, no requireConfig|org-inherited-config.json|del(.requireConfig)|requireConfig must be "required"
inherited, an invalid value|org-inherited-config.json|.requireConfig = "sometimes"|Invalid value `sometimes` for `requireConfig`
CASES

# A filter that fails in rules.jq fails the check instead of passing it.
setup
cp -r "$SCRIPTS" "$work/scripts"
chmod -R u+w "$work/scripts"
printf 'def problems(kind): error("broken");\n' >"$work/scripts/check/presets/rules.jq"
run "presets: broken rules" fail "$work/scripts/check/presets.sh" "$work/repo"
expect message "the rules could not be applied"
finish

setup
printf 'not JSON\n' >"$work/repo/org-inherited-config.json"
run "presets: inherited, not JSON" fail check
expect message "could not be parsed"
finish

summary
