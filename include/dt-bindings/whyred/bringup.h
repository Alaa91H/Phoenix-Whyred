/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Gradual bring-up stages for Xiaomi whyred (SDM636).
 *
 * Override at build time, e.g.:
 *   make DTC_FLAGS="-DWHYRED_BRINGUP_STAGE=2"
 * or pass via scripts/build.sh BRINGUP_STAGE=2
 *
 * Stages (cumulative):
 *   1  UART + keys + board glue          (console only)
 *   2  + eMMC / microSD                  (rootfs)
 *   3  + USB gadget / PHY                (adb)
 *   4  + simple-fb + WLED                (display)
 *   5  + touch (Novatek)                 (input)
 *   9  full experiment (all of the above + optional nodes)
 *
 * Default: 5 — full basic bring-up path.
 */
#ifndef _DT_BINDINGS_WHYRED_BRINGUP_H
#define _DT_BINDINGS_WHYRED_BRINGUP_H

#ifndef WHYRED_BRINGUP_STAGE
#define WHYRED_BRINGUP_STAGE		5
#endif

#define WHYRED_STAGE_UART		1
#define WHYRED_STAGE_MMC		2
#define WHYRED_STAGE_USB		3
#define WHYRED_STAGE_DISPLAY		4
#define WHYRED_STAGE_TOUCH		5
#define WHYRED_STAGE_FULL		9

#define WHYRED_BRINGUP_HAS_UART		(WHYRED_BRINGUP_STAGE >= WHYRED_STAGE_UART)
#define WHYRED_BRINGUP_HAS_MMC		(WHYRED_BRINGUP_STAGE >= WHYRED_STAGE_MMC)
#define WHYRED_BRINGUP_HAS_USB		(WHYRED_BRINGUP_STAGE >= WHYRED_STAGE_USB)
#define WHYRED_BRINGUP_HAS_DISPLAY	(WHYRED_BRINGUP_STAGE >= WHYRED_STAGE_DISPLAY)
#define WHYRED_BRINGUP_HAS_TOUCH		(WHYRED_BRINGUP_STAGE >= WHYRED_STAGE_TOUCH)

#endif /* _DT_BINDINGS_WHYRED_BRINGUP_H */
