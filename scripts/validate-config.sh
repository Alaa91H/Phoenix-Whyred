#!/usr/bin/env bash
# Validate merged kernel configuration for whyred sdm660-mainline 7.0.9
# Run after build.sh config to verify critical options are set
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"

BDIR="${ROOT}/${BUILD_DIR}"
CONFIG="${BDIR}/.config"
DIST="${ROOT}/${DIST_DIR}"
ERR=0
WARN=0

if [[ ! -f "${CONFIG}" ]]; then
  echo "ERROR: .config not found at ${CONFIG}"
  echo "Run build.sh first"
  exit 1
fi

echo "==> Validating config: ${CONFIG}"
echo "    $(wc -l < "${CONFIG}") lines"

check_enabled() {
  local sym="$1"
  local reason="$2"
  if grep -qE "^${sym}=y" "${CONFIG}"; then
    echo "  OK  ${sym}=y  (${reason})"
  elif grep -qE "^${sym}=m" "${CONFIG}"; then
    echo "  OK  ${sym}=m  (${reason})"
  else
    echo "  MISSING  ${sym}  (${reason})"
    ERR=$((ERR + 1))
  fi
}

check_not_set() {
  local sym="$1"
  local reason="$2"
  if grep -qE "^${sym}=[ym]" "${CONFIG}"; then
    echo "  WARN  ${sym} is set but should not be  (${reason})"
    WARN=$((WARN + 1))
  fi
}

# === Architecture ===
echo ""
echo "==> Architecture"
check_enabled "CONFIG_64BIT" "ARM64 required"
check_enabled "CONFIG_ARCH_QCOM" "Qualcomm SoC"

# === SoC / Platform ===
echo ""
echo "==> SoC platform (SDM660/SDM636)"
check_enabled "CONFIG_COMMON_CLK_QCOM" "QCOM clocks"
check_enabled "CONFIG_PINCTRL_SDM660" "SDM660 pinctrl"
check_enabled "CONFIG_SDM_GCC_660" "SDM660 GCC"
check_enabled "CONFIG_QCOM_RPMH" "RPMH"

# === Serial / UART ===
echo ""
echo "==> Serial / UART (bring-up stage 1+)"
check_enabled "CONFIG_SERIAL_MSM_GENI_SERIAL" "GENI serial" 2>/dev/null || \
  check_enabled "CONFIG_SERIAL_QCOM_GENI" "GENI serial"
check_enabled "CONFIG_SERIAL_EARLYCON" "Early console"

# === Storage / MMC ===
echo ""
echo "==> Storage (bring-up stage 2+)"
check_enabled "CONFIG_MMC" "MMC core"
check_enabled "CONFIG_MMC_SDHCI" "SDHCI"
check_enabled "CONFIG_MMC_SDHCI_MSM" "QCOM SDHCI"
check_enabled "CONFIG_MMC_BLOCK" "MMC block device"

# === USB ===
echo ""
echo "==> USB (bring-up stage 3+)"
check_enabled "CONFIG_USB" "USB core"
check_enabled "CONFIG_USB_DWC3" "DWC3 controller"
check_enabled "CONFIG_USB_DWC3_QCOM" "DWC3 QCOM glue"
check_enabled "CONFIG_PHY_QCOM_QUSB2" "QUSB2 PHY"

# === Display ===
echo ""
echo "==> Display (bring-up stage 4+)"
check_enabled "CONFIG_DRM" "DRM core"
check_enabled "CONFIG_DRM_MSM" "MSM DRM"
check_enabled "CONFIG_FB_SIMPLE" "Simple framebuffer"

# === Input / Touch ===
echo ""
echo "==> Touch (bring-up stage 5+)"
check_enabled "CONFIG_INPUT" "Input core"
check_enabled "CONFIG_INPUT_TOUCHSCREEN" "Touchscreen subsystem"

# === Android ===
echo ""
echo "==> Android features"
check_enabled "CONFIG_ANDROID_BINDER_IPC" "Binder IPC"
check_enabled "CONFIG_ANDROID_BINDERFS" "BinderFS"
check_enabled "CONFIG_SECURITY_SELINUX" "SELinux"

# === Memory ===
echo ""
echo "==> Memory management"
check_enabled "CONFIG_CMA" "CMA"
check_enabled "CONFIG_DMA_CMA" "DMA CMA"
check_enabled "CONFIG_ZRAM" "ZRAM"
check_enabled "CONFIG_DMABUF_HEAPS" "DMA-BUF heaps"

# === Modules ===
echo ""
echo "==> Module support"
check_enabled "CONFIG_MODULES" "Loadable modules"
check_enabled "CONFIG_MODULE_UNLOAD" "Module unloading"

# === Debugging ===
echo ""
echo "==> Debug / crash"
check_enabled "CONFIG_PSTORE" "Persistent storage"
check_enabled "CONFIG_MAGIC_SYSRQ" "SysRq"

# === Whyred custom ===
echo ""
echo "==> Whyred-specific"
check_enabled "CONFIG_WHYRED_DRIVERS" "Whyred driver menu"
check_enabled "CONFIG_WHYRED_BOARD" "Whyred board driver"

# === Forbidden / problematic ===
echo ""
echo "==> Forbidden / problematic options"
check_not_set "CONFIG_DEBUG_INFO_BTF" "BTF disabled until resolve_btfids fixed"
check_not_set "CONFIG_MODULE_SIG_FORCE" "Must not force in bring-up"

# === Summary ===
echo ""
echo "========================================="
echo "Config validation: errors=${ERR} warnings=${WARN}"
if [[ ${ERR} -gt 0 ]]; then
  echo "FAILED — ${ERR} critical config(s) missing"
  exit 1
fi
if [[ ${WARN} -gt 0 ]]; then
  echo "PASSED with ${WARN} warning(s)"
else
  echo "PASSED"
fi
