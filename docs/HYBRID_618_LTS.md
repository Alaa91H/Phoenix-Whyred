# Whyred Hybrid Kernel — Linux 6.18 LTS

## ما هو الهجين 6.18 LTS؟

| الطبقة | المصدر |
|--------|--------|
| **LTS base** | Linux **6.18** (LTS على kernel.org) |
| **Android ACK** | فرع **`android17-6.18`** من AOSP kernel/common |
| **الجهاز** | DT + `drivers/whyred` + fragments لـ SDM636/whyred |
| **مرجع SoC** | sdm660-mainline (اختياري) |

```
Android userspace
       │
┌──────▼──────────────────────────────┐
│  GKI / ACK Image  (android17-6.18)  │  ← 6.18 LTS + Android patches
│  + hybrid config fragments          │
└──────┬──────────────────────────────┘
       │ modules
┌──────▼──────────────────────────────┐
│  drivers/whyred + vendor modules    │
└──────┬──────────────────────────────┘
       │
┌──────▼──────────────────────────────┐
│  sdm636-xiaomi-whyred.dts           │
└─────────────────────────────────────┘
```

- دعم Android ACK `android17-6.18`: حتى **~2030-07** (حسب جدول AOSP).
- Linux 6.18 LTS على kernel.org: دعم طويل الأمد من فريق stable.

## البناء (المسار الافتراضي)

```bash
# Linux أو WSL2
cd /path/to/Kernel
sed -i 's/\r$//' scripts/*.sh PROJECT.conf
chmod +x scripts/*.sh

export KERNEL_TRACK=6.18          # افتراضي أصلاً
# اختياري: مرجع mainline + شجرة LTS للـ cherry-pick
# export SKIP_SDM660=0 FETCH_LTS=1

./scripts/setup.sh
./scripts/apply-patches.sh
./scripts/build.sh whyred
# أو Image فقط (أسرع):
# ./scripts/build.sh image

FETCH_ANYKERNEL=1 ./scripts/pack.sh
```

المخرجات:

- `out/dist/Image.gz`
- `out/dist/Whyred-Hybrid-6.18-LTS-*.zip`
- `out/dist/config` · `out/dist/build-info.txt`

## GitHub Actions

1. **Actions → Build Kernel → Run workflow**
2. `kernel_track` = **`6.18`**
3. `build_mode` = `image` أو `full`
4. حمّل Artifact

```bash
git tag v0.3.0-hybrid-lts
git push origin v0.3.0-hybrid-lts
```

## Device Tree والدرايفرات

مكتمل هيكلياً في الشجرة:

- DT: `arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred*.dts*`
- Drivers: `drivers/whyred/`
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
**هجين 6.18 LTS** = bring-up:

1. بناء Image من ACK 6.18 ✅  
2. مطابقة stock (مرجع Lineage20) ✅ — [STOCK_AUDIT.md](STOCK_AUDIT.md)  
3. bring-up: UART → MMC → USB → شاشة → لمس 🟡 (`BRINGUP_STAGE`)  
4. DRM panel كامل / WLAN / audio 🔴

## متغيرات مفيدة

| المتغير | المعنى |
|---------|--------|
| `KERNEL_TRACK=6.18` | هجين LTS (افتراضي) |
| `KERNEL_TRACK=4.19` | كيرنل ROM تقليدي |
| `SKIP_SDM660=0` | جلب sdm660-mainline |
| `FETCH_LTS=1` | جلب `linux-6.18.y` من kernel.org |
| `SKIP_MODULES=1` | بناء Image فقط |
| `GKI_REMOTE=...` | مرآة لـ kernel/common |

## الباتشات

```
patches/gki/      → تعديلات على android17-6.18
patches/sdm660/   → forward-port من mainline
patches/android/  → extras Android
```

## مراجع

- [android17-6.18](https://android.googlesource.com/kernel/common/+/refs/heads/android17-6.18)
- [Android common kernels](https://source.android.com/docs/core/architecture/kernel/android-common)
- [sdm660-mainline](https://github.com/sdm660-mainline)
