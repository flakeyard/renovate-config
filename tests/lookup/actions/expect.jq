# Actions and reusable workflows are updated by SHA with their version, a
# flakeyard pre-release is proposed, references within the repository ($/)
# and runner labels are not updated. The case runs internal/action, so the
# rules of the default preset show that its reference /default resolves.
include "lookup";

def pinned: (.newDigest // "" | test(sha_pattern)) and (.newValue | test(exact_tag_pattern));

no_problems,
(dep("github-actions"; "actions/checkout")
  | expect(every_update(pinned); "actions/checkout is not updated by SHA and exact version")),
(dep("github-actions"; "actions/setup-node")
  | expect(some_update(.updateType == "pinDigest"); "actions/setup-node by tag is not pinned")),
(dep("github-actions"; "flakeyard/workflow-release")
  | expect(some_update(pinned and (.newValue | startswith("v0."))); "the reusable workflow gets no pre-release")),
(deps("github-actions") | select(.depName | test("^[$.]"))
  | "\(.depName) is a dependency"),
(dep("github-actions"; "ubuntu")
  | expect(.skipReason == "disabled"; "runner labels are not disabled"))
