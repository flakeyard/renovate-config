# The dev container image pinned by an exact version tag is updated to a newer
# exact version tag together with its digest (FY-0012).
include "lookup";

def digest_pattern: "^sha256:[0-9a-f]{64}$";

no_problems,
(dep("devcontainer"; "ghcr.io/flakeyard/image-devcontainer")
  | expect(some_update(.newValue != "v0.1.9" and (.newValue | test(exact_tag_pattern)) and (.newDigest | test(digest_pattern)));
      "the image is not updated to a newer exact tag with its digest"),
    expect(every_update(.newValue | test(exact_tag_pattern));
      "the image is updated to a tag that is not an exact version"))
