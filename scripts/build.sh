#!/usr/bin/env bash
# Build Phoenix-Whyred 7.0 (default) or Downstream 4.19
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"
# shellcheck source=/dev/null
source "${ROOT}/scripts/ci-env.sh"

MODE="${1:-whyred}"
COMMON="${ROOT}/${KERNEL_SRC}"
BDIR="${ROOT}/${BUILD_DIR}"
SKIP_MODULES="${SKIP_MODULES:-0}"
CONTINUE_ON_ERROR="${CONTINUE_ON_ERROR:-0}"
BRINGUP_STAGE="${BRINGUP_STAGE:-5}"

if ci_is_github; then
  JOBS="${JOBS:-$(ci_nproc)}"
fi

if [[ ! -f "${COMMON}/Makefile" ]]; then
  echo "ERROR: kernel tree missing at ${COMMON}"
  echo "Run: KERNEL_TRACK=${KERNEL_TRACK} ./scripts/setup.sh"
  exit 1
fi

mkdir -p "${BDIR}" "${ROOT}/${DIST_DIR}" "${ROOT}/${MODULES_OUT}" "${ROOT}/${OUT_DIR}"

export ARCH="${ARCH}"
export SUBARCH="${SUBARCH}"
export CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
export LLVM="${LLVM:-1}"
export LLVM_IAS="${LLVM_IAS:-1}"

DTC_CPP_FLAGS_EXTRA="-DWHYRED_BRINGUP_STAGE=${BRINGUP_STAGE}"

MAKE=(make -C "${COMMON}" O="${BDIR}" ARCH="${ARCH}" \
  LOCALVERSION="${LOCALVERSION}" \
  DTC_CPP_FLAGS="${DTC_CPP_FLAGS:-} ${DTC_CPP_FLAGS_EXTRA}" \
  -j"${JOBS}")

if command -v clang >/dev/null 2>&1; then
  MAKE+=(CC=clang CLANG_TRIPLE=aarch64-linux-gnu-)
  if [[ "${LLVM}" == "1" ]]; then
    MAKE+=(LLVM=1)
    if [[ "${LLVM_IAS:-1}" == "1" ]]; then
      MAKE+=(LLVM_IAS=1)
    fi
  fi
fi

config_70() {
  echo "==> [7.0 sdm660-mainline] ${BASE_DEFCONFIG} + fragments"
  if [[ -f "${COMMON}/arch/arm64/configs/${BASE_DEFCONFIG}" ]]; then
    "${MAKE[@]}" "${BASE_DEFCONFIG}"
  else
    "${MAKE[@]}" defconfig
  fi

  local frags=()
  [[ -f "${ROOT}/${FRAGMENT_SDM660}" ]] && frags+=("${ROOT}/${FRAGMENT_SDM660}")
  [[ -f "${ROOT}/${FRAGMENT_WHYRED}" ]] && frags+=("${ROOT}/${FRAGMENT_WHYRED}")

  if [[ -f "${ROOT}/${FRAGMENT_ANDROID}" ]]; then
    frags+=("${ROOT}/${FRAGMENT_ANDROID}")
  fi

  for ((s = 1; s <= BRINGUP_STAGE && s <= 5; s++)); do
    local sf="${ROOT}/configs/fragments/bringup/stage${s}-*.config"
    for f in $sf; do
      [[ -f "$f" ]] && frags+=("$f")
    done
  done
  echo "    BRINGUP_STAGE=${BRINGUP_STAGE} (UART->MMC->USB->display->touch)"

  for f in "${frags[@]}"; do
    [[ -f "$f" ]] || continue
    echo "    merge $(basename "$f")"
    if [[ -f "${COMMON}/scripts/kconfig/merge_config.sh" ]]; then
      bash "${COMMON}/scripts/kconfig/merge_config.sh" -m -O "${BDIR}" \
        "${BDIR}/.config" "$f"
    else
      cat "$f" >> "${BDIR}/.config"
    fi
  done
  "${MAKE[@]}" olddefconfig
  cp -a "${BDIR}/.config" "${ROOT}/${DIST_DIR}/config" || true
  {
    echo "CONFIG_LOCALVERSION=\"${LOCALVERSION}\""
    echo "BRINGUP_STAGE=${BRINGUP_STAGE}"
  } >> "${ROOT}/${DIST_DIR}/localversion.txt" || true
}

config_618() {
  echo "==> [6.18 LTS Mainline] ${BASE_DEFCONFIG} + fragments"
  config_70
}

collect_images() {
  local found=0 img
  for img in Image.gz Image Image.gz-dtb; do
    if [[ -f "${BDIR}/arch/arm64/boot/${img}" ]]; then
      cp -a "${BDIR}/arch/arm64/boot/${img}" "${ROOT}/${DIST_DIR}/"
      echo "    -> out/dist/${img}"
      found=1
    fi
  done
  find "${BDIR}/arch/arm64/boot/dts" \( -name '*whyred*.dtb' -o -name 'sdm636*.dtb' -o -name 'sdm660*.dtb' \) \
    -exec cp -a {} "${ROOT}/${DIST_DIR}/" \; 2>/dev/null || true
  [[ $found -eq 1 ]]
}

build_image() {
  local label="${1:-7.0}"
  echo "==> [${label}] Building Image.gz (jobs=${JOBS})..."
  set +e
  "${MAKE[@]}" Image.gz 2>&1 | tee "${ROOT}/${OUT_DIR}/build-image.log"
  local rc=${PIPESTATUS[0]}
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "Image.gz failed — trying Image..."
    set +e
    "${MAKE[@]}" Image 2>&1 | tee -a "${ROOT}/${OUT_DIR}/build-image.log"
    set -e
  fi

  if ! collect_images; then
    echo "ERROR: no kernel Image produced"
    tail -n 100 "${ROOT}/${OUT_DIR}/build-image.log" || true
    exit 1
  fi

  set +e
  "${MAKE[@]}" dtbs 2>&1 | tee "${ROOT}/${OUT_DIR}/build-dtbs.log"
  set -e
  collect_images || true

  if [[ "${SKIP_MODULES}" != "1" ]]; then
    echo "==> Building modules..."
    set +e
    "${MAKE[@]}" modules 2>&1 | tee "${ROOT}/${OUT_DIR}/build-modules.log"
    local mrc=${PIPESTATUS[0]}
    set -e
    if [[ $mrc -ne 0 && "${CONTINUE_ON_ERROR}" != "1" ]]; then
      exit "$mrc"
    fi
    set +e
    "${MAKE[@]}" modules_install INSTALL_MOD_PATH="${ROOT}/${MODULES_OUT}" \
      2>&1 | tee "${ROOT}/${OUT_DIR}/modules-install.log"
    set -e
  fi

  local _clang_ver _ld_ver _gcc_ver _config_hash
  _clang_ver="$(clang --version 2>/dev/null | head -n1 || echo unknown)"
  _ld_ver="$(ld.lld --version 2>/dev/null | head -n1 || echo unknown)"
  _gcc_ver="$(gcc --version 2>/dev/null | head -n1 || echo unknown)"
  _config_hash="$(sha256sum "${BDIR}/.config" 2>/dev/null | cut -d' ' -f1 || echo unknown)"
  {
    echo "=== Build Provenance ==="
    echo "project=${PROJECT_NAME}"
    echo "version=${PROJECT_VERSION}"
    echo "track=${KERNEL_TRACK}"
    echo "kernel_version=$(make -C "${COMMON}" O="${BDIR}" -s kernelrelease 2>/dev/null || echo unknown)"
    echo ""
    echo "=== Source ==="
    echo "kernel_remote=${GKI_REMOTE}"
    echo "kernel_branch=${GKI_BRANCH_REF}"
    echo "kernel_commit_pinned=${GKI_COMMIT:-HEAD}"
    echo "kernel_commit_actual=$(git -C "${COMMON}" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "project_commit=$(git -C "${ROOT}" rev-parse HEAD 2>/dev/null || echo local)"
    echo ""
    echo "=== Toolchain ==="
    echo "clang=${_clang_ver}"
    echo "linker=${_ld_ver}"
    echo "gcc=${_gcc_ver}"
    echo ""
    echo "=== Build ==="
    echo "host=$(uname -n 2>/dev/null || echo unknown)"
    echo "arch=${ARCH}"
    echo "defconfig=${BASE_DEFCONFIG}"
    echo "bringup_stage=${BRINGUP_STAGE}"
    echo "localversion=${LOCALVERSION}"
    echo "jobs=${JOBS}"
    echo "llvm=${LLVM}"
    echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    echo "=== Config ==="
    echo "config_hash=${_config_hash}"
  } > "${ROOT}/${DIST_DIR}/build-info.txt"

  (
    cd "${ROOT}/${DIST_DIR}"
    sha256sum Image* 2>/dev/null || true
    sha256sum *.dtb 2>/dev/null || true
    sha256sum config 2>/dev/null || true
    [[ -f dtbo.img ]] && sha256sum dtbo.img 2>/dev/null || true
    [[ -f build-info.txt ]] && sha256sum build-info.txt 2>/dev/null || true
  ) > "${ROOT}/${DIST_DIR}/SHA256SUMS" 2>/dev/null || true

  echo "==> Build finished (BRINGUP_STAGE=${BRINGUP_STAGE})"
}

config_419() {
  echo "==> [4.19] ${KERNEL_419_DEFCONFIG}"
  "${MAKE[@]}" "${KERNEL_419_DEFCONFIG}"
  cp -a "${BDIR}/.config" "${ROOT}/${DIST_DIR}/config" || true
}

build_419() {
  echo "==> [4.19] Building..."
  set +e
  "${MAKE[@]}" Image.gz-dtb 2>&1 | tee "${ROOT}/${OUT_DIR}/build-image.log"
  local rc=${PIPESTATUS[0]}
  set -e
  [[ $rc -ne 0 ]] && "${MAKE[@]}" Image.gz 2>&1 | tee -a "${ROOT}/${OUT_DIR}/build-image.log"
  collect_images || { echo "ERROR: no image"; exit 1; }
  if [[ "${SKIP_MODULES}" != "1" ]]; then
    "${MAKE[@]}" modules modules_install INSTALL_MOD_PATH="${ROOT}/${MODULES_OUT}" || true
  fi
}

echo "==> Track=${KERNEL_TRACK} src=${COMMON} BRINGUP_STAGE=${BRINGUP_STAGE}"

case "${MODE}" in
  config)
    if [[ "${KERNEL_TRACK}" == "4.19" ]]; then config_419; else config_70; fi
    ;;
  image)
    SKIP_MODULES=1
    if [[ "${KERNEL_TRACK}" == "4.19" ]]; then config_419; build_419; else config_70; build_image "7.0"; fi
    ;;
  whyred|all|build|full|modules)
    if [[ "${KERNEL_TRACK}" == "4.19" ]]; then config_419; build_419; else config_70; build_image "7.0"; fi
    ;;
  *)
    echo "Usage: BRINGUP_STAGE=1..5 $0 [config|image|whyred]"
    echo "  BRINGUP_STAGE: 1=UART 2=+MMC 3=+USB 4=+display 5=+touch (default 5)"
    exit 1
    ;;
esac

echo "Artifacts:"
ls -la "${ROOT}/${DIST_DIR}" 2>/dev/null || true
