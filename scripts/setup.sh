#!/usr/bin/env bash
# Setup kernel sources — handles 7.0 direct tree, 6.18 mainline overlay, 4.19 downstream
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"
# shellcheck source=/dev/null
source "${ROOT}/scripts/ci-env.sh"

cd "${ROOT}"

echo "==> Phoenix-Whyred setup"
echo "    KERNEL_TRACK=${KERNEL_TRACK}"
echo "    Device=${DEVICE_CODENAME} (${SOC})"
ci_free_disk

if ci_is_github; then
  FETCH_LTS="${FETCH_LTS:-0}"
  export GIT_HTTP_LOW_SPEED_LIMIT=1000
  export GIT_HTTP_LOW_SPEED_TIME=60
fi

# ---------- 7.0 direct (repo IS the kernel tree) ----------
setup_70() {
  echo "==> sdm660-mainline 7.0.y — repo is the kernel tree"
  if [[ ! -f "${ROOT}/Makefile" ]]; then
    echo "ERROR: Makefile not found at ${ROOT}"
    echo "This track expects the repo to contain the full kernel tree."
    exit 1
  fi
  local ver
  ver="$(make -C "${ROOT}" -s kernelversion 2>/dev/null || echo unknown)"
  echo "    Kernel version: ${ver}"
  echo "==> Source tree ready: ${ROOT}"
}

# ---------- Mainline 6.18 LTS (clone + overlay) ----------
setup_618() {
  local dest="${ROOT}/${SRC_DIR}"
  echo "==> Linux Mainline 6.18 LTS base"
  echo "    ${GKI_REMOTE}"

  if [[ ! -d "${dest}/.git" && ! -f "${dest}/Makefile" ]]; then
    mkdir -p "$(dirname "${dest}")"
    echo "==> Cloning Linux Mainline 6.18 LTS..."
    if ! git clone --depth 1 --branch "${GKI_BRANCH_REF}" "${GKI_REMOTE}" "${dest}"; then
      echo "ERROR: failed to clone Linux Mainline 6.18 LTS"
      echo "Hint: set GKI_REMOTE to a mirror if kernel.org is slow"
      exit 1
    fi
  else
    echo "==> Mainline tree present — updating..."
    git -C "${dest}" fetch --depth 1 origin "${GKI_BRANCH_REF}" || true
    git -C "${dest}" checkout -B "${GKI_BRANCH_REF}" FETCH_HEAD 2>/dev/null || true
  fi

  if [[ -n "${GKI_COMMIT:-}" && "${GKI_COMMIT}" != "HEAD" ]]; then
    echo "==> Pinning to GKI_COMMIT=${GKI_COMMIT}"
    if git -C "${dest}" cat-file -t "${GKI_COMMIT}" >/dev/null 2>&1; then
      git -C "${dest}" checkout "${GKI_COMMIT}" 2>/dev/null || \
        echo "WARNING: could not checkout ${GKI_COMMIT} — using branch HEAD"
    else
      echo "WARNING: GKI_COMMIT ${GKI_COMMIT} not found in repo — using branch HEAD"
    fi
  fi

  echo "==> Overlaying whyred files into mainline tree..."
  mkdir -p "${dest}/arch/arm64/boot/dts/qcom" \
           "${dest}/arch/arm64/configs" \
           "${dest}/drivers/whyred" \
           "${dest}/include/dt-bindings/whyred"

  cp -a "${ROOT}/arch/arm64/boot/dts/qcom/"*.dts \
        "${ROOT}/arch/arm64/boot/dts/qcom/"*.dtsi \
        "${dest}/arch/arm64/boot/dts/qcom/" 2>/dev/null || true
  cp -a "${ROOT}/arch/arm64/configs/"* "${dest}/arch/arm64/configs/" 2>/dev/null || true
  mkdir -p "${dest}/drivers/whyred"
  cp -a "${ROOT}/drivers/whyred/." "${dest}/drivers/whyred/"
  mkdir -p "${dest}/include/dt-bindings/whyred"
  cp -a "${ROOT}/include/dt-bindings/whyred/"* "${dest}/include/dt-bindings/whyred/" 2>/dev/null || true

  if [[ -f "${dest}/drivers/Kconfig" ]] && ! grep -q 'whyred/Kconfig' "${dest}/drivers/Kconfig"; then
    echo 'source "drivers/whyred/Kconfig"' >> "${dest}/drivers/Kconfig"
  fi
  if [[ -f "${dest}/drivers/Makefile" ]] && ! grep -q 'whyred/' "${dest}/drivers/Makefile"; then
    echo 'obj-y += whyred/' >> "${dest}/drivers/Makefile"
  fi
  if [[ -f "${dest}/arch/arm64/boot/dts/qcom/Makefile" ]] && \
     ! grep -q 'sdm636-xiaomi-whyred' "${dest}/arch/arm64/boot/dts/qcom/Makefile"; then
    echo 'dtb-$(CONFIG_ARCH_QCOM) += sdm636-xiaomi-whyred.dtb' \
      >> "${dest}/arch/arm64/boot/dts/qcom/Makefile"
  fi

  local ver
  ver="$(make -C "${dest}" -s kernelversion 2>/dev/null || echo 6.18.x)"
  echo "==> Kernel version string: ${ver}"
  echo "==> Linux Mainline 6.18 LTS sources ready: ${dest}"
}

# ---------- 4.19 downstream ----------
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
  7.0|70|sdm660|mainline-sdm660)
    setup_70
    ;;
  4.19|419|downstream)
    setup_419
    ;;
  6.18|618|lts|mainline|hybrid)
    setup_618
    ;;
  *)
    echo "WARNING: unknown KERNEL_TRACK=${KERNEL_TRACK}, defaulting to 7.0"
    setup_70
    ;;
esac

if command -v clang >/dev/null 2>&1; then
  echo "==> clang: $(clang --version | head -n1)"
else
  echo "WARNING: clang not in PATH — install clang/lld for build"
fi

echo ""
echo "Next:"
echo "  ./scripts/build.sh whyred"
echo "  ./scripts/pack.sh"
ci_free_disk
