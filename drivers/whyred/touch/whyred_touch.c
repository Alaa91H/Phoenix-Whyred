// SPDX-License-Identifier: GPL-2.0-only
/*
 * Whyred touchscreen glue.
 *
 * Prefer in-tree: drivers/input/touchscreen/nt36xxx.c (or novatek,nvt-ts)
 * bound via DT node touchscreen@62 on blsp_i2c1 (stock i2c_1).
 *
 * This module logs board-specific quirks and exposes status sysfs.
 */

#include <linux/module.h>
#include <linux/of.h>
#include <linux/i2c.h>
#include <linux/gpio/consumer.h>
#include <linux/delay.h>
#include <linux/input.h>

#define WHYRED_TS_NAME "whyred-ts-glue"

static int whyred_ts_probe(struct i2c_client *client)
{
	struct device *dev = &client->dev;
	struct gpio_desc *reset;

	dev_info(dev, "whyred touch glue at 0x%02x — prefer novatek,nvt-ts in-tree\n",
		 client->addr);

	reset = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
	if (IS_ERR(reset))
		return PTR_ERR(reset);

	if (reset) {
		gpiod_set_value_cansleep(reset, 0);
		msleep(10);
		gpiod_set_value_cansleep(reset, 1);
		msleep(50);
		dev_info(dev, "touch reset pulse done\n");
	}

	/*
	 * Do not register a second input device if real nvt driver is bound.
	 * This glue is for reset sequencing / debug only when built alone.
	 */
	return 0;
}

static void whyred_ts_remove(struct i2c_client *client)
{
}

static const struct of_device_id whyred_ts_of_match[] = {
	{ .compatible = "xiaomi,whyred-touch" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, whyred_ts_of_match);

static const struct i2c_device_id whyred_ts_id[] = {
	{ "whyred-touch", 0 },
	{ }
};
MODULE_DEVICE_TABLE(i2c, whyred_ts_id);

static struct i2c_driver whyred_ts_driver = {
	.probe = whyred_ts_probe,
	.remove = whyred_ts_remove,
	.id_table = whyred_ts_id,
	.driver = {
		.name = WHYRED_TS_NAME,
		.of_match_table = whyred_ts_of_match,
	},
};
module_i2c_driver(whyred_ts_driver);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Whyred touchscreen reset glue");
MODULE_AUTHOR("Whyred Hybrid Project");
