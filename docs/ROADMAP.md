# خارطة الطريق

## المرحلة 0 — Scaffold

- [x] هيكل المستودع + CI  
- [x] مسار 4.19  
- [x] مسار 6.18 hybrid LTS  

## المرحلة 1 — Downstream 4.19

- [x] ربط San-Kernel + whyred-perf_defconfig  
- [x] setup / import / build / pack  
- [ ] بناء ناجح على GitHub Actions  
- [ ] اختبار إقلاع على جهاز whyred + ROM 4.19  

## المرحلة 2 — تخصيص 4.19

- [ ] باتشات في patches/4.19  
- [ ] KernelSU (اختياري)  
- [ ] ضبط أداء/بطارية  

## المرحلة 3 — 6.18 Hybrid (طويل الأمد)

### 3.1 مطابقة stock DTB

- [x] `scripts/extract-stock-dtb.sh`  
- [x] `scripts/compare-stock-dt.sh` + تقرير `out/dt-audit/`  
- [x] `scripts/fetch-stock-ref.sh` + مرجع Lineage20  
- [x] دليل [STOCK_DTB.md](STOCK_DTB.md) · [STOCK_AUDIT.md](STOCK_AUDIT.md)  
- [x] دمج ref: msm-id/board-id، touch `blsp_i2c1`، splash/ramoops، FP GPIO  
- [ ] استخراج DTB من جهاز whyred فعلي (تحقق نهائي)  

### 3.2 bring-up تدريجي

- [x] مراحل DT: `bringup.h` + `*-bringup.dtsi`  
- [x] `BRINGUP_STAGE` في `build.sh` + `make bringup1..5`  
- [x] fragments `configs/fragments/bringup/`  
- [x] دليل [BRINGUP.md](BRINGUP.md)  
- [ ] مرحلة 1: UART + earlycon على الجهاز  
- [ ] مرحلة 2: MMC / rootfs  
- [ ] مرحلة 3: USB gadget / adb  
- [ ] مرحلة 4: simple-fb + WLED  
- [ ] مرحلة 5: touch Novatek  
- [ ] DRM panel / WLAN / audio بعد الاستقرار  
