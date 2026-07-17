# Device Tree — whyred (SDM636)

## الملفات

| ملف | الدور |
|-----|--------|
| `sdm636.dtsi` | فروق SDM636 عن SDM660 (Adreno 509) |
| `sdm636-xiaomi-whyred.dts` | لوحة whyred الرئيسية |
| `sdm636-xiaomi-whyred-pmic.dtsi` | منظمات PM660 / PM660L |
| `sdm636-xiaomi-whyred-pinctrl.dtsi` | TLMM pins |
| `sdm636-xiaomi-whyred-reserved.dtsi` | splash + ramoops (stock) |
| `sdm636-xiaomi-whyred-bringup.dtsi` | `status` حسب مرحلة bring-up |
| `include/dt-bindings/whyred/whyred.h` | GPIO / msm-id / splash |
| `include/dt-bindings/whyred/bringup.h` | `WHYRED_BRINGUP_STAGE` |

الأساس: نمط mainline **sdm660-xiaomi-lavender.dts** (نفس عائلة PMIC/SoC).

## ما يُفعَّل في DT (عند STAGE≥N)

| المكوّن | المرحلة | الحالة في DT |
|---------|:-------:|----------------|
| UART console (`blsp1_uart2`) + earlycon | 1 | okay |
| Power key + Volume | 1 | okay |
| ramoops | 1 | reserved-memory |
| eMMC (`sdhc_1`) + microSD | 2 | okay |
| USB2 peripheral + QUSB2 PHY | 3 | okay |
| simple-framebuffer 1080×2160 | 4 | chosen |
| WLED backlight | 4 | okay |
| Touch Novatek @0x62 على **`blsp_i2c1`** | 5 | okay (pins 66/67) |
| Fingerprint Goodix | — | disabled (IRQ 72 / RST 20) |
| GPU Adreno 509 | — | okay |
| whyred_board / power | 1 | platform nodes |

## مطابقة Stock DTB

راجع الدليل الكامل: **[STOCK_DTB.md](STOCK_DTB.md)**

```bash
./scripts/extract-stock-dtb.sh boot.img
./scripts/compare-stock-dt.sh
# → out/dt-audit/stock-vs-hybrid.md
```

ركّز على:

1. `reserved-memory` (modem / adsp / splash)  
2. أرقام GPIO للمس / البصمة / USB ID  
3. أسماء buses: `blsp1_i2c5` قد تختلف في شجرة 6.18  
4. `qcom,msm-id` / `qcom,board-id`  

## Bring-up التدريجي

راجع **[BRINGUP.md](BRINGUP.md)**

```bash
BRINGUP_STAGE=1 ./scripts/build.sh image   # UART
make bringup3                              # حتى USB
```

## الدرايفرات المرتبطة

| compatible | الدرايفر |
|------------|----------|
| `xiaomi,whyred-board` | `drivers/whyred/whyred_board.c` |
| `xiaomi,whyred-power` | `drivers/whyred/power/whyred_power.c` |
| `xiaomi,whyred-wlan` | `drivers/whyred/wlan/whyred_wlan.c` |
| `novatek,nvt-ts` | in-tree nt36xxx / nvt |
| `xiaomi,whyred-touch` | glue اختياري |

## Sysfs بعد الإقلاع

```
/sys/devices/platform/whyred_board/codename
/sys/devices/platform/whyred_board/panel
/sys/kernel/whyred_panel/geometry
/proc/device-tree/whyred_bringup/xiaomi,bringup-stage
```
