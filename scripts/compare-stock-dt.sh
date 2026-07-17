#!/usr/bin/env bash
# Compare stock decompiled DTS vs hybrid whyred DT (key bring-up properties).
#
# Usage:
#   ./scripts/compare-stock-dt.sh [stock.dts] [hybrid.dts]
#   ./scripts/compare-stock-dt.sh   # auto: vendor/import/stock-dt/*.dts vs tree DT
#
# Requires: python3 (stdlib only). Optional: dtc for re-decompiling .dtb.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOCK_DIR="${ROOT}/vendor/import/stock-dt"
HYBRID_DEFAULT="${ROOT}/arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts"
REPORT_DIR="${ROOT}/out/dt-audit"
mkdir -p "${REPORT_DIR}"

STOCK_DTS="${1:-}"
HYBRID_DTS="${2:-${HYBRID_DEFAULT}}"

if [[ -z "${STOCK_DTS}" ]]; then
  # Prefer first decompiled stock .dts (portable; no mapfile)
  STOCK_DTS="$(find "${STOCK_DIR}" -maxdepth 3 -type f -name '*.dts' 2>/dev/null | sort | head -n1 || true)"
  if [[ -z "${STOCK_DTS}" ]]; then
    echo "No stock DTS found under ${STOCK_DIR}"
    echo ""
    echo "Extract first:"
    echo "  adb shell su -c 'dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot.img'"
    echo "  adb pull /sdcard/boot.img"
    echo "  ./scripts/extract-stock-dtb.sh boot.img"
    echo "  ./scripts/compare-stock-dt.sh"
    exit 2
  fi
  extra="$(find "${STOCK_DIR}" -maxdepth 3 -type f -name '*.dts' 2>/dev/null | sort | wc -l | tr -d ' ')"
  if [[ "${extra}" -gt 1 ]]; then
    echo "NOTE: ${extra} stock DTS files — using: ${STOCK_DTS}"
  fi
fi

if [[ ! -f "${STOCK_DTS}" ]]; then
  echo "Stock DTS not found: ${STOCK_DTS}"
  exit 1
fi
if [[ ! -f "${HYBRID_DTS}" ]]; then
  echo "Hybrid DTS not found: ${HYBRID_DTS}"
  exit 1
fi

# Also scan hybrid includes for GPIO / reserved-memory
HYBRID_BUNDLE="${REPORT_DIR}/hybrid-bundle.dts.txt"
{
  echo "/* auto-concat for audit — not a valid single DTS */"
  for f in \
    "${ROOT}/arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts" \
    "${ROOT}/arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred-pinctrl.dtsi" \
    "${ROOT}/arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred-pmic.dtsi" \
    "${ROOT}/arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred-reserved.dtsi" \
    "${ROOT}/arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred-bringup.dtsi" \
    "${ROOT}/include/dt-bindings/whyred/whyred.h"
  do
    [[ -f "$f" ]] || continue
    echo ""
    echo "/* ==== $(basename "$f") ==== */"
    cat "$f"
  done
} > "${HYBRID_BUNDLE}"

echo "==> Stock : ${STOCK_DTS}"
echo "==> Hybrid: ${HYBRID_DTS} (+ includes → ${HYBRID_BUNDLE})"
echo "==> Report: ${REPORT_DIR}/stock-vs-hybrid.md"
echo ""

python3 - <<'PY' "${STOCK_DTS}" "${HYBRID_BUNDLE}" "${REPORT_DIR}/stock-vs-hybrid.md" "${REPORT_DIR}/stock-summary.txt"
import re, sys, os
from collections import OrderedDict

stock_path, hybrid_path, report_path, summary_path = sys.argv[1:5]

def read(p):
    with open(p, "r", errors="replace") as f:
        return f.read()

stock = read(stock_path)
hybrid = read(hybrid_path)

def find_all(pattern, text, flags=re.I | re.M):
    return re.findall(pattern, text, flags)

def first(pattern, text, default="(not found)"):
    m = re.search(pattern, text, re.I | re.M | re.S)
    if not m:
        return default
    return " ".join(m.group(0).split())

def prop_values(name, text, limit=8):
    # property-name = <...>; or "..."
    pat = rf'{re.escape(name)}\s*=\s*([^;]+);'
    vals = find_all(pat, text)
    out = []
    for v in vals[:limit]:
        out.append(" ".join(v.split()))
    return out

def gpios_near(label, text, window=400):
    """Find gpio / interrupt mentions near a keyword."""
    hits = []
    for m in re.finditer(re.escape(label), text, re.I):
        start = max(0, m.start() - 80)
        end = min(len(text), m.end() + window)
        chunk = text[start:end]
        g = re.findall(r'(?:gpios|interrupts|reset-gpios|id-gpios|cd-gpios)\s*=\s*[^;]+;', chunk, re.I)
        hits.extend(" ".join(x.split()) for x in g)
    return hits[:12]

checks = OrderedDict()

# --- identity ---
checks["model / compatible"] = {
    "stock": prop_values("compatible", stock)[:3] + prop_values("model", stock)[:2],
    "hybrid": prop_values("compatible", hybrid)[:3] + prop_values("model", hybrid)[:2],
}
checks["qcom,msm-id"] = {
    "stock": prop_values("qcom,msm-id", stock),
    "hybrid": prop_values("qcom,msm-id", hybrid),
}
checks["qcom,board-id"] = {
    "stock": prop_values("qcom,board-id", stock),
    "hybrid": prop_values("qcom,board-id", hybrid),
}

# --- UART / console ---
checks["stdout-path / console"] = {
    "stock": prop_values("stdout-path", stock) + [
        x for x in prop_values("bootargs", stock) if "console" in x.lower() or "earlycon" in x.lower()
    ],
    "hybrid": prop_values("stdout-path", hybrid) + [
        x for x in prop_values("bootargs", hybrid) if "console" in x.lower() or "earlycon" in x.lower()
    ],
}
checks["uart status (blsp/uart)"] = {
    "stock": re.findall(r'(uart[0-9a-z_@]*\s*\{[^}]{0,200}status\s*=\s*"[^"]+")', stock, re.I | re.S)[:6],
    "hybrid": re.findall(r'(blsp1_uart2[^{]*\{[^}]*status\s*=\s*"[^"]+")', hybrid, re.I | re.S)[:4],
}

# --- reserved-memory ---
def reserved_regs(text):
    # reg = <a b c d> inside reserved-memory-ish names
    blocks = re.findall(
        r'([\w@.-]+)\s*\{([^{}]{0,500}reg\s*=\s*<[^>]+>[^{}]{0,200})\}',
        text, re.I | re.S)
    out = []
    keys = ("memory@", "rmem", "modem", "adsp", "cdsp", "venus", "splash",
            "framebuffer", "ramoops", "cont_splash", "secure", "hyp", "tz")
    for name, body in blocks:
        low = (name + body).lower()
        if any(k in low for k in keys) or "no-map" in body:
            reg = re.search(r'reg\s*=\s*<([^>]+)>', body, re.I)
            if reg:
                out.append(f"{name}: <{' '.join(reg.group(1).split())}>")
    return out[:40]

checks["reserved-memory / splash / ramoops"] = {
    "stock": reserved_regs(stock),
    "hybrid": reserved_regs(hybrid),
}

# --- MMC ---
checks["sdhc / mmc supplies & status"] = {
    "stock": (
        prop_values("vmmc-supply", stock)[:6]
        + prop_values("vqmmc-supply", stock)[:6]
        + gpios_near("sdhc", stock)
        + gpios_near("sdc", stock)
    ),
    "hybrid": (
        prop_values("vmmc-supply", hybrid)[:6]
        + prop_values("vqmmc-supply", hybrid)[:6]
        + gpios_near("sdhc", hybrid)
    ),
}

# --- USB ---
checks["usb / qusb / dwc3"] = {
    "stock": gpios_near("usb", stock) + prop_values("dr_mode", stock)[:4],
    "hybrid": gpios_near("usb", hybrid) + prop_values("dr_mode", hybrid)[:4]
              + prop_values("id-gpios", hybrid),
}

# --- Touch ---
checks["touch / novatek / nvt"] = {
    "stock": (
        gpios_near("novatek", stock)
        + gpios_near("nvt", stock)
        + gpios_near("touchscreen", stock)
        + prop_values("reg", "\n".join(
            re.findall(r'(?:novatek|nvt|touchscreen)[^{]*\{[^}]{0,400}\}', stock, re.I | re.S)
        ))[:6]
    ),
    "hybrid": (
        gpios_near("novatek", hybrid)
        + gpios_near("touchscreen", hybrid)
        + prop_values("reg", hybrid)[:4]
    ),
}

# --- GPIO numbers of interest ---
def gpio_numbers(text):
    nums = set()
    for m in re.finditer(r'gpio(?:s)?\s*=\s*<[^>]*\b(\d{1,3})\b', text, re.I):
        nums.add(int(m.group(1)))
    for m in re.finditer(r'interrupts\s*=\s*<\s*(\d{1,3})\b', text, re.I):
        nums.add(int(m.group(1)))
    for m in re.finditer(r'pins\s*=\s*"gpio(\d+)"', text, re.I):
        nums.add(int(m.group(1)))
    return sorted(nums)

checks["TLMM gpio numbers seen"] = {
    "stock": [str(n) for n in gpio_numbers(stock)[:60]],
    "hybrid": [str(n) for n in gpio_numbers(hybrid)[:60]],
}

# --- Bring-up checklist keys ---
bringup_keys = [
    ("UART", r"blsp1_uart|uart2|ttyMSM|stdout-path"),
    ("MMC eMMC", r"sdhc_1|sdhci.*1|qcom,sdhc"),
    ("MMC SD", r"sdhc_2|sdc2|cd-gpios"),
    ("USB PHY", r"qusb2|usb2.?phy|dwc3"),
    ("simple-fb / splash", r"simple-framebuffer|cont_splash|framebuffer@"),
    ("Touch", r"novatek|nvt-ts|nt36"),
    ("WLED backlight", r"wled|backlight"),
    ("ramoops", r"ramoops"),
]

def present(pat, text):
    return bool(re.search(pat, text, re.I))

lines = []
lines.append("# Stock DTB vs Hybrid DT — audit report")
lines.append("")
lines.append(f"- **Stock:** `{stock_path}`")
lines.append(f"- **Hybrid bundle:** `{hybrid_path}`")
lines.append("")
lines.append("## Bring-up presence matrix")
lines.append("")
lines.append("| Feature | Stock | Hybrid |")
lines.append("|---------|:-----:|:------:|")
for name, pat in bringup_keys:
    s = "✅" if present(pat, stock) else "❌"
    h = "✅" if present(pat, hybrid) else "❌"
    lines.append(f"| {name} | {s} | {h} |")
lines.append("")
lines.append("## Property dumps (manual review)")
lines.append("")
lines.append("Compare stock values and **port mismatches** into hybrid DT.")
lines.append("Focus: `reserved-memory`, GPIO numbers, I2C bus labels, msm-id/board-id.")
lines.append("")

for title, sides in checks.items():
    lines.append(f"### {title}")
    lines.append("")
    lines.append("**Stock:**")
    if sides["stock"]:
        for v in sides["stock"]:
            lines.append(f"- `{v}`")
    else:
        lines.append("- _(none extracted)_")
    lines.append("")
    lines.append("**Hybrid:**")
    if sides["hybrid"]:
        for v in sides["hybrid"]:
            lines.append(f"- `{v}`")
    else:
        lines.append("- _(none extracted)_")
    lines.append("")

# GPIO set diff for hybrid constants of interest
interest = {54, 58, 64, 65, 66, 67}
sg = set(gpio_numbers(stock))
hg = set(gpio_numbers(hybrid))
lines.append("## Hybrid interest GPIOs (54 SD_CD, 58 USB_ID, 64/65 FP, 66/67 TS)")
lines.append("")
lines.append("| GPIO | In stock dump? | In hybrid? |")
lines.append("|------|:--------------:|:----------:|")
for g in sorted(interest):
    lines.append(f"| {g} | {'✅' if g in sg else '❓'} | {'✅' if g in hg else '❌'} |")
lines.append("")
lines.append("## Next actions")
lines.append("")
lines.append("1. Copy any missing `reserved-memory` regions from stock into `sdm636-xiaomi-whyred.dts`.")
lines.append("2. Align touch/USB/SD GPIOs if stock differs.")
lines.append("3. Set `qcom,msm-id` / `qcom,board-id` from stock (bootloader matching).")
lines.append("4. Continue gradual bring-up: UART → MMC → USB → display → touch (see `docs/BRINGUP.md`).")
lines.append("")

report = "\n".join(lines)
with open(report_path, "w", encoding="utf-8") as f:
    f.write(report)

# Short machine-readable summary
with open(summary_path, "w", encoding="utf-8") as f:
    for name, pat in bringup_keys:
        f.write(f"{name}: stock={present(pat, stock)} hybrid={present(pat, hybrid)}\n")
    f.write(f"stock_gpio_count={len(sg)}\n")
    f.write(f"hybrid_gpio_count={len(hg)}\n")

print(report)
print(f"\nWrote {report_path}")
print(f"Wrote {summary_path}")
PY

echo ""
echo "Done. Review ${REPORT_DIR}/stock-vs-hybrid.md and update DT if needed."
