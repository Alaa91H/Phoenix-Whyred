#!/usr/bin/env bash
# Fetch whyred vendor DT reference from LineageOS kernel (read-only audit).
# Does NOT replace hybrid DT — use compare-stock-dt.sh after device dump.
#
# Usage:
#   ./scripts/fetch-stock-ref.sh [branch]
# Default branch: lineage-20
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRANCH="${1:-lineage-20}"
REPO="${STOCK_REF_REPO:-https://raw.githubusercontent.com/LineageOS/android_kernel_xiaomi_sdm660}"
OUT="${ROOT}/vendor/import/stock-dt/ref-${BRANCH}"
BASE="${REPO}/${BRANCH}"

mkdir -p "${OUT}"

files=(
  "arch/arm64/boot/dts/vendor/qcom/sdm636-mtp-whyred.dts"
  "arch/arm64/boot/dts/vendor/qcom/sdm636.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/sdm636-mtp.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/sdm660.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/sdm660-common.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/sdm660-mtp.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/sdm660-blsp.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/whyred.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/xiaomi-sdm660-common.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/longcheer/whyred/whyred-base.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/longcheer/whyred/sdm660-novatek-i2c_d2s.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/longcheer/common/longcheer-sdm660-base.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/longcheer/common/longcheer-sdm636.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/longcheer/common/longcheer-sdm660-pinctrl.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/longcheer/common/longcheer-sdm660-ramoops.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/longcheer/common/longcheer-sdm660-mtp.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/longcheer/common/longcheer-sdm660-mdss.dtsi"
  "arch/arm64/boot/dts/vendor/qcom/xiaomi/longcheer/common/longcheer-pm660.dtsi"
)

echo "==> Fetching whyred DT ref from ${BASE}"
ok=0
fail=0
for f in "${files[@]}"; do
  name="$(basename "$f")"
  url="${BASE}/${f}"
  if curl -fsSL "$url" -o "${OUT}/${name}"; then
    echo "  OK  ${name} ($(wc -c < "${OUT}/${name}" | tr -d ' ') bytes)"
    ok=$((ok + 1))
  else
    echo "  FAIL ${name}"
    fail=$((fail + 1))
  fi
done

{
  echo "# ref-lineage20 inventory"
  echo "branch=${BRANCH}"
  echo "fetched=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "ok=${ok} fail=${fail}"
  ls -la "${OUT}"
} > "${OUT}/INVENTORY.txt"

# Minimal machine summary for humans / CI
python3 - <<'PY' "${OUT}" || true
import re, sys, os
root = sys.argv[1]
summary = os.path.join(root, "AUDIT-SNIPPETS.txt")
keys = []
def grab(path, patterns):
    if not os.path.isfile(path):
        return
    t = open(path, errors="replace").read()
    keys.append(f"## {os.path.basename(path)}")
    for pat in patterns:
        for m in re.finditer(pat, t, re.I | re.M):
            keys.append("  " + " ".join(m.group(0).split())[:160])

grab(os.path.join(root, "sdm636.dtsi"), [r"qcom,msm-id\s*=\s*<[^>]+>"])
grab(os.path.join(root, "sdm636-mtp-whyred.dts"), [r"qcom,board-id\s*=\s*<[^;]+;", r"qcom,pmic-id\s*=\s*<[^;]+;"])
grab(os.path.join(root, "sdm660-novatek-i2c_d2s.dtsi"),
     [r"reg\s*=\s*<0x62>", r"reset-gpio\s*=\s*<[^>]+>", r"irq-gpio\s*=\s*<[^>]+>", r"&i2c_1"])
grab(os.path.join(root, "longcheer-sdm660-mtp.dtsi"),
     [r"cd-gpios\s*=\s*<[^>]+>", r"fp-gpio-[^=]+=\s*<[^>]+>", r"fpc,gpio_[^=]+=\s*<[^>]+>"])
grab(os.path.join(root, "longcheer-sdm660-ramoops.dtsi"), [r"reg\s*=\s*<[^>]+>"])
grab(os.path.join(root, "sdm660.dtsi"), [r"splash_region@[0-9a-fA-F]+[^{]*\{[^}]+\}"])
open(summary, "w").write("\n".join(keys) + "\n")
print(f"Wrote {summary}")
PY

echo ""
echo "Done: ${OUT} (ok=${ok} fail=${fail})"
echo "See docs/STOCK_AUDIT.md"
echo "Next on device: ./scripts/extract-stock-dtb.sh boot.img && ./scripts/compare-stock-dt.sh"
