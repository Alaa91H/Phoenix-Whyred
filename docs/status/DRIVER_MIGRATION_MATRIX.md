# Driver & Subsystem Migration Matrix

> **Device**: Xiaomi Redmi Note 5 Pro (`whyred`) | **SoC**: Qualcomm SDM636 (SDM660 family)
> **Primary Source**: Linux Mainline 6.18 LTS | **Reference**: Downstream Android 4.19 (LineageOS)
> **Last Updated**: 2026-07-18

## Classification Key

| Action | Meaning |
|---|---|
| `ALREADY_SUPPORTED` | Upstream mainline driver works; may need DT enablement only |
| `DEVICE_TREE_ONLY` | Mainline driver exists; only DT bindings/node needed |
| `MAINLINE_DRIVER_ADAPTATION` | Mainline driver exists but needs patching for SDM636/660 quirks |
| `UPSTREAM_PATCH_REQUIRED` | No upstream support for this specific hardware; patch needed |
| `DOWNSTREAM_REFERENCE_ONLY` | No mainline path; downstream 4.19 code is reference for future work |
| `NEW_DRIVER_REQUIRED` | No mainline or viable upstream driver; new driver needed |
| `UNKNOWN` | Insufficient data; requires further research |

## Risk Levels

| Level | Meaning |
|---|---|
| `NONE` | Already works upstream |
| `LOW` | Straightforward enablement; well-documented |
| `MEDIUM` | Requires adaptation; known issues exist |
| `HIGH` | Significant work; complex subsystem interaction |
| `CRITICAL` | Blocking; no viable mainline path currently |

## Priority

| Level | Meaning |
|---|---|
| `P0` | Must work for boot/basic functionality |
| `P1` | Required for daily-driver usability |
| `P2` | Important but non-blocking |
| `P3` | Nice-to-have; defer until stable |

---

## 1. Core Platform

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| CPU (8-core Kryo 260) | `qcom,gcc-sdm660` + DT | Upstream since ~5.9 | Qualcomm BSP | `ALREADY_SUPPORTED` | Fully upstream; `qcom,gcc-sdm660` + DTS present | NONE | P0 |
| CPUFreq (SCMI) | SCMI transport + `scmi-cpufreq` | Works on SDM660 | Qualcomm `qcom-cpufreq-hw` | `MAINLINE_DRIVER_ADAPTATION` | SCMI cpufreq works but **panics on SDM660 since 5.12**; known issue in sdm660-mainline. May use `CONFIG_ARM_QCOM_CPUFREQ_HW` instead | MEDIUM | P0 |
| PSCI Firmware | ARM SCMI/PSCI | Works | Qualcomm SCMI | `ALREADY_SUPPORTED` | Standard ARM PSCI; upstream | NONE | P0 |
| Timer/Arch Timer | ARM Generic Timer | Works | ARM Generic Timer | `ALREADY_SUPPORTED` | Standard ARM; upstream | NONE | P0 |
| GICv3 | ARM GICv3 | Works | ARM GICv3 | `ALREADY_SUPPORTED` | Standard ARM; upstream | NONE | P0 |

## 2. Memory & Storage

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| DDR (BIMC) | `qcom,sm6150-mc` or BL2 firmware | U-Boot handles init | Qualcomm DDR driver | `ALREADY_SUPPORTED` | BIMC DDR init handled by U-Boot BL2; kernel DDR freq scaling not needed at this stage | LOW | P0 |
| eMMC (SDHCI) | `qcom,sdm660-sdhci` | Upstream | Qualcomm SDHCI | `ALREADY_SUPPORTED` | DT present; `qcom,sdm660-sdhci` + `mmc-hs200-1_8v` | NONE | P0 |
| SD Card | Qualcomm SDHCI + `sd-uhs` | Upstream | Qualcomm SDHCI | `ALREADY_SUPPORTED` | DT present; `qcom,sdm660-sdhci` | NONE | P1 |

## 3. Clocks & Power

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| GCC Clock Controller | `qcom,gcc-sdm660` | Upstream | Qualcomm GCC driver | `ALREADY_SUPPORTED` | DT present; 320+ clock definitions | NONE | P0 |
| GPUCC | `qcom,gpucc-sdm660` | Upstream | Qualcomm GPUCC | `ALREADY_SUPPORTED` | Required for GPU/MDSS clock gating | LOW | P1 |
| VIDEOCC | `qcom,videocc-sdm660` | Upstream | Qualcomm VIDEOCC | `ALREADY_SUPPORTED` | Required for camera/video clocks | LOW | P1 |
| DISPCC | `qcom,dispcc-sdm660` | Upstream | Qualcomm DISPCC | `ALREADY_SUPPORTED` | Required for display clock control | LOW | P1 |

## 4. PMIC & Regulators

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| PM660 PMIC | `qcom,pm660` (regulator + RTC + GPIO + PON) | Upstream | Qualcomm PMIC driver | `ALREADY_SUPPORTED` | Regulators, RTC, GPIO all upstream | NONE | P0 |
| PM660L PMIC | `qcom,pm660l` (regulator + GPIO + LED) | Upstream | Qualcomm PMIC driver | `ALREADY_SUPPORTED` | Regulators, GPIO, LED/WLED upstream | NONE | P0 |
| Regulators (vddcx, etc.) | PMIC regulator framework | Upstream via PM660/660L | Qualcomm regulator driver | `ALREADY_SUPPORTED` | Sufficient for basic operation | NONE | P0 |
| WLED (Backlight) | PM660L LED driver | Upstream | Qualcomm LED driver | `DEVICE_TREE_ONLY` | Driver works; DT node `pm660l:leds` needed for display backlight | LOW | P1 |
| PON (Power-On) | PM660 PON driver | Upstream | Qualcomm PON | `ALREADY_SUPPORTED` | Reset/power-button handling | NONE | P0 |
| RTC | PM660 RTC | Upstream | Qualcomm PMIC RTC | `ALREADY_SUPPORTED` | Real-time clock on PM660 | NONE | P1 |

## 5. Interconnect (NoC)

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| ICC RPMh | `qcom,icc-rpmh-sdm660` | Upstream | Qualcomm ICC driver | `ALREADY_SUPPORTED` | Bandwidth voting framework | LOW | P1 |
| BIMC (Memory) | U-Boot / BL2 | U-Boot handles | Qualcomm DDR BW voting | `ALREADY_SUPPORTED` | Handled at firmware level | NONE | P0 |

## 6. GPIO & Pinctrl

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| TLMM Pinctrl | `qcom,pinctrl-sdm660` | Upstream | Qualcomm pinctrl driver | `ALREADY_SUPPORTED` | Pin multiplexing and config | NONE | P0 |
| GPIO (PMIC) | PM660/660L GPIO | Upstream | Qualcomm PMIC GPIO | `ALREADY_SUPPORTED` | Via PMIC GPIO controllers | NONE | P1 |
| GPIO Expander (PM660L) | PM660L GPIO | Upstream | Qualcomm PMIC GPIO | `ALREADY_SUPPORTED` | Additional GPIOs on PM660L | LOW | P2 |

**Whyred GPIO Assignments** (from DT):
- GPIO 66/67: Touch interrupt + reset
- GPIO 20: Fingerprint IRQ (disabled)
- GPIO 72: Fingerprint reset (disabled)
- GPIO 54: SD card detect
- GPIO 58: USB ID
- GPIO 75: Hall sensor

## 7. Serial (UART)

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| GENI Serial | `qcom,geni-uart` | Upstream | Qualcomm GENI UART | `ALREADY_SUPPORTED` | Console + BT UART | NONE | P0 |
| BLSP1 UART (BT) | GENI Serial | Upstream | Qualcomm GENI UART | `ALREADY_SUPPORTED` | Bluetooth UART on BLSP1 | NONE | P1 |

## 8. USB

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| DWC3 Controller | `qcom,sdm660-dwc3` | Upstream | Qualcomm DWC3 glue | `ALREADY_SUPPORTED` | USB 3.0 host/device | NONE | P0 |
| QUSB2 PHY | `qcom,sdm660-qusb2-phy` | Upstream | Qualcomm USB PHY | `ALREADY_SUPPORTED` | HS/FS PHY | NONE | P0 |
| HS PHY | `qcom,sdm660-hs-usb-phy` | Upstream | Qualcomm USB PHY | `ALREADY_SUPPORTED` | High-speed PHY | LOW | P0 |
| USB PHY Mux | `qcom,sdm660-usb-hs-mpm` | Upstream | Qualcomm MPM | `ALREADY_SUPPORTED` | MPM interrupt mux | LOW | P0 |
| UFS Host | `qcom,sdm660-ufs` | Upstream | Qualcomm UFS | `ALREADY_SUPPORTED` | Not used on whyred (eMMC only) | NONE | P3 |

## 9. Display

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| MDP/MDSS | `qcom,mdss` + `qcom,mdp5` | Upstream | Qualcomm MDSS driver | `ALREADY_SUPPORTED` | DRM MSM + MDP5 | LOW | P0 |
| DPU | `qcom,dpu` | Upstream (SDM660) | N/A (4.19 uses MDSS) | `ALREADY_SUPPORTED` | DPU works on SDM660; **broken on SDM630** | MEDIUM | P1 |
| DSI Controller | `qcom,mdss-dsi` | Upstream | Qualcomm DSI | `ALREADY_SUPPORTED` | DSI host controller upstream | LOW | P0 |
| Panel: TRULY NT36672C | **No upstream** | Needs panel driver | `panel-truly-nt36672c.c` | `DOWNSTREAM_REFERENCE_ONLY` | Custom MIPI-DSI panel; DT bindings not upstream; use downstream driver as reference | HIGH | P1 |
| Panel: BOE (nt36672c) | **No upstream** | Needs panel driver | `panel-boe-nt36672c.c` | `DOWNSTREAM_REFERENCE_ONLY` | Same IC, different panel manufacturer | HIGH | P1 |
| Panel: EBBG (nt36672c) | **No upstream** | Needs panel driver | `panel-ebbg-nt36672c.c` | `DOWNSTREAM_REFERENCE_ONLY` | Same IC, different panel manufacturer | HIGH | P1 |
| Panel IC: Novatek NT36672C | **No upstream** | Needs panel driver | Qualcomm panel driver | `DOWNSTREAM_REFERENCE_ONLY` | MIPI-DSI command mode panel; needs `drm_panel_bridge` integration | HIGH | P1 |
| Simple Framebuffer | `simple-framebuffer` | DT present | N/A | `ALREADY_SUPPORTED` | `qcom,mdss-dsi-simple-framebuffer` | NONE | P1 |

**Notes**: The NT36672C panel IC variants (TRULY/BOE/EBBG) all use the same NT36672C command-mode DSI protocol but with different init sequences and display timings. Panel auto-detection is planned but initially requires board-specific DT configuration.

## 10. GPU

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| Adreno A509 | `qcom,adreno-3xx-gpu` (freedreno) | DT present; `adreno@500000` with `qcom,gpu-pwrlevel-0` | Qualcomm `kgsl` (proprietary) | `DEVICE_TREE_ONLY` | Freedreno supports A3xx/A5xx/A6xx; whyred DT already has GPU node with freq levels | MEDIUM | P1 |
| GPU Clocks | GPUCC (`qcom,gpucc-sdm660`) | Upstream | Qualcomm GPUCC | `ALREADY_SUPPORTED` | Required for GPU clock gating | LOW | P1 |

**Notes**: A3xx/A4xx/A5xx are "simple" Adreno GPUs with reasonable mainline support. A509 on SDM636 is essentially an underclocked A512. Freedreno mesa supports these. Initial bringup targets OpenGL ES via llvmpipe; GPU acceleration is P2.

## 11. Touchscreen

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| Novatek NT36XXX (touch) | `qcom,touch-nt36xxx` | DT present; `stage-gate` compatible; IRQ GPIO 66 | `nt3xxx_ts` (Novatek proprietary) | `DEVICE_TREE_ONLY` | Mainline `nt36xxx` touchscreen driver exists; DT present; needs `i2c@ade0000` bus node + enable touchscreen in DTS | LOW | P1 |
| Touch I2C bus | I2C GENI | Upstream | Qualcomm GENI I2C | `ALREADY_SUPPORTED` | I2C GENI controller upstream | NONE | P1 |

**Notes**: The DT has the touch node with correct GPIO assignments (IRQ: gpio66, reset: gpio67) but is `stage-gate` compatible. The I2C bus node (`i2c@ade0000`) that the touch device is on is missing from the DTS and must be added. The mainline `qcom,touch-nt36xxx` driver (or generic `novatek,nt36xxx`) should work once the bus is present.

## 12. Battery & Charging

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| PM660 Charger | PM660 regulator + charger IC | DT present (placeholder) | `qcom,pm660-charger` | `ALREADY_SUPPORTED` | PM660 charger is upstream; DT node is placeholder only | LOW | P1 |
| Battery Monitoring (FG) | **No upstream FG driver** | Battery DT node is placeholder | Qualcomm FG (`qcom,pm660l-gauge`) | `UPSTREAM_PATCH_REQUIRED` | Fuel gauge not in mainline; battery monitoring requires FG or voltage-based estimation | HIGH | P2 |
| Battery DT | `battery` node present | Placeholder only | `qcom,battery-data` | `DOWNSTREAM_REFERENCE_ONLY` | Battery data (voltage/capacity mapping) is downstream-specific; needs real values from stock DT | MEDIUM | P2 |
| Battery Profile | `batt_id` / `batt_therm` resistors | Not mapped | Qualcomm battery profile | `DOWNSTREAM_REFERENCE_ONLY` | Battery identification via ADC; downstream has profile data | MEDIUM | P2 |

**Notes**: Basic charging may work with PM660 regulator alone. Accurate SoC% reporting requires fuel gauge driver or voltage-based estimation. Battery profile data (voltage→capacity mapping, thermistor calibration) must be extracted from downstream.

## 13. LEDs

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| Notification LED | `qcom,pm660l-led` | DT present | Qualcomm LED driver | `ALREADY_SUPPORTED` | PM660L LED controller upstream | NONE | P2 |

## 14. Wi-Fi

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| WCN3990 (Wi-Fi) | ath10k (partial) | Needs firmware patches | `qcacld-3.0` (CAF proprietary) | `MAINLINE_DRIVER_ADAPTATION` | `ath10k_pci` supports WCN3990 but needs: (1) `firmware-5.bin` with 4 board data files (mht40/mht20 DB/AB), (2) board-specific data, (3) WiFi firmware quirks (`ENABLE_BATTERY_LEVEL`, `WOW_ENABLE`) | MEDIUM | P2 |
| Wi-Fi Power | `wlan-en-gpio` | DT missing; needs PMIC regulator or GPIO | Qualcomm WLAN power driver | `UPSTREAM_PATCH_REQUIRED` | Power sequencing via PMIC regulator or GPIO; DT node missing from current DTS | MEDIUM | P2 |
| Wi-Fi firmware | ath10k firmware | Needs extraction from stock/CAF | `WCN3990/hw1.0/` firmware package | `DOWNSTREAM_REFERENCE_ONLY` | Firmware must be extracted from stock ROM or CAF; not redistributable | LOW | P2 |

**Notes**: ath10k support for WCN3990 is partially upstream. The sdm660-mainline project has working WiFi using ath10k with specific firmware configurations. Main firmware is `firmware-5.bin` (not `firmware-6.bin` used on newer Qualcomm WiFi). Board-specific data files are required.

## 15. Bluetooth

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| WCN3990 (BT) | ath3k + ath10k BT | Partial | `qca_cld3` + BT firmware | `MAINLINE_DRIVER_ADAPTATION` | BT on WCN3990 uses HCI over UART; partially upstream but needs firmware | MEDIUM | P2 |
| Bluetooth UART | GENI UART | Upstream | Qualcomm GENI UART | `ALREADY_SUPPORTED` | UART transport layer | NONE | P1 |
| BT Firmware | `rome-3` / `cherokee` firmware | Needs extraction | CAF BT firmware package | `DOWNSTREAM_REFERENCE_ONLY` | Must be extracted from stock; not redistributable | LOW | P2 |

## 16. Audio

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| ASoC Platform (Q6DSP) | `qcom,q6afedai` + `q6afe` + `q6asm` | Skeleton exists | Qualcomm audio drivers | `MAINLINE_DRIVER_ADAPTATION` | Skeleton framework exists but not fully functional; needs significant work | HIGH | P3 |
| Sound Card (SDM660) | `asoc-sdm660-intern` | No DTS node | `sdm660-internal` machine driver | `UPSTREAM_PATCH_REQUIRED` | Machine driver exists in `sound/soc/qcom/` but SDM660 DTS node is **missing** from whyred DTS | HIGH | P3 |
| WCD9340 (Speaker) | `qcom,wcd934x-codec` | Upstream | Qualcomm WCD934x | `ALREADY_SUPPORTED` | Codec driver upstream | LOW | P3 |
| Speaker Amplifier | `qcom,bolero-codec` + `wcd938x` | No DT bindings | `speaker-pa` driver | `DOWNSTREAM_REFERENCE_ONLY` | PA driver exists but lacks proper DT bindings upstream | HIGH | P3 |
| Soundwire | `qcom,soundwire` | No DT bindings | Qualcomm soundwire | `UNKNOWN` | Soundwire bus controller needs proper bindings for SDM660 | HIGH | P3 |
| DMIC / AMIC | Qualcomm voice/w | Upstream | Qualcomm voice driver | `MAINLINE_DRIVER_ADAPTATION` | DMIC/AMIC routing needs configuration | MEDIUM | P3 |
| Headphone jack | ASoC jack framework | Upstream | Qualcomm audio jack | `ALREADY_SUPPORTED` | Standard ALSA jack detection | LOW | P3 |

**Notes**: Audio is the most complex subsystem gap. The upstream `sdm660-intern` machine driver exists but requires: (1) a proper DTS node with sound card properties, (2) DAI link configuration matching whyred hardware, (3) codec routing, (4) clock configuration. The q6dsp framework provides the DSP communication layer. Audio is **P3** as it's not required for basic bringup.

## 17. Camera

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| CAMSS (ISP) | `qcom,camss` | Partial (basic support) | Qualcomm Spectra ISP | `MAINLINE_DRIVER_ADAPTATION` | CAMSS has basic support for some Qualcomm ISPs but SDM660/636 Spectra ISP is not fully upstream | HIGH | P3 |
| Camera Sensors (IMX486) | **No upstream** | No DTS node | `imx486` sensor driver | `DOWNSTREAM_REFERENCE_ONLY` | Sony IMX486 sensor has no upstream driver; downstream has full register init | HIGH | P3 |
| Camera Sensors (OV13855) | **No upstream** | No DTS node | `ov13855` sensor driver | `DOWNSTREAM_REFERENCE_ONLY` | OmniVision OV13855 has no upstream driver | HIGH | P3 |
| Camera Sensors (S5K5E8) | **No upstream** | No DTS node | `s5k5e8` sensor driver | `DOWNSTREAM_REFERENCE_ONLY` | Samsung S5K5E8 has no upstream driver | HIGH | P3 |
| Camera Flash (LC898212X) | **No upstream** | No DTS node | `lc898212xc` OIS driver | `DOWNSTREAM_REFERENCE_ONLY` | OIS controller; no mainline support | HIGH | P3 |

**Notes**: Camera requires: (1) working CAMSS/ISP pipeline, (2) sensor drivers with I2C register init sequences, (3) CSI-2 configuration, (4) clock/power management. None of the whyred camera sensors are upstream. Camera is **P3** for basic bringup.

## 18. Sensors & Motion

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| LSM6DS3 (Gyro/Accel) | `st_lsm6dsx` (mainline) | No DTS node | `stm_lsm6ds3` sensor driver | `DEVICE_TREE_ONLY` | Mainline `st_lsm6dsx` IIO driver exists in `drivers/iio/imu/st_lsm6dsx/`; needs DTS I2C node only | LOW | P3 |
| BME680 (Env) | BME680 IIO driver | No DTS node | Bosch BME680 driver | `DEVICE_TREE_ONLY` | Mainline BME680 IIO driver exists; needs DTS I2C node | LOW | P3 |
| TMD2772 (Proximity/Light) | Avago/TMD2772 driver | No DTS node | `tmd2772` driver | `DEVICE_TREE_ONLY` | Mainline `tmd2772` IIO driver exists; needs DTS I2C node | LOW | P3 |
| BMI160 (Gyro/Accel) | BMI160 IIO driver | No DTS node | Bosch BMI160 driver | `DEVICE_TREE_ONLY` | Mainline `bmi160` IIO driver exists; needs DTS I2C/SPI node | LOW | P3 |
| MPU6050 (Gyro/Accel) | MPU6050 IIO driver | No DTS node | InvenSense MPU6050 driver | `DEVICE_TREE_ONLY` | Mainline `mpu6050` IIO driver exists; needs DTS I2C node | LOW | P3 |
| Magnetometer (AK09911/09918) | AK09911 IIO driver | No DTS node | AKM magnetometer driver | `DEVICE_TREE_ONLY` | Mainline `ak09911` IIO driver exists; needs DTS I2C node | LOW | P3 |
| IR Blaster | `gpio-ir-tx` | No DTS node | `gpio-ir-tx` driver | `DEVICE_TREE_ONLY` | Mainline GPIO IR TX driver; needs DTS GPIO node | LOW | P3 |
| SLPI (Sensor Hub) | `qcom,slpi-imem` | No DTS node | Qualcomm SLPI remoteproc | `DOWNSTREAM_REFERENCE_ONLY` | Sensor hub co-processor; no mainline remoteproc for SLPI | HIGH | P3 |

**Notes**: Most sensors are on I2C buses and need DTS nodes. The mainline IIO subsystem has drivers for most of these sensors. SLPI is a separate co-processor that handles sensor fusion; without it, individual sensors can still be accessed directly via I2C but lack low-power always-on sensing.

## 19. Fingerprint

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| Fingerprint sensor | **No driver** | DT present (disabled) | `goodix_fp` / `fpc1020` | `DOWNSTREAM_REFERENCE_ONLY` | No mainline FP driver exists; downstream has Goodix GF3208 + FPC1020 support; requires TZ applet | CRITICAL | P3 |

**Notes**: Fingerprint requires: (1) TEE/TZ communication channel (QSEECOM/TrustZone), (2) sensor-specific driver, (3) HAL integration. None of this exists in mainline Linux. This is a **Android TEE** dependency that cannot be solved in-kernel alone.

## 20. NFC

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| NFC controller | **No driver** | No DTS node | `nfc-nci` (NXP) | `DOWNSTREAM_REFERENCE_ONLY` | Mainline has NXP PN5xx support; NQ2xx used in whyred may need NCI protocol adaptation. Requires I2C/SPI binding + NCI stack | HIGH | P3 |

**Notes**: NFC requires: (1) I2C/SPI driver for NFC controller, (2) NCI protocol stack, (3) HAL integration. Mainline Linux has no Qualcomm/NXP NFC support for this platform.

## 21. Vibration Motor

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| Haptic driver | `qcom,qpnp-haptic` | No DTS node | `qpnp-haptic` driver | `DOWNSTREAM_REFERENCE_ONLY` | No mainline haptic driver for PM660L haptic motor | MEDIUM | P3 |

## 22. Hall Sensor

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| Hall effect sensor | `gpio-keys` or IIO | No DTS node | `gpio-hall` driver | `DEVICE_TREE_ONLY` | Simple GPIO-based hall sensor (GPIO 75); can use `gpio-keys` node | LOW | P3 |

## 23. Modem (Telephony)

| Subsystem | Mainline 6.18 | Whyred Status | 4.19 Downstream | Action | Reason | Risk | Priority |
|---|---|---|---|---|---|---|---|
| Q6 Modem (MSS) | `qcom,q6v5-mss` | Upstream | Qualcomm remoteproc MSS | `ALREADY_SUPPORTED` | Modem remoteproc is upstream; requires MPSS firmware from stock | LOW | P1 |
| Q6 Communication | `qcom,q6v5-mailbox` | Upstream | Qualcomm mailbox | `ALREADY_SUPPORTED` | IPC between ARM and Q6 DSP | NONE | P1 |
| MPSS Firmware | Blob required | Needs extraction | Stock MPSS firmware | `DOWNSTREAM_REFERENCE_ONLY` | Modem firmware is a proprietary blob; must be extracted from stock ROM | LOW | P1 |
| Netdev/QRTR | `qcom,qrtr` + QRTR NS | Upstream | Qualcomm QRTR | `ALREADY_SUPPORTED` | QMI/QRTR communication over IPC | LOW | P1 |

**Notes**: The Modem remoteproc (`qcom,q6v5-mss`) loads MPSS firmware via `/lib/firmware`. The firmware must be extracted from stock ROM and placed in the initramfs. Without MPSS firmware, the modem subsystem will fail to boot but the rest of the system continues to work.

## Summary Statistics

| Action | Count | Examples |
|---|---|---|
| `ALREADY_SUPPORTED` | **27** | CPU, GCC, PMIC, DDR, UART, USB, UFS, charger, UART, GENI, eMMC |
| `DEVICE_TREE_ONLY` | **11** | LSM6DS3, BME680, TMD2772, BMI160, MPU6050, AK09911, IR, Hall, WLED, touch, Avago |
| `MAINLINE_DRIVER_ADAPTATION` | **7** | CPUFreq (panic fix), GPU (A509), Wi-Fi (ath10k WCN3990), BT, Audio (Q6DSP), CAMSS |
| `UPSTREAM_PATCH_REQUIRED` | **4** | Battery FG, Wi-Fi power, Sound card, SDM660 battery data |
| `DOWNSTREAM_REFERENCE_ONLY` | **10** | Panel (TRULY/BOE/EBBG), FP, NFC, Vibration, SLPI, Wi-Fi/BT FW, Camera sensors, Battery profile |
| `NEW_DRIVER_REQUIRED` | **0** | — |
| `UNKNOWN` | **1** | Soundwire bindings |

### By Priority

| Priority | Count | Subsystems |
|---|---|---|
| **P0 (Boot)** | 15 | CPU, DDR, eMMC, GCC, PMICs, Regulators, PON, RTC, USB, UFS, UART |
| **P1 (Daily Driver)** | 13 | Display (MDP/DSI), Panel, Touch, GPU, SD card, Wi-Fi power, BT UART, Modem, MPSS, GPUCC, VIDEOCC, DISPCC, Interconnect |
| **P2 (Important)** | 6 | Wi-Fi (ath10k), BT, Battery FG, Battery data, LEDs, USB |
| **P3 (Nice-to-have)** | 12 | Audio, Camera (all sensors + ISP), Sensors (all), FP, NFC, Vibration, Hall, Speaker Amp, Soundwire, IR |

---

## Implementation Roadmap

### Phase 1: Boot & Basic Display (Week 1-2)
- [ ] Fix CPUFreq SCMI panic (UPSTREAM_PATCH)
- [ ] Enable WLED backlight (DT)
- [ ] Enable panel driver (TRULY NT36672C) (DOWNSTREAM_REFERENCE)
- [ ] Verify MDSS/MDP5 display pipeline

### Phase 2: Input & Connectivity (Week 3-4)
- [ ] Enable touch I2C bus + NT36XXX driver (DT)
- [ ] Enable GPU via freedreno A509 (DT)
- [ ] Enable modem remoteproc + MPSS firmware
- [ ] Enable Wi-Fi (ath10k WCN3990 firmware + DT)

### Phase 3: Power & Sensors (Week 5-6)
- [ ] Enable battery monitoring (UPSTREAM_PATCH or voltage estimation)
- [ ] Enable sensors via I2C DTS nodes
- [ ] Enable hall sensor (DT)
- [ ] Enable BT (ath10k BT + firmware)

### Phase 4: Advanced Features (Week 7+)
- [ ] Audio (Q6DSP + SDM660 sound card)
- [ ] Camera (CAMSS + sensor drivers)
- [ ] Fingerprint (requires TEE)
- [ ] NFC (requires new driver)
- [ ] Vibration motor
