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

# ---------- 7.0 sdm660-mainline (clone + overlay) ----------
setup_70() {
  local dest="${ROOT}/${KERNEL_SRC}"
  echo "==> sdm660-mainline 7.0.y"
  echo "    Remote: ${GKI_REMOTE}"
  echo "    Branch: ${GKI_BRANCH_REF}"

  if [[ ! -d "${dest}/.git" && ! -f "${dest}/Makefile" ]]; then
    mkdir -p "$(dirname "${dest}")"
    echo "==> Cloning sdm660-mainline 7.0.y..."
    if ! git clone --depth 1 --branch "${GKI_BRANCH_REF}" "${GKI_REMOTE}" "${dest}"; then
      echo "ERROR: failed to clone ${GKI_REMOTE}"
      exit 1
    fi
  else
    echo "==> Kernel tree present — updating..."
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

  echo "==> Overlaying whyred files into sdm660-mainline tree..."
  mkdir -p "${dest}/arch/arm64/boot/dts/qcom" \
           "${dest}/arch/arm64/configs" \
           "${dest}/include/dt-bindings/whyred"

  # Device tree
  cp -a "${ROOT}/arch/arm64/boot/dts/qcom/"*.dts \
        "${ROOT}/arch/arm64/boot/dts/qcom/"*.dtsi \
        "${dest}/arch/arm64/boot/dts/qcom/" 2>/dev/null || true

  # Configs
  cp -a "${ROOT}/arch/arm64/configs/"* "${dest}/arch/arm64/configs/" 2>/dev/null || true

  # DT bindings
  mkdir -p "${dest}/include/dt-bindings/whyred"
  cp -a "${ROOT}/include/dt-bindings/whyred/"* "${dest}/include/dt-bindings/whyred/" 2>/dev/null || true

  # Ensure DTB is listed in DTS Makefile
  if [[ -f "${dest}/arch/arm64/boot/dts/qcom/Makefile" ]] && \
     ! grep -q 'sdm636-xiaomi-whyred' "${dest}/arch/arm64/boot/dts/qcom/Makefile"; then
    echo 'dtb-$(CONFIG_ARCH_QCOM) += sdm636-xiaomi-whyred.dtb' \
      >> "${dest}/arch/arm64/boot/dts/qcom/Makefile"
  fi

  local ver
  ver="$(make -C "${dest}" -s kernelversion 2>/dev/null || echo unknown)"
  echo "==> Kernel version: ${ver}"
  echo "==> sdm660-mainline 7.0.y ready: ${dest}"
}

# ---------- 4.19 downstream ----------
setup_419() {
  local dest="${ROOT}/${KERNEL_419_DIR}"
  echo "==> Downstream 4.19 (optional ROM track)"
  if [[ ! -d "${dest}/.git" && ! -f "${dest}/Makefile" ]]; then
    mkdir -p "$(dirname "${dest}")"
    if [[ -n "${KERNEL_419_REMOTE}" ]]; then
      ci_git_clone "${KERNEL_419_REMOTE}" "${dest}" "${KERNEL_419_BRANCH}" || exit 1
    else
      echo "ERROR: KERNEL_419_REMOTE not set — cannot clone 4.19 tree"
      exit 1
    fi
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
