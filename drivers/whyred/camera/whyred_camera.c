// SPDX-License-Identifier: GPL-2.0-only
/*
 * Whyred camera — WIP.
 * Sensors often: Sony IMX486 / S5K3L6 etc. (variant dependent).
 * Needs CAMSS / ISP pipeline — not complete on many mainline SDM660 trees.
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of.h>

static int whyred_camera_probe(struct platform_device *pdev)
{
	dev_info(&pdev->dev, "whyred camera: WIP (CAMSS + sensors)\n");
	return 0;
}

static const struct of_device_id whyred_camera_of_match[] = {
	{ .compatible = "xiaomi,whyred-camera" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, whyred_camera_of_match);

static struct platform_driver whyred_camera_driver = {
	.probe = whyred_camera_probe,
	.driver = {
		.name = "whyred-camera",
		.of_match_table = whyred_camera_of_match,
	},
};
module_platform_driver(whyred_camera_driver);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Whyred camera placeholder");
MODULE_AUTHOR("Whyred Hybrid Project");
