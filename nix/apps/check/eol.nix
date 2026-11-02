# The app check-eol: weekly maintenance, not required (FY-0026).
{
  perSystem =
    { mkApp, pkgs, ... }:
    {
      apps.check-eol =
        mkApp
          {
            name = "check-eol";
            script = ../../../scripts/check/eol.sh;
          }
          {
            description = "Warn before the nixpkgs branch reaches its end of life";
            runtimeInputs = [ pkgs.gnugrep ];
          };
    };
}
