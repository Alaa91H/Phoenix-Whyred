# حالة الدعم — Whyred Kernel

آخر تحديث: 2026-07-16

## مسار 6.18 LTS Hybrid (الافتراضي)

| المكوّن | الحالة | ملاحظات |
|---------|--------|---------|
| سكربتات + CI | ✅ | KERNEL_TRACK=6.18 |
| قاعدة android17-6.18 | ✅ | setup يجلب ACK |
| DT whyred (لوحة/PMIC/pinctrl/USB/MMC/TS) | 🟡 | مُحدَّث من ref Lineage20 — بقي dump الجهاز |
| مطابقة stock (مرجع vendor) | ✅ | msm-id/board-id، touch `blsp_i2c1`، splash/ramoops |
| أدوات مطابقة stock DTB | ✅ | extract + compare + `fetch-stock-ref` |
| bring-up تدريجي (UART→…→لمس) | 🟡 | `BRINGUP_STAGE` + earlycon `0x0c170000` |
| whyred_board / power / wlan / panel | 🟡 | درايفرات platform + placeholders |
| Touch Novatek عبر DT | 🟡 | node + in-tree nvt (مرحلة 5) |
| Fingerprint | 🔴 | node معطل |
| DRM panel كامل | 🔴 | simple-fb أولاً (مرحلة 4) |
| Audio / Camera | 🔴 | placeholders |
| إقلاع ROM كامل | 🔴 | بعد مراحل bring-up |

راجع: [DEVICE_TREE.md](DEVICE_TREE.md) · [STOCK_DTB.md](STOCK_DTB.md) · [BRINGUP.md](BRINGUP.md) · [DRIVERS.md](DRIVERS.md)

## مسار 4.19 (بديل ROM)

| المكوّن | الحالة | ملاحظات |
|---------|--------|---------|
| San-Kernel 4.19 | ✅ | KERNEL_TRACK=4.19 |
| whyred-perf_defconfig | ✅ | |
| إقلاع ROM 4.19 | 🟡 | بعد build ناجح |

## الرموز

- ✅ جاهز للاستخدام في المشروع  
- 🟡 قيد العمل / جزئي  
- 🔴 غير مُنفَّذ بعد  

## أولويات العمل الحالية

1. ~~بناء Image من ACK 6.18~~ (مسار جاهز)  
2. ~~مطابقة stock من مرجع vendor~~ — [STOCK_AUDIT.md](STOCK_AUDIT.md) ✅  
3. **تحقق dump من الجهاز** (اختياري لكن مهم): `extract-stock-dtb` + `compare-stock-dt`  
4. **bring-up على الجهاز:** `make bringup1` → … → `bringup5`  

تفصيل: [BRINGUP.md](BRINGUP.md) · [STOCK_AUDIT.md](STOCK_AUDIT.md)
