# The flake of an action holds the tools it runs, so its inputs are fix, the
# shell library also by its own rule, but an atom is a development tool and ci
# (FY-0007, FY-0035, FY-0038, FY-0040). The fixture is the one of flake-inputs.
include "lookup";

no_problems,
expect_commit_type("nixpkgs"; "fix"),
expect_commit_type("action-setup-nix"; "fix"),
expect_commit_type("lib-actions"; "fix"),
expect_commit_type("atom-workflows"; "ci")
