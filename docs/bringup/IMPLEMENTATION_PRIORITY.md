# Implementation Priority Plan

> **Device**: Xiaomi Redmi Note 5 Pro (`whyred`) | **SoC**: SDM636
> **Target**: Linux Mainline 6.18 LTS — first physical boot
> **Created**: 2026-07-18

## Priority Scale

| Level | Meaning |
|---|---|
| **P0** | Required for kernel build or first boot |
| **P1** | Required for basic hardware functionality |
| **P2** | Required for usable Linux system |
| **P3** | Android integration |
| **P4** | Optional enhancements |

---

## P0 — Required for Kernel Build or First Boot

These must work before anything else. Failure in any P0 item blocks first boot.

### Boot Architecture
1. ARM64 architecture support
2. Qualcomm SDM660/636 platform (GCC, SoC info)
3. Device Tree compilation (sdm636-xiaomi-whyred.dtb)
4. `qcom,msm-id` / `qcom,board-id` — bootloader matching
5. `qcom,pmic-id` — PMIC identification

### CPU & Interrupts
6. ARM Generic Timer
7. GICv3 interrupt controller
8. 8-core Kryo 260 CPU

### Memory
9. DDR memory controller (U-Boot BL2 handles init)
10. CMA/DMA memory allocation

### PMIC & Power
11. PM660 PMIC (SPMI communication)
12. PM660L PMIC (SPMI communication)
13. Regulator tree (rpm_requests)
14. PON (power-on/reset key handling)
15. SPMI PMIC arbiter

### Clocks
16. GCC clock controller (`qcom,gcc-sdm660`)
17. Common clock framework

### Pinctrl
18. TLMM pinctrl (`qcom,pinctrl-sdm660`)

### Serial / Early Console
19. GENI serial (`blsp1_uart2`) — console output
20. earlycon support

### Storage
21. eMMC/SDHCI (`sdhc_1`) — rootfs access
22. MMC block device + filesystem

### USB (Debugging)
23. DWC3 USB controller
24. QUSB2 PHY
25. USB gadget (adb access)

---

## P1 — Required for Basic Hardware Functionality

Needed for the device to be minimally usable beyond serial console.

26. GPU clock controller (`GPUCC`)
27. Display clock controller (`DISPCC`)
28. Video clock controller (`VIDEOCC`)
29. Interconnect framework (`ICC RPMh`)
30. Simple framebuffer (splash from bootloader)
31. WLED backlight
32. Panel driver (TRULY NT36672C)
33. Touchscreen (Novatek NT36XXX)
34. GPU via freedreno (Adreno 509)
35. SD card reader
36. Modem remoteproc (Q6V5-MSS)
37. QRTR (modem IPC)

---

## P2 — Required for Usable Linux System

38. Wi-Fi (ath10k WCN3990)
39. Bluetooth
40. Battery monitoring (fuel gauge or voltage estimation)
41. Battery charging
42. Notification LED
43. RTC (real-time clock)
44. GPIO expander (PM660L)

---

## P3 — Android Integration

45. Audio (Q6DSP + SDM660 sound card)
46. Camera (CAMSS + sensor drivers)
47. Fingerprint (requires TEE)
48. NFC
49. Vibration motor
50. Hall sensor
51. Sensors (IMU, environment, proximity)
52. IR blaster
53. SLPI (sensor hub)

---

## P4 — Optional Enhancements

54. Vulkan (Mesa Turnip — userspace, not kernel)
55. Energy-aware scheduling tuning
56. DDR frequency scaling
57. LLCC (last-level cache)
58. UFS (not used on whyred — eMMC only)

---

## First Boot Path (P0 only)

The minimum viable path to first physical boot:

```
Kernel image (Image.gz)
    → DTB (sdm636-xiaomi-whyred.dtb)
        → Bootloader loads both
            → Kernel starts
                → ARM64 arch init
                    → GICv3 interrupts
                        → Timer
                            → GCC clocks
                                → SPMI → PMIC → Regulators
                                    → TLMM pinctrl
                                        → UART console (earlycon)
                                            → eMMC (rootfs)
                                                → USB (adb)
```

Each layer depends on the previous. If any layer fails, boot stops there.
