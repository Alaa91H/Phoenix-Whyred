// SPDX-License-Identifier: GPL-2.0-only
/*
 * Whyred audio machine notes.
 *
 * Codec: WCD9335 / related on many SDM660 Xiaomi devices (confirm).
 * Path: sound/soc/qcom + machine driver + audio routing DT.
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of.h>

static int whyred_audio_probe(struct platform_device *pdev)
{
	dev_info(&pdev->dev,
		 "whyred audio: enable SND_SOC_QCOM + WCD machine DT graph\n");
	return 0;
}

static const struct of_device_id whyred_audio_of_match[] = {
	{ .compatible = "xiaomi,whyred-audio" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, whyred_audio_of_match);

static struct platform_driver whyred_audio_driver = {
	.probe = whyred_audio_probe,
	.driver = {
		.name = "whyred-audio",
		.of_match_table = whyred_audio_of_match,
	},
};
module_platform_driver(whyred_audio_driver);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Whyred audio placeholder");
MODULE_AUTHOR("Whyred Hybrid Project");
