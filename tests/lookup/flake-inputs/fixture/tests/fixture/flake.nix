# A fixture of the fixture: under a directory named fixture, so Renovate
# must not update it.
{
  inputs.nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-26.05&rev=08d3a97586f6b6343b3b5e799980773629432610&shallow=1";

  outputs = _: { };
}
