# The scripts of the apps pass shellcheck and their unit tests, whose suites
# are at the paths of the scripts under tests/unit.
{
  perSystem =
    {
      pkgs,
      presets,
      renovateSchema,
      ...
    }:
    {
      checks.scripts =
        pkgs.runCommand "script-tests"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              git
              gnugrep
              jq
              renovate
              shellcheck
            ];
            scripts = ../../scripts;
            unit = ../../tests/unit;
            inherit presets;
            RENOVATE_SCHEMA = renovateSchema;
          }
          ''
            shellcheck "$scripts"/*/*.sh
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
