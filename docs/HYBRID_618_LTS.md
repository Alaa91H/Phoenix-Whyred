# Phoenix-Whyred — Linux Mainline 6.18 LTS

## ما هو Phoenix-Whyred؟

| الطبقة | المصدر |
|--------|--------|
| **Linux Mainline** | Linux **6.18 LTS** (kernel.org) |
| **SoC** | SDM660/636 drivers مدعومة upstream |
| **الجهاز** | DT whyred + `drivers/whyred/` (glue فقط) |

```
Linux Mainline 6.18 LTS
       │
┌──────▼──────────────────────────────────┐
│  Mainline Image  (v6.18 tag)           │  ← 6.18 LTS + SDM660 upstream
│  + config fragments (SDM660 + whyred)  │
└──────┬──────────────────────────────────┘
       │ DT
┌──────▼──────────────────────────────────┐
│  sdm636-xiaomi-whyred.dts              │
│  + whyred_board.ko (sysfs identity)    │
└─────────────────────────────────────────┘
```

- Linux 6.18 LTS على kernel.org: دعم طويل الأمد من فريق stable.
- SDM660/636 support مدعومة upstream عبر sdm660-mainline project.

## البناء

```bash
# Linux أو WSL2
cd /path/to/Kernel
sed -i 's/\r$//' scripts/*.sh PROJECT.conf
chmod +x scripts/*.sh

export KERNEL_TRACK=6.18          # افتراضي أصلاً

./scripts/setup.sh
./scripts/apply-patches.sh
./scripts/build.sh whyred
# أو Image فقط (أسرع):
# ./scripts/build.sh image

FETCH_ANYKERNEL=1 ./scripts/pack.sh
```

المخرجات:

- `out/dist/Image.gz`
- `out/dist/Phoenix-Whyred-6.18-*.zip`
- `out/dist/config` · `out/dist/build-info.txt`

## GitHub Actions

1. **Actions → Build Kernel → Run workflow**
2. `kernel_track` = **`6.18`**
3. `build_mode` = `image` أو `full`
4. حمّل Artifact

```bash
git tag v0.4.0
git push origin v0.4.0
```

## Device Tree والدرايفرات

مكتمل هيكلياً في الشجرة:

- DT: `arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred*.dts*`
- Drivers: `drivers/whyred/whyred_board.c` (sysfs identity فقط)
- docs: [DEVICE_TREE.md](DEVICE_TREE.md) · [DRIVERS.md](DRIVERS.md)

استخراج ومطابقة stock:

```bash
./scripts/extract-stock-dtb.sh boot.img
./scripts/compare-stock-dt.sh
# docs: STOCK_DTB.md
```

Bring-up تدريجي:

```bash
BRINGUP_STAGE=1 ./scripts/build.sh image   # UART
BRINGUP_STAGE=3 ./scripts/build.sh image   # + MMC + USB
make bringup5                              # كامل أساسي
# docs: BRINGUP.md
```

## الواقعية (مهم)

whyred يومياً على **4.19** في ROM.  
**Phoenix-Whyred 6.18 LTS** = bring-up:

1. بناء Image من Linux Mainline 6.18 ✅  
2. مطابقة stock (مرجع Lineage20) ✅ — [STOCK_AUDIT.md](STOCK_AUDIT.md)  
3. bring-up: UART → MMC → USB → شاشة → لمس 🟡 (`BRINGUP_STAGE`)  
4. DRM panel كامل / WLAN / audio 🔴

## متغيرات مفيدة

| المتغير | المعنى |
|---------|--------|
| `KERNEL_TRACK=6.18` | Linux Mainline LTS (افتراضي) |
| `KERNEL_TRACK=4.19` | كيرنل ROM تقليدي |
| `SKIP_MODULES=1` | بناء Image فقط |
| `GKI_REMOTE=...` | مرآة لـ kernel.org |
| `FRAGMENT_ANDROID=...` | Android binder overlay (اختياري) |

## الباتشات

```
patches/mainline/  → تعديلات على Linux Mainline (إن وُجدت)
patches/sdm660/    → forward-port من mainline (إن وُجدت)
```

## مراجع

- [Linux Mainline 6.18](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git)
- [sdm660-mainline](https://github.com/sdm660-mainline)
- [MAINLINE_MIGRATION_AUDIT.md](MAINLINE_MIGRATION_AUDIT.md)
