include ../../Rules.mk

# Bundle the thin-edge.io standalone runtime (fetched + prepared by
# packages/tedge) into this Router App. build-module unpacks each INSTALL pkg
# into tmp/opt/tedge and then overlays everything under merge/ on top of it,
# finally producing images/tedge/tedge.<platform>.tgz
INSTALL += ../../packages/tedge/*.$(PLATFORM).pkg

# The tedge-container-plugin binary (folded into this platform module). Its pkg
# payload unpacks into tmp/opt/tedge/bin; the sm-plugins, config .toml and log
# plugins ship in merge/ and are wired up by etc/init + etc/install.
INSTALL += ../../packages/tedge-container/*.$(PLATFORM).pkg

$(eval $(build-module))
