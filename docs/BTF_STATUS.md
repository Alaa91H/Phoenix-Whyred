# BTF (BPF Type Format) — Status

## Current State

**CONFIG_DEBUG_INFO_BTF=n** — intentionally disabled.

## What Happened

During CI builds, the final BTF generation step fails:

```
FAILED: load BTF from vmlinux.unstripped: Invalid argument
  resolve_btfids
```

## Root Cause Analysis

| Factor | Status |
|--------|--------|
| `pahole` installed? | Yes (via `dwarves` package) |
| pahole version? | Ubuntu 24.04 ships pahole ~1.24 |
| Required version for 6.18 BTF? | >= 1.25 (kernel 6.18 BTF format changes) |
| `resolve_btfids` built correctly? | Yes (part of kernel build) |
| Generated BTF valid? | No — `Invalid argument` from loader |

The `resolve_btfids` tool processes BTF data from `vmlinux.unstripped`. Kernel 6.18 uses BTF format features that require pahole >= 1.25. Ubuntu 24.04's `dwarves` package provides pahole 1.24, which generates BTF that the 6.18 kernel loader rejects.

## Impact

With BTF disabled:
- `CONFIG_DEBUG_INFO_BTF=n`
- No kfunc/BPF CO-RE support
- No BTF-based debugging
- Kernel still functions normally
- Android GKI still boots

## Temporary Workaround

The `hybrid.config` fragment explicitly disables BTF:

```
# CONFIG_DEBUG_INFO_BTF is not set
# CONFIG_DEBUG_INFO_BTF_MODULES is not set
```

## Resolution Paths

### Option A: Upgrade pahole (Recommended)
```bash
# On CI (Ubuntu 24.04):
sudo apt-get install -y dwarves
pahole --version  # needs >= 1.25
```
If Ubuntu 26.04 ships pahole 1.25+, simply remove the BTF disable from `hybrid.config`.

### Option B: Build pahole from source
```bash
git clone https://github.com/acmel/dwarves.git
cd dwarves && mkdir build && cd build
cmake .. && make && sudo make install
```

### Option C: Keep disabled (acceptable)
BTF is not required for boot or basic functionality. Disable permanently if the
complexity of building pahole from source is not justified for this project.

## How to Re-enable

1. Remove these lines from `configs/fragments/hybrid.config`:
   ```
   # CONFIG_DEBUG_INFO_BTF is not set
   # CONFIG_DEBUG_INFO_BTF_MODULES is not set
   ```
2. Ensure `pahole --version` reports >= 1.25
3. Build and verify `resolve_btfids` succeeds

## References

- [kernel.org BTF docs](https://www.kernel.org/doc/html/latest/bpf/btf.html)
- [pahole repository](https://github.com/acmel/dwarves)
- [BPF CO-RE](https://nakryiko.com/posts/bpf-core-reference-guide/)
