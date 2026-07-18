#!/usr/bin/env bash
# Validate build output — run after build.sh to verify artifacts
# Fails the pipeline if critical checks fail
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"

DIST="${ROOT}/${DIST_DIR}"
ERR=0

echo "==> Validating build artifacts in ${DIST}"

if [[ ! -d "${DIST}" ]]; then
  echo "ERROR: dist directory not found: ${DIST}"
  exit 1
fi

# --- Kernel image ---
echo ""
echo "==> Kernel image"
FOUND_IMAGE=0
for img in Image.gz Image Image.gz-dtb; do
  if [[ -f "${DIST}/${img}" ]]; then
    SIZE=$(stat -c%s "${DIST}/${img}" 2>/dev/null || stat -f%z "${DIST}/${img}" 2>/dev/null || echo 0)
    echo "  OK  ${img} (${SIZE} bytes)"

    # Verify architecture (ELF magic or gzip)
    if file "${DIST}/${img}" 2>/dev/null | grep -qi 'aarch64\|ARM aarch64'; then
      echo "  OK  architecture: aarch64"
    elif file "${DIST}/${img}" 2>/dev/null | grep -qi 'gzip'; then
      echo "  OK  format: gzip compressed"
    fi

    # Verify size is reasonable (1MB < size < 200MB)
    if [[ ${SIZE} -lt 1048576 ]]; then
      echo "  WARN  image suspiciously small (${SIZE} bytes)"
    elif [[ ${SIZE} -gt 209715200 ]]; then
      echo "  WARN  image suspiciously large (${SIZE} bytes)"
    fi

    FOUND_IMAGE=1
    break
  fi
done

if [[ ${FOUND_IMAGE} -eq 0 ]]; then
  echo "  ERROR  no kernel image found (Image.gz / Image / Image.gz-dtb)"
  ERR=$((ERR + 1))
fi

# --- DTBs ---
echo ""
echo "==> Device Tree Blobs"
DTB_COUNT=0
for dtb in "${DIST}"/*.dtb; do
  if [[ -f "${dtb}" ]]; then
    DTB_COUNT=$((DTB_COUNT + 1))
    DNAME=$(basename "${dtb}")

    # Verify FDT magic
    if file "${dtb}" 2>/dev/null | grep -qi 'device tree\|FDT'; then
      echo "  OK  ${DNAME} (valid FDT)"
    else
      echo "  WARN  ${DNAME} — may not be valid FDT"
    fi

    # Check for whyred in name
    if echo "${DNAME}" | grep -qi 'whyred\|sdm636'; then
      echo "  OK  ${DNAME} matches target device"
    fi
  fi
done
echo "  Total DTBs: ${DTB_COUNT}"

# --- Config ---
echo ""
echo "==> Config"
if [[ -f "${DIST}/config" ]]; then
  echo "  OK  config present ($(wc -l < "${DIST}/config") lines)"

  # Quick architecture check
  if grep -q "CONFIG_64BIT=y" "${DIST}/config" 2>/dev/null; then
    echo "  OK  CONFIG_64BIT=y (ARM64)"
  else
    echo "  WARN  CONFIG_64BIT not set"
  fi

  # Check whyred-specific
  if grep -q "CONFIG_WHYRED_DRIVERS=y" "${DIST}/config" 2>/dev/null; then
    echo "  OK  CONFIG_WHYRED_DRIVERS=y"
  fi
else
  echo "  WARN  config not found in dist"
fi

# --- Build info ---
echo ""
echo "==> Build metadata"
if [[ -f "${DIST}/build-info.txt" ]]; then
  echo "  OK  build-info.txt present"
  # Show key fields
  grep -E '^(gki_commit|kernel_version|config_hash|timestamp)' "${DIST}/build-info.txt" 2>/dev/null | while read -r line; do
    echo "    ${line}"
  done
else
  echo "  WARN  build-info.txt not found"
fi

if [[ -f "${DIST}/SHA256SUMS" ]]; then
  echo "  OK  SHA256SUMS present"
else
  echo "  WARN  SHA256SUMS not found"
fi

# --- Modules ---
echo ""
echo "==> Modules"
MODULES_DIR="${ROOT}/${MODULES_OUT}/lib/modules"
if [[ -d "${MODULES_DIR}" ]]; then
  MOD_COUNT=$(find "${MODULES_DIR}" -name '*.ko' 2>/dev/null | wc -l | tr -d ' ')
  echo "  OK  modules directory present (${MOD_COUNT} .ko files)"
else
  echo "  INFO  modules not built (SKIP_MODULES=1 or image mode)"
fi

# --- Zip ---
echo ""
echo "==> Flashable zip"
ZIP_COUNT=$(find "${DIST}" -maxdepth 1 -name '*.zip' 2>/dev/null | wc -l | tr -d ' ')
if [[ ${ZIP_COUNT} -gt 0 ]]; then
  for z in "${DIST}"/*.zip; do
    [[ -f "${z}" ]] || continue
    ZSIZE=$(stat -c%s "${z}" 2>/dev/null || stat -f%z "${z}" 2>/dev/null || echo 0)
    echo "  OK  $(basename "${z}") (${ZSIZE} bytes)"
  done
else
  echo "  INFO  no zip (pack.sh not run yet)"
fi

# --- Summary ---
echo ""
echo "========================================="
if [[ ${ERR} -gt 0 ]]; then
  echo "BUILD VALIDATION FAILED — ${ERR} error(s)"
  exit 1
fi
echo "BUILD VALIDATION PASSED"
