#!/usr/bin/env bash
# Download a recent LLVM/clang suitable for arm64 kernel builds (CI helper).
# Prefers system clang if version >= 14; otherwise fetches AOSP clang r487747c-ish tarball pattern.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-${ROOT}/.src/clang}"
mkdir -p "${DEST}"

have_good_clang() {
  command -v clang >/dev/null 2>&1 || return 1
  local maj
  maj="$(clang -dumpversion | cut -d. -f1)"
  [[ "${maj}" -ge 14 ]]
}

if have_good_clang && [[ "${FORCE_AOSP_CLANG:-0}" != "1" ]]; then
  echo "Using system clang: $(clang --version | head -n1)"
  echo "export PATH already OK"
  exit 0
fi

# Ubuntu packages are usually enough on GHA ubuntu-latest
if command -v apt-get >/dev/null 2>&1 && [[ "$(id -u)" -eq 0 || -n "${GITHUB_ACTIONS:-}" ]]; then
  echo "Install distro clang via apt if missing (handled in workflow)."
fi

# Optional: AOSP prebuilt (large). Enable with FETCH_AOSP_CLANG=1
if [[ "${FETCH_AOSP_CLANG:-0}" == "1" ]]; then
  echo "Fetching AOSP clang (large)..."
  # Pin a known good snapshot — update as needed
  CLANG_URL="${AOSP_CLANG_URL:-https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r547379.tar.gz}"
  tmp="$(mktemp -d)"
  if command -v curl >/dev/null 2>&1; then
    curl -L --retry 3 -o "${tmp}/clang.tar.gz" "${CLANG_URL}" || true
  fi
  if [[ -f "${tmp}/clang.tar.gz" ]]; then
    mkdir -p "${DEST}"
    tar -xzf "${tmp}/clang.tar.gz" -C "${DEST}"
    # find bin/clang
    CLANG_BIN="$(find "${DEST}" -type f -name clang | head -n1 || true)"
    if [[ -n "${CLANG_BIN}" ]]; then
      echo "CLANG_BIN=${CLANG_BIN}"
      echo "export PATH=$(dirname "${CLANG_BIN}"):\$PATH"
    fi
  fi
  rm -rf "${tmp}"
fi

echo "Done."
