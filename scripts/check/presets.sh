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

# The checks below print every problem they find and then set failed=1, so
# that one run reports every problem; they are not called in conditions, so
# errexit holds in them.

# check_rules KIND FILE: prints the problems that rules.jq finds in FILE, a
# file of KIND, one per line.
check_rules() {
  local kind=$1 file=$2 problems problem
  problems=$(jq -r -L "${rules_dir}" --arg kind "${kind}" --slurpfile schema "${RENOVATE_SCHEMA}" \
    'include "rules"; problems($kind)' "${file}") || {
    printf '::error file=%s::the rules could not be applied\n' "${file}"
    failed=1
    return 0
  }
  [[ -n ${problems} ]] || return 0
  while IFS= read -r problem; do
    printf '::error file=%s::%s\n' "${file}" "${problem}"
  done <<<"${problems}"
  failed=1
}

# check_internal_presets_exist: the presets of flakeyard repositories, one per
# kind, are in internal/.
check_internal_presets_exist() {
  ((${#internal_presets[@]} > 0)) && return 0
  echo "::error::There are no presets in internal/."
  failed=1
}

# validate_files: Renovate's validator on every file. The file the Mend app
# reads from main is global configuration (FY-0029); the others are the
# configuration of a repository, which presets are. One run checks every such
# file and names the file of each problem; a run of the validator takes most of
# the time of the check.
validate_files() {
  renovate-config-validator --strict "${inherited_config}" || failed=1
  renovate-config-validator --strict --no-global \
    "${default_preset}" "${internal_presets[@]}" "${repository_config}" || failed=1
}

# check_all_rules: the rules of every file, also of those that the validator
# rejects, so that one run reports every problem: the file the Mend app reads
# from main (FY-0029), the rules for every repository and generated project,
# the presets of flakeyard repositories and the configuration of this
# repository, which extends a released preset like any other repository.
check_all_rules() {
  local preset
  check_rules inherited "${inherited_config}"
  check_rules default "${default_preset}"
  for preset in "${internal_presets[@]}"; do
    check_rules internal "${preset}"
  done
  check_rules repository "${repository_config}"
}

cd -- "${repository}"
internal_presets=(internal/*.json)
failed=0
check_internal_presets_exist
validate_files
check_all_rules
if ((failed)); then
  echo "::error::The presets or configuration files have problems."
  exit 1
fi
echo "The presets and configuration files pass."
