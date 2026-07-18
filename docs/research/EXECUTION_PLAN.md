# Execution Plan: Phoenix-Whyred onto sdm660-mainline

## Overview

**Objective**: Rebase Phoenix-Whyred onto sdm660-mainline 7.0.9 (Linux 7.0.9)
**Strategy**: Fork sdm660-mainline, add Phoenix customizations on top
**Timeline**: 8 days
**Status**: Ready to execute

## Phase 1: Fork sdm660-mainline (Day 1)

### Actions
1. Fork `github.com/sdm660-mainline/linux` branch `qcom-sdm660-7.0.y`
2. Add Phoenix-Whyred as remote
3. Create `phoenix-whyred` branch from sdm660-mainline default
4. Verify DTS exists: `sdm636-xiaomi-whyred.dts`
5. Verify defconfig exists: `sdm660_defconfig`

### Validation
- [ ] Fork created successfully
- [ ] Branch `phoenix-whyred` exists
- [ ] DTS file present in `arch/arm64/boot/dts/qcom/`
- [ ] Defconfig present in `arch/arm64/configs/`

### Commands
```bash
# Fork via GitHub API or web interface
# Clone fork
git clone https://github.com/Alaa91H/sdm660-mainline.git
cd sdm660-mainline
git checkout -b phoenix-whyred qcom-sdm660-7.0.y

# Verify files
ls arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts
ls arch/arm64/configs/sdm660_defconfig
```

## Phase 2: Port Phoenix Configs (Days 2-3)

### Current State
- **sdm660-mainline defconfig**: `sdm660_defconfig` (23,870 bytes)
- **Phoenix configs**: `sdm660.config` + `whyred.config` + `hybrid.config` + bringup stages

### Actions
1. Compare sdm660_defconfig with Phoenix config fragments
2. Merge Phoenix customizations into sdm660_defconfig
3. Remove duplicate symbols (~80% overlap)
4. Add missing symbols from Phoenix
5. Keep sdm660-mainline's proven symbols

### Key Differences to Resolve

| Symbol | sdm660-mainline | Phoenix | Action |
|--------|-----------------|---------|--------|
| `LOCALVERSION` | `-sdm660` | `-phoenix-whyred-7.0` | Update |
| `SERIAL_QCOM_GENI` | ✅ | ✅ | Keep |
| `DRM_MSM` | ✅ | ✅ | Keep |
| `USB_DWC3` | ✅ | ✅ | Keep |
| `WCN3990` | ✅ | ❌ | Keep (sdm660-mainline) |
| `TOUCHSCREEN_SYNAPTICS_DSX` | ✅ | ❌ | Keep (sdm660-mainline) |
| `WHYRED_DRIVERS` | ❌ | ✅ | Add (custom) |
| `WHYRED_BOARD` | ❌ | ✅ | Add (custom) |

### Validation
- [ ] Config builds successfully
- [ ] All Phoenix customizations preserved
- [ ] All sdm660-mainline proven options kept
- [ ] No duplicate symbols

## Phase 3: Port Phoenix CI Pipeline (Day 4)

### Current State
- **Phoenix CI**: `.github/workflows/build-kernel.yml`
- **sdm660-mainline CI**: `infra/` repository (Dockerfiles, scripts)

### Actions
1. Copy Phoenix CI workflow to sdm660-mainline fork
2. Update source URL to sdm660-mainline
3. Update build scripts to use sdm660-mainline defconfig
4. Update artifact naming
5. Keep AnyKernel3 flash scripts

### Key Changes
```yaml
# .github/workflows/build-kernel.yml
- name: Clone kernel
  run: |
    git clone --depth=1 https://github.com/sdm660-mainline/linux.git
    cd linux
    git checkout qcom-sdm660-7.0.y

- name: Build
  run: |
    make ARCH=arm64 sdm660_defconfig
    make ARCH=arm64 -j$(nproc) Image.gz dtbs
```

### Validation
- [ ] CI workflow runs successfully
- [ ] Build produces Image.gz and DTBs
- [ ] Artifacts uploaded correctly
- [ ] AnyKernel3 zip created

## Phase 4: Port Phoenix Flash Scripts (Day 5)

### Current State
- **Phoenix**: `pack/AnyKernel3/anykernel.sh`
- **sdm660-mainline**: No flash scripts

### Actions
1. Copy `pack/AnyKernel3/` to sdm660-mainline fork
2. Update device names (whyred → whyred)
3. Verify block device path
4. Verify slot configuration (non-A/B)

### Key Changes
```bash
# anykernel.sh
device.name1=whyred
device.name2=Whyred
device.name3=Redmi Note 5
device.name4=redmi note 5 pro
device.name5=Redmi Note 5 Pro
block=/dev/block/bootdevice/by-name/boot
is_slot_device=0
```

### Validation
- [ ] Flash script runs on device
- [ ] Image flashed correctly
- [ ] Device boots

## Phase 5: Update PROJECT.conf (Day 5)

### Current State
- **Phoenix**: `PROJECT.conf` with dual-track (6.18 + 4.19)
- **sdm660-mainline**: Single track (7.0.y)

### Actions
1. Simplify PROJECT.conf to single track
2. Update source URL to sdm660-mainline
3. Update version to 7.0.9
4. Update fragment paths
5. Remove 4.19 track references

### Key Changes
```bash
# PROJECT.conf
PROJECT_NAME="phoenix-whyred"
DEVICE_CODENAME="whyred"
SOC="sdm636"
SOC_FAMILY="sdm660"
KERNEL_TRACK="7.0"
GKI_REMOTE="https://github.com/sdm660-mainline/linux.git"
GKI_BRANCH_REF="qcom-sdm660-7.0.y"
LOCALVERSION="-phoenix-whyred-7.0"
ZIP_PREFIX="Phoenix-Whyred-7.0"
```

### Validation
- [ ] All scripts source PROJECT.conf correctly
- [ ] No broken path references
- [ ] Version numbers consistent

## Phase 6: Build and Validate (Days 6-7)

### Actions
1. Trigger CI build
2. Monitor build progress
3. Validate build artifacts
4. Download and verify zip
5. Compare with sdm660-mainline reference build

### Validation Checklist
- [ ] Build completes successfully
- [ ] Image.gz present and valid
- [ ] DTBs present (sdm636-xiaomi-whyred.dtb)
- [ ] Config validation passes
- [ ] SHA256SUMS generated
- [ ] Build-info.txt present

### Commands
```bash
# Trigger CI build
gh workflow run build-kernel.yml

# Download artifacts
gh run download <run-id>

# Verify
unzip -l Phoenix-Whyred-7.0-*.zip
```

## Phase 7: Test on Hardware (Day 8)

### Actions
1. Flash to device via TWRP
2. Boot and capture UART logs
3. Verify display output
4. Test touchscreen
5. Test WiFi and Bluetooth
6. Test USB connectivity

### Boot Test Matrix
| Test | Expected Result | Status |
|------|-----------------|--------|
| Boot | Kernel loads, init starts | Pending |
| Display | Framebuffer output | Pending |
| Touch | Input events registered | Pending |
| WiFi | WCN3990 connects | Pending |
| Bluetooth | WCN3990 pairs | Pending |
| USB | DWC3 enumerates | Pending |
| Modem | MSS loads | Pending |

### Validation
- [ ] Device boots to shell
- [ ] All peripherals functional
- [ ] No kernel panics
- [ ] No hardware errors

## Phase 8: Documentation Update (Day 8)

### Actions
1. Update README.md
2. Update PROJECT.conf
3. Create migration guide
4. Archive old Phoenix-Whyred main branch
5. Update status documents

### Documents to Update
- `README.md` - Project description
- `PROJECT.conf` - Version and source info
- `docs/bringup/STEP9_FINAL_REPORT.md` - Final report
- `docs/research/` - Analysis documents (keep as reference)

### Validation
- [ ] README.md reflects new base
- [ ] All links work
- [ ] No broken references

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Touch mismatch | High | Low | sdm660-mainline DTS uses Synaptics, verified working |
| Display mismatch | High | Low | sdm660-mainline DTS uses Tianma TD4310, verified working |
| Config drift | Medium | Medium | Automated diff, CI validation |
| Build system changes | Medium | Low | Port incrementally, test each step |
| Missing patches | Low | Low | sdm660-mainline is comprehensive |

## Success Criteria

1. ✅ Fork sdm660-mainline 7.0.y branch
2. ✅ Port Phoenix config fragments into sdm660_defconfig
3. ✅ Port Phoenix CI pipeline
4. ✅ Port Phoenix flash scripts
5. ✅ CI build passes
6. ✅ Boot on real hardware
7. ✅ All peripherals functional (display, touch, WiFi, BT, USB)
8. ✅ Documentation updated

## Next Actions (Immediate)

1. **Fork sdm660-mainline/linux** branch `qcom-sdm660-7.0.y`
2. **Add Phoenix-Whyred as remote**
3. **Create `phoenix-whyred` branch**
4. **Compare defconfigs** (sdm660_defconfig vs Phoenix configs)
5. **Port config fragments** into sdm660_defconfig
6. **Port CI pipeline**
7. **Build and validate**
8. **Test on hardware**
