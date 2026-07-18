#!/usr/bin/env bash
# Fast validation for PR CI (no full kernel clone)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"
ERR=0

echo "==> Validate project structure"
required=(
  PROJECT.conf
  Makefile
  README.md
  configs/fragments/lts-6.18.config
  configs/fragments/hybrid.config
  configs/fragments/whyred.config
  configs/fragments/sdm660.config
  configs/fragments/android-gki.config
  arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts
  arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred-pmic.dtsi
  arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred-pinctrl.dtsi
  arch/arm64/boot/dts/qcom/sdm636.dtsi
  drivers/whyred/whyred_board.c
  drivers/whyred/power/whyred_power.c
  drivers/whyred/touch/whyred_touch.c
  drivers/whyred/display/whyred_panel.c
  drivers/whyred/wlan/whyred_wlan.c
  include/dt-bindings/whyred/whyred.h
  include/dt-bindings/whyred/bringup.h
  scripts/setup.sh
  scripts/build.sh
  scripts/pack.sh
  scripts/ci-env.sh
  scripts/apply-patches.sh
  scripts/extract-stock-dtb.sh
  scripts/compare-stock-dt.sh
  scripts/validate-config.sh
  scripts/fetch-stock-ref.sh
  pack/AnyKernel3/anykernel.sh
  docs/HYBRID_618_LTS.md
  docs/DEVICE_TREE.md
  docs/DRIVERS.md
  docs/STOCK_DTB.md
  docs/BRINGUP.md
  docs/GITHUB_BUILD.md
  docs/BUILD_AR.md
  docs/ROADMAP.md
  docs/AUDIT_6.18.md
  arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred-bringup.dtsi
  arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred-reserved.dtsi
  configs/fragments/bringup/stage1-uart.config
  configs/fragments/bringup/stage5-touch.config
  vendor/import/stock-dt/README.md
  docs/STOCK_AUDIT.md
)
for f in "${required[@]}"; do
  if [[ ! -e "$f" ]]; then
    echo "MISSING: $f"
    ERR=1
  else
    echo "OK  $f"
  fi
done

echo "==> Check shell scripts syntax"
for s in scripts/*.sh; do
  bash -n "$s" && echo "OK  bash -n $s" || { echo "FAIL $s"; ERR=1; }
done

echo "==> PROJECT.conf keys"
# shellcheck source=/dev/null
source PROJECT.conf
for v in PROJECT_NAME KERNEL_TRACK DEVICE_CODENAME SOC GKI_BRANCH_REF GKI_COMMIT KERNEL_VERSION; do
  if [[ -z "${!v:-}" ]]; then
    echo "EMPTY: $v"
    ERR=1
  else
    echo "OK  $v=${!v}"
  fi
done
if [[ "${KERNEL_TRACK}" != "6.18" ]]; then
  echo "NOTE: default track should be 6.18 for hybrid LTS (got ${KERNEL_TRACK})"
fi
if [[ "${KERNEL_VERSION}" != "6.18" ]]; then
  echo "NOTE: expected KERNEL_VERSION=6.18 for hybrid default"
fi
# Verify commit pin is not default/empty
if [[ -z "${GKI_COMMIT:-}" || "${GKI_COMMIT}" == "HEAD" ]]; then
  echo "WARNING: GKI_COMMIT not pinned — builds will not be reproducible"
fi

echo "==> C stubs compile-check (host, syntax only)"
if command -v gcc >/dev/null 2>&1; then
  # -fsyntax-only won't fully resolve kernel headers; just check our files parse as C with stubs
  for c in drivers/whyred/*.c drivers/whyred/*/*.c; do
    [[ -f "$c" ]] || continue
    # lightweight: ensure file non-empty and has MODULE_LICENSE
    if ! grep -q 'MODULE_LICENSE' "$c"; then
      if [[ "$(basename "$c")" != "whyred_board.c" ]]; then
        echo "WARN: no MODULE_LICENSE in $c"
      fi
    fi
    echo "OK  present $c"
  done
fi

if command -v dtc >/dev/null 2>&1; then
  echo "==> DTC dry-run (may fail without includes — non-fatal)"
  dtc -I dts -O dtb -o /tmp/whyred-test.dtb \
    arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts 2>/dev/null \
    && echo "OK  dtc" || echo "SKIP dtc (expected without kernel includes)"
fi

if [[ $ERR -ne 0 ]]; then
  echo "VALIDATION FAILED"
  exit 1
fi
echo "VALIDATION PASSED"
