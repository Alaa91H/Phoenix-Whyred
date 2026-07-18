#!/usr/bin/env bash
# Report driver status for whyred hybrid kernel
# Shows what's enabled, what's placeholder, what's missing
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"

CONFIG="${ROOT}/${DIST_DIR}/config"
if [[ ! -f "${CONFIG}" ]]; then
  CONFIG="${ROOT}/configs/fragments/hybrid.config"
fi

echo "======================================"
echo " Whyred Driver Status Report"
echo "======================================"
echo ""

echo "=== Whyred-specific drivers (drivers/whyred/) ==="
DRIVERS=(
  "whyred_board:Core board identification"
  "whyred_display:DRM display panel driver"
  "whyred_touch:Touchscreen driver"
  "whyred_power:Power management (battery/charging)"
  "whyred_wlan:Wi-Fi connectivity driver"
  "whyred_audio:Audio codec driver"
  "whyred_camera:Camera sensor driver"
)

for entry in "${DRIVERS[@]}"; do
  IFS=':' read -r drv desc <<< "$entry"
  drvfile="${ROOT}/drivers/whyred/${drv}.c"
  if [[ -f "${drvfile}" ]]; then
    lines=$(wc -l < "${drvfile}" | tr -d ' ')
    is_stub="0"
    grep -q 'platform_driver_no_pm\|module_init.*stub\|TODO\|FIXME' "${drvfile}" 2>/dev/null && is_stub="1"
    if [[ ${is_stub} -eq 1 ]]; then
      status="PLACEHOLDER (${lines} lines)"
    else
      status="ACTIVE (${lines} lines)"
    fi
  else
    status="MISSING"
  fi
  printf "  %-25s %s\n" "${drv}" "${status}"
done

echo ""
echo "=== Critical Kconfig symbols ==="
if [[ -f "${CONFIG}" ]]; then
  symbols=(
    "CONFIG_WHYRED_DRIVERS:Whyred driver Kconfig"
    "CONFIG_WHYRED_DISPLAY:Display driver"
    "CONFIG_WHYRED_TOUCH:Touchscreen driver"
    "CONFIG_WHYRED_POWER:Power driver"
    "CONFIG_WHYRED_WLAN:Wi-Fi driver"
    "CONFIG_MFD_SPMI_PMIC:SPMI PMIC (power)"
    "CONFIG_REGULATOR_PM660:PM660 regulator"
    "CONFIG_REGULATOR_PM660L:PM660L regulator"
    "CONFIG_PINCTRL_SDM636:SDM636 pinctrl"
    "CONFIG_CLK_SDM636:SDM636 clocks"
    "CONFIG_MMC_SDHCI_MSM:MMC/SDHCI storage"
    "CONFIG_USB_DWC3_DUAL_ROLE:USB dual role"
    "CONFIG_TOUCHSCREEN_NT36XXX:Novatek touch (ACK)"
    "CONFIG_DRM_MSM:DRM display (QCOM)"
    "CONFIG_ATH10K_SNOC:Wi-Fi Atheros (ACK)"
    "CONFIG_THERMAL_MSM_TZ:Thermal management"
    "CONFIG_SMP:Multi-core"
    "CONFIG_ARM64:Architecture"
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
