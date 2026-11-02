# The scripts of the apps and of .github pass shellcheck, and the scripts their
# unit tests, whose suites are at the paths of the scripts under tests/unit.
{
  perSystem =
    { pkgs, presets, ... }:
    {
      checks.scripts =
        pkgs.runCommand "script-tests"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              gnugrep
              jq
              renovate
              shellcheck
            ];
            scripts = ../../scripts;
            unit = ../../tests/unit;
            inherit presets;
            # A store path name cannot start with a period.
            github = builtins.path {
              name = "github";
              path = ../../.github;
            };
          }
          ''
            shellcheck "$scripts"/*/*.sh "$github"/scripts/*.sh
            shellcheck -x "$unit"/lib.sh "$unit"/*/*.sh
            # The sandbox has no /usr/bin/env.
            cp -r "$scripts" scripts
            chmod -R u+w scripts
            patchShebangs scripts
            # Renovate writes its cache under HOME.
            export HOME=$TMPDIR
            for suite in "$unit"/*/*.sh; do
              SCRIPTS=$PWD/scripts PRESETS=$presets bash "$suite"
            done
            touch $out
          '';
    };
}
