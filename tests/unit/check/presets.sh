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

# Paths and changes for the filters of the cases, which cannot contain "|":
# the package rule that disables update types of flake inputs and its list.
helpers='
  def nix_disabling: .packageRules[] | select(.matchManagers == ["nix"] and .enabled == false);
  def nix_disabled_types: nix_disabling | .matchUpdateTypes;
  def nix_disabling_everything: nix_disabling |= del(.matchUpdateTypes);
'

# change FILE FILTER: rewrites FILE of the copy with the jq FILTER.
change() {
  local file=$work/repo/$1 filter=$2
  jq "$helpers $filter" "$file" >"$work/changed" && mv -- "$work/changed" "$file"
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
default, a built-in preset|default.json|.extends = ["config:recommended"]|must not extend presets
default, enabledManagers|default.json|.enabledManagers = ["nix"]|enabledManagers turns off
default, a rule without its decision|default.json|.packageRules[0].description = "weekly"|packageRules[0] has no description
default, dashboard approval|default.json|.dependencyDashboardApproval = true|dependencyDashboardApproval must be false
default, a shorter age|default.json|.minimumReleaseAge = "1 day"|minimumReleaseAge must be "3 days"
default, updates held back|default.json|.minimumReleaseAgeBehaviour = "timestamp-required"|minimumReleaseAgeBehaviour must be "timestamp-optional"
default, lock file maintenance|default.json|.lockFileMaintenance.enabled = true|lockFileMaintenance.enabled must be false
default, no flake inputs|default.json|del(.nix)|nix.enabled must be true
default, copier|default.json|del(.copier)|copier.enabled must be false
default, automerge|default.json|.automerge = true|automerge must be false
default, fixtures updated|default.json|.ignorePaths -= ["**/fixture/**"]|ignorePaths must contain **/fixture/**
default, node modules updated|default.json|.ignorePaths = ["**/fixture/**"]|ignorePaths must contain **/node_modules/**
default, a flake input pinned|default.json|nix_disabled_types -= ["pin"]|update type pin of flake inputs is not disabled
default, new commits disabled|default.json|nix_disabled_types += ["digest"]|update type digest of flake inputs must not be disabled
default, flake inputs disabled|default.json|nix_disabling_everything|a rule disables flake inputs instead
default, an invalid option|default.json|.minimumReleaseAge = 3|Configuration Error
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
