#!/usr/bin/env bash
# Usage: check-presets REPOSITORY
#
# Checks the presets and configuration files of REPOSITORY with Renovate's
# validator, then with the rules of presets/rules.jq that the validator cannot
# express. Prints every problem; fails when there is one.
set -euo pipefail
shopt -s inherit_errexit

repository=$1
rules_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/presets" && pwd)
inherited_config=org-inherited-config.json

# validate_global FILE: Renovate's validator on FILE as global configuration.
validate_global() {
  local file=$1
  renovate-config-validator --strict "$file"
}

# rule_problems KIND FILE: the problems that rules.jq finds in FILE, a file of
# KIND, one per line.
rule_problems() {
  local kind=$1 file=$2
  jq -r -L "$rules_dir" --arg kind "$kind" 'include "rules"; problems($kind)' "$file"
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

# check_inherited_config: the file the Mend app reads from main (FY-0029).
check_inherited_config() {
  validate_global "$inherited_config" && check_rules inherited "$inherited_config"
}

cd -- "$repository"
failed=0
check_inherited_config || failed=1
if ((failed)); then
  echo "::error::The presets or configuration files have problems."
  exit 1
fi
echo "The presets and configuration files pass."
