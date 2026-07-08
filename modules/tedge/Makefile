include ../../Rules.mk

# Bundle the thin-edge.io standalone runtime (fetched + prepared by
# packages/tedge) into this Router App. build-module unpacks each INSTALL pkg
# into tmp/opt/tedge and then overlays everything under merge/ on top of it,
# finally producing images/tedge/tedge.<platform>.tgz
INSTALL += ../../packages/tedge/*.$(PLATFORM).pkg

$(eval $(build-module))
