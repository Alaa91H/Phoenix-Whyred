# Boot Preparation Analysis — whyred (SDM636)

> **Target**: Linux Mainline 6.18 LTS
> **Device**: Xiaomi Redmi Note 5 Pro (`whyred`)
> **Created**: 2026-07-18

## Boot Image Layout (from stock/vendor analysis)

The whyred bootloader expects an Android boot image. Key parameters:

### Boot Image Header (v0/v1)

| Field | Value | Source |
|---|---|---|
| Header version | 0 (or 1) | Stock boot.img |
| Page size | 4096 (0x1000) | Standard Qualcomm |
| Kernel physical address | 0x00008000 | Standard ARM64 |
| Kernel offset | 0x00008000 | Standard Qualcomm |
| Ramdisk offset | 0x01000000 | Standard Qualcomm |
| Second stage offset | 0x00000000 | Not used |
| Tags address | 0x00000100 | Standard ARM64 |
| DTB offset | Appended to Image.gz or separate | Build-dependent |

### Boot Image Components

| Component | Description |
|---|---|
| Kernel | `Image.gz` (compressed ARM64 kernel image) |
| Ramdisk | initramfs (or initrd) with rootfs |
| DTB | `sdm636-xiaomi-whyred.dtb` (appended to Image.gz or separate) |
| DTBO | Display tree overlay (for panel variants — optional) |
| cmdline | Boot arguments (console, hardware) |

### Command Line

Stock whyred bootargs pattern:
```
console=ttyMSM0,115200n8 androidboot.console=ttyMSM0
androidboot.hardware=qcom
androidboot.bootdevice=7824900.sdhci
earlycon=msm_serial_dm,0x0c170000
```

Our DTS `chosen` node bootargs:
```
earlycon=msm_serial_dm,0x0c170000
console=ttyMSM0,115200n8
androidboot.hardware=qcom
```

### Critical Boot Parameters

| Parameter | Value | Notes |
|---|---|---|
| `console` | `ttyMSM0,115200n8` | GENI serial UART2 |
| `earlycon` | `msm_serial_dm,0x0c170000` | Early console address |
| `androidboot.hardware` | `qcom` | Platform identifier |
| `androidboot.bootdevice` | `7824900.sdhci` | eMMC boot device |

## Boot Flow

```
PBL (ROM) → SBL/XBL (bootloader) → ABL (Android bootloader)
    → Loads boot.img from userdata/system/boot partition
        → Extracts kernel Image.gz + DTB
            → Decompresses to RAM
                → Jumps to kernel entry point
                    → Kernel starts with DTB
```

## DTB Placement Options

### Option A: Appended DTB (Image.gz-dtb)
- DTB appended directly after compressed kernel
- Bootloader decompresses both
- Simpler; single file
- Used by downstream 4.19 builds

### Option B: Separate DTB
- DTB as separate file in boot partition
- Bootloader loads independently
- More flexible; can swap DTB without rebuilding kernel
- Used by mainline builds

### Recommendation
Use **Option A** (appended DTB) for first boot — matches stock bootloader expectations.

## Bootloader Expectations

The whyred bootloader (ABL/XBL) expects:
1. **Valid boot image header** — must match expected magic bytes
2. **ARM64 kernel** — `Image.gz` format
3. **Valid DTB** — must contain `qcom,msm-id` and `qcom,board-id` matching bootloader
4. **Correct page size** — 4096 bytes

### `qcom,msm-id` Validation
- Whyred uses MSM ID 345 (SDM636)
- Board IDs: 0x30008, 0x10008
- Bootloader validates these match the hardware
- If mismatched → bootloader rejects the boot image

### `qcom,pmic-id` Validation
- PM660 (0x0001001b, 0x0101011a)
- PM660L (0x0001001b, 0x0201011a)
- Secondary PM660 (0x0001001b, 0x0102001a)
- Bootloader validates PMIC presence

## Flashing Method

### Method 1: fastboot (recommended for first boot)
```bash
# Flash boot image
fastboot flash boot out/dist/Image.gz-dtb

# Or flash kernel + DTB separately
fastboot flash kernel out/dist/Image.gz
fastboot flash dtbo out/dist/sdm636-xiaomi-whyred.dtb
```

### Method 2: Recovery/ADB sideload
- Not recommended for first boot (requires working recovery)

### Method 3: Direct partition write
- Requires root access to device
- Not recommended

## Risk Assessment

| Risk | Impact | Mitigation |
|---|---|---|
| Invalid boot image header | Boot rejected | Use AnyKernel3 repack tool |
| DTB `qcom,msm-id` mismatch | Boot rejected | Verify against stock DTB |
| Missing regulator supply | Power rails fail | PMIC DT already ported from lavender |
| UART wrong address | No console output | Address verified (0x0c170000) |
| Kernel panic on boot | No boot | Debug via UART/serial |
| eMMC not probed | No rootfs | Verify SDHCI DT binding |
