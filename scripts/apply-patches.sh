#!/usr/bin/env bash
# Apply patches for the active KERNEL_TRACK — with safety checks
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"

COMMON="${ROOT}/${KERNEL_SRC}"

if [[ ! -f "${COMMON}/Makefile" ]]; then
  echo "ERROR: sources missing at ${COMMON}. Run setup.sh first."
  exit 1
fi

# Track patch results
PATCH_APPLIED=0
PATCH_FAILED=0
PATCH_SKIPPED=0

apply_series() {
  local dir="$1"
  local name="$2"
  [[ -d "${dir}" ]] || return 0
  local count
  count="$(find "${dir}" -maxdepth 1 -name '*.patch' 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "${count}" -eq 0 ]]; then
    echo "==> No patches in ${name}"
    return 0
  fi
  echo "==> Applying ${name} (${count} patches)..."
  while IFS= read -r -d '' p; do
    local pname
    pname="$(basename "${p}")"
    if git -C "${COMMON}" apply --check "${p}" 2>/dev/null; then
      git -C "${COMMON}" apply "${p}"
      echo "    APPLIED  ${pname}"
      PATCH_APPLIED=$((PATCH_APPLIED + 1))
    elif git -C "${COMMON}" apply --reverse --check "${p}" 2>/dev/null; then
      echo "    ALREADY_APPLIED  ${pname}"
    elif patch -d "${COMMON}" -p1 --dry-run -i "${p}" >/dev/null 2>&1; then
      patch -d "${COMMON}" -p1 -i "${p}"
      echo "    APPLIED (patch)  ${pname}"
      PATCH_APPLIED=$((PATCH_APPLIED + 1))
    else
      echo "    FAILED  ${pname}"
      PATCH_FAILED=$((PATCH_FAILED + 1))
    fi
  done < <(find "${dir}" -maxdepth 1 -name '*.patch' -print0 | sort -z)
}

echo "==> Track=${KERNEL_TRACK} tree=${COMMON}"

if [[ "${KERNEL_TRACK}" == "6.18" ]]; then
  apply_series "${ROOT}/patches/gki" "GKI"
  apply_series "${ROOT}/patches/sdm660" "SDM660"
  apply_series "${ROOT}/patches/android" "Android"
else
  apply_series "${ROOT}/patches/4.19" "4.19-whyred"
fi

echo ""
echo "==> Patch summary: applied=${PATCH_APPLIED} failed=${PATCH_FAILED} skipped=${PATCH_SKIPPED}"

if [[ ${PATCH_FAILED} -gt 0 ]]; then
  echo "ERROR: ${PATCH_FAILED} required patch(es) failed to apply"
  echo "Fix the patches or mark them as optional before proceeding"
  exit 1
fi

echo "==> Done"
