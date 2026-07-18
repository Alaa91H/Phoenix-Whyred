# SDM660-Mainline Base Selection Analysis

## Executive Summary

The sdm660-mainline organization maintains a Linux kernel fork specifically for Qualcomm SDM630/SDM636/SDM660 devices. The default branch is `qcom-sdm660-7.0.y` running **Linux 7.0.9**. This is the proven base for whyred (Xiaomi Redmi Note 5 Pro) booting.

## Repository Overview

| Property | Value |
|----------|-------|
| Repository | `github.com/sdm660-mainline/linux` |
| Default branch | `qcom-sdm660-7.0.y` |
| Kernel version | **7.0.9** ("Baby Opossum Posse") |
| Forked from | `torvalds/linux` |
| Stars | 48 |
| Forks | 36 |
| Last push | 2026-07-18 (today) |
| License | GPL-2.0 |

## Branch History (20 release branches)

| Branch | Kernel | Status | Last Commit |
|--------|--------|--------|-------------|
| `qcom-sdm660-5.10.y` | 5.10 | EOL | Archived |
| `qcom-sdm660-5.19.y` | 5.19 | EOL | Archived |
| `qcom-sdm660-6.0.y` | 6.0 | EOL | Archived |
| `qcom-sdm660-6.1.y` | 6.1 | EOL | Archived |
| `qcom-sdm660-6.3.y` | 6.3 | EOL | Archived |
| `qcom-sdm660-6.6.y` | 6.6 | EOL | Archived |
| `qcom-sdm660-6.7.y` | 6.7 | EOL | Archived |
| `qcom-sdm660-6.8.y` | 6.8 | EOL | Archived |
| `qcom-sdm660-6.9.y` | 6.9 | EOL | Archived |
| `qcom-sdm660-6.10.y` | 6.10 | EOL | Archived |
| `qcom-sdm660-6.11.y` | 6.11 | EOL | Archived |
| `qcom-sdm660-6.12.y` | 6.12 | EOL | Archived |
| `qcom-sdm660-6.13.y` | 6.13 | EOL | Archived |
| `qcom-sdm660-6.14.y` | 6.14 | EOL | Archived |
| `qcom-sdm660-6.15.y` | 6.15 | EOL | Archived |
| `qcom-sdm660-6.16.y` | 6.16 | Dormant | 2026-03-17 |
| `qcom-sdm660-6.17.y` | 6.17 | Dormant | 2026-03-29 |
| `qcom-sdm660-6.18.y` | 6.18 | Dormant | 2026-03-17 |
| `qcom-sdm660-6.19.y` | 6.19 | Dormant | 2026-03-29 |
| `qcom-sdm660-7.0.y` | **7.0** | **Active** | **2026-07-18** |

## Activity Analysis

- **6 commits in last 8 days** (Jul 11-18, 2026)
- Active contributors: M0Rf30 (Gianluca Boiano), minlexx (Alexey Minnekhanov), setotau (Nickolay Goppen)
- 6.18.y and 6.19.y branches dormant since March 2026
- 7.0.y is the only actively maintained branch

## Key Contributors

| Contributor | Role | Focus Areas |
|-------------|------|-------------|
| **M0Rf30** (Gianluca Boiano) | Maintainer | Touch drivers, CI, overall project |
| **minlexx** (Alexey Minnekhanov) | Core contributor | DRM/MSM, device trees, sensors |
| **setotau** (Nickolay Goppen) | Contributor | FastRPC, crypto, modem |

## Decision

**Base selection: `qcom-sdm660-7.0.y` (Linux 7.0.9)**

Rationale:
1. Only actively maintained branch
2. Proven whyred DTS already exists
3. Whyred touchscreen (Synaptics RMI4 E753) support confirmed
4. Full peripheral support (WiFi, Bluetooth, USB, display)
5. Active community with 48 stars and 36 forks
6. Regular upstream merges from torvalds/linux
