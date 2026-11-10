# shellcheck shell=bash
# Harness of the unit tests, sourced by every suite: case.sh and checks.sh of
# internal/testing of the shell library in SHELL_LIB, which the check of the
# scripts takes at the commit that test.yaml pins. A case is
#
#   setup; run NAME EXPECTED SCRIPT [NAME=VALUE...] [-- ARG...]; expect KIND ARGS...; finish
#
# where SCRIPT is a path in SCRIPTS, the scripts directory, run with only the
# variables of the harness and those given. A suite ends with conclude, which
# gives its exit status.

# shellcheck source=/dev/null
source "${SHELL_LIB:?}/internal/testing/case.sh"
# shellcheck source=/dev/null
source "$SHELL_LIB/internal/testing/checks.sh"
# The scripts that run takes paths in.
# shellcheck disable=SC2034 # read by checks.sh
code_root=${SCRIPTS:?}
