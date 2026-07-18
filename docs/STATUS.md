# Phoenix-Whyred Status

Last updated: 2026-07-18

## Major Transition: Linux Mainline 6.18 LTS

**Key discovery:** Linux Mainline 6.18 LTS already has extensive SDM636/SDM660 support — including `sdm636-xiaomi-whyred.dtb` — via the sdm660-mainline project merged upstream.

**Architecture:** Linux Mainline 6.18 LTS as primary kernel source; downstream 4.19 as reference only.

See: [MAINLINE_MIGRATION_AUDIT.md](MAINLINE_MIGRATION_AUDIT.md)

---

## 6.18 LTS Mainline Track (Default)

| Component | Status | Notes |
|-----------|--------|-------|
| Scripts + CI | ✅ | KERNEL_TRACK=6.18, mainline clone, validation |
| Linux Mainline 6.18 LTS base | ✅ | setup clones kernel.org v6.18 tag |
| Build provenance (build-info) | ✅ | build-info.txt + SHA256SUMS + toolchain versions |
| Patch safety | ✅ | APPLIED/FAILED tracking, exit on failure |
| Config validation | ✅ | validate-config.sh checks 30+ critical CONFIGs |
| Device Tree (board/PMIC/pinctrl) | 🟡 | Updated from LineageOS ref — needs device dump |
| Stock alignment (vendor ref) | ✅ | msm-id/board-id, touch `blsp_i2c1`, splash/ramoops |
| Stock DTB matching tools | ✅ | extract + compare + `fetch-stock-ref` |
| Gradual bring-up (UART→…→touch) | 🟡 | `BRINGUP_STAGE` + earlycon `0x0c170000` |
| whyred_board (sysfs identity) | 🟡 | Optional board glue module |
| Touch Novatek via DT | 🟡 | node + in-tree nvt (stage 5) |
| Fingerprint | 🔴 | node disabled |
| Full DRM panel | 🔴 | simple-fb first (stage 4) |
| Audio / Camera | 🔴 | upstream drivers need DT wiring |
| Full ROM boot | 🔴 | after bring-up stages |
| BTF (BPF Type Format) | 🟡 | disabled temporarily — pahole >= 1.25 required |

See: [DEVICE_TREE.md](DEVICE_TREE.md) · [STOCK_DTB.md](STOCK_DTB.md) · [BRINGUP.md](BRINGUP.md) · [DRIVERS.md](DRIVERS.md)

## 4.19 Track (ROM fallback)

| Component | Status | Notes |
|-----------|--------|-------|
| San-Kernel 4.19 | ✅ | KERNEL_TRACK=4.19 |
| whyred-perf_defconfig | ✅ | |
| ROM 4.19 boot | 🟡 | after successful build |

## Legend

- ✅ Ready for use
- 🟡 In progress / partial
- 🔴 Not yet implemented

## Current Work Priorities

1. ~~Build Image from ACK 6.18~~ (path ready)
2. ~~Stock matching from vendor ref~~ — [STOCK_AUDIT.md](STOCK_AUDIT.md) ✅
3. **Switch to Linux Mainline 6.18 LTS** — [MAINLINE_MIGRATION_AUDIT.md](MAINLINE_MIGRATION_AUDIT.md)
4. **Remove redundant whyred drivers** (6 of 7)
5. **Clean up Device Tree** — remove dangerous `whyred_power` node
6. **Device dump verification** (optional but important): `extract-stock-dtb` + `compare-stock-dt`
7. **Device bring-up:** `make bringup1` → … → `bringup5`

Details: [BRINGUP.md](BRINGUP.md) · [STOCK_AUDIT.md](STOCK_AUDIT.md) · [MAINLINE_MIGRATION_AUDIT.md](MAINLINE_MIGRATION_AUDIT.md)
