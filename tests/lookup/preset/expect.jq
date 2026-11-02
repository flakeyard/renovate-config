# A preset by exact tag is proposed exact tags only, never the moving tag vX
# (FY-0028). The fixture extends flakeyard/workflow-release, which has exact
# tags and a moving tag v0 like this repository, but releases already.
include "lookup";

no_problems,
(dep("renovate-config"; "flakeyard/workflow-release")
  | expect(every_update(.newValue | test(exact_tag_pattern)); "the preset is not proposed an exact tag"))
