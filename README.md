# Whyred Hybrid Kernel 6.18 LTS

**Xiaomi Redmi Note 5 Pro (`whyred`)** · **SDM636** · **Linux 6.18 LTS + Android GKI (`android17-6.18`)**

كيرنل **هجين** يجمع:

| الطبقة | المصدر | الدور |
|--------|--------|--------|
| **LTS / GKI** | `android17-6.18` (ACK على Linux **6.18 LTS**) | نواة حديثة + طبقات Android |
| **SoC** | fragments SDM660 + مرجع sdm660-mainline | ساعات، pinctrl، منصة QCOM |
| **الجهاز** | DT whyred + `drivers/whyred` | لوحة whyred |

> الدليل التفصيلي: **[docs/HYBRID_618_LTS.md](docs/HYBRID_618_LTS.md)**

---

## بناء الهجين 6.18 LTS

### محلي (Linux / WSL2)

```bash
cd /path/to/Kernel
sed -i 's/\r$//' scripts/*.sh PROJECT.conf
chmod +x scripts/*.sh

./scripts/setup.sh              # يجلب android17-6.18 + يدمج whyred
./scripts/apply-patches.sh
./scripts/build.sh whyred       # أو: ./scripts/build.sh image
FETCH_ANYKERNEL=1 ./scripts/pack.sh
```

الناتج: `out/dist/Whyred-Hybrid-6.18-LTS-*.zip` و `Image.gz`

```bash
make setup build pack
make info
```

### GitHub Actions

1. ارفع المستودع إلى GitHub  
2. **Actions → Build Kernel → Run workflow**  
3. اختر **`kernel_track = 6.18`**  
4. حمّل الـ Artifact  

```bash
git tag v0.3.0 && git push origin v0.3.0
```

---

## الإعداد الافتراضي

| البند | القيمة |
|-------|--------|
| `KERNEL_TRACK` | **`6.18`** (هجين LTS) |
| فرع GKI | `android17-6.18` |
| Defconfig | `gki_defconfig` + fragments |
| Localversion | `-whyred-hybrid-6.18-lts-...` |
| Zip | `Whyred-Hybrid-6.18-LTS-*.zip` |

مسار بديل لـ ROM الحالية (4.19):

```bash
export KERNEL_TRACK=4.19
./scripts/setup.sh && ./scripts/build.sh whyred
```

---

## هيكل مهم

```
scripts/setup.sh          ← جلب ACK 6.18 LTS + overlay whyred
scripts/build.sh          ← gki_defconfig + hybrid fragments
configs/fragments/
  android-gki.config
  sdm660.config
  whyred.config
  hybrid.config
  lts-6.18.config         ← هوية 6.18 LTS
arch/.../sdm636-xiaomi-whyred.dts
drivers/whyred/           ← glue / stubs للجهاز
patches/{gki,sdm660,android}/
```

---

## مطابقة stock DTB + bring-up

```bash
# 0) مرجع vendor (مُدمَج مسبقاً — اختياري إعادة جلب)
make stock-ref                         # LineageOS whyred DTS
# docs/STOCK_AUDIT.md

# 1) من الجهاز (تحقق نهائي)
./scripts/extract-stock-dtb.sh boot.img
./scripts/compare-stock-dt.sh          # → out/dt-audit/stock-vs-hybrid.md

# 2) بناء مرحلي
make bringup1    # UART  earlycon@0x0c170000
make bringup2    # + MMC
make bringup3    # + USB
make bringup4    # + شاشة (simple-fb)
make bringup5    # + لمس على blsp_i2c1
```

أدلة: [docs/STOCK_AUDIT.md](docs/STOCK_AUDIT.md) · [docs/BRINGUP.md](docs/BRINGUP.md)

## ملاحظة واقعية

- **6.18 LTS hybrid** = هدف تطوير حديث (GKI + bring-up).  
- إقلاع ROM whyred اليوم غالباً يحتاج **4.19** (`KERNEL_TRACK=4.19`).  
- بعد أول بناء 6.18: **مطابقة stock DTB** ثم **UART → MMC → USB → شاشة → لمس**.

---

## ترخيص

نواة Linux / ACK: **GPL-2.0** · سكربتات المشروع: **MIT** (انظر `LICENSE`)
