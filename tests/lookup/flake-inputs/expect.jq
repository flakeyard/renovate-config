# Flake inputs get one update each, a new commit of their ref; a flakeyard
# input on its moving tag v0 too; a flake under a directory named fixture or
# fixtures is not updated (FY-0016). The case runs internal/image, and only the default
# preset enables flake inputs, so it shows that /default resolves.
include "lookup";

def new_commit_of($ref): .updateType == "digest" and .newValue == $ref and (.newDigest | test(sha_pattern));

no_problems,
(dep("nix"; "nixpkgs")
  | expect(every_update(new_commit_of("nixos-26.05")); "nixpkgs gets no new commit of nixos-26.05")),
(dep("nix"; "action-setup-nix")
  | expect(every_update(new_commit_of("v0")); "the flakeyard input gets no new commit of v0")),
(deps("nix") | select(.updates | length != 1)
  | "\(.depName) has \(.updates | length) updates instead of one"),
(.repositories.local.packageFiles.nix // [] | .[].packageFile | select(test("fixtures?/"))
  | "\(.) is updated")
