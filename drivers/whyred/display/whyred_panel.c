// SPDX-License-Identifier: GPL-2.0-only
/*
 * Whyred panel helper for hybrid bring-up.
 *
 * Full DSI panel control should live in drm/panel or msm DSI driver with
 * proper panel timing from stock. This module:
 *  - registers panel geometry via sysfs
 *  - documents Tianma/EBBG/BOE 1080x2160 SKUs
 *  - can load when simple-framebuffer is used
 */

#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/sysfs.h>

struct whyred_panel {
	u32 width;
	u32 height;
	const char *name;
};

static struct whyred_panel g_panel = {
	.width = 1080,
	.height = 2160,
	.name = "whyred-1080x2160",
};

static ssize_t geometry_show(struct kobject *kobj,
			     struct kobj_attribute *attr, char *buf)
{
	return sysfs_emit(buf, "%ux%u\n", g_panel.width, g_panel.height);
}

static ssize_t name_show(struct kobject *kobj,
			 struct kobj_attribute *attr, char *buf)
{
	return sysfs_emit(buf, "%s\n", g_panel.name);
}

static struct kobj_attribute geometry_attr = __ATTR_RO(geometry);
static struct kobj_attribute name_attr = __ATTR_RO(name);
static struct kobject *panel_kobj;

static struct attribute *panel_attrs[] = {
	&geometry_attr.attr,
	&name_attr.attr,
	NULL,
};
static const struct attribute_group panel_group = { .attrs = panel_attrs };

static int __init whyred_panel_init(void)
{
	int ret;

	panel_kobj = kobject_create_and_add("whyred_panel", kernel_kobj);
	if (!panel_kobj)
		return -ENOMEM;

	ret = sysfs_create_group(panel_kobj, &panel_group);
	if (ret) {
		kobject_put(panel_kobj);
		return ret;
	}

	pr_info("whyred_panel: %s (%ux%u) — use DRM panel driver for full DSI\n",
		g_panel.name, g_panel.width, g_panel.height);
	return 0;
}

static void __exit whyred_panel_exit(void)
{
	if (panel_kobj) {
		sysfs_remove_group(panel_kobj, &panel_group);
		kobject_put(panel_kobj);
	}
}

module_init(whyred_panel_init);
module_exit(whyred_panel_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Whyred panel geometry helper");
MODULE_AUTHOR("Whyred Hybrid Project");
