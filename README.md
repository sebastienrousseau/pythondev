<!-- SPDX-License-Identifier: MIT -->

# pythondev — portable, disposable Python dev environment

[![ci](https://github.com/sebastienrousseau/pythondev/actions/workflows/ci.yml/badge.svg)](https://github.com/sebastienrousseau/pythondev/actions/workflows/ci.yml)

`pythondev` is a member of the [`langdev`][langdev] suite: a complete,
batteries-included **Python** toolchain inside a container you can spin up
and throw away in seconds, on any machine with Docker or Podman
(Linux, macOS, Windows/WSL2).

It ships CPython 3.13, the [`uv`][uv] package manager, a hash-pinned dev
toolchain (ruff, mypy, pytest & friends), and **your own dotfiles**
(shell, tmux, Neovim) pre-wired with a Python LSP — all built as a
hardened, non-root, read-only-rootfs image.

The developer environment IS your chezmoi-managed dotfiles: at build time
the image clones your dotfiles repo and runs `chezmoi apply`, so the
container has your *real* bashrc, aliases, tmux config, and Neovim setup —
**always the latest** by default (pin a tag/commit with the `DOTFILES_REF`
build arg for reproducible builds). **tmux is loaded by default**: the
entrypoint attaches to (or creates) a persistent `langdev` session for
interactive shells (opt out with `LANGDEV_NO_TMUX=1`).

## What's inside

| Component | Version | How it's pinned |
|---|---|---|
| Base OS | Alpine 3.22 | image **digest** (`sha256:14358309…`) |
| Python | **3.13.15** | built from source, **GPG + sha256** verified |
| uv | 0.12.7 | release binary, **sha256** verified (no `curl \| sh`) |
| ruff / mypy / pytest / … | see `requirements.txt` | **hash-locked** `requirements.lock` |
| basedpyright (LSP) | 1.39.10 | hash-locked; bundles node via `nodejs-wheel` |
| Dev env (shell/tmux/Neovim) | your dotfiles | git ref via `DOTFILES_REF` (latest by default) |

Alpine's `apk python3` tracks the 3.12 line (3.22/3.23) or 3.14 (3.24) and
never 3.13, so CPython 3.13.15 — the current 3.13 maintenance release as of
Aug 2026 — is built from source in a throwaway `toolchain` stage with both
its SHA-256 and its OpenPGP signature (release-manager key
`7169605F…`) verified before use.

## Quick start

```sh
make up            # build (if needed) + drop into an interactive dev shell
make run CMD="pytest -q"   # one-shot command in a fresh container
make trash         # remove the image + dangling build cache
```

`make` auto-detects **docker** or **podman** and adjusts mount flags
(SELinux `:Z`, userns) accordingly. Your project is bind-mounted at `/work`.

Inside the container everything is on `PATH` (the baked venv is first):

```sh
python --version        # Python 3.13.15
ruff check . && ruff format .
mypy .
pytest -q
pip-audit               # dependency CVE scan
nvim .                  # LSP: basedpyright + ruff server, no first-run downloads
```

Run `pyhelp` for the full alias list.

## Editor / LSP

Neovim comes from **your dotfiles** (authoritative). pythondev adds exactly
one spec — `nvim/plugins.local/lang.lua` — which is dropped into the
dotfiles' nvim config at build time and auto-imported via its
`plugins.local` convention. The plugin set is baked headless at build time,
so there are no first-launch downloads and the image stays reproducible and
network-free at runtime. Language servers are installed at **build time**
into the baked venv and are on `PATH`:

- **basedpyright** — type checking, completion, navigation.
- **ruff** via its native server (`ruff server`) — linting + formatting.
  (The deprecated `ruff-lsp` is **not** used.)

## Lifecycle

- **Build:** multi-stage. A `toolchain` stage builds CPython + the venv and
  installs `uv`; an `env-build` stage clones + `chezmoi apply`s your dotfiles
  and bakes the Neovim plugin set headless; the tiny `final` stage copies
  only runtime artifacts (interpreter, venv, `uv`, and the
  `/etc/profile.d/python.sh` shell fragment) onto the shared hardened base.
  No compilers or `-dev` packages reach the final image.
- **Run:** `make up` / `docker compose up` / `podman compose up`. The only
  bind mount is your code at `/work`. Interactive by default.
- **Trash:** `make trash`. The container is disposable; nothing you need
  lives outside your bind-mounted project directory.

## Security model

- Runs as non-root `dev` (UID/GID 1000); no `sudo`, no setuid binaries
  (setuid/setgid bits are stripped at build).
- `compose.yaml` / `make` enforce `cap_drop: [ALL]`,
  `no-new-privileges:true`, `read_only: true` root filesystem (with tmpfs
  for `/tmp`, `~/.cache`, `~/.local/state`), `pids_limit`, `mem_limit`.
- Supply chain: base image pinned **by digest**; CPython **GPG + sha256**
  verified; `uv` installed from a **checksum-verified** release binary (no
  `curl | sh`); Python deps installed from a **hash-pinned lockfile** with
  `uv pip install --require-hashes`.
- **No `.env` is committed or `COPY`'d** into the image — secrets are
  runtime-only via compose `env_file`. `.dockerignore` and `.gitignore`
  both block `.env` from the build context and from git.
- The healthcheck is a cheap `nvim --version` liveness probe — no
  full-filesystem scans.

> Vulnerability posture is enforced continuously by CI (Trivy, fail on
> HIGH/CRITICAL) rather than asserted by a static label; see the CI badge
> above for current status.

## Reproducing / updating the pins

- **Python deps:** edit a pin in `requirements.txt`, then `make lock`
  (regenerates the hashed `requirements.lock` with
  `uv pip compile --generate-hashes --python-version 3.13 --universal`).
- **Base image digest:** `make bump-base` (or update `ALPINE_DIGEST`).
- **Dotfiles:** latest by default; pin a tag/commit for reproducible builds
  with `--build-arg DOTFILES_REF=<tag|commit>` (or `DOTFILES_REPO=<url>` to
  point at a fork).
- **Shared core:** `make sync-common` re-vendors `common/` from `langdev`.

## CI

`.github/workflows/ci.yml` gates every change with **hadolint**
(Containerfile lint), **shellcheck** (all `*.sh`), a container **build**,
a **Trivy** scan (fails on HIGH/CRITICAL), and a **CycloneDX SBOM** upload.

## Portability

One OCI `Containerfile` builds with `docker build`, `podman build`,
`buildah`, and `nerdctl`; multi-arch (`linux/amd64`, `linux/arm64`) via
`make buildx`. No host-path assumptions beyond the `/work` bind mount.

## License

[MIT](LICENSE) — part of the [`langdev`][langdev] suite.

[langdev]: https://github.com/sebastienrousseau/langdev
[uv]: https://github.com/astral-sh/uv
