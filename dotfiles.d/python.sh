# /etc/profile.d/python.sh — pythondev language fragment (sourced by login
# shells via /etc/profile). Kept OUT of the user's chezmoi dotfiles so those
# stay pristine and langdev-agnostic.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# The image bakes a ready-to-use virtualenv at /opt/venv (CPython 3.13 plus
# the hash-pinned dev toolchain). We simply put it on PATH — no PYTHONHOME /
# PYTHONPATH overrides (the venv is self-describing; this avoids the old
# python3.12-vs-3.13 path break).

export VIRTUAL_ENV="/opt/venv"
case ":${PATH}:" in
  *":${VIRTUAL_ENV}/bin:"*) ;;
  *) PATH="${VIRTUAL_ENV}/bin:${PATH}" ;;
esac
export PATH

# Reproducible, quiet interpreter behaviour.
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# --- Aliases — ONLY for tools actually installed in the venv -----------------
alias py='python3'
# Fixes the old broken `pip=pip3.13` alias: route pip through the active
# interpreter so it always targets the baked venv.
alias pip='python3 -m pip'
alias venv='python3 -m venv'

# ruff (lint + format), mypy (types), pytest (tests) — all present in /opt/venv.
alias lint='ruff check'
alias fmt='ruff format'
alias typecheck='mypy'
alias pytest='pytest'
alias cov='pytest --cov'
alias audit='pip-audit'

# --- Help --------------------------------------------------------------------
pyhelp() {
  cat <<'EOF'
pythondev — installed toolchain (all in /opt/venv):
  python3 / py     CPython 3.13
  pip              -> python3 -m pip (venv)
  ruff / lint      ruff check         fmt   ruff format
  mypy / typecheck static type check
  pytest / cov     tests (+ coverage)
  audit            pip-audit (dependency CVE scan)
  bandit           security linter    codespell  spell check
  uv               fast installer/resolver
LSP (Neovim, baked): basedpyright + ruff server.
EOF
}
