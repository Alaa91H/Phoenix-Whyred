# Roadmap

## Phase 0 — Audit ✅

- [x] Full repository audit (mainline-first architecture)
- [x] Research mainline 6.18 SDM660/636 support
- [x] Write MAINLINE_MIGRATION_AUDIT.md

## Phase 1 — Linux Mainline 6.18 LTS ✅

- [x] Switch from ACK android17-6.18 to Linux Mainline v6.18
- [x] Update PROJECT.conf, setup.sh, build.sh
- [x] Update CI workflow for mainline
- [x] Update documentation

## Phase 2 — Remove Redundant Drivers ✅

- [x] Remove whyred_power.c (dangerous fake battery)
- [x] Remove whyred_touch.c (redundant with upstream NT36XXX)
- [x] Remove whyred_wlan.c (redundant with upstream ATH10K)
- [x] Remove whyred_panel.c (redundant with upstream DRM MSM)
- [x] Remove whyred_audio.c (stub)
- [x] Remove whyred_camera.c (stub)
- [x] Keep whyred_board.c (sysfs identity)

## Phase 3 — Clean Up Device Tree ✅

- [x] Remove redundant board glue nodes (power, wlan, audio, camera)
- [x] Keep whyred_board node (sysfs identity)

## Phase 4 — Clean Up Config ✅

- [x] Remove WHYRED_DISPLAY, WHYRED_TOUCH, WHYRED_POWER, WHYRED_WLAN, WHYRED_AUDIO, WHYRED_CAMERA from whyred.config
- [x] Keep WHYRED_BOARD (optional)
- [x] Remove Android binder/cgroups from hybrid.config (now optional)

## Phase 5 — Hardware Bring-up (after first boot)

- [ ] Stage 1: UART + earlycon on device
- [ ] Stage 2: MMC / rootfs
- [ ] Stage 3: USB gadget / adb
- [ ] Stage 4: simple-fb + WLED
- [ ] Stage 5: touch Novatek
- [ ] DRM panel / WLAN / audio after stabilization

## Phase 6 — Production ROM (4.19 fallback)

- [ ] 4.19 builds for ROM compatibility
- [ ] KernelSU (optional)
- [ ] Performance / battery tuning
