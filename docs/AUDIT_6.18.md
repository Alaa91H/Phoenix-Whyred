# Repository Audit — Whyred Hybrid 6.18 LTS

**Date:** 2026-07-18
**Auditor:** PHASE 0 automated inspection
**Scope:** Full repository — every file inspected

---

## 1. Current Architecture

### 1.1 System Overview

```
This repo (overlay tree)
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

### 1.2 Track System

| Track | Base | Purpose |
|-------|------|---------|
| **6.18 (default)** | `android17-6.18` ACK | Hybrid LTS — long-term development |
| **4.19** | `user-why-red/android_kernel_xiaomi_sdm660_419` | Downstream ROM kernel — boots today |

Track selection: `KERNEL_TRACK` env var or PROJECT.conf default. The 4.19 track is a fallback for ROM users; 6.18 is the primary development target.

### 1.3 Build Pipeline

1. `setup.sh` — clone ACK + overlay project files into .src/common
2. `apply-patches.sh` — apply patches from `patches/{gki,sdm660,android}/` (currently empty)
3. `build.sh` — config merge + Image.gz + DTBs + modules
4. `pack.sh` — AnyKernel3 zip
5. `validate.sh` — structure checks (no build validation)

### 1.4 CI/CD

- `build-kernel.yml` — main build (manual/tag/schedule), produces artifact + optional release
- `validate.yml` — fast structure + syntax checks on push/PR
- `release.yml` — convenience wrapper for manual release

All upgraded to Node 24 (`actions/checkout@v7`, `upload-artifact@v7`, `softprops/action-gh-release@v3`).

---

## 2. Current Source-of-Truth for 6.18 Kernel

### 2.1 ACK Source

```
REMOTE: https://android.googlesource.com/kernel/common
BRANCH: android17-6.18
DEST:   .src/common/
```

- Fetched via `git clone --depth 1 --single-branch`
- Always uses **HEAD** of the branch — **never pinned**
- Provenance lock: `vendor/import/kernel-6.18-hybrid.lock` generated at setup time

### 2.2 Reference Sources

```
LTS:      https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git  (linux-6.18.y)
SDM660:   https://github.com/sdm660-mainline/linux.git                       (master)
4.19:     https://github.com/user-why-red/android_kernel_xiaomi_sdm660_419   (stable-release)
```

LTS and SDM660 are **optional** reference clones (disabled on CI by default).

---

## 3. Exact Upstream/ACK Commit

**NOT LOCKED.** The build always uses HEAD of `android17-6.18`. The lock file is generated dynamically:

```bash
# In setup.sh:
echo "gki_commit=$(git -C "${dest}" rev-parse HEAD)" >> vendor/import/kernel-6.18-hybrid.lock
```

**Risk:** Non-reproducible builds. Two builds on different days may use different ACK commits.

**Recommendation:** Pin a specific commit in PROJECT.conf (e.g., `GKI_COMMIT="abc123"`) and checkout that exact ref during setup.

---

## 4. Current Patch Flow

### 4.1 Patch Directories

| Directory | Contents | Purpose |
|-----------|----------|---------|
| `patches/gki/` | `README.md` only (empty) | ACK modifications |
| `patches/sdm660/` | `README.md` only (empty) | SoC forward-port patches |
| `patches/android/` | `README.md` only (empty) | Android extras |
| `patches/4.19/` | `README.md` only (empty) | 4.19 downstream patches |

### 4.2 Patch Application (`apply-patches.sh`)

```bash
apply_series() {
  # find *.patch, try git apply --check, then git apply, fallback to patch -p1
  # On failure: prints "SKIP/FAIL" and continues
}
```

**Critical Issues:**
1. **Silent failure** — required patches that fail are silently skipped (prints "SKIP/FAIL" but continues)
2. **No patch result tracking** — no APPLIED/FAILED/ALREADY_APPLIED report
3. **No exit code on required failure** — always exits 0
4. **CI workflow masks failures** — `run: ./scripts/apply-patches.sh || echo "::warning::Some patches failed to apply"`

**Current impact:** None — there are no patches. But when patches are added, this will be dangerous.

---

## 5. Current Overlay Flow

The overlay mechanism in `setup.sh` (lines 66-119):

1. **Directories created:** DTS, configs, drivers, dt-bindings, kernel/configs
2. **DTS:** `cp -a *.dts *.dtsi` — copies all project DTS into ACK tree
3. **Configs:** `cp -a` — copies fragments into `kernel/configs/whyred-hybrid/`
4. **Drivers:** `rm -rf + cp -a` — replaces drivers/whyred entirely
5. **Build system wiring:**
   - Appends `source "drivers/whyred/Kconfig"` to `drivers/Kconfig`
   - Appends `obj-y += whyred/` to `drivers/Makefile`
   - Appends `dtb-$(CONFIG_ARCH_QCOM) += sdm636-xiaomi-whyred.dtb` to `arch/arm64/boot/dts/qcom/Makefile`
6. **Provenance lock:** Writes commit hash + metadata to `vendor/import/kernel-6.18-hybrid.lock`

**Issues:**
- `cp -a` of DTS into ACK tree may overwrite existing upstream files (e.g., if upstream has a sdm636.dtsi)
- Build system wiring uses `grep -q` which may match substrings
- No idempotency check on all operations

---

## 6. Current Config Merge Order

```
1. gki_defconfig           (base — from ACK tree)
2. android-gki.config      (Android binder/cgroups/SELinux — 38 lines)
3. sdm660.config           (SoC enablement — 31 lines)
4. whyred.config           (device + drivers — 61 lines)
5. hybrid.config           (GKI glue — 45 lines)
6. lts-6.18.config         (LTS identity — 36 lines)
7. bringup/stage1-5.config (cumulative per BRINGUP_STAGE — 9-17 lines each)
```

### 6.1 Merge Mechanism

```bash
# Per fragment:
if merge_config.sh exists:
    merge_config.sh -m -O "${BDIR}" "${BDIR}/.config" "$f"
else:
    cat "$f" >> "${BDIR}/.config"  # DANGEROUS: duplicate keys
```

**Issues:**
1. **Duplicate CONFIG keys across fragments** — `CONFIG_MODULES`, `CONFIG_MODULE_UNLOAD`, `CONFIG_ZRAM`, `CONFIG_CMA`, `CONFIG_DMA_CMA`, `CONFIG_PSI`, `CONFIG_ANDROID`, `CONFIG_ANDROID_BINDER_*`, `CONFIG_PSTORE*`, `CONFIG_ARCH_QCOM` all appear in multiple fragments. With `merge_config.sh` this is fine (last wins); with `cat` it's broken (duplicate lines).
2. **No verification** that fragments are actually applied
3. **No final config validation** — no script checks that critical CONFIGs are set

### 6.2 Config Fragment Inventory

| Fragment | Lines | Status | Key CONFIGs |
|----------|-------|--------|-------------|
| android-gki.config | 38 | Active | ANDROID, BINDER, SELINUX, CGROUPS, BPF, USB_CONFIGFS |
| sdm660.config | 31 | Active | ARCH_QCOM, RPMH, GENI, MMC, USB, PHY |
| whyred.config | 61 | Active | DRM_MSM, WHYRED_*, WCD9335, ATH10K, QRTR |
| hybrid.config | 45 | Active | MODULES, CMA, ZRAM, ZSWAP, BTF=n, PSTORE |
| lts-6.18.config | 36 | Active | LOCALVERSION_AUTO, IKCONFIG, MODULES (dup), PSTORE (dup) |
| whyred-419.config | 13 | 4.19 only | LOCALVERSION, KPROBES, ZRAM |
| bringup/stage1 | 17 | Cumulative | SERIAL_MSM, EARLYCON, DEVTMPFS |
| bringup/stage2 | 10 | Cumulative | MMC, EXT4 |
| bringup/stage3 | 14 | Cumulative | USB, DWC3, CONFIGFS |
| bringup/stage4 | 10 | Cumulative | FB_SIMPLE, DRM_MSM |
| bringup/stage5 | 9 | Cumulative | I2C, TOUCHSCREEN, WHYRED_TOUCH |

### 6.3 Specific Config Issues

1. **`CONFIG_TOUCHSCREEN_NT36XXX=m`** — declared in `whyred.config` but depends on whether this Kconfig symbol exists in ACK 6.18. If it doesn't exist, the fragment is silently ignored.
2. **`CONFIG_SND_SOC_WCD9335=m`** — same concern; WCD9335 may not be in ACK 6.18 tree.
3. **`CONFIG_ATH10K=m` + `CONFIG_ATH10K_SNOC=m`** — ath10k depends on `CONFIG_ATH10K_SNOC` which requires SNOC bus support.
4. **`CONFIG_BATTERY_QCOM_BATTMGR=m` + `CONFIG_CHARGER_QCOM_SMB2=m`** — these are downstream Qualcomm symbols; may not exist in ACK.
5. **`CONFIG_QCOM_Q6V5_MSS=m`** — Modem subsystem driver; critical for cellular but requires PIL + remoteproc chain.
6. **`CONFIG_FB_SIMPLE=y`** in both `stage4-display.config` AND `whyred.config` — redundant.
7. **`CONFIG_TOUCHSCREEN_EDT_FT5X06=m`** in `whyred.config` — this is for EDT/FocalTech, not Novatek. Likely copied from lavender. **Should be removed for whyred.**
8. **`CONFIG_NFC_NXP_NCI=m`** — NFC driver; hardware may or may not exist on whyred. **Needs verification.**
9. **`CONFIG_IIO_ST_LSM6DSX=m` + `CONFIG_IIO_ST_LSM6DSX_I2C=m`** — accelerometer/gyroscope; usually not on whyred. **Needs verification.**

---

## 7. Current Device Tree Source

### 7.1 File Structure

```
arch/arm64/boot/dts/qcom/
  sdm636.dtsi                        (17 lines) — SoC delta over sdm660
  sdm636-xiaomi-whyred.dts           (269 lines) — main board DTS
  sdm636-xiaomi-whyred-pmic.dtsi     (253 lines) — PM660/PM660L regulators
  sdm636-xiaomi-whyred-pinctrl.dtsi  (89 lines)  — TLMM pinctrl
  sdm636-xiaomi-whyred-reserved.dtsi (51 lines)  — splash + ramoops
  sdm636-xiaomi-whyred-bringup.dtsi  (89 lines)  — stage-gated status
```

### 7.2 Include Chain

```
sdm636-xiaomi-whyred.dts
  ├── sdm636.dtsi → sdm660.dtsi (upstream SoC base)
  ├── pm660.dtsi (upstream PMIC)
  ├── pm660l.dtsi (upstream PMIC LDO)
  ├── <dt-bindings/gpio/gpio.h>
  ├── <dt-bindings/input/input.h>
  ├── <dt-bindings/interrupt-controller/irq.h>
  ├── <dt-bindings/pinctrl/qcom,pmic-gpio.h>
  ├── <dt-bindings/whyred/whyred.h>       (GPIO constants, msm-id)
  ├── <dt-bindings/whyred/bringup.h>       (stage macros)
  ├── sdm636-xiaomi-whyred-pmic.dtsi       (regulator tree)
  ├── sdm636-xiaomi-whyred-pinctrl.dtsi    (pin states)
  ├── sdm636-xiaomi-whyred-reserved.dtsi   (reserved memory)
  └── sdm636-xiaomi-whyred-bringup.dtsi    (status overrides, last)
```

### 7.3 DT Identity

| Property | Value | Source |
|----------|-------|--------|
| `model` | "Xiaomi Redmi Note 5 Pro" | Stock |
| `compatible` | "xiaomi,whyred", "qcom,sdm636", "qcom,sdm660" | Stock + mainline pattern |
| `qcom,msm-id` | `<345 0x0>` | Stock sdm636.dtsi (msm-id 345 = SDM636) |
| `qcom,board-id` | `<0x30008 0>, <0x10008 0>` | Stock sdm636-mtp-whyred.dts |
| `qcom,pmic-id` | PM660+PM660L triples | Stock sdm636-mtp-whyred.dts |

### 7.4 Critical DT Nodes

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

### 7.5 Reserved Memory

| Region | Address | Size | Status |
|--------|---------|------|--------|
| `framebuffer_mem` | 0x9d400000 | 0x023ff000 (36MB) | Present in reserved.dtsi |
| `ramoops` | 0xa0000000 | 0x00400000 (4MB) | Present in reserved.dtsi |
| modem/adsp/smem/tz | various | various | **NOT in project DT** — relies on upstream sdm660.dtsi/sdm630.dtsi |

**Critical gap:** The upstream sdm660.dtsi/sdm630.dtsi in the ACK tree may NOT contain the correct reserved-memory map for SDM636. The stock reserved-memory regions (modem 0x8ac00000, adsp 0x92a00000, etc.) are documented in `STOCK_AUDIT.md` but **only the splash and ramoops are actually defined in the project's DT**. The SoC-level reserved regions must come from the upstream SoC dtsi — which may have different addresses or be missing entirely.

### 7.6 DT Binding Constants (`whyred.h`)

```c
WHYRED_PANEL_WIDTH      1080
WHYRED_PANEL_HEIGHT     2160
WHYRED_MSM_ID           345
WHYRED_BOARD_ID_0       0x30008
WHYRED_BOARD_ID_1       0x10008
WHYRED_GPIO_SD_CD       54
WHYRED_GPIO_USB_ID      58
WHYRED_GPIO_TP_RESET    66
WHYRED_GPIO_TP_INT      67
WHYRED_GPIO_FP_RESET    20
WHYRED_GPIO_FP_INT      72
WHYRED_GPIO_HALL_INT    75
WHYRED_PM660L_GPIO_VOL_UP 7
WHYRED_NT36XXX_I2C_ADDR 0x62
WHYRED_FB_PHYS_BASE     0x9d400000
WHYRED_FB_SIZE          0x023ff000
WHYRED_RAMOOPS_BASE     0xa0000000
WHYRED_RAMOOPS_SIZE     0x00400000
WHYRED_UART_EARLYCON_ADDR 0x0c170000
```

Source: LineageOS vendor DT reference (lineage-20), cross-referenced with mainline sdm660-xiaomi-lavender.

---

## 8. Current Custom Drivers

### 8.1 Driver Inventory

| Driver | File | Type | Kconfig | Compatible | Status |
|--------|------|------|---------|------------|--------|
| whyred_board | whyred_board.c | platform | `WHYRED_BOARD` (y) | `xiaomi,whyred-board` | Working glue (sysfs) |
| whyred_panel | display/whyred_panel.c | module | `WHYRED_DISPLAY` (m) | — | Sysfs geometry only |
| whyred_touch | touch/whyred_touch.c | i2c | `WHYRED_TOUCH` (m) | `xiaomi,whyred-touch` | Reset glue only |
| whyred_power | power/whyred_power.c | platform | `WHYRED_POWER` (m) | `xiaomi,whyred-power` | Placeholder battery PSY |
| whyred_wlan | wlan/whyred_wlan.c | platform | `WHYRED_WLAN` (m) | `xiaomi,whyred-wlan` | Sysfs hints only |
| whyred_audio | audio/whyred_audio.c | platform | `WHYRED_AUDIO` (m) | `xiaomi,whyred-audio` | Placeholder (logs only) |
| whyred_camera | camera/whyred_camera.c | platform | `WHYRED_CAMERA` (m) | `xiaomi,whyred-camera` | Placeholder (logs only) |

### 8.2 Driver Assessment

| Driver | Does Real HW Work? | Upstream Equivalent | Recommendation |
|--------|--------------------|--------------------|----------------|
| whyred_board | No (sysfs only) | None needed | Keep as board glue |
| whyred_panel | No | DRM panel driver needed | Replace with real panel driver |
| whyred_touch | No (reset pulse only) | `TOUCHSCREEN_NT36XXX` / nvt-ts | Use in-tree nvt driver |
| whyred_power | No (fake values) | `CHARGER_QCOM_SMB2` + FG | Replace with real PMIC drivers |
| whyred_wlan | No | `ATH10K_SNOC` | Use in-tree ath10k |
| whyred_audio | No | `SND_SOC_QCOM` + WCD machine | Replace with real audio stack |
| whyred_camera | No | CAMSS + sensor drivers | Replace with real camera stack |

**All whyred-specific drivers are placeholders/stubs.** None perform actual hardware operations. They exist for:
1. Build system validation
2. Sysfs debugging interfaces
3. Documentation of hardware parameters
4. Future glue if needed

### 8.3 Driver Build Integration

```makefile
# drivers/whyred/Makefile
obj-$(CONFIG_WHYRED_BOARD)   += whyred_board.o
obj-$(CONFIG_WHYRED_DISPLAY) += display/
obj-$(CONFIG_WHYRED_TOUCH)   += touch/
obj-$(CONFIG_WHYRED_AUDIO)   += audio/
obj-$(CONFIG_WHYRED_CAMERA)  += camera/
obj-$(CONFIG_WHYRED_POWER)   += power/
obj-$(CONFIG_WHYRED_WLAN)    += wlan/
```

`whyred_board` is `=y` (built-in) when stage ≥ 1; all others are `=m` (modules).

---

## 9. Current Known Build Blockers

### 9.1 Already Fixed

| Issue | Fix | Status |
|-------|-----|--------|
| LOCALVERSION > 64 chars | Shortened in PROJECT.conf, removed from lts-6.18.config | ✅ Fixed |
| `dwarf.h` not found | `libdwarf-dev` + symlink for Ubuntu 24.04 paths | ✅ Fixed |
| `elfutils/libdw.h` not found | `libdw-dev` package added | ✅ Fixed |
| `actions/checkout@v4` (Node 16) | Upgraded to `@v7` (Node 24) | ✅ Fixed |

### 9.2 Workarounds Applied

| Issue | Workaround | Impact |
|-------|-----------|--------|
| BTF resolve_btfids "Invalid argument" | `CONFIG_DEBUG_INFO_BTF=n` in hybrid.config | BTF disabled; no kfunc/BPF CO-RE |

### 9.3 Potential Build Issues (Not Yet Triggered)

| Risk | Condition | Mitigation |
|------|-----------|------------|
| Missing Kconfig symbols | `TOUCHSCREEN_NT36XXX`, `WCD9335`, `ATH10K_SNOC` may not exist in ACK | `olddefconfig` resolves, but options silently dropped |
| `merge_config.sh` fallback | If merge_config.sh missing, `cat >> .config` produces duplicates | Verify merge_config.sh exists in ACK tree |
| Drivers/whyred not compiled | If `drivers/Kconfig` or `drivers/Makefile` wiring fails silently | Verify grep patterns |
| DTS compilation | DTS may reference upstream nodes (sdm660.dtsi, pm660.dtsi) that differ in ACK | DT compilation test needed |

---

## 10. Current Known Boot Blockers

### 10.1 Hard Blockers (Must Fix Before Boot)

| # | Blocker | Risk Level |
|---|---------|-----------|
| 1 | **No real Device Tree validation against device** — all DT values from LineageOS reference, not actual dump | **CRITICAL** |
| 2 | **Reserved-memory regions for modem/adsp depend on upstream SoC dtsi** — if ACK's sdm660.dtsi/sdm630.dtsi doesn't define them, kernel will fail to boot or crash | **CRITICAL** |
| 3 | **qcom,msm-id / qcom,board-id not verified against device** — wrong values → bootloader rejects kernel | **CRITICAL** |
| 4 | **No real panel driver** — simple-fb may not survive bootloader handoff correctly | HIGH |
| 5 | **PMIC regulator tree from sdm660-xiaomi-lavender** — voltage rails may differ for SDM636/PM660 | HIGH |

### 10.2 Soft Blockers (May Cause Issues)

| # | Issue | Impact |
|---|-------|--------|
| 6 | No real MMC tuning data | eMMC may fail at HS400 |
| 7 | No real touch driver wiring | Touch won't work but boot succeeds |
| 8 | No real audio codec binding | Audio won't work but boot succeeds |
| 9 | No real WLAN firmware path | WiFi won't work but boot succeeds |
| 10 | No real charger/FG binding | Battery shows fake 50% but boot succeeds |

### 10.3 Unknown Blockers

| # | Unknown | How to Determine |
|---|---------|-----------------|
| 11 | Whether `blsp1_uart2` address matches ACK's SoC dtsi | Compare ACK's sdm660.dtsi with stock |
| 12 | Whether GENI serial driver is in ACK | Check `CONFIG_SERIAL_QCOM_GENI` |
| 13 | Whether SDHCI MSM driver is in ACK | Check `CONFIG_MMC_SDHCI_MSM` |
| 14 | Whether DRM MSM is in ACK | Check `CONFIG_DRM_MSM` |
| 15 | Whether `TOUCHSCREEN_NT36XXX` exists in ACK | Check Kconfig |

---

## 11. Current Unsupported Assumptions

| # | Assumption | Evidence | Risk |
|---|-----------|----------|------|
| 1 | Stock DTB data from LineageOS ref matches actual device | No device dump available | HIGH — msm-id, GPIOs, regulators could differ |
| 2 | Upstream sdm660.dtsi in ACK has correct reserved-memory for SDM636 | Not verified | HIGH — missing regions → crash |
| 3 | MMC regulator voltages from lavender work for whyred | Same PMIC family (PM660/PM660L) | MEDIUM — likely OK but unverified |
| 4 | Touch I2C bus = blsp_i2c1 (stock i2c_1) | LineageOS ref confirms | LOW — likely correct |
| 5 | Panel is 1080x2160 with simple-fb at 0x9d400000 | Stock splash matches | LOW — likely correct |
| 6 | `earlycon=msm_serial_dm,0x0c170000` is correct | LineageOS ref + mainline | LOW — likely correct |
| 7 | PMIC IDs (triples) match device | From stock sdm636-mtp-whyred | MEDIUM — should verify |
| 8 | GPIO reservations (8-11) are correct | From pinctrl dtsi comment | LOW — hyp/TZ reserve |
| 9 | All CONFIG_ symbols exist in ACK 6.18 | Not verified | MEDIUM — olddefconfig drops unknowns |

---

## 12. Recommended Execution Order

### Phase 0 (this audit) ✅

### Phase 1 — Source Lock
**Priority: HIGH — Must do before any other phase**

1. Pin ACK commit in PROJECT.conf (e.g., `GKI_COMMIT="abc1234"`)
2. In setup.sh: `git checkout $GKI_COMMIT` after clone
3. Generate complete `build-info.txt` with:
   - ACK commit hash
   - Project commit hash
   - Config fragments hash
   - Compiler version (clang, lld, llvm)
   - pahole version
   - binutils version
   - Build host
   - Timestamp
4. Generate `SHA256SUMS` for all artifacts

**Files to change:** `PROJECT.conf`, `scripts/setup.sh`, `scripts/build.sh`

### Phase 2 — Patch Safety
**Priority: HIGH — Required before any patches are added**

1. Fix `apply-patches.sh`:
   - Required patches: exit non-zero on failure
   - Track result per patch: APPLIED / ALREADY_APPLIED / FAILED / SKIPPED
   - Generate patch report
2. Fix CI workflow: remove `|| echo "::warning::..."` masking failures

**Files to change:** `scripts/apply-patches.sh`, `.github/workflows/build-kernel.yml`

### Phase 3 — Config Validation
**Priority: HIGH — Required before build is trustworthy**

1. Create `scripts/validate-config.sh`:
   - Verify ARM64 architecture
   - Verify critical CONFIGs are enabled after merge
   - Verify whyred-specific CONFIGs
   - Check for known-broken combinations
2. Remove duplicate CONFIG entries across fragments
3. Remove CONFIGs that likely don't exist in ACK 6.18 (mark as TODO)
4. Create `docs/CONFIGURATION.md`

**Files to change:** `scripts/validate-config.sh` (new), config fragments, `docs/CONFIGURATION.md` (new)

### Phase 4 — BTF Investigation
**Priority: MEDIUM — Document and resolve**

1. Check pahole version in CI (needs >= 1.25 for 6.18 BTF)
2. Investigate resolve_btfids "Invalid argument" root cause
3. If fixable: fix and re-enable BTF
4. If not: document the workaround and keep disabled

**Files to change:** `configs/fragments/hybrid.config`, `.github/workflows/build-kernel.yml`

### Phase 5 — Device Tree Forensic Validation
**Priority: HIGH — Critical for boot**

1. Compare upstream sdm660.dtsi in ACK with stock reserved-memory
2. Verify all GPIO numbers against actual device dump (when available)
3. Verify PMIC regulator values against stock
4. Create `docs/DEVICE_TREE_VALIDATION.md`
5. Create `scripts/validate-dtb.sh`

**Files to change:** `docs/DEVICE_TREE_VALIDATION.md` (new), `scripts/validate-dtb.sh` (new)

### Phase 6 — Build Validation Gate
**Priority: HIGH — Required for trustworthy CI**

1. Create `scripts/validate-build.sh`:
   - Verify Image.gz exists and is correct architecture
   - Verify DTB exists with correct compatible
   - Verify config was applied correctly
   - Generate validation-report.txt
2. Integrate into build pipeline (fail build if validation fails)

**Files to change:** `scripts/validate-build.sh` (new), `scripts/build.sh`

### Phase 7 — Boot Artifact Packaging
**Priority: HIGH — Required for device testing**

1. Determine actual whyred boot architecture:
   - Header version (v0/v1/v2/v3)
   - Kernel placement
   - DTB placement (separate or appended)
   - Page size, base address
   - vendor_boot requirements
2. Fix pack.sh for correct boot image format
3. Add boot image size/hash reporting

**Files to change:** `scripts/pack.sh`, `pack/AnyKernel3/anykernel.sh`

### Phase 8 — Documentation Updates
**Priority: MEDIUM**

1. Update README.md — accurate status claims
2. Create `docs/DRIVER_STATUS.md`
3. Create `docs/ANDROID_COMPATIBILITY.md`
4. Create `docs/BUILD_REPRODUCIBILITY.md`

### Phase 9+ — Hardware Bring-up (after image boots)
1. Stage 1: UART earlycon
2. Stage 2: eMMC
3. Stage 3: USB
4. Stage 4: simple-fb
5. Stage 5: Touch
6. Stages 6-11: WiFi, power, audio, camera, Android userspace

---

## Appendix A: File Inventory

### Project Files (113+ files)

| Category | Count | Key Files |
|----------|-------|-----------|
| Scripts | 12 | setup.sh, build.sh, pack.sh, validate.sh, ci-env.sh, apply-patches.sh, etc. |
| Config fragments | 11 | android-gki, sdm660, whyred, hybrid, lts-6.18, whyred-419, stage1-5 |
| Device Tree | 6 | sdm636.dtsi, whyred.dts, pmic.dtsi, pinctrl.dtsi, reserved.dtsi, bringup.dtsi |
| DT constants | 2 | whyred.h, bringup.h |
| Custom drivers | 13 | whyred_board.c + 6 subdirectories (display, touch, power, wlan, audio, camera) |
| CI workflows | 3 | build-kernel.yml, validate.yml, release.yml |
| Documentation | 12 | AUDIT_6.18, ARCHITECTURE, BRINGUP, DEVICE_TREE, DRIVERS, etc. |
| AnyKernel3 | 2 | anykernel.sh, META-INF |
| Vendor | 3 | stock-dt ref, modules.load, .gitkeep |
| Patches | 4 README | Empty patch directories (gki, sdm660, android, 4.19) |

### Stock Reference (vendor/import/stock-dt/ref-lineage20/)

21 files from LineageOS `android_kernel_xiaomi_sdm660` branch `lineage-20`:
- Board-level DTS: `sdm636-mtp-whyred.dts`
- SoC DTSIs: `sdm636.dtsi`, `sdm660.dtsi`, `sdm660-common.dtsi`, `sdm660-blsp.dtsi`, `sdm660-mtp.dtsi`
- Xiaomi DTSIs: `whyred.dtsi`, `whyred-base.dtsi`, `xiaomi-sdm660-common.dtsi`
- Longcheer DTSIs: `longcheer-sdm660-base.dtsi`, `longcheer-sdm636.dtsi`, `longcheer-sdm660-pinctrl.dtsi`, `longcheer-sdm660-ramoops.dtsi`, `longcheer-sdm660-mtp.dtsi`, `longcheer-sdm660-mdss.dtsi`, `longcheer-pm660.dtsi`
- Touch DTSI: `sdm660-novatek-i2c_d2s.dtsi`
- Mainline references: `mainline-sdm630.dtsi`, `mainline-sdm660.dtsi`

### Stock DTB Extraction (vendor/import/stock-dt/)

36 extracted DTBs (`dtb-00.dtb` through `dtb-35.dtb`) from actual whyred boot.img, plus `stock-whyred-selected.dtb`. **These have been extracted but NOT compared with hybrid DT.**

---

## Appendix B: Critical Questions Requiring Answers

1. **Does ACK `android17-6.18` include `sdm660.dtsi`?** If not, the build will fail at DTS compilation.
2. **Does ACK `android17-6.18` include `sdm630.dtsi`?** This defines base SoC reserved-memory.
3. **Does ACK `android17-6.18` include `TOUCHSCREEN_NT36XXX`?** If not, touch module won't build.
4. **Does ACK `android17-6.18` include `SERIAL_QCOM_GENI`?** Required for UART.
5. **Does ACK `android17-6.18` include `MMC_SDHCI_MSM`?** Required for eMMC.
6. **Does ACK `android17-6.18` include `DRM_MSM`?** Required for display.
7. **Does ACK `android17-6.18` include `ATH10K_SNOC`?** Required for WiFi.
8. **What is the actual boot image header format for whyred?** (v0/v1/v2/v3)
9. **What is the actual reserved-memory map on the physical device?** (Only a device dump can answer)
10. **Is `earlycon=msm_serial_dm` the correct earlycon driver for GENI serial?** (May need `earlycon=msm_serial` or `earlycon=pl011`)

---

## Appendix C: Immediate Next Steps

After this audit, the **exact next action** should be:

1. **Answer the 10 questions in Appendix B** by cloning ACK and inspecting its Kconfig/DTS
2. **Then proceed to PHASE 1** — pin commit + generate build-info

Do NOT proceed to Phase 2+ until Phase 1 is complete.
