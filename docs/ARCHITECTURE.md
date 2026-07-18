# Architecture — Phoenix-Whyred

## Goals

1. Build against **Linux Mainline 6.18 LTS** as primary kernel source.
2. Reuse **upstream SDM660** support (already merged from sdm660-mainline project).
3. Keep **device-specific** code isolated under `drivers/whyred` + DT.
4. Ship as **flashable kernel zip** (AnyKernel3) for custom ROM users.

## Why Linux Mainline (not ACK / not downstream 4.19)?

| Approach | Pros | Cons |
|----------|------|------|
| Downstream 4.4/4.19 | Boots stock/custom ROMs easily | Old kernel, security debt |
| Android ACK (android17-6.18) | Android ABI ready | Large repo, Google dependency |
| **Linux Mainline 6.18 LTS** | Clean, upstream, SDM660 support exists | Android binder/cgroups need overlay |

Whyred hardware is **SDM636** (SDM660 family). The sdm660-mainline project has been merged into Linux Mainline, providing full SoC support. This project builds directly from mainline with minimal device-specific overlay.

## Build graph

```
PROJECT tree (this repo)
        │
        ├─ setup.sh ──► .src/linux-6.18  (kernel.org v6.18 tag)
        │
        ├─ apply-patches.sh ──► patches/{mainline,sdm660}/
        │
        ├─ build.sh ──► out/build + out/dist + out/modules
        │
        └─ pack.sh ──► out/dist/*.zip
```

## Device tree strategy

1. Start from SoC `sdm636.dtsi` → `sdm660.dtsi` in mainline tree.
2. Board file `sdm636-xiaomi-whyred.dts` holds model, compatible, board-level nodes.
3. Overlay optional SKUs (panel variants) as DTBO later.

## Module policy

- Prefer **in-tree** drivers with DT bindings.
- Use `drivers/whyred/*` only for glue that cannot live upstream yet.
- Current recommendation: keep only `whyred_board.c` (sysfs identity).
- Vendor `.ko` list: `vendor/modules/modules.load`.

## Security

- Release builds should enable module signing and keep SELinux enforcing.
- Dev builds may relax `MODULE_SIG_FORCE` via fragment.
