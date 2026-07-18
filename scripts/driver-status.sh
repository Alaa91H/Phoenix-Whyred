#!/usr/bin/env bash
# Report driver status for Phoenix-Whyred kernel
# Shows what's enabled, what's placeholder, what's missing
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"

CONFIG="${ROOT}/${DIST_DIR}/config"
if [[ ! -f "${CONFIG}" ]]; then
  CONFIG="${ROOT}/configs/fragments/whyred.config"
fi

echo "======================================"
echo " Phoenix-Whyred Driver Status Report"
echo "======================================"
echo ""

echo "=== Whyred-specific drivers (drivers/whyred/) ==="
DRIVERS=(
  "whyred_board:Core board identification (sysfs)"
)

for entry in "${DRIVERS[@]}"; do
  IFS=':' read -r drv desc <<< "$entry"
  drvfile="${ROOT}/drivers/whyred/${drv}.c"
  if [[ -f "${drvfile}" ]]; then
    lines=$(wc -l < "${drvfile}" | tr -d ' ')
    status="ACTIVE (${lines} lines)"
  else
    status="MISSING"
  fi
  printf "  %-25s %s\n" "${drv}" "${status}"
done

echo ""
echo "=== Upstream drivers (via DT + config) ==="
UPSTREAM_DRIVERS=(
  "CONFIG_TOUCHSCREEN_NT36XXX:Novatek touch (upstream)"
  "CONFIG_DRM_MSM:DRM display (upstream)"
  "CONFIG_ATH10K_SNOC:Wi-Fi Atheros (upstream)"
  "CONFIG_CHARGER_QCOM_SMB2:Charger (upstream)"
  "CONFIG_BATTERY_QCOM_BATTMGR:Battery (upstream)"
  "CONFIG_SND_SOC_WCD9335:Audio codec (upstream)"
  "CONFIG_MMC_SDHCI_MSM:MMC/SDHCI storage (upstream)"
  "CONFIG_USB_DWC3_QCOM:USB (upstream)"
  "CONFIG_QCOM_Q6V5_MSS:Modem (upstream)"
  "CONFIG_REMOTEPROC:Remote processors (upstream)"
)

for entry in "${UPSTREAM_DRIVERS[@]}"; do
  IFS=':' read -r sym desc <<< "$entry"
  if [[ -f "${CONFIG}" ]]; then
    if grep -q "^${sym}=" "${CONFIG}" 2>/dev/null; then
      val=$(grep "^${sym}=" "${CONFIG}" | tail -1 | cut -d= -f2)
      printf "  %-40s = %-8s (%s)\n" "${sym}" "${val}" "${desc}"
    elif grep -q "^# ${sym} is not set" "${CONFIG}" 2>/dev/null; then
      printf "  %-40s   not set  (%s)\n" "${sym}" "${desc}"
    else
      printf "  %-40s   ABSENT   (%s)\n" "${sym}" "${desc}"
    fi
  fi
done

echo ""
echo "=== Critical Kconfig symbols ==="
if [[ -f "${CONFIG}" ]]; then
  symbols=(
    "CONFIG_WHYRED_DRIVERS:Whyred driver Kconfig"
    "CONFIG_WHYRED_BOARD:Board identity"
    "CONFIG_PINCTRL_SDM660:SDM660 pinctrl"
    "CONFIG_SDM_GCC_660:SDM660 clocks"
    "CONFIG_SDM_GPUCC_660:SDM660 GPU clocks"
    "CONFIG_SDM_VIDEOCC_660:SDM660 video clocks"
    "CONFIG_SDM_DISPCC_660:SDM660 display clocks"
    "CONFIG_INTERCONNECT_QCOM_SDM660:SDM660 interconnect"
    "CONFIG_MMC_SDHCI_MSM:MMC/SDHCI storage"
    "CONFIG_DRM_MSM:DRM display"
    "CONFIG_TOUCHSCREEN_NT36XXX:Novatek touch"
    "CONFIG_ATH10K_SNOC:Wi-Fi"
    "CONFIG_DEBUG_INFO_BTF:BTF (disabled)"
    "CONFIG_MODULES:Loadable modules"
    "CONFIG_CMA:Contiguous memory allocator"
    "CONFIG_ZRAM:ZRAM compression"
    "CONFIG_PSTORE:Persistent storage"
  )
  for entry in "${symbols[@]}"; do
    IFS=':' read -r sym desc <<< "$entry"
    if grep -q "^${sym}=" "${CONFIG}" 2>/dev/null; then
      val=$(grep "^${sym}=" "${CONFIG}" | tail -1 | cut -d= -f2)
      printf "  %-40s = %-12s (%s)\n" "${sym}" "${val}" "${desc}"
    elif grep -q "^# ${sym} is not set" "${CONFIG}" 2>/dev/null; then
      printf "  %-40s   not set      (%s)\n" "${sym}" "${desc}"
    else
      printf "  %-40s   ABSENT       (%s)\n" "${sym}" "${desc}"
    fi
  done
else
  echo "  No config found. Run build first."
fi

echo ""
echo "=== Bring-up stage gates ==="
echo "  BRINGUP_STAGE=${BRINGUP_STAGE:-5}"
echo "  Stage 1 (UART):      earlycon at 0x0c170000"
echo "  Stage 2 (+MMC):      SDHCI storage probe"
echo "  Stage 3 (+USB):      USB peripheral/host"
echo "  Stage 4 (+display):  DRM panel init"
echo "  Stage 5 (+touch):    Novatek I2C probe"
echo ""
echo "Use BRINGUP_STAGE=N to build incrementally."
echo "======================================"
