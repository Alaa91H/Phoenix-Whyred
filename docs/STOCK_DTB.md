# مطابقة Stock DTB — whyred

## حالة التدقيق الحالية

| المصدر | الحالة |
|--------|--------|
| مرجع LineageOS vendor DT (lineage-20) | ✅ مُدمَج — [STOCK_AUDIT.md](STOCK_AUDIT.md) |
| dump DTB من جهازك (`boot.img`) | ⬜ بعد السحب |

مرجع محلي: `vendor/import/stock-dt/ref-lineage20/`  
إعادة الجلب: `./scripts/fetch-stock-ref.sh`

## 1) استخراج من الجهاز (موصى به للتحقق النهائي)

```bash
adb shell su -c 'dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot.img bs=4M'
adb pull /sdcard/boot.img

./scripts/extract-stock-dtb.sh boot.img
./scripts/compare-stock-dt.sh
# → out/dt-audit/stock-vs-hybrid.md
```

## 2) ما طُبّق من المرجع (ملخص)

- `qcom,msm-id = <345 0x0>` (SDM636)
- `qcom,board-id` / `pmic-id` من `sdm636-mtp-whyred.dts`
- لمس Novatek على **`blsp_i2c1`** (stock `i2c_1`) @ `0x62`، GPIO 66/67
- بصمة stock: IRQ **72** / RST **20** (معطّلة)
- splash `0x9d400000` size `0x23ff000` + ramoops 4M @ `0xa0000000`
- earlycon: `msm_serial_dm,0x0c170000`

التفاصيل: [STOCK_AUDIT.md](STOCK_AUDIT.md)

## 3) قائمة تحقق يدوية متبقية

| # | البند | معيار النجاح |
|---|--------|---------------|
| 1 | dump حقيقي يطابق msm-id/board-id | compare report |
| 2 | UART على الجهاز | نص earlycon |
| 3 | eMMC `mmcblk0` | مرحلة 2 |
| 4 | USB gadget | مرحلة 3 |
| 5 | simple-fb | مرحلة 4 |
| 6 | touch events | مرحلة 5 على `blsp_i2c1` |

## 4) ثوابت

`include/dt-bindings/whyred/whyred.h`

## 5) بعد المطابقة

→ [BRINGUP.md](BRINGUP.md) مرحلة بمرحلة (`make bringup1` … `bringup5`)
