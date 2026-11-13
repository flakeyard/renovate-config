# Helpers of the expectations of the lookup tests. An expectation is a jq
# program over the report of Renovate that prints one message per failure.

# The forms of a full commit SHA and of an exact version tag.
def sha_pattern: "^[0-9a-f]{40}$";
def exact_tag_pattern: "^v[0-9]+\\.[0-9]+\\.[0-9]+$";

# deps(MANAGER): the dependencies that MANAGER found.
def deps($manager): .repositories.local.packageFiles[$manager] // [] | .[].deps[];

# dep(MANAGER; NAME): the first dependency NAME that MANAGER found, or null.
def dep($manager; $name): first(deps($manager) | select(.depName == $name)) // null;

# expect(CONDITION; MESSAGE): MESSAGE unless CONDITION holds for the input.
def expect(condition; $message): if condition then empty else $message end;

# problems: what Renovate reported as problems of the run and the repository.
def problems: .problems + .repositories.local.problems;

# problem_messages: the messages of the problems, with the reason of an
# invalid config.
def problem_messages: problems | map([.msg, .err.validationError // empty] | join(": ")) | join(", ");

def no_problems: expect(problems == []; "Renovate reported problems: \(problem_messages)");

# some_update(CONDITION): whether an update of the input dependency holds
# CONDITION.
def some_update(condition): .updates // [] | any(condition);

# every_update(CONDITION): whether the input dependency has updates and all
# of them hold CONDITION.
def every_update(condition): .updates // [] | length > 0 and all(condition);

# commit_type(NAME): the commit type in the pull request title of the branch
# that updates the dependency NAME, or null. $branches holds the branches of
# the lookup, as check-lookup gives them.
def commit_type($name):
  first($branches[] | select(any(.upgrades[]; .depName == $name)) | .prTitle | capture("^(?<type>[a-z]+)[(:]").type) // null;

# expect_commit_type(NAME; TYPE): a message unless the pull request of the
# dependency NAME has the commit type TYPE.
def expect_commit_type($name; $type):
  commit_type($name) as $actual
  | expect($actual == $type; "\($name) is proposed as \($actual // "nothing") instead of \($type)");
