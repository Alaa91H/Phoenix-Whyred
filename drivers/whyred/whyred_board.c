// SPDX-License-Identifier: GPL-2.0-only
/*
 * Xiaomi whyred board platform driver — hybrid 6.18 LTS
 * Provides sysfs identity + panel geometry from DT.
 */

#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/sysfs.h>
#include <linux/device.h>
#include <linux/slab.h>

#define WHYRED_DRV "whyred-board"

struct whyred_board {
	struct device *dev;
	u32 panel_w;
	u32 panel_h;
	u32 bringup_stage;
	const char *codename;
};

static ssize_t codename_show(struct device *dev,
			     struct device_attribute *attr, char *buf)
{
	struct whyred_board *wb = dev_get_drvdata(dev);

	return sysfs_emit(buf, "%s\n", wb->codename ? wb->codename : "whyred");
}
static DEVICE_ATTR_RO(codename);

static ssize_t soc_show(struct device *dev,
			struct device_attribute *attr, char *buf)
{
	return sysfs_emit(buf, "sdm636\n");
}
static DEVICE_ATTR_RO(soc);

static ssize_t hybrid_show(struct device *dev,
			   struct device_attribute *attr, char *buf)
{
	return sysfs_emit(buf, "6.18-lts-hybrid\n");
}
static DEVICE_ATTR_RO(hybrid);

static ssize_t panel_show(struct device *dev,
			  struct device_attribute *attr, char *buf)
{
	struct whyred_board *wb = dev_get_drvdata(dev);

	return sysfs_emit(buf, "%ux%u\n", wb->panel_w, wb->panel_h);
}
static DEVICE_ATTR_RO(panel);

static ssize_t bringup_stage_show(struct device *dev,
				  struct device_attribute *attr, char *buf)
{
	struct whyred_board *wb = dev_get_drvdata(dev);

	return sysfs_emit(buf, "%u\n", wb->bringup_stage);
}
static DEVICE_ATTR_RO(bringup_stage);

static struct attribute *whyred_attrs[] = {
	&dev_attr_codename.attr,
	&dev_attr_soc.attr,
	&dev_attr_hybrid.attr,
	&dev_attr_panel.attr,
	&dev_attr_bringup_stage.attr,
	NULL,
};
ATTRIBUTE_GROUPS(whyred);

static int whyred_board_probe(struct platform_device *pdev)
{
	struct whyred_board *wb;
	struct device_node *np = pdev->dev.of_node;
	int ret;

	wb = devm_kzalloc(&pdev->dev, sizeof(*wb), GFP_KERNEL);
	if (!wb)
		return -ENOMEM;

	wb->dev = &pdev->dev;
	wb->panel_w = 1080;
	wb->panel_h = 2160;
	wb->bringup_stage = 5;
	wb->codename = "whyred";

	of_property_read_u32(np, "xiaomi,panel-width", &wb->panel_w);
	of_property_read_u32(np, "xiaomi,panel-height", &wb->panel_h);
	of_property_read_u32(np, "xiaomi,bringup-stage", &wb->bringup_stage);
	of_property_read_string(np, "xiaomi,codename", &wb->codename);

	platform_set_drvdata(pdev, wb);

	ret = sysfs_create_groups(&pdev->dev.kobj, whyred_groups);
	if (ret)
		return ret;

	dev_info(&pdev->dev,
		 "whyred board probe OK (%ux%u hybrid 6.18 LTS, bringup stage %u)\n",
		 wb->panel_w, wb->panel_h, wb->bringup_stage);
	return 0;
}

static void whyred_board_remove(struct platform_device *pdev)
{
	sysfs_remove_groups(&pdev->dev.kobj, whyred_groups);
}

static const struct of_device_id whyred_board_of_match[] = {
	{ .compatible = "xiaomi,whyred-board" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, whyred_board_of_match);

static struct platform_driver whyred_board_driver = {
	.probe = whyred_board_probe,
	.remove = whyred_board_remove,
	.driver = {
		.name = WHYRED_DRV,
		.of_match_table = whyred_board_of_match,
	},
};
module_platform_driver(whyred_board_driver);

MODULE_AUTHOR("Whyred Hybrid Project");
MODULE_DESCRIPTION("Xiaomi whyred board platform driver");
MODULE_LICENSE("GPL");
