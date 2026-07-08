include ../../Rules.mk

# --------------------------------------------------------------------------
# thin-edge.io "standalone" runtime package
#
# thin-edge.io publishes self-contained, statically linked "standalone" bundles
# (tedge multi-call binary + a static mosquitto broker + service/config files)
# per CPU architecture at:
#   https://github.com/thin-edge/tedge-standalone/releases
#
# This package downloads the bundle matching the ICR build PLATFORM, rewrites
# the @CONFIG_DIR@ placeholders to the on-router install location (/opt/tedge)
# and repackages the payload as a Router App `*.pkg` that the `tedge` module
# unpacks into /opt/tedge.
# --------------------------------------------------------------------------

# Pinned thin-edge.io standalone release (see version.txt / CHANGELOG).
TEDGE_VERSION := 2.0.1-3
PKGNAME       := tedge-standalone-$(TEDGE_VERSION)

# On-router installation directory. Router Apps always live under /opt/<module>,
# and this module is named "tedge", so the config dir is fixed.
CONFIG_DIR    := /opt/tedge

# Map the ICR build PLATFORM onto the thin-edge.io release architecture.
#   v2i  = armv5 soft-float EABI      -> armel
#   v3   = armv7 EABI                 -> armhf
#   v4   = aarch64                    -> arm64
#   v4i  = aarch64  (ICR-1642)        -> arm64
#   pc   = x86_64  (host smoke test)  -> amd64
ifeq ($(PLATFORM),v2i)
TEDGE_ARCH := armel
else ifeq ($(PLATFORM),v3)
TEDGE_ARCH := armhf
else ifneq ($(filter $(PLATFORM),v4 v4i),)
TEDGE_ARCH := arm64
else ifeq ($(PLATFORM),pc)
TEDGE_ARCH := amd64
else
TEDGE_ARCH := unsupported
endif

TARBALL  := tedge-standalone-$(TEDGE_ARCH).tar.gz
BASE_URL := https://github.com/thin-edge/tedge-standalone/releases/download/$(TEDGE_VERSION)
DESTDIR  := $(CURDIR)/tmp

# Host tools required to assemble the package. build-package's `check` target
# warns (and skips) gracefully if any are missing.
CMD_LIST := curl tar gzip sed find

$(eval $(build-package))

$(PKGNAME).$(PLATFORM).pkg:
	@if [ "$(TEDGE_ARCH)" = "unsupported" ]; then \
		echo "  WARNING: no thin-edge.io standalone build for PLATFORM=$(PLATFORM)"; \
		touch $@; exit 0; \
	fi
	@rm -rf $(DESTDIR) *.$(PLATFORM).pkg
	@mkdir -p $(DESTDIR)
	@echo "  Fetching $(TARBALL)"
	@if [ ! -f "$(TARBALL)" ]; then \
		curl -fSL --retry 3 -o "$(TARBALL)" "$(BASE_URL)/$(TARBALL)"; \
	fi
	@echo "  Unpacking thin-edge.io $(TEDGE_VERSION) ($(TEDGE_ARCH)) for $(PLATFORM)"
	@tar -xzf "$(TARBALL)" -C $(DESTDIR)
	@echo "  Rewriting @CONFIG_DIR@ -> $(CONFIG_DIR)"
	@# Rewrite the config-dir placeholder in every text file. The tedge and
	@# mosquitto binaries are excluded (matching thin-edge's own install.sh),
	@# both because they must not be modified and to avoid needless memory use.
	@find $(DESTDIR)/tedge -type f ! -name tedge ! -name mosquitto \
		-exec sed -i 's%@CONFIG_DIR@%$(CONFIG_DIR)%g' {} +
	@install -d $(DESTDIR)/tedge/license
	@printf 'thin-edge.io standalone %s (%s)\nSPDX-License-Identifier: Apache-2.0\nSee https://github.com/thin-edge/thin-edge.io\n' \
		"$(TEDGE_VERSION)" "$(TEDGE_ARCH)" > $(DESTDIR)/tedge/license/$(PKGNAME).txt
	@echo "  Creating $@"
	@# The pkg payload is the *contents* of the tedge/ dir (bin/, services/,
	@# *.toml, ...). build-module unpacks it straight into tmp/opt/tedge.
	@tar -czf $@ -C $(DESTDIR)/tedge .
	@rm -rf $(DESTDIR)

clean:
	@rm -rf $(DESTDIR) *.pkg $(TARBALL)
