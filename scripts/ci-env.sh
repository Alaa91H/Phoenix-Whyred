#!/usr/bin/env bash
# Shared CI helpers (sourced by other scripts)
# shellcheck disable=SC2034

set -euo pipefail

ci_is_github() {
  [[ "${GITHUB_ACTIONS:-}" == "true" ]] || [[ "${CI:-}" == "true" ]]
}

ci_nproc() {
  nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2
}

ci_free_disk() {
  df -h . | tail -1 || true
}

ci_log() {
  echo "::group::$*" 2>/dev/null || echo "==> $*"
}

ci_end_group() {
  echo "::endgroup::" 2>/dev/null || true
}

# GitHub-friendly shallow clone with retries
ci_git_clone() {
  local url="$1" dest="$2" branch="${3:-}"
  local tries=3 i=1
  local args=(clone --depth 1 --single-branch)
  [[ -n "${branch}" ]] && args+=(-b "${branch}")
  while [[ $i -le $tries ]]; do
    echo "git clone attempt $i/$tries: $url -> $dest"
    if git "${args[@]}" "$url" "$dest"; then
      return 0
    fi
    rm -rf "$dest"
    i=$((i + 1))
    sleep $((i * 5))
  done
  return 1
}
