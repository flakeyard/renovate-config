# Rules for the presets and configuration files that Renovate's validator
# cannot express. problems(KIND) gives one message per broken rule of its
# input, a file of KIND that the validator accepted. $schema holds the JSON
# schema of the Renovate that runs the check, as --slurpfile gives it.

# The only keys org-inherited-config.json may hold, with the values of the
# organization settings in the Mend Developer Portal (FY-0029).
def onboarding_settings: {onboarding: false, requireConfig: "required"};

# Settings of default.json that decisions require, with the reason.
def required_settings: [
  {path: ["automerge"], value: false, reason: "no checks are required yet (FY-0007, FY-0022)"},
  {path: ["dependencyDashboardApproval"], value: false, reason: "updates arrive as pull requests (FY-0028)"},
  {path: ["minimumReleaseAge"], value: "3 days", reason: "FY-0028"},
  {path: ["minimumReleaseAgeBehaviour"], value: "timestamp-optional", reason: "nothing is held back forever (FY-0028)"},
  {path: ["lockFileMaintenance", "enabled"], value: false, reason: "FY-0016"},
  {path: ["nix", "enabled"], value: true, reason: "flake inputs are updated (FY-0016)"},
  {path: ["copier", "enabled"], value: false, reason: "the Mend app runs no Copier tasks (FY-0029)"}
];

# The only update type of flake inputs (FY-0016, FY-0026).
def flake_input_update_type: "digest";

# The directory of test fixtures, which pin old versions on purpose.
def fixture_paths: "**/fixture/**";

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

def default_problems:
  preset_problems,
  (if has("extends") then "default.json must not extend presets (FY-0029)" else empty end),
  (. as $config | required_settings[] as $setting
    | select($config | getpath($setting.path) != $setting.value)
    | "\($setting.path | join(".")) must be \($setting.value | tojson): \($setting.reason)"),
  (default_ignore_paths + [fixture_paths] - .ignorePaths | .[]
    | "ignorePaths must contain \(.)"),
  flake_input_problems;

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
  commit_type_problems;

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
