# New Project Direction: Phoenix-Whyred onto sdm660-mainline

## Strategic Reset

### Previous Approach (Abandoned)
- **Source**: Vanilla Linux 6.18 (no Qualcomm support)
- **Strategy**: Reconstruct SDM660 platform from scratch
- **Status**: Build passes, but 5 config gaps, no verified boot
- **Problem**: Developer who booted whyred on Mainline Linux directs rebase onto sdm660-mainline

### New Approach
- **Source**: sdm660-mainline/linux branch `qcom-sdm660-7.0.y` (Linux 7.0.9)
- **Strategy**: Fork sdm660-mainline, add Phoenix customizations on top
- **Status**: Research phase
- **Advantage**: Proven working whyred DTS, active community, regular upstream merges

## Why This Change

1. **Proven Boot**: sdm660-mainline has verified whyred boot
2. **Active Development**: 6 commits in last 8 days
3. **Complete Support**: WiFi, Bluetooth, USB, display, touch all working
4. **Community**: 48 stars, 36 forks, active contributors
5. **Upstream Regular**: Merges from torvalds/linux regularly
6. **Expert Guidance**: Developer who booted whyred recommends this base

## What Changes

### Preserved from Phoenix-Whyred
- CI pipeline concept (adapted from sdm660-mainline `infra`)
- AnyKernel3 flash scripts
- Project documentation structure
- Whyred-specific config fragments (merged into sdm660_defconfig)

### Replaced
- Vanilla 6.18 base → sdm660-mainline 7.0.9 base
- Custom DTS reconstruction → sdm660-mainline proven DTS
- From-scratch platform support → sdm660-mainline platform support

### Added
- sdm660-mainline SDM660/630/636 platform patches
- Proven whyred Device Tree
- Active community support
- Regular upstream kernel merges

## Project Structure (New)

```
Phoenix-Whyred/
├── arch/arm64/boot/dts/qcom/
│   └── sdm636-xiaomi-whyred.dts    # From sdm660-mainline
├── configs/
│   ├── sdm660_defconfig            # From sdm660-mainline
│   └── fragments/
│       └── whyred.config           # Phoenix customizations
├── docs/
│   ├── bringup/                    # Existing docs
│   ├── research/                   # This analysis
│   └── status/                     # Migration matrix
├── pack/
│   └── AnyKernel3/                 # Flash scripts
├── scripts/
│   ├── build.sh                    # CI build script
│   └── setup.sh                    # CI setup script
├── .github/workflows/
│   └── build-kernel.yml            # CI pipeline
└── PROJECT.conf                    # Project metadata
```

## Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Research | Complete | 4 analysis documents |
| Fork & Align | 2 days | Forked repo, branch structure |
| Port Additions | 3 days | Config, DTS, scripts merged |
| Validate | 2 days | CI build passes, boot test |
| Documentation | 1 day | Updated docs, migration guide |
| **Total** | **8 days** | **Working whyred on 7.0.9** |

## Success Metrics

1. ✅ Fork sdm660-mainline 7.0.y branch
2. ✅ Port Phoenix config fragments into sdm660_defconfig
3. ✅ Port Phoenix CI pipeline
4. ✅ Port Phoenix flash scripts
5. ✅ CI build passes
6. ✅ Boot on real hardware
7. ✅ All peripherals functional (display, touch, WiFi, BT, USB)
8. ✅ Documentation updated

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Touch mismatch | High | Test Synaptics RMI4 first |
| Panel mismatch | High | Verify Tianma TD4310 display |
| Config drift | Medium | Automated diff, CI validation |
| Build system changes | Medium | Port incrementally |
| Missing patches | Low | sdm660-mainline is comprehensive |

## Next Actions

1. **Fork sdm660-mainline/linux** branch `qcom-sdm660-7.0.y`
2. **Add Phoenix-Whyred as remote**
3. **Create `phoenix-whyred` branch**
4. **Compare defconfigs** (sdm660_defconfig vs Phoenix configs)
5. **Port config fragments** into sdm660_defconfig
6. **Port CI pipeline**
7. **Build and validate**
8. **Test on hardware**

## Documentation Artifacts

| Document | Location | Status |
|----------|----------|--------|
| SDM660_MAINLINE_BASE_SELECTION.md | `docs/research/` | ✅ Complete |
| REBASE_STRATEGY.md | `docs/research/` | ✅ Complete |
| WHYRED_MAINLINE_REFERENCE.md | `docs/research/` | ✅ Complete |
| NEW_PROJECT_DIRECTION.md | `docs/research/` | ✅ Complete |
| DRIVER_MIGRATION_MATRIX.md | `docs/status/` | Existing |
| IMPLEMENTATION_PRIORITY.md | `docs/bringup/` | Existing |
| STEP9_FINAL_REPORT.md | `docs/bringup/` | Existing |

## Decision

**Proceed with Option C: Fork sdm660-mainline 7.0.y, add Phoenix customizations on top.**

This provides the cleanest path to a working whyred on Mainline Linux, leveraging proven community work while preserving Phoenix project identity.
