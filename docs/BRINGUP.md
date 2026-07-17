# Bring-up تدريجي — whyred (6.18 Hybrid)

الترتيب المعتمد:

```
UART  →  MMC  →  USB  →  شاشة  →  لمس
 (1)      (2)     (3)      (4)       (5)
```

كل مرحلة **تراكمية**: نجاح المرحلة N شرط للانتقال إلى N+1.

## المتطلبات المشتركة

1. مطابقة أولية لـ stock DTB ([STOCK_DTB.md](STOCK_DTB.md)) — على الأقل UART + reserved-memory الحرجة  
2. بناء Image: `./scripts/setup.sh && ./scripts/build.sh image`  
3. كابل USB + محوّل UART (1.8V TTL) على نقاط whyred إن أمكن  
4. `adb` / fastboot جاهزان  

## اختيار المرحلة

| المتغير | المعنى |
|---------|--------|
| `BRINGUP_STAGE=1` … `5` | يمرَّر لـ DTC كـ `WHYRED_BRINGUP_STAGE` ويعطّل عقد DT اللاحقة |
| افتراضي | `5` (UART…لمس) |

```bash
# أمثلة
BRINGUP_STAGE=1 ./scripts/build.sh image    # UART فقط
BRINGUP_STAGE=2 ./scripts/build.sh image    # + eMMC
BRINGUP_STAGE=3 ./scripts/build.sh image    # + USB
BRINGUP_STAGE=4 ./scripts/build.sh image    # + simple-fb
BRINGUP_STAGE=5 ./scripts/build.sh whyred   # + touch + modules
```

الملفات:

- `include/dt-bindings/whyred/bringup.h` — تعاريف المراحل  
- `arch/.../sdm636-xiaomi-whyred-bringup.dtsi` — `status` حسب المرحلة  
- `configs/fragments/bringup/stageN-*.config` — تلميحات Kconfig  

بعد الإقلاع:

```bash
# إن وُجد device-tree
cat /proc/device-tree/whyred_bringup/xiaomi,bringup-stage | od -An -tu4
# أو
cat /sys/firmware/devicetree/base/whyred_bringup/xiaomi,bringup-stage | xxd
```

---

## المرحلة 1 — UART

**الهدف:** `printk` مبكر + كونسول تفاعلي.

| عنصر | DT / Config |
|------|-------------|
| `&blsp1_uart2` | `okay` — mainline `serial@c170000` |
| `stdout-path` | `serial0:115200n8` |
| `bootargs` | `earlycon=msm_serial_dm,0x0c170000 console=ttyMSM0,115200n8` |
| Config | `stage1-uart.config` + serial MSM |

**تحقق:**

```
# على UART (1.8V TTL — نقاط whyred)
Linux version 6.18...
...
console [ttyMSM0] enabled
```

إن صمت تام: تأكد من `0x0c170000` (ليس `0xc1b0000`)، وpinctrl UART في SoC dtsi، ومستوى الجهد 1.8V.

**بديل بدون أسلاك:** بعد panic/reboot اقرأ ramoops @ `0xa0000000` إن كان bootloader يترك المنطقة.

**لا تنتقل للمرحلة 2** بدون سطر كونسول واحد على الأقل (أو pstore بعد إعادة تشغيل).

---

## المرحلة 2 — MMC (eMMC + microSD)

**الهدف:** ظهور `mmcblk0` وجذر/بيانات.

| عنصر | DT |
|------|-----|
| `&sdhc_1` | eMMC + HS400 rails (`vreg_l4b` / `vreg_l8a`) |
| `&sdhc_2` | microSD + CD GPIO 54 |

**تحقق:**

```bash
dmesg | grep -iE 'mmc|sdhci'
ls -l /dev/mmcblk*
# أو من initramfs
```

**أعطال شائعة:** regulator range، `vqmmc` 1.8V، pinmux SDC، تعارض reserved-memory.

---

## المرحلة 3 — USB

**الهدف:** gadget peripheral (configfs / adb لاحقاً).

| عنصر | DT |
|------|-----|
| `&qusb2phy0` | supplies |
| `&usb3` / `&usb3_dwc3` | `dr_mode = "peripheral"` |
| `extcon_usb` | GPIO 58 |

**تحقق:**

```bash
dmesg | grep -iE 'dwc3|qusb|gadget|configfs'
# على المضيف:
lsusb
# بعد userspace configfs: adb devices
```

---

## المرحلة 4 — شاشة (simple-fb أولاً)

**الهدف:** صورة ثابتة من splash / simple-framebuffer (قبل DRM panel كامل).

| عنصر | DT |
|------|-----|
| `framebuffer0` @ `0x9d400000` | 1080×2160 |
| `framebuffer_mem` | `no-map` |
| `&pm660l_wled` | إضاءة خلفية |

**تحقق:** شاشة غير سوداء بعد bootloader splash؛  
`/sys/class/graphics/fb0` أو DRM simple pipe.

DRM panel كامل (DSI + panel driver) = مرحلة لاحقة فوق هذه.

---

## المرحلة 5 — لمس

**الهدف:** Novatek NT36xxx على I2C.

| عنصر | DT |
|------|-----|
| **`&blsp_i2c1`** | stock `i2c_1` @ `0x0c175000` — **ليس** `blsp_i2c5` |
| `touchscreen@62` | reset **66** / int **67** |
| VDDIO | `vreg_l11a_1p8` (stock `pm660_l11`) |
| Config | `TOUCHSCREEN_NT36XXX` / `WHYRED_TOUCH` |

**تحقق:**

```bash
dmesg | grep -iE 'nvt|novatek|i2c'
getevent -l   # أحداث ABS_MT_*
```

إن فشل الـ probe: تأكد أن العقدة على **`blsp_i2c1`**، وعنوان 0x62، وregulator L11.

---

## جدول سريع

| Stage | DT ON | نجاح = |
|:-----:|-------|--------|
| 1 | UART, keys, board, ramoops | كونسول |
| 2 | + sdhc_1/2 | mmcblk |
| 3 | + USB PHY + dwc3 + extcon | lsusb / gadget |
| 4 | + simple-fb + WLED | صورة |
| 5 | + i2c5 touch | getevent |

## بعد المرحلة 5

- WLAN (`ath10k` + firmware)  
- شحن FG/SMB  
- DRM panel حقيقي بدل simple-fb  
- صوت / كاميرا  
- إقلاع ROM userspace كامل  

راجع [STATUS.md](STATUS.md) · [DEVICE_TREE.md](DEVICE_TREE.md) · [DRIVERS.md](DRIVERS.md)
