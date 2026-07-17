#!/usr/bin/env bash
# Import / inventory whyred-related pieces from the cloned 4.19 tree into vendor/import/
# Does NOT copy the entire multi-GB kernel (sources stay in .src/kernel-4.19).
# Use this to snapshot defconfig, DTS list, and techpack paths for documentation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"

SRC="${ROOT}/${KERNEL_419_DIR}"
OUT="${ROOT}/vendor/import/whyred-4.19"
MANIFEST="${OUT}/MANIFEST.txt"

if [[ ! -f "${SRC}/Makefile" ]]; then
  echo "ERROR: 4.19 tree not found. Run: KERNEL_TRACK=4.19 ./scripts/setup.sh"
  exit 1
fi

mkdir -p "${OUT}/defconfig" "${OUT}/dts-list" "${OUT}/paths"

echo "==> Importing whyred metadata from ${SRC}"

# Defconfig
if [[ -f "${SRC}/arch/arm64/configs/vendor/whyred-perf_defconfig" ]]; then
  cp -a "${SRC}/arch/arm64/configs/vendor/whyred-perf_defconfig" \
        "${OUT}/defconfig/"
  echo "OK defconfig whyred-perf_defconfig"
fi
if [[ -f "${SRC}/arch/arm64/configs/vendor/sdm660-perf_defconfig" ]]; then
  cp -a "${SRC}/arch/arm64/configs/vendor/sdm660-perf_defconfig" \
        "${OUT}/defconfig/"
fi

# Find whyred / sdm660 DTS references
{
  echo "# whyred / sdm660 related paths (relative to kernel root)"
  echo "# generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# commit $(git -C "${SRC}" rev-parse HEAD)"
  echo
  (cd "${SRC}" && find arch/arm64/boot/dts -iname '*whyred*' 2>/dev/null) || true
  (cd "${SRC}" && find arch/arm64/boot/dts -iname '*sdm660*' 2>/dev/null | head -n 80) || true
  (cd "${SRC}" && find arch/arm64/boot/dts -iname '*sdm636*' 2>/dev/null) || true
} > "${OUT}/dts-list/whyred-dts-paths.txt"

# techpack / audio / display hints
{
  echo "# Common SDM660 Android 4.19 subtrees"
  for p in \
    techpack \
    drivers/input/touchscreen \
    drivers/gpu/drm \
    drivers/media \
    drivers/bluetooth \
    drivers/net/wireless \
    drivers/power/supply \
    drivers/fingerprint \
    arch/arm64/configs/vendor
  do
    if [[ -e "${SRC}/${p}" ]]; then
      echo "PRESENT  ${p}"
    else
      echo "MISSING  ${p}"
    fi
  done
} > "${OUT}/paths/subtrees.txt"

# Full file list for whyred-named files
(cd "${SRC}" && find . -iname '*whyred*' 2>/dev/null | head -n 500) \
  > "${OUT}/paths/files-named-whyred.txt" || true

# Manifest
{
  echo "Whyred 4.19 import snapshot"
  echo "remote=$(git -C "${SRC}" remote get-url origin 2>/dev/null || echo unknown)"
  echo "branch=$(git -C "${SRC}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  echo "commit=$(git -C "${SRC}" rev-parse HEAD)"
  echo "defconfig=${KERNEL_419_DEFCONFIG}"
  echo "kernel_version=$(make -C "${SRC}" -s kernelversion 2>/dev/null || echo 4.19.x)"
  echo
  echo "NOTE: Full kernel sources remain in ${KERNEL_419_DIR}"
  echo "      This directory only stores defconfig + inventories."
  echo "      Building uses the full tree via scripts/build.sh"
} > "${MANIFEST}"

# Copy defconfig into project configs for reference
mkdir -p "${ROOT}/configs/imported"
cp -a "${OUT}/defconfig/"* "${ROOT}/configs/imported/" 2>/dev/null || true

echo "==> Snapshot written to ${OUT}"
echo "    ${MANIFEST}"
cat "${MANIFEST}"
echo ""
echo "whyred-named files (sample):"
head -n 30 "${OUT}/paths/files-named-whyred.txt" 2>/dev/null || true
