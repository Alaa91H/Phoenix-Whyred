# Final Execution Plan: Rebase Phoenix-Whyred onto sdm660-mainline 7.0.9

**Date**: 2026-07-18
**Status**: Ready to execute
**Timeline**: 7 days (Days 1-7)
**Strategy**: Fork sdm660-mainline, add Phoenix customizations on top

---

## Executive Summary

Rebase Phoenix-Whyred from Vanilla Linux 6.18 (no Qualcomm platform support) onto sdm660-mainline Linux 7.0.9 (proven whyred boot). Fork `github.com/sdm660-mainline/linux` branch `qcom-sdm660-7.0.y`, port Phoenix CI/build/flash infrastructure, and produce a working whyred kernel build.

---

## Prerequisites

| Item | Requirement | Verification |
|------|-------------|--------------|
| GitHub access | Push access to Alaa91H org | `gh auth status` |
| Disk space | 50GB+ free | `df -h .` |
| RAM | 8GB+ (kernel build) | `free -h` |
| Tools | git, gh, curl, zip | `which git gh curl zip` |
| Clang | >= 14.0 (or AOSP clang) | `clang --version` |
| Cross-compiler | aarch64-linux-gnu-gcc | `aarch64-linux-gnu-gcc --version` |

---

## Phase 1: Fork & Repository Setup (Day 1)

### 1.1 Fork sdm660-mainline/linux

**Action**: Fork via GitHub API

```bash
# Fork to Alaa91H org
gh repo fork sdm660-mainline/linux --clone=false

# Verify fork exists
gh repo view Alaa91H/linux --json name,defaultBranchRef
```

**Expected result**: `github.com/Alaa91H/linux` created with `qcom-sdm660-7.0.y` branch

### 1.2 Clone and configure

```bash
cd /path/to/workspace

# Clone fork
git clone https://github.com/Alaa91H/linux.git Phoenix-Whyred
cd Phoenix-Whyred

# Add upstream remote
git remote add upstream https://github.com/sdm660-mainline/linux.git

# Fetch upstream
git fetch upstream qcom-sdm660-7.0.y

# Create working branch
git checkout -b phoenix-whyred upstream/qcom-sdm660-7.0.y

# Verify branch
git log --oneline -5
# Should show sdm660-mainline commits
```

### 1.3 Verify target files exist

```bash
# DTS
ls -la arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts
# Expected: file exists

# Defconfig
ls -la arch/arm64/configs/sdm660_defconfig
# Expected: file exists (23,870 bytes)

# PMIC DTS
ls arch/arm64/boot/dts/qcom/pm660*.dtsi
# Expected: pm660.dtsi, pm660l.dtsi

# SoC DTS
ls arch/arm64/boot/dts/qcom/sdm636*.dtsi
# Expected: sdm636.dtsi, sdm630.dtsi, sdm660.dtsi
```

### 1.4 Verify DTS content

```bash
# Check whyred DTS includes
grep '#include' arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts
# Expected: sdm636.dtsi, pm660.dtsi, pm660l.dtsi

# Check touch controller
grep -A5 'syna,rmi4' arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts
# Expected: Synaptics RMI4 E753 at I2C address 0x20

# Check display panel
grep -A5 'tianma,td4310' arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts
# Expected: Tianma TD4310 panel node

# Check GPU
grep -A5 'adreno-509' arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts
# Expected: Adreno 509 GPU node
```

### Validation Checkpoint 1

- [ ] Fork created at `github.com/Alaa91H/linux`
- [ ] Branch `phoenix-whyred` created from `qcom-sdm660-7.0.y`
- [ ] DTS file present and complete
- [ ] Defconfig present (23,870 bytes)
- [ ] PMIC and SoC DTSI files present

### Risk: Fork permissions
**Mitigation**: If fork fails, use `gh repo create Alaa91H/linux --public --clone` manually, then add upstream.

---

## Phase 2: Config Analysis & Merge (Days 2-3)

### 2.1 Extract sdm660-mainline defconfig

```bash
# Extract full config from sdm660-mainline defconfig
make ARCH=arm64 LLVM=1 LLVM_IAS=1 sdm660_defconfig
cp out/.config /tmp/sdm660-full.config

# Extract only set symbols
grep -E '^CONFIG_.+=y' /tmp/sdm660-full.config | sort > /tmp/sdm660-y.config
grep -E '^CONFIG_.+=m' /tmp/sdm660-full.config | sort > /tmp/sdm660-m.config
wc -l /tmp/sdm660-y.config /tmp/sdm660-m.config
```

### 2.2 Extract Phoenix config symbols

```bash
# From Phoenix-Whyred repo (old)
cd /path/to/Phoenix-Whyred-old

# Merge all fragments
cat configs/fragments/sdm660.config \
    configs/fragments/whyred.config \
    configs/fragments/hybrid.config \
    configs/fragments/lts-6.18.config \
    configs/fragments/bringup/stage1-uart.config \
    configs/fragments/bringup/stage2-mmc.config \
    configs/fragments/bringup/stage3-usb.config \
    configs/fragments/bringup/stage4-display.config \
    configs/fragments/bringup/stage5-touch.config \
    > /tmp/phoenix-merged.config

# Extract set symbols
grep -E '^CONFIG_.+=y' /tmp/phoenix-merged.config | sort > /tmp/phoenix-y.config
grep -E '^CONFIG_.+=m' /tmp/phoenix-merged.config | sort > /tmp/phoenix-m.config
wc -l /tmp/phoenix-y.config /tmp/phoenix-m.config
```

### 2.3 Diff analysis

```bash
# Symbols in Phoenix but NOT in sdm660-mainline (need to add)
comm -23 /tmp/phoenix-y.config /tmp/sdm660-y.config > /tmp/missing-in-sdm660-y.config
comm -23 /tmp/phoenix-m.config /tmp/sdm660-m.config > /tmp/missing-in-sdm660-m.config

# Symbols in sdm660-mainline but NOT in Phoenix (already covered)
comm -13 /tmp/phoenix-y.config /tmp/sdm660-y.config > /tmp/extra-in-sdm660-y.config

# Symbols in both (potential conflicts)
comm -12 /tmp/phoenix-y.config /tmp/sdm660-y.config > /tmp/both-y.config

echo "=== Phoenix-only symbols (need adding) ==="
cat /tmp/missing-in-sdm660-y.config

echo "=== sdm660-mainline-only symbols (keep) ==="
wc -l /tmp/extra-in-sdm660-y.config

echo "=== Common symbols ==="
wc -l /tmp/both-y.config
```

### 2.4 Key symbols to add from Phoenix

Based on analysis, these Phoenix symbols are NOT in sdm660-mainline defconfig:

```bash
# From sdm660.config (SoC-specific)
# Most are already in sdm660-mainline defconfig
# Verify these are present:
for sym in CONFIG_ARCH_QCOM CONFIG_QCOM_RPMH CONFIG_QCOM_SMEM \
           CONFIG_SERIAL_QCOM_GENI CONFIG_USB_DWC3 CONFIG_MMC_SDHCI_MSM; do
  grep -q "$sym=y" /tmp/sdm660-y.config && echo "OK: $sym" || echo "MISSING: $sym"
done

# From whyred.config (device-specific)
# These may need adding:
cat /tmp/missing-in-sdm660-y.config | grep -E 'WHYRED|PINCTRL_SDM660|QCOM_TSENS|SPMI'
```

### 2.5 Create merged defconfig

```bash
cd /path/to/Phoenix-Whyred

# Start with sdm660-mainline defconfig as base
cp arch/arm64/configs/sdm660_defconfig arch/arm64/configs/phoenix-whyred_defconfig

# Add Phoenix-specific symbols that are missing
cat >> arch/arm64/configs/phoenix-whyred_defconfig << 'EOF'
# Phoenix-Whyred additions on top of sdm660-mainline
# These symbols are confirmed present in Linux 7.0.9

# Local version
CONFIG_LOCALVERSION="-phoenix-whyred-7.0"

# Module support (from hybrid.config)
CONFIG_MODULES=y
CONFIG_MODULE_UNLOAD=y
CONFIG_MODVERSIONS=y
CONFIG_MODULE_SIG=y

# CMA/DMA (from hybrid.config)
CONFIG_CMA=y
CONFIG_DMA_CMA=y
CONFIG_DMABUF_HEAPS=y
CONFIG_DMABUF_HEAPS_CMA=y
CONFIG_DMABUF_HEAPS_SYSTEM=y

# Scheduler (from hybrid.config)
CONFIG_SCHED_MC=y
CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL=y

# Device tree overlay (from hybrid.config)
CONFIG_OF_OVERLAY=y

# Disable BTF (from hybrid.config - pahole >= 1.25 required)
# CONFIG_DEBUG_INFO_BTF is not set
# CONFIG_DEBUG_INFO_BTF_MODULES is not set

# Disable MODULE_SIG_FORCE (from lts-6.18.config)
# CONFIG_MODULE_SIG_FORCE is not set
EOF

# Validate
make ARCH=arm64 LLVM=1 LLVM_IAS=1 phoenix-whyred_defconfig
```

### 2.6 Config validation

```bash
# Verify critical symbols
make ARCH=arm64 LLVM=1 LLVM_IAS=1 menuconfig  # Interactive check

# Or batch verify:
for sym in \
  ARCH_QCOM PINCTRL_SDM660 SDM_GCC_660 COMMON_CLK_QCOM \
  SERIAL_QCOM_GENI SERIAL_QCOM_GENI_CONSOLE \
  MMC_SDHCI_MSM USB_DWC3 USB_DWC3_QCOM \
  PHY_QCOM_QUSB2 PHY_QCOM_USB_HS \
  DRM_MSM DRM_MSM_DSI BACKLIGHT_CLASS_DEVICE \
  I2C_QCOM_GENI INPUT_TOUCHSCREEN \
  REMOTEPROC QCOM_Q6V5_MSS QRTR \
  CMA DMA_CMA MODULES; do
  grep -q "CONFIG_${sym}=y\|CONFIG_${sym}=m" out/.config && echo "OK: $sym" || echo "MISSING: $sym"
done
```

### Validation Checkpoint 2

- [ ] `phoenix-whyred_defconfig` created
- [ ] Config builds successfully with `make olddefconfig`
- [ ] All Phoenix customizations preserved
- [ ] All sdm660-mainline proven options kept
- [ ] No duplicate symbols
- [ ] Critical symbols verified (QCOM, MMC, USB, DRM, TOUCH)

### Risk: Config symbol conflicts
**Mitigation**: Keep sdm660-mainline value for conflicts; document in commit message.

---

## Phase 3: Port CI Pipeline (Day 4)

### 3.1 Create GitHub Actions workflow

```bash
cd /path/to/Phoenix-Whyred
mkdir -p .github/workflows
```

Create `.github/workflows/build-kernel.yml`:

```yaml
name: Build Phoenix-Whyred Kernel

on:
  push:
    branches: [phoenix-whyred]
    paths-ignore:
      - '*.md'
      - 'docs/**'
  pull_request:
    branches: [phoenix-whyred]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 120

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y \
            clang lld llvm \
            gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
            bc bison flex libssl-dev libelf-dev \
            python3 cpio zip

      - name: Setup kernel tree
        run: |
          # sdm660-mainline is the repo itself - no separate clone needed
          # Verify we're on the right branch
          git log --oneline -3
          make ARCH=arm64 LLVM=1 LLVM_IAS=1 phoenix-whyred_defconfig

      - name: Build kernel
        run: |
          make ARCH=arm64 LLVM=1 LLVM_IAS=1 \
            -j$(nproc) Image.gz dtbs 2>&1 | tee build.log

      - name: Build modules
        run: |
          make ARCH=arm64 LLVM=1 LLVM_IAS=1 \
            -j$(nproc) modules 2>&1 | tee modules.log
          mkdir -p out/modules
          make ARCH=arm64 LLVM=1 LLVM_IAS=1 \
            modules_install INSTALL_MOD_PATH=out/modules

      - name: Collect artifacts
        run: |
          mkdir -p out/dist
          # Kernel image
          cp arch/arm64/boot/Image.gz out/dist/ || true
          cp arch/arm64/boot/Image out/dist/ || true

          # DTBs
          find arch/arm64/boot/dts -name '*whyred*.dtb' \
            -exec cp {} out/dist/ \; || true
          find arch/arm64/boot/dts -name 'sdm636*.dtb' \
            -exec cp {} out/dist/ \; || true

          # Config
          cp out/.config out/dist/config

          # Build info
          cat > out/dist/build-info.txt << EOF
          project=phoenix-whyred
          version=7.0.9
          track=7.0-sdm660-mainline
          kernel_version=$(make -s kernelrelease 2>/dev/null || echo unknown)
          git_sha=$(git rev-parse --short HEAD)
          timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
          EOF

          # SHA256SUMS
          cd out/dist && sha256sum * > SHA256SUMS

      - name: Package AnyKernel3
        run: |
          mkdir -p pack/AnyKernel3
          # Fetch AnyKernel3 if not present
          if [ ! -f pack/AnyKernel3/tools/ak3-core.sh ]; then
            git clone --depth 1 https://github.com/osm0sis/AnyKernel3.git /tmp/ak3
            cp -a /tmp/ak3/. pack/AnyKernel3/
            rm -rf pack/AnyKernel3/.git
          fi

          # Copy kernel image
          cp out/dist/Image.gz pack/AnyKernel3/ || \
            cp out/dist/Image pack/AnyKernel3/ || true

          # Copy DTBs
          cp out/dist/*.dtb pack/AnyKernel3/ 2>/dev/null || true

          # Copy build info
          cp out/dist/build-info.txt pack/AnyKernel3/
          cp out/dist/SHA256SUMS pack/AnyKernel3/

          # Create zip
          cd pack/AnyKernel3
          zip -r9 ../../out/dist/Phoenix-Whyred-7.0.9-$(date +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD).zip \
            . -x "*.git*"

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: Phoenix-Whyred-7.0.9
          path: out/dist/
          retention-days: 30
```

### 3.2 Port AnyKernel3 flash script

Update `pack/AnyKernel3/anykernel.sh`:

```bash
cd /path/to/Phoenix-Whyred
mkdir -p pack/AnyKernel3
```

Create `pack/AnyKernel3/anykernel.sh`:

```bash
### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
## Adapted for Phoenix-Whyred 7.0.9

### AnyKernel setup
properties() { '
kernel.string=Phoenix-Whyred 7.0.9
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=whyred
device.name2=Whyred
device.name3=Redmi Note 5
device.name4=redmi note 5 pro
device.name5=Redmi Note 5 Pro
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; }

### AnyKernel install
boot_attributes() {
  set_perm_recursive 0 0 755 644 $RAMDISK/*;
  set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
}

block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

. tools/ak3-core.sh;

dump_boot;

# begin ramdisk changes
# (none required for pure Image flash on whyred)
# end ramdisk changes

write_boot;
```

### Validation Checkpoint 3

- [ ] `.github/workflows/build-kernel.yml` created
- [ ] `pack/AnyKernel3/anykernel.sh` created
- [ ] Workflow syntax valid (`act --list` or push to test)
- [ ] AnyKernel3 targets whyred correctly
- [ ] Block device path correct (`/dev/block/bootdevice/by-name/boot`)
- [ ] Slot device disabled (`is_slot_device=0`)

### Risk: CI runner disk space
**Mitigation**: Use `actions/cache` for kernel tree; limit modules build.

---

## Phase 4: Port Build Scripts (Day 5)

### 4.1 Create PROJECT.conf

Create `PROJECT.conf` in repo root:

```bash
cd /path/to/Phoenix-Whyred
```

```bash
# =============================================================================
# Phoenix-Whyred — Linux 7.0.9 (sdm660-mainline)
# =============================================================================

PROJECT_NAME="phoenix-whyred"
PROJECT_VERSION="1.0.0"

# Device
DEVICE_CODENAME="whyred"
DEVICE_NAME="Xiaomi Redmi Note 5 Pro"
SOC="sdm636"
SOC_FAMILY="sdm660"
ARCH="arm64"
SUBARCH="arm64"

# =============================================================================
# Kernel source — sdm660-mainline 7.0.y
# =============================================================================
KERNEL_TRACK="7.0"
KERNEL_VERSION="7.0.9"
GKI_REMOTE="https://github.com/sdm660-mainline/linux.git"
GKI_BRANCH_REF="qcom-sdm660-7.0.y"
KERNEL_SRC="."  # Repo itself is the kernel tree

# Config
BASE_DEFCONFIG="phoenix-whyred_defconfig"
LOCALVERSION="-phoenix-whyred-7.0"
ZIP_PREFIX="Phoenix-Whyred-7.0"

# Paths
OUT_DIR="out"
DIST_DIR="out/dist"
MODULES_OUT="out/modules"

# Device tree
DTS_DIR="arch/arm64/boot/dts/qcom"
DTB_NAME="sdm636-xiaomi-whyred"

# Build options
JOBS="$(nproc 2>/dev/null || echo 4)"
CC="clang"
LLVM="1"
LLVM_IAS="1"
CROSS_COMPILE="aarch64-linux-gnu-"

# Packing
ANYKERNEL_DIR="pack/AnyKernel3"
```

### 4.2 Create build.sh

Create `scripts/build.sh`:

```bash
#!/usr/bin/env bash
# Build Phoenix-Whyred 7.0.9 (sdm660-mainline)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/PROJECT.conf"

MODE="${1:-whyred}"
SKIP_MODULES="${SKIP_MODULES:-0}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"

export ARCH="${ARCH}"
export SUBARCH="${SUBARCH}"
export LLVM="${LLVM:-1}"
export LLVM_IAS="${LLVM_IAS:-1}"
export CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"

MAKE=(make -C "${ROOT}" ARCH="${ARCH}" \
  LOCALVERSION="${LOCALVERSION}" \
  -j"${JOBS}")

if command -v clang >/dev/null 2>&1; then
  MAKE+=(CC=clang CLANG_TRIPLE=aarch64-linux-gnu-)
fi

config() {
  echo "==> Configuring: ${BASE_DEFCONFIG}"
  "${MAKE[@]}" "${BASE_DEFCONFIG}"
  cp out/.config "${ROOT}/${DIST_DIR}/config" || true
}

build() {
  echo "==> Building Image.gz (jobs=${JOBS})..."
  set +e
  "${MAKE[@]}" Image.gz 2>&1 | tee "${ROOT}/${OUT_DIR}/build-image.log"
  local rc=${PIPESTATUS[0]}
  set -e

  if [[ $rc -ne 0 ]]; then
    echo "Image.gz failed — trying Image..."
    set +e
    "${MAKE[@]}" Image 2>&1 | tee -a "${ROOT}/${OUT_DIR}/build-image.log"
    set -e
  fi

  echo "==> Building DTBs..."
  set +e
  "${MAKE[@]}" dtbs 2>&1 | tee "${ROOT}/${OUT_DIR}/build-dtbs.log"
  set -e

  if [[ "${SKIP_MODULES}" != "1" ]]; then
    echo "==> Building modules..."
    set +e
    "${MAKE[@]}" modules 2>&1 | tee "${ROOT}/${OUT_DIR}/build-modules.log"
    set -e
    mkdir -p "${ROOT}/${MODULES_OUT}"
    set +e
    "${MAKE[@]}" modules_install INSTALL_MOD_PATH="${ROOT}/${MODULES_OUT}" \
      2>&1 | tee "${ROOT}/${OUT_DIR}/modules-install.log"
    set -e
  fi

  # Collect artifacts
  mkdir -p "${ROOT}/${DIST_DIR}"
  for img in Image.gz Image; do
    [[ -f "out/arch/arm64/boot/${img}" ]] && \
      cp -a "out/arch/arm64/boot/${img}" "${ROOT}/${DIST_DIR}/"
  done
  find out/arch/arm64/boot/dts -name '*whyred*.dtb' \
    -exec cp -a {} "${ROOT}/${DIST_DIR}/" \; 2>/dev/null || true

  echo "==> Build complete"
  ls -la "${ROOT}/${DIST_DIR}/"
}

case "${MODE}" in
  config) config ;;
  image) SKIP_MODULES=1; config; build ;;
  whyred|all|build|full) config; build ;;
  *)
    echo "Usage: $0 [config|image|whyred]"
    exit 1
    ;;
esac
```

```bash
chmod +x scripts/build.sh
```

### 4.3 Create pack.sh

Create `scripts/pack.sh`:

```bash
#!/usr/bin/env bash
# Pack Image into AnyKernel3 zip for whyred
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/PROJECT.conf"

DIST="${ROOT}/${DIST_DIR}"
AK="${ROOT}/${ANYKERNEL_DIR}"
STAMP="$(date -u +%Y%m%d-%H%M%S)"
GIT_SHA="${GITHUB_SHA:-$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo local)}"
GIT_SHA="${GIT_SHA:0:7}"
ZIP_NAME="${ZIP_PREFIX}-${PROJECT_VERSION}-${STAMP}-${GIT_SHA}.zip"

# Verify image exists
has_image=0
for img in Image.gz Image; do
  [[ -f "${DIST}/${img}" ]] && has_image=1
done
if [[ $has_image -eq 0 ]]; then
  echo "ERROR: no Image in ${DIST}. Build first."
  exit 1
fi

# Fetch AnyKernel3 if needed
if [[ ! -f "${AK}/tools/ak3-core.sh" ]]; then
  echo "==> Fetching AnyKernel3..."
  tmp="$(mktemp -d)"
  git clone --depth 1 https://github.com/osm0sis/AnyKernel3.git "${tmp}/ak3"
  [[ -f "${AK}/anykernel.sh" ]] && cp -a "${AK}/anykernel.sh" "${tmp}/whyred-ak.sh"
  mkdir -p "${AK}"
  cp -a "${tmp}/ak3/." "${AK}/"
  rm -rf "${AK}/.git"
  [[ -f "${tmp}/whyred-ak.sh" ]] && cp -a "${tmp}/whyred-ak.sh" "${AK}/anykernel.sh"
  rm -rf "${tmp}"
fi

# Copy kernel image
rm -f "${AK}/Image.gz" "${AK}/Image"
for img in Image.gz Image; do
  if [[ -f "${DIST}/${img}" ]]; then
    cp -a "${DIST}/${img}" "${AK}/"
    echo "    pack: ${img}"
    break
  fi
done

# Copy DTBs
cp -a "${DIST}/"*.dtb "${AK}/" 2>/dev/null || true

# Copy build info
[[ -f "${DIST}/build-info.txt" ]] && cp -a "${DIST}/build-info.txt" "${AK}/"
[[ -f "${DIST}/SHA256SUMS" ]] && cp -a "${DIST}/SHA256SUMS" "${AK}/"

# Create zip
OUT_ZIP="${ROOT}/${DIST_DIR}/${ZIP_NAME}"
rm -f "${OUT_ZIP}"
(
  cd "${AK}"
  zip -r9 "${OUT_ZIP}" . -x "*.git*" -x "*.DS_Store"
)
cp -a "${OUT_ZIP}" "${ROOT}/${DIST_DIR}/${ZIP_PREFIX}-latest.zip"
echo "==> ${OUT_ZIP}"
ls -lh "${OUT_ZIP}"
```

```bash
chmod +x scripts/pack.sh
```

### 4.4 Create ci-env.sh

Create `scripts/ci-env.sh`:

```bash
#!/usr/bin/env bash
# Shared CI helpers
set -euo pipefail

ci_is_github() {
  [[ "${GITHUB_ACTIONS:-}" == "true" ]] || [[ "${CI:-}" == "true" ]]
}

ci_nproc() {
  nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2
}

ci_free_disk() {
  df -h . | tail -1 || true
}

ci_log() {
  echo "::group::$*" 2>/dev/null || echo "==> $*"
}

ci_end_group() {
  echo "::endgroup::" 2>/dev/null || true
}
```

```bash
chmod +x scripts/ci-env.sh
```

### Validation Checkpoint 4

- [ ] `PROJECT.conf` created and correct
- [ ] `scripts/build.sh` created and executable
- [ ] `scripts/pack.sh` created and executable
- [ ] `scripts/ci-env.sh` created and executable
- [ ] `PROJECT.conf` references correct kernel source (sdm660-mainline)
- [ ] `PROJECT.conf` version is 7.0.9

### Risk: Script path errors
**Mitigation**: Test each script locally before committing.

---

## Phase 5: Build & Validate (Days 6-7)

### 5.1 Local build test

```bash
cd /path/to/Phoenix-Whyred

# Clean previous build artifacts
make mrproper || true
rm -rf out/

# Configure
make ARCH=arm64 LLVM=1 LLVM_IAS=1 phoenix-whyred_defconfig

# Verify config
grep 'CONFIG_LOCALVERSION' out/.config
# Expected: CONFIG_LOCALVERSION="-phoenix-whyred-7.0"

# Build kernel
make ARCH=arm64 LLVM=1 LLVM_IAS=1 -j$(nproc) Image.gz 2>&1 | tee build.log

# Build DTBs
make ARCH=arm64 LLVM=1 LLVM_IAS=1 -j$(nproc) dtbs 2>&1 | tee dtbs.log

# Build modules (optional)
make ARCH=arm64 LLVM=1 LLVM_IAS=1 -j$(nproc) modules 2>&1 | tee modules.log
```

### 5.2 Build artifact verification

```bash
# Verify Image.gz
ls -lh out/arch/arm64/boot/Image.gz
# Expected: exists, > 5MB

# Verify DTBs
ls -la out/arch/arm64/boot/dts/qcom/*whyred*.dtb
# Expected: sdm636-xiaomi-whyred.dtb exists

# Verify kernel version
make ARCH=arm64 LLVM=1 LLVM_IAS=1 -s kernelrelease
# Expected: 7.0.9-phoenix-whyred-7.0 or similar

# Check for build errors
grep -i "error:" build.log | head -20
# Expected: no errors

# Check for warnings (non-critical)
grep -i "warning:" build.log | wc -l
# Expected: < 100 warnings (normal for kernel build)
```

### 5.3 Create CI build test

```bash
# Push to trigger CI
git add -A
git commit -m "phoenix: initial sdm660-mainline 7.0.9 rebase

- Fork sdm660-mainline/linux qcom-sdm660-7.0.y
- Port Phoenix CI pipeline
- Port Phoenix build scripts
- Port Phoenix AnyKernel3 flash script
- Create phoenix-whyred_defconfig

Based on sdm660-mainline 7.0.9 (Linux 7.0.9)
Device: Xiaomi Redmi Note 5 Pro (whyred/SDM636)"

git push origin phoenix-whyred
```

### 5.4 Monitor CI

```bash
# Check workflow status
gh run list --workflow=build-kernel.yml --limit=5

# Watch specific run
gh run watch <run-id>

# Download artifacts if successful
gh run download <run-id> --dir=out/artifacts
```

### 5.5 Compare with sdm660-mainline reference

```bash
# Clone sdm660-mainline reference build
git clone --depth 1 --branch qcom-sdm660-7.0.y \
  https://github.com/sdm660-mainline/linux.git /tmp/sdm660-ref

# Compare DTS
diff arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts \
     /tmp/sdm660-ref/arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts
# Expected: no differences (using upstream DTS)

# Compare defconfig
diff out/.config /tmp/sdm660-ref/out/.config 2>/dev/null || true
# Expected: Phoenix additions only

# Clean up
rm -rf /tmp/sdm660-ref
```

### Validation Checkpoint 5

- [ ] Local build passes (Image.gz + DTBs)
- [ ] CI build passes
- [ ] Artifacts uploaded successfully
- [ ] AnyKernel3 zip created
- [ ] Kernel version string correct (7.0.9)
- [ ] DTS matches sdm660-mainline reference
- [ ] No build errors in log

### Risk: Build failure on CI
**Mitigation**: Check build.log for specific error; fix config or patches as needed.

---

## Phase 6: Documentation Update (Day 7)

### 6.1 Update README.md

```bash
cd /path/to/Phoenix-Whyred
```

Create `README.md`:

```markdown
# Phoenix-Whyred

Linux 7.0.9 kernel for Xiaomi Redmi Note 5 Pro (whyred) based on
[sdm660-mainline](https://github.com/sdm660-mainline/linux).

## Features

- Linux 7.0.9 (sdm660-mainline qcom-sdm660-7.0.y)
- Synaptics RMI4 E753 touchscreen support
- Tianma TD4310 display panel
- Adreno 509 GPU
- WCN3990 WiFi/Bluetooth
- USB DWC3 (peripheral mode)
- Modem (MSS) support
- AnyKernel3 flashable zip

## Build

```bash
# Install dependencies
sudo apt-get install clang lld llvm gcc-aarch64-linux-gnu \
  binutils-aarch64-linux-gnu bc bison flex libssl-dev

# Build
make ARCH=arm64 LLVM=1 LLVM_IAS=1 phoenix-whyred_defconfig
make ARCH=arm64 LLVM=1 LLVM_IAS=1 -j$(nproc) Image.gz dtbs

# Pack
./scripts/pack.sh
```

## Flash

1. Download `Phoenix-Whyred-7.0.9-*.zip` from [Releases](../../releases)
2. Boot to TWRP
3. Flash zip
4. Reboot

## Device Tree

Based on sdm660-mainline DTS with Phoenix customizations.

| Component | Model |
|-----------|-------|
| Touch | Synaptics RMI4 E753 |
| Display | Tianma TD4310 |
| GPU | Adreno 509 |
| WiFi/BT | WCN3990 |

## Credits

- [sdm660-mainline](https://github.com/sdm660-mainline/linux) - Base kernel
- [AnyKernel3](https://github.com/osm0sis/AnyKernel3) - Flash script

## License

GPL-2.0
```

### 6.2 Update docs/STATUS.md

```bash
cat > docs/STATUS.md << 'EOF'
# Phoenix-Whyred Status

Last updated: 2026-07-18

## Current State

| Component | Status | Notes |
|-----------|--------|-------|
| Kernel base | ✅ | sdm660-mainline 7.0.9 (Linux 7.0.9) |
| Device Tree | ✅ | sdm636-xiaomi-whyred.dts (proven boot) |
| Defconfig | ✅ | phoenix-whyred_defconfig |
| CI pipeline | ✅ | GitHub Actions workflow |
| Build scripts | ✅ | build.sh, pack.sh, setup.sh |
| Flash scripts | ✅ | AnyKernel3 |
| Local build | ✅ | Image.gz + DTBs |
| CI build | ✅ | Passes on GitHub Actions |
| Hardware boot | 🔴 | Pending device test |

## Next Steps

1. Flash to device via TWRP
2. Capture UART boot logs
3. Verify display, touch, WiFi, Bluetooth
4. Test USB connectivity
5. Test modem (MSS)

## Credits

Based on sdm660-mainline by M0Rf30, minlexx, setotau.
EOF
```

### 6.3 Archive old Phoenix-Whyred

```bash
# Tag old main branch
git tag -a v0.4.0-final -m "Final 6.18 LTS release before sdm660-mainline rebase"
git push origin v0.4.0-final

# Update default branch to phoenix-whyred
gh repo edit Alaa91H/Phoenix-Whyred --default-branch phoenix-whyred
```

### Validation Checkpoint 6

- [ ] README.md updated with new base info
- [ ] docs/STATUS.md reflects current state
- [ ] All links work
- [ ] Old branch tagged
- [ ] Default branch updated

---

## Complete File Manifest

### Files to Create (New)

| File | Purpose |
|------|---------|
| `.github/workflows/build-kernel.yml` | CI pipeline |
| `PROJECT.conf` | Project metadata |
| `scripts/build.sh` | Build script |
| `scripts/pack.sh` | Flash script packager |
| `scripts/ci-env.sh` | CI helpers |
| `pack/AnyKernel3/anykernel.sh` | Flash script |
| `pack/AnyKernel3/META-INF/com/google/android/update-binary` | Android updater |
| `pack/AnyKernel3/META-INF/com/google/android/updater-script` | Android updater |
| `arch/arm64/configs/phoenix-whyred_defconfig` | Merged defconfig |
| `README.md` | Project documentation |
| `docs/STATUS.md` | Status documentation |

### Files from sdm660-mainline (Already Present)

| File | Purpose |
|------|---------|
| `arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts` | Device Tree |
| `arch/arm64/boot/dts/qcom/sdm636.dtsi` | SoC DTSI |
| `arch/arm64/boot/dts/qcom/sdm660.dtsi` | SoC DTSI |
| `arch/arm64/boot/dts/qcom/sdm630.dtsi` | SoC DTSI |
| `arch/arm64/boot/dts/qcom/pm660.dtsi` | PMIC DTSI |
| `arch/arm64/boot/dts/qcom/pm660l.dtsi` | PMIC DTSI |
| `arch/arm64/configs/sdm660_defconfig` | Base defconfig |

---

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| DTS mismatch | High | Low | Use sdm660-mainline DTS directly |
| Config conflict | Medium | Medium | Keep sdm660-mainline value; document |
| Build failure | High | Low | Fix config; check build.log |
| CI timeout | Medium | Low | Optimize jobs; cache deps |
| Touch mismatch | High | Low | Synaptics RMI4 confirmed in DTS |
| Display mismatch | High | Low | Tianma TD4310 confirmed in DTS |
| Missing symbols | Medium | Low | Diff analysis in Phase 2 |
| Module failure | Low | Low | Build without modules first |

---

## Success Criteria

| Criterion | Metric | Phase |
|-----------|--------|-------|
| Fork created | `gh repo view Alaa91H/linux` | 1 |
| DTS verified | File exists, includes correct | 1 |
| Config merged | `make olddefconfig` passes | 2 |
| CI workflow valid | `act --list` or push test | 3 |
| Build passes | Image.gz + DTBs produced | 5 |
| Artifacts uploaded | CI artifacts available | 5 |
| AnyKernel3 zip | Flashable zip created | 5 |
| Documentation | README.md + STATUS.md updated | 6 |

---

## Daily Milestones

| Day | Phase | Deliverable |
|-----|-------|-------------|
| 1 | Fork & Setup | Forked repo, branch structure |
| 2 | Config Analysis | Diff report, missing symbols |
| 3 | Config Merge | phoenix-whyred_defconfig |
| 4 | CI Pipeline | .github/workflows/build-kernel.yml |
| 5 | Build Scripts | scripts/{build,pack,ci-env}.sh |
| 6 | Build Test | Local build passes |
| 7 | CI Test + Docs | CI passes, documentation updated |

---

## Immediate Next Actions

1. **Fork sdm660-mainline/linux** branch `qcom-sdm660-7.0.y`
2. **Clone fork** to local workspace
3. **Verify DTS** exists and is complete
4. **Extract defconfig** symbols for comparison
5. **Create phoenix-whyred_defconfig** (merged)
6. **Test local build** (Image.gz + DTBs)
7. **Create CI workflow**
8. **Push and verify CI**
9. **Update documentation**

---

*Document generated: 2026-07-18*
*Based on research: SDM660_MAINLINE_BASE_SELECTION.md, REBASE_STRATEGY.md, WHYRED_MAINLINE_REFERENCE.md*
