#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for dotfiles.d/python.sh — the Python language profile fragment
# installed to /etc/profile.d and sourced by login shells. The fragment only
# exports the baked venv env and prepends its bin to PATH (guarded, so it is
# safe to re-source). These tests source it in a hermetic sandbox and assert
# it sets that environment without error and is idempotent.
load helpers/common

setup() { common_setup; }

SCRIPT="dotfiles.d/python.sh"

@test "python.sh: sets the venv env and prepends the venv bin to PATH" {
  run bash -c '
    set -euo pipefail
    export PATH="/langdev-base"
    # shellcheck source=/dev/null
    source "$1"
    printf "VIRTUAL_ENV=%s\n" "$VIRTUAL_ENV"
    printf "PYTHONDONTWRITEBYTECODE=%s\n" "$PYTHONDONTWRITEBYTECODE"
    printf "PATHVAL=%s\n" "$PATH"
  ' _ "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"VIRTUAL_ENV=/opt/venv"* ]]
  [[ "$output" == *"PYTHONDONTWRITEBYTECODE=1"* ]]
  [[ "$output" == *"PATHVAL=/opt/venv/bin:/langdev-base"* ]]
}

@test "python.sh: is idempotent — re-sourcing does not duplicate the PATH entry" {
  run bash -c '
    set -euo pipefail
    export PATH="/langdev-base"
    source "$1"; source "$1"
    printf "PATHVAL=%s" "$PATH"
  ' _ "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  pathval="${output#PATHVAL=}"
  n="$(printf '%s' "$pathval" | grep -oF '/opt/venv/bin' | wc -l)"
  [ "$n" -eq 1 ]
}
