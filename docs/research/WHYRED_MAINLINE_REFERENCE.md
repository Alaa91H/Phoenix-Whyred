# Whyred Mainline Reference: sdm660-mainline DTS Analysis

## Device Identity

| Property | Value |
|----------|-------|
| Device | Xiaomi Redmi Note 5 Pro |
| Codename | whyred |
| SoC | SDM636 (SDM660 family) |
| Compatible | `"xiaomi,whyred", "qcom,sdm636"` |
| Chassis | `"handset"` |
| Source | `sdm660-mainline/linux` branch `qcom-sdm660-7.0.y` |

## DTS Includes

```dts
#include "sdm636.dtsi"    // → sdm660.dtsi → sdm630.dtsi
#include "pm660.dtsi"     // PMIC main
#include "pm660l.dtsi"    // PMIC LDO/boost
```

**Note**: No direct `#include "sdm660.dtsi"` — inherited through `sdm636.dtsi`.

## Device Tree Structure

### Display

| Property | Value |
|----------|-------|
| Panel | `"tianma,td4310-xiaomi-whyred"` |
| Resolution | 1080 × 2160 |
| Backlight | `pm660l_wled` |
| Reset GPIO | `tlmm 53` (active low) |
| Simple Framebuffer | `0x9d400000` (1080 × 2160 × 4 bytes) |
| Size | 68mm × 136mm |

### Touchscreen (Synaptics RMI4 E753)

| Property | Value |
|----------|-------|
| Compatible | `"syna,rmi4-i2c"` |
| I2C Address | `0x20` |
| Bus | `blsp_i2c1` |
| IRQ | `tlmm 67` (edge falling) |
| Reset GPIO | `tlmm 66` (active low) |
| Power Supply | `vreg_l11a_1p8` |
| Reset Delay | 300ms |
| Startup Delay | 600ms |

**Important**: This is a **Synaptics** touch, not Novatek as initially reported. The sdm660-mainline DTS confirms Synaptics RMI4 E753.

### USB

| Property | Value |
|----------|-------|
| Controller | DWC3 |
| PHY | QUSB2 |
| Mode | `peripheral` (USB device only) |
| Max Speed | High-speed |
| Pipe Clock | UTMI |

### WiFi (WCN3990)

| Supply | Source |
|--------|--------|
| vdd-0.8-cx-mx | `vreg_l5a_0p848` |
| vdd-1.8-xo | `vreg_l9a_1p8` |
| vdd-1.3-rfa | `vreg_l6a_1p3` |
| vdd-3.3-ch0 | `vreg_l19a_3p3` |
| vdd-3.3-ch1 | `vreg_l19a_3p3` |

### Bluetooth (WCN3990)

| Property | Value |
|----------|-------|
| Compatible | `"qcom,wcn3990-bt"` |
| UART | `blsp2_uart1` |
| Max Speed | 3,200,000 baud |
| VDDXO | `vreg_l9a_1p8` |
| VDDRF | `vreg_l6a_1p3` |
| VDDCH0 | `vreg_l19a_3p3` |
| VDDIO | `vreg_l13a_1p8` |

### GPU (Adreno 509)

| Property | Value |
|----------|-------|
| Compatible | `"qcom,adreno-509.0", "qcom,adreno"` |
| Status | `okay` |
| ZAP Firmware | `a512_zap.mbn` |
| Memory Region | `zap_shader_region` @ `0xfbc00000` (8KB) |

**Note**: Adreno 509, NOT 512. SDM636 has reduced GPU vs SDM660.

### Modem (MSS)

| Property | Value |
|----------|-------|
| Firmware | `mba.mbn`, `modem.mdt` |
| Status | `okay` |

### GPIO Keys

| Key | GPIO | Type |
|-----|------|------|
| Volume Up | `pm660l_gpios 7` | `KEY_VOLUMEUP` |
| Volume Down | `pm660l_gpios 6` | `KEY_VOLUMEDOWN` |
| Edge Hall | `tlmm 75` | `SW_LID` |

### Sensors

| Sensor | GPIO | Type |
|--------|------|------|
| Hall Effect | `tlmm 75` | `SW_LID` |

## Regulator Configuration

### PM660

| Regulator | Voltage | Notes |
|-----------|---------|-------|
| `vreg_s4a_2p04` | 1.805-2.04V | **always-on** |
| `vreg_s5a_1p35` | 1.224-1.35V | |
| `vreg_s6a_0p87` | 0.504-0.992V | |
| `vreg_l13a_1p8` | 1.78-1.95V | **always-on + boot-on** (LPDDR4) |
| `vreg_l16a_2p7` | 2.8V fixed | **always-on** |

### PM660L

| Regulator | Voltage | Notes |
|-----------|---------|-------|
| `vreg_bob` | 3.3-3.6V | ramp delay 500 |
| `vreg_l1b_0p925` | 0.8-0.925V | allow-set-load |
| `vreg_l2b_2p95` | 1.648-3.1V | SDHCI 3.3V not supported |
| `vreg_l3b_3p3` | 1.71-3.6V | **always-on** |
| `vreg_l5b_2p95` | 1.8-3.328V | system-load 800mA |
| `vreg_l7b_3p125` | 2.7-3.125V | |
| `vreg_l8b_3.3` | 3.2-3.4V | |

## Key Differences from Phoenix-Whyred DTS

| Aspect | sdm660-mainline | Phoenix-Whyred |
|--------|-----------------|----------------|
| Touch | Synaptics RMI4 E753 | Novatek NT36672C |
| Panel | Tianma TD4310 | Different |
| MSM IDs | None (bootloader) | qcom,msm-id/board-id/pmic-id |
| GPU Firmware | `a512_zap.mbn` | Different |
| Modem Firmware | `mba.mbn` + `modem.mdt` | Different |
| USB Mode | peripheral only | host + peripheral |
| ZAP Shader | 8KB @ 0xfbc00000 | Different size/location |

## Recommendations

1. **Use sdm660-mainline DTS as primary reference** — it's proven to boot
2. **Adapt Phoenix-specific additions** (if any) on top
3. **Test touchscreen first** — Synaptics vs Novatek difference is critical
4. **Verify display panel** — Tianma TD4310 may differ from Phoenix's panel
5. **Keep modem firmware names** — sdm660-mainline uses standard names
