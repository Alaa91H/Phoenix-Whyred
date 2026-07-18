# STEP 9 — Final Report: First Build Validation

> **Date**: 2026-07-18
> **CI Run**: `29636961537` (workflow_dispatch)
> **Result**: Build PASSED | Config validation FAILED (expected for P0-only)

---

## 1. Kernel Commit

| Field | Value |
|---|---|
| Source | Linux Mainline 6.18 LTS (kernel.org) |
| Tag | `v6.18` (`f7b88edb52c8dd01b7e576390d658ae6eef0e134`) |
| Kernel Version | `6.18.0-dirty` (dirty due to project overlay DTS) |
| Cloned At | `.src/linux-6.18` |

## 2. Phoenix Commit

| Field | Value |
|---|---|
| Commit | `e841299` (docs: add bringup plan, DT audit, minimal config, fix migration matrix) |
| Branch | `main` |
| Previous | `53794cd` (Driver migration matrix) |

## 3. Toolchain Versions

| Component | Version |
|---|---|
| Compiler | Ubuntu Clang 18.1.3 (`18.1.3-1ubuntu1`) |
| Cross-compiler | `aarch64-linux-gnu-gcc 13.3.0` (Ubuntu cross1) |
| LLVM | 18.1.3 |
| Linker | `ld.lld` (LLVM) |
| Assembler | `llvm-objcopy`, `llvm-objdump` |
| Flags | `CC=clang LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu-` |

## 4. Final Config

| Field | Value |
|---|---|
| Config Lines | 11,770 |
| Config Hash | `5db7c2d97a185305f06d6f2f523192d20d050b314fd62798cf3a0e43ef70d8e9` |
| Merge Order | `defconfig` → `sdm660.config` → `whyred.config` → `lts-6.18.config` → `android-gki.config` → `stage1-uart.config` → `stage2-mmc.config` → `stage3-usb.config` → `stage4-display.config` → `stage5-touch.config` |
| Redefinitions | 29 config symbol redefinitions across fragments (expected — override semantics) |
| Override Warning | `.config:11746: warning: override: reassigning to symbol WHYRED_DRIVERS` (stage1 sets it, whyred.config comments it out, stage fragments re-enable) |

### Key Config Values

| Config | Value | Source |
|---|---|---|
| `CONFIG_64BIT` | `y` | defconfig |
| `CONFIG_ARCH_QCOM` | `y` | sdm660.config |
| `CONFIG_SDM_GCC_660` | `y` | sdm660.config |
| `CONFIG_PINCTRL_SDM660` | `y` | sdm660.config |
| `CONFIG_SERIAL_QCOM_GENI` | `y` | sdm660.config |
| `CONFIG_SERIAL_QCOM_GENI_CONSOLE` | `y` | sdm660.config |
| `CONFIG_MMC_SDHCI_MSM` | `y` | sdm660.config |
| `CONFIG_USB_DWC3` | `y` | sdm660.config |
| `CONFIG_USB_DWC3_QCOM` | `y` | sdm660.config |
| `CONFIG_PHY_QCOM_QUSB2` | `y` | sdm660.config |
| `CONFIG_DRM_MSM` | `=m` | stage4-display.config |
| `CONFIG_DRM_MSM_DSI` | `=m` | stage4-display.config |
| `CONFIG_FB_SIMPLE` | `y` | stage4-display.config |
| `CONFIG_MODULES` | `y` | android-gki.config |

## 5. Build Result

| Field | Value |
|---|---|
| Status | **PASSED** |
| Duration | ~31 min (08:12:50 → 08:43:34) |
| CI Run ID | `29636961537` |
| Jobs | 4 (parallel make) |
| Patches Applied | 0 (clean mainline) |
| BTF | Compiled (`kernel/bpf/btf.o` present) |
| Modules | Not built (`SKIP_MODULES=1` in image mode) |

## 6. BTF Status

| Field | Value |
|---|---|
| `kernel/bpf/btf.o` | Built successfully |
| `kernel/bpf/btf_iter.o` | Built successfully |
| `kernel/bpf/btf_relocate.o` | Built successfully |
| Config | BTF was compiled as part of mainline defconfig |

## 7. DTB Validation

| DTB | Size | Valid FDT | Target Match |
|---|---|---|---|
| `sdm636-xiaomi-whyred.dtb` | OK | Yes | Yes (matches target device) |
| `sdm636-sony-xperia-ganges-mermaid.dtb` | OK | Yes | Yes |
| `sdm660-xiaomi-lavender.dtb` | OK | Yes | — |
| **Total DTBs** | **3** | | |

### DTB Content (sdm636-xiaomi-whyred.dtb)

| Field | Status |
|---|---|
| Model string | Present (`Xiaomi Redmi Note 5 Pro`) |
| Compatible | `xiaomi,whyred` |
| `qcom,msm-id` | Present |
| `qcom,board-id` | Present |
| pon_pwrkey/pon_resin | Fallback defined in `#if 0` block (needs mainline fix) |

## 8. Boot Artifact

| Artifact | Size | Format |
|---|---|---|
| `Image.gz` | 15,336,387 bytes (~14.6 MB) | gzip compressed ARM64 Image |
| `sdm636-xiaomi-whyred.dtb` | Valid FDT | Device Tree Blob v17 |
| `build-info.txt` | Present | Build metadata |
| `SHA256SUMS` | Present | Artifact checksums |
| Flashable Zip | Not yet | `pack.sh` not run |

## 9. Config Validation Results

### PASSED (20 checks)

| Check | Value |
|---|---|
| `CONFIG_64BIT=y` | ARM64 |
| `CONFIG_ARCH_QCOM=y` | Qualcomm SoC |
| `CONFIG_COMMON_CLK_QCOM=y` | QCOM clocks |
| `CONFIG_PINCTRL_SDM660=y` | SDM660 pinctrl |
| `CONFIG_SDM_GCC_660=y` | SDM660 GCC |
| `CONFIG_QCOM_RPMH=y` | RPMH |
| `CONFIG_SERIAL_EARLYCON=y` | Early console |
| `CONFIG_MMC=y` | MMC core |
| `CONFIG_MMC_SDHCI=y` | SDHCI |
| `CONFIG_MMC_SDHCI_MSM=y` | QCOM SDHCI |
| `CONFIG_MMC_BLOCK=y` | MMC block device |
| `CONFIG_USB=y` | USB core |
| `CONFIG_USB_DWC3=y` | DWC3 controller |
| `CONFIG_USB_DWC3_QCOM=y` | DWC3 QCOM glue |
| `CONFIG_PHY_QCOM_QUSB2=y` | QUSB2 PHY |
| `CONFIG_DRM=y` | DRM core |
| `CONFIG_DRM_MSM=m` | MSM DRM |
| `CONFIG_FB_SIMPLE=y` | Simple framebuffer |
| `CONFIG_INPUT=y` | Input core |
| `CONFIG_INPUT_TOUCHSCREEN=y` | Touchscreen subsystem |
| `CONFIG_ANDROID_BINDER_IPC=y` | Binder IPC |
| `CONFIG_ANDROID_BINDERFS=y` | BinderFS |
| `CONFIG_SECURITY_SELINUX=y` | SELinux |
| `CONFIG_CMA=y` | CMA |
| `CONFIG_DMA_CMA=y` | DMA CMA |
| `CONFIG_MODULES=y` | Loadable modules |

### MISSING (5 — expected for P0-only config)

| Config | Status | Fix Stage |
|---|---|---|
| `CONFIG_SERIAL_MSM_GENI_SERIAL` | MISSING | validate-config.sh uses downstream name; upstream is `CONFIG_SERIAL_QCOM_GENI=y` — **already present** |
| `CONFIG_ZRAM` | MISSING | P2 — needed for swap, not first boot |
| `CONFIG_DMABUF_HEAPS` | MISSING | P2 — needed for camera/GPU, not first boot |
| `CONFIG_WHYRED_DRIVERS` | MISSING | Expected — Kconfig menu requires proper `drivers/whyred/Kconfig` integration |
| `CONFIG_WHYRED_BOARD` | MISSING | Expected — board glue driver needs full Kconfig entry |

### Validation Verdict

```
Config validation: errors=5 warnings=0
FAILED — 5 critical config(s) missing
```

**Note**: Build validation **PASSED**. Config validation failures are expected because:
1. `CONFIG_SERIAL_MSM_GENI_SERIAL` is a downstream name — upstream uses `CONFIG_SERIAL_QCOM_GENI` (already `=y`)
2. `CONFIG_ZRAM` and `CONFIG_DMABUF_HEAPS` are P2 items — intentionally excluded from minimal first boot
3. `CONFIG_WHYRED_DRIVERS` and `CONFIG_WHYRED_BOARD` require Kconfig menu integration in `drivers/whyred/Kconfig` — custom driver not yet wired into mainline Kconfig

## 10. Remaining P0 Blockers

| # | Blocker | Impact | Fix |
|---|---|---|---|
| 1 | **pon_pwrkey/pon_resin missing** in upstream pm660.dtsi | PWR_KEY/RESET button not functional | Fallback DTS added; upstream patch needed |
| 2 | **WHYRED_DRIVERS Kconfig** not wired | Custom driver not enabled | Wire `drivers/whyred/Kconfig` into menu |
| 3 | **WHYRED_BOARD Kconfig** not wired | Board glue driver not enabled | Wire `drivers/whyred/Kconfig` into menu |
| 4 | **validate-config.sh downstream names** | False positives in validation | Update script to check upstream names |
| 5 | **No flashable zip yet** | Cannot flash to device | Run `pack.sh` after boot testing |

## 11. First Boot Procedure

### Required Files

| File | Location |
|---|---|
| Boot Image | `out/dist/Image.gz` + `out/dist/sdm636-xiaomi-whyred.dtb` |
| AnyKernel3 | `pack/AnyKernel3/` |
| Flash Tool | `adb reboot bootloader` → `fastboot flash boot boot.img` |

### Flash Sequence

```bash
# 1. Pack boot image
./scripts/pack.sh

# 2. Flash via fastboot
adb reboot bootloader
fastboot flash boot out/dist/Phoenix-Whyred-6.18-*.zip
fastboot reboot

# 3. Monitor UART console
# Expected: Kernel boots → init starts → shell prompt
# If stuck: check UART output for panic/oops
```

### Expected Boot Stages

| Stage | What Happens |
|---|---|
| Bootloader | Loads Image.gz + DTB |
| Kernel Init | Decompresses, starts PID 1 |
| Device Tree | SDM636 platform probes |
| Console | UART serial output (`ttyMSM0`) |
| Storage | eMMC detected (`mmcblk0`) |
| USB | DWC3 controller ready |
| Display | Simple framebuffer (DRM_MSM=m) |
| Touch | Novatek NT36XXX (stage5) |

## 12. CI Build Provenance

| Field | Value |
|---|---|
| Repository | `Alaa91H/Phoenix-Whyred` |
| Branch | `main` |
| Trigger | `workflow_dispatch` |
| Run ID | `29636961537` |
| Runner | `ubuntu-latest` |
| Build Mode | `image` (modules not built) |
| Create Release | `false` |
| Free Disk | Yes (freed ~50 GB) |
| Dependencies | Installed (clang, llvm, gcc-aarch64-linux-gnu, dtc, zip, rsync, python3) |

## 13. Next Steps

### Immediate (P0)

1. **Test boot on device** — Flash Image.gz + DTB via fastboot, verify UART output
2. **Fix pon_pwrkey/pon_resin** — Upstream patch to pm660.dtsi
3. **Wire WHYRED_DRIVERS/BOARD Kconfig** — Proper Kconfig integration
4. **Fix validate-config.sh** — Update to check upstream symbol names

### Short Term (P1)

5. **Enable display** — DRM_MSM=y (currently =m)
6. **Enable touch** — Novatek NT36XXX driver
7. **Enable GPU** — Freedreno Adreno 509
8. **Build flashable zip** — Run pack.sh, test on device

### Medium Term (P2)

9. **Enable Wi-Fi** — ath10k driver
10. **Enable battery** — QCOM SMB2 charger
11. **Enable ZRAM** — Swap for Android
12. **Enable camera** — Qualcomm camera subsystem

---

**Status**: First mainline 6.18 build for whyred **PASSED**. Ready for device boot testing.

---

## STRATEGIC RESET — sdm660-mainline 7.0.9 (2026-07-18)

> **IMPORTANT**: This project has been rebased onto sdm660-mainline Linux 7.0.9.
> See `docs/research/NEW_PROJECT_DIRECTION.md` for details.

| Field | Old | New |
|-------|-----|-----|
| Kernel Base | Vanilla Linux 6.18 | sdm660-mainline Linux 7.0.9 |
| Source | kernel.org | github.com/sdm660-mainline/linux |
| Branch | v6.18 tag | qcom-sdm660-7.0.y |
| DTS | Custom reconstruction | Proven sdm660-mainline DTS |
| Touch | Novatek NT36672C (custom) | Synaptics RMI4 E753 (proven) |
| Display | Custom | Tianma TD4310 (proven) |
| CI Run (new) | `29636961537` | `29662770941` (PASSED, 30min) |
| Artifact | `whyred-6.18-15` | `Phoenix-Whyred-7.0.9` |
| Zip Size | 18 MB | 13.6 MB |
| Kernel Version | 6.18.0-dirty | 7.0.9-phoenix-whyred-7.0+ |
| Build Time | ~35min | ~30min |
| Repository | Alaa91H/Phoenix-Whyred (main) | Alaa91H/linux (phoenix-whyred) |
