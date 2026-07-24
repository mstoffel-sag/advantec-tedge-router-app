include ../../Rules.mk

# --------------------------------------------------------------------------
# tedge-container-plugin (container software-management + monitoring)
#
# thin-edge.io's container plugin ("ng", a single static Go multi-call binary)
# is published per CPU architecture at:
#   https://github.com/thin-edge/tedge-container-plugin/releases
#
# The .apk/.deb/.rpm packages target openrc/systemd/s6 init systems that do not
# exist on ICR-OS, so we take the plain binary tarball instead and lay just the
# binary into the tedge platform tree. Everything else the plugin needs (the
# sm-plugin names, its config .toml and the log plugins) ships as static files
# in modules/tedge/merge and is wired up by the platform's etc/init + etc/install
# -- exactly like the built-in metrics/relay features. This package therefore
# produces a *.pkg whose payload unpacks straight into /opt/tedge (bin/).
# --------------------------------------------------------------------------

# Pinned tedge-container-plugin release (see version.txt / CHANGELOG).
CONTAINER_VERSION := 2.9.0
PKGNAME           := tedge-container-$(CONTAINER_VERSION)

# Map the ICR build PLATFORM onto the tedge-container release architecture.
#   v2i  = armv5 soft-float EABI      -> arm_v5
#   v3   = armv7 EABI                 -> arm_v7
#   v4   = aarch64                    -> arm64
#   v4i  = aarch64  (ICR-1642)        -> arm64
#   pc   = x86_64  (host smoke test)  -> amd64
ifeq ($(PLATFORM),v2i)
TC_ARCH := arm_v5
else ifeq ($(PLATFORM),v3)
TC_ARCH := arm_v7
else ifneq ($(filter $(PLATFORM),v4 v4i),)
TC_ARCH := arm64
else ifeq ($(PLATFORM),pc)
TC_ARCH := amd64
else
TC_ARCH := unsupported
endif

TARBALL  := tedge-container_$(CONTAINER_VERSION)_linux_$(TC_ARCH).tar.gz
BASE_URL := https://github.com/thin-edge/tedge-container-plugin/releases/download/$(CONTAINER_VERSION)
DESTDIR  := $(CURDIR)/tmp

# Host tools required to assemble the package. build-package's `check` target
# warns (and skips) gracefully if any are missing.
CMD_LIST := curl tar gzip find

$(eval $(build-package))

$(PKGNAME).$(PLATFORM).pkg:
	@if [ "$(TC_ARCH)" = "unsupported" ]; then \
		echo "  WARNING: no tedge-container build for PLATFORM=$(PLATFORM)"; \
		touch $@; exit 0; \
	fi
	@rm -rf $(DESTDIR) *.$(PLATFORM).pkg
	@mkdir -p $(DESTDIR)
	@echo "  Fetching $(TARBALL)"
	@if [ ! -f "$(TARBALL)" ]; then \
		curl -fSL --retry 3 -o "$(TARBALL)" "$(BASE_URL)/$(TARBALL)"; \
	fi
	@echo "  Unpacking tedge-container $(CONTAINER_VERSION) ($(TC_ARCH)) for $(PLATFORM)"
	@# The tarball holds tedge-container_<ver>_linux_<arch>/bin/tedge-container
	@# (+ LICENSE). Extract just the binary into the pkg's bin/ so it lands at
	@# /opt/tedge/bin/tedge-container when the tedge module unpacks this pkg.
	@tar -xzf "$(TARBALL)" -C $(DESTDIR) --strip-components=1 \
		"tedge-container_$(CONTAINER_VERSION)_linux_$(TC_ARCH)/bin/tedge-container"
	@chmod +x $(DESTDIR)/bin/tedge-container
	@install -d $(DESTDIR)/license
	@printf 'tedge-container-plugin %s (%s)\nSPDX-License-Identifier: Apache-2.0\nSee https://github.com/thin-edge/tedge-container-plugin\n' \
		"$(CONTAINER_VERSION)" "$(TC_ARCH)" > $(DESTDIR)/license/$(PKGNAME).txt
	@echo "  Creating $@"
	@# Payload is the *contents* of DESTDIR (bin/, license/); build-module
	@# unpacks it straight into tmp/opt/tedge.
	@tar -czf $@ -C $(DESTDIR) .
	@rm -rf $(DESTDIR)

clean:
	@rm -rf $(DESTDIR) *.pkg $(TARBALL)
