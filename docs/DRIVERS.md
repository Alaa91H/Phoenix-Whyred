# درايفرات whyred — Hybrid 6.18 LTS

## داخل الشجرة (`drivers/whyred/`)

| الوحدة | Kconfig | الوظيفة |
|--------|---------|---------|
| `whyred_board` | `WHYRED_BOARD` | هوية اللوحة + أبعاد الشاشة (platform + sysfs) |
| `whyred_panel` | `WHYRED_DISPLAY` | مساعد هندسة 1080×2160 |
| `whyred_touch` | `WHYRED_TOUCH` | نبضة reset / glue (I2C) |
| `whyred_power` | `WHYRED_POWER` | `power_supply` مؤقت 4000mAh |
| `whyred_wlan` | `WHYRED_WLAN` | تلميحات firmware ath10k |
| `whyred_audio` | `WHYRED_AUDIO` | placeholder |
| `whyred_camera` | `WHYRED_CAMERA` | placeholder |

## درايفرات Mainline / GKI المفضّلة (عبر DT)

| الوظيفة | الدرايفر المقترح |
|---------|------------------|
| لمس | `CONFIG_TOUCHSCREEN_NT36XXX` / novatek nvt-ts |
| شاشة | `CONFIG_DRM_MSM` + panel driver |
| Wi‑Fi | `CONFIG_ATH10K_SNOC` |
| شحن | `CONFIG_CHARGER_QCOM_SMB2` / FG |
| صوت | `CONFIG_SND_SOC_QCOM` + WCD |
| USB | DWC3 + QUSB2 PHY |
| تخزين | `CONFIG_MMC_SDHCI_MSM` |

فعّلها عبر `configs/fragments/whyred.config`.

## ترتيب bring-up المقترح

راجع الدليل التفصيلي: **[BRINGUP.md](BRINGUP.md)** · مطابقة DT: **[STOCK_DTB.md](STOCK_DTB.md)**

1. UART + earlycon + `whyred_board` (`BRINGUP_STAGE=1`)  
2. eMMC rootfs (`=2`)  
3. USB gadget / adb (`=3`)  
4. simple-fb أو DRM (`=4`)  
5. touch (`=5`)  
6. WLAN firmware  
7. audio / camera  

```bash
make bringup1   # … حتى bringup5
```


## البناء كوحدات

بعد `build.sh`:

```
out/modules/lib/modules/*/kernel/drivers/whyred/
  whyred_board.ko
  display/whyred_panel.ko
  ...
```

```bash
insmod whyred_board.ko
# أو
modprobe whyred_board
```
