# Rebase Strategy: Phoenix-Whyred onto sdm660-mainline

## Current State

### Phoenix-Whyred (Current)
- **Source**: Vanilla Linux 6.18 (no Qualcomm platform support)
- **Approach**: Reconstruct platform support from scratch
- **Status**: Build passes, but 5 config gaps, no verified boot
- **Commits**: Custom DTS, Kconfig, build scripts, CI pipeline

### sdm660-mainline (Target)
- **Source**: torvalds/linux with Qualcomm patches
- **Approach**: Fork of upstream with SDM660/630/636 support
- **Status**: Working whyred boot, active development
- **Kernel**: 7.0.9
- **Branch**: `qcom-sdm660-7.0.y`

## Rebase Strategy Options

### Option A: Direct Rebase onto sdm660-mainline 7.0.y
**Pros:**
- Most up-to-date kernel
- Active maintenance and bug fixes
- All SDM660 patches already applied

**Cons:**
- Larger version jump (6.18 → 7.0)
- May require rebasing custom patches
- Less proven with Phoenix-specific changes

### Option B: Cherry-pick sdm660-mainline patches onto Phoenix 6.18
**Pros:**
- Smaller delta to manage
- Phoenix build system preserved
- Incremental integration possible

**Cons:**
- Maintaining two trees is complex
- May miss fixes in newer sdm660-mainline commits
- DTS differences could cause conflicts

### Option C: Fork sdm660-mainline 7.0.y, add Phoenix customizations
**Pros:**
- Cleanest approach
- All sdm660-mainline work preserved
- Phoenix additions are clearly separate commits

**Cons:**
- Losing Phoenix build system (unless ported)
- Need to understand sdm660-mainline CI/infrastructure
- Initial setup time

## Recommended Approach: Option C

**Fork sdm660-mainline 7.0.y, add Phoenix customizations on top.**

### Rationale
1. sdm660-mainline is the proven, working base
2. Phoenix's custom DTS and config fragments can be added as additional commits
3. CI pipeline can be adapted from sdm660-mainline's `infra` repository
4. Long-term maintenance is simpler with single upstream

## Implementation Plan

### Phase 1: Fork and Align (Days 1-2)
1. Fork `sdm660-mainline/linux` branch `qcom-sdm660-7.0.y`
2. Add Phoenix-Whyred as remote
3. Create `phoenix-whyred` branch from sdm660-mainline default
4. Compare sdm660_defconfig with Phoenix configs

### Phase 2: Port Phoenix Additions (Days 3-5)
1. Port `configs/fragments/whyred.config` → sdm660_defconfig
2. Port `arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred.dts` differences
3. Port `scripts/build.sh`, `setup.sh`, `pack.sh` (if needed)
4. Port `.github/workflows/build-kernel.yml` CI pipeline
5. Port `pack/AnyKernel3/anykernel.sh` flash config

### Phase 3: Validate (Days 6-7)
1. Build on CI
2. Verify boot artifact
3. Compare DTS output
4. Test config completeness

### Phase 4: Documentation (Day 8)
1. Update PROJECT.conf
2. Update README.md
3. Create migration guide
4. Archive old Phoenix-Whyred main branch

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| DTS conflicts | High | Manual merge, test each node |
| Config drift | Medium | Automated diff, CI validation |
| Build system changes | Medium | Port incrementally, test each step |
| Missing patches | Low | sdm660-mainline is comprehensive |
| Regression in 7.0.y | Low | sdm660-mainline is proven |

## Success Criteria

1. Build passes on CI
2. Boot artifact matches expected layout
3. All whyred-specific nodes present in DTS
4. Config validation passes (0 gaps)
5. Flash and boot on real hardware
6. All peripherals functional (display, touch, WiFi, BT, USB)
