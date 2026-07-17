// SPDX-License-Identifier: GPL-2.0-only
/*
 * Whyred WLAN board data hints.
 *
 * Hardware: typically WCN3990 / QCA on SDM660 platforms (verify SKU).
 * Mainline: ath10k_snoc + firmware under /lib/firmware/ath10k/...
 *
 * This module only documents board cal / name via sysfs.
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/sysfs.h>

static ssize_t chip_show(struct device *dev,
			 struct device_attribute *attr, char *buf)
{
	return sysfs_emit(buf, "wcn3990-or-qca-sdm660\n");
}
static DEVICE_ATTR_RO(chip);

static ssize_t firmware_hint_show(struct device *dev,
				  struct device_attribute *attr, char *buf)
{
	return sysfs_emit(buf,
		"ath10k/WCN3990/hw1.0/firmware-5.bin\n"
		"Place board-2.bin / caldata from vendor firmware\n");
}
static DEVICE_ATTR_RO(firmware_hint);

static struct attribute *whyred_wlan_attrs[] = {
	&dev_attr_chip.attr,
	&dev_attr_firmware_hint.attr,
	NULL,
};
ATTRIBUTE_GROUPS(whyred_wlan);

static int whyred_wlan_probe(struct platform_device *pdev)
{
	int ret;

	ret = sysfs_create_groups(&pdev->dev.kobj, whyred_wlan_groups);
	if (ret)
		return ret;

	dev_info(&pdev->dev,
		 "whyred wlan: use ath10k_snoc + vendor firmware\n");
	return 0;
}

static void whyred_wlan_remove(struct platform_device *pdev)
{
	sysfs_remove_groups(&pdev->dev.kobj, whyred_wlan_groups);
}

static const struct of_device_id whyred_wlan_of_match[] = {
	{ .compatible = "xiaomi,whyred-wlan" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, whyred_wlan_of_match);

static struct platform_driver whyred_wlan_driver = {
	.probe = whyred_wlan_probe,
	.remove = whyred_wlan_remove,
	.driver = {
		.name = "whyred-wlan",
		.of_match_table = whyred_wlan_of_match,
	},
};
module_platform_driver(whyred_wlan_driver);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Whyred WLAN board hints");
MODULE_AUTHOR("Whyred Hybrid Project");
