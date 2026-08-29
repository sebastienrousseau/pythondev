<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

<p align="center">
  <img src="https://cloudcdn.pro/pythondev/v1/logos/pythondev.svg" alt="pythondev logo" width="128" />
</p>

<h1 align="center">pythondev</h1>

<p align="center">
  A portable, disposable Python development container — CPython 3.13
  built from source, <code>uv</code>, and a hash-locked dev toolchain
  on the hardened <a href="https://github.com/sebastienrousseau/langdev">langdev</a>
  core that builds with <b>both</b> Docker and Podman and boots the
  developer's own dotfiles.
</p>

<p align="center">
  <a href="https://github.com/sebastienrousseau/pythondev/actions"><img src="https://img.shields.io/github/actions/workflow/status/sebastienrousseau/pythondev/ci.yml?style=for-the-badge&logo=github" alt="Build" /></a>
  <a href="#license"><img src="https://img.shields.io/badge/license-Apache--2.0%20OR%20MIT-blue?style=for-the-badge" alt="License: Apache-2.0 OR MIT" /></a>
  <a href="https://scorecard.dev/viewer/?uri=github.com/sebastienrousseau/pythondev"><img src="https://img.shields.io/ossf-scorecard/github.com/sebastienrousseau/pythondev?style=for-the-badge&label=OpenSSF%20Scorecard&logo=openssf" alt="OpenSSF Scorecard" /></a>
  <a href="#portability"><img src="https://img.shields.io/badge/engines-docker%20%7C%20podman-1d63ed?style=for-the-badge&logo=docker" alt="Engines: Docker or Podman" /></a>
  <a href="#portability"><img src="https://img.shields.io/badge/arch-amd64%20%C2%B7%20arm64-555?style=for-the-badge" alt="Architectures: amd64, arm64" /></a>
</p>

---

## Contents

**Getting started**

- [Quick start](#quick-start) — clone, `make up`, and you are in a dev shell
- [Why this approach?](#why-this-approach) — the choices that shape the image

**What you get**

- [What's inside](#whats-inside) — the pinned toolchain, exactly
- [The developer environment IS your dotfiles](#the-developer-environment-is-your-dotfiles) — no synthetic config, tmux loaded by default

**Operational**

- [Security model](#security-model) — the container threat model and controls
- [Portability](#portability) — engines, architectures, host assumptions
- [When not to use pythondev](#when-not-to-use-pythondev) — limitations, stated plainly
- [Development](#development) — `make` targets, tests, lint, scan, SBOM, CI
- [Documentation](#documentation) — community docs and the house style
- [License](#license)

---

## Quick start

`pythondev` is standalone. Clone it, and one command gets you an
interactive, hardened Python shell in a fresh container:

```sh
git clone https://github.com/sebastienrousseau/pythondev.git
cd pythondev
make up                     # build (if needed) + interactive dev shell
```

Other everyday commands:

```sh
make run CMD="pytest -q"    # one-shot command in a fresh container
make trash                  # remove the image + dangling build cache
```

`make` auto-detects **docker** or **podman** and adjusts mount flags
(SELinux `:Z`, userns) accordingly. It runs the container non-root,
read-only, with all capabilities dropped (see
[Security model](#security-model)). Your project is the **only** bind
mount, at `/work`. Inside the container everything is on `PATH` (the
baked venv is first):

```sh
python --version            # Python 3.13.15
ruff check . && ruff format .
mypy .
pytest -q
pip-audit                   # dependency CVE scan
nvim .                      # LSP: basedpyright + ruff server, no first-run downloads
```

Run `pyhelp` for the full alias list. No registry pull, no base-image
dependency, and no network needed on first launch — the image is built
entirely from the repo you cloned.

---

## Why this approach?

Most "Python dev container" setups make one of two trades: a
root-running image with the kitchen sink and an unpinned `pip install`,
or a bare `python:slim` that leaves you to reassemble your editor,
shell, and tools every time. pythondev refuses both. Four choices, in
priority order, shape the image:

1. **Secure by default, not by opt-in.** The container runs as a
   non-root `dev` user (UID/GID 1000) with **all Linux capabilities
   dropped**, `no-new-privileges`, and a **read-only root filesystem**;
   writable state is confined to explicit `tmpfs` mounts. This is the
   default `make up` posture, not a hardened variant you have to
   remember to select. The threat model is [documented](SECURITY.md),
   not implied.

2. **Ultra-small but complete.** CPython, `uv`, `ruff`, `mypy`,
   `pytest`, `debugpy`, `pip-audit`, and a Neovim wired with
   `basedpyright` + `ruff server` are all present and on `PATH`, baked
   at build time in a throwaway `toolchain` stage; no compilers or
   `-dev` packages reach the final image. "Complete" is measured
   against editing, testing, type-checking, and debugging Python — not a
   feature list.

3. **Portable and disposable.** One OCI `Containerfile` builds with
   Docker, Podman, Buildah, and nerdctl; the `Makefile` auto-detects the
   engine and adjusts flags (SELinux `:Z` mounts, userns) accordingly.
   Images are multi-arch (`linux/amd64`, `linux/arm64`). The only bind
   mount is your project at `/work`, and `make trash` leaves nothing
   behind.

4. **Reproducible, verified inputs.** The Alpine base is pinned **by
   digest**; CPython is built from a source tarball checked against
   **both** its SHA-256 and its OpenPGP signature; `uv` is a
   **checksum-verified** release binary; and the Python dependency set
   installs from a **hash-pinned lockfile** with `--require-hashes`.
   There is no `curl | sh` anywhere in the build. Pin `DOTFILES_REF` to
   a tag or commit and a build is byte-reproducible.

Everything language-agnostic — the entrypoint, dotfiles bootstrap, and
`Containerfile`/`compose`/`Makefile` shape — is **vendored** from the
langdev core under `common/`. pythondev is therefore a complete,
auditable unit on its own, with no base-image drift and no supply-chain
hop at build time.

---

## What's inside

Every version is pinned, and every download is verified before use.

| Component | Version | How it's pinned |
|---|---|---|
| Alpine base | `3.22` | image **digest** (`sha256:14358309…`) |
| Python | **3.13.15** | built from source, **GPG + sha256** verified |
| uv | 0.12.7 | release binary, **sha256** verified (no `curl \| sh`) |
| ruff / mypy / pytest / debugpy / … | see `requirements.txt` | **hash-locked** `requirements.lock` |
| basedpyright (LSP) | 1.39.10 | hash-locked; bundles node via `nodejs-wheel` |
| Dotfiles (shell / tmux / Neovim) | latest | git ref via `DOTFILES_REF` (latest by default) |
| Neovim plugins | — | baked headless at build time from the dotfiles' `lazy-lock.json` |

Alpine's `apk python3` tracks the 3.12 line (3.22/3.23) or 3.14 (3.24)
and never 3.13, so CPython 3.13.15 — the current 3.13 maintenance
release as of Aug 2026 — is built from source in a throwaway
`toolchain` stage with **both** its SHA-256 and its OpenPGP signature
(release-manager key `7169605F…`) verified before the build begins.

The `toolchain` stage also installs a checksum-verified `uv` and
materialises a ready-to-use virtualenv at `/opt/venv` from the
hash-pinned `requirements.lock` (`uv pip install --require-hashes`).
The tiny `final` stage copies only runtime artifacts — the interpreter
(`/opt/python`), the venv (`/opt/venv`), `uv`, and the
`/etc/profile.d/python.sh` shell fragment — onto the shared hardened
base. No compilers or `-dev` packages reach the final image.

---

## The developer environment IS your dotfiles

pythondev does **not** ship a synthetic shell or editor config. At
build time the image clones the user's chezmoi-managed **dotfiles
repo** and runs `chezmoi apply`, so the container has the *real*
bashrc, aliases, tmux config, and Neovim setup — **always the latest**
by default. Pin `DOTFILES_REF` to a tag or commit for a reproducible
build (or `DOTFILES_REPO` to point at a fork); the exact commit bundled
is recorded at `~/.dotfiles.commit`.

- **tmux is installed and loaded by default.** An interactive shell
  attaches to (or creates) a persistent `langdev` tmux session, so panes
  and windows survive detach. Opt out with `LANGDEV_NO_TMUX=1`.
- **The dotfiles' Neovim config is authoritative.** pythondev drops
  exactly one `nvim/plugins.local/lang.lua` spec into the config's
  `plugins.local/` directory (auto-imported via that convention), so it
  composes with the rest of your setup untouched.
- **LSP via `nvim-lspconfig`.** Python is wired to **basedpyright** for
  type checking, completion, and navigation, and **ruff** via its native
  `ruff server` for linting and formatting; the deprecated `ruff-lsp` is
  **not** used. Both servers are installed at **build time** into the
  baked venv on `PATH` — no Mason, no first-launch downloads.
- **Baked, offline-ready.** The full plugin set (yours plus this spec)
  is baked headless at build time from your dotfiles'
  `nvim/lazy-lock.json`, so the container is reproducible and needs no
  network on first launch.

The language `PATH`/env lives in `/etc/profile.d/python.sh` — installed
root-owned and kept **out** of the user's dotfiles so those stay
pristine and langdev-agnostic.

---

## Security model

The full threat model and the private disclosure process are in
[`SECURITY.md`](SECURITY.md). Enforced by `compose.yaml` and mirrored in
`make run` / `make shell`:

- **Non-root.** Runs as `dev` (UID/GID 1000); no `sudo`, no setuid
  binaries — setuid/setgid bits are stripped at build.
- **Least privilege at runtime.** `cap_drop: [ALL]`,
  `security_opt: [no-new-privileges:true]`, `read_only: true` (with
  `tmpfs` for `/tmp`, `~/.cache`, and `~/.local/state`), plus
  `pids_limit` and `mem_limit`.
- **Cheap liveness probe.** The healthcheck is a `nvim --version`
  probe — no full-filesystem scans.
- **Pinned, checksummed inputs.** Alpine base pinned **by digest**;
  CPython **GPG + sha256** verified; `uv` from a **checksum-verified**
  release binary; Python deps installed from a **hash-pinned lockfile**
  with `uv pip install --require-hashes`. Never `curl | sh`.
- **No committed secrets.** No `.env` is committed or `COPY`'d into the
  image — secrets are runtime-only via compose `env_file`.
  `.dockerignore` and `.gitignore` block `.env` from both the build
  context and git.
- **One bind mount.** The only bind mount is your project directory at
  `/work`.
- **CI gates every change.** `hadolint`, `shellcheck`, a Docker build,
  and a Trivy image scan (fail on HIGH/CRITICAL) run on every push and
  pull request; a CycloneDX SBOM is uploaded as an artifact.

Report a vulnerability privately — see [`SECURITY.md`](SECURITY.md). Do
not open a public issue.

---

## Portability

- **One `Containerfile` (OCI).** `docker build`, `podman build`,
  `buildah`, and `nerdctl` all work from the same file.
- **Engine autodetection.** The `Makefile` detects `docker` or `podman`
  and adjusts flags (SELinux `:Z` mounts, userns) accordingly.
- **Multi-arch.** Images build for `linux/amd64` and `linux/arm64` via
  `make buildx`; the `uv` binary is fetched per-arch (`x86_64` /
  `aarch64`), each with its own checksum.
- **No host assumptions.** The only bind mount is your project directory
  at `/work`.

---

## When not to use pythondev

Stated plainly, so you can rule it out fast:

- **You need a production runtime image.** pythondev builds a
  *development* environment — editor, LSP, test and debug tooling, a
  shell. It is deliberately not a minimal production artifact; ship a
  separate, slimmer image for that.
- **You do not use chezmoi-managed dotfiles.** The environment *is*
  the user's dotfiles. Without a chezmoi dotfiles repo you lose the
  main point, though the hardening and Python toolchain layers still
  stand on their own.
- **You need a Python other than 3.13.** The image builds CPython
  3.13.15 from source. A different minor line means changing the
  pinned version, checksum, and signature — a deliberate edit, not a
  runtime toggle.
- **You need GPU passthrough or host-device access.** The default
  posture drops all capabilities and forbids privilege escalation;
  device access requires deliberate, documented relaxations that run
  against the grain of the design.
- **You are on a platform without Docker or Podman.** There is no
  VM-less fallback; pythondev targets an OCI engine on Linux, macOS, or
  Windows/WSL2.

---

## Development

The `Makefile` exposes the full lifecycle and auto-detects `docker` or
`podman` (adding `:Z` SELinux mount flags for Podman), so the same
commands work with either engine:

```sh
make up          # build + interactive dev shell (alias: make shell)
make run CMD=…   # one-shot command in a fresh container
make build       # build the image for the host arch
make buildx      # multi-arch build (linux/amd64, linux/arm64)
make lint        # hadolint the Containerfile + shellcheck the scripts
make scan        # Trivy vulnerability scan (fail on HIGH/CRITICAL)
make sbom        # CycloneDX SBOM via syft
make trash       # remove the image and dangling build cache
```

Updating the pins:

- **Python deps:** edit a pin in `requirements.txt`, then `make lock`
  regenerates the hashed `requirements.lock`
  (`uv pip compile --generate-hashes --python-version 3.13 --universal`).
- **Base image digest:** `make bump-base` (or update `ALPINE_DIGEST`).
- **Dotfiles:** latest by default; pin a tag/commit for reproducible
  builds with `--build-arg DOTFILES_REF=<tag|commit>` (or
  `DOTFILES_REPO=<url>` to point at a fork).

### Tests and coverage

The language-agnostic shell core — `common/bootstrap-dotfiles.sh` and
`common/entrypoint.sh` — is vendored verbatim from the
[`langdev`](https://github.com/sebastienrousseau/langdev) core. That
core is unit-tested with
[bats-core](https://github.com/bats-core/bats-core) under
[kcov](https://github.com/SimonKagstrom/kcov) in the langdev repo, whose
`make test` / `make coverage` gate **fails below 95 % line coverage**.
The tests are hermetic — `git`, `chezmoi`, `nvim`, `tmux`, and `rsync`
are test doubles on a closed `PATH`, so no network or container is
needed. The suite and its coverage gate are documented in
[langdev's `test/README.md`](https://github.com/sebastienrousseau/langdev/blob/main/test/README.md).

### CI and security workflows

This repo's [`.github/workflows/ci.yml`](.github/workflows/ci.yml) gates
every push and pull request with `hadolint`, `shellcheck`, a Docker
build, a Trivy image scan (fail on HIGH/CRITICAL), and a CycloneDX SBOM
artifact. The suite's OpenSSF hardening workflows are maintained in the
langdev core and provisioned across the suite from
[`templates/github-workflows/`](https://github.com/sebastienrousseau/langdev/tree/main/templates/github-workflows):

| Workflow | What it gates |
|---|---|
| `ci.yml` | shellcheck, hadolint, Docker build, Trivy image scan (fail HIGH/CRITICAL), CycloneDX SBOM |
| `scorecard.yml` | OpenSSF Scorecard, results published + SARIF to code-scanning |
| `sast.yml` | ShellCheck + Trivy config + Checkov, SARIF → code-scanning |
| `dependency-review.yml` | dependency + action changes reviewed on every PR |

The OpenSSF Best-Practices self-assessment lives in the langdev core's
[`doc/CII-BEST-PRACTICES.md`](https://github.com/sebastienrousseau/langdev/blob/main/doc/CII-BEST-PRACTICES.md);
a maintainer can apply the branch-protection ruleset with langdev's
[`scripts/set-branch-protection.sh`](https://github.com/sebastienrousseau/langdev/blob/main/scripts/set-branch-protection.sh).

Contributions require signed commits and Conventional Commit messages —
see [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## Documentation

| Document | What it covers |
|---|---|
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | The container workflow: build/test/lint/scan/sbom, signed commits, Conventional Commits. |
| [`SECURITY.md`](SECURITY.md) | The container threat model and the private disclosure process. |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Community standards and enforcement. |
| [`GOVERNANCE.md`](GOVERNANCE.md) | Who decides what, and how the maintainer base is meant to grow. |
| [`SUPPORT.md`](SUPPORT.md) | Where to go for questions, bugs, and feature requests. |
| [`CHANGELOG.md`](CHANGELOG.md) | Notable changes, Keep a Changelog format. |
| [langdev `doc/CII-BEST-PRACTICES.md`](https://github.com/sebastienrousseau/langdev/blob/main/doc/CII-BEST-PRACTICES.md) | OpenSSF Best-Practices self-assessment for the suite. |

pythondev follows the langdev suite's house style — see
[`STYLE.md`](https://github.com/sebastienrousseau/langdev/blob/main/STYLE.md)
in the `langdev` core.

---

## License

Licensed under either of

- Apache License, Version 2.0 ([`LICENSE-APACHE`](LICENSE-APACHE))
- MIT license ([`LICENSE-MIT`](LICENSE-MIT))

at your option. The suite is dual-licensed `Apache-2.0 OR MIT`; every
non-vendored file carries an `SPDX-License-Identifier: Apache-2.0 OR MIT`
header.

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms
or conditions.
