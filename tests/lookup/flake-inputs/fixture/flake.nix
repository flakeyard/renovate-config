# Inputs locked to older commits of their refs, so that each has a newer one.
{
  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-26.05&rev=08d3a97586f6b6343b3b5e799980773629432610&shallow=1";
    # The commit of v0.1.0; the moving tag v0 is at a later release.
    action-setup-nix = {
      url = "git+https://github.com/flakeyard/action-setup-nix?ref=v0&rev=2c58fef33760785dfe660be025fcadd88f1269b1&shallow=1";
      flake = false;
    };
  };

  outputs = _: { };
}
