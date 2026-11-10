#!/usr/bin/env bash
# Unit tests of scripts/check/lookup.sh with a stub of renovate, which saves
# the renovate.json of the fixture repository and writes the report $REPORT.
# Inputs (environment): SCRIPTS, the scripts directory.
set -uo pipefail
export LC_ALL=C

# shellcheck source-path=SCRIPTDIR source=../lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib.sh"

empty_report='{"problems": [], "repositories": {"local": {"problems": [], "packageFiles": {}}}}'

setup() {
  work=$(mktemp -d)
  mkdir -p "$work/bin" "$work/cases/one/fixture"
  # The sandbox of the check has no /usr/bin/env.
  printf '#!%s\n' "$BASH" >"$work/bin/renovate"
  cat >>"$work/bin/renovate" <<'STUB'
cp renovate.json "$CONFIG"
[[ -f flake.nix ]] || exit 1
for arg; do [[ $arg == --report-path=* ]] && printf '%s\n' "$REPORT" >"${arg#--report-path=}"; done
true
STUB
  chmod +x "$work/bin/renovate"
  touch "$work/cases/one/fixture/flake.nix"
  echo default >"$work/cases/one/preset"
  echo 'include "lookup"; empty' >"$work/cases/one/expect.jq"
  echo 'def nothing: empty;' >"$work/cases/lookup.jq"
  export PATH=$work/bin:$PATH CONFIG=$work/config REPORT=$empty_report
  export RENOVATE_GITHUB_COM_TOKEN=token
}

lookup() { "$SCRIPTS/check/lookup.sh" "$@"; }

# expect_extends PRESET: the renovate.json of the fixture repository extends
# exactly PRESET.
expect_extends() {
  local preset=$1
  jq -e --arg preset "$preset" '. == {extends: [$preset]}' "$CONFIG" >/dev/null ||
    report "renovate.json is $(cat -- "$CONFIG")"
}

setup
run "lookup: the default preset" ok lookup 0123abc "$work/cases/one/"
expect output "passed: $work/cases/one"
expect_extends "github>flakeyard/renovate-config#0123abc"
finish

setup
echo internal/action >"$work/cases/one/preset"
run "lookup: an internal preset" ok lookup 0123abc "$work/cases/one"
expect_extends "github>flakeyard/renovate-config//internal/action#0123abc"
finish

setup
printf '"first failure", "second failure"\n' >"$work/cases/one/expect.jq"
cp -r "$work/cases/one" "$work/cases/two"
echo empty >"$work/cases/two/expect.jq"
run "lookup: a failed expectation" fail lookup 0123abc "$work/cases/one" "$work/cases/two"
expect message "cases/one: first failure; second failure"
expect message "passed: $work/cases/two"
finish

setup
rm -- "$work/cases/one/fixture/flake.nix"
run "lookup: Renovate fails" fail lookup 0123abc "$work/cases/one"
expect message "the lookup could not run"
finish

setup
echo 'error("broken")' >"$work/cases/one/expect.jq"
run "lookup: a broken expectation" fail lookup 0123abc "$work/cases/one"
expect message "the lookup could not run"
finish

setup
unset RENOVATE_GITHUB_COM_TOKEN
run "lookup: no token" fail lookup 0123abc "$work/cases/one"
expect message "RENOVATE_GITHUB_COM_TOKEN is not set"
finish

summary
