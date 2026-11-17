# The scripts of the apps pass their unit tests, whose suites are at the paths
# of the scripts under tests/unit, with the harness of the shell library at the
# commit that test.yaml pins, so that the pin exists once.
{
  perSystem =
    {
      pkgs,
      presets,
      renovateSchema,
      root,
      ...
    }:
    let
      pin = builtins.match ".*uses: flakeyard/lib-actions@([0-9a-f]{40}) .*" (
        builtins.readFile (root + "/.github/workflows/test.yaml")
      );
      shellLib =
        if pin == null then
          throw "test.yaml pins no commit of flakeyard/lib-actions"
        else
          builtins.fetchGit {
            url = "https://github.com/flakeyard/lib-actions";
            rev = builtins.head pin;
            shallow = true;
          };
    in
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
            ];
            scripts = root + "/scripts";
            unit = root + "/tests/unit";
            inherit presets shellLib;
            RENOVATE_SCHEMA = renovateSchema;
          }
          ''
            # The sandbox has no /usr/bin/env.
            cp -r "$scripts" scripts
            cp -r "$shellLib" shell-lib
            chmod -R u+w scripts shell-lib
            patchShebangs scripts shell-lib
            # Renovate writes its cache under HOME.
            export HOME=$TMPDIR
            for suite in "$unit"/*/*.sh; do
              SHELL_LIB=$PWD/shell-lib SCRIPTS=$PWD/scripts PRESETS=$presets bash "$suite"
            done
            touch $out
          '';
    };
}
