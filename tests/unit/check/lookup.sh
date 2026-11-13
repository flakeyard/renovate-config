#!/usr/bin/env bash
# Unit tests of scripts/check/lookup.sh with a stub of renovate, which saves
# the renovate.json of the fixture repository, writes the report $REPORT and,
# unless $LOG is empty, the log $LOG.
# Inputs (environment): SHELL_LIB, the shell library; SCRIPTS, the scripts
# directory.
# shellcheck disable=SC2154 # work comes from setup of the harness.
set -uo pipefail
export LC_ALL=C

# shellcheck source-path=SCRIPTDIR source=../lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib.sh"

empty_report='{"problems": [], "repositories": {"local": {"problems": [], "packageFiles": {}}}}'
# A log of Renovate without branches.
quiet_log='{"msg": "Repository started"}'

# setup_lookup: a case with the stub of renovate first on PATH and one case of
# the lookup tests.
setup_lookup() {
  setup
  mkdir -p "$work/bin" "$work/cases/one/fixture"
  # The sandbox of the check has no /usr/bin/env.
  printf '#!%s\n' "$BASH" >"$work/bin/renovate"
  cat >>"$work/bin/renovate" <<'STUB'
cp renovate.json "$CONFIG"
[[ -f flake.nix ]] || exit 1
for arg; do [[ $arg == --report-path=* ]] && printf '%s\n' "$REPORT" >"${arg#--report-path=}"; done
[[ -z $LOG ]] || printf '%s\n' "$LOG" >"$LOG_FILE"
true
STUB
  chmod +x "$work/bin/renovate"
  touch "$work/cases/one/fixture/flake.nix"
  echo default >"$work/cases/one/preset"
  echo 'include "lookup"; empty' >"$work/cases/one/expect.jq"
  echo 'def nothing: empty;' >"$work/cases/lookup.jq"
  apply PATH="$work/bin:$TESTING_BIN:$HOST_PATH" CONFIG="$work/config" REPORT="$empty_report" LOG="$quiet_log"
}

# lookup NAME EXPECTED ARG...: run the lookup with a token and ARG.
lookup() {
  local name=$1 expected=$2
  shift 2
  run "$name" "$expected" check/lookup.sh RENOVATE_GITHUB_COM_TOKEN=token -- "$@"
}

# expect_extends PRESET: the renovate.json of the fixture repository extends
# exactly PRESET.
expect_extends() {
  local preset=$1
  jq -e --arg preset "$preset" '. == {extends: [$preset]}' "$work/config" >/dev/null \
    || report "renovate.json is $(cat -- "$work/config")"
}

setup_lookup
lookup "lookup: the default preset" ok 0123abc "$work/cases/one/"
expect stdout "passed: $work/cases/one"
expect_extends "github>flakeyard/renovate-config#0123abc"
finish

setup_lookup
echo internal/action >"$work/cases/one/preset"
lookup "lookup: an internal preset" ok 0123abc "$work/cases/one"
expect_extends "github>flakeyard/renovate-config//internal/action#0123abc"
finish

setup_lookup
printf '"first failure", "second failure"\n' >"$work/cases/one/expect.jq"
cp -r "$work/cases/one" "$work/cases/two"
echo empty >"$work/cases/two/expect.jq"
lookup "lookup: a failed expectation" fail 0123abc "$work/cases/one" "$work/cases/two"
expect message "cases/one: first failure; second failure"
expect message "passed: $work/cases/two"
finish

setup_lookup
rm -- "$work/cases/one/fixture/flake.nix"
lookup "lookup: Renovate fails" fail 0123abc "$work/cases/one"
expect message "the lookup could not run"
finish

setup_lookup
apply LOG='{"msg": "branches", "branches": [{"prTitle": "ci(deps): a"}, {"prTitle": "fix(deps): b"}]}
{"msg": "Repository finished"}'
# shellcheck disable=SC2016 # a jq variable, not one of the shell.
echo '$branches[].prTitle' >"$work/cases/one/expect.jq"
lookup "lookup: the branches of the log" fail 0123abc "$work/cases/one"
expect message "cases/one: ci(deps): a; fix(deps): b"
finish

setup_lookup
apply LOG=""
lookup "lookup: Renovate writes no log" fail 0123abc "$work/cases/one"
expect message "the lookup could not run"
finish

setup_lookup
echo 'error("broken")' >"$work/cases/one/expect.jq"
lookup "lookup: a broken expectation" fail 0123abc "$work/cases/one"
expect message "the lookup could not run"
finish

setup_lookup
run "lookup: no token" fail check/lookup.sh -- 0123abc "$work/cases/one"
expect message "RENOVATE_GITHUB_COM_TOKEN is not set"
finish

conclude
