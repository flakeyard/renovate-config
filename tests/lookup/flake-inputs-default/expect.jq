# Flake inputs are chore, the libraries too, since only the presets of the
# repositories that ship them make them fix, but an atom is a development tool
# and ci (FY-0007, FY-0038, FY-0040). The fixture is the one of flake-inputs.
include "lookup";

no_problems,
expect_commit_type("nixpkgs"; "chore"),
expect_commit_type("action-setup-nix"; "chore"),
expect_commit_type("lib-atom"; "chore"),
expect_commit_type("lib-actions"; "chore"),
expect_commit_type("atom-workflows"; "ci")
