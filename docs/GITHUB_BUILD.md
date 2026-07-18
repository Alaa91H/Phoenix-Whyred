# البناء على GitHub Actions

## نظرة عامة

| Workflow | الملف | متى يعمل | ماذا يفعل |
|----------|-------|----------|-----------|
| **Validate** | `.github/workflows/validate.yml` | كل push/PR | فحص الهيكل والسكربتات (سريع) |
| **Build Kernel** | `.github/workflows/build-kernel.yml` | يدوي / تاج `v*` / أسبوعي | بناء **6.18** (افتراضي) أو 4.19 + zip |
| **Release** | `.github/workflows/release.yml` | تاج `vX.Y.Z` | يستدعي البناء (إن وُجد) |

## تفعيل المستودع

1. ارفع المشروع إلى GitHub:

```bash
cd /path/to/Kernel
git init
git add .
git commit -m "Initial whyred hybrid kernel 6.18 project"
git branch -M main
git remote add origin https://github.com/USER/whyred-hybrid-6.18.git
git push -u origin main
```

2. من تبويب **Actions** فعّل workflows إن طُلب منك.

3. للبناء اليدوي: **Actions → Build Kernel → Run workflow**

| Input | المعنى | الافتراضي |
|-------|--------|-----------|
| `kernel_track` | **`6.18`** (هجين LTS) أو `4.19` (ROM) | `6.18` |
| `build_mode` | `image` (أسرع) أو `full` | `image` |
| `kernel_419_branch` | فرع San-Kernel | `stable-release` |
| `create_release` | إنشاء Release | `false` |

4. بعد النجاح: **Artifacts** → حمّل `whyred-hybrid-6.18-<run>`

## إصدارات (Releases)

```bash
git tag -a v0.1.0 -m "Whyred Hybrid 6.18 first CI build"
git push origin v0.1.0
```

يدفع تاج `v*` فيشغّل البناء ويرفع ملفات الـ Release (Image / zip).

## حدود GitHub المجاني

- مساحة القرص محدودة → الـ workflow يحرّر مساحة تلقائياً.
- استنساخ Linux Mainline من kernel.org أسرع بكثير من ACK.
- مهلة job: حتى 6 ساعات (`timeout-minutes: 360`).
- الوضع `image` أخف من `full` (بدون modules).

إذا فشل الاستنساخ من `kernel.org`، أعد تشغيل الـ job أو غيّر `GKI_REMOTE` في `PROJECT.conf` إلى مرآة.

## البناء محلياً بنفس أوامر CI

```bash
export CI=true KERNEL_TRACK=6.18 SKIP_MODULES=1 CONTINUE_ON_ERROR=1
./scripts/setup.sh
./scripts/build.sh image
FETCH_ANYKERNEL=1 ./scripts/pack.sh
```

## الشارة (Badge)

أضف في `README.md` (استبدل `USER/REPO`):

```markdown
[![Validate](https://github.com/USER/REPO/actions/workflows/validate.yml/badge.svg)](https://github.com/USER/REPO/actions/workflows/validate.yml)
[![Build Kernel](https://github.com/USER/REPO/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/USER/REPO/actions/workflows/build-kernel.yml)
```

## أذونات Release

للـ workflow الذي ينشئ Releases يحتاج:

- `permissions: contents: write` (موجود في الملف)
- على المستودعات من منظمات: تأكد أن Actions مسموح لها بإنشاء releases

## استكشاف أخطاء شائعة

| المشكلة | الحل |
|---------|------|
| No space left | تأكد أن خطوة Free disk space تعمل؛ قلّل `full` → `image` |
| Clone timeout | أعد التشغيل؛ أو مرآة GKI |
| clang errors | Ubuntu clang 14+ كافٍ غالباً |
| Artifact فارغ | راجع `out/build-image.log` في الـ artifact إن وُجد |
| Release لم يُنشأ | استخدم تاج `v*` أو `create_release=true` |
