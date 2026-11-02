# Rules for the presets and configuration files that Renovate's validator
# cannot express. problems(KIND) gives one message per broken rule of its
# input, a file of KIND that the validator accepted.

# The only keys org-inherited-config.json may hold, with the values of the
# organization settings in the Mend Developer Portal (FY-0029).
def onboarding_settings: {onboarding: false, requireConfig: "required"};

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

def problems($kind):
  if $kind == "inherited" then inherited_problems
  else "unknown kind of file \($kind)"
  end;
