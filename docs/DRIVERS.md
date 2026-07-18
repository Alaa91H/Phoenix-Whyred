# Whyred Drivers — Phoenix-Whyred 6.18 LTS

## In-tree drivers (`drivers/whyred/`)

| Module | Kconfig | Purpose |
|--------|---------|---------|
| `whyred_board` | `WHYRED_BOARD` | Board identity + panel geometry (platform + sysfs) |

**Note:** All other whyred drivers have been removed — they were stubs/placeholders that conflicted with upstream drivers.

## Upstream drivers (via DT)

| Function | Driver | Status |
|----------|--------|--------|
| Touch | `CONFIG_TOUCHSCREEN_NT36XXX` / novatek nvt-ts | ✅ Upstream |
| Display | `CONFIG_DRM_MSM` + simple-framebuffer | ✅ Upstream |
| WiFi | `CONFIG_ATH10K_SNOC` | ✅ Upstream |
| Charger | `CONFIG_CHARGER_QCOM_SMB2` / FG | ✅ Upstream |
| Audio | `CONFIG_SND_SOC_WCD9335` + QCOM machine | ✅ Upstream |
| USB | DWC3 + QUSB2 PHY | ✅ Upstream |
| Storage | `CONFIG_MMC_SDHCI_MSM` | ✅ Upstream |
| Modem | `CONFIG_QCOM_Q6V5_MSS` + remoteproc | ✅ Upstream |
| PMIC | `CONFIG_MFD_SPMI_PMIC` (PM660/PM660L) | ✅ Upstream |
| Clocks | `CONFIG_SDM_GCC_660` / GPUCC / VIDEOCC / DISPCC | ✅ Upstream |
| Pinctrl | `CONFIG_PINCTRL_SDM660` | ✅ Upstream |
| Interconnect | `CONFIG_INTERCONNECT_QCOM_SDM660` | ✅ Upstream |

Enable via `configs/fragments/whyred.config`.

## Bring-up sequence

See detailed guide: **[BRINGUP.md](BRINGUP.md)** · DT audit: **[STOCK_DTB.md](STOCK_DTB.md)**

1. UART + earlycon (`BRINGUP_STAGE=1`)
2. eMMC rootfs (`=2`)
3. USB gadget / adb (`=3`)
4. simple-fb or DRM (`=4`)
5. touch (`=5`)
6. WiFi firmware
7. audio / camera

```bash
make bringup1   # … through bringup5
```

## Building as modules

After `build.sh`:

```
out/modules/lib/modules/*/kernel/drivers/whyred/
  whyred_board.ko
```

```bash
insmod whyred_board.ko
# or
modprobe whyred_board
```
