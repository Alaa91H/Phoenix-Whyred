// SPDX-License-Identifier: GPL-2.0-only
/*
 * Whyred power / charger notes for hybrid bring-up.
 *
 * Stock uses Qualcomm SMB charger + fuel gauge on PMIC.
 * Mainline path: qcom,smb2 / qcom,pmi8998-charger patterns or
 * simple power_supply from PMIC FG when available.
 *
 * This module registers a placeholder power_supply for debugging
 * until real FG/charger drivers bind.
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/power_supply.h>
#include <linux/of.h>

struct whyred_power {
	struct power_supply *psy;
	struct power_supply_desc desc;
};

static int whyred_get_property(struct power_supply *psy,
			       enum power_supply_property psp,
			       union power_supply_propval *val)
{
	switch (psp) {
	case POWER_SUPPLY_PROP_STATUS:
		val->intval = POWER_SUPPLY_STATUS_UNKNOWN;
		break;
	case POWER_SUPPLY_PROP_PRESENT:
		val->intval = 1;
		break;
	case POWER_SUPPLY_PROP_TECHNOLOGY:
		val->intval = POWER_SUPPLY_TECHNOLOGY_LION;
		break;
	case POWER_SUPPLY_PROP_CAPACITY:
		/* Unknown until FG works */
		val->intval = 50;
		break;
	case POWER_SUPPLY_PROP_VOLTAGE_MAX_DESIGN:
		val->intval = 4400000;
		break;
	case POWER_SUPPLY_PROP_CHARGE_FULL_DESIGN:
		/* whyred 4000 mAh typical */
		val->intval = 4000000;
		break;
	default:
		return -EINVAL;
	}
	return 0;
}

static enum power_supply_property whyred_psy_props[] = {
	POWER_SUPPLY_PROP_STATUS,
	POWER_SUPPLY_PROP_PRESENT,
	POWER_SUPPLY_PROP_TECHNOLOGY,
	POWER_SUPPLY_PROP_CAPACITY,
	POWER_SUPPLY_PROP_VOLTAGE_MAX_DESIGN,
	POWER_SUPPLY_PROP_CHARGE_FULL_DESIGN,
};

static int whyred_power_probe(struct platform_device *pdev)
{
	struct whyred_power *wp;
	struct power_supply_config cfg = {};

	wp = devm_kzalloc(&pdev->dev, sizeof(*wp), GFP_KERNEL);
	if (!wp)
		return -ENOMEM;

	wp->desc.name = "whyred-battery";
	wp->desc.type = POWER_SUPPLY_TYPE_BATTERY;
	wp->desc.properties = whyred_psy_props;
	wp->desc.num_properties = ARRAY_SIZE(whyred_psy_props);
	wp->desc.get_property = whyred_get_property;

	cfg.drv_data = wp;
	cfg.of_node = pdev->dev.of_node;

	wp->psy = devm_power_supply_register(&pdev->dev, &wp->desc, &cfg);
	if (IS_ERR(wp->psy))
		return PTR_ERR(wp->psy);

	platform_set_drvdata(pdev, wp);
	dev_info(&pdev->dev,
		 "whyred power: placeholder battery psy (replace with FG/SMB)\n");
	return 0;
}

static const struct of_device_id whyred_power_of_match[] = {
	{ .compatible = "xiaomi,whyred-power" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, whyred_power_of_match);

static struct platform_driver whyred_power_driver = {
	.probe = whyred_power_probe,
	.driver = {
		.name = "whyred-power",
		.of_match_table = whyred_power_of_match,
	},
};
module_platform_driver(whyred_power_driver);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Whyred power_supply placeholder");
MODULE_AUTHOR("Whyred Hybrid Project");
