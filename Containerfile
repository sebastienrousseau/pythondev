# syntax=docker/dockerfile:1.9
# SPDX-License-Identifier: Apache-2.0 OR MIT
# pythondev Containerfile — OCI, builds with Docker AND Podman.
#
# A <language>dev image on the langdev foundation: Python 3.13 + uv + a
# hash-pinned dev toolchain (ruff, mypy, pytest, …) + Neovim wired for Python
# (basedpyright + ruff server) via the user's own dotfiles.
#
# The developer environment (shell, editor, tmux) is the USER'S OWN
# chezmoi-managed dotfiles, cloned + applied at build time (latest by default;
# pin with DOTFILES_REF). langdev provides only the hardened base + toolchain
# + a single nvim/plugins.local/lang.lua LSP drop-in. Everything below the
# "COMMON BASE" banner is identical across the suite (kept in sync via
# `make sync-common`); only the `toolchain` and `final` stages are
# Python-specific.
#
# Pin the base by DIGEST. Update via `make bump-base`.
ARG ALPINE_VERSION=3.22
# renovate: datasource=docker depName=alpine
ARG ALPINE_DIGEST=sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Dotfiles source — "always the latest" by default; pin a tag/commit for
# reproducible builds.
ARG DOTFILES_REPO=https://github.com/sebastienrousseau/dotfiles.git
ARG DOTFILES_REF=main

# --- Python + uv pins (real, verified values) --------------------------------
# Alpine's apk `python3` tracks 3.12 (3.22/3.23) or 3.14 (3.24), never the
# 3.13.x line, so we build CPython 3.13 from source with GPG + sha256
# verification (the foundation's documented fallback). 3.13.15 is the current
# 3.13 maintenance release as of Aug 2026.
ARG PYTHON_VERSION=3.13.15
ARG PYTHON_SHA256=c28d9d213c09b5b5ab2c29812950e12f746999e099b82894231be954b26baed9
# Thomas Wouters — CPython 3.12/3.13 release manager signing key.
ARG PYTHON_GPG_KEY=7169605F62C751356D054A26A821E680E5FA6305
# uv release binaries (checksum-verified; never `curl | sh`).
ARG UV_VERSION=0.12.7
ARG UV_SHA256_X86_64=3d64d44ed67da7908dc7f5c4d64ebb44bad326fa17f8a0a52fc9a7793017bbe1
ARG UV_SHA256_AARCH64=6dcf60e3c085de88ace3671b949ca99f0652be561ff5627f0d21394140f041db

###############################################################################
# Stage: toolchain  (PYTHON-SPECIFIC)
#   Builds CPython 3.13 into a relocatable prefix (/opt/python), installs a
#   checksum-verified `uv`, then materialises a ready-to-use virtualenv at
#   /opt/venv from the hash-pinned lockfile. The final stage copies both
#   prefixes verbatim (identical paths keep the venv valid).
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS toolchain
ARG PYTHON_VERSION
ARG PYTHON_SHA256
ARG PYTHON_GPG_KEY
ARG UV_VERSION
ARG UV_SHA256_X86_64
ARG UV_SHA256_AARCH64

# Build dependencies (this stage is thrown away; nothing here reaches final).
# hadolint ignore=DL3018
RUN apk add --no-cache \
      build-base \
      ca-certificates \
      gnupg \
      wget \
      bzip2-dev \
      gdbm-dev \
      libffi-dev \
      ncurses-dev \
      openssl-dev \
      readline-dev \
      sqlite-dev \
      util-linux-dev \
      xz-dev \
      zlib-dev

# Fetch, verify (sha256 + GPG), build and install CPython 3.13 -> /opt/python.
RUN set -eux; \
    wget -q -O python.tgz \
      "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"; \
    echo "${PYTHON_SHA256}  python.tgz" | sha256sum -c -; \
    wget -q -O python.tgz.asc \
      "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz.asc"; \
    GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "${PYTHON_GPG_KEY}"; \
    gpg --batch --verify python.tgz.asc python.tgz; \
    gpgconf --kill all || true; \
    rm -rf "${GNUPGHOME}" python.tgz.asc; \
    mkdir -p /usr/src/python; \
    tar -xf python.tgz -C /usr/src/python --strip-components=1; \
    rm python.tgz; \
    cd /usr/src/python; \
    ./configure \
      --prefix=/opt/python \
      --enable-shared \
      --with-system-ffi \
      --with-ensurepip=install \
      --without-static-libpython \
      LDFLAGS="-Wl,-rpath,/opt/python/lib"; \
    make -j"$(nproc)"; \
    make install; \
    cd /; rm -rf /usr/src/python; \
    find /opt/python -depth \
      \( -type d -a \( -name test -o -name tests -o -name idle_test -o -name __pycache__ \) \) \
      -exec rm -rf '{}' + ; \
    find /opt/python -type f -name '*.py[co]' -delete; \
    /opt/python/bin/python3 --version

# Install a checksum-verified `uv` release binary (per-arch).
RUN set -eux; \
    arch="$(apk --print-arch)"; \
    case "${arch}" in \
      x86_64)  uvtriple="x86_64-unknown-linux-musl";  uvsha="${UV_SHA256_X86_64}"  ;; \
      aarch64) uvtriple="aarch64-unknown-linux-musl"; uvsha="${UV_SHA256_AARCH64}" ;; \
      *) echo "unsupported arch: ${arch}" >&2; exit 1 ;; \
    esac; \
    wget -q -O uv.tgz \
      "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${uvtriple}.tar.gz"; \
    echo "${uvsha}  uv.tgz" | sha256sum -c -; \
    tar -xzf uv.tgz; \
    install -m 0755 "uv-${uvtriple}/uv" /usr/local/bin/uv; \
    rm -rf uv.tgz "uv-${uvtriple}"; \
    uv --version

# Create the venv and install the hash-pinned toolchain into it. The venv
# (and its LSP servers: basedpyright, ruff) live on /opt/venv/bin.
COPY requirements.lock /tmp/requirements.lock
RUN set -eux; \
    /opt/python/bin/python3 -m venv /opt/venv; \
    uv pip install --python /opt/venv/bin/python --no-cache \
      --require-hashes -r /tmp/requirements.lock; \
    rm /tmp/requirements.lock; \
    find /opt/venv -depth -type d -name __pycache__ -exec rm -rf '{}' + ; \
    /opt/venv/bin/python -c "import sys, ssl, sqlite3, lzma, ctypes; print(sys.version)"; \
    /opt/venv/bin/ruff --version; \
    /opt/venv/bin/basedpyright-langserver --help >/dev/null 2>&1 || true

###############################################################################
# Stage: env-build  (COMMON — apply the user's dotfiles + bake nvim plugins)
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS env-build
ARG USERNAME USER_UID USER_GID DOTFILES_REPO DOTFILES_REF
# Tools needed to clone+apply dotfiles and compile/install nvim plugins.
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash ca-certificates chezmoi curl git \
      neovim ripgrep fd fzf bat \
      build-base cmake
RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"
COPY --chown=${USER_UID}:${USER_GID} common/bootstrap-dotfiles.sh /usr/local/bin/langdev-bootstrap-dotfiles
RUN chmod 0755 /usr/local/bin/langdev-bootstrap-dotfiles
USER ${USERNAME}
ENV HOME=/home/${USERNAME}
# 1) Clone + chezmoi-apply the user's dotfiles (brings bashrc, tmux, nvim…).
RUN DOTFILES_REPO="${DOTFILES_REPO}" DOTFILES_REF="${DOTFILES_REF}" \
      langdev-bootstrap-dotfiles
# 2) Drop the Python LSP spec into the dotfiles' nvim (auto-imported via the
#    config's `plugins.local`), then bake the full plugin set headless so the
#    runtime needs no network on first launch.
COPY --chown=${USER_UID}:${USER_GID} nvim/plugins.local/ /home/${USERNAME}/.config/nvim/lua/plugins.local/
RUN nvim --headless "+Lazy! restore" +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+Lazy! sync"    +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+TSUpdateSync"  +qa 2>&1 | tail -n 5 || true

###############################################################################
#                              COMMON BASE
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS base
ARG USERNAME USER_UID USER_GID

LABEL org.opencontainers.image.title="pythondev" \
      org.opencontainers.image.description="Portable, hardened Python dev environment (langdev)" \
      org.opencontainers.image.licenses="Apache-2.0 OR MIT" \
      org.opencontainers.image.vendor="Sebastien Rousseau"

# Runtime deps: editor, multiplexer (tmux — available by default), and the
# CLI tools the dotfiles expect. `tini` is PID 1 (compose sets init:true).
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      bat \
      ca-certificates \
      chezmoi \
      curl \
      fd \
      fzf \
      git \
      less \
      neovim \
      ripgrep \
      tini \
      tmux \
      tzdata \
      zoxide \
 && update-ca-certificates

RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"

# Bring in the fully-populated home from env-build: the applied dotfiles
# (~/.bashrc, ~/.config/tmux, ~/.config/nvim, ~/.config/shell/*, …) plus the
# baked nvim plugin set. One COPY captures everything chezmoi wrote.
COPY --from=env-build --chown=${USER_UID}:${USER_GID} /home/${USERNAME} /home/${USERNAME}

# Entrypoint (tmux-loading, strict-mode).
COPY common/entrypoint.sh /usr/local/bin/langdev-entrypoint
RUN chmod 0755 /usr/local/bin/langdev-entrypoint \
 && mkdir -p /usr/local/lib/langdev

# --- Hardening ---------------------------------------------------------------
# Sticky bit preserved (1777, NOT 777). Strip setuid/setgid bits everywhere.
RUN chmod 1777 /tmp \
 && find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec chmod -s {} + 2>/dev/null || true

USER ${USERNAME}
WORKDIR /work
ENV HOME=/home/${USERNAME} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    EDITOR=nvim \
    XDG_CONFIG_HOME=/home/${USERNAME}/.config \
    XDG_DATA_HOME=/home/${USERNAME}/.local/share \
    XDG_STATE_HOME=/home/${USERNAME}/.local/state \
    XDG_CACHE_HOME=/home/${USERNAME}/.cache

# Cheap, honest liveness probe (no full-FS scans).
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD nvim --version >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/langdev-entrypoint"]

###############################################################################
# Stage: final  (PYTHON-SPECIFIC)
#   Adds ONLY runtime artifacts on top of the common base: the CPython
#   runtime shared libraries, the built interpreter (/opt/python), the
#   ready-made venv (/opt/venv), `uv`, and the language shell fragment.
###############################################################################
FROM base AS final
ARG USERNAME USER_UID USER_GID

USER root

# Runtime shared libraries CPython 3.13 links against (no *-dev, no build
# tools — those stayed in the toolchain stage).
# hadolint ignore=DL3018
RUN apk add --no-cache \
      libbz2 \
      libcrypto3 \
      libssl3 \
      libffi \
      gdbm \
      ncurses-libs \
      readline \
      sqlite-libs \
      xz-libs \
 && rm -rf /var/cache/apk/*

# Built interpreter + ready-to-use venv (same paths as the toolchain stage
# so the venv's shebangs / pyvenv.cfg stay valid). Root-owned, read-only.
COPY --from=toolchain /opt/python /opt/python
COPY --from=toolchain /opt/venv   /opt/venv
COPY --from=toolchain /usr/local/bin/uv /usr/local/bin/uv

# Language PATH/env for login shells: venv activation + tool aliases. Installed
# to /etc/profile.d (sourced via /etc/profile), root-owned 0644 — kept OUT of
# the user's chezmoi dotfiles so those stay pristine and langdev-agnostic.
COPY dotfiles.d/python.sh /etc/profile.d/python.sh
RUN chmod 0644 /etc/profile.d/python.sh

USER ${USERNAME}

# Put the venv first on PATH so `python`, `ruff`, `mypy`, `pytest`,
# `basedpyright-langserver`, `uv` all resolve to the baked toolchain.
# No PYTHONHOME/PYTHONPATH overrides — the venv is self-describing (this
# fixes the old python3.12 vs 3.13 path break).
ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:/opt/python/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
