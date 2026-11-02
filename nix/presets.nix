# presets: the JSON files of the repository, the presets and configuration
# files that the checks read.
{
  perSystem =
    { lib, ... }:
    {
      _module.args.presets = lib.fileset.toSource {
        root = ../.;
        fileset = lib.fileset.fileFilter (file: file.hasExt "json") ../.;
      };
    };
}
