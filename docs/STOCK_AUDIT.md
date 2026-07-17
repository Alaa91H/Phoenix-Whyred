# تدقيق DT مقابل مرجع downstream whyred

**المصدر:** LineageOS `android_kernel_xiaomi_sdm660` فرع `lineage-20`  
**ملفات مرجعية محلية:** `vendor/import/stock-dt/ref-lineage20/`  
**تاريخ الدمج في الهجين:** 2026-07-16

> هذا **مرجع vendor/kernel** وليس dump DTB من جهازك.  
> بعد سحب `boot.img` الحقيقي: أعد `./scripts/compare-stock-dt.sh` للتحقق.

## نتائج حرجة طُبِّقت

| البند | كان (تخمين lavender) | stock / ref | الهجين الآن |
|-------|----------------------|-------------|-------------|
| `qcom,msm-id` | (فارغ) | `<345 0x0>` SDM636 | ✅ |
| `qcom,board-id` | (فارغ) | `<0x30008 0>, <0x10008 0>` | ✅ |
| `qcom,pmic-id` | (فارغ) | PM660+PM660L triples | ✅ |
| Touch I2C bus | `blsp1_i2c5` ❌ | stock `i2c_1` @ `0xc175000` | **`blsp_i2c1`** ✅ |
| Touch addr / GPIO | 0x62 / 66 / 67 | same | ✅ |
| Touch VDDIO | l15/l10 | `pm660_l11` | `vreg_l11a_1p8` ✅ |
| TP reset drive | 2 mA | 16 mA + pull-up | ✅ |
| Fingerprint | GPIO 64/65 I2C | **IRQ 72 / RST 20** platform | ✅ (disabled) |
| SD CD | 54 | 54 | ✅ |
| cont_splash | `0x9d400000` / `0x1c20000` | size **`0x23ff000`** | ✅ |
| ramoops | 4M @ `0xa0000000`, console 128K | console/pmsg **2M** each | ✅ |
| earlycon UART | غير محدد بدقة | `blsp1_uart2` @ **`0x0c170000`** | ✅ |
| USB speed | HS peripheral | HS (no SS on whyred path) | ✅ |
| Primary panel | generic | NT36672 Tianma FHD video (+ variants) | simple-fb أولاً |

## reserved-memory (stock sdm660 + sdm636)

| عنوان | حجم | الدور |
|-------|-----|------|
| `0x85600000` | 1M | wlan_msa_guard |
| `0x85700000` | 1M | wlan_msa_mem |
| `0x85800000` | ~6–8M | hyp / removed |
| `0x86000000` | 2M | smem |
| `0x86200000` | ~45–51M | tz |
| `0x8ac00000` | 126M | modem (mpss) |
| `0x92a00000` | 30M | adsp |
| `0x94800000` | 2M | mba |
| `0x94a00000` | 1M (636) | buffer (بدل cdsp 6M على 660) |
| `0x9d400000` | `0x23ff000` | cont_splash |
| `0xa0000000` | 4M | ramoops (Xiaomi) |

مناطق SoC الأساسية تُعرَّف في mainline `sdm630.dtsi`.  
اللوحة تضيف splash + ramoops في `sdm636-xiaomi-whyred-reserved.dtsi`.

## مراحل bring-up (بعد هذا التدقيق)

1. **UART** — `earlycon=msm_serial_dm,0x0c170000` + `ttyMSM0`  
2. **MMC** — sdhc_1 / CD 54  
3. **USB** — HS gadget + extcon (charger path لاحقاً)  
4. **شاشة** — simple-fb على splash  
5. **لمس** — Novatek على **`blsp_i2c1`** @ 0x62  

```bash
make bringup1
# …
make bringup5
```

## إعادة جلب المرجع

```bash
./scripts/fetch-stock-ref.sh
```

## ملفات stock المهمة

- `sdm636-mtp-whyred.dts` — board-id / pmic-id / hall GPIO75  
- `sdm636.dtsi` — msm-id 345، buffer@94a00000  
- `longcheer/whyred/sdm660-novatek-i2c_d2s.dtsi` — touch  
- `longcheer/common/longcheer-sdm660-mtp.dtsi` — FP + SD CD  
- `longcheer-sdm660-ramoops.dtsi`  
- `sdm660.dtsi` — reserved-memory map  
