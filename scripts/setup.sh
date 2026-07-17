#!/usr/bin/env bash
# Setup kernel sources — default: Hybrid 6.18 LTS (android17-6.18)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"
# shellcheck source=/dev/null
source "${ROOT}/scripts/ci-env.sh"

mkdir -p "${ROOT}/${SRC_DIR}"
cd "${ROOT}"

echo "==> Whyred Hybrid setup"
echo "    KERNEL_TRACK=${KERNEL_TRACK}"
echo "    Device=${DEVICE_CODENAME} (${SOC})"
ci_free_disk

if ci_is_github; then
  SKIP_SDM660="${SKIP_SDM660:-1}"
  FETCH_LTS="${FETCH_LTS:-0}"
  export GIT_HTTP_LOW_SPEED_LIMIT=1000
  export GIT_HTTP_LOW_SPEED_TIME=60
fi

setup_618() {
  local dest="${ROOT}/${GKI_SRC}"
  echo "==> Hybrid 6.18 LTS base: Android ACK ${GKI_BRANCH_REF}"
  echo "    ${GKI_REMOTE}"

  if [[ ! -d "${dest}/.git" && ! -f "${dest}/Makefile" ]]; then
    mkdir -p "$(dirname "${dest}")"
    if ! ci_git_clone "${GKI_REMOTE}" "${dest}" "${GKI_BRANCH_REF}"; then
      echo "ERROR: failed to clone android17-6.18 (GKI / ACK)"
      echo "Hint: set GKI_REMOTE to a mirror if googlesource is slow"
      exit 1
    fi
  else
    echo "==> GKI tree present — updating..."
    git -C "${dest}" fetch --depth 1 origin "${GKI_BRANCH_REF}" || true
    git -C "${dest}" checkout -B "${GKI_BRANCH_REF}" FETCH_HEAD 2>/dev/null || true
  fi

  # Optional pure LTS 6.18.y for cherry-picks
  if [[ "${FETCH_LTS}" == "1" ]]; then
    local lts="${ROOT}/${LTS_DIR}"
    if [[ ! -d "${lts}/.git" ]]; then
      echo "==> Cloning kernel.org LTS ${LTS_BRANCH}..."
      ci_git_clone "${LTS_REMOTE}" "${lts}" "${LTS_BRANCH}" || \
        echo "WARNING: LTS clone failed (optional)"
    fi
  fi

  # Optional sdm660-mainline reference
  if [[ "${SKIP_SDM660}" != "1" ]]; then
    local sdm="${ROOT}/${SDM660_DIR}"
    if [[ ! -d "${sdm}/.git" ]]; then
      echo "==> Cloning sdm660-mainline reference..."
      ci_git_clone "${SDM660_REMOTE}" "${sdm}" "${SDM660_BRANCH}" || \
        echo "WARNING: sdm660-mainline clone failed"
    fi
  else
    echo "==> SKIP_SDM660=1"
  fi

  echo "==> Overlaying hybrid whyred files into GKI tree..."
  mkdir -p "${dest}/arch/arm64/boot/dts/qcom" \
           "${dest}/arch/arm64/configs" \
           "${dest}/drivers/whyred" \
           "${dest}/include/dt-bindings/whyred" \
           "${dest}/kernel/configs/whyred-hybrid"

  # Device tree (all whyred fragments)
  cp -a "${ROOT}/arch/arm64/boot/dts/qcom/"*.dts \
        "${ROOT}/arch/arm64/boot/dts/qcom/"*.dtsi \
        "${dest}/arch/arm64/boot/dts/qcom/" 2>/dev/null || true
  # Do not overwrite entire qcom/Makefile — append dtb line only (below)
  cp -a "${ROOT}/arch/arm64/configs/"* "${dest}/arch/arm64/configs/" 2>/dev/null || true

  # Drivers (rsync-like recursive)
  rm -rf "${dest}/drivers/whyred"
  mkdir -p "${dest}/drivers/whyred"
  cp -a "${ROOT}/drivers/whyred/." "${dest}/drivers/whyred/"

  mkdir -p "${dest}/include/dt-bindings/whyred"
  cp -a "${ROOT}/include/dt-bindings/whyred/"* "${dest}/include/dt-bindings/whyred/" 2>/dev/null || true
  # fragments + bringup subdir
  mkdir -p "${dest}/kernel/configs/whyred-hybrid/bringup"
  cp -a "${ROOT}/configs/fragments/"*.config \
        "${dest}/kernel/configs/whyred-hybrid/" 2>/dev/null || true
  cp -a "${ROOT}/configs/fragments/bringup/"*.config \
        "${dest}/kernel/configs/whyred-hybrid/bringup/" 2>/dev/null || true

  # Wire drivers/whyred into kernel build system
  if [[ -f "${dest}/drivers/Kconfig" ]] && ! grep -q 'whyred/Kconfig' "${dest}/drivers/Kconfig"; then
    echo 'source "drivers/whyred/Kconfig"' >> "${dest}/drivers/Kconfig"
  fi
  if [[ -f "${dest}/drivers/Makefile" ]] && ! grep -q 'drivers/whyred' "${dest}/drivers/Makefile" && ! grep -q 'whyred/' "${dest}/drivers/Makefile"; then
    echo 'obj-y += whyred/' >> "${dest}/drivers/Makefile"
  fi

  # Ensure DTB is listed
  if [[ -f "${dest}/arch/arm64/boot/dts/qcom/Makefile" ]] && \
     ! grep -q 'sdm636-xiaomi-whyred' "${dest}/arch/arm64/boot/dts/qcom/Makefile"; then
    echo 'dtb-$(CONFIG_ARCH_QCOM) += sdm636-xiaomi-whyred.dtb' \
      >> "${dest}/arch/arm64/boot/dts/qcom/Makefile"
  fi

  # Provenance lock
  mkdir -p "${ROOT}/vendor/import"
  {
    echo "track=6.18-hybrid-lts"
    echo "gki_remote=${GKI_REMOTE}"
    echo "gki_branch=${GKI_BRANCH_REF}"
    echo "gki_commit=$(git -C "${dest}" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "android_release=${ANDROID_RELEASE}"
    echo "lts_series=6.18"
    echo "date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "${ROOT}/vendor/import/kernel-6.18-hybrid.lock"

  local ver
  ver="$(make -C "${dest}" -s kernelversion 2>/dev/null || echo 6.18.x)"
  echo "==> Kernel version string: ${ver}"
  echo "==> Hybrid 6.18 LTS sources ready: ${dest}"
}

setup_419() {
  local dest="${ROOT}/${KERNEL_419_DIR}"
  echo "==> Downstream 4.19 (optional ROM track)"
  if [[ ! -d "${dest}/.git" && ! -f "${dest}/Makefile" ]]; then
    mkdir -p "$(dirname "${dest}")"
    ci_git_clone "${KERNEL_419_REMOTE}" "${dest}" "${KERNEL_419_BRANCH}" || exit 1
  fi
  echo "==> 4.19 ready: ${dest}"
}

case "${KERNEL_TRACK}" in
  4.19|419|downstream)
    setup_419
    ;;
  6.18|618|gki|hybrid|lts|*)
    setup_618
    ;;
esac

if command -v clang >/dev/null 2>&1; then
  echo "==> clang: $(clang --version | head -n1)"
else
  echo "WARNING: clang not in PATH — install clang/lld for build"
fi

echo ""
echo "Next (hybrid 6.18 LTS):"
echo "  ./scripts/apply-patches.sh"
echo "  ./scripts/build.sh whyred"
echo "  FETCH_ANYKERNEL=1 ./scripts/pack.sh"
ci_free_disk
