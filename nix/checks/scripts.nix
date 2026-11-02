# The scripts of .github pass shellcheck.
{
  perSystem =
    { pkgs, ... }:
    {
      checks.scripts =
        pkgs.runCommand "script-tests"
          {
            nativeBuildInputs = [ pkgs.shellcheck ];
            # A store path name cannot start with a period.
            github = builtins.path {
              name = "github";
              path = ../../.github;
            };
          }
          ''
            shellcheck "$github"/scripts/*.sh
            touch $out
          '';
    };
}
