# The presets and configuration files pass Renovate's validator and the rules
# of scripts/check/presets/rules.jq, with the Renovate of flake.lock.
{
  perSystem =
    {
      pkgs,
      presets,
      renovateSchema,
      root,
      ...
    }:
    {
      checks.presets =
        pkgs.runCommand "presets"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              jq
              renovate
            ];
            scripts = root + "/scripts";
            inherit presets;
            RENOVATE_SCHEMA = renovateSchema;
          }
          ''
            # Renovate writes its cache under HOME.
            export HOME=$TMPDIR
            bash "$scripts/check/presets.sh" "$presets"
            touch $out
          '';
    };
}
