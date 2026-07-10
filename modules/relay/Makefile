include ../../Rules.mk

# Relay-control extension Router App.
#
# An extension bundles no thin-edge.io runtime (no INSTALL line), so its build
# needs no downloads. build-module overlays merge/ into images/relay/relay.<platform>.tgz.
# It integrates with the tedge platform at runtime: the local MQTT bus and the
# Cumulocity operations registry (/opt/tedge/operations/c8y). See docs/EXTENSION-API.md.
$(eval $(build-module))
