# renovate-config

Renovate presets of flakeyard, consumed by every flakeyard repository and by
projects generated from flakeyard templates. They encode the update rules that
the [decisions][decisions] of flakeyard require and add no policy of their own.

Work in progress: the presets are not released yet.

## Inherited configuration

The Mend-hosted Renovate app reads `org-inherited-config.json` from `main` of
this repository and applies it to every repository of the organization
([FY-0029][fy-0029]). The file is neither pinned nor released, so it holds only
the onboarding settings, the same as the organization settings in the Mend
Developer Portal: no onboarding pull requests, and no run in a repository
without its own `renovate.json`. The checks reject any other key.

## Development

- `nix flake check` checks the presets and configuration files with Renovate's
  validator and the rules of `scripts/check/presets/rules.jq`, formatting
  (`nix fmt`), and the scripts with their unit tests (`tests/unit/`).
- `nix run .#check-eol -- nixpkgs-eol` warns before the nixpkgs branch reaches
  its end of life ([FY-0026][fy-0026]).

CI runs the checks on both architectures; the weekly workflow
`maintenance.yaml`, which is not a required check, runs `check-eol`. Releases
are made by release-please through `flakeyard/workflow-release`; `0.y.z`
releases are pre-releases.

## Bootstrap

This repository is bootstrapped under [FY-0022][fy-0022]. Until their providers
are released:

- actionlint, zizmor, shellcheck, shfmt, statix, deadnix, Prettier,
  markdownlint, typos and `reuse lint` run locally before every pull request
  (provider: `workflow-check` and the atoms);
- pull request titles are checked by the reviewer (provider: `workflow-check`);
- rulesets require no status checks, so the checks of this repository's CI are
  not enforced before a merge (provider: `workflow-check`);
- the jobs `pending` and `required` of `.github/workflows/test.yaml` and
  `.github/scripts/commit-status.sh` and `required.sh` are a copy shared with
  the other bootstrapped repositories (provider: `workflow-check`);
- OpenSSF Scorecard is not run (provider: `workflow-check`);
- dependency updates are made by hand, following [FY-0016][fy-0016] and
  [FY-0028][fy-0028], while Renovate is not configured (provider:
  `renovate-config`).

## License

[MIT](LICENSE).

[decisions]: https://github.com/flakeyard/decisions
[fy-0016]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0016-pin-form.md
[fy-0026]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0026-stable-nixpkgs.md
[fy-0029]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0029-renovate-mend.md
[fy-0022]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0022-bootstrap.md
[fy-0028]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0028-supply-chain.md
