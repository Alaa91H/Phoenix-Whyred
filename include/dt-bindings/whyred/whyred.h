/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Board constants for Xiaomi whyred (SDM636).
 * Sourced from LineageOS android_kernel_xiaomi_sdm660 (lineage-20)
 * vendor DT: sdm636-mtp-whyred + longcheer/whyred + sdm660-novatek-i2c_d2s.
 * Keep in sync with arch/arm64/boot/dts/qcom/sdm636-xiaomi-whyred*.dts*
 */
#ifndef _DT_BINDINGS_WHYRED_WHYRED_H
#define _DT_BINDINGS_WHYRED_WHYRED_H

/* Panel (FHD+ 18:9) */
#define WHYRED_PANEL_WIDTH		1080
#define WHYRED_PANEL_HEIGHT		2160
#define WHYRED_PANEL_BPP		32

/*
 * SoC / board IDs from stock sdm636.dtsi + sdm636-mtp-whyred.dts
 * msm-id 345 = SDM636
 */
#define WHYRED_MSM_ID			345
#define WHYRED_BOARD_ID_0		0x30008
#define WHYRED_BOARD_ID_1		0x10008

/* TLMM GPIOs (stock longcheer whyred / novatek / mtp) */
#define WHYRED_GPIO_SD_CD		54
#define WHYRED_GPIO_USB_ID		58	/* lavender-style; whyred often uses charger extcon */
#define WHYRED_GPIO_TP_RESET		66
#define WHYRED_GPIO_TP_INT		67
#define WHYRED_GPIO_FP_RESET		20	/* stock goodix/fpc — was wrongly 65 */
#define WHYRED_GPIO_FP_INT		72	/* stock — was wrongly 64 */
#define WHYRED_GPIO_HALL_INT		75

/* PM660L GPIO */
#define WHYRED_PM660L_GPIO_VOL_UP	7

/* I2C — stock i2c_1 = BLSP1 QUP1 @ 0x0c175000 = mainline blsp_i2c1 */
#define WHYRED_NT36XXX_I2C_ADDR		0x62
#define WHYRED_GOODIX_FP_I2C_ADDR	0x27	/* legacy; stock goodix is platform+GPIO */

/* Contiguous framebuffer / cont_splash (stock splash_region@9d400000) */
#define WHYRED_FB_PHYS_BASE		0x9d400000
#define WHYRED_FB_SIZE			0x023ff000	/* stock cont_splash size */

/* ramoops (stock longcheer-sdm660-ramoops) */
#define WHYRED_RAMOOPS_BASE		0xa0000000
#define WHYRED_RAMOOPS_SIZE		0x00400000

/* earlycon: mainline blsp1_uart2 @ 0x0c170000 (uartdm) */
#define WHYRED_UART_EARLYCON_ADDR	0x0c170000

#endif /* _DT_BINDINGS_WHYRED_WHYRED_H */
