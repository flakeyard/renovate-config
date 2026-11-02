# The app check-lookup: lookup tests with the Renovate of flake.lock. They
# need the network, so CI runs them as an app, not as a check.
{
  perSystem =
    { mkApp, pkgs, ... }:
    {
      apps.check-lookup =
        mkApp
          {
            name = "check-lookup";
            script = ../../../scripts/check/lookup.sh;
          }
          {
            description = "Check which updates Renovate proposes with the presets";
            runtimeInputs = with pkgs; [
              git
              jq
              renovate
            ];
          };
    };
}
