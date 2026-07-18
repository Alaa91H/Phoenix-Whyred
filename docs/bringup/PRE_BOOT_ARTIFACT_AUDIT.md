# Pre-Boot Artifact Audit

> **Date**: 2026-07-18
> **Purpose**: Verify every artifact before first physical boot attempt
> **Status**: READY FOR FLASH

---

## 1. Exact Kernel Image Being Tested

| Field | Value |
|---|---|
| File | `Image.gz` |
| Size | 15,336,387 bytes (~14.6 MB) |
| Format | gzip-compressed ARM64 Linux kernel image |
| Kernel Version | `6.18.0-dirty` |
| LOCALVERSION | `-phoenix-whyred-6.18-0.4.0-dev` |
| Full Version | `Linux version 6.18.0-dirty-phoenix-whyred-6.18-0.4.0-dev` |
| Source | Mainline Linux 6.18 LTS (kernel.org, tag `v6.18`) |
| Compiler | Ubuntu Clang 18.1.3 |
| Flags | `CC=clang LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu-` |

## 2. Exact DTB Being Tested

| Field | Value |
|---|---|
| File | `sdm636-xiaomi-whyred.dtb` |
| Format | Device Tree Blob version 17 (valid FDT) |
| Model | `Xiaomi Redmi Note 5 Pro` |
| Compatible | `"xiaomi,whyred", "qcom,sdm636", "qcom,sdm660"` |
| qcom,msm-id | 345 (SDM636) |
| qcom,board-id | `<0x30008 0>`, `<0x10008 0>` |
| qcom,pmic-id | PM660 + PM660L triplet |
| Console | BLSP1 UART2 @ `0x0c170000` @ 115200 |
| DTB compilation | No errors or warnings |

## 3. Kernel Commit

| Field | Value |
|---|---|
| Source | `https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git` |
| Branch/Tag | `v6.18` |
| Pinned Commit | `v6.18` (tag `f7b88edb52c8dd01b7e576390d658ae6eef0e134`) |
| Actual Checkout | `7d0a66e4bb9081d75c82ec4957c50034cb0ea449` (branch HEAD for v6.18 tag) |
| Patches Applied | 0 (clean mainline) |

## 4. Phoenix Commit

| Field | Value |
|---|---|
| Commit | `e841299` |
| Message | `docs: add bringup plan, DT audit, minimal config, fix migration matrix` |
| Branch | `main` |
| Previous | `53794cd` (Driver migration matrix) |

## 5. Configuration

| Field | Value |
|---|---|
| Config Lines | 11,770 |
| Config Hash | `5db7c2d97a185305f06d6f2f523192d20d050b314fd62798cf3a0e43ef70d8e9` |
| Merge Order | `defconfig` → `sdm660.config` → `whyred.config` → `lts-6.18.config` → `android-gki.config` → `stage1-uart.config` → `stage2-mmc.config` → `stage3-usb.config` → `stage4-display.config` → `stage5-touch.config` |

### Key Config Values for Boot

| Config | Value | Purpose |
|---|---|---|
| `CONFIG_64BIT` | `y` | ARM64 |
| `CONFIG_ARCH_QCOM` | `y` | Qualcomm SoC support |
| `CONFIG_SDM_GCC_660` | `y` | Clock controller |
| `CONFIG_PINCTRL_SDM660` | `y` | GPIO/pinctrl |
| `CONFIG_SERIAL_QCOM_GENI` | `y` | UART serial |
| `CONFIG_SERIAL_QCOM_GENI_CONSOLE` | `y` | Serial console |
| `CONFIG_SERIAL_EARLYCON` | `y` | Early console |
| `CONFIG_MMC_SDHCI_MSM` | `y` | eMMC storage |
| `CONFIG_MMC_BLOCK` | `y` | Block device |
| `CONFIG_EXT4_FS` | `y` | Filesystem |
| `CONFIG_USB` | `y` | USB core |
| `CONFIG_USB_DWC3` | `y` | USB controller |
| `CONFIG_USB_DWC3_QCOM` | `y` | Qualcomm USB glue |
| `CONFIG_PHY_QCOM_QUSB2` | `y` | USB PHY |
| `CONFIG_DRM_MSM` | `=m` | Display (module) |
| `CONFIG_FB_SIMPLE` | `y` | Simple framebuffer |
| `CONFIG_MODULES` | `y` | Loadable modules |
| `CONFIG_ANDROID_BINDER_IPC` | `y` | Android binder |
| `CONFIG_SECURITY_SELINUX` | `y` | SELinux |
| `CONFIG_CMA` | `y` | Contiguous memory allocator |
| `CONFIG_DMA_CMA` | `y` | DMA CMA |

## 6. Image Architecture

| Field | Value |
|---|---|
| Architecture | ARM64 (AArch64) |
| Endianness | Little-endian |
| Compression | gzip |
| Format | Linux kernel ARM64 boot image (compressed) |

## 7. DTB Compatible String

```dts
compatible = "xiaomi,whyred", "qcom,sdm636", "qcom,sdm660";
```

The bootloader uses `qcom,msm-id` (345) and `qcom,board-id` (`0x30008`/`0x10008`) to match the device. The `compatible` string is for kernel driver matching.

## 8. Boot Image Format

| Field | Value |
|---|---|
| Package Format | AnyKernel3 zip |
| Zip Name | `Phoenix-Whyred-6.18-0.4.0-dev-20260718-084334-e841299.zip` |
| Zip Size | 18 MB |
| CI Artifact Name | `whyred-6.18-15` |
| CI Artifact ID | `8427693766` |
| CI Artifact SHA256 | `0dabf91c402bcc8d915ecf91c1c10de7558aca984bb3c23549abfe8d5bfe406a` |
| Total CI Upload | 103,182,971 bytes (38 files) |

### Zip Contents

| File | Size | Purpose |
|---|---|---|
| `Image.gz` | 14.6 MB | Compressed kernel |
| `sdm636-xiaomi-whyred.dtb` | ~70 KB | Device tree blob |
| `ramdisk/placeholder` | 0 bytes | Empty (preserves device ramdisk) |
| `anykernel.sh` | AnyKernel3 config | Flash script |
| `tools/ak3-core.sh` | Core flash logic | Handles boot image patching |
| `tools/magiskboot` | Boot image tool | Extracts/creates boot images |
| `build-info.txt` | Provenance | Build metadata |
| `SHA256SUMS` | Checksums | Artifact verification |
| `version` | Version info | Provenance |

## 9. Boot Image Header Version

| Field | Value |
|---|---|
| Header Version | **Inherited from device's existing boot image** |
| AnyKernel3 Behavior | Reads existing boot partition → extracts kernel → replaces with Image.gz → writes back |
| Expected Header | v1 (Qualcomm SDM636, Android 9 stock) |
| Page Size | Inherited (typically 2048 for Qualcomm SDM636) |
| Kernel Offset | Inherited from existing boot image |
| Base Address | Inherited from existing boot image |

**Note**: AnyKernel3 does NOT construct a new boot image header. It operates on the existing boot image in the device's boot partition. The kernel binary (Image.gz) is inserted into the existing boot image structure.

## 10. Page Size

Inherited from device's existing boot image. Typical for SDM636:
- Page size: **2048 bytes**
- Kernel offset: `0x00008000`
- Base address: `0x80000000`

## 11. Kernel Offset

Inherited from existing boot image. Standard Qualcomm value: `0x00008000`.

## 12. DTB Placement

| Field | Value |
|---|---|
| In Zip | Separate file (`sdm636-xiaomi-whyred.dtb`) |
| AnyKernel3 Handling | DTBs in zip are available for DTB flashing if needed |
| Boot Image | AnyKernel3 preserves existing DTB in boot partition |
| Mainline Approach | DTBs are separate from kernel (not appended as in Image.gz-dtb) |

**Critical**: AnyKernel3 replaces only the kernel binary. The DTB in the boot image comes from the device's existing boot partition. For a pure mainline boot, the DTB must be flashed separately or the existing boot DTB must be compatible.

## 13. Ramdisk Requirements

| Field | Value |
|---|---|
| Ramdisk in Zip | `ramdisk/placeholder` (empty) |
| AnyKernel3 Behavior | Preserves existing ramdisk from device's boot partition |
| Android Ramdisk | Needed for init, mounting system/vendor |
| First Boot | Ramdisk from stock/LineageOS will be used |

**Note**: For first boot testing (UART console only), the ramdisk is not critical. The kernel will boot to a shell via serial console regardless of ramdisk content. If the ramdisk's init fails, the kernel will still reach the early console.

## 14. Command Line

From DTS `chosen` node:
```
earlycon=msm_serial_dm,0x0c170000 console=ttyMSM0,115200n8 androidboot.hardware=qcom
```

| Parameter | Value | Purpose |
|---|---|---|
| `earlycon` | `msm_serial_dm,0x0c170000` | Early UART console at BLSP1 UART2 |
| `console` | `ttyMSM0,115200n8` | Main console at 115200 baud |
| `androidboot.hardware` | `qcom` | Android hardware identifier |

## 15. Device Bootloader Expectations

| Field | Value |
|---|---|
| Device | Xiaomi Redmi Note 5 Pro (whyred) |
| SoC | Qualcomm SDM636 (Snapdragon 636) |
| Bootloader | Qualcomm XBL (eXtensible Boot Loader) |
| Boot Partition | `/dev/block/bootdevice/by-name/boot` |
| A/B Slots | No (single slot) |
| Boot Image Format | Android boot image header v1 |
| Fastboot | Standard Qualcomm fastboot |
| Unlock Requirement | Bootloader unlock required for flashing |
| Recovery | TWRP or stock recovery |

### Bootloader Boot Sequence

1. XBL initializes PMIC, DDR, clocks
2. XBL loads `boot.img` from boot partition
3. XBL verifies boot image header (hash/signature)
4. XBL loads kernel + ramdisk + DTB from boot image
5. XBL jumps to kernel entry point
6. Kernel decompresses (gzip)
7. Kernel parses DTB (from boot image or appended)
8. Kernel initializes CPUs, memory, interrupts
9. Kernel reaches early console (UART)
10. Kernel mounts rootfs, starts init

---

## Flashing Methods

### Method 1: AnyKernel3 via TWRP (Recommended for First Boot)

**Prerequisites:**
- Unlocked bootloader
- TWRP recovery installed
- USB debugging enabled

**Steps:**
```bash
# 1. Download zip from CI artifacts
#    Artifact: whyred-6.18-15
#    File: Phoenix-Whyred-6.18-0.4.0-dev-20260718-084334-e841299.zip

# 2. Boot to TWRP
adb reboot recovery

# 3. Flash zip
# In TWRP: Install → select zip → Swipe to confirm

# 4. Reboot
# In TWRP: Reboot → System
```

**Behavior:**
- AnyKernel3 reads existing boot partition
- Extracts kernel binary
- Replaces with our Image.gz
- Preserves existing ramdisk and DTB
- Writes modified boot image back
- Device reboots with new kernel

### Method 2: fastboot boot (Temporary Test)

**Prerequisites:**
- Unlocked bootloader
- USB debugging enabled
- fastboot drivers installed

**Steps:**
```bash
# 1. Reboot to bootloader
adb reboot bootloader

# 2. Temporary boot (does not persist)
# Note: Requires a proper boot.img, not raw Image.gz
# AnyKernel3 zip must be extracted to get Image.gz
# Then use mkbootimg to create boot.img:

mkbootimg \
  --kernel Image.gz \
  --ramdisk <extracted-ramdisk> \
  --board whyred \
  --base 0x80000000 \
  --pagesize 2048 \
  --kernel_offset 0x00008000 \
  --header_version 1 \
  --os_version 9.0.0 \
  --os_patch_level 2021-04-01 \
  -o boot-test.img

# 3. Temporary boot
fastboot boot boot-test.img

# 4. Device will boot with new kernel
# Kernel logs appear on UART console
# After reboot, device returns to original kernel
```

**Note**: `fastboot boot` is **temporary** — the kernel runs once and does not modify the boot partition. This is the safest first boot test method.

### Method 3: fastboot flash boot (Permanent)

**Prerequisites:**
- Unlocked bootloader
- **WARNING**: Overwrites existing boot partition

**Steps:**
```bash
# 1. BACKUP FIRST
adb shell "dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot-backup.img"
adb pull /sdcard/boot-backup.img

# 2. Flash
fastboot flash boot boot-test.img

# 3. Reboot
fastboot reboot
```

**WARNING**: This permanently modifies the boot partition. Always keep a backup.

---

## Boot Test Matrix

| # | Method | Artifact | Persistence | Risk |
|---|---|---|---|---|
| 1 | `fastboot boot` | `boot-test.img` (mkbootimg) | Temporary | LOW — no permanent change |
| 2 | AnyKernel3 via TWRP | `Phoenix-Whyred-6.18-*.zip` | Permanent | MEDIUM — modifies boot partition |
| 3 | `fastboot flash boot` | `boot-test.img` (mkbootimg) | Permanent | HIGH — overwrites boot partition |

**Recommendation for first boot**: Use **Method 1 (AnyKernel3 via TWRP)** if TWRP is available. This is the standard kernel flashing method and preserves the device's ramdisk. If TWRP is not available, use **Method 2 (fastboot boot)** with a properly constructed boot.img.

---

## Logging Preparation

### UART Serial Console (PRIMARY)

The DTS configures BLSP1 UART2 at `0x0c170000` @ 115200 baud.

**Setup:**
1. Connect USB-UART adapter to device's test points:
   - TX: GP16 (test point near SIM tray)
   - RX: GP15 (test point near SIM tray)
   - GND: Any ground point
2. Open terminal: `minicom -D /dev/ttyUSB0 -b 115200`
3. Or use: `screen /dev/ttyUSB0 115200`

**Expected Output:**
```
[    0.000000] Booting Linux on physical CPU 0x0000000000 [0x510f8030]
[    0.000000] Linux version 6.18.0-dirty-phoenix-whyred-6.18-0.4.0-dev (...)
[    0.000000] Machine model: Xiaomi Redmi Note 5 Pro
[    0.000000] bootargs: earlycon=msm_serial_dm,0x0c170000 console=ttyMSM0,115200n8 ...
```

### USB Early Debugging (SECONDARY)

If UART is not available, enable `CONFIG_USB_SERIAL_CONSOLE` in config. Requires USB gadget mode.

### adb (TERTIARY)

Only available if Android userspace boots. Do not rely on this for first boot.

### pstore/ramoops (AFTER REBOOT)

Requires `CONFIG_PSTORE=y` (currently disabled in hybrid.config). Not available for first boot.

### Bootloader Logs

Qualcomm XBL logs may be available via:
- `fastboot getvar all`
- Device-specific log commands (varies by bootloader version)

---

## Artifact Verification Checklist

Before flashing, verify:

- [ ] Downloaded correct CI artifact: `whyred-6.18-15` (ID: `8427693766`)
- [ ] Zip SHA256 matches: `0dabf91c402bcc8d915ecf91c1c10de7558aca984bb3c23549abfe8d5bfe406a`
- [ ] Zip contains `Image.gz` (15,336,387 bytes)
- [ ] Zip contains `sdm636-xiaomi-whyred.dtb` (valid FDT)
- [ ] Zip contains `build-info.txt` with correct metadata
- [ ] Zip contains `SHA256SUMS` with correct checksums
- [ ] Device is whyred (Xiaomi Redmi Note 5 Pro)
- [ ] Bootloader is unlocked
- [ ] UART serial console is connected (if available)
- [ ] TWRP recovery is installed (if using AnyKernel3 method)
- [ ] Original boot partition is backed up (if flashing permanently)
- [ ] Battery is charged (>50%)

---

## Risk Assessment

| Risk | Impact | Mitigation |
|---|---|---|
| Kernel panics early | No boot, no console | UART console will show panic message |
| DTB mismatch | Hardware probes fail, kernel hangs | Verify DTB compatible strings match stock |
| Missing config | Driver not loaded, feature missing | Config validated, 20 OK checks passed |
| Bootloader rejects image | Device boots to bootloader | Use AnyKernel3 (preserves header) |
| Ramdisk incompatible | Android init fails | Acceptable for first boot (UART only) |
| Brick risk | Device unusable | Bootloader recovery always available via fastboot |

---

## First Boot Decision

**Primary Objective**: Boot to UART console showing kernel messages.

**Success Criteria**:
- UART output shows `Linux version 6.18.0-dirty`
- UART output shows `Machine model: Xiaomi Redmi Note 5 Pro`
- UART output shows CPU initialization
- UART output shows memory initialization
- UART output reaches shell prompt (or init start)

**Failure Criteria**:
- No UART output at all (bootloader rejected or kernel entry failed)
- Kernel panic before console init
- Hangs during early initialization

**Next Action After Boot**: Record exact UART output in `FIRST_BOOT_RESULT.md`.
