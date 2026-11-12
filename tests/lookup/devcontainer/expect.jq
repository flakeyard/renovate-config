# The dev container image pinned by its moving tag v0 is updated to the digest
# of v0, never to an exact version tag.
include "lookup";

def digest_pattern: "^sha256:[0-9a-f]{64}$";

no_problems,
(dep("devcontainer"; "ghcr.io/flakeyard/image-devcontainer")
  | expect(every_update(.updateType == "digest" and .newValue == "v0" and (.newDigest | test(digest_pattern)));
      "the image is not updated to the digest of v0"))
