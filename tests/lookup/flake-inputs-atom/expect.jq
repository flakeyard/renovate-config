# Consumers of an atom follow its inputs, so their updates are chore and the
# atom is ci, but the atom pins lib-atom itself and a release delivers it to
# projects, so lib-atom is fix (FY-0038, FY-0040). The fixture is the one of
# flake-inputs.
include "lookup";

no_problems,
expect_commit_type("nixpkgs"; "chore"),
expect_commit_type("lib-atom"; "fix"),
expect_commit_type("lib-actions"; "chore"),
expect_commit_type("atom-workflows"; "ci")
