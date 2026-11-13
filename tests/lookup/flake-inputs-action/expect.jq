# The flake of an action holds the tools it runs, so its inputs are fix, but
# an atom is a development tool and ci (FY-0007, FY-0038). The fixture is the
# one of flake-inputs.
include "lookup";

no_problems,
expect_commit_type("nixpkgs"; "fix"),
expect_commit_type("action-setup-nix"; "fix"),
expect_commit_type("atom-workflows"; "ci")
