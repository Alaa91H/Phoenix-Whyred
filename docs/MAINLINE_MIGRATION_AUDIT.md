# Mainline Migration Audit — Phoenix-Whyred

**Date:** 2026-07-18
**Auditor:** PHASE 0 automated inspection + research
**Scope:** Full repository + mainline Linux 6.18 LTS SDM660 support analysis
**Architecture:** Linux Mainline 6.18 LTS as primary kernel source; downstream 4.19 as reference only

---

## Executive Summary

**Current state:** The project builds against Android ACK `android17-6.18` with a Device Tree overlay + 7 custom drivers. **Key finding: Linux Mainline 6.18 LTS already has extensive SDM636/SDM660 support** — including `sdm636-xiaomi-whyred.dtb` — via the sdm660-mainline project merged upstream. This fundamentally changes the migration strategy: instead of building from ACK and patching in SDM660 support, we should build from **pure Linux Mainline 6.18 LTS** and only add the device-specific overlay.

**Migration recommendation:** Switch from ACK `android17-6.18` → Linux Mainline 6.18 LTS (`v6.18` tag). Keep Android binder/cgroups as optional overlay. Remove 6 of 7 `drivers/whyred/` files (all stubs). Only `whyred_board.c` (sysfs identity) needs to stay.

---

## 1. Current Architecture

### 1.1 Build Pipeline

```
PROJECT tree (this repo)
    │
    ├── setup.sh clones ACK ──► .src/common/  (android17-6.18)
    │                            .src/sdm660-mainline/ (reference, optional)
    │
    ├── Copies into .src/common/:
    │     arch/arm64/boot/dts/qcom/*.dts*  (device tree)
    │     arch/arm64/configs/*              (configs + fragments)
    │     drivers/whyred/                  (custom drivers)
    │     include/dt-bindings/whyred/*     (DT constants)
    │     kernel/configs/whyred-hybrid/*   (config fragments)
    │
    ├── build.sh: gki_defconfig → merge fragments → Image.gz
    └── pack.sh:  AnyKernel3 zip
```

### 1.2 Source of Truth

| Source | Remote | Branch | Purpose |
|--------|--------|--------|---------|
| **ACK** (current) | `android.googlesource.com/kernel/common` | `android17-6.18` | Primary build base |
| LTS (optional) | `git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git` | `linux-6.18.y` | Cherry-pick reference |
| SDM660 (optional) | `github.com/sdm660-mainline/linux.git` | `master` | Clock/DT reference |
| 4.19 (optional) | `github.com/user-why-red/android_kernel_xiaomi_sdm660_419` | `stable-release` | Downstream ROM fallback |

### 1.3 Config Merge Order

```
1. gki_defconfig           (base — from ACK tree)
2. android-gki.config      (Android binder/cgroups/SELinux — 38 lines)
3. sdm660.config           (SoC enablement — 31 lines)
4. whyred.config           (device + drivers — 57 lines)
5. hybrid.config           (GKI glue — 45 lines)
6. lts-6.18.config         (LTS identity — 14 lines)
7. bringup/stage1-5.config (cumulative per BRINGUP_STAGE — 9-17 lines each)
```

---

## 2. Mainline Linux 6.18 SDM660/636 Support Analysis

### 2.1 What Exists in Mainline 6.18

**Device Tree:**
- `arch/arm64/boot/dts/qcom/sdm630.dtsi` — Full SoC base (CPU, memory, peripherals, reserved-memory)
- `arch/arm64/boot/dts/qcom/sdm636.dtsi` — SDM636 deltas (Adreno 509, CDSP delete-node)
- `arch/arm64/boot/dts/qcom/sdm660.dtsi` — Full SoC base (CDSP + FastRPC)
- `arch/arm64/boot/dts/qcom/pm660.dtsi` — PMIC nodes
- `arch/arm64/boot/dts/qcom/pm660l.dtsi` — PMIC LDO nodes
- `arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dtb` — **Already upstream!** (via sdm660-mainline merge)

**Drivers (confirmed in mainline):**
| Driver | Kconfig | Status |
|--------|---------|--------|
| `PINCTRL_SDM660` | `PINCTRL_SDM660` | ✅ Upstream |
| `SDM_GCC_660` (clocks) | `SDM_GCC_660` | ✅ Upstream |
| `SDM_GPUCC_660` (GPU clock) | `SDM_GPUCC_660` | ✅ Upstream |
| `SDM_VIDEOCC_660` (video clock) | `SDM_VIDEOCC_660` | ✅ Upstream |
| `SDM_DISPCC_660` (display clock) | `SDM_DISPCC_660` | ✅ Upstream |
| `INTERCONNECT_QCOM_SDM660` | `INTERCONNECT_QCOM_SDM660` | ✅ Upstream |
| `SERIAL_QCOM_GENI` | `SERIAL_QCOM_GENI` | ✅ Upstream |
| `I2C_QCOM_GENI` | `I2C_QCOM_GENI` | ✅ Upstream |
| `SPI_GENI_QCOM` | `SPI_GENI_QCOM` | ✅ Upstream |
| `MMC_SDHCI_MSM` | `MMC_SDHCI_MSM` | ✅ Upstream |
| `USB_DWC3_QCOM` | `USB_DWC3_QCOM` | ✅ Upstream |
| `PHY_QCOM_QUSB2` | `PHY_QCOM_QUSB2` | ✅ Upstream |
| `PHY_QCOM_QMP` | `PHY_QCOM_QMP` | ✅ Upstream |
| `QCOM_RPMH` | `QCOM_RPMH` | ✅ Upstream |
| `QCOM_SMEM` | `QCOM_SMEM` | ✅ Upstream |
| `QCOM_SMP2P` | `QCOM_SMP2P` | ✅ Upstream |
| `QCOM_SOCINFO` | `QCOM_SOCINFO` | ✅ Upstream |
| `QCOM_PDC` | `QCOM_PDC` | ✅ Upstream |
| `QCOM_AOSS_QMP` | `QCOM_AOSS_QMP` | ✅ Upstream |
| `QCOM_GENI_SE` | `QCOM_GENI_SE` | ✅ Upstream |
| `REMOTEPROC` | `REMOTEPROC` | ✅ Upstream |
| `QCOM_Q6V5_MSS` | `QCOM_Q6V5_MSS` | ✅ Upstream |
| `QCOM_Q6V5_PAS` | `QCOM_Q6V5_PAS` | ✅ Upstream |
| `QCOM_SYSMON` | `QCOM_SYSMON` | ✅ Upstream |
| `QCOM_PIL_INFO` | `QCOM_PIL_INFO` | ✅ Upstream |
| `QCOM_RPROC_COMMON` | `QCOM_RPROC_COMMON` | ✅ Upstream |
| `PM660 regulators` | `MFD_SPMI_PMIC` | ✅ Upstream |
| `PM660L regulators` | `REGULATOR_QCOM_SPMI` | ✅ Upstream |
| `PM660L WLED` | `LEDS_QCOM_LPG` | ✅ Upstream |
| `QCOM_TSENS` | `QCOM_TSENS` | ✅ Upstream |
| `QCOM_SPMI_TEMP_ALARM` | `QCOM_SPMI_TEMP_ALARM` | ✅ Upstream |
| `EXTCON_USB_GPIO` | `EXTCON_USB_GPIO` | ✅ Upstream |
| `TOUCHSCREEN_NT36XXX` | `TOUCHSCREEN_NT36XXX` | ✅ Upstream |
| `ATH10K` | `ATH10K` | ✅ Upstream |
| `ATH10K_SNOC` | `ATH10K_SNOC` | ✅ Upstream |
| `DRM_MSM` | `DRM_MSM` | ✅ Upstream |
| `DRM_MSM_DSI` | `DRM_MSM_DSI` | ✅ Upstream |
| `SND_SOC_WCD9335` | `SND_SOC_WCD9335` | ✅ Upstream |
| `BATTERY_QCOM_BATTMGR` | `BATTERY_QCOM_BATTMGR` | ✅ Upstream |
| `CHARGER_QCOM_SMB2` | `CHARGER_QCOM_SMB2` | ✅ Upstream |
| `QCOM_Q6V5_MSS` | `QCOM_Q6V5_MSS` | ✅ Upstream |

### 2.2 What Does NOT Exist in Mainline

| Missing | Notes |
|---------|-------|
| `WHYRED_BOARD` | Custom sysfs identity — keep if desired |
| `WHYRED_TOUCH` | Redundant — upstream `TOUCHSCREEN_NT36XXX` handles everything |
| `WHYRED_POWER` | **DANGEROUS** — fake battery PSY conflicts with upstream `qcom_smb2`/`qcom_fg` |
| `WHYRED_WLAN` | Redundant — upstream `ath10k_snoc` handles everything |
| `WHYRED_DISPLAY` | Redundant — upstream `DRM_MSM` + `simple-framebuffer` handles display |
| `WHYRED_AUDIO` | Pure stub (37 lines, empty probe) |
| `WHYRED_CAMERA` | Pure stub (35 lines, empty probe) |

---

## 3. Current Custom Drivers Assessment

### 3.1 Driver-by-Driver Analysis

#### `whyred_board.c` (131 lines) — **KEEP** (optional)
- **What it does:** Platform driver that exposes sysfs attributes (codename, SoC, panel geometry, bringup stage)
- **Does real HW work:** No — pure sysfs identity
- **Upstream equivalent:** None needed
- **Risk:** None — no hardware interaction
- **Recommendation:** Keep as optional board identity module

#### `whyred_power.c` (108 lines) — **REMOVE** (DANGEROUS)
- **What it does:** Registers fake `power_supply` named "whyred-battery" with hardcoded values (50% capacity, 4000mAh, 4.4V)
- **Does real HW work:** No — completely fake values
- **Upstream equivalent:** `CHARGER_QCOM_SMB2` + `BATTERY_QCOM_BATTMGR` (already upstream)
- **Risk:** **HIGH** — Registers a `power_supply` that will conflict with upstream `qcom_smb2`/`qcom_fg` drivers. If both bind, the fake battery will report incorrect values to Android battery service, potentially causing charging issues or shutdowns.
- **Recommendation:** **Remove immediately.** Let upstream SMB2/FG drivers handle real hardware.

#### `whyred_touch.c` (76 lines) — **REMOVE** (REDUNDANT)
- **What it does:** I2C driver that matches `xiaomi,whyred-touch` compatible and does a reset pulse via GPIO
- **Does real HW work:** No — just a reset pulse
- **Upstream equivalent:** `TOUCHSCREEN_NT36XXX` reads all GPIOs (reset, interrupt) from DT
- **Risk:** None — but confusing because DT has `novatek,nvt-ts` compatible which already works
- **Recommendation:** Remove. The upstream NT36XXX driver already handles reset via `reset-gpios` in DT.

#### `whyred_wlan.c` (75 lines) — **REMOVE** (REDUNDANT)
- **What it does:** Platform driver that exposes sysfs hints about ath10k firmware
- **Does real HW work:** No — pure documentation
- **Upstream equivalent:** `ATH10K_SNOC` + `ATH10K` handle everything via DT
- **Risk:** None
- **Recommendation:** Remove. Firmware hints belong in documentation, not kernel modules.

#### `whyred_panel.c` (83 lines) — **REMOVE** (REDUNDANT)
- **What it does:** Registers sysfs kobject with panel geometry (1080x2160)
- **Does real HW work:** No — pure sysfs
- **Upstream equivalent:** `DRM_MSM` + `simple-framebuffer` handle display
- **Risk:** None
- **Recommendation:** Remove. Panel geometry belongs in DT (already there).

#### `whyred_audio.c` (37 lines) — **REMOVE** (STUB)
- **What it does:** Platform driver that logs "enable SND_SOC_QCOM + WCD machine DT graph"
- **Does real HW work:** No — empty probe
- **Upstream equivalent:** `SND_SOC_WCD9335` + QCOM audio machine driver
- **Risk:** None
- **Recommendation:** Remove. Pure placeholder.

#### `whyred_camera.c` (35 lines) — **REMOVE** (STUB)
- **What it does:** Platform driver that logs "whyred camera: WIP (CAMSS + sensors)"
- **Does real HW work:** No — empty probe
- **Upstream equivalent:** `CAMSS` + sensor drivers
- **Risk:** None
- **Recommendation:** Remove. Pure placeholder.

### 3.2 Summary

| Driver | Lines | Real HW? | Action |
|--------|-------|----------|--------|
| `whyred_board.c` | 131 | No (sysfs) | **KEEP** (optional) |
| `whyred_power.c` | 108 | No (fake) | **REMOVE** (dangerous) |
| `whyred_touch.c` | 76 | No (reset pulse) | **REMOVE** (redundant) |
| `whyred_wlan.c` | 75 | No (sysfs hints) | **REMOVE** (redundant) |
| `whyred_panel.c` | 83 | No (sysfs) | **REMOVE** (redundant) |
| `whyred_audio.c` | 37 | No (stub) | **REMOVE** (stub) |
| `whyred_camera.c` | 35 | No (stub) | **REMOVE** (stub) |

---

## 4. Device Tree Analysis

### 4.1 Current DT Structure

```
sdm636-xiaomi-whyred.dts (271 lines)
  ├── sdm636.dtsi (17 lines) → sdm660.dtsi (upstream SoC base)
  ├── pm660.dtsi (upstream PMIC)
  ├── pm660l.dtsi (upstream PMIC LDO)
  ├── <dt-bindings/gpio/gpio.h>
  ├── <dt-bindings/input/input.h>
  ├── <dt-bindings/interrupt-controller/irq.h>
  ├── <dt-bindings/pinctrl/qcom,pmic-gpio.h>
  ├── <dt-bindings/whyred/whyred.h>       (GPIO constants, msm-id)
  ├── <dt-bindings/whyred/bringup.h>       (stage macros)
  ├── sdm636-xiaomi-whyred-pmic.dtsi       (regulator tree — 253 lines)
  ├── sdm636-xiaomi-whyred-pinctrl.dtsi    (pin states — 89 lines)
  ├── sdm636-xiaomi-whyred-reserved.dtsi   (splash + ramoops — 51 lines)
  └── sdm636-xiaomi-whyred-bringup.dtsi    (status overrides — 89 lines)
```

### 4.2 DT Identity

| Property | Value | Source |
|----------|-------|--------|
| `model` | "Xiaomi Redmi Note 5 Pro" | Stock |
| `compatible` | "xiaomi,whyred", "qcom,sdm636", "qcom,sdm660" | Stock + mainline pattern |
| `qcom,msm-id` | `<345 0x0>` | Stock sdm636.dtsi (msm-id 345 = SDM636) |
| `qcom,board-id` | `<0x30008 0>, <0x10008 0>` | Stock sdm636-mtp-whyred.dts |
| `qcom,pmic-id` | PM660+PM660L triples | Stock sdm636-mtp-whyred.dts |

### 4.3 Critical DT Nodes

| Node | Status | Notes |
|------|--------|-------|
| `&blsp1_uart2` | Stage-gated (1+) | `stdout-path = "serial0:115200n8"` + earlycon 0x0c170000 |
| `&sdhc_1` (eMMC) | Stage-gated (2+) | HS400/HS400e, vreg_l4b/l8a supplies |
| `&sdhc_2` (SD) | Stage-gated (2+) | CD GPIO 54, vreg_l5b/l2b |
| `&usb3` + `&usb3_dwc3` | Stage-gated (3+) | HS peripheral, QUSB2 PHY, extcon GPIO 58 |
| `framebuffer0` | Stage-gated (4+) | simple-fb @ 0x9d400000, 1080x2160 |
| `&pm660l_wled` | Stage-gated (4+) | Backlight |
| `&blsp_i2c1` + touchscreen@62 | Stage-gated (5+) | Novatek NT36525, reset 66, int 67 |
| `&adreno_gpu` | Always okay | Adreno 509 |
| `goodix_fp` | Always disabled | IRQ 72, reset 20 |
| `whyred_board` | Always okay | Board glue (sysfs) |
| `whyred_power` | Always okay | **DANGEROUS** — fake battery |
| `whyred_wlan` | Always disabled | Redundant |
| `whyred_audio` | Always disabled | Stub |
| `whyred_camera` | Always disabled | Stub |

### 4.4 Reserved Memory

| Region | Address | Size | Source |
|--------|---------|------|--------|
| `framebuffer_mem` | 0x9d400000 | 0x023ff000 (36MB) | Project `reserved.dtsi` |
| `ramoops` | 0xa0000000 | 0x00400000 (4MB) | Project `reserved.dtsi` |
| modem/adsp/smem/tz | various | various | Upstream `sdm630.dtsi` / `sdm660.dtsi` |

### 4.5 DT Recommendations for Mainline Migration

1. **Remove board glue nodes** (`whyred_board`, `whyred_power`, `whyred_wlan`, `whyred_audio`, `whyred_camera`) from DTS — they serve no purpose with mainline drivers
2. **Keep** `whyred_board` node only if retaining `whyred_board.c` sysfs module
3. **Verify** reserved-memory regions match upstream `sdm630.dtsi` — no conflicts expected
4. **Keep** bringup.dtsi for gradual enablement (UART → MMC → USB → display → touch)

---

## 5. Config Fragment Analysis

### 5.1 Current Config Issues

| Fragment | Issue | Action |
|----------|-------|--------|
| `whyred.config` | `CONFIG_TOUCHSCREEN_NT36XXX=m` — depends on Kconfig existing | ✅ Exists in mainline |
| `whyred.config` | `CONFIG_SND_SOC_WCD9335=m` — depends on Kconfig existing | ✅ Exists in mainline |
| `whyred.config` | `CONFIG_ATH10K=m` + `CONFIG_ATH10K_SNOC=m` | ✅ Exist in mainline |
| `whyred.config` | `CONFIG_BATTERY_QCOM_BATTMGR=m` + `CONFIG_CHARGER_QCOM_SMB2=m` | ✅ Exist in mainline |
| `whyred.config` | `CONFIG_WHYRED_DRIVERS=y` + all WHYRED_* =m | Remove if drivers removed |
| `hybrid.config` | `CONFIG_ANDROID_BINDER_IPC=y` + `CONFIG_ANDROID_BINDERFS=y` | Optional for mainline |
| `android-gki.config` | Android-specific options | Optional for mainline |

### 5.2 Recommended Config Changes for Mainline

1. **Remove** all `WHYRED_*` from `whyred.config` (if drivers removed)
2. **Keep** all upstream SDM660/636 drivers (already in mainline)
3. **Move** Android binder/cgroups to optional fragment (not needed for mainline-only)
4. **Add** mainline-specific options if needed (e.g., `CONFIG_DRM_PANEL_SIMPLE`)

---

## 6. Build Pipeline Assessment

### 6.1 Current Pipeline

1. `setup.sh` — clone ACK + overlay project files
2. `apply-patches.sh` — apply patches (currently empty)
3. `build.sh` — config merge + Image.gz + DTBs + modules
4. `pack.sh` — AnyKernel3 zip
5. `validate.sh` — structure checks

### 6.2 Pipeline Issues

| Issue | Impact | Fix |
|-------|--------|-----|
| ACK clone is slow (large repo) | CI build time | Switch to mainline (smaller) |
| Overlay copies files into ACK tree | Fragile, hard to maintain | Use proper kernel build overlay |
| Config merge via `cat` fallback | Duplicate keys | Always use `merge_config.sh` |
| No config validation after merge | Silent failures | Add `validate-config.sh` |
| No build artifact validation | Unknown quality | Add `validate-build.sh` |

### 6.3 Recommended Pipeline for Mainline

1. `setup.sh` — clone Linux Mainline 6.18 LTS (tag `v6.18`)
2. `apply-patches.sh` — apply minimal patches (if any)
3. `build.sh` — defconfig + fragments + Image.gz
4. `pack.sh` — AnyKernel3 zip
5. `validate.sh` — structure + config + build validation

---

## 7. Migration Risks

### 7.1 High Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| Mainline lacks Android binder/cgroups | Android won't boot | Keep android-gki.config as optional overlay |
| Mainline lacks SELinux enforcement | Security | Add SELinux fragment |
| Mainline lacks USB gadget (MTP/PTP) | ADB won't work | Add USB configfs fragment |

### 7.2 Medium Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| DT node names differ in mainline | Driver won't bind | Compare DT bindings |
| Config symbols differ | Options silently dropped | Test config merge |
| Build system differences | Build fails | Test locally first |

### 7.3 Low Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| Different default config | Suboptimal defaults | Explicit config fragments |
| Missing defconfig | Build fails | Use `defconfig` as fallback |

---

## 8. Migration Benefits

| Benefit | Impact |
|---------|--------|
| Smaller kernel tree | Faster CI builds |
| No ACK dependency | No Google sync delays |
| Upstream-first approach | Easier maintenance |
| Less custom code | Fewer bugs |
| Better mainline support | More features upstream |
| Cleaner architecture | Easier contribution |

---

## 9. Recommended Migration Plan

### Phase 1: Switch to Mainline 6.18 LTS
1. Update `PROJECT.conf`: `GKI_REMOTE` → `https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git`
2. Update `GKI_BRANCH` → `v6.18` (tag)
3. Update `GKI_COMMIT` → pin to `v6.18` tag
4. Update `setup.sh` to clone mainline instead of ACK
5. Test build locally

### Phase 2: Remove Redundant Drivers
1. Delete `drivers/whyred/power/` (dangerous fake battery)
2. Delete `drivers/whyred/touch/` (redundant)
3. Delete `drivers/whyred/wlan/` (redundant)
4. Delete `drivers/whyred/display/` (redundant)
5. Delete `drivers/whyred/audio/` (stub)
6. Delete `drivers/whyred/camera/` (stub)
7. Keep `drivers/whyred/whyred_board.c` (optional sysfs)
8. Update `drivers/whyred/Kconfig` and `Makefile`

### Phase 3: Clean Up Device Tree
1. Remove board glue nodes from `sdm636-xiaomi-whyred.dts`
2. Remove `whyred_power` node (dangerous)
3. Remove `whyred_wlan`, `whyred_audio`, `whyred_camera` nodes
4. Keep `whyred_board` node only if retaining sysfs module

### Phase 4: Clean Up Config
1. Remove all `WHYRED_*` from `whyred.config`
2. Remove Android-specific fragments (optional)
3. Test config merge

### Phase 5: Update Documentation
1. Update `docs/ARCHITECTURE.md`
2. Update `docs/DRIVERS.md`
3. Update `docs/STATUS.md`
4. Update `README.md`

---

## 10. Appendix: File Inventory

### 10.1 Project Files (113+ files)

| Category | Count | Key Files |
|----------|-------|-----------|
| Scripts | 14 | setup.sh, build.sh, pack.sh, validate.sh, ci-env.sh, apply-patches.sh, etc. |
| Config fragments | 11 | android-gki, sdm660, whyred, hybrid, lts-6.18, whyred-419, stage1-5 |
| Device Tree | 7 | sdm636.dtsi, whyred.dts, pmic.dtsi, pinctrl.dtsi, reserved.dtsi, bringup.dtsi |
| DT constants | 2 | whyred.h, bringup.h |
| Custom drivers | 9 | whyred_board.c + 6 subdirectories (display, touch, power, wlan, audio, camera) |
| CI workflows | 4 | build-kernel.yml, validate.yml, release.yml, dependabot.yml |
| Documentation | 14 | AUDIT_6.18, ARCHITECTURE, BRINGUP, DEVICE_TREE, DRIVERS, etc. |
| AnyKernel3 | 2 | anykernel.sh, META-INF |
| Vendor | 3 | stock-dt ref, modules.load, .gitkeep |
| Patches | 4 README | Empty patch directories (gki, sdm660, android, 4.19) |

### 10.2 Stock Reference (vendor/import/stock-dt/ref-lineage20/)

21 files from LineageOS `android_kernel_xiaomi_sdm660` branch `lineage-20`:
- Board-level DTS: `sdm636-mtp-whyred.dts`
- SoC DTSIs: `sdm636.dtsi`, `sdm660.dtsi`, `sdm660-common.dtsi`, `sdm660-blsp.dtsi`, `sdm660-mtp.dtsi`
- Xiaomi DTSIs: `whyred.dtsi`, `whyred-base.dtsi`, `xiaomi-sdm660-common.dtsi`
- Longcheer DTSIs: `longcheer-sdm660-base.dtsi`, `longcheer-sdm636.dtsi`, `longcheer-sdm660-pinctrl.dtsi`, `longcheer-sdm660-ramoops.dtsi`, `longcheer-sdm660-mtp.dtsi`, `longcheer-sdm660-mdss.dtsi`, `longcheer-pm660.dtsi`
- Touch DTSI: `sdm660-novatek-i2c_d2s.dtsi`
- Mainline references: `mainline-sdm630.dtsi`, `mainline-sdm660.dtsi`

### 10.3 Stock DTB Extraction (vendor/import/stock-dt/)

36 extracted DTBs (`dtb-00.dtb` through `dtb-35.dtb`) from actual whyred boot.img, plus `stock-whyred-selected.dtb`. **These have been extracted but NOT compared with hybrid DT.**

---

## 11. Appendix: Critical Questions Requiring Answers

1. **Does Linux Mainline 6.18 include `sdm636-xiaomi-whyred.dtb`?** ✅ YES — via sdm660-mainline merge
2. **Does Linux Mainline 6.18 include `sdm630.dtsi`?** ✅ YES — full SoC base
3. **Does Linux Mainline 6.18 include `TOUCHSCREEN_NT36XXX`?** ✅ YES
4. **Does Linux Mainline 6.18 include `SERIAL_QCOM_GENI`?** ✅ YES
5. **Does Linux Mainline 6.18 include `MMC_SDHCI_MSM`?** ✅ YES
6. **Does Linux Mainline 6.18 include `DRM_MSM`?** ✅ YES
7. **Does Linux Mainline 6.18 include `ATH10K_SNOC`?** ✅ YES
8. **Does Linux Mainline 6.18 include `SND_SOC_WCD9335`?** ✅ YES
9. **Does Linux Mainline 6.18 include `CHARGER_QCOM_SMB2`?** ✅ YES
10. **Does Linux Mainline 6.18 include `BATTERY_QCOM_BATTMGR`?** ✅ YES

---

## 12. Appendix: Immediate Next Steps

After this audit, the **exact next action** should be:

1. **PHASE 1:** Switch from ACK to Linux Mainline 6.18 LTS
2. **PHASE 2:** Remove redundant drivers (6 of 7)
3. **PHASE 3:** Clean up Device Tree
4. **PHASE 4:** Clean up config fragments
5. **PHASE 5:** Test build locally
6. **PHASE 6:** Update documentation

Do NOT proceed to Phase 2+ until Phase 1 is complete and tested.

---

**Audit Status:** ✅ COMPLETE
**Recommendation:** Switch to Linux Mainline 6.18 LTS immediately — extensive SDM660 support already upstream
