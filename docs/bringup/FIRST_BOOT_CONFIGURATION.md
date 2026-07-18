# First Boot Configuration — Minimal Viable Build

> **Goal**: Clean Mainline 6.18 build → valid DTB → flashable boot image
> **Created**: 2026-07-18

## What This Configuration Enables

| Subsystem | Status | Config Source |
|---|---|---|
| ARM64 architecture | `=y` | defconfig |
| Qualcomm SDM660 platform | `=y` | sdm660.config |
| GCC clock controller | `=y` | whyred.config |
| UART console (GENI serial) | `=y` | sdm660.config |
| PMIC (SPMI arbiter + PM660/660L) | `=y` | whyred.config |
| Regulators | `=y` | whyred.config |
| Pinctrl (TLMM) | `=y` | whyred.config |
| eMMC (SDHCI MSM) | `=y` | whyred.config |
| USB (DWC3 + QUSB2 PHY) | `=y` | whyred.config |
| GPIO keys (volume up) | `=y` | whyred.config |
| I2C + SPI buses | `=y` | whyred.config |
| Device Tree | `=y` | defconfig |
| Remote processor (modem) | `=y` | whyred.config |
| QRTR (modem IPC) | `=y` | whyred.config |

## What This Configuration DOES NOT Enable

| Subsystem | Status | Why |
|---|---|---|
| Display (DRM/MDP5) | `is not set` | P1 — not needed for first boot |
| Touchscreen | `is not set` | P1 — not needed for first boot |
| GPU (freedreno) | `is not set` | P1 — not needed for first boot |
| Wi-Fi (ath10k) | `is not set` | P2 — not needed for first boot |
| Bluetooth | `is not set` | P2 — not needed for first boot |
| Audio (WCD9335) | `is not set` | P3 — not needed for first boot |
| Battery/Charger | `is not set` | P2 — not needed for first boot |
| Camera | `is not set` | P3 — not needed for first boot |
| Simple framebuffer | `is not set` | P1 — not needed for first boot |
| ZRAM/Swap | `is not set` | Not needed for first boot |
| PSTORE/Ramoops | `is not set` | Nice-to-have, not P0 |
| Board glue driver | `is not set` | Not needed for first boot |

## Build Commands

```bash
# Clone mainline 6.18 source
KERNEL_TRACK=6.18 ./scripts/setup.sh

# Build with stage 1 (UART only)
BRINGUP_STAGE=1 ./scripts/build.sh whyred

# Or build full stage 5 (UART+MMC+USB+display+touch)
BRINGUP_STAGE=5 ./scripts/build.sh whyred
```

## Expected Artifacts

| File | Description |
|---|---|
| `out/dist/Image.gz` | Compressed kernel image |
| `out/dist/sdm636-xiaomi-whyred.dtb` | Device tree blob |
| `out/dist/config` | Final .config |
| `out/dist/build-info.txt` | Build provenance |
| `out/dist/SHA256SUMS` | Artifact checksums |

## Config Fragment Merge Order

1. `defconfig` (mainline ARM64 defconfig)
2. `sdm660.config` (SoC enablement)
3. `whyred.config` (device-specific P0)
4. `lts-6.18.config` (LTS features)
5. `hybrid.config` (mainline glue — modules, CMA, scheduler)
6. Stage fragments (cumulative based on BRINGUP_STAGE)

## Known Risks

1. **Kconfig symbols** — `SDM_GPUCC_660`, `SDM_VIDEOCC_660`, `SDM_DISPCC_660`, `INTERCONNECT_QCOM_SDM660` may not exist in mainline 6.18. If build fails with "symbol not found", these need to be identified by their actual mainline names.

2. **DTS labels** — `pon_pwrkey` and `pon_resin` may not be defined in upstream pm660.dtsi. If DTS compilation fails, these references need to be fixed.

3. **GPU compatible** — `"qcom,adreno-509.0"` may not be recognized by mainline `adreno` driver. If so, try `"qcom,adreno-509"` or `"qcom,adreno"`.

4. **Earlycon** — `msm_serial_dm` may not be the correct earlycon driver name for GENI serial in mainline 6.18.
