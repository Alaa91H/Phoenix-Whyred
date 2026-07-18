# Phoenix-Whyred

**Xiaomi Redmi Note 5 Pro (`whyred`)** · **SDM636** · **Linux Mainline 6.18 LTS**

## Project Status

| Phase | Status |
|-------|--------|
| Repository build on CI | **Working** — Image.gz produced |
| Linux Mainline 6.18 LTS base | **Working** — clones kernel.org v6.18 tag |
| Build provenance | **Working** — full build-info.txt + SHA256SUMS |
| Patch safety | **Working** — APPLIED/FAILED tracking |
| Config validation | **Working** — 30+ critical CONFIGs verified |
| Device Tree | **Partial** — from LineageOS reference, not device dump |
| Hardware bring-up | **Not started** — awaiting first boot test |

> This is an **experimental kernel port**. It compiles and packages successfully.
> Hardware bring-up (UART → MMC → USB → display → touch) has not been tested on
> physical device yet. Do not use as daily driver.

## What Is This?

A **mainline-first** kernel for whyred:

| Layer | Source | Role |
|-------|--------|------|
| **Linux Mainline** | `v6.18` tag (kernel.org) | Modern LTS kernel with SDM660 support |
| **SoC** | Upstream SDM660 drivers | Clocks, pinctrl, QCOM platform |
| **Device** | DT whyred + optional `drivers/whyred` | whyred board overlay |

> Full audit: **[docs/MAINLINE_MIGRATION_AUDIT.md](docs/MAINLINE_MIGRATION_AUDIT.md)**

---

## بناء Whyred

### محلي (Linux / WSL2)

```bash
cd /path/to/Kernel
sed -i 's/\r$//' scripts/*.sh PROJECT.conf
chmod +x scripts/*.sh

./scripts/setup.sh              # يجلب Linux Mainline 6.18 + يدمج whyred
./scripts/apply-patches.sh
./scripts/build.sh whyred       # أو: ./scripts/build.sh image
FETCH_ANYKERNEL=1 ./scripts/pack.sh
```

الناتج: `out/dist/Phoenix-Whyred-6.18-*.zip` و `Image.gz`

```bash
make setup build pack
make info
```

### GitHub Actions

1. ارفع المستودع إلى GitHub  
2. **Actions → Build Kernel → Run workflow**  
3. اختر **`kernel_track = 6.18`**  
4. حمّل الـ Artifact  

```bash
git tag v0.4.0 && git push origin v0.4.0
```

---

## الإعداد الافتراضي

| البند | القيمة |
|-------|--------|
| `KERNEL_TRACK` | **`6.18`** (Linux Mainline LTS) |
| فرع kernel | `v6.18` (kernel.org tag) |
| Defconfig | `defconfig` + fragments |
| Localversion | `-phoenix-whyred-6.18-...` |
| Zip | `Phoenix-Whyred-6.18-*.zip` |

مسار بديل لـ ROM الحالية (4.19):

```bash
export KERNEL_TRACK=4.19
./scripts/setup.sh && ./scripts/build.sh whyred
```

---

## هيكل مهم

```
scripts/setup.sh          ← جلب Linux Mainline 6.18 LTS + overlay whyred
scripts/build.sh          ← defconfig + whyred fragments
configs/fragments/
  android-gki.config      ← Android binder/cgroups (اختياري)
  sdm660.config           ← SoC enablement
  whyred.config           ← device + drivers
  lts-6.18.config         ← هوية 6.18 LTS
arch/.../sdm636-xiaomi-whyred.dts
drivers/whyred/           ← board glue فقط
patches/{mainline,sdm660}/
```

---

## مطابقة stock DTB + bring-up

```bash
# 0) مرجع vendor (مُدمَج مسبقاً — اختياري إعادة جلب)
make stock-ref                         # LineageOS whyred DTS
# docs/STOCK_AUDIT.md

# 1) من الجهاز (تحقق نهائي)
./scripts/extract-stock-dtb.sh boot.img
./scripts/compare-stock-dt.sh          # → out/dt-audit/stock-vs-hybrid.md

# 2) بناء مرحلي
make bringup1    # UART  earlycon@0x0c170000
make bringup2    # + MMC
make bringup3    # + USB
make bringup4    # + شاشة (simple-fb)
make bringup5    # + لمس على blsp_i2c1
```

أدلة: [docs/STOCK_AUDIT.md](docs/STOCK_AUDIT.md) · [docs/BRINGUP.md](docs/BRINGUP.md)

## ملاحظة واقعية

- **6.18 LTS mainline** = هدف تطوير رئيسي (Linux Mainline + bring-up).  
- إقلاع ROM whyred اليوم غالباً يحتاج **4.19** (`KERNEL_TRACK=4.19`).  
- بعد أول بناء 6.18: **مطابقة stock DTB** ثم **UART → MMC → USB → شاشة → لمس**.

---

## ترخيص

نواة Linux: **GPL-2.0** · سكربتات المشروع: **MIT** (انظر `LICENSE`)
