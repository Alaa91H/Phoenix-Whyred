# Vendor modules (whyred)

على GKI، صورة النواة عامة وتُحمَّل وحدات البائع (`.ko`) من `vendor` / `vendor_dlkm`.

## سير العمل

1. ابنِ النواة والوحدات: `./scripts/build.sh whyred`
2. الوحدات تخرج إلى `out/modules/lib/modules/<version>/`
3. انسخ الوحدات المطلوبة إلى صورة vendor أو ارفعها systemless (Magisk / KernelSU module)
4. حدّث `modules.load` بترتيب التحميل

## KMI

وحدات vendor يجب أن تُبنى ضد **نفس** جيل KMI لـ `android17-6.18`. أي تحديث GKI يكسر ABI يستلزم إعادة بناء الوحدات.

```bash
# مثال فحص الرموز
nm -D out/modules/lib/modules/*/kernel/drivers/whyred/whyred_board.ko
```
