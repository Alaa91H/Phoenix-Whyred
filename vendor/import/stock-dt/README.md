# Stock DTB import (whyred)

Place extracted / decompiled stock device trees here. **Do not commit large boot.img blobs** unless intentional.

## Extract from device

```bash
# on device (root)
adb shell su -c 'dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot.img bs=4M'
adb pull /sdcard/boot.img

# from repo root
./scripts/extract-stock-dtb.sh boot.img
# → vendor/import/stock-dt/dtb-*.dtb + *.dts
```

Optional: also dump `dtbo` if the ROM uses it:

```bash
adb shell su -c 'dd if=/dev/block/bootdevice/by-name/dtbo of=/sdcard/dtbo.img'
adb pull /sdcard/dtbo.img
./scripts/extract-stock-dtb.sh dtbo.img vendor/import/stock-dt/dtbo
```

## Compare with hybrid DT

```bash
./scripts/compare-stock-dt.sh
# report → out/dt-audit/stock-vs-hybrid.md
```

## What to port first

| Priority | Item | Hybrid file |
|----------|------|-------------|
| P0 | `reserved-memory` (modem/adsp/splash/ramoops) | `sdm636-xiaomi-whyred.dts` |
| P0 | UART / console / earlycon | same |
| P1 | eMMC / SD regulators + CD GPIO | same + pinctrl |
| P1 | USB PHY rails + ID GPIO | same |
| P2 | Touch I2C bus, addr, reset/int GPIO | same + pinctrl |
| P2 | `qcom,msm-id` / `qcom,board-id` | root node |
| P3 | Fingerprint / NFC / camera | later |

See [docs/STOCK_DTB.md](../../docs/STOCK_DTB.md) and [docs/BRINGUP.md](../../docs/BRINGUP.md).
