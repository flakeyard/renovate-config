# renovate-config

Renovate presets of flakeyard, consumed by every flakeyard repository and by
projects generated from flakeyard templates. They encode the update rules that
the [decisions][decisions] of flakeyard require and add no policy of their own.

Work in progress: the presets are not released yet.

## Development

- `nix flake check` checks formatting (`nix fmt`).

## Bootstrap

This repository is bootstrapped under [FY-0022][fy-0022]. Until their providers
are released:

- actionlint, zizmor, shellcheck, shfmt, statix, deadnix, Prettier,
  markdownlint, typos and `reuse lint` run locally before every pull request
  (provider: `workflow-check` and the atoms);
- pull request titles are checked by the reviewer (provider: `workflow-check`);
- rulesets require no status checks, so the checks of this repository's CI are
  not enforced before a merge (provider: `workflow-check`);
- OpenSSF Scorecard is not run (provider: `workflow-check`);
- dependency updates are made by hand, following [FY-0016][fy-0016] and
  [FY-0028][fy-0028], while Renovate is not configured (provider:
  `renovate-config`).

## License

[MIT](LICENSE).

[decisions]: https://github.com/flakeyard/decisions
[fy-0016]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0016-pin-form.md
[fy-0022]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0022-bootstrap.md
[fy-0028]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0028-supply-chain.md
