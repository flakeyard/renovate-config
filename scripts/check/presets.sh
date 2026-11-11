#!/usr/bin/env bash
# Usage: check-presets REPOSITORY
#
# Checks the presets and configuration files of REPOSITORY with Renovate's
# validator, then with the rules of presets/rules.jq that the validator cannot
# express. Prints every problem; fails when there is one. Inputs
# (environment): RENOVATE_SCHEMA, the JSON schema of the Renovate that runs.
set -euo pipefail
shopt -s inherit_errexit nullglob

repository=$1
rules_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/presets" && pwd)
inherited_config=org-inherited-config.json
default_preset=default.json
repository_config=renovate.json

# validate_global FILE: Renovate's validator on FILE as global configuration.
validate_global() {
  local file=$1
  renovate-config-validator --strict "$file"
}

# validate_repository FILE...: Renovate's validator on each FILE as the
# configuration of a repository, which presets are. One run checks every FILE
# and names the file of each problem; a run of the validator takes most of the
# time of the check.
validate_repository() {
  renovate-config-validator --strict --no-global "$@"
}

# rule_problems KIND FILE: the problems that rules.jq finds in FILE, a file of
# KIND, one per line.
rule_problems() {
  local kind=$1 file=$2
  jq -r -L "$rules_dir" --arg kind "$kind" --slurpfile schema "$RENOVATE_SCHEMA" \
    'include "rules"; problems($kind)' "$file"
}

# check_rules KIND FILE: prints the problems of FILE, a file of KIND; fails
# when there is one.
check_rules() {
  local kind=$1 file=$2 problems problem
  # Called in a condition, where errexit is off.
  problems=$(rule_problems "$kind" "$file") || {
    printf '::error file=%s::the rules could not be applied\n' "$file"
    return 1
  }
  [[ -z $problems ]] && return 0
  while IFS= read -r problem; do
    printf '::error file=%s::%s\n' "$file" "$problem"
  done <<<"$problems"
  return 1
}

# check_internal_presets_exist: the presets of flakeyard repositories, one per
# kind, are in internal/.
check_internal_presets_exist() {
  ((${#internal_presets[@]} > 0)) && return 0
  echo "::error::There are no presets in internal/."
  return 1
}

# validate_files: Renovate's validator on every file. The file the Mend app
# reads from main is global configuration (FY-0029).
validate_files() {
  local failed=0
  validate_global "$inherited_config" || failed=1
  validate_repository "$default_preset" "${internal_presets[@]}" "$repository_config" || failed=1
  return "$failed"
}

# check_all_rules: the rules of every file, also of those that the validator
# rejects, so that one run reports every problem: the file the Mend app reads
# from main (FY-0029), the rules for every repository and generated project,
# the presets of flakeyard repositories and the configuration of this
# repository, which extends a released preset like any other repository.
check_all_rules() {
  local preset failed=0
  check_rules inherited "$inherited_config" || failed=1
  check_rules default "$default_preset" || failed=1
  for preset in "${internal_presets[@]}"; do
    check_rules internal "$preset" || failed=1
  done
  check_rules repository "$repository_config" || failed=1
  return "$failed"
}

cd -- "$repository"
internal_presets=(internal/*.json)
failed=0
check_internal_presets_exist || failed=1
validate_files || failed=1
check_all_rules || failed=1
if ((failed)); then
  echo "::error::The presets or configuration files have problems."
  exit 1
fi
echo "The presets and configuration files pass."
