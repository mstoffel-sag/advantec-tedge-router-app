# Top-level recursive Makefile for the Advantech thin-edge.io Router App.
#
# Build the Router App for one or more platforms (space separated):
#
#   make PLATFORMS="v4i"          # ICR-1642 (and every other v4i router)
#   make PLATFORMS="v4 v4i"       # all aarch64 routers
#   make                          # default: every supported platform
#
# Built Router Apps are written to ./images/<module>/<module>.<platform>.tgz
#
# Platform -> ICR router family mapping (see docs/PLATFORMS.md):
#   v2i  armv5  |  v3  armv7  |  v4 / v4i  aarch64  (ICR-1642 == v4i)

# Default target platform is the ICR-1642 family (v4i) plus the other tedge
# architectures. Override with PLATFORMS="..." on the command line.
PLATFORM  ?= v4i v4 v3 v2i
PLATFORMS ?= $(PLATFORM)

DIRS := packages modules

all:
	@for DIR in $(DIRS); do \
		for PLATFORM in $(PLATFORMS); do \
			echo "==> $$DIR (PLATFORM=$$PLATFORM)"; \
			$(MAKE) -C $$DIR PLATFORM=$$PLATFORM || exit; \
		done; \
	done
	@echo
	@echo "Done. Router Apps are in ./images/"

clean:
	@for DIR in $(DIRS); do \
		$(MAKE) -C $$DIR clean; \
	done
	@rm -rf images

.PHONY: all clean
