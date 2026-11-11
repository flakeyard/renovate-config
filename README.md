# renovate-config

[![OpenSSF Scorecard][scorecard-badge]][scorecard-viewer]

Renovate presets of flakeyard, consumed by every flakeyard repository and by
projects generated from flakeyard templates. They encode the update rules that
the [decisions][decisions] of flakeyard require and add no policy of their own.

## Usage

A generated project, or a repository that is not a flakeyard product, extends
the default preset in its `renovate.json`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>flakeyard/renovate-config#v0.1.0"]
}
```

Pin the preset by the tag `vX.Y.Z` of a release. Releases are immutable, so the
tag cannot move; the moving tag `vX` and branches must not be used
([FY-0028][fy-0028]). New releases of the preset arrive as Renovate pull
requests, like any other update.

A flakeyard repository extends the preset of its kind instead, which extends the
default preset at the same tag and makes updates of the files that consumers
receive `fix(deps)`, so that they are released ([FY-0007][fy-0007]):

| Preset              | Repositories | `fix(deps)` for           |
| ------------------- | ------------ | ------------------------- |
| `internal/action`   | `action-*`   | `action.yml`, `flake.nix` |
| `internal/atom`     | `atom-*`     | nothing                   |
| `internal/image`    | `image-*`    | `flake.nix`               |
| `internal/template` | `template-*` | `template/**`             |
| `internal/workflow` | `workflow-*` | `.github/actions/**`      |

Consumers of an atom follow every input of it, so its updates are not released.
The flake of a workflow repository only checks and tests it, so
`internal/workflow` makes updates of `flake.nix` `ci(deps)`.
`scripts/check/presets/rules.jq` holds the same table and fails when a preset
differs from it.

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>flakeyard/renovate-config//internal/action#v0.1.0"]
}
```

`.github` and `decisions` use the default preset. The presets in `internal/` are
not part of the public API and change with the flakeyard repositories. A
`workflow-*` repository also raises its product workflow, which a shared rule
cannot name ([FY-0003][fy-0003]):

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>flakeyard/renovate-config//internal/workflow#v0.1.0"],
  "packageRules": [
    {
      "description": "The product workflow (FY-0007, FY-0030)",
      "matchFileNames": [".github/workflows/release.yaml"],
      "semanticCommitType": "fix"
    }
  ]
}
```

- Test fixtures belong under a directory named `fixture` or `fixtures`; the
  preset ignores every path that contains one, so that fixtures keep their old
  versions.
- `ignorePaths` is replaced, not merged: a repository that sets its own must
  repeat `**/node_modules/**`, `**/bower_components/**`, `**/fixture/**` and
  `**/fixtures/**`.

## Rules

`default.json` sets every rule itself and extends no built-in preset, so that a
new Renovate version cannot change them ([FY-0029][fy-0029]). Every package rule
names its decision in its `description`.

- **Pull requests.** Every update is a pull request without approval on the
  Dependency Dashboard and without automerge; branches are rebased when they
  fall behind. The Dependency Dashboard lists pending updates.
- **Commits and labels.** Commit messages are `chore(deps): ...`, or
  `ci(deps): ...` for files under `.github/workflows/` and `.github/actions/`
  ([FY-0007][fy-0007]). Updates of `flakeyard/action-shell-lib` are
  `fix(deps): ...` wherever they are pinned, so that every consumer releases
  them ([FY-0035][fy-0035]); the rule follows the other commit types of the
  preset, because a later rule wins. Pull requests get the label `dependencies`,
  majors and minor updates below `1.0.0` also `breaking`, fixes of security
  alerts `security`.
- **Schedule and age.** Third-party updates are proposed on Mondays (UTC), 3
  days after their release. Updates of flakeyard's own actions, workflows, flake
  inputs, presets and images are proposed at any time and at once, `0.y.z`
  pre-releases included. Updates without a release date are not held back
  ([FY-0028][fy-0028]). Pull requests are not limited per hour
  (`prHourlyLimit: 0`), so a release of flakeyard does not wait behind other
  updates; Renovate's default of at most 10 open pull requests still applies.
- **Actions and workflows.** References are full commit SHAs with a version
  comment; references by tag are pinned. Runner labels such as `ubuntu-24.04`
  are not updated ([FY-0030][fy-0030]).
- **Flake inputs.** Only new commits of the locked `ref`, one pull request per
  input, with a link that compares the commits and, for flakeyard inputs, a link
  to the releases. Every other update type is disabled by name, including those
  of Renovate versions newer than the one of `flake.lock`; lock file maintenance
  is off ([FY-0016][fy-0016], [FY-0036][fy-0036]). Pull requests of third-party
  inputs are not updated outside their schedule (`updateNotScheduled: false`):
  nixpkgs gets new commits several times a day, and each would replace the
  commit under review and run the checks again. Such a pull request that falls
  behind `main` waits for the next Monday to be rebased, or for "Update branch"
  on GitHub.
- **Presets.** Only exact tags `vX.Y.Z`, never `vX` ([FY-0028][fy-0028]).
- **Other managers.** Every manager that Renovate enables by default runs, such
  as the one for the dev container image in `devcontainer.json`
  ([FY-0012][fy-0012]); Copier is off, because the Mend app does not run the
  tasks of templates.

## Limits

- The minimum release age delays an update only by the date its datasource
  reports. A tag pushed without a GitHub release, with an old commit date,
  passes at once, and updates without a date, such as flake inputs and images on
  the GitHub Container Registry, get no delay. The age protects against a
  compromised release that is noticed and withdrawn, not against a compromised
  upstream repository.
- Fixes of vulnerabilities skip the age and the schedule only when Renovate
  receives an alert for them. Actions pinned by SHA, flake inputs and images
  receive none: start such an update from the Dependency Dashboard.
- The Mend-hosted app chooses the Renovate version. The checks and tests here
  use the Renovate of `flake.lock`, 44.79.2; the version Mend last ran is not
  recorded yet.

## Public API

Releases follow [semantic versioning][versioning] ([FY-0024][fy-0024]). The
public API is the names of the presets outside `internal/` and the rules they
set explicitly that change which updates are proposed, grouped or merged
automatically, or which commit types they propose. Defaults of the Renovate
version that runs them are not part of it.

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
  (`nix fmt`), and the scripts with their unit tests (`tests/unit/`). The unit
  tests use the harness of `internal/testing` of
  [action-shell-lib][action-shell-lib] at the commit that `test.yaml` pins.
- `nix run .#check-lookup -- REF tests/lookup/*/` runs the lookup tests:
  Renovate looks up the updates of the files in `tests/lookup/<case>/fixture/`
  with the preset named in `preset`, read from the commit `REF` of this
  repository on GitHub, and `expect.jq` checks its report. `REF` must be pushed.
  The tests need the network and a token that can read public repositories in
  `RENOVATE_GITHUB_COM_TOKEN`, such as the one of `gh auth token`.

CI, `test.yaml`, runs the lookup tests with the commit under test, also weekly,
and then calls [workflow-check][workflow-check], which builds the checks of the
flake on both architectures and checks pull request titles, `renovate.json` and
the immutable release behind its preset tag ([workflow-check
ADR-0001][workflow-check-adr-0001]). Its weekly run also checks the end of life
of the nixpkgs branch in `flake.lock` ([FY-0036][fy-0036]). `scorecard.yaml`
runs OpenSSF Scorecard through [workflow-scorecard][workflow-scorecard].
Releases are made by release-please through `flakeyard/workflow-release`;
`0.y.z` releases are pre-releases.

This repository extends its own default preset by the tag of its latest release,
so every release comes back as a Renovate pull request here first. Read the job
log of that pull request in the Mend Developer Portal before other repositories
take the release: it shows the Renovate version Mend runs and whether it accepts
the presets.

## Bootstrap

This repository is bootstrapped under [FY-0022][fy-0022]. Until their providers
are released:

- actionlint, zizmor, shellcheck, shfmt, statix, deadnix, Prettier,
  markdownlint, typos and `reuse lint` run locally before every pull request
  (provider: the atoms).

## License

[MIT](LICENSE).

[decisions]: https://github.com/flakeyard/decisions
[fy-0016]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0016-pin-form.md
[fy-0029]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0029-renovate-mend.md
[fy-0022]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0022-bootstrap.md
[fy-0028]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0028-supply-chain.md
[fy-0007]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0007-branching-and-releases.md
[fy-0012]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0012-develop-in-container.md
[fy-0024]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0024-versioning-and-support.md
[fy-0030]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0030-actions-workflows-and-release-bot.md
[fy-0035]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0035-extract-logic-that-has-two-users.md
[fy-0036]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0036-check-the-end-of-life-of-nixpkgs-in-flake-lock.md
[versioning]: https://github.com/flakeyard/.github/blob/main/VERSIONING.md
[fy-0003]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0003-repository-naming.md
[workflow-check-adr-0001]:
  https://github.com/flakeyard/workflow-check/blob/main/docs/adr/records/0001-check-pull-requests-and-pushes.md
[action-shell-lib]: https://github.com/flakeyard/action-shell-lib
[workflow-check]: https://github.com/flakeyard/workflow-check
[workflow-scorecard]: https://github.com/flakeyard/workflow-scorecard
[scorecard-badge]:
  https://api.scorecard.dev/projects/github.com/flakeyard/renovate-config/badge
[scorecard-viewer]:
  https://scorecard.dev/viewer/?uri=github.com/flakeyard/renovate-config
