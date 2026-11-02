#!/usr/bin/env bash
# Usage: check-lookup REF CASE...
#
# Runs the lookup test of each CASE, a directory under tests/lookup. Renovate
# looks up the updates of the files in CASE/fixture with the preset that
# CASE/preset names, such as internal/action, taken from the commit REF of
# this repository on GitHub. CASE/expect.jq checks the report and prints one
# message per failure; it may include "lookup", the helpers in the directory
# above CASE. Needs the network. Inputs (environment):
# RENOVATE_GITHUB_COM_TOKEN, a token that can read public repositories.
set -euo pipefail
shopt -s inherit_errexit

ref=$1
shift
repository=flakeyard/renovate-config
# The fixture repository is committed with no configuration of the user.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

# preset_reference PRESET: how a repository extends PRESET at REF.
preset_reference() {
  local preset=$1
  if [[ $preset == default ]]; then
    printf 'github>%s#%s\n' "$repository" "$ref"
  else
    printf 'github>%s//%s#%s\n' "$repository" "$preset" "$ref"
  fi
}

# The functions below run in the condition of the loop over the cases, where
# errexit is off, so they chain their commands.

# fixture_repository CASE DIR: DIR becomes a git repository with the files of
# CASE/fixture and a renovate.json that extends the preset of CASE.
fixture_repository() {
  local case=$1 dir=$2 preset reference
  preset=$(<"$case/preset") &&
    reference=$(preset_reference "$preset") &&
    cp -r -- "$case/fixture/." "$dir" &&
    jq -n --arg preset "$reference" '{extends: [$preset]}' >"$dir/renovate.json" &&
    git -C "$dir" init -q &&
    git -C "$dir" add -A &&
    git -C "$dir" -c user.name=lookup -c user.email=lookup@localhost commit -q -m fixture
}

# look_up DIR REPORT: Renovate's lookup of the repository DIR, its report in
# the file REPORT.
look_up() {
  local dir=$1 report=$2
  (cd -- "$dir" && RENOVATE_BASE_DIR=$work/renovate renovate --platform=local \
    --dry-run=lookup --report-type=file --report-path="$report")
}

# failed_expectations CASE REPORT: what CASE/expect.jq finds wrong in REPORT.
failed_expectations() {
  local case=$1 report=$2
  jq -r -L "$(dirname -- "$case")" -f "$case/expect.jq" "$report"
}

# look_up_case CASE: the report of Renovate for CASE, in $work/report.json.
look_up_case() {
  local case=$1
  rm -rf -- "${work:?}"/* &&
    mkdir -- "$work/repository" &&
    fixture_repository "$case" "$work/repository" &&
    look_up "$work/repository" "$work/report.json"
}

# run_case CASE: runs the test CASE; fails when an expectation fails.
run_case() {
  local case=${1%/} failures
  if ! look_up_case "$case" || ! failures=$(failed_expectations "$case" "$work/report.json"); then
    printf '::error::%s: the lookup could not run\n' "$case"
    return 1
  fi
  if [[ -n $failures ]]; then
    printf '::error::%s: %s\n' "$case" "${failures//$'\n'/; }"
    return 1
  fi
  echo "passed: $case"
}

if [[ -z ${RENOVATE_GITHUB_COM_TOKEN-} ]]; then
  echo "::error::RENOVATE_GITHUB_COM_TOKEN is not set."
  exit 2
fi
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
failed=0
for case in "$@"; do
  run_case "$case" || failed=1
done
exit "$failed"
