#!/usr/bin/env bash
# Unit tests of scripts/check/presets.sh: each case breaks one rule in a copy
# of the presets. Inputs (environment): SHELL_LIB, the shell library; SCRIPTS,
# the scripts directory; PRESETS, the JSON files of the repository;
# RENOVATE_SCHEMA, the JSON schema of the Renovate that runs.
# shellcheck disable=SC2154 # work comes from setup of the harness.
set -uo pipefail
export LC_ALL=C

# shellcheck source-path=SCRIPTDIR source=../lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib.sh"

# setup_presets: a case with a writable copy of the presets.
setup_presets() {
  setup
  cp -r "$PRESETS" "$work/repo"
  chmod -R u+w "$work/repo"
}

# Paths and changes for the filters of the cases, which cannot contain "|":
# the package rule that disables update types of flake inputs and its list,
# and the package rule of the shell library, found by its description.
helpers='
  def nix_disabling: .packageRules[] | select(.matchManagers == ["nix"] and .enabled == false);
  def nix_disabled_types: nix_disabling | .matchUpdateTypes;
  def nix_disabling_everything: nix_disabling |= del(.matchUpdateTypes);
  def is_shell_library: .description | test("shell library");
  def shell_library: .packageRules[] | select(is_shell_library);
  def shell_library_removed: .packageRules |= map(select(is_shell_library | not));
  def shell_library_first: .packageRules |= ([.[] | select(is_shell_library)] + [.[] | select(is_shell_library | not)]);
'

# change FILE FILTER: rewrites FILE of the copy with the jq FILTER.
change() {
  local file=$work/repo/$1 filter=$2
  jq "$helpers $filter" "$file" >"$work/changed" && mv -- "$work/changed" "$file"
}

# check NAME EXPECTED: run the check on the copy, with the schema of Renovate.
check() {
  local name=$1 expected=$2
  run "$name" "$expected" check/presets.sh RENOVATE_SCHEMA="$RENOVATE_SCHEMA" -- "$work/repo"
}

setup_presets
check "presets: the repository" ok
finish

setup_presets
change renovate.json '.extends = ["github>flakeyard/renovate-config//internal/workflow#v1.2.3"]'
check "presets: an internal preset in renovate.json" ok
finish

while IFS='|' read -r name file filter message; do
  setup_presets
  change "$file" "$filter"
  check "presets: $name" fail
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
default, an hourly limit|default.json|del(.prHourlyLimit)|prHourlyLimit must be 0
default, updates held back|default.json|.minimumReleaseAgeBehaviour = "timestamp-required"|minimumReleaseAgeBehaviour must be "timestamp-optional"
default, lock file maintenance|default.json|.lockFileMaintenance.enabled = true|lockFileMaintenance.enabled must be false
default, no flake inputs|default.json|del(.nix)|nix.enabled must be true
default, copier|default.json|del(.copier)|copier.enabled must be false
default, automerge|default.json|.automerge = true|automerge must be false
default, fixture updated|default.json|.ignorePaths -= ["**/fixture/**"]|ignorePaths must contain **/fixture/**
default, fixtures updated|default.json|.ignorePaths -= ["**/fixtures/**"]|ignorePaths must contain **/fixtures/**
default, node modules updated|default.json|.ignorePaths = ["**/fixture/**"]|ignorePaths must contain **/node_modules/**
default, a flake input pinned|default.json|nix_disabled_types -= ["pin"]|update type pin of flake inputs is not disabled
default, new commits disabled|default.json|nix_disabled_types += ["digest"]|update type digest of flake inputs must not be disabled
default, flake inputs disabled|default.json|nix_disabling_everything|a rule disables flake inputs instead
default, an invalid option|default.json|.minimumReleaseAge = 3|Configuration Error
default, the shell library not fix|default.json|shell_library_removed|no package rule gives fix to every update of flakeyard/action-shell-lib
default, the shell library as a chore|default.json|shell_library.semanticCommitType = "chore"|no package rule gives fix to every update of flakeyard/action-shell-lib
default, the shell library only as an action|default.json|shell_library.matchManagers = ["github-actions"]|no package rule gives fix to every update of flakeyard/action-shell-lib
default, the shell library as a flake input left out|default.json|shell_library.matchPackageNames = ["flakeyard/action-shell-lib"]|no package rule gives fix to every update of flakeyard/action-shell-lib
default, the shell library before ci|default.json|shell_library_first|the rule that gives fix to flakeyard/action-shell-lib must follow every other commit type
internal, no default|internal/action.json|del(.extends)|must extend exactly ["/default"]
internal, a built-in preset|internal/image.json|.extends += ["config:recommended"]|must extend exactly ["/default"]
internal, the default by tag|internal/atom.json|.extends = ["github>flakeyard/renovate-config#v0.1.0"]|must extend exactly ["/default"]
internal, a rule without its decision|internal/template.json|.packageRules[0].description = "files"|packageRules[0] has no description
internal, enabledManagers|internal/workflow.json|.enabledManagers = ["github-actions"]|enabledManagers turns off
internal, the flake of a workflow released|internal/workflow.json|.packageRules[0].matchFileNames += ["flake.nix"]|fix is given to [".github/actions/**","flake.nix"] instead of [".github/actions/**"]
internal, the flake of a workflow not ci|internal/workflow.json|del(.packageRules[1])|ci is given to [] instead of ["flake.nix"]
internal, an action not released|internal/action.json|.packageRules[0].matchFileNames -= ["action.yml"]|fix is given to ["flake.nix"] instead of ["action.yml","flake.nix"]
internal, an atom released|internal/atom.json|.packageRules = [{description: "FY-0007", matchFileNames: ["flake.nix"], semanticCommitType: "fix"}]|fix is given to ["flake.nix"] instead of []
repository, no preset|renovate.json|del(.extends)|must extend a preset of this repository
repository, the moving tag|renovate.json|.extends = ["github>flakeyard/renovate-config#v0"]|is not a preset of this repository by the tag of a release
repository, a branch|renovate.json|.extends = ["github>flakeyard/renovate-config#main"]|is not a preset of this repository by the tag of a release
repository, a relative reference|renovate.json|.extends = ["/default"]|/default is not a preset of this repository
repository, a built-in preset|renovate.json|.extends += [":semanticCommits"]|:semanticCommits is not a preset of this repository
repository, another repository|renovate.json|.extends = ["github>flakeyard-evil/renovate-config#v1.0.0"]|is not a preset of this repository
internal, an invalid option|internal/action.json|.packageRules[0].semanticCommitType = 1|Configuration Error
CASES

# A filter that fails in rules.jq fails the check instead of passing it.
setup_presets
cp -r "$SCRIPTS" "$work/scripts"
chmod -R u+w "$work/scripts"
printf 'def problems(kind): error("broken");\n' >"$work/scripts/check/presets/rules.jq"
# run takes the script from the broken copy.
code_root=$work/scripts check "presets: broken rules" fail
expect message "the rules could not be applied"
finish

setup_presets
rm -r -- "$work/repo/internal"
check "presets: no internal presets" fail
expect message "There are no presets in internal/"
finish

setup_presets
printf 'not JSON\n' >"$work/repo/org-inherited-config.json"
check "presets: inherited, not JSON" fail
expect message "could not be parsed"
finish

conclude
