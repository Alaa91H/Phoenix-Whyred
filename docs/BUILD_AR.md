# دليل البناء — كيرنل whyred الهجين 6.18

> **للبناء على GitHub:** انظر [GITHUB_BUILD.md](GITHUB_BUILD.md)

## 1. البيئة

استخدم **Linux** أو **WSL2 Ubuntu 22.04+**.

```bash
sudo apt update
sudo apt install -y git make bc bison flex libssl-dev libelf-dev \
  zip unzip python3 device-tree-compiler gcc-aarch64-linux-gnu clang lld llvm
```

يفضّل Clang الخاص بـ AOSP لبناء GKI رسمي.

## 2. الإعداد

```bash
cd /mnt/d/Kernel   # مثال على WSL لمسار Windows
sed -i 's/\r$//' scripts/*.sh PROJECT.conf Makefile
chmod +x scripts/*.sh
./scripts/setup.sh
```

هذا يجلب `android17-6.18` إلى `.src/common` (حجم كبير).

## 3. الباتشات

```bash
./scripts/apply-patches.sh
```

أضف ملفات `patches/*/*.patch` حسب الحاجة.

## 4. البناء

```bash
./scripts/build.sh whyred
# أو
make build
```

المخرجات:

- `out/dist/Image.gz`
- `out/dist/*.dtb`
- `out/modules/lib/modules/...`

## 5. التعبئة والتثبيت

```bash
# انسخ AnyKernel3 الكامل من upstream إلى pack/AnyKernel3
./scripts/pack.sh
```

ثم من Recovery:

1. عمل نسخة احتياطية (boot)  
2. تثبيت الـ zip  
3. إعادة التشغيل  

## 6. استخراج DTB من الجهاز (مهم)

```bash
# على الجهاز (root) أو من boot.img
# unpack boot.img → kernel + dtb
dtc -I dtb -O dts -o stock-whyred.dts stock.dtb
```

انقل regulators و pins و reserved-memory إلى  
`arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts`.

## 7. استكشاف الأخطاء

| العرض | اتجاه الحل |
|-------|------------|
| لا إقلاع / شاشة سوداء | UART log، تحقق DTB / cmdline |
| bootloop بعد شعار | modules / SELinux / vendor mismatch |
| لا Wi‑Fi | firmware تحت /vendor/firmware |
| KMI mismatch | أعد بناء الوحدات مع نفس GKI |
