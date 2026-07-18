#!/usr/bin/env bash
# Build Whyred Hybrid 6.18 LTS (default) or Downstream 4.19
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"
# shellcheck source=/dev/null
source "${ROOT}/scripts/ci-env.sh"

MODE="${1:-whyred}"
COMMON="${ROOT}/${KERNEL_SRC}"
# BUILD_DIR from conf is relative "out/build"
BDIR="${ROOT}/${BUILD_DIR}"
SKIP_MODULES="${SKIP_MODULES:-0}"
CONTINUE_ON_ERROR="${CONTINUE_ON_ERROR:-0}"
# Gradual bring-up: 1=UART … 5=touch (see docs/BRINGUP.md)
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

# Pass stage into DT C preprocessor (not dtc binary flags)
DTC_CPP_FLAGS_EXTRA="-DWHYRED_BRINGUP_STAGE=${BRINGUP_STAGE}"

MAKE=(make -C "${COMMON}" O="${BDIR}" ARCH="${ARCH}" \
  LOCALVERSION="${LOCALVERSION}" \
  DTC_CPP_FLAGS="${DTC_CPP_FLAGS:-} ${DTC_CPP_FLAGS_EXTRA}" \
  -j"${JOBS}")

if command -v clang >/dev/null 2>&1; then
  MAKE+=(CC=clang CLANG_TRIPLE=aarch64-linux-gnu-)
  if [[ "${LLVM}" == "1" ]]; then
    MAKE+=(LLVM=1)
    if [[ "${KERNEL_TRACK}" == "6.18" || "${LLVM_IAS:-1}" == "1" ]]; then
      [[ "${KERNEL_TRACK}" == "6.18" ]] && MAKE+=(LLVM_IAS=1)
    fi
  fi
fi

# ---------- Hybrid 6.18 LTS ----------
config_618() {
  echo "==> [6.18 LTS Hybrid] ${BASE_DEFCONFIG} + fragments"
  if [[ -f "${COMMON}/arch/arm64/configs/gki_defconfig" ]]; then
    "${MAKE[@]}" gki_defconfig
  elif [[ -f "${COMMON}/arch/arm64/configs/whyred_hybrid_defconfig" ]]; then
    "${MAKE[@]}" whyred_hybrid_defconfig
  else
    "${MAKE[@]}" defconfig
  fi

  local frags=(
    "${ROOT}/${FRAGMENT_ANDROID}"
    "${ROOT}/${FRAGMENT_SDM660}"
    "${ROOT}/${FRAGMENT_WHYRED}"
    "${ROOT}/${FRAGMENT_HYBRID}"
    "${ROOT}/${FRAGMENT_LTS}"
  )

  # Cumulative bring-up Kconfig hints (1..BRINGUP_STAGE)
  local s stage_frags=(
    "${ROOT}/configs/fragments/bringup/stage1-uart.config"
    "${ROOT}/configs/fragments/bringup/stage2-mmc.config"
    "${ROOT}/configs/fragments/bringup/stage3-usb.config"
    "${ROOT}/configs/fragments/bringup/stage4-display.config"
    "${ROOT}/configs/fragments/bringup/stage5-touch.config"
  )
  echo "    BRINGUP_STAGE=${BRINGUP_STAGE} (UART→MMC→USB→display→touch)"
  for ((s = 1; s <= BRINGUP_STAGE && s <= ${#stage_frags[@]}; s++)); do
    frags+=("${stage_frags[$((s - 1))]}")
  done

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
  # Record uname-style localversion intent
  {
    echo "CONFIG_LOCALVERSION=\"${LOCALVERSION}\""
    echo "BRINGUP_STAGE=${BRINGUP_STAGE}"
  } >> "${ROOT}/${DIST_DIR}/localversion.txt" || true
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

build_618() {
  echo "==> [6.18 LTS Hybrid] Building Image.gz (jobs=${JOBS})..."
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

  # DTBs (best-effort; whyred DT may need full SoC includes)
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

  # Build stamp — comprehensive provenance
  local _clang_ver _ld_ver _llvm_ver _pahole_ver _as_ver _gcc_ver _config_hash
  _clang_ver="$(clang --version 2>/dev/null | head -n1 || echo unknown)"
  _ld_ver="$(ld.lld --version 2>/dev/null | head -n1 || echo unknown)"
  _llvm_ver="$(llvm-ar --version 2>/dev/null | head -n1 || echo unknown)"
  _pahole_ver="$(pahole --version 2>/dev/null | head -n1 || echo unknown)"
  _as_ver="$(clang --version 2>/dev/null | grep -i 'LLVM' | head -n1 || echo unknown)"
  _gcc_ver="$(gcc --version 2>/dev/null | head -n1 || echo unknown)"
  _config_hash="$(sha256sum "${BDIR}/.config" 2>/dev/null | cut -d' ' -f1 || echo unknown)"
  {
    echo "=== Build Provenance ==="
    echo "project=${PROJECT_NAME}"
    echo "version=${PROJECT_VERSION}"
    echo "track=6.18-hybrid-lts"
    echo "kernel_version=$(make -C "${COMMON}" O="${BDIR}" -s kernelrelease 2>/dev/null || echo unknown)"
    echo ""
    echo "=== Source ==="
    echo "gki_remote=${GKI_REMOTE}"
    echo "gki_branch=${GKI_BRANCH_REF}"
    echo "gki_commit_pinned=${GKI_COMMIT:-HEAD}"
    echo "gki_commit_actual=$(git -C "${COMMON}" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "project_commit=$(git -C "${ROOT}" rev-parse HEAD 2>/dev/null || echo local)"
    echo ""
    echo "=== Toolchain ==="
    echo "clang=${_clang_ver}"
    echo "linker=${_ld_ver}"
    echo "llvm=${_llvm_ver}"
    echo "assembler=${_as_ver}"
    echo "gcc=${_gcc_ver}"
    echo "pahole=${_pahole_ver}"
    echo ""
    echo "=== Build ==="
    echo "host=$(uname -n 2>/dev/null || echo unknown)"
    echo "arch=${ARCH}"
    echo "defconfig=${BASE_DEFCONFIG}"
    echo "bringup_stage=${BRINGUP_STAGE}"
    echo "localversion=${LOCALVERSION}"
    echo "jobs=${JOBS}"
    echo "llvm=${LLVM}"
    echo "llvm_ias=${LLVM_IAS}"
    echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    echo "=== Config ==="
    echo "config_hash=${_config_hash}"
    echo "config_fragments=$(for f in "${frags[@]}"; do basename "$f"; done | tr '\n' ' ')"
  } > "${ROOT}/${DIST_DIR}/build-info.txt"

  # SHA256SUMS for all artifacts
  (
    cd "${ROOT}/${DIST_DIR}"
    sha256sum Image* *.dtb 2>/dev/null || true
    sha256sum config 2>/dev/null || true
  ) > "${ROOT}/${DIST_DIR}/SHA256SUMS" 2>/dev/null || true

  echo "==> Hybrid 6.18 LTS build finished (BRINGUP_STAGE=${BRINGUP_STAGE})"
}

# ---------- 4.19 ----------
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
    if [[ "${KERNEL_TRACK}" == "4.19" ]]; then config_419; else config_618; fi
    ;;
  image)
    SKIP_MODULES=1
    if [[ "${KERNEL_TRACK}" == "4.19" ]]; then config_419; build_419; else config_618; build_618; fi
    ;;
  whyred|all|build|full|modules)
    if [[ "${KERNEL_TRACK}" == "4.19" ]]; then config_419; build_419; else config_618; build_618; fi
    ;;
  *)
    echo "Usage: BRINGUP_STAGE=1..5 $0 [config|image|whyred]"
    echo "  BRINGUP_STAGE: 1=UART 2=+MMC 3=+USB 4=+display 5=+touch (default 5)"
    exit 1
    ;;
esac

echo "Artifacts:"
ls -la "${ROOT}/${DIST_DIR}" 2>/dev/null || true
