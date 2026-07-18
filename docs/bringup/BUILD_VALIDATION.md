# Build Validation Checklist

> **Run after successful build. Validates all artifacts are correct.**
> **Created**: 2026-07-18

## Pre-Build Requirements

- [ ] Linux Mainline 6.18 source cloned at `.src/linux-6.18`
- [ ] Clang/LLVM toolchain available
- [ ] `aarch64-linux-gnu-` cross-compiler available
- [ ] Device Tree source compiles without errors
- [ ] Config merges without "symbol not found" errors

## Validation Checks

### 1. Architecture
```bash
file out/dist/Image.gz
# Expected: "data" (compressed kernel image)
```
- [ ] File exists
- [ ] Non-zero size
- [ ] Compressed format

### 2. Kernel Version
```bash
strings out/dist/Image.gz | grep -i "linux version"
# Expected: "Linux version 6.18.x"
```
- [ ] Version string present
- [ ] Matches 6.18.x

### 3. Image Format
```bash
# After decompression:
gunzip -c out/dist/Image.gz | file -
# Expected: "Linux kernel ARM64 boot Image"
```
- [ ] ARM64 format confirmed

### 4. DTB Validation
```bash
file out/dist/sdm636-xiaomi-whyred.dtb
# Expected: "Device Tree Blob version 17, size=..."
```
- [ ] DTB exists
- [ ] Valid Device Tree Blob
- [ ] Version 17 (current DT spec)

### 5. DTB Content Validation
```bash
dtc -I dtb -O dts out/dist/sdm636-xiaomi-whyred.dtb 2>/dev/null | grep -i "whyred"
# Expected: model = "Xiaomi Redmi Note 5 Pro"
```
- [ ] `model` string present
- [ ] `compatible` string includes "xiaomi,whyred"
- [ ] `qcom,msm-id` present (value 345)
- [ ] `qcom,board-id` present

### 6. Required Configuration
```bash
grep -c "=y" out/dist/config
# Should have 200+ =y options
```
- [ ] `CONFIG_ARCH_QCOM=y`
- [ ] `CONFIG_SERIAL_QCOM_GENI=y`
- [ ] `CONFIG_SERIAL_QCOM_GENI_CONSOLE=y`
- [ ] `CONFIG_MMC_SDHCI_MSM=y`
- [ ] `CONFIG_USB_DWC3=y`
- [ ] `CONFIG_PINCTRL_SDM660=y`
- [ ] `CONFIG_SDM_GCC_660=y`
- [ ] `CONFIG_OF=y`
- [ ] `CONFIG_MODULES=y`

### 7. Config Hash
```bash
sha256sum out/dist/config
```
- [ ] Hash recorded in build-info.txt

### 8. Build Metadata
```bash
cat out/dist/build-info.txt
```
- [ ] kernel_version matches expected
- [ ] toolchain recorded
- [ ] timestamp present
- [ ] config_fragments listed

### 9. SHA256SUMS
```bash
sha256sum -c out/dist/SHA256SUMS
```
- [ ] All checksums pass

### 10. Output Artifacts
```
out/dist/
├── Image.gz              (kernel image)
├── sdm636-xiaomi-whyred.dtb  (device tree)
├── config                (final .config)
├── build-info.txt        (provenance)
├── SHA256SUMS            (checksums)
└── localversion.txt      (version info)
```
- [ ] All files present
- [ ] File sizes reasonable (Image.gz: ~8-15MB, DTB: ~100-300KB)

## Failure Classification

If build fails, classify the error:

| Category | Example Error | Fix |
|---|---|---|
| **A. Config problem** | "symbol not found" | Fix config fragment |
| **B. DT problem** | "undefined label" | Fix DTS reference |
| **C. Toolchain problem** | "clang: not found" | Install toolchain |
| **D. API problem** | "implicit declaration" | Patch driver code |
| **E. Custom code** | Error in drivers/whyred/ | Fix or remove driver |
| **F. Missing driver** | "module not found" | Enable config or add driver |
