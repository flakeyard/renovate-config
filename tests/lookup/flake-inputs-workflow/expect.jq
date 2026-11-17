# The flake of a workflow only checks and tests it, so its inputs are ci, but
# the workflow runs the shell library for its callers, so it is fix, by a
# rule that follows the ci of flake.nix (FY-0007, FY-0035, FY-0040). The
# fixture is the one of flake-inputs.
include "lookup";

no_problems,
expect_commit_type("nixpkgs"; "ci"),
expect_commit_type("lib-actions"; "fix"),
expect_commit_type("lib-atom"; "ci"),
expect_commit_type("atom-workflows"; "ci")
