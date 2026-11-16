# Rules for the presets and configuration files that Renovate's validator
# cannot express. problems(KIND) gives one message per broken rule of its
# input, a file of KIND, which the check also gives to the validator. $schema
# holds the JSON schema of the Renovate that runs the check, as --slurpfile
# gives it.

# The only keys org-inherited-config.json may hold, with the values of the
# organization settings in the Mend Developer Portal (FY-0029).
def onboarding_settings: {onboarding: false, requireConfig: "required"};

# Settings of default.json that decisions require, with the reason.
def required_settings: [
  {path: ["automerge"], value: false, reason: "no decision enables it; FY-0016 only allows it for atoms within a major version"},
  {path: ["dependencyDashboardApproval"], value: false, reason: "updates arrive as pull requests (FY-0028)"},
  {path: ["minimumReleaseAge"], value: "3 days", reason: "FY-0028"},
  {path: ["prHourlyLimit"], value: 0, reason: "a release of flakeyard reaches every repository at once (FY-0028)"},
  {path: ["minimumReleaseAgeBehaviour"], value: "timestamp-optional", reason: "nothing is held back forever (FY-0028)"},
  {path: ["lockFileMaintenance", "enabled"], value: false, reason: "FY-0016"},
  {path: ["nix", "enabled"], value: true, reason: "flake inputs are updated (FY-0016)"},
  {path: ["copier", "enabled"], value: false, reason: "the Mend app runs no Copier tasks (FY-0029)"}
];

# The only update type of flake inputs (FY-0016, FY-0036).
def flake_input_update_type: "digest";

# The directories of test fixtures, which pin old versions on purpose: fixture
# and the tests/fixtures of the organization's layout.
def fixture_paths: ["**/fixture/**", "**/fixtures/**"];

# How a description names the decision behind its rule.
def adr_pattern: "FY-[0-9]{4}";

# Update types that only Renovate versions newer than that of flake.lock
# know. The Mend app may run them, so the preset disables them ahead.
def newer_update_types: ["lockfileUpdate"];

# update_types: the update types that the Renovate of $schema knows.
def update_types: [$schema[0].definitions.matchUpdateTypes | .. | .enum? // empty] | first // [];

# default_ignore_paths: what ignorePaths is when a config does not set it.
def default_ignore_paths: $schema[0].definitions.ignorePaths.default;

# unexpected_keys(ALLOWED): the keys of the input that the object ALLOWED
# does not have.
def unexpected_keys($allowed): keys - ($allowed | keys) | .[];

# differing_values(EXPECTED): the entries of the object EXPECTED whose value
# the input does not have.
def differing_values($expected):
  . as $config | $expected | to_entries[] | select($config[.key] != .value);

def inherited_problems:
  (unexpected_keys(onboarding_settings)
    | "\(.) is not an onboarding key (FY-0029)"),
  (differing_values(onboarding_settings)
    | "\(.key) must be \(.value | tojson) (FY-0029)");

# Rules of every preset: no built-in presets, no allow-list of managers, and
# every package rule names its decision.
def preset_problems:
  (if has("enabledManagers") then "enabledManagers turns off every other manager without a warning" else empty end),
  (.packageRules // [] | to_entries[]
    | select(.value.description // "" | test(adr_pattern) | not)
    | "packageRules[\(.key)] has no description naming its FY decision");

# nix_rules_disabling: the package rules that disable flake inputs.
def nix_rules_disabling: .packageRules // [] | .[] | select(.matchManagers == ["nix"] and .enabled == false);

# flake_input_problems: every update type of flake inputs but one is
# disabled, by name: a rule without matchUpdateTypes disables the inputs
# themselves.
def flake_input_problems:
  (update_types - [flake_input_update_type]) as $unwanted
  | [nix_rules_disabling | .matchUpdateTypes // [] | .[]] as $disabled
  | (if update_types == [] then "the schema of Renovate lists no update types" else empty end),
    (nix_rules_disabling | select(has("matchUpdateTypes") | not)
      | "a rule disables flake inputs instead of their update types (FY-0016)"),
    ($unwanted - $disabled | .[] | "update type \(.) of flake inputs is not disabled (FY-0016)"),
    ($disabled - $unwanted - newer_update_types | .[]
      | "update type \(.) of flake inputs must not be disabled (FY-0016)");

# The libraries whose updates are fix in the presets of the repositories that
# ship them to their users, and nowhere else (FY-0040):
# - name: how the messages name the library;
# - names: its names in the managers that may pin it, github-actions by owner
#   and name, nix by URL;
# - presets: the presets that give it fix, which owners names in messages;
# - decisions: the decisions behind the rule.
# The shell library is run by actions in action.yml and by workflows in the
# workflow their callers use; the other presets leave its updates the type of
# the files they change, ci in CI (FY-0035, FY-0007). Its old name,
# action-shell-lib, stays until the repository is deleted, since its consumers
# move to lib-actions one by one. An atom pins lib-atom in its root flake.lock
# and a release of the atom delivers it to projects; its dev flake takes that
# pin, so lib-atom has no other.
def libraries: [
  {
    name: "flakeyard/lib-actions",
    names: [
      "flakeyard/lib-actions", "https://github.com/flakeyard/lib-actions",
      "flakeyard/action-shell-lib", "https://github.com/flakeyard/action-shell-lib"
    ],
    presets: ["internal/action.json", "internal/workflow.json"],
    owners: "the presets of actions and workflows",
    decisions: "FY-0035, FY-0040"
  },
  {
    name: "flakeyard/lib-atom",
    names: ["https://github.com/flakeyard/lib-atom"],
    presets: ["internal/atom.json"],
    owners: "the preset of atoms",
    decisions: "FY-0040"
  }
];

# The only keys of the rule that gives fix to a library: one more condition
# would leave some of its updates out.
def library_rule_keys: ["description", "matchPackageNames", "semanticCommitType"];

# gives_fix(NAMES): whether the input package rule gives fix to every update
# of the library with the names NAMES.
def gives_fix($names):
  .semanticCommitType == "fix"
  and (.matchPackageNames // [] | sort) == ($names | sort)
  and (keys - library_rule_keys == []);

# typed_rule_indexes(SELECTION): the indexes of the package rules of the
# input that give a commit type and hold SELECTION.
def typed_rule_indexes(selection):
  [.packageRules // [] | to_entries[] | select(.value | has("semanticCommitType") and selection) | .key];

# library_fix_problems(LIBRARY): updates of LIBRARY are fix, by a rule after
# every other commit type of the preset, because a later rule wins.
def library_fix_problems($library):
  typed_rule_indexes(gives_fix($library.names)) as $fixes
  | if $fixes == [] then "no package rule gives fix to every update of \($library.name) (\($library.decisions))"
    elif $fixes[-1] != typed_rule_indexes(true)[-1] then "the rule that gives fix to \($library.name) must follow every other commit type (\($library.decisions))"
    else empty end;

# library_problems: only the presets of each library give it fix.
def library_problems:
  libraries[] as $library
  | if any($library.presets[]; . == input_filename) then library_fix_problems($library)
    elif typed_rule_indexes(gives_fix($library.names)) != [] then "only \($library.owners) may give fix to \($library.name) (\($library.decisions))"
    else empty end;

# The atoms in the form Renovate gives flake inputs: development tools, whose
# updates change nothing consumers receive (FY-0038).
def atom_inputs: "https://github.com/flakeyard/atom-*";

# gives_atoms_ci: whether the input package rule gives ci to every update of
# an atom input and to nothing else.
def gives_atoms_ci:
  .semanticCommitType == "ci"
  and .matchManagers == ["nix"]
  and .matchPackageNames == [atom_inputs]
  and (keys - ["description", "matchManagers", "matchPackageNames", "semanticCommitType"] == []);

# atom_problems: the default preset gives ci to the atoms.
def atom_problems:
  if [.packageRules // [] | .[] | select(gives_atoms_ci)] == [] then "no package rule gives ci to every update of an atom input (FY-0038)" else empty end;

# atoms_released_problems: a rule of an internal preset that gives fix to
# flake.nix leaves out the atoms, so that their ci of the default preset
# stands.
def atoms_released_problems:
  .packageRules // [] | to_entries[]
  | select(.value.semanticCommitType == "fix" and (.value.matchFileNames // [] | index("flake.nix")))
  | select(.value.matchPackageNames // [] | index("!" + atom_inputs) | not)
  | "packageRules[\(.key)] gives fix to the atoms in flake.nix (FY-0038)";

def default_problems:
  preset_problems,
  (if has("extends") then "default.json must not extend presets (FY-0029)" else empty end),
  (. as $config | required_settings[] as $setting
    | select($config | getpath($setting.path) != $setting.value)
    | "\($setting.path | join(".")) must be \($setting.value | tojson): \($setting.reason)"),
  (default_ignore_paths + fixture_paths - .ignorePaths | .[]
    | "ignorePaths must contain \(.)"),
  flake_input_problems,
  atom_problems,
  library_problems;

# The files whose updates each internal preset gives a commit type: fix for
# the files consumers receive, ci for those that only check the repository
# (FY-0007). The default preset gives the rest theirs.
def commit_types: {
  "internal/action.json": {fix: ["action.yml", "flake.nix"]},
  "internal/atom.json": {},
  "internal/image.json": {fix: ["flake.nix"]},
  "internal/template.json": {fix: ["template/**"]},
  "internal/workflow.json": {fix: [".github/actions/**"], ci: ["flake.nix"]}
};

# typed_files(TYPE): the files that the package rules of the input give the
# commit type TYPE.
def typed_files($type):
  [.packageRules // [] | .[] | select(.semanticCommitType == $type) | .matchFileNames // [] | .[]] | unique;

def commit_type_problems:
  commit_types[input_filename] as $expected
  | if $expected == null then "\(input_filename) has no commit types in rules.jq"
    else ("fix", "ci") as $type
      | ($expected[$type] // [] | unique) as $required
      | typed_files($type) as $typed
      | select($typed != $required)
      | "\($type) is given to \($typed | tojson) instead of \($required | tojson) (FY-0007)"
    end;

# The presets of flakeyard repositories add rules to the default preset,
# which they extend by a reference relative to their own tag.
def internal_problems:
  preset_problems,
  (if .extends != ["/default"] then "an internal preset must extend exactly [\"/default\"]" else empty end),
  commit_type_problems,
  atoms_released_problems,
  library_problems;

# How a repository extends a preset: by the exact tag of a release, never by
# the moving tag vX, a branch or a reference relative to the repository
# (FY-0028).
def released_preset_pattern: "^github>flakeyard/renovate-config(//[a-z/]+)?#v[0-9]+\\.[0-9]+\\.[0-9]+$";

def repository_problems:
  (if (.extends // []) == [] then "renovate.json must extend a preset of this repository" else empty end),
  (.extends // [] | .[] | select(test(released_preset_pattern) | not)
    | "\(.) is not a preset of this repository by the tag of a release (FY-0028)");

def problems($kind):
  if $kind == "inherited" then inherited_problems
  elif $kind == "default" then default_problems
  elif $kind == "internal" then internal_problems
  elif $kind == "repository" then repository_problems
  else "unknown kind of file \($kind)"
  end;
