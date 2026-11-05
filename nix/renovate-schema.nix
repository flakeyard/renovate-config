# renovateSchema: the JSON schema of the Renovate of flake.lock, which the
# rules of scripts/check/presets/rules.jq read.
{
  perSystem =
    { pkgs, ... }:
    {
      _module.args.renovateSchema = "${pkgs.renovate}/lib/node_modules/renovate/renovate-schema.json";
    };
}
