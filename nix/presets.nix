# presets: the JSON files of the repository, the presets and configuration
# files that the checks read.
{
  perSystem =
    { lib, root, ... }:
    {
      _module.args.presets = lib.fileset.toSource {
        inherit root;
        fileset = lib.fileset.fileFilter (file: file.hasExt "json") root;
      };
    };
}
