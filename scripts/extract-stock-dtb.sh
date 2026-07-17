#!/usr/bin/env bash
# Extract / decompile Device Tree from stock or custom boot.img (whyred)
# Usage:
#   ./scripts/extract-stock-dtb.sh boot.img [outdir]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOT_IMG="${1:-}"
OUT="${2:-${ROOT}/vendor/import/stock-dt}"

if [[ -z "${BOOT_IMG}" || ! -f "${BOOT_IMG}" ]]; then
  echo "Usage: $0 /path/to/boot.img [outdir]"
  echo ""
  echo "On device (root):"
  echo "  dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot.img"
  echo "  adb pull /sdcard/boot.img"
  exit 1
fi

mkdir -p "${OUT}"
cp -a "${BOOT_IMG}" "${OUT}/boot.img"

echo "==> Extracting kernel/DTB from ${BOOT_IMG}"

# Prefer unpack_bootimg (AOSP) if available
if command -v unpack_bootimg >/dev/null 2>&1; then
  unpack_bootimg --boot_img "${BOOT_IMG}" --out "${OUT}/unpacked"
elif command -v unpackbootimg >/dev/null 2>&1; then
  unpackbootimg -i "${BOOT_IMG}" -o "${OUT}/unpacked"
else
  echo "NOTE: unpack_bootimg not found — trying raw DTB scan"
  mkdir -p "${OUT}/unpacked"
  # Magiskboot optional
  if command -v magiskboot >/dev/null 2>&1; then
    (
      cd "${OUT}/unpacked"
      cp -a "${BOOT_IMG}" boot.img
      magiskboot unpack boot.img
    )
  else
    echo "Install: android-sdk platform-tools unpack_bootimg, or magiskboot"
    echo "Meanwhile copying boot.img only."
  fi
fi

# Find DTB blobs (FDT magic d0 0d fe ed)
echo "==> Scanning for FDT magic..."
python3 - <<'PY' "${OUT}" || true
import sys, os, struct
root = sys.argv[1]
magic = b"\xd0\x0d\xfe\xed"
found = 0
for dirpath, _, files in os.walk(root):
    for fn in files:
        path = os.path.join(dirpath, fn)
        try:
            data = open(path, "rb").read()
        except Exception:
            continue
        off = 0
        while True:
            i = data.find(magic, off)
            if i < 0:
                break
            if i + 8 > len(data):
                break
            total = struct.unpack(">I", data[i+4:i+8])[0]
            if 64 < total < 2*1024*1024 and i + total <= len(data):
                out = os.path.join(root, f"dtb-{found:02d}.dtb")
                open(out, "wb").write(data[i:i+total])
                print(f"  wrote {out} ({total} bytes @ {fn}+{i})")
                found += 1
            off = i + 4
print(f"Found {found} DTB candidate(s)")
PY

if command -v dtc >/dev/null 2>&1; then
  for dtb in "${OUT}"/dtb-*.dtb; do
    [[ -f "$dtb" ]] || continue
    dts="${dtb%.dtb}.dts"
    echo "==> dtc -I dtb -O dts ${dtb}"
    dtc -I dtb -O dts -o "${dts}" "${dtb}" 2>/dev/null || true
  done
  echo "Decompiled DTS (if any): ${OUT}/*.dts"
  echo "Compare regulators/gpios with arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred*.dts*"
else
  echo "Install device-tree-compiler (dtc) to decompile .dtb → .dts"
fi

# Write a short inventory for humans / CI
{
  echo "# stock-dt inventory"
  echo "source=${BOOT_IMG}"
  echo "extracted=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  ls -la "${OUT}"/dtb-*.dtb "${OUT}"/dtb-*.dts 2>/dev/null || true
} > "${OUT}/INVENTORY.txt" || true

echo ""
echo "Next: compare with hybrid DT"
echo "  ./scripts/compare-stock-dt.sh"
echo "  # report → out/dt-audit/stock-vs-hybrid.md"
echo "Docs: docs/STOCK_DTB.md · docs/BRINGUP.md"

echo "Done: ${OUT}"
