# Patches for Downstream 4.19 (whyred)

ضع هنا ملفات `0001-*.patch` … تُطبَّق على `.src/kernel-4.19` عبر:

```bash
KERNEL_TRACK=4.19 ./scripts/apply-patches.sh
```

أمثلة:

- KernelSU / SUSFS
- ضبط CPU / sched
- إصلاحات panel whyred
- Wi‑Fi firmware path

المصدر الافتراضي للشجرة:

- https://github.com/user-why-red/android_kernel_xiaomi_sdm660_419  
- branch: `stable-release`  
- defconfig: `vendor/whyred-perf_defconfig`
