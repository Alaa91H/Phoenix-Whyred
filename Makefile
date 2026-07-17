# Whyred Hybrid Kernel 6.18 LTS — top-level Makefile

.PHONY: help setup import patches config build image pack clean distclean info \
	setup-618 setup-419 build-618 build-419 all \
	bringup1 bringup2 bringup3 bringup4 bringup5 stock-dt-compare stock-ref validate

help:
	@echo "Whyred Hybrid Kernel 6.18 LTS (default)"
	@echo ""
	@echo "  make setup       - clone android17-6.18 + overlay whyred"
	@echo "  make build       - build hybrid Image.gz + modules"
	@echo "  make image       - Image only (faster)"
	@echo "  make pack        - AnyKernel3 zip"
	@echo "  make all         - setup → build → pack"
	@echo "  make setup-419   - optional downstream 4.19"
	@echo "  make info"
	@echo ""
	@echo "Bring-up (BRINGUP_STAGE / UART→MMC→USB→display→touch):"
	@echo "  make bringup1 … bringup5   - image with stage N"
	@echo "  make stock-dt-compare      - stock vs hybrid DT audit"
	@echo "  make stock-ref             - fetch LineageOS vendor DT ref"
	@echo "  make validate              - structure checks"

all: setup build pack

setup:
	@KERNEL_TRACK=6.18 bash scripts/setup.sh

setup-618:
	@KERNEL_TRACK=6.18 bash scripts/setup.sh

setup-419:
	@KERNEL_TRACK=4.19 bash scripts/setup.sh

import:
	@bash scripts/import-whyred-419.sh

patches:
	@KERNEL_TRACK=6.18 bash scripts/apply-patches.sh

config:
	@KERNEL_TRACK=6.18 bash scripts/build.sh config

build:
	@KERNEL_TRACK=6.18 bash scripts/build.sh whyred

image:
	@KERNEL_TRACK=6.18 bash scripts/build.sh image

build-618:
	@KERNEL_TRACK=6.18 bash scripts/build.sh whyred

build-419:
	@KERNEL_TRACK=4.19 bash scripts/build.sh whyred

pack:
	@KERNEL_TRACK=6.18 bash scripts/pack.sh

clean:
	@rm -rf out/build out/modules out/dist
	@echo "Cleaned out/"

distclean: clean
	@rm -rf .src
	@echo "Removed .src/"

info:
	@bash -c 'source PROJECT.conf; echo "Track=$$KERNEL_TRACK Kernel=$$KERNEL_VERSION Src=$$KERNEL_SRC Defconfig=$$BASE_DEFCONFIG Zip=$$ZIP_PREFIX Localversion=$$LOCALVERSION"; echo "BRINGUP_STAGE=$${BRINGUP_STAGE:-5} (1=UART … 5=touch)"'

bringup1:
	@BRINGUP_STAGE=1 KERNEL_TRACK=6.18 bash scripts/build.sh image

bringup2:
	@BRINGUP_STAGE=2 KERNEL_TRACK=6.18 bash scripts/build.sh image

bringup3:
	@BRINGUP_STAGE=3 KERNEL_TRACK=6.18 bash scripts/build.sh image

bringup4:
	@BRINGUP_STAGE=4 KERNEL_TRACK=6.18 bash scripts/build.sh image

bringup5:
	@BRINGUP_STAGE=5 KERNEL_TRACK=6.18 bash scripts/build.sh whyred

stock-dt-compare:
	@bash scripts/compare-stock-dt.sh

stock-ref:
	@bash scripts/fetch-stock-ref.sh

validate:
	@bash scripts/validate.sh
