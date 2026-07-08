# Generic build rules for the Advantech thin-edge.io Router App.
#
# This mirrors the layout used by the official Advantech RouterApps repository:
# the project is meant to be checked out *next to* the Advantech ModulesSDK, i.e.
#
#   <workspace>/
#     |-- ModulesSDK/                 (https://bitbucket.org/bbsmartworx/modulessdk)
#     +-- advantec-tedge-router-app/  (this repository)
#
# The ModulesSDK provides the `build-module` / `build-package` make macros and the
# per-platform cross-toolchain settings that turn our sources into a `*.tgz`
# Router App that can be uploaded to an ICR router.

# top directory of this repository
TOPDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# path to the Advantech Router App SDK (checked out alongside this repo)
SDKDIR := $(abspath $(TOPDIR)/../ModulesSDK)

# SDK version this project was developed against
SDKVER := 2.2.10

# pull in the SDK rules (toolchain selection, build-module / build-package, ...)
ifneq ($(wildcard $(SDKDIR)/Rules.mk),)
include $(SDKDIR)/Rules.mk
else
$(error ModulesSDK not found in $(SDKDIR). See README.md / scripts/setup-build-env.sh)
endif

# sanity-check the SDK version (warn instead of hard-fail to ease upgrades)
-include $(SDKDIR)/version
ifneq ($(VERSION),$(SDKVER))
$(warning ModulesSDK version mismatch: found "$(VERSION)", developed against "$(SDKVER)")
endif
