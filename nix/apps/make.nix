# mkApp { name, script } SETTINGS: the app NAME, which runs SCRIPT with
# coreutils and the runtimeInputs of SETTINGS on PATH.
{
  perSystem =
    { lib, pkgs, ... }:
    {
      _module.args.mkApp =
        { name, script }:
        {
          description,
          runtimeInputs ? [ ],
        }:
        {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              inherit name;
              runtimeInputs = [ pkgs.coreutils ] ++ runtimeInputs;
              text = builtins.readFile script;
            }
          );
          meta = { inherit description; };
        };
    };
}
