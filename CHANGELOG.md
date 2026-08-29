<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

`pythondev` is a member of the [`langdev`](https://github.com/sebastienrousseau/langdev)
suite: a complete, batteries-included Python toolchain inside a
portable, disposable container that builds with **both** Docker and
Podman and boots the developer's own chezmoi-managed dotfiles.

### Added

- **Python toolchain, built from source.** CPython 3.13.15 compiled
  in a throwaway `toolchain` stage with **both** its SHA-256 and its
  OpenPGP signature (release-manager key `7169605F…`) verified before
  use; Alpine's `apk python3` never tracks the 3.13 line.
- **`uv` package manager (0.12.7).** Installed from a
  checksum-verified release binary — never `curl | sh`.
- **Hash-locked dev toolchain.** `ruff`, `mypy`, `pytest`, `pip-audit`
  and friends installed into a baked `/opt/venv` from
  `requirements.lock` via `uv pip install --require-hashes`;
  `make lock` regenerates the hashed lockfile.
- **Editor wiring.** One `nvim/plugins.local/lang.lua` LSP spec —
  **basedpyright** (type checking, completion, navigation) plus
  **ruff** via its native `ruff server` (lint + format; the
  deprecated `ruff-lsp` is not used). The plugin set is baked
  headless at build time, so first launch needs no network.
- **The developer environment is your dotfiles.** At build time the
  image clones the user's chezmoi dotfiles and runs `chezmoi apply`;
  `tmux` is loaded by default (opt out with `LANGDEV_NO_TMUX=1`).
- **Security posture, on by default.** Non-root `dev` (UID/GID 1000);
  `cap_drop: [ALL]`; `no-new-privileges`; read-only root filesystem
  with `tmpfs` for `/tmp`, `~/.cache`, and `~/.local/state`;
  `pids_limit` and `mem_limit`; Alpine base pinned **by digest**; no
  committed or baked-in secrets.
- **`make` lifecycle.** `build`, `buildx` (multi-arch: `linux/amd64`,
  `linux/arm64`), `up`/`shell`, `run`, `lint`, `scan`, `sbom`, and
  `trash`.
- **Shared core (`common/`).** Vendored from `langdev` and refreshed
  with `make sync-common`, so the repo is standalone-buildable with no
  registry or base-image pull.

### Documentation

- Rewrote `README.md` to the langdev suite house style
  ([`STYLE.md`](https://github.com/sebastienrousseau/langdev/blob/main/STYLE.md)):
  centred header, badge row, Contents table, and the standard section
  order through to a dual-license stanza.
- Vendored the community docs: [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md),
  [`CONTRIBUTING.md`](CONTRIBUTING.md), [`SECURITY.md`](SECURITY.md),
  [`SUPPORT.md`](SUPPORT.md), [`GOVERNANCE.md`](GOVERNANCE.md), and the
  `.github/` scaffolding (`CODEOWNERS`, `FUNDING.yml`, `dependabot.yml`,
  a pull-request template, and issue forms).

### Licensing

- Relicensed from single MIT to **dual `Apache-2.0 OR MIT`**. Added
  `LICENSE-APACHE` and `LICENSE-MIT`, removed the single `LICENSE`
  file, and applied `SPDX-License-Identifier: Apache-2.0 OR MIT`
  headers across the non-vendored sources.

[Unreleased]: https://github.com/sebastienrousseau/pythondev/commits/main
