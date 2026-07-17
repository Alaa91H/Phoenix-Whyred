# Architecture — Whyred Hybrid 6.18

## Goals

1. Track **Android GKI** branch `android17-6.18` for Android 17 ecosystem readiness.  
2. Reuse **mainline SDM660** progress for clocks, interconnect, DRM, remoteproc.  
3. Keep **device-specific** code isolated under `drivers/whyred` + DT.  
4. Ship as **flashable kernel zip** (AnyKernel3) for custom ROM users.

## Why hybrid (not pure mainline / not pure 4.19)?

| Approach | Pros | Cons |
|----------|------|------|
| Downstream 4.4/4.19 | Boots stock/custom ROMs easily | Old kernel, security debt |
| Pure mainline | Clean, upstream | Weak Android (binder/GKI), incomplete SoC |
| **Hybrid GKI 6.18** | Modern base + Android ABI path | Hard bring-up; module work |

Whyred hardware is **SDM636** (SDM660 family). Community mainline lives around postmarketOS / sdm660-mainline. Android custom ROMs historically used 4.4 then 4.19. This project targets the **next** step: GKI-class 6.18 with board DT.

## Build graph

```
PROJECT tree (this repo)
        │
        ├─ setup.sh ──► .src/common  (android17-6.18)
        │                 .src/sdm660-mainline (reference)
        │
        ├─ apply-patches.sh ──► patches/{gki,sdm660,android}
        │
        ├─ build.sh ──► out/build + out/dist + out/modules
        │
        └─ pack.sh ──► out/dist/*.zip
```

## Device tree strategy

1. Start from SoC `sdm660.dtsi` in the kernel tree after sync.  
2. Board file `sdm636-xiaomi-whyred.dts` holds model, compatible, board-level nodes.  
3. Overlay optional SKUs (panel variants) as DTBO later.

## Module policy

- Prefer **in-tree** drivers with DT bindings.  
- Use `drivers/whyred/*` only for glue that cannot live upstream yet.  
- Vendor `.ko` list: `vendor/modules/modules.load`.

## Security

- Release builds should enable module signing and keep SELinux enforcing.  
- Dev builds may relax `MODULE_SIG_FORCE` via fragment.
