# مسار Downstream 4.19 — whyred

## لماذا 4.19؟

معظم ROM whyred الحديثة (dynamic partitions) تستخدم **Linux 4.19**.  
هذا المسار يعطي أعلى فرصة إقلاع مقارنة بـ GKI 6.18.

## المصدر

```
https://github.com/user-why-red/android_kernel_xiaomi_sdm660_419
branch: stable-release
defconfig: vendor/whyred-perf_defconfig
```

Defconfigs أخرى في نفس الشجرة:

- `vendor/sdm660-perf_defconfig`
- `vendor/sdm660-perf-full_defconfig`
- `vendor/lavender-perf_defconfig`
- `vendor/tulip-perf_defconfig`

## الأوامر

```bash
export KERNEL_TRACK=4.19   # افتراضي أصلاً
./scripts/setup.sh         # clone → .src/kernel-4.19
./scripts/import-whyred-419.sh
./scripts/build.sh whyred
FETCH_ANYKERNEL=1 ./scripts/pack.sh
```

تغيير الفرع:

```bash
export KERNEL_419_BRANCH=android-4.19-stable
./scripts/setup.sh
```

تغيير defconfig:

```bash
export KERNEL_419_DEFCONFIG=vendor/sdm660-perf_defconfig
./scripts/build.sh whyred
```

## ماذا يوجد داخل الشجرة؟

بعد `setup` ستجد تقريباً:

- `arch/arm64/` — SoC + DT
- `drivers/` — لمس، شاشة، طاقة، …
- `techpack/` — audio / display / camera (CAF style)
- `arch/arm64/configs/vendor/whyred-perf_defconfig`

`import-whyred-419.sh` **لا ينسخ الشجرة**؛ ينشئ جرداً في `vendor/import/whyred-4.19/`.

## التوافق

| ROM kernel | كيرنل هذا المشروع 4.19 |
|------------|-------------------------|
| 4.19 dynamic | ✅ متوقع |
| 4.4 | ❌ لا |
| GKI pure | ❌ لا |

## الترخيص

مصادر San-Kernel / Linux: **GPL-2.0**. عند إعادة التوزيع يجب توفير المصدر.
