# Device Tree Audit — whyred (SDM636)

> **Target**: Linux Mainline 6.18 LTS
> **Base DTS**: `sdm636-xiaomi-whyred.dts` + 4 include files
> **Upstream DTSI chain**: `sdm636.dtsi` → `sdm660.dtsi` → `sdm630.dtsi`
> **Created**: 2026-07-18

## Methodology

Every DT node is classified against **mainline Linux 6.18 bindings** (not downstream 4.19).
Nodes are only added if required by confirmed hardware and mainline bindings.

## Classification Key

| Action | Meaning |
|---|---|
| `KEEP_AS_IS` | Node exists, correct, no changes needed |
| `FIX` | Node exists but has incorrect properties or references |
| `ADD` | Node missing; required for hardware; must be added |
| `REMOVE` | Node exists but is unnecessary for mainline |
| `REPLACE_WITH_UPSTREAM` | Custom node should be replaced by upstream DTSI include |
| `UNKNOWN` | Insufficient data to classify |

---

## 1. Root Node (`/`)

### `sdm636-xiaomi-whyred.dts`

| Property | Current Value | Action | Notes |
|---|---|---|---|
| `model` | "Xiaomi Redmi Note 5 Pro" | `KEEP_AS_IS` | Correct |
| `compatible` | "xiaomi,whyred", "qcom,sdm636", "qcom,sdm660" | `FIX` | Mainline uses `qcom,sdm636` as primary; "xiaomi,whyred" is board-specific |
| `chassis-type` | "handset" | `KEEP_AS_IS` | Correct for phone |
| `qcom,msm-id` | `<345 0x0>` | `FIX` | Value 345 is correct (SDM636), but format may need adjustment for mainline |
| `qcom,board-id` | `<0x30008 0>, <0x10008 0>` | `FIX` | Board IDs from stock; verify these match what bootloader expects |
| `qcom,pmic-id` | 3 PMIC entries | `KEEP_AS_IS` | Correct for PM660+PM660L |

### `sdm636.dtsi` (project overlay)

| Node | Action | Notes |
|---|---|---|
| `#include "sdm660.dtsi"` | `KEEP_AS_IS` | Correct — mainline include chain |
| `&adreno_gpu` compatible override | `FIX` | Needs verification: upstream `qcom,adreno-509.0` may not be recognized; may need `qcom,adreno-509` (without `.0`) |

---

## 2. `/chosen` Node

| Property | Action | Notes |
|---|---|---|
| `stdout-path` | `KEEP_AS_IS` | "serial0:115200n8" — correct |
| `bootargs` | `FIX` | `earlycon=msm_serial_dm,0x0c170000` — verify this is the correct earlycon driver name for GENI serial in mainline 6.18 |
| `framebuffer0` (simple-fb) | `KEEP_AS_IS` | Correct pattern; uses `WHYRED_FB_PHYS_BASE` and `WHYRED_PANEL_WIDTH/HEIGHT` |

---

## 3. `aliases` Node

| Alias | Target | Action | Notes |
|---|---|---|---|
| `serial0` | `&blsp1_uart2` | `KEEP_AS_IS` | Correct — upstream label exists in sdm630.dtsi |
| `mmc0` | `&sdhc_1` | `KEEP_AS_IS` | Correct — upstream label exists in sdm630.dtsi |
| `mmc1` | `&sdhc_2` | `KEEP_AS_IS` | Correct — upstream label exists in sdm630.dtsi |

---

## 4. GPIO Keys

| Node | Action | Notes |
|---|---|---|
| `gpio-keys` | `KEEP_AS_IS` | Correct pattern |
| `key-volup` GPIO | `FIX` | Uses `WHYRED_PM660L_GPIO_VOL_UP` (7) — verify PM660L GPIO numbering |

---

## 5. USB

| Node | Action | Notes |
|---|---|---|
| `extcon_usb` | `KEEP_AS_IS` | Correct pattern for USB ID detection |
| `&qusb2phy0` supplies | `FIX` | Verify supply rail references match upstream pm660l regulator labels |
| `&usb3` properties | `KEEP_AS_IS` | `qcom,select-utmi-as-pipe-clk` — verify this property exists in mainline DWC3-QCOM binding |
| `&usb3_dwc3` | `KEEP_AS_IS` | Correct configuration |

---

## 6. eMMC / SD

| Node | Action | Notes |
|---|---|---|
| `&sdhc_1` | `KEEP_AS_IS` | Correct — eMMC with HS200/HS400 support |
| `&sdhc_2` | `KEEP_AS_IS` | Correct — SD card with CD GPIO |

---

## 7. Display

| Node | Action | Notes |
|---|---|---|
| `&pm660l_wled` | `KEEP_AS_IS` | Correct WLED configuration |

---

## 8. Touchscreen

| Node | Action | Notes |
|---|---|---|
| `&blsp_i2c1` | `KEEP_AS_IS` | Correct I2C bus (BLSP1 QUP1 @ 0x0c175000) |
| `touchscreen@62` | `FIX` | Compatible "novatek,nt36525" — verify this matches mainline `TOUCHSCREEN_NT36XXX` driver binding |
| Touch GPIO references | `KEEP_AS_IS` | Correct GPIO assignments |

---

## 9. Fingerprint

| Node | Action | Notes |
|---|---|---|
| `goodix_fp` | `REMOVE` | No mainline driver; node is `status = "disabled"` anyway; remove to reduce DTS noise |

---

## 10. GPU

| Node | Action | Notes |
|---|---|---|
| `&adreno_gpu` | `FIX` | Status "okay" is correct; verify compatible string works with mainline `adreno` driver |

---

## 11. Board Glue

| Node | Action | Notes |
|---|---|---|
| `whyred_board` | `REMOVE` | Board identity driver provides no boot-critical function; sysfs only; remove for minimal first boot |

---

## 12. PMIC (`sdm636-xiaomi-whyred-pmic.dtsi`)

| Node | Action | Notes |
|---|---|---|
| `vph_pwr` | `KEEP_AS_IS` | Correct — virtual power rail |
| `regulators-0` (PM660L) | `KEEP_AS_IS` | Correct regulator tree matching mainline pm660l.dtsi |
| `regulators-1` (PM660) | `KEEP_AS_IS` | Correct regulator tree matching mainline pm660.dtsi |

---

## 13. Pinctrl (`sdm636-xiaomi-whyred-pinctrl.dtsi`)

| Node | Action | Notes |
|---|---|---|
| `&tlmm` gpio-reserved-ranges | `FIX` | `<8 4>` — verify this is correct for SDM636; TZ/Hyp may reserve different ranges |
| Touch pinctrl states | `KEEP_AS_IS` | Correct |
| Fingerprint pinctrl states | `REMOVE` | Fingerprint disabled; remove unused pinctrl states |
| USB ID pinctrl | `KEEP_AS_IS` | Correct |
| SD CD pinctrl | `KEEP_AS_IS` | Correct |

---

## 14. Reserved Memory (`sdm636-xiaomi-whyred-reserved.dtsi`)

| Node | Action | Notes |
|---|---|---|
| `framebuffer_mem` | `KEEP_AS_IS` | Correct — matches stock cont_splash region |
| `ramoops` | `KEEP_AS_IS` | Correct — pstore for crash debugging |

---

## 15. PMIC Nodes (referenced from upstream)

| Label | Action | Notes |
|---|---|---|
| `&pon_pwrkey` | `FIX` | **MISSING in upstream pm660.dtsi** — upstream uses unnamed child node under `pon@800`. Need to add label or use path reference |
| `&pon_resin` | `FIX` | **MISSING in upstream pm660.dtsi** — upstream may use `pm660_resin` or similar. Need to add label or use path reference |

---

## 16. Bringup Gating (`sdm636-xiaomi-whyred-bringup.dtsi`)

| Node | Action | Notes |
|---|---|---|
| All stage-gated nodes | `KEEP_AS_IS` | Correct pattern for gradual bring-up |

---

## Summary

| Action | Count | Nodes |
|---|---|---|
| `KEEP_AS_IS` | 25 | Most core platform nodes |
| `FIX` | 8 | compatible, msm-id, board-id, earlycon, GPU compatible, touch compatible, pon_pwrkey, pon_resin |
| `ADD` | 0 | — |
| `REMOVE` | 2 | goodix_fp, whyred_board |
| `REPLACE_WITH_UPSTREAM` | 0 | — |

## Critical Fixes Required Before Build

1. **`pon_pwrkey` / `pon_resin` labels** — upstream pm660.dtsi does not define these labels. Options:
   a. Add labels to upstream pm660.dtsi (modifies upstream DTSI)
   b. Reference nodes by full path (e.g., `/soc/spmi@8800000/pmic@1/pon@800/pwrkey`)
   c. Remove pon_pwrkey/pon_resin nodes from whyred DTS and rely on upstream defaults

2. **GPU compatible string** — verify `"qcom,adreno-509.0"` works with mainline `adreno` driver

3. **Bootargs earlycon** — verify `msm_serial_dm` is correct for GENI serial in 6.18

4. **Kconfig symbols** — several config fragments reference symbols that may not exist in mainline 6.18
